const std = @import("std");

const microzig = @import("microzig");
const assert = microzig.assert;
const rp2xxx = microzig.hal;
const clocks = rp2xxx.clocks;
const gpio = rp2xxx.gpio;

const log = std.log.scoped(.i2s);

pub const StereoMode = enum {
    // Samples in the fifo alternate between left and right,
    // with left coming before right
    alternate_samples,
    // Samples in the fifo are packed into single words,
    // with the left channel in the high bits and the
    // right channel in the low bits.
    packed_samples,
};

pub fn I2S(comptime Sample: type, comptime args: struct {
    sample_rate: u32,
    // When set, an individual item in the fifo is two samples
    // packed together, with the left sample in the high bits
    // and the right sample in the low bits.
    stereo_mode: StereoMode = .alternate_samples,
}) type {
    switch (args.sample_rate) {
        8_000,
        16_000,
        32_000,
        44_100,
        48_000,
        88_200,
        96_000,
        => {},
        else => @compileError("sample_rate must be 8kHz, 16kHz, 32kHz, 44.1kHz, 48kHz, 88.2kHz or 96kHz"),
    }

    switch (Sample) {
        i16, i24, i32 => {},
        else => @compileError("sample_type must be i16, i24, or i32"),
    }

    const sample_width = @bitSizeOf(Sample);
    const output = comptime rp2xxx.pio.assemble(std.fmt.comptimePrint(
        \\.program i2s
        \\.side_set 2
        \\
        \\.define SAMPLE_BITS {}
        \\
        \\  set pindirs, 0x7         side 0x1 ; Set pin to output
        \\.wrap_target
        \\  set x, (SAMPLE_BITS - 2) side 0x1
        \\left_first:
        \\  out pins, 1              side 0x0
        \\  jmp x-- left_first       side 0x1
        \\  out pins, 1              side 0x2
        \\
        \\  set x, (SAMPLE_BITS - 2) side 0x3
        \\right_first:
        \\  out pins, 1              side 0x2
        \\  jmp x-- right_first      side 0x3
        \\  out pins, 1              side 0x0
        \\.wrap
    , .{sample_width}), .{});

    const i2s_program = comptime output.get_program_by_name("i2s");
    return struct {
        pio: rp2xxx.pio.Pio,
        sm: rp2xxx.pio.StateMachine,

        const Self = @This();
        pub const InitOptions = struct {
            clock_config: clocks.config.Global,
            clk_pin: gpio.Pin,
            word_select_pin: gpio.Pin,
            data_pin: gpio.Pin,
        };

        pub fn init(pio: rp2xxx.pio.Pio, comptime opts: InitOptions) @This() {
            comptime {
                if (@backingInt(opts.word_select_pin) != @backingInt(opts.clk_pin) + 1)
                    @panic("word select pin must be clk pin + 1");

                // TODO: ensure they are contiguous
            }

            pio.gpio_init(opts.data_pin);
            pio.gpio_init(opts.clk_pin);
            pio.gpio_init(opts.word_select_pin);

            log.info("initialized GPIO", .{});
            log.info("data pin:  {}", .{opts.data_pin});
            log.info("clk pin:  {}", .{opts.clk_pin});
            log.info("word select pin:  {}", .{opts.word_select_pin});

            const set_mapping: rp2xxx.pio.PinMapping(u3) = .{ .low = opts.data_pin, .high = opts.word_select_pin };
            const side_set_mapping: rp2xxx.pio.PinMapping(u3) = .{ .low = opts.clk_pin, .high = opts.word_select_pin };
            const out_mapping: rp2xxx.pio.PinMapping(u6) = .single(opts.data_pin);

            log.info("set_mapping: {}", .{set_mapping});
            log.info("side_set_mapping: {}", .{side_set_mapping});
            log.info("out_mapping: {}", .{out_mapping});

            comptime {
                assert(set_mapping.count() == 3, .{});
                assert(side_set_mapping.count() == 2, .{});
            }

            const sm = pio.claim_unused_state_machine() catch unreachable;
            pio.sm_load_and_start_program(sm, i2s_program, .{
                .clkdiv = comptime rp2xxx.pio.ClkDivOptions.from_float(div: {
                    const sys_clk_freq = @as(f32, @floatFromInt(opts.clock_config.get_frequency(.clk_sys).?));
                    const i2s_clk_freq = @as(f32, @floatFromInt(args.sample_rate * sample_width * 2));

                    // TODO: 2 or 4 PIO clocks generate one I2S clock cycle
                    const pio_clk_freq = 2 * i2s_clk_freq;
                    break :div sys_clk_freq / pio_clk_freq;
                }),
                .shift = .{
                    .autopull = true,
                    .pull_threshold = switch (args.stereo_mode) {
                        .packed_samples => @as(u5, @truncate(sample_width * 2)),
                        .alternate_samples => @as(u5, @truncate(sample_width)),
                    },
                    .join_tx = true,
                    .out_shiftdir = .left,
                },
                .pin_mappings = .{
                    .set = set_mapping,
                    .side_set = side_set_mapping,
                    .out = out_mapping,
                },
            }) catch unreachable;

            pio.sm_set_enabled(sm, true);
            return Self{
                .pio = pio,
                .sm = sm,
            };
        }

        pub fn is_writable(self: Self) bool {
            // the TX FIFO is joined, making a total of 8 entries. We only
            // want to write when there's room for at least two samples
            return self.pio.sm_fifo_level(self.sm, .tx) <= 6;
        }

        const UnsignedSample = @Int(.unsigned, @bitSizeOf(Sample));
        fn sample_to_fifo_entry(sample: Sample) u32 {
            const sample_shift = comptime 32 - sample_width;
            return @shlExact(@as(
                u32,
                @intCast(@as(UnsignedSample, @bitCast(sample))),
            ), sample_shift);
        }

        pub fn write_mono(self: Self, sample: Sample) void {
            const value = sample_to_fifo_entry(sample);
            switch (args.stereo_mode) {
                .packed_samples =>
                    self.pio.sm_write(
                        value | @shrExact(value, sample_width),
                    ),
                .alternate_samples => {
                    self.pio.sm_write(self.sm, value);
                    self.pio.sm_write(self.sm, value);
                },
            }
        }

        pub const StereoSample = struct {
            left: Sample,
            right: Sample,
        };

        pub fn write_stereo(self: Self, sample: StereoSample) void {
            switch (args.stereo_mode) {
                .packed_samples =>
                    self.pio.sm_write(
                        sample_to_fifo_entry(sample.left) |
                        @shrExact(sample_to_fifo_entry(sample.right), sample_width)
                    ),
                .alternate_samples => {
                    self.pio.sm_write(self.sm, sample_to_fifo_entry(sample.left));
                    self.pio.sm_write(self.sm, sample_to_fifo_entry(sample.right));
                },
            }
        }

        pub fn write_stereo_blocking(self: Self, sample: StereoSample) void {
            switch (args.stereo_mode) {
                .packed_samples =>
                    self.pio.sm_write(
                        sample_to_fifo_entry(sample.left) |
                        @shrExact(sample_to_fifo_entry(sample.right), sample_width)
                    ),
                .alternate_samples => {
                    self.pio.sm_blocking_write(self.sm, sample_to_fifo_entry(sample.left));
                    self.pio.sm_blocking_write(self.sm, sample_to_fifo_entry(sample.right));
                },
            }
        }
    };
}
