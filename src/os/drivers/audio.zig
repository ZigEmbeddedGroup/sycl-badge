// ============================================================================
// Buzzer controller for CMT-7525-80-SMT-TR
//
// GPIO8 = SPKR_EN  - speaker enable (active-high)
// GPIO9 = SPKR_A0  - PWM audio output → PWM slice 4, channel B
//
// The CMT-7525-80-SMT-TR is a magnetic buzzer with a resonant frequency of
// ~2500 Hz. It is driven by toggling the A0 line at the desired frequency
// (50 % duty cycle for maximum volume) while SPKR_EN is held high.
// ============================================================================

const microzig = @import("microzig");
const assert = microzig.assert;
const hal = microzig.hal;
const pwm = hal.pwm;
const board = microzig.board;
const PWM = microzig.chip.peripherals.PWM;
const DMA = microzig.chip.peripherals.DMA;

const std = @import("std");
const log = std.log.scoped(.audio);

const timer = @import("timer.zig");
const fps_overlay = @import("../system/fps_overlay.zig");
const terry = @import("../system/terry.zig");
const rev = @import("rev.zig");

const TransferRequest = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).TREQ_SEL);
const DMA_DataSize = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).DATA_SIZE);
const DMA_RingSize = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).RING_SIZE);

const DMA_Params = struct {
    treq: TransferRequest,
    data_size: DMA_DataSize,
    ring_size: DMA_RingSize,
    write_addr: u32,
};

const rev0 = struct {
    const Sample = u32;
    /// System clock in Hz (150 MHz)
    const buzzer_sys_clk_hz: u32 = hal.clock_config.get_frequency(.clk_sys).?;
    /// Integer pre-divider applied to the system clock before the PWM counter.
    const buzzer_pwm_clk_div = 1;
    /// Number of possible values in an audio buffer
    const audio_levels = 500;
    /// Speed of the pwm cycle for controlling volume,
    /// too fast for humans to hear (or for the speaker to even create)
    const audio_pwm_cycle_hz = 300_000;

    // Make sure the above values are consistent with the hardware.
    // They are all important so we specify them all instead of calculating any of them
    comptime {
        std.debug.assert(buzzer_sys_clk_hz == audio_levels * audio_pwm_cycle_hz * buzzer_pwm_clk_div);
    }

    /// PWM slice number for GPIO9 (slice = pin / 2 = 9 / 2 = 4).
    const buzzer_pwm_slice: pwm.Slice = @fromBackingInt(@intCast(4));
    const buzzer_pwm_ch = pwm.Pwm{ .slice_number = @backingInt(buzzer_pwm_slice), .channel = .b };

    /// Separate PWM slice used for wave timing control
    const audio_timing_slice: pwm.Slice = @fromBackingInt(@intCast(5));

    fn init() void {
        // Enable pin: SIO output, start disabled
        board.rev0.audio.buzzer_enable.set_function(.sio);
        board.rev0.audio.buzzer_enable.set_direction(.out);
        board.rev0.audio.buzzer_enable.put(0);

        // Audio pin: hand control to the PWM peripheral
        board.rev0.audio.buzzer_pwm.set_function(.pwm);

        buzzer_pwm_slice.set_clk_div(.{
            .int = @intCast(buzzer_pwm_clk_div),
            .frac = 0,
        });
        buzzer_pwm_slice.set_wrap(@intCast(audio_levels));

        buzzer_pwm_ch.set_level(0);
    }

    fn set_enabled(enabled: bool) void {
        board.rev0.audio.buzzer_enable.put(@intFromBool(enabled));
    }

    fn start_pwm() void {
        audio_timing_slice.enable();
        buzzer_pwm_slice.enable();
    }

    fn stop() void {
        board.rev0.audio.buzzer_enable.put(0);
        buzzer_pwm_slice.disable();
        audio_timing_slice.disable();
        board.rev0.audio.buzzer_pwm.put(0);
    }

    fn set_timing_PWM_hz(hz: f32) !void {
        // A piano ranges from 27.5 Hz to 4186 Hz, so for the square wave generator
        // clock we need to support a pretty wide range with reasonable accuracy.
        // The possible source clocks are 8.4 fractional divs of the sys clock,
        // or 0 for a max div of 256

        const clk_rate = @as(f32, @floatFromInt(buzzer_sys_clk_hz));
        var clk_div = @ceil(clk_rate * 16.0 / 65536.0 / hz);

        // Can't divide by less than 1.0
        clk_div = @max(16.0, clk_div);

        if (clk_div > (1 << 13)) {
            // The target frequency is too slow to reproduce
            return error.FrequencyTooSlow;
        }

        var wrap_ticks = clk_rate * 16.0 / clk_div / hz;

        // Centered mode allows another 2x divider on the clock
        var use_centered_mode = false;
        if (clk_div > (1 << 12)) {
            clk_div = @ceil(clk_div / 2.0);
            wrap_ticks = wrap_ticks / 2.0;
            use_centered_mode = true;
        }
        wrap_ticks = @max(1.0, @round(wrap_ticks));

        const clk_div_int: u32 = if (clk_div == 256) 0 else @intFromFloat(clk_div);
        const wrap_int: u32 = @intFromFloat(wrap_ticks - 1.0);

        audio_timing_slice.set_phase_correct(use_centered_mode);
        audio_timing_slice.set_clk_div(.{
            .int = @intCast(clk_div_int >> 4),
            .frac = @intCast(clk_div_int & 0xF),
        });
        audio_timing_slice.set_wrap(@intCast(wrap_int));
    }

    fn dma_params() DMA_Params {
        return .{
            .treq = @fromBackingInt(@intCast(@backingInt(TransferRequest.pwm_wrap0) + @backingInt(audio_timing_slice))),
            .data_size = .size_32,
            .ring_size = @fromBackingInt(@intCast(log2_dma_buf_size + 2)),
            .write_addr = @intFromPtr(&PWM.CH4_CC),
        };
    }

    fn encode_sample(val: f32) Sample {
        const val01 = @max(0.0, @min(1.0, val * 0.5 + 0.5));
        return @as(u32, @intFromFloat(val01 * rev0.audio_levels)) << 16;
    }
};

const rev1 = struct {
    const Sample = packed struct(u32) {
        right: i16,
        left: i16,
    };
    const I2S = @import("../drivers/i2s.zig").I2S(i16, .{ .sample_rate = max_sample_rate, .stereo_mode = .packed_samples });
    var i2s: I2S = undefined;

    fn init() void {
        const sd_mode_n = board.rev1.audio.sd_mode_n;
        const din = board.rev1.audio.din;
        const bclk = board.rev1.audio.bclk;
        const lrclk = board.rev1.audio.lrclk;

        sd_mode_n.set_function(.sio);
        sd_mode_n.set_direction(.out);
        sd_mode_n.put(1);

        i2s = I2S.init(board.i2s_pio, .{
            .clock_config = hal.clock_config,
            .clk_pin = bclk,
            .word_select_pin = lrclk,
            .data_pin = din,
        });
    }

    fn set_enabled(enabled: bool) void {
        board.rev1.audio.sd_mode_n.put(@intFromBool(enabled));
    }

    fn stop() void {
        rev1.set_enabled(false);
    }

    fn dma_params() DMA_Params {
        return .{
            .treq = blk: {
                const stride = @backingInt(TransferRequest.pio1_tx0) - @backingInt(TransferRequest.pio0_tx0);
                const base = @backingInt(TransferRequest.pio0_tx0);
                break :blk @fromBackingInt(base + (stride * @backingInt(i2s.pio)) + @backingInt(i2s.sm)); // + 0 for tx
            },
            .data_size = .size_32,
            .ring_size = @fromBackingInt(@intCast(log2_dma_buf_size + 2)),
            .write_addr = @intFromPtr(i2s.pio.sm_get_tx_fifo(i2s.sm)),
        };
    }

    fn encode_sample(val: f32) Sample {
        const mono_val: i16 = @intFromFloat(std.math.clamp(val, -1.0, 1.0) * @as(f32, @floatFromInt(std.math.maxInt(i16))));
        return .{ .left = mono_val, .right = mono_val };
    }
};

// Aliases for the DMA control registers to avoid triggering DMA start.
const DMA_CH1_AL1_CTRL: *volatile @TypeOf(DMA.CH1_CTRL_TRIG) = @ptrCast(&DMA.CH1_AL1_CTRL);
const DMA_CH2_AL1_CTRL: *volatile @TypeOf(DMA.CH1_CTRL_TRIG) = @ptrCast(&DMA.CH2_AL1_CTRL);

const max_sample_rate = 44100;

/// Global volume setting on reset
/// 1.0 is quite loud, we might want to reduce this to 0.5 by default
/// and let users turn it up, maybe by having the cart API allow volume
/// levels 0-2.
const initial_global_volume = 1.0;

var global_volume: f32 = initial_global_volume;
var vol_amplitude: f32 = calc_perceptually_linear_amplitude_for_volume(initial_global_volume);

var sound_type: terry.core0.TrackedStateMachine(enum {
    off,
    sample,
}) = undefined;

const MixState = enum {
    disabled,
    running,
    shutting_down,
};

var mix_idx: u32 = 0;
var mix_state: terry.core0.TrackedStateMachine(MixState) = undefined;

fn mix_audio_samples(comptime impl: type, noalias samples: []const u8, noalias buf: []impl.Sample) linksection(".data") void {
    const samp_mul = vol_amplitude * (2.0 / 255.0);
    const samp_add = -vol_amplitude;
    for (samples, buf) |in, *out| {
        const in_f32: f32 = @floatFromInt(in);
        const vol_adj = @mulAdd(f32, in_f32, samp_mul, samp_add);
        out.* = impl.encode_sample(vol_adj);
    }
}

noinline fn mix_buffer_samples(comptime impl: type, buffer: []impl.Sample) linksection(".data") bool {
    switch (sound_type.state) {
        .off => {}, // mixer shouldn't be in use
        .sample => {
            const abi = @import("../cart/os_abi.zig");
            var mix_pos: usize = 0;
            if (abi.ipc_data.audio_buffer_ptr) |raw_ptr| {
                @branchHint(.likely);
                const samp_ptr: [*]u8 = @ptrCast(raw_ptr);
                const len = abi.ipc_data.audio_buffer_len;
                const tail = abi.ipc_data.audio_buffer_tail;
                const head = abi.ipc_data.audio_buffer_head;
                if (tail <= head or tail + buffer.len < len) {
                    const to_mix = if (tail <= head) @min(head - tail, buffer.len) else buffer.len;
                    mix_audio_samples(impl, (samp_ptr + tail)[0..to_mix], buffer[0..to_mix]);
                    mix_pos += to_mix;
                    abi.ipc_data.audio_buffer_tail = tail + to_mix;
                } else {
                    const to_mix_1 = len - tail;
                    mix_audio_samples(impl, (samp_ptr + tail)[0..to_mix_1], buffer[0..to_mix_1]);
                    mix_pos += to_mix_1;

                    const to_mix_2 = @min(head, buffer.len - mix_pos);
                    mix_audio_samples(impl, samp_ptr[0..to_mix_2], buffer[mix_pos..][0..to_mix_2]);
                    mix_pos += to_mix_2;
                    abi.ipc_data.audio_buffer_tail = to_mix_2;
                }
            }
            if (mix_pos < buffer.len) {
                @memset(buffer[mix_pos..], comptime impl.encode_sample(0.0));
            }
        },
    }
    return true;
}

fn mix_buffer(buffer: *align(64) [dma_buf_size]u32) bool {
    const more_buffers = if (@backingInt(rev.revision) < 1)
        mix_buffer_samples(rev0, @as([*]rev0.Sample, @ptrCast(buffer))[0..dma_buf_size])
    else
        mix_buffer_samples(rev1, @as([*]rev1.Sample, @ptrCast(buffer))[0..dma_buf_size]);

    asm volatile ("dmb" ::: .{ .memory = true });

    return more_buffers;
}

/// Initialise buzzer hardware.
/// SPKR_EN is driven low (muted), the PWM pin is muxed to PWM function.
pub fn init() void {
    sound_type.register("audio.sound_type", .off, @src());
    mix_state.register("audio.mix_state", .disabled, @src());

    if (@backingInt(rev.revision) < 1) {
        rev0.init();
    } else {
        rev1.init();
    }
}

fn set_enabled(enabled: bool) void {
    if (@backingInt(rev.revision) < 1) {
        rev0.set_enabled(enabled);
    } else {
        rev1.set_enabled(enabled);
    }
}

pub fn set_global_volume(in_vol: f32) void {
    const vol = @max(0.0, @min(1.0, in_vol));
    if (global_volume != vol) {
        global_volume = vol;
        update_derived_volume();

        if (sound_type.state != .off) {
            set_enabled(global_volume != 0.0);
        }
    }
}

pub fn poll() void {
    // Check if a buffer needs mixing
    if (mix_state.state != .disabled) {
        const buffer_bit: u32 = @as(u32, 1) << @intCast(mix_idx + 1);
        if (DMA.INTR.raw & buffer_bit != 0) {
            DMA.INTR.write_raw(buffer_bit);

            const z = terry.core0.zone("Audio Mix", @src());
            defer z.end();

            const start = timer.micros();
            const more_buffers = mix_buffer(&audio_dma_buf[mix_idx]);
            if (!more_buffers) {
                mix_state.set_state(.shutting_down, @src());
                // Turn off the continuation after the mixed buffer
                switch (mix_idx) {
                    0 => DMA.CH2_CTRL_TRIG.modify(.{ .EN = 0, .CHAIN_TO = 2 }),
                    1 => DMA.CH1_CTRL_TRIG.modify(.{ .EN = 0, .CHAIN_TO = 1 }),
                    else => unreachable,
                }
            }
            const end = timer.micros();
            fps_overlay.submit_audio_mix_time(start, end, 1000000 * dma_buf_size / max_sample_rate);
            mix_idx = 1 - mix_idx;
        }

        if (mix_state.state == .shutting_down) {
            const ch1 = DMA.CH1_CTRL_TRIG.read();
            const ch2 = DMA.CH2_CTRL_TRIG.read();
            if (ch1.EN == 0 and ch1.BUSY == 0 and ch2.EN == 0 and ch2.BUSY == 0) {
                stop();
            }
        }
    }
}

fn calc_perceptually_linear_amplitude_for_volume(volume: f32) f32 {
    // Adjust the volume on a log scale for perceptual linearity
    // Total range of 50 dB between min and max volume
    const clipped_vol = @max(0.0, @min(1.0, volume));
    const db_range = -50.0;
    const exp_range = db_range / 20.0 * @log(10.0);
    const vol_adjust_exp = exp_range * (1.0 - clipped_vol);
    return @exp(vol_adjust_exp);
}

fn update_derived_volume() void {
    vol_amplitude = calc_perceptually_linear_amplitude_for_volume(global_volume);
}

pub fn stop_buffered() void {
    stop();
}

/// Start a continuous tone at `freq_hz`.
/// Passing 0 is equivalent to calling `stop()`.
/// The speaker enable pin is asserted automatically.
pub fn start_buffered() void {
    begin_stop_DMA();

    sound_type.set_state(.sample, @src());

    setup_ping_pong_DMA() catch unreachable;

    // Then came. The Noise.
    if (rev.revision == .r0) {
        rev0.start_pwm();
    }

    // When the volume is 0, we still need to enable the
    // PWM slices, mixer, etc, because the volume may change
    // while the tone is playing and we need it to start
    // running. However, we turn off the buzzer enable at 0
    // to ensure no sound comes out.
    // set_global_volume() has more handling of this case.
    if (global_volume != 0.0) {
        set_enabled(true);
    }
}

fn dma_params() DMA_Params {
    return if (@backingInt(rev.revision) < 1)
        rev0.dma_params()
    else
        rev1.dma_params();
}

fn setup_ping_pong_DMA() !void {
    if (rev.revision == .r0) {
        try rev0.set_timing_PWM_hz(max_sample_rate);
    }

    finish_stop_DMA();

    mix_idx = 0;
    mix_state.set_state(.running, @src());
    // For simplicty, don't handle very short audio spurts here.
    _ = mix_buffer(&audio_dma_buf[0]);
    _ = mix_buffer(&audio_dma_buf[1]);

    // Configure DMA ch1 to update the duty cycle
    // for pin 9 every time the timing slice wraps,
    // switching between the low part and the high
    // part of the square wave.
    DMA.CH1_READ_ADDR.write(.{ .CH1_READ_ADDR = @intFromPtr(&audio_dma_buf[0]) });
    DMA.CH2_READ_ADDR.write(.{ .CH2_READ_ADDR = @intFromPtr(&audio_dma_buf[1]) });
    // TODO get_registers() doesn't exist until future versions
    //DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    //DMA.CH2_WRITE_ADDR.write(.{ .CH2_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    const params = dma_params();
    DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = params.write_addr });
    DMA.CH2_WRITE_ADDR.write(.{ .CH2_WRITE_ADDR = params.write_addr });

    DMA.CH1_TRANS_COUNT.write(.{ .MODE = .NORMAL, .COUNT = audio_dma_buf[0].len });
    DMA.CH2_TRANS_COUNT.write(.{ .MODE = .NORMAL, .COUNT = audio_dma_buf[1].len });

    // Ch2 first since we don't trigger it, then Ch1 to kick things off.
    DMA_CH2_AL1_CTRL.write(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 0,
        .TREQ_SEL = params.treq,
        .CHAIN_TO = 1, // Chain ping pong to 1
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = params.ring_size,
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = params.data_size,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });

    DMA.CH1_CTRL_TRIG.write(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 0,
        .TREQ_SEL = params.treq,
        .CHAIN_TO = 2, // Chain ping pong to 2
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = params.ring_size,
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = params.data_size,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });
}

fn begin_stop_DMA() void {
    mix_state.set_state(.disabled, @src());
    DMA.CH1_CTRL_TRIG.modify(.{ .EN = 0, .CHAIN_TO = 1 });
    DMA.CH2_CTRL_TRIG.modify(.{ .EN = 0, .CHAIN_TO = 2 });
    DMA.CHAN_ABORT.write(.{ .CHAN_ABORT = 0b110 });
}

fn finish_stop_DMA() void {
    while (DMA.CHAN_ABORT.raw & 0b110 != 0) {
        //DMA.CHAN_ABORT.write_raw(0b110);
    }
    DMA.INTR.write_raw(0b110);
}

/// Stop PWM output and deassert SPKR_EN.
pub fn stop() void {
    begin_stop_DMA();
    if (@backingInt(rev.revision) < 1) {
        rev0.stop();
    } else {
        rev1.stop();
    }
    sound_type.set_state(.off, @src());
}

/// Reset the audio module for a new cart
pub fn reset() void {
    stop();
    global_volume = initial_global_volume;
    vol_amplitude = comptime calc_perceptually_linear_amplitude_for_volume(initial_global_volume);
}

const log2_dma_buf_size: u32 = 9; // 512 samples, about 12 mS of audio at 44.1kHz
const dma_buf_size: u32 = 1 << log2_dma_buf_size;
var audio_dma_buf: [2][dma_buf_size]u32 align(dma_buf_size * @sizeOf(u32)) = undefined;
