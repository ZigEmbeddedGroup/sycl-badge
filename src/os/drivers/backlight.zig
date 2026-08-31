/// Backlight brightness for the SYCL Badge V2 display.
/// GPIO16 switches the panel's LED cathodes, so a PWM duty cycle sets brightness.
const microzig = @import("microzig");
const board = microzig.board;
const pwm = microzig.hal.pwm;

/// GPIO16 is on PWM slice 0, channel A. The mux repeats its PWM slots every 16
/// pins below GPIO32, so the slice is (16 >> 1) & 7, not 16 / 2.
const backlight_slice: pwm.Slice = @enumFromInt(0);
const backlight_ch = pwm.Pwm{ .slice_number = 0, .channel = .a };

/// 1 kHz carrier: 125 MHz / clk_div / (period + 1). Too fast and the LED driver
/// cannot follow it and stays dark.
const clk_div = 2;
const period = 62499;

/// Full brightness is more light than the panel's contrast can hold back: blacks
/// lift and the bright end of the range crowds together.
pub const default_level: u8 = 220;

/// Take GPIO16 from lcd.init, which brings it up as a plain output, and dim it.
pub fn init() void {
    set(default_level);
}

/// 0 is off, 255 is full brightness.
///
/// Configures the slice from scratch each time rather than only the compare
/// value, because stopping a cart runs gpio.resetCartPWM, which disables all 12
/// slices. Re-asserting the pin function matters for the same reason: driving
/// GPIO16 as a plain output takes the pad back and leaves the slice writes inert.
pub fn set(level: u8) void {
    backlight_slice.set_clk_div(clk_div, 0);
    backlight_slice.set_wrap(period);
    // 255 overshoots the period so the output never goes low.
    backlight_ch.set_level(@intCast((@as(u32, level) * (period + 1)) / 255));
    backlight_slice.enable();
    board.BKLT_PWM.set_function(.pwm);
}
