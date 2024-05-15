const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gclk = hal.clocks.gclk;
const mclk = hal.clocks.mclk;
const timer = hal.timer;

const spkr_en_pin = microzig.board.SPKR_EN;
const analog_out_pin = microzig.board.A0;
const led_pin = microzig.board.D13;

pub fn main() !void {
    spkr_en_pin.set_dir(.out);
    analog_out_pin.set_dir(.out);
    led_pin.set_dir(.out);

    analog_out_pin.write(.low);
    spkr_en_pin.write(.high);

    mclk.set_apb_mask(.{
        .TC0 = .enabled,
        .TC1 = .enabled,
    });

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK1);

    timer.init();
    while (true) {
        led_pin.toggle();
        analog_out_pin.toggle();
        timer.delay_us(std.time.us_per_ms);
    }
}

fn delay_count(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {}
}
