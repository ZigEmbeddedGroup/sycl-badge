/// Panic handler for kernel (We can just copy the panic from kernel.zig and replace it by calling this file)
const std = @import("std");
const microzig = @import("microzig");
const multicore = @import("multicore.zig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;
const timer = @import("../drivers/timer.zig");

const led = gpio.num(25);

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = message;
    while (true) {
        led.put(1);
        timer.sleep_ms(100);
        led.put(0);
        timer.sleep_ms(100);
    }
}
