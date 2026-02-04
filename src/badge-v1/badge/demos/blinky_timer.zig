const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const timer = hal.timer;
const gclk = hal.clocks.gclk;

const led_pin = microzig.board.D13;

pub fn main() !void {
    // Initialize pins
    led_pin.set_dir(.out);

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    timer.init();
    while (true) {
        led_pin.toggle();
        timer.delay_us(1 * std.time.us_per_s);
    }
}
