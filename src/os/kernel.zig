/// SYCL Badge OS Kernel
/// Main entry point for os
const std = @import("std");

// Import drivers and sys modules
const uart = @import("drivers/uart.zig");
const gpio = @import("drivers/gpio.zig");
const usb = @import("drivers/usb.zig");

/// Main entry point required by MicroZig
pub fn main() noreturn {
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
    // Init UART
    uart.init();
    uart.println("UART initialized");

    // Init GPIO subsystem
    gpio.init();
    uart.println("GPIO initialized");

    // Init LED on GPIO 25
    gpio.initLED();
    gpio.setLED(true); // Turn on LED to show we're alive
    uart.println("LED initialized (GPIO 25)");

    // Init USB CDC for program loading
    usb.init() catch {
        uart.println("Warning: USB init failed");
        uart.println("Continuing with UART only...");
    };
    uart.println("USB CDC initialized (if available)");
}

/// Main kernel loop
fn kernelMain() noreturn {
    uart.println("Kernel initialized. Entering main loop.");
    uart.println("Echo mode: Type characters via UART or USB CDC");
    uart.puts("\r\n> ");

    var led_state: bool = true;
    var iteration: u32 = 0;

    // Main loop: process USB events and echo input
    while (true) {
        // Process USB events (required for USB to work)
        usb.poll();
        _ = usb.send("test");

        // Blink LED every 100000 iterations to show we're alive
        iteration += 1;
        if (iteration % 100000 == 0) {
            led_state = !led_state;
            gpio.setLED(led_state);
        }

        // Check for UART input (non-blocking would be better but keeping it simple)
        // Note: This will block if nothing is available
        // TODO: Implement non-blocking UART reads

        // For now, just show USB status periodically
        if (iteration % 1000000 == 0) {
            if (usb.isConnected()) {
                uart.println("\r\n[USB connected]");
            } else {
                uart.println("\r\n[USB disconnected]");
            }
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
