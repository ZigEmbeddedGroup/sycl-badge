const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const gclk = hal.clocks.gclk;
const mclk = hal.clocks.mclk;
const timer = hal.timer;

const adc0 = hal.adc.num(0);

const board = microzig.board;
const led_pin = microzig.board.D13;
const light_sensor_pin = microzig.board.A7_LIGHT;

pub fn main() !void {
    // enable pins
    led_pin.set_dir(.out);
    light_sensor_pin.set_mux(.B);

    // enable clocks
    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    mclk.set_apb_mask(.{ .ADC0 = .enabled });
    gclk.set_peripheral_clk_gen(.GCLK_ADC0, .GCLK0);

    // configure ADC
    adc0.init();
    timer.init();
    while (true) {
        const reading = adc0.single_shot_blocking(.AIN6);

        led_pin.write(.high);
        timer.delay_us(@as(u32, 100) * reading);

        led_pin.write(.low);
        timer.delay_us(@as(u32, 100) * reading);
    }
}

fn delay_count(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {}
}
