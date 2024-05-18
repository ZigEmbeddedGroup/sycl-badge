const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const gclk = hal.clocks.gclk;
const mclk = hal.clocks.mclk;
const timer = hal.timer;

const adc0 = hal.adc.num(0);

const board = microzig.board;
const led_pin = microzig.board.A5_D13;

pub fn main() !void {
    // enable pins
    led_pin.set_dir(.out);
    microzig.board.A6_LIGHT.set_mux(.B);
    microzig.board.A7_VCC.set_mux(.B);

    // enable clocks
    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });
    gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK1);
    gclk.set_peripheral_clk_gen(.GCLK_ADC0, .GCLK1);
    mclk.set_apb_mask(.{
        .TC0 = .enabled,
        .TC1 = .enabled,
        .ADC0 = .enabled,
    });

    timer.init();

    adc0.init(.DIV16);
    adc0.set_input(.AIN6, .GND, .single_ended, .stop);
    adc0.enable();
    var reading: u12 = 0;
    reading = reading;
    while (true) {
        timer.start_delay_us(@as(u32, ~reading));
        led_pin.write(.high);
        adc0.start_conversion();
        timer.finish_delay();

        timer.start_delay_us(@as(u32, reading));
        led_pin.write(.low);
        adc0.wait_for_result();
        reading = @intCast(adc0.get_result());
        timer.finish_delay();
    }
}

const ADC0 = microzig.chip.peripherals.ADC0;
const NVMCTRL = struct {
    pub const SW0: *volatile microzig.chip.types.peripherals.FUSES.SW0_FUSES = @ptrFromInt(0x00800080);
};
