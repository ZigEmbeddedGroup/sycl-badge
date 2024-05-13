const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gclk = hal.clocks.gclk;
const timer = hal.timer;

const neopixel_pin = microzig.board.D8_NEOPIX;

const white: u24 = 0xFFA;
const red: u24 = 0x0F0;

pub fn main() !void {
    neopixel_pin.set_dir(.out);

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 1,
    });

    timer.init();
    reset();

    write_color(red);
    write_color(white);
    write_color(red);
    write_color(white);
    write_color(red);

    while (true) {}
}

fn reset() void {
    neopixel_pin.write(.low);
    timer.delay_us(3840);
}

fn write_color(color: u24) void {
    for (0..24) |i| {
        if (color & @as(u24, 1) << @as(u5, @intCast(i)) == 0)
            write_zero()
        else
            write_one();
    }
}

fn write_one() void {
    neopixel_pin.write(.high);
    timer.delay_us(14);
    neopixel_pin.write(.low);
    timer.delay_us(43);
}

fn write_zero() void {
    neopixel_pin.write(.high);
    timer.delay_us(29);
    neopixel_pin.write(.low);
    timer.delay_us(29);
}
