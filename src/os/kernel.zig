// imports
const std = @import("std");
const microzig = @import("microzig");
const gpio = microzig.hal.gpio;
const time = microzig.hal.time;

// Pico 2 has LED on GPIO 25
const led_pin = gpio.num(25);

// MicroZig expects a pub fn main() as the entry point
pub fn main() noreturn {
    initSystem();
    initScheduler();

    // Main OS loop - blink LED to show we're alive
    while (true) {
        led_pin.put(1); // Turn LED on
        time.sleep_ms(500);
        led_pin.put(0); // Turn LED off
        time.sleep_ms(500);
    }
}

fn initSystem() void {
    // Initialize system peripherals using microzig HAL

    // Initialize LED pin as output
    led_pin.set_function(.sio);
    led_pin.set_direction(.out);

    // TODO: Initialize UART, timers, etc. for OS features
}

fn initScheduler() void {
    // Initialize the task scheduler
    // this should be a different file?
}

// Panic handler (required by Zig for freestanding)
pub fn panic(msg: []const u8, error_return_trace: ?*anyopaque, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    while (true) {}
}
