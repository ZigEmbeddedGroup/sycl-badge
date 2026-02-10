/// SYCL Badge OS - Interrupt Test Kernel
/// Tests interrupt handling with USB CDC character switching
///
/// Debug Output: Use SWD debugger with breakpoints or SWO via TC2030-CTX-NL connector
/// USB Interface: USB CDC for character input/output
///
/// Usage in PuTTY or any serial terminal:
/// - Connect to the USB CDC port
/// - You'll see 'A' printed continuously
/// - Press '1' to switch to printing 'B'
/// - Press '2' to switch to printing 'C'
/// - Press '3' to switch to printing 'D'
/// - Press '0' to go back to printing 'A'
const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;
const board = microzig.board;

const usb = @import("drivers/usb.zig");
const timer = @import("drivers/timer.zig");
const interrupts = @import("system/interrupts.zig");

const led = board.led_pin;

// State variables (volatile for interrupt safety)
var current_char: u8 = 'A';
var char_changed: bool = false;

// USB receive buffer for interrupt handler
var usb_rx_buffer: [64]u8 = undefined;

/// USB interrupt handler
/// This gets called when USB data is available
fn usbInterruptHandler() void {
    // Check for incoming USB data
    const bytes_read = usb.receive(&usb_rx_buffer, 0); // Non-blocking read

    if (bytes_read > 0) {
        // Process the first character received
        const cmd = usb_rx_buffer[0];

        // Switch character based on input
        switch (cmd) {
            '0' => {
                current_char = 'A';
                char_changed = true;
            },
            '1' => {
                current_char = 'B';
                char_changed = true;
            },
            '2' => {
                current_char = 'C';
                char_changed = true;
            },
            '3' => {
                current_char = 'D';
                char_changed = true;
            },
            else => {
                // Echo unknown character back
                var echo_buf: [32]u8 = undefined;
                const echo = std.fmt.bufPrint(&echo_buf, "\r\nUnknown: '{c}' (use 0-3)\r\n", .{cmd}) catch return;
                _ = usb.send(echo);
            },
        }
    }
}

/// Timer interrupt handler
/// This gets called periodically to print the current character
var tick_count: u32 = 0;
fn timerInterruptHandler() void {
    tick_count += 1;

    // Send current character every 100 ticks (adjust rate as needed)
    if (tick_count >= 100) {
        tick_count = 0;

        // Send the current character
        const char_buf = [_]u8{current_char};
        _ = usb.send(&char_buf);
    }
}

pub fn main() !void {
    // Initialize LED
    led.set_function(.sio);
    led.set_direction(.out);
    led.put(1);

    // Initialize USB
    try usb.init();

    // Small delay for USB enumeration
    timer.sleep_ms(1000);

    // Send welcome message over USB
    const welcome =
        \\
        \\========================================
        \\  SYCL Badge OS - Interrupt Test
        \\========================================
        \\Commands:
        \\  0 - Print 'A' continuously
        \\  1 - Print 'B' continuously
        \\  2 - Print 'C' continuously
        \\  3 - Print 'D' continuously
        \\
        \\Starting with 'A'...
        \\
    ;
    _ = usb.send(welcome);


    // NOTE: For a real interrupt-driven implementation, you would:
    // 1. Register the interrupt handlers
    // 2. Enable the appropriate IRQs
    //
    // However, the RP2xxx USB implementation in MicroZig typically uses
    // polling (usb.poll()) rather than interrupts for simplicity.
    //
    // This test will use a hybrid approach:
    // - Polling for USB events (required by HAL)
    // - Simulated "interrupt-like" behavior by checking for data frequently

    var old_time: u64 = timer.micros();
    var blink_time: u64 = timer.micros();
    var print_time: u64 = timer.micros();

    // Main loop
    while (true) {
        // CRITICAL: Poll USB frequently (this is like an interrupt service)
        usb.poll();

        const now = timer.micros();

        // Check for USB data (simulating interrupt handler)
        if (now - old_time > 10_000) { // Every 10ms, check for data
            old_time = now;
            usbInterruptHandler(); // Call our "interrupt" handler
        }

        // Print current character periodically
        if (now - print_time > 500_000) { // Every 500ms
            print_time = now;
            timerInterruptHandler(); // Call our timer "interrupt" handler

            // If character changed, send notification
            if (char_changed) {
                char_changed = false;
                var notify_buf: [64]u8 = undefined;
                const notify = std.fmt.bufPrint(&notify_buf, "\r\n>>> Switched to '{c}' <<<\r\n", .{current_char}) catch "";
                _ = usb.send(notify);
            }
        }

        // Blink LED as heartbeat
        if (now - blink_time > 250_000) { // Every 250ms
            blink_time = now;
            led.toggle();
        }
    }
}

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = message;

    // Rapid blink pattern on panic
    while (true) {
        led.put(1);
        timer.sleep_ms(100);
        led.put(0);
        timer.sleep_ms(100);
    }
}
