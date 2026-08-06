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
const cpu = microzig.cpu;
const board = microzig.board;
const PWM = microzig.chip.peripherals.PWM;
const DMA = microzig.chip.peripherals.DMA;

const std = @import("std");
const log = std.log.scoped(.audio);

const timer = @import("timer.zig");
const fps_overlay = @import("../system/fps_overlay.zig");
const terry = @import("../system/terry.zig");
const rev = @import("rev.zig");

// Aliases for the DMA control registers to avoid triggering DMA start.
const DMA_CH1_AL1_CTRL: *volatile @TypeOf(DMA.CH1_CTRL_TRIG) = @ptrCast(&DMA.CH1_AL1_CTRL);
const DMA_CH2_AL1_CTRL: *volatile @TypeOf(DMA.CH1_CTRL_TRIG) = @ptrCast(&DMA.CH2_AL1_CTRL);

/// System clock in Hz (125 MHz for RP2354B)
/// TODO: This isn't quite right, the notes come out
/// somewhere around 400 cents higher than they should
const buzzer_sys_clk_hz: u32 = 125_000_000;
/// Integer pre-divider applied to the system clock before the PWM counter.
const buzzer_pwm_clk_div = 1;
/// Number of possible values in an audio buffer
const audio_levels = 250;
/// Speed of the pwm cycle for controlling volume,
/// too fast for humans to hear (or for the speaker to even create)
const audio_pwm_cycle_hz = 500_000;

const max_sample_rate = 44100;

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

/// Global volume setting on reset
/// 1.0 is quite loud, we might want to reduce this to 0.5 by default
/// and let users turn it up, maybe by having the cart API allow volume
/// levels 0-2.
const initial_global_volume = 1.0;

var global_volume: f32 = initial_global_volume;
var tone_volume: f32 = 1.0;
var vol_amplitude: f32 = calc_perceptually_linear_amplitude_for_volume(initial_global_volume);

var sound_type: enum {
    off,
    square,
    triangle,
    sawtooth,
    sample,
} = .off;

var mix_idx: u32 = 0;
var mix_enabled: bool = false;

fn encode_sample(comptime T: type, val: f32) T {
    return switch (T) {
        u32 => blk: {
            const val01 = @max(0.0, @min(1.0, val * 0.5 + 0.5));
            break :blk @as(u32, @intFromFloat(val01 * audio_levels)) << 16;
        },
        i16 => @intFromFloat(std.math.clamp(val, -1.0, 1.0) * @as(f32, @floatFromInt(std.math.maxInt(i16)))),
        else => @compileError("RIP dude"),
    };
}

var period_per_sample: f32 = 0;
var phase: f32 = 0;
fn mix_audio_sawtooth(comptime T: type, noalias buf: []T) void {
    for (buf, 0..) |*sample, i| {
        const f: f32 = @floatFromInt(i);
        const samp_phase = phase + period_per_sample * f;
        const value = (samp_phase - @trunc(samp_phase)) * 2.0 - 1.0;
        const vol_adj = value * vol_amplitude;
        sample.* = encode_sample(T, vol_adj);
    }
    phase += @as(f32, @floatFromInt(buf.len)) * period_per_sample;
    phase = phase - @trunc(phase);
}

fn mix_audio_triangle(comptime T: type, noalias buf: []T) void {
    for (buf, 0..) |*sample, i| {
        const f: f32 = @floatFromInt(i);
        const samp_phase = phase + period_per_sample * f;
        const saw_val = (samp_phase - @trunc(samp_phase)) * 2.0 - 1.0;
        const tri_val = @abs(saw_val) * 2.0 - 1.0;
        const vol_adj = tri_val * vol_amplitude;
        sample.* = encode_sample(T, vol_adj);
    }
    phase += @as(f32, @floatFromInt(buf.len)) * period_per_sample;
    phase = phase - @trunc(phase);
}

var mixes_remaining: ?u32 = 0;
var final_mix_samples: u32 = 0;
fn mix_buffer(buffer: *align(64) [dma_buf_size]u32) bool {
    const samples_to_mix = if (mixes_remaining) |*rem| blk: {
        if (rem.* > 1) {
            rem.* -= 1;
            break :blk dma_buf_size;
        } else if (rem.* == 1) {
            rem.* = 0;
            break :blk final_mix_samples;
        } else {
            break :blk 0;
        }
    } else dma_buf_size;

    return if (@backingInt(rev.revision) < 1)
        mix_buffer_samples(u32, buffer, samples_to_mix)
    else
        mix_buffer_samples(i16, @as([*]i16, @ptrCast(buffer))[0..dma_buf_size], samples_to_mix);
}

noinline fn mix_buffer_samples(comptime T: type, buffer: []T, samples_to_mix: u32) bool {
    switch (sound_type) {
        .off, .square => {}, // mixer shouldn't be in use
        .sawtooth => mix_audio_sawtooth(T, buffer[0..samples_to_mix]),
        .triangle => mix_audio_triangle(T, buffer[0..samples_to_mix]),
        .sample => {
            // TODO sample mixing
        },
    }

    if (samples_to_mix < buffer.len) {
        @memset(buffer[samples_to_mix..], comptime encode_sample(T, 0.0));
        return false;
    }

    return true;
}

// Needs to be aligned for DMA source
var square_cc_vals: [2]u32 align(8) = undefined;
const square_wave_sample: AudioSample = .{
    .samples_per_fundamental = 2,
    .wrap_values_bits = 1,
    .sample_buf = &square_cc_vals,
};

/// Initialise buzzer hardware.
/// SPKR_EN is driven low (muted), the PWM pin is muxed to PWM function.
pub fn init() void {
    switch (rev.revision) {
        .r0 => {
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
        },
        .r1 => {
            const sd_mode_n = board.rev1.audio.sd_mode_n;
            const din = board.rev1.audio.din;
            const bclk = board.rev1.audio.bclk;
            const lrclk = board.rev1.audio.lrclk;

            sd_mode_n.set_function(.sio);
            sd_mode_n.set_direction(.out);
            sd_mode_n.put(1);

            i2s = I2S.init(.pio0, .{
                .clock_config = hal.clock_config,
                .clk_pin = bclk,
                .word_select_pin = lrclk,
                .data_pin = din,
            });
        },
        .unknown => @panic("Not expected"),
    }
}

fn audio_enable() void {
    switch (rev.revision) {
        .r0 => board.rev0.audio.buzzer_enable.put(@intFromBool(global_volume != 0.0)),
        .r1 => board.rev1.audio.sd_mode_n.put(@intFromBool(global_volume != 0)),
        .unknown => {},
    }
}

pub fn set_global_volume(in_vol: f32) void {
    const vol = @max(0.0, @min(1.0, in_vol));
    if (global_volume != vol) {
        global_volume = vol;
        update_derived_volume();

        if (sound_type == .square) {
            update_square_wave_levels();
        }

        if (sound_type != .off) {
            audio_enable();
        }
    }
}

const start_freq = 220;
const end_freq = 5000;

var freq: u32 = start_freq;
var osc: Oscillator = .init(440);
var ticks: u32 = 0;

pub fn poll() void {
    // Check if a buffer needs mixing
    if (mix_enabled) {
        const buffer_bit: u32 = @as(u32, 1) << @intCast(mix_idx + 1);
        if (DMA.INTR.raw & buffer_bit != 0) {
            DMA.INTR.write_raw(buffer_bit);

            const z = terry.core0.zone("Audio Mix", @src());
            defer z.end();

            const start = timer.micros();
            const more_buffers = mix_buffer(&audio_dma_buf[mix_idx]);
            std.mem.doNotOptimizeAway(&audio_dma_buf[mix_idx]);
            if (!more_buffers) {
                // Turn off the continuation after the mixed buffer
                switch (mix_idx) {
                    0 => DMA.CH2_CTRL_TRIG.modify(.{ .EN = 0 }),
                    1 => DMA.CH1_CTRL_TRIG.modify(.{ .EN = 0 }),
                    else => unreachable,
                }
            }
            const end = timer.micros();
            fps_overlay.submit_audio_mix_time(start, end, 1000000 * dma_buf_size / max_sample_rate);
            mix_idx = 1 - mix_idx;
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
    const volume = global_volume * tone_volume;
    vol_amplitude = calc_perceptually_linear_amplitude_for_volume(volume);
}

fn update_square_wave_levels() void {
    const midpoint = @as(f32, @floatFromInt(audio_levels)) / 2;
    const amplitude = midpoint * vol_amplitude;

    // Square wave
    // Use round and floor to allow amplitudes with an odd number of divisions
    const min_f: f32 = @max(0.0, @min(@round(midpoint - amplitude), audio_levels));
    const max_f: f32 = @max(0.0, @min(@floor(midpoint + amplitude), audio_levels));
    square_cc_vals[0] = @as(u32, @intFromFloat(min_f)) << 16;
    square_cc_vals[1] = @as(u32, @intFromFloat(max_f)) << 16;
}

/// Start a continuous tone at `freq_hz`.
/// Passing 0 is equivalent to calling `stop()`.
/// The speaker enable pin is asserted automatically.
pub fn tone(freq_hz: f32, duration_sec: f32, volume: f32, flags: u32) void {
    board.led_pin.put(0);

    if (freq_hz == 0 or volume <= 0 or (duration_sec != -1.0 and duration_sec <= 0.0)) {
        stop();
        return;
    }

    begin_stop_DMA();

    if (volume != tone_volume) {
        tone_volume = volume;
        update_derived_volume();
    }

    const sample_sel = flags & 0x7;

    switch (sample_sel) {
        0 => {
            update_square_wave_levels();
            setup_audio_sample_DMA(duration_sec, freq_hz, square_wave_sample) catch {
                // This frequency is too slow for us to reproduce, and also probably
                // too slow to hear, so just stop audio.
                stop();
                return;
            };
        },
        else => {
            const sample_freq = @as(comptime_float, audio_levels) * freq_hz;
            const max_freq = max_sample_rate;
            if (sample_freq <= max_freq) {
                period_per_sample = 1.0 / @as(comptime_float, audio_levels);
                setup_ping_pong_DMA(duration_sec, sample_freq) catch {
                    stop();
                    return;
                };
            } else {
                // Too fast, slow it down!
                period_per_sample = freq_hz / max_freq;
                setup_ping_pong_DMA(duration_sec, max_freq) catch unreachable;
            }
            sound_type = switch (sample_sel) {
                1 => .triangle,
                2 => .sawtooth,
                else => {
                    stop();
                    return;
                },
            };
        },
    }

    if (rev.revision == .r0) {
        // Then came. The Noise.
        audio_timing_slice.enable();
        buzzer_pwm_slice.enable();
    }

    // When the volume is 0, we still need to enable the
    // PWM slices, mixer, etc, because the volume may change
    // while the tone is playing and we need it to start
    // running. However, we turn off the buzzer enable at 0
    // to ensure no sound comes out.
    // set_global_volume() has more handling of this case.
    if (global_volume != 0.0) {
        audio_enable();
    }
}

const AudioSample = struct {
    samples_per_fundamental: f32,
    wrap_values_bits: u32,
    sample_buf: [*]const u32,
};

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

fn setup_audio_sample_DMA(duration_sec: f32, frequency: f32, sample: AudioSample) !void {
    if (@backingInt(rev.revision) >= 1)
        return error.NotSupported;

    const sample_hz = frequency * sample.samples_per_fundamental;

    try set_timing_PWM_hz(sample_hz);

    finish_stop_DMA();

    // Configure DMA ch1 to update the duty cycle
    // for pin 9 every time the timing slice wraps,
    // switching between the low part and the high
    // part of the square wave.
    DMA.CH1_READ_ADDR.write(.{ .CH1_READ_ADDR = @intFromPtr(sample.sample_buf) });
    // TODO get_registers() doesn't exist until future versions
    //DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&PWM.CH4_CC) });
    if (duration_sec == -1.0) {
        DMA.CH1_TRANS_COUNT.write(.{
            .MODE = .ENDLESS,
            .COUNT = 1,
        });
    } else {
        const dma_count: u32 = @intFromFloat(@round(duration_sec * sample_hz));
        DMA.CH1_TRANS_COUNT.write(.{
            .MODE = .NORMAL, // Count down and stop
            .COUNT = @intCast(dma_count),
        });
    }

    const params = dma_params();
    const RingEnum = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).RING_SIZE);
    DMA.CH1_CTRL_TRIG.modify(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 1, // No interrupts
        .TREQ_SEL = params.treq,
        .CHAIN_TO = 1, // Chain to self, meaning disable
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = @as(RingEnum, @fromBackingInt(@intCast(sample.wrap_values_bits + 2))), // Wrap every 2 values / 8 bytes
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = params.data_size,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });
}

const TransferRequest = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).TREQ_SEL);
const DMA_DataSize = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).DATA_SIZE);
const DMA_RingSize = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).RING_SIZE);

const DMA_Params = struct {
    treq: TransferRequest,
    data_size: DMA_DataSize,
    ring_size: DMA_RingSize,
    write_addr: u32,
};

fn dma_params() DMA_Params {
    const treq: TransferRequest = if (@backingInt(rev.revision) < 1)
        @fromBackingInt(@intCast(@backingInt(TransferRequest.pwm_wrap0) + @backingInt(audio_timing_slice)))
    else blk: {
        const stride = @backingInt(TransferRequest.pio1_tx0) - @backingInt(TransferRequest.pio0_tx0);
        const base = @backingInt(TransferRequest.pio0_tx0);
        break :blk @fromBackingInt(base + (stride * @backingInt(i2s.pio)) + @backingInt(i2s.sm)); // + 0 for tx
    };

    const data_size: DMA_DataSize = if (@backingInt(rev.revision) < 1)
        .size_32
    else
        .size_16;

    const ring_size: DMA_RingSize = if (@backingInt(rev.revision) < 1)
        @fromBackingInt(@intCast(log2_dma_buf_size + 2))
    else
        @fromBackingInt(@intCast(log2_dma_buf_size + 1));

    const write_addr: u32 = if (@backingInt(rev.revision) < 1)
        @intFromPtr(&PWM.CH4_CC)
    else
        @intFromPtr(i2s.pio.sm_get_tx_fifo(i2s.sm));

    return .{
        .treq = treq,
        .data_size = data_size,
        .ring_size = ring_size,
        .write_addr = write_addr,
    };
}

fn setup_ping_pong_DMA(duration_sec: f32, sample_freq: f32) !void {
    try set_timing_PWM_hz(sample_freq);

    finish_stop_DMA();

    if (duration_sec >= 0) {
        // This can be large enough that we lose precision.
        // The following operations are designed to keep as
        // much precision as possible without using more than
        // 32 bits.
        const total_samples_flt = @as(f64, duration_sec) * @as(f64, sample_freq);
        const total_samples_64: u64 = @intFromFloat(total_samples_flt);
        const total_mixes_64 = (total_samples_64 + dma_buf_size - 1) / dma_buf_size;
        const final_samples: u32 = @intCast(total_samples_64 % dma_buf_size);
        // If the number of mixes overflows a u32, that's hundreds of days.
        // Just call it infinite at that point.
        mixes_remaining = if (total_mixes_64 > ~@as(u32, 0)) null else @intCast(total_mixes_64);
        final_mix_samples = if (final_samples == 0) dma_buf_size else final_samples;
    } else {
        mixes_remaining = null;
        final_mix_samples = dma_buf_size;
    }

    mix_idx = 0;
    mix_enabled = true;
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

    log.info("TREQ_SEL: {}", .{params.treq});

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
    mix_enabled = false;
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
    // TODO: I2S audio
    switch (rev.revision) {
        .r0 => {
            board.rev0.audio.buzzer_enable.put(0);
            begin_stop_DMA();
            buzzer_pwm_slice.disable();
            audio_timing_slice.disable();
            board.rev0.audio.buzzer_pwm.put(0);
            sound_type = .off;
        },
        .r1 => {
            board.rev1.audio.sd_mode_n.put(0);
        },
        .unknown => {},
    }
}

/// Reset the audio module for a new cart
pub fn reset() void {
    stop();
    global_volume = initial_global_volume;
    tone_volume = 1.0;
    vol_amplitude = comptime calc_perceptually_linear_amplitude_for_volume(initial_global_volume);
}

const log2_dma_buf_size: u32 = 9; // 512 samples, about 12 mS of audio at 44.1kHz
const dma_buf_size: u32 = 1 << log2_dma_buf_size;
var audio_dma_buf: [2][dma_buf_size]u32 align(dma_buf_size * @sizeOf(u32)) = undefined;

const Sample = i16;
const I2S = @import("../drivers/i2s.zig").I2S(Sample, .{ .sample_rate = max_sample_rate });
var i2s: I2S = undefined;

pub const FrequencyRatio = packed struct(u16) {
    int: u8,
    frac: u8 = 0,
};

/// The oscillator takes advantage of integer overflow to represent radians as
/// you rotate about a circle. It assumes 32-bit architecture so that maximum
/// precision is achieved with minimum runtime cost.
///
/// The sample rate is known at compile time, and the frequency can be changed
/// at runtime.
const Oscillator = struct {
    phase: u32 = 0,
    delta: u32 = 0,

    const Self = @This();

    pub fn init(frequency: u32) Self {
        return Self{
            .phase = 0,
            .delta = calculate_delta(frequency),
        };
    }

    pub fn reset(self: *Self) void {
        self.phase = 0;
        self.delta = 0;
    }

    fn calculate_delta(frequency: u32) u32 {
        return @as(u32, @intCast((@as(u64, 0x100000000) * frequency) / max_sample_rate));
    }

    pub fn tick(self: *Self) void {
        self.phase +%= self.delta;
    }

    pub fn tick_modulate(self: *Self, comptime T: type, input: T, ratio: FrequencyRatio) void {
        // TODO: calculate Accumulator
        const base = @as(i64, @intCast(self.delta)) * input;
        const mod_delta = ((base * ratio.int) >> @bitSizeOf(T)) +
            ((base * ratio.frac) >> (@bitSizeOf(T) + 8));
        // TODO: will have truncated bits I think
        if (mod_delta < 0)
            self.phase -%= @as(u32, @intCast(-mod_delta))
        else
            self.phase +%= @as(u32, @intCast(mod_delta));
    }

    pub fn set_frequency(self: *Self, frequency: u32) void {
        self.delta = calculate_delta(frequency);
    }

    /// at compile time,
    pub fn set_frequency_float(self: *Self, comptime frequency: f32) void {
        self.delta = comptime phase_delta_from_float(max_sample_rate, frequency);
    }

    fn phase_delta_from_float(frequency: f64) u32 {
        return @as(
            u32,
            @intFromFloat(frequency / @as(f64, @floatFromInt(max_sample_rate)) * std.math.pow(f64, 2, 32)),
        );
    }

    pub fn to_sawtooth(self: Self, comptime T: type) T {
        const UnsignedSample = @Int(.unsigned, @bitSizeOf(T));
        return @as(T, @bitCast(@as(
            UnsignedSample,
            @truncate(self.phase >> 32 - @bitSizeOf(T)),
        )));
    }

    pub fn to_square(self: Self, comptime T: type) T {
        return if (self.delta != 0)
            if (self.phase > (std.math.maxInt(u32) / 2))
                std.math.maxInt(T)
            else
                std.math.minInt(T)
        else
            0;
    }

    pub fn to_sine(self: Self, comptime T: type) T {
        const lut = comptime blk: {
            const samples = 64;

            assert(std.math.isPowerOfTwo(samples), .{});
            var ret: [samples]T = undefined;
            const radian_delta = (2.0 * std.math.pi) / @as(comptime_float, @floatFromInt(samples));

            for (0..samples) |i|
                ret[i] = @as(T, @intFromFloat(@as(f64, @floatFromInt(std.math.maxInt(T))) * @sin(@as(f64, @floatFromInt(i)) * radian_delta)));

            break :blk ret;
        };

        const lut_bits = comptime std.math.log2(lut.len);
        const LutIndex = @Int(.unsigned, lut_bits);
        const x_span = comptime 1 << (32 - lut_bits);

        const y0_index: LutIndex = @as(LutIndex, @intCast(self.phase >> @as(u5, 32 - lut_bits)));
        const y1_index = y0_index +% 1;

        const y0 = lut[y0_index];
        const y1 = lut[y1_index];

        const x0 = @as(u32, y0_index) * x_span;

        const y_span = y1 - y0;

        const x_delta = @as(i32, @intCast(self.phase - x0));
        // TODO: fix overflow here
        const y = y0 + @divFloor(std.math.mulWide(i32, x_delta, y_span), x_span);

        return @as(T, @intCast(y));
    }
};
