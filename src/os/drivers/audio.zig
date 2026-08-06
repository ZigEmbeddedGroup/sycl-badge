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
const hal = microzig.hal;
const pwm = hal.pwm;
const board = microzig.board;
const PWM = microzig.chip.peripherals.PWM;
const DMA = microzig.chip.peripherals.DMA;
const interrupt = microzig.interrupt;

const std = @import("std");

const timer = @import("timer.zig");
const fps_overlay = @import("../system/fps_overlay.zig");

// Aliases for the DMA control registers to avoid triggering DMA start.
const DMA_CH1_AL1_CTRL: *volatile @TypeOf(DMA.CH1_CTRL_TRIG) = @ptrCast(&DMA.CH1_AL1_CTRL);
const DMA_CH2_AL1_CTRL: *volatile @TypeOf(DMA.CH2_CTRL_TRIG) = @ptrCast(&DMA.CH2_AL1_CTRL);

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
comptime { std.debug.assert(buzzer_sys_clk_hz == audio_levels * audio_pwm_cycle_hz * buzzer_pwm_clk_div); }

/// PWM slice number for GPIO9 (slice = pin / 2 = 9 / 2 = 4).
const buzzer_pwm_slice: pwm.Slice = @enumFromInt(4);
const buzzer_pwm_ch = pwm.Pwm{ .slice_number = @intFromEnum(buzzer_pwm_slice), .channel = .b };

/// Separate PWM slice used for wave timing control
const audio_timing_slice: pwm.Slice = @enumFromInt(5);

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
var mix_ready: u32 = 0;
var mix_enabled: bool = false;
var mix_request_time: [2]u64 = .{ 0, 0 };
var mix_slow: bool = false;

fn encode_sample(val: f32) u32 {
    const val01 = @max(0.0, @min(1.0, val * 0.5 + 0.5));
    return @as(u32, @intFromFloat(val01 * audio_levels)) << 16;
}

var period_per_sample: f32 = 0;
var phase: f32 = 0;
fn mix_audio_sawtooth(noalias buf: []u32) void {
    for (buf, 0..) |*sample, i| {
        const f: f32 = @floatFromInt(i);
        const samp_phase = phase + period_per_sample * f;
        const value = (samp_phase - @trunc(samp_phase)) * 2.0 - 1.0;
        const vol_adj = value * vol_amplitude;
        sample.* = encode_sample(vol_adj);
    }
    phase += @as(f32, @floatFromInt(buf.len)) * period_per_sample;
    phase = phase - @trunc(phase);
}

fn mix_audio_triangle(noalias buf: []u32) void {
    for (buf, 0..) |*sample, i| {
        const f: f32 = @floatFromInt(i);
        const samp_phase = phase + period_per_sample * f;
        const saw_val = (samp_phase - @trunc(samp_phase)) * 2.0 - 1.0;
        const tri_val = @abs(saw_val) * 2.0 - 1.0;
        const vol_adj = tri_val * vol_amplitude;
        sample.* = encode_sample(vol_adj);
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
            @memset(buffer, comptime encode_sample(0.0));
            return false;
        }
    } else dma_buf_size;

    switch (sound_type) {
        .off, .square => {}, // mixer shouldn't be in use
        .sawtooth => mix_audio_sawtooth(buffer[0..samples_to_mix]),
        .triangle => mix_audio_triangle(buffer[0..samples_to_mix]),
        .sample => {
            // TODO sample mixing
        },
    }

    if (samples_to_mix < dma_buf_size) {
        @memset(buffer[samples_to_mix..], comptime encode_sample(0.0));
        return false;
    }

    return true;
}

const INTS = &DMA.INTS1;
const INTE = &DMA.INTE1;

pub fn interrupt_DMA_1() callconv(.c) void {
    const int_bits = INTS.raw;
    var handled_bits: u32 = 0;

    if (int_bits & 0b010 != 0) {
        handled_bits |= 0b010;
        mix_ready |= 0b010;
        mix_request_time[0] = timer.micros();
        // Detect slow mixing
        if (mix_idx != 1) {
            mix_slow |= mix_enabled;
        }
    }

    if (int_bits & 0b100 != 0) {
        handled_bits |= 0b100;
        mix_ready |= 0b100;
        mix_request_time[1] = timer.micros();
        // Detect slow mixing
        if (mix_idx != 0) {
            mix_slow |= mix_enabled;
        }
    }

    INTS.write_raw(handled_bits);
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
    // Enable pin: SIO output, start disabled
    board.buzzer_enable.set_function(.sio);
    board.buzzer_enable.set_direction(.out);
    board.buzzer_enable.put(0);

    // Audio pin: hand control to the PWM peripheral
    board.buzzer_pwm.set_function(.pwm);

    buzzer_pwm_slice.set_clk_div(@intCast(buzzer_pwm_clk_div), 0);
    buzzer_pwm_slice.set_wrap(@intCast(audio_levels));

    buzzer_pwm_ch.set_level(0);
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
            board.buzzer_enable.put(@intFromBool(global_volume != 0.0));
        }
    }
}

pub fn poll() void {
    // Check if a buffer needs mixing
    if (mix_enabled) {
        const buffer_bit: u32 = @as(u32, 1) << @intCast(mix_idx + 1);
        if (mix_ready & buffer_bit != 0) {
            mix_ready &= ~buffer_bit;
            const start = timer.micros();
            const more_buffers = mix_buffer(&audio_dma_buf[mix_idx]);
            std.mem.doNotOptimizeAway(&audio_dma_buf[mix_idx]);
            if (!more_buffers) {
                // Turn off the continuation after the mixed buffer
                switch(mix_idx) {
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
                else => { stop(); return; }
            };
        },
    }

    // Then came. The Noise.
    audio_timing_slice.enable();
    buzzer_pwm_slice.enable();

    // When the volume is 0, we still need to enable the
    // PWM slices, mixer, etc, because the volume may change
    // while the tone is playing and we need it to start
    // running. However, we turn off the buzzer enable at 0
    // to ensure no sound comes out.
    // set_global_volume() has more handling of this case.
    if (global_volume != 0.0) {
        board.buzzer_enable.put(1);
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

    if (clk_div > (1<<13)) {
        // The target frequency is too slow to reproduce
        return error.FrequencyTooSlow;
    }

    var wrap_ticks = clk_rate * 16.0 / clk_div / hz;

    // Centered mode allows another 2x divider on the clock
    var use_centered_mode = false;
    if (clk_div > (1<<12)) {
        clk_div = @ceil(clk_div / 2.0);
        wrap_ticks = wrap_ticks / 2.0;
        use_centered_mode = true;
    }
    wrap_ticks = @max(1.0, @round(wrap_ticks));

    const clk_div_int: u32 = if (clk_div == 256) 0 else @intFromFloat(clk_div);
    const wrap_int: u32 = @intFromFloat(wrap_ticks - 1.0);

    audio_timing_slice.set_phase_correct(use_centered_mode);
    audio_timing_slice.set_clk_div(@intCast(clk_div_int >> 4), @intCast(clk_div_int & 0xF));
    audio_timing_slice.set_wrap(@intCast(wrap_int));
}

fn setup_audio_sample_DMA(duration_sec: f32, frequency: f32, sample: AudioSample) !void {
    const sample_hz = frequency * sample.samples_per_fundamental;

    try set_timing_PWM_hz(sample_hz);

    finish_stop_DMA();

    // Disable DMA interrupts
    INTE.write_raw(INTE.raw & ~@as(u32, 0b110));

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
    const TreqEnum = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).TREQ_SEL);
    const RingEnum = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).RING_SIZE);
    DMA.CH1_CTRL_TRIG.modify(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 1, // No interrupts
        .TREQ_SEL = @as(TreqEnum, @enumFromInt(@intFromEnum(TreqEnum.pwm_wrap0) + @intFromEnum(audio_timing_slice))),
        .CHAIN_TO = 1, // Chain to self, meaning disable
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = @as(RingEnum, @enumFromInt(sample.wrap_values_bits + 2)), // Wrap every 2 values / 8 bytes
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = .size_32,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });
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

    // Clear and enable DMA interrupts
    INTS.write_raw(0b110);
    INTE.write_raw(INTE.raw | 0b110);

    // For simplicty, don't handle very short audio spurts here.
    _ = mix_buffer(&audio_dma_buf[0]);
    _ = mix_buffer(&audio_dma_buf[1]);
    mix_idx = 0;
    mix_enabled = true;

    // Configure DMA ch1 to update the duty cycle
    // for pin 9 every time the timing slice wraps,
    // switching between the low part and the high
    // part of the square wave.
    DMA.CH1_READ_ADDR.write(.{ .CH1_READ_ADDR = @intFromPtr(&audio_dma_buf[0]) });
    DMA.CH2_READ_ADDR.write(.{ .CH2_READ_ADDR = @intFromPtr(&audio_dma_buf[1]) });
    // TODO get_registers() doesn't exist until future versions
    //DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    //DMA.CH2_WRITE_ADDR.write(.{ .CH2_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&PWM.CH4_CC) });
    DMA.CH2_WRITE_ADDR.write(.{ .CH2_WRITE_ADDR = @intFromPtr(&PWM.CH4_CC) });
    DMA.CH1_TRANS_COUNT.write(.{ .MODE = .NORMAL, .COUNT = audio_dma_buf[0].len });
    DMA.CH2_TRANS_COUNT.write(.{ .MODE = .NORMAL, .COUNT = audio_dma_buf[1].len });
    const TreqEnum = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).TREQ_SEL);

    // Ch2 first since we don't trigger it, then Ch1 to kick things off.
    const RingEnum2 = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH2_CTRL_TRIG).underlying_type).RING_SIZE);
    DMA_CH2_AL1_CTRL.modify(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 0,
        .TREQ_SEL = @as(TreqEnum, @enumFromInt(@intFromEnum(TreqEnum.pwm_wrap0) + @intFromEnum(audio_timing_slice))),
        .CHAIN_TO = 1, // Chain ping pong to 1
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = @as(RingEnum2, @enumFromInt(log2_dma_buf_size + 2)), // Wrap to restart DMA
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = .size_32,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });

    const RingEnum1 = @TypeOf(std.mem.zeroes(@TypeOf(DMA.CH1_CTRL_TRIG).underlying_type).RING_SIZE);
    DMA.CH1_CTRL_TRIG.modify(.{
        .SNIFF_EN = 0,
        .BSWAP = 0,
        .IRQ_QUIET = 0,
        .TREQ_SEL = @as(TreqEnum, @enumFromInt(@intFromEnum(TreqEnum.pwm_wrap0) + @intFromEnum(audio_timing_slice))),
        .CHAIN_TO = 2, // Chain ping pong to 2
        .RING_SEL = 0, // Wrap reads
        .RING_SIZE = @as(RingEnum1, @enumFromInt(log2_dma_buf_size + 2)), // Wrap to restart DMA
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = .size_32,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });
}

fn begin_stop_DMA() void {
    mix_enabled = false;
    DMA.CH1_CTRL_TRIG.modify(.{ .EN = 0 });
    DMA.CH2_CTRL_TRIG.modify(.{ .EN = 0 });
    DMA.CHAN_ABORT.write(.{ .CHAN_ABORT = 0b110 });
}

fn finish_stop_DMA() void {
    while (DMA.CHAN_ABORT.raw & 0b110 != 0b110) {
        DMA.CHAN_ABORT.write_raw(0b110);
    }
    mix_ready = 0;
}

/// Stop PWM output and deassert SPKR_EN.
pub fn stop() void {
    board.buzzer_enable.put(0);
    begin_stop_DMA();
    buzzer_pwm_slice.disable();
    audio_timing_slice.disable();
    board.buzzer_pwm.put(0);
    sound_type = .off;
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
