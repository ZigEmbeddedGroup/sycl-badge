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



// Buzzer tone playback: kernel plays tones requested via CART_TONE (non-blocking)
var tone_stop_at_us: u64 = 0; // 0 = no active tone

var out_val: bool = false;
var is_sounding: bool = false;

const buzzer_timing_irq_mask: u32 = @as(u32, 1) << @intCast(@intFromEnum(audio_timing_slice));

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
    // board.buzzer_pwm.set_function(.sio);
    // board.buzzer_pwm.set_direction(.out);
    // board.buzzer_pwm.put(0);
}

pub fn poll() void {
    if (is_sounding) {
        // Interrupt abuse >:(
        if (PWM.INTR.raw & buzzer_timing_irq_mask != 0) {
            PWM.INTR.write_raw(buzzer_timing_irq_mask);
            out_val = !out_val;
            //board.buzzer_pwm.put(@intFromBool(out_val));
            const level: u16 = if (out_val) 250 else 0;
            buzzer_pwm_ch.set_level(level);
        }

        // Stop buzzer when tone duration expires (non-blocking CART_TONE playback)
        if (tone_stop_at_us != 0 and timer.micros() >= tone_stop_at_us) {
            stop();
            tone_stop_at_us = 0;
        }
    }
}

/// Enable or disable the speaker amplifier without changing the PWM output.
fn setEnable(enabled: bool) void {
    board.buzzer_enable.put(@intFromBool(enabled));
}

/// Start a continuous tone at `freq_hz`.
/// Passing 0 is equivalent to calling `stop()`.
/// The speaker enable pin is asserted automatically.
pub fn tone(freq_hz: f32, in_duration_sec: f32) void {
    const duration_sec = if (in_duration_sec == -1.0)
            60 * 60 * 60 // the number of the beats
        else @max(0.0, in_duration_sec);
    const duration_us: u64 = @intFromFloat(duration_sec * 1000000.0 + 0.5);
    tone_stop_at_us = timer.micros() + duration_us;

    if (freq_hz == 0 or duration_sec <= 0.0) {
        stop();
        return;
    }

    // A piano ranges from 27.5 Hz to 4186 Hz, so for the square wave generator
    // clock we need to support a pretty wide range with reasonable accuracy.
    // The possible source clocks are 8.4 fractional divs of the sys clock,
    // or 0 for a max div of 256
    //
    // Max Freq = Clk Rate * 16 / 65536 / N
    // N = ceil(Clk Rate * 16 / 65536 / Freq)
    // Ticks = round(Clk Rate * 16 / N / Freq)

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

    // Then came. The Noise.
    audio_timing_slice.set_phase_correct(use_centered_mode);
    audio_timing_slice.set_clk_div(@intCast(clk_div_int >> 4), @intCast(clk_div_int & 0xF));
    audio_timing_slice.set_wrap(@intCast(wrap_int));
    audio_timing_slice.enable();

    buzzer_pwm_ch.set_level(0);
    buzzer_pwm_slice.enable();

    is_sounding = true;
    PWM.INTR.write_raw(buzzer_timing_irq_mask);

    setEnable(true);
}

/// Stop PWM output and deassert SPKR_EN.
pub fn stop() void {
    setEnable(false);
    buzzer_pwm_slice.disable();
    audio_timing_slice.disable();
    board.buzzer_pwm.put(0);
    out_val = false;
    is_sounding = false;
}
