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

// Make sure the above values are consistent with the hardware.
// They are all important so we specify them all instead of calculating any of them
comptime { std.debug.assert(buzzer_sys_clk_hz == audio_levels * audio_pwm_cycle_hz * buzzer_pwm_clk_div); }

/// PWM slice number for GPIO9 (slice = pin / 2 = 9 / 2 = 4).
const buzzer_pwm_slice: pwm.Slice = @enumFromInt(4);
const buzzer_pwm_ch = pwm.Pwm{ .slice_number = @intFromEnum(buzzer_pwm_slice), .channel = .b };

/// Separate PWM slice used for wave timing control
const audio_timing_slice: pwm.Slice = @enumFromInt(5);

var global_volume: f32 = 1.0;

var sound_type: enum {
    off,
    square,
} = .off;

var tone_volume: f32 = 0.0;

pub fn interrupt_DMA_0(int_bits: u32) u32 {
    var handled_bits: u32 = 0;
    _ = int_bits;
    _ = &handled_bits;
    return handled_bits;
}

// Needs to be aligned for DMA source
var square_cc_vals: [2]u32 align(8) = undefined;

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

pub fn setGlobalVolume(in_vol: f32) void {
    const vol = @max(0.0, @min(1.0, in_vol));
    if (global_volume != vol) {
        global_volume = vol;
        switch (sound_type) {
            .off => {},
            .square => {
                updateSquareWaveLevels();
            },
        }
    }
}

pub fn poll() void {
    // Leaving this stub for future polling needs
}

/// Enable or disable the speaker amplifier without changing the PWM output.
fn setEnable(enabled: bool) void {
    board.buzzer_enable.put(@intFromBool(enabled));
}

fn calcPerceptuallyLinearAmplitudeScaleForVolume(volume: f32) f32 {
    // Adjust the volume on a log scale for perceptual linearity
    // Total range of 50 dB between min and max volume
    const db_range = -50.0;
    const exp_range = db_range / 20.0 * @log(10.0);
    const vol_adjust_exp = exp_range * (1.0 - volume);
    return @exp(vol_adjust_exp);
}

fn updateSquareWaveLevels() void {
    const volume = global_volume * tone_volume;
    const vol_amplitude = calcPerceptuallyLinearAmplitudeScaleForVolume(volume);

    const midpoint = @as(f32, @floatFromInt(audio_levels)) / 2;
    const amplitude = midpoint * vol_amplitude; // exp scale is more accurate but sq works for now.

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
pub fn tone(freq_hz: f32, duration_sec: f32, volume: f32) void {
    if (freq_hz == 0 or volume <= 0 or (duration_sec != -1.0 and duration_sec <= 0.0)) {
        stop();
        return;
    }

    beginStopDma();

    tone_volume = volume;
    updateSquareWaveLevels();

    // A piano ranges from 27.5 Hz to 4186 Hz, so for the square wave generator
    // clock we need to support a pretty wide range with reasonable accuracy.
    // The possible source clocks are 8.4 fractional divs of the sys clock,
    // or 0 for a max div of 256

    // We need to trigger DMA twice per wavelength
    const trig_hz = freq_hz * 2.0;

    const clk_rate = @as(f32, @floatFromInt(buzzer_sys_clk_hz));
    var clk_div = @ceil(clk_rate * 16.0 / 65536.0 / trig_hz);

    // Can't divide by less than 1.0
    clk_div = @max(16.0, clk_div);

    if (clk_div > (1<<13)) {
        // This frequency is too slow for us to reproduce, and also probably
        // too slow to hear, so just stop audio.
        stop();
        return;
    }

    var wrap_ticks = clk_rate * 16.0 / clk_div / trig_hz;

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

    finishStopDma();

    // Configure DMA ch1 to update the duty cycle
    // for pin 9 every time the timing slice wraps,
    // switching between the low part and the high
    // part of the square wave.
    DMA.CH1_READ_ADDR.write(.{ .CH1_READ_ADDR = @intFromPtr(&square_cc_vals) });
    // TODO get_registers() doesn't exist until future versions
    //DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&buzzer_pwm_slice.get_registers().cc) });
    DMA.CH1_WRITE_ADDR.write(.{ .CH1_WRITE_ADDR = @intFromPtr(&PWM.CH4_CC) });
    if (duration_sec == -1.0) {
        DMA.CH1_TRANS_COUNT.write(.{
            .MODE = .ENDLESS,
            .COUNT = 1,
        });
    } else {
        const dma_count: u32 = @intFromFloat(@round(duration_sec * trig_hz));
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
        .RING_SIZE = @as(RingEnum, @enumFromInt(3)), // Wrap every 2 values / 8 bytes
        .INCR_WRITE_REV = 0,
        .INCR_WRITE = 0,
        .INCR_READ_REV = 0,
        .INCR_READ = 1, // Increment read address
        .DATA_SIZE = .size_32,
        .HIGH_PRIORITY = 1, // Audio is high priority, delays are audible
        .EN = 1,
    });

    // Then came. The Noise.
    sound_type = .square;
    audio_timing_slice.enable();
    buzzer_pwm_slice.enable();
    setEnable(true);
}

fn beginStopDma() void {
    DMA.CHAN_ABORT.write(.{ .CHAN_ABORT = 0b10 });
}

fn finishStopDma() void {
    while (DMA.CH1_CTRL_TRIG.read().BUSY != 0) {}
}

/// Stop PWM output and deassert SPKR_EN.
pub fn stop() void {
    setEnable(false);
    beginStopDma();
    buzzer_pwm_slice.disable();
    audio_timing_slice.disable();
    board.buzzer_pwm.put(0);
    sound_type = .off;
}

/// Reset the audio module for a new cart
pub fn reset() void {
    stop();
    global_volume = 1.0;
}
