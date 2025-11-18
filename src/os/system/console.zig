/// Console system for SYCL Badge OS
/// Handles line buffering, command parsing, and interactive shell
const std = @import("std");
const usb = @import("../drivers/usb.zig");
const uart = @import("../drivers/uart.zig");
const timer = @import("../drivers/timer.zig");
const gpio = @import("../drivers/gpio.zig");

// Console Configuration
const MAX_LINE_LENGTH = 256; // Maximum length of input line (max chars allowed before hitting enter)
const MAX_ARGS = 8; // Maximum number of command arguments
const PROMPT = "SYCL> "; // Text shown before input

// Line Buffer State
var line_buffer: [MAX_LINE_LENGTH]u8 = undefined; // Stores characters typed by user
var line_length: usize = 0;
var echo_enabled: bool = true; // Echoing chars back

// Command Handler Type
// CommandFn - function pointer type taking arguements and returning nada
pub const CommandFn = *const fn (args: []const []const u8) void;


// Command Structure
pub const Command = struct {
    name: []const u8, 
    description: []const u8,
    handler: CommandFn, // function this cmd calls
};

// Command Registry
const commands = [_]Command{
    .{ .name = "help", .description = "Show available commands", .handler = cmdHelp },
    .{ .name = "version", .description = "Show OS version", .handler = cmdVersion },
    .{ .name = "uptime", .description = "Show time since boot", .handler = cmdUptime },
    .{ .name = "echo", .description = "Echo arguments back", .handler = cmdEcho },
    .{ .name = "led", .description = "Control LED (on/off/toggle)", .handler = cmdLed },
    .{ .name = "clear", .description = "Clear terminal screen", .handler = cmdClear },
    .{ .name = "reboot", .description = "Reboot the system", .handler = cmdReboot },
};

// Unified Console Output (sends to both USB and UART)
var print_buffer: [512]u8 = undefined;

/// Print formatted string to console (USB + UART)
pub fn printf(comptime fmt: []const u8, args: anytype) void {
    const text = std.fmt.bufPrint(&print_buffer, fmt, args) catch return;
    print(text);
}

/// Print string to console (USB + UART)
pub fn print(text: []const u8) void {
    _ = usb.send(text);
    uart.puts(text);
}

/// Print string with newline
pub fn println(text: []const u8) void {
    print(text);
    print("\r\n");
}

/// Show the prompt
pub fn showPrompt() void {
    print(PROMPT);
}

/// Console Initialization
pub fn init() void {
    line_length = 0;

    println("");
    println("========================================");
    println("  SYCL Badge OS v0.1.0");
    println("  RP2350 Console");
    println("========================================");
    println("Type 'help' for available commands");
    println("");
    showPrompt();
}

/// Input Processing
/// Call this frequently from main loop
pub fn processInput() void {
    var rx_buffer: [64]u8 = undefined;

    // Try to receive data from USB (non-blocking)
    const bytes_read = usb.receive(&rx_buffer, 0);
    if (bytes_read == 0) return;

    // Process each received character
    for (rx_buffer[0..bytes_read]) |byte| {
        processChar(byte);
    }
}

fn processChar(char: u8) void {
    switch (char) {
        '\r', '\n' => {
            // Enter key - echo newline and process the line
            if (echo_enabled) {
                print("\r\n");
            }

            // Process the buffered line if not empty
            if (line_length > 0) {
                // Echo back what was typed (for testing)
                printf("You typed: {s}\r\n", .{line_buffer[0..line_length]});

                // Reset the line buffer for next input
                line_length = 0;
            }

            showPrompt();
        },

        0x7F, 0x08 => {
            // Backspace or Delete
            if (line_length > 0) {
                line_length -= 1;
                if (echo_enabled) {
                    // Send backspace sequence: BS + Space + BS
                    print("\x08 \x08");
                }
            }
        },

        0x03 => {
            // Ctrl+C - cancel current line
            line_length = 0;
            print("^C\r\n");
            showPrompt();
        },

        0x20...0x7E => {
            // Printable characters
            if (line_length < MAX_LINE_LENGTH - 1) {
                line_buffer[line_length] = char;
                line_length += 1;

                if (echo_enabled) {
                    print(&.{char});
                }
            } else {
                // Buffer full - beep
                print("\x07"); // BEL character
            }
        },

        else => {
            // Ignore other control characters
        },
    }
}
