/// Console system for SYCL Badge OS
/// Handles line buffering, command parsing, and interactive shell
const std = @import("std");
const microzig = @import("microzig");
const usb = @import("../drivers/usb.zig");
const uart = @import("../drivers/uart.zig");
const timer = @import("../drivers/timer.zig");
const gpio = @import("../drivers/gpio.zig");

// Console Configuration
const MAX_LINE_LENGTH = 256; // Maximum length of input line (max chars allowed before hitting enter)
const MAX_ARGS = 8; // Maximum number of command arguments
const PROMPT = "SYCL> "; // Text shown before input
const MAX_HISTORY = 10; // Number of commands to remember

// Line Buffer State
var line_buffer: [MAX_LINE_LENGTH]u8 = undefined; // Stores characters typed by user
var line_length: usize = 0;
var cursor_pos: usize = 0; // Current cursor position in line (for left/right arrow)
var echo_enabled: bool = true; // Echoing chars back

// Command History
var history: [MAX_HISTORY][MAX_LINE_LENGTH]u8 = undefined;
var history_lengths: [MAX_HISTORY]usize = [_]usize{0} ** MAX_HISTORY;
var history_count: usize = 0; // Total commands stored
var history_index: usize = 0; // Current position in history (for up/down)
var in_history_mode: bool = false; // Are we browsing history?

// Escape Sequence State Machine
const EscapeState = enum {
    normal,
    escape, // Got ESC (0x1B)
    csi, // Got ESC + [ (Control Sequence Introducer)
};

var escape_state: EscapeState = .normal;
var escape_buffer: [8]u8 = undefined; // Store escape sequence params
var escape_length: usize = 0;

// Command Handler Type
// CommandFn - function pointer type that takes a token iterator
pub const CommandFn = *const fn (iter: *std.mem.TokenIterator(u8, .scalar)) void;

// Command Structure
pub const Command = struct {
    name: []const u8,
    description: []const u8,
    handler: CommandFn, // function this cmd calls
};

// Command Registry
const commands = [_]Command{
    .{ .name = "help", .description = "List available commands", .handler = cmdHelp },
    .{ .name = "led", .description = "Control LED (on/off/toggle)", .handler = cmdLed },
    .{ .name = "uptime", .description = "Show system uptime", .handler = cmdUptime },
    .{ .name = "echo", .description = "Echo arguments back", .handler = cmdEcho },
    .{ .name = "clear", .description = "Clear terminal screen", .handler = cmdClear },
    .{ .name = "history", .description = "Show command history", .handler = cmdHistory },
<<<<<<< HEAD
    .{ .name = "ps", .description = "List running processes (not implemented)", .handler = cmdPs },
=======
    .{ .name = "gpio", .description = "GPIO operations (read/write/toggle/list)", .handler = cmdGpio },
    .{ .name = "reboot", .description = "Restart the system", .handler = cmdReboot },
>>>>>>> fb359aace46eb909d61e5344f55b12029cb6dd06
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
    if (line_length != 0 or cursor_pos != 0) {
        print("\r\n");
    }
    print(PROMPT);
}

/// Console Initialization
pub fn init() void {
    line_length = 0;
    cursor_pos = 0;
    history_count = 0;
    history_index = 0;
    in_history_mode = false;
    escape_state = .normal;
    println("");
    println("========================================");
    println("  SYCL Badge OS v0.1.0");
    println("  RP2350 Console");
    println("========================================");
    println("Type 'help' for available commands");
    showPrompt();
}

/// Input Processing
/// Call this frequently from kernel
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
    // Handle escape sequences (arrow keys, etc.)
    switch (escape_state) {
        .normal => {
            if (char == 0x1B) { // ESC
                escape_state = .escape;
                escape_length = 0;
                return;
            }
        },
        .escape => {
            if (char == '[') {
                escape_state = .csi;
                escape_length = 0;
                return;
            } else {
                // Invalid escape sequence, reset
                escape_state = .normal;
            }
        },
        .csi => {
            // Accumulate escape sequence
            if (escape_length < escape_buffer.len) {
                escape_buffer[escape_length] = char;
                escape_length += 1;
            }

            // Check if sequence is complete (ends with A-Z or a-z or ~)
            if ((char >= 'A' and char <= 'Z') or (char >= 'a' and char <= 'z') or char == '~') {
                handleEscapeSequence(escape_buffer[0..escape_length]);
                escape_state = .normal;
                return;
            }
            return;
        },
    }

    // Normal character processing
    switch (char) {
        '\r', '\n' => {
            if (echo_enabled) {
                print("\r\n");
            }

            if (line_length > 0) {
                // Save to history
                addToHistory(line_buffer[0..line_length]);

                // Process command
                processCommand(line_buffer[0..line_length]);

                // Reset
                line_length = 0;
                cursor_pos = 0;
            }

            in_history_mode = false;
            history_index = history_count;
            showPrompt();
        },

        0x7F, 0x08 => {
            // Backspace - delete character before cursor
            if (cursor_pos > 0) {
                deleteCharAt(cursor_pos - 1);
            }
        },

        0x03 => {
            // Ctrl+C
            line_length = 0;
            cursor_pos = 0;
            in_history_mode = false;
            print("^C\r\n");
            showPrompt();
        },

        0x04 => {
            // Ctrl+D - delete character at cursor (like Delete key)
            if (cursor_pos < line_length) {
                deleteCharAt(cursor_pos);
            }
        },

        0x01 => {
            // Ctrl+A - move to beginning of line
            moveCursorToStart();
        },

        0x05 => {
            // Ctrl+E - move to end of line
            moveCursorToEnd();
        },

        0x0C => {
            // Ctrl+L - clear screen
            print("\x1b[2J\x1b[H");
            showPrompt();
            redrawLine();
        },

        0x20...0x7E => {
            // Printable characters
            insertCharAt(cursor_pos, char);
        },

        else => {
            // Ignore other control characters
        },
    }
}

fn handleEscapeSequence(seq: []const u8) void {
    if (seq.len == 0) return;

    const final_char = seq[seq.len - 1];

    switch (final_char) {
        'A' => handleUpArrow(), // Up arrow
        'B' => handleDownArrow(), // Down arrow
        'C' => handleRightArrow(), // Right arrow
        'D' => handleLeftArrow(), // Left arrow
        '~' => {
            // Extended sequences (like Delete key = ESC[3~)
            if (seq.len >= 2) {
                switch (seq[0]) {
                    '3' => {
                        // Delete key - delete character at cursor
                        if (cursor_pos < line_length) {
                            deleteCharAt(cursor_pos);
                        }
                    },
                    '1' => handleHome(), // Home key (alternative)
                    '4' => handleEnd(), // End key (alternative)
                    else => {},
                }
            }
        },
        'H' => handleHome(), // Home key
        'F' => handleEnd(), // End key
        else => {
            // TODO: Handle Ctrl+Left/Right (word jumping) if terminal sends them
            // This varies by terminal - some send ESC[1;5C for Ctrl+Right
        },
    }
}

// Arrow Key Handlers
fn handleUpArrow() void {
    if (history_count == 0) return;

    if (!in_history_mode) {
        in_history_mode = true;
        history_index = history_count;
    }

    if (history_index > 0) {
        history_index -= 1;
        loadHistory(history_index);
    }
}

fn handleDownArrow() void {
    if (!in_history_mode) return;

    if (history_index < history_count - 1) {
        history_index += 1;
        loadHistory(history_index);
    } else {
        // At bottom of history - clear line
        in_history_mode = false;
        history_index = history_count;
        clearCurrentLine();
    }
}

fn handleLeftArrow() void {
    if (cursor_pos > 0) {
        cursor_pos -= 1;
        print("\x1b[D"); // Move cursor left
    }
}

fn handleRightArrow() void {
    if (cursor_pos < line_length) {
        cursor_pos += 1;
        print("\x1b[C"); // Move cursor right
    }
}

fn handleHome() void {
    moveCursorToStart();
}

fn handleEnd() void {
    moveCursorToEnd();
}

// Cursor Movement Helpers
fn moveCursorToStart() void {
    if (cursor_pos > 0) {
        printf("\x1b[{d}D", .{cursor_pos}); // Move left N times
        cursor_pos = 0;
    }
}

fn moveCursorToEnd() void {
    if (cursor_pos < line_length) {
        const distance = line_length - cursor_pos;
        printf("\x1b[{d}C", .{distance}); // Move right N times
        cursor_pos = line_length;
    }
}

// Line Editing Helpers
fn insertCharAt(pos: usize, char: u8) void {
    if (line_length >= MAX_LINE_LENGTH - 1) {
        print("\x07"); // Beep
        return;
    }

    // Shift characters right to make room
    var i = line_length;
    while (i > pos) : (i -= 1) {
        line_buffer[i] = line_buffer[i - 1];
    }

    // Insert new character
    line_buffer[pos] = char;
    line_length += 1;
    cursor_pos += 1;

    if (echo_enabled) {
        // Redraw from cursor to end of line
        print(&.{char});
        if (cursor_pos < line_length) {
            // There are characters after cursor - redraw them
            print(line_buffer[cursor_pos..line_length]);
            // Move cursor back to correct position
            const distance = line_length - cursor_pos;
            printf("\x1b[{d}D", .{distance});
        }
    }
}

fn deleteCharAt(pos: usize) void {
    if (pos >= line_length) return;

    // Shift characters left
    var i = pos;
    while (i < line_length - 1) : (i += 1) {
        line_buffer[i] = line_buffer[i + 1];
    }

    line_length -= 1;
    if (cursor_pos > pos) {
        cursor_pos -= 1;
    }

    if (echo_enabled) {
        // Redraw from cursor to end
        if (pos == cursor_pos) {
            // Deleting before cursor (backspace)
            print("\x08"); // Move cursor left
        }
        // Clear to end of line and redraw
        print("\x1b[K"); // Clear from cursor to end
        if (pos < line_length) {
            print(line_buffer[pos..line_length]);
            // Move cursor back
            const distance = line_length - pos;
            printf("\x1b[{d}D", .{distance});
        }
    }
}

fn clearCurrentLine() void {
    // Clear entire line and move cursor to start
    print("\r\x1b[K");
    showPrompt();
    line_length = 0;
    cursor_pos = 0;
}

fn redrawLine() void {
    if (line_length > 0) {
        print(line_buffer[0..line_length]);
        // Move cursor to correct position
        if (cursor_pos < line_length) {
            const distance = line_length - cursor_pos;
            printf("\x1b[{d}D", .{distance});
        }
    }
}

// Command History
fn addToHistory(line: []const u8) void {
    if (line.len == 0) return;

    // Don't add duplicates of last command
    if (history_count > 0) {
        const last_idx = history_count - 1;
        if (std.mem.eql(u8, history[last_idx][0..history_lengths[last_idx]], line)) {
            return;
        }
    }

    const idx = history_count % MAX_HISTORY;
    const copy_len = @min(line.len, MAX_LINE_LENGTH);
    @memcpy(history[idx][0..copy_len], line[0..copy_len]);
    history_lengths[idx] = copy_len;

    if (history_count < MAX_HISTORY) {
        history_count += 1;
    }
}

fn loadHistory(idx: usize) void {
    if (idx >= history_count) return;

    const hist_idx = idx % MAX_HISTORY;
    const len = history_lengths[hist_idx];

    // Clear current line
    print("\r\x1b[K");
    showPrompt();

    // Load from history
    @memcpy(line_buffer[0..len], history[hist_idx][0..len]);
    line_length = len;
    cursor_pos = len;

    // Display
    if (echo_enabled and len > 0) {
        print(line_buffer[0..len]);
    }
}

// Command Processing
fn processCommand(line: []const u8) void {
    // Trim and tokenize
    const trimmed = std.mem.trim(u8, line, " \t");
    if (trimmed.len == 0) return;

    var iter = std.mem.tokenizeScalar(u8, trimmed, ' ');
    const command_name = iter.next() orelse return;

    // Look up command
    for (commands) |cmd| {
        if (std.mem.eql(u8, command_name, cmd.name)) {
            cmd.handler(&iter);
            return;
        }
    }

    // Command not found
    printf("Unknown command: {s}\r\n", .{command_name});
    println("Type 'help' for available commands");
}

// Command Handlers
fn cmdHelp(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    println("\r\nAvailable commands:");
    for (commands) |cmd| {
        printf("  {s: <10} - {s}\r\n", .{ cmd.name, cmd.description });
    }
    println("\r\nKeyboard shortcuts:");
    println("  Up/Down    - Browse command history");
    println("  Left/Right - Move cursor");
    println("  Home/End   - Jump to start/end of line");
    println("  Ctrl+A/E   - Jump to start/end of line");
    println("  Ctrl+C     - Cancel current line");
    println("  Ctrl+L     - Clear screen");
    println("  Ctrl+D     - Delete character at cursor");
    println("");
}

var led_pin = gpio.num(25);
var led_initialized = false;

fn cmdLed(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    if (!led_initialized) {
        led_pin.set_function(.sio);
        led_pin.set_direction(.out);
        led_initialized = true;
    }

    const arg = iter.next();
    if (arg) |a| {
        if (std.mem.eql(u8, a, "on")) {
            led_pin.put(1);
            println("\r\nLED turned ON\r\n");
        } else if (std.mem.eql(u8, a, "off")) {
            led_pin.put(0);
            println("\r\nLED turned OFF\r\n");
        } else if (std.mem.eql(u8, a, "toggle")) {
            led_pin.toggle();
            println("\r\nLED toggled\r\n");
        } else {
            println("\r\nUsage: led [on|off|toggle]\r\n");
        }
    } else {
        println("\r\nUsage: led [on|off|toggle]\r\n");
    }
}

fn cmdUptime(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    const uptime_us = timer.micros();
    const uptime_sec = uptime_us / 1_000_000;
    const hours = uptime_sec / 3600;
    const minutes = (uptime_sec % 3600) / 60;
    const seconds = uptime_sec % 60;

    printf("\r\nUptime: {d}h {d}m {d}s\r\n\r\n", .{ hours, minutes, seconds });
}

fn cmdEcho(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    print("\r\n");
    while (iter.next()) |arg| {
        print(arg);
        print(" ");
    }
    println("\r\n");
}

fn cmdClear(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    // ANSI escape codes to clear screen and move cursor to home
    print("\x1b[2J\x1b[H");
}

fn cmdHistory(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    if (history_count == 0) {
        println("\r\nNo commands in history\r\n");
        return;
    }

    println("\r\nCommand History:");
    var i: usize = 0;
    while (i < history_count) : (i += 1) {
        const idx = i % MAX_HISTORY;
        const len = history_lengths[idx];
        printf("  {d}: {s}\r\n", .{ i + 1, history[idx][0..len] });
    }
    println("");
}
fn cmdPs(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    println("\r\nProcess listing not implemented yet.\r\n");
    return;
}

<<<<<<< HEAD
=======
// GPIO Command Handler
fn cmdGpio(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const subcmd = iter.next();
    if (subcmd == null) {
        println("\r\nUsage: gpio <read|write|toggle|list> [args]\r\n");
        return;
    }

    if (std.mem.eql(u8, subcmd.?, "read")) {
        cmdGpioRead(iter);
    } else if (std.mem.eql(u8, subcmd.?, "write")) {
        cmdGpioWrite(iter);
    } else if (std.mem.eql(u8, subcmd.?, "toggle")) {
        cmdGpioToggle(iter);
    } else if (std.mem.eql(u8, subcmd.?, "list")) {
        cmdGpioList(iter);
    } else {
        println("\r\nUsage: gpio <read|write|toggle|list> [args]\r\n");
    }
}

fn cmdGpioRead(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const pin_str = iter.next();
    if (pin_str == null) {
        println("\r\nUsage: gpio read <pin>\r\n");
        return;
    }

    const pin_num = std.fmt.parseInt(u9, pin_str.?, 10) catch {
        printf("\r\nError: Invalid pin number: {s}\r\n\r\n", .{pin_str.?});
        return;
    };

    if (pin_num > 29) {
        println("\r\nError: Pin number must be 0-29\r\n");
        return;
    }

    const pin = gpio.num(pin_num);
    const value = gpio.read(pin);
    printf("\r\nGPIO {d}: {d}\r\n\r\n", .{ pin_num, value });
}

fn cmdGpioWrite(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const pin_str = iter.next();
    if (pin_str == null) {
        println("\r\nUsage: gpio write <pin> <value>\r\n");
        return;
    }

    const pin_num = std.fmt.parseInt(u9, pin_str.?, 10) catch {
        printf("\r\nError: Invalid pin number: {s}\r\n\r\n", .{pin_str.?});
        return;
    };

    if (pin_num > 29) {
        println("\r\nError: Pin number must be 0-29\r\n");
        return;
    }

    const value_str = iter.next();
    if (value_str == null) {
        println("\r\nUsage: gpio write <pin> <value>\r\n");
        return;
    }

    const value = std.fmt.parseInt(u1, value_str.?, 10) catch {
        printf("\r\nError: Invalid value: {s} (must be 0 or 1)\r\n\r\n", .{value_str.?});
        return;
    };

    const pin = gpio.num(pin_num);
    // Configure as output if not already configured
    pin.set_function(.sio);
    pin.set_direction(.out);
    pin.put(value);
    printf("\r\nGPIO {d} set to {d}\r\n\r\n", .{ pin_num, value });
}

fn cmdGpioToggle(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const pin_str = iter.next();
    if (pin_str == null) {
        println("\r\nUsage: gpio toggle <pin>\r\n");
        return;
    }

    const pin_num = std.fmt.parseInt(u9, pin_str.?, 10) catch {
        printf("\r\nError: Invalid pin number: {s}\r\n\r\n", .{pin_str.?});
        return;
    };

    if (pin_num > 29) {
        println("\r\nError: Pin number must be 0-29\r\n");
        return;
    }

    const pin = gpio.num(pin_num);
    // Configure as output if not already configured
    pin.set_function(.sio);
    pin.set_direction(.out);
    gpio.toggle(pin);
    const new_value = gpio.read(pin);
    printf("\r\nGPIO {d} toggled to {d}\r\n\r\n", .{ pin_num, new_value });
}

fn cmdGpioList(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    var start_pin: u9 = 0;
    var end_pin: u9 = 29;

    const start_str = iter.next();
    if (start_str) |s| {
        start_pin = std.fmt.parseInt(u9, s, 10) catch {
            printf("\r\nError: Invalid start pin: {s}\r\n\r\n", .{s});
            return;
        };
        if (start_pin > 29) {
            println("\r\nError: Start pin must be 0-29\r\n");
            return;
        }

        const end_str = iter.next();
        if (end_str) |e| {
            end_pin = std.fmt.parseInt(u9, e, 10) catch {
                printf("\r\nError: Invalid end pin: {s}\r\n\r\n", .{e});
                return;
            };
            if (end_pin > 29) {
                println("\r\nError: End pin must be 0-29\r\n");
                return;
            }
            if (end_pin < start_pin) {
                println("\r\nError: End pin must be >= start pin\r\n");
                return;
            }
        } else {
            end_pin = start_pin;
        }
    }

    println("\r\nGPIO Status:");
    var pin_num = start_pin;
    while (pin_num <= end_pin) : (pin_num += 1) {
        const pin = gpio.num(pin_num);
        const value = gpio.read(pin);
        printf("  GPIO {d: >2}: {d}\r\n", .{ pin_num, value });
    }
    println("");
}

// Reboot Command (does not work properly)
fn cmdReboot(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    println("\r\nRebooting system...\r\n");

    // Small delay to allow message to be sent
    timer.sleep_ms(100);

    // Trigger system reset via SCB (System Control Block)
    // RP2350 uses Cortex-M33, same reset mechanism as other ARM Cortex-M
    const SCB_BASE = 0xE000ED00;
    const AIRCR = @as(*volatile u32, @ptrFromInt(SCB_BASE + 0x0C));

    // Write SYSRESETREQ bit with VECTKEY
    // VECTKEY = 0x5FA, SYSRESETREQ = bit 2
    microzig.cpu.dsb();
    AIRCR.* = 0x05FA0004; // VECTKEY (0x5FA) in upper 16 bits, SYSRESETREQ (bit 2) set
    microzig.cpu.dsb();

    // If reset doesn't happen, hang
    // microzig.hang();
}

>>>>>>> fb359aace46eb909d61e5344f55b12029cb6dd06
//TODO:
// - done -- up direction key (recall last command)
// - done -- left direction key
// - done -- right direction key
// - done -- down direction key (future command history navigation)
// - left direction key + ctrl to move cursor word by word
// - done -- right direction key + ctrl to move cursor word by word
// - ctrl + shift + left/right to select text
// - done -- delete key
<<<<<<< HEAD
=======
// - get reboot command working properly
>>>>>>> fb359aace46eb909d61e5344f55b12029cb6dd06
