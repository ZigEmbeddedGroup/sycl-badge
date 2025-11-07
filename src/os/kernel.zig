/// SYCL Badge OS Kernel
/// Main entry point for os
const std = @import("std");

// Import drivers and sys modules
const uart = @import("drivers/uart.zig");
const gpio = @import("drivers/gpio.zig");
const usb = @import("drivers/usb.zig");

/// Kernel entry point called from boot.S
/// This is the C-callable entry point that boot code jumps to
export fn kernel_main(r0: u32, r1: u32, atags: u32) callconv(.C) noreturn {
    _ = r0;
    _ = r1;
    _ = atags;

    // Init hardware
    initHardware();

    // Print boot message
    uart.println("SYCL Badge OS v0.1");
    uart.println("Booting on RP2350...");
    uart.puts("\r\n");

    // Run main kernel loop
    kernelMain();
}

/// Init all hardware subsystems
fn initHardware() void {
    // Init UART for debug output
    uart.init();

    // TODO: Init other peripherals
    // - Timers
    // - DMA
    // - USB
    // - etc.
}

/// Main kernel loop
fn kernelMain() noreturn {
    uart.println("Kernel initialized. Entering main loop.");
    uart.println("Echo mode: Type characters to see them echoed back.");
    uart.puts("\r\n> ");

    // Simple echo loop for now
    // TODO: replace with a proper scheduler and task management
    while (true) {
        const c = uart.getc();

        // Echo the character
        uart.putc(c);

        // Add newline on enter
        if (c == '\r' or c == '\n') {
            uart.putc('\n');
            uart.puts("> ");
        }
    }
}

/// Panic handler required by Zig runtime
/// Called when an unrecoverable error occurs
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;

    // Try to output panic message if UART is available
    uart.puts("\r\n\r\n*** KERNEL PANIC ***\r\n");
    uart.puts("Error: ");
    uart.puts(msg);
    uart.puts("\r\n");

    // Hang forever
    while (true) {
        asm volatile ("wfe"); // Wait for event (low power)
    }
}
