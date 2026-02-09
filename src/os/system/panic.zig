/// Panic handler for kernel
const std = @import("std");
const microzig = @import("microzig");
const multicore = @import("multicore.zig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;
const uart = @import("../drivers/uart.zig");
const timer = @import("../drivers/timer.zig");
const badge = microzig.board;

const led = badge.led_pin;

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    // Ensure LED is configured
    led.set_function(.sio);
    led.set_direction(.out);

    // Blink fast briefly to indicate panic
    var i: usize = 0;
    while (i < 15) : (i += 1) {
        uart.println("PANIC!");
        if (message.len > 0) {
            uart.println(message);
        }
        led.put(1);
        timer.sleep_ms(50);
        led.put(0);
        timer.sleep_ms(50);
    }

    // Try to reboot
    const SCB_BASE = 0xE000ED00;
    const AIRCR = @as(*volatile u32, @ptrFromInt(SCB_BASE + 0x0C));

    microzig.cpu.dsb();
    AIRCR.* = 0x05FA0004; // System Reset Request
    microzig.cpu.dsb();

    // Loop forever if reset fails
    while (true) {
        led.put(1);
        timer.sleep_ms(50);
        led.put(0);
        timer.sleep_ms(50);
        microzig.cpu.wfi();
    }
}
