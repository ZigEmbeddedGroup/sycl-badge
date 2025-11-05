// imports
const std = @import("std");
const microzig = @import("microzig");

// MicroZig expects a pub fn main() as the entry point (this is if we don't use our own boot.S and linker.ld)
pub fn main() noreturn {
    initSystem();
    initScheduler();
    // Main OS loop
    while (true) {
        // TODO: Task scheduler, process management, etc.
    }
}

fn initSystem() void {
    // Initialize system peripherals using microzig HAL
    // microzig has:
    // - microzig.chip: RP2350 register definitions
    // - microzig.hal: High-level hardware abstraction
    // - microzig.board: Board-specific pins/config

    // TODO: Initialize GPIO, UART, timers, etc.
    _ = microzig;
    _ = microzig.hal;
    _ = microzig.chip;
    _ = microzig.board;
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
