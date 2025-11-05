// imports
const std = @import("std");
const microzig = @import("microzig");

/// Main kernel entry point - called by boot.S
// Exported with C calling convention so assembly (boot.S) can call it reliably.
// Also `pub` so other Zig code can reference it if desired.
pub export fn kernel_main() callconv(.C) noreturn {
    initSystem();
    initScheduler();
    // Main function which runs forever and doesn't return anything
    while (true) {

    }
}

fn initSystem() void {
    // we need to add GPIO, uart, timers, and anything else that needs to be initialized
    microzig.init();
    microzig.hal.uart.initDefaultUart();
    microzig.hal.gpio.initDefaultGpio();
    microzig.hal.timer.initDefaultTimer();
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
