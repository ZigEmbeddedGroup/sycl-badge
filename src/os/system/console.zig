/// Console system for SYCL Badge OS
/// Handles line buffering, command parsing, and interactive shell
const std = @import("std");
const microzig = @import("microzig");
const usb = @import("../drivers/usb.zig");
const timer = @import("../drivers/timer.zig");
const gpio = @import("../drivers/gpio.zig");
const lcd = @import("../drivers/lcd.zig");
const rom = @import("../drivers/rom.zig");
const mailbox = @import("../ipc/mailbox.zig");
const shared_mem = @import("../ipc/shared_mem.zig");
const storage = @import("../loader/storage.zig");
const loader = @import("../loader/loader.zig");
const debug_log = @import("../debug_log.zig");
const multicore = @import("multicore.zig");
const fps_overlay = @import("fps_overlay.zig");
const badge = microzig.board;

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
var in_history_mode: bool = false; // Sets if we are browsing history

// Escape Sequence State Machine
const EscapeState = enum {
    normal,
    escape, // Got ESC (0x1B)
    csi, // Got ESC + [ (Control Sequence Introducer)
};

var escape_state: EscapeState = .normal;
var escape_buffer: [8]u8 = undefined; // Store escape sequence params
var escape_length: usize = 0;

// Tab Completion State
var completion_original_input: [MAX_LINE_LENGTH]u8 = undefined; // Original input before completion
var completion_original_length: usize = 0; // Length of original input
var completion_index: usize = 0; // Current completion index
var in_completion_mode: bool = false; // Sets if we are cycling through completions

// Command Handler Type
// CommandFn - function pointer type that takes a token iterator
pub const CommandFn = *const fn (iter: *std.mem.TokenIterator(u8, .scalar)) void;

// Completion Provider Type - returns list of valid completions for a given argument position
pub const CompletionFn = *const fn (arg_index: usize, partial: []const u8) []const []const u8;

// Command Structure
pub const Command = struct {
    name: []const u8,
    description: []const u8,
    handler: CommandFn, // function this cmd calls
    completion_provider: ?CompletionFn = null, // optional argument completion
};

// Completion providers for specific commands
fn lcdCompletions(arg_index: usize, partial: []const u8) []const []const u8 {
    _ = partial;
    if (arg_index == 0) {
        const options = [_][]const u8{ "test", "red", "green", "blue", "yellow", "cyan", "magenta", "white", "black", "image", "fps" };
        return &options;
    }
    return &[_][]const u8{};
}

fn gpioCompletions(arg_index: usize, partial: []const u8) []const []const u8 {
    _ = partial;
    if (arg_index == 0) {
        const options = [_][]const u8{ "read", "write", "toggle", "list" };
        return &options;
    }
    return &[_][]const u8{};
}

fn rebootCompletions(arg_index: usize, partial: []const u8) []const []const u8 {
    _ = partial;
    if (arg_index == 0) {
        const options = [_][]const u8{"bootsel"};
        return &options;
    }
    return &[_][]const u8{};
}

// Static storage for cart name completions
const MAX_CART_COMPLETIONS = 16;
const MAX_CART_NAME_LEN = 32;
var cart_name_storage: [MAX_CART_COMPLETIONS][MAX_CART_NAME_LEN]u8 = undefined;
var cart_name_slices: [MAX_CART_COMPLETIONS][]const u8 = undefined;
var cart_name_count: usize = 0;

fn refreshCartNames() void {
    cart_name_count = 0;
    storage.listCarts(struct {
        fn visit(name: []const u8, size: u32) void {
            _ = size;
            if (cart_name_count >= MAX_CART_COMPLETIONS) return;
            const copy_len = @min(name.len, MAX_CART_NAME_LEN);
            @memcpy(cart_name_storage[cart_name_count][0..copy_len], name[0..copy_len]);
            cart_name_slices[cart_name_count] = cart_name_storage[cart_name_count][0..copy_len];
            cart_name_count += 1;
        }
    }.visit);
}

fn overlayCompletions(arg_index: usize, partial: []const u8) []const []const u8 {
    _ = partial;
    if (arg_index == 0) {
        const options = [_][]const u8{"fps"};
        return &options;
    }
    if (arg_index == 1) {
        const options = [_][]const u8{ "on", "off" };
        return &options;
    }
    return &[_][]const u8{};
}

fn cartCompletions(arg_index: usize, partial: []const u8) []const []const u8 {
    _ = partial;
    if (arg_index == 0) {
        const options = [_][]const u8{ "list", "run", "stop", "status", "exec", "info", "delete", "wipeall" };
        return &options;
    }
    if (arg_index == 1) {
        // Return cart names for "cart run <name>", "cart info <name>", etc.
        refreshCartNames();
        return cart_name_slices[0..cart_name_count];
    }
    return &[_][]const u8{};
}

// Command Registry
const commands = [_]Command{
    .{ .name = "help", .description = "List available commands", .handler = cmdHelp },
    .{ .name = "uptime", .description = "Show system uptime", .handler = cmdUptime },
    .{ .name = "clear", .description = "Clear terminal screen", .handler = cmdClear },
    .{ .name = "history", .description = "Show command history", .handler = cmdHistory },
    .{ .name = "gpio", .description = "GPIO operations (read/write/toggle/list)", .handler = cmdGpio, .completion_provider = gpioCompletions },
    .{ .name = "lcd", .description = "LCD tests (test/red/green/blue/black/white/fps)", .handler = cmdLcd, .completion_provider = lcdCompletions },
    .{ .name = "cart", .description = "Manage carts (list/run/stop/info/delete/wipeall)", .handler = cmdCart, .completion_provider = cartCompletions },
    .{ .name = "overlay", .description = "LCD overlay controls (overlay fps [on|off])", .handler = cmdOverlay, .completion_provider = overlayCompletions },
    .{ .name = "storage", .description = "Show storage filesystem statistics", .handler = cmdStorage },
    .{ .name = "wipe", .description = "Erase cart XIP flash and process RAM (wipe confirm)", .handler = cmdWipe },
    .{ .name = "menu", .description = "Return to cart selection screen", .handler = cmdMenu },
    .{ .name = "reboot", .description = "Restart the system", .handler = cmdReboot },
};

// Unified Console Output (sends to USB CDC)
var print_buffer: [512]u8 = undefined;

/// Print formatted string to console (USB)
pub fn printf(comptime fmt: []const u8, args: anytype) void {
    const text = std.fmt.bufPrint(&print_buffer, fmt, args) catch return;
    print(text);
}

/// Print string to console (USB)
pub fn print(text: []const u8) void {
    _ = usb.send(text);
}

/// Print string with newline
pub fn println(text: []const u8) void {
    print(text);
    print("\r\n");
}

/// Helper to print a debug_log entry with newline
pub fn consolePrintLog(msg: []const u8) void {
    printf("  {s}\r\n", .{msg});
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
    println("=============");
    println("SYCL Badge OS");
    println("=============");
    println("'help' for cmds");
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
            in_completion_mode = false;
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
            in_completion_mode = false;
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

        0x09 => {
            // Ctrl + I - command line comletion (TAB)
            commandLineCompletion();
        },

        0x20...0x7E => {
            // Printable characters
            in_completion_mode = false; // Exit completion mode
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
fn commandLineCompletion() void {
    // If not in completion mode, save original input and start
    if (!in_completion_mode) {
        if (line_length == 0) {
            // Nothing to complete
            print("\x07"); // Beep
            return;
        }

        // Save original input
        @memcpy(completion_original_input[0..line_length], line_buffer[0..line_length]);
        completion_original_length = line_length;
        completion_index = 0;
        in_completion_mode = true;
    } else {
        // Already in completion mode, move to next match
        completion_index += 1;
    }

    const search_input = completion_original_input[0..completion_original_length];

    // Parse the input to determine what we're completing
    var iter = std.mem.tokenizeScalar(u8, search_input, ' ');
    const first_word = iter.next() orelse {
        print("\x07");
        in_completion_mode = false;
        return;
    };

    // Count how many complete words we have
    var word_count: usize = 1;
    var last_word_start: usize = 0;
    var in_word = false;

    for (search_input, 0..) |c, i| {
        if (c == ' ') {
            if (in_word) {
                word_count += 1;
                in_word = false;
            }
        } else {
            if (!in_word) {
                last_word_start = i;
                in_word = true;
            }
        }
    }

    const last_word = if (in_word) search_input[last_word_start..] else "";
    const is_first_word = (word_count == 1 and search_input[search_input.len - 1] != ' ');

    var match_count: usize = 0;
    var current_match: ?[]const u8 = null;

    if (is_first_word) {
        // Complete command name
        for (commands) |cmd| {
            if (std.mem.startsWith(u8, cmd.name, last_word)) {
                if (match_count == completion_index) {
                    current_match = cmd.name;
                }
                match_count += 1;
            }
        }
    } else {
        // Complete argument/subcommand
        // Find the command
        for (commands) |cmd| {
            if (std.mem.eql(u8, cmd.name, first_word)) {
                if (cmd.completion_provider) |provider| {
                    const arg_index = word_count - 2; // -1 for command, -1 for 0-based
                    const options = provider(arg_index, last_word);

                    for (options) |option| {
                        // If last_word is empty, show all options; otherwise filter by prefix
                        if (last_word.len == 0 or std.mem.startsWith(u8, option, last_word)) {
                            if (match_count == completion_index) {
                                current_match = option;
                            }
                            match_count += 1;
                        }
                    }
                }
                break;
            }
        }
    }

    // If cycled past the end, wrap around
    if (match_count == 0) {
        // No matches at all, beep and reset
        print("\x07");
        in_completion_mode = false;
        return;
    }

    if (completion_index >= match_count) {
        // Cycled past end, wrap to beginning
        completion_index = 0;

        // Find first match again
        if (is_first_word) {
            for (commands) |cmd| {
                if (std.mem.startsWith(u8, cmd.name, last_word)) {
                    current_match = cmd.name;
                    break;
                }
            }
        } else {
            for (commands) |cmd| {
                if (std.mem.eql(u8, cmd.name, first_word)) {
                    if (cmd.completion_provider) |provider| {
                        const arg_index = word_count - 2;
                        const options = provider(arg_index, last_word);
                        for (options) |option| {
                            // If last_word is empty, show all options; otherwise filter by prefix
                            if (last_word.len == 0 or std.mem.startsWith(u8, option, last_word)) {
                                current_match = option;
                                break;
                            }
                        }
                    }
                    break;
                }
            }
        }
    }

    if (current_match) |m| {
        // Build the completed line
        var new_line: [MAX_LINE_LENGTH]u8 = undefined;
        var new_length: usize = 0;

        if (is_first_word) {
            // Just replace with matched command
            const copy_len = @min(m.len, MAX_LINE_LENGTH);
            @memcpy(new_line[0..copy_len], m[0..copy_len]);
            new_length = copy_len;
        } else {
            // Keep everything before the last word, append match
            const prefix_len = last_word_start;
            @memcpy(new_line[0..prefix_len], search_input[0..prefix_len]);
            const match_len = @min(m.len, MAX_LINE_LENGTH - prefix_len);
            @memcpy(new_line[prefix_len .. prefix_len + match_len], m[0..match_len]);
            new_length = prefix_len + match_len;
        }

        // Clear current line and rewrite
        print("\r\x1b[K"); // Move to start, clear line
        print(PROMPT); // Show prompt directly without newline

        // Copy to line buffer
        @memcpy(line_buffer[0..new_length], new_line[0..new_length]);
        line_length = new_length;
        cursor_pos = new_length;

        // Display completed line
        if (echo_enabled and new_length > 0) {
            print(line_buffer[0..new_length]);
        }
    }
}
fn clearCurrentLine() void {
    // Clear entire line and move cursor to start
    print("\r\x1b[K");
    print(PROMPT);
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
    print(PROMPT);

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

fn cmdUptime(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    const uptime_us = timer.micros();
    const uptime_sec = uptime_us / 1_000_000;
    const hours = uptime_sec / 3600;
    const minutes = (uptime_sec % 3600) / 60;
    const seconds = uptime_sec % 60;

    printf("\r\nUptime: {d}h {d}m {d}s\r\n\r\n", .{ hours, minutes, seconds });
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

    if (pin_num > 47) {
        println("\r\nError: Pin number must be 0-47\r\n");
        return;
    }

    // Configure as input to read actual pin state (otherwise it doesn't get the correct value)
    gpio.configureAsInput(pin_num);

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

    if (pin_num > 47) {
        println("\r\nError: Pin number must be 0-47\r\n");
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

    if (pin_num > 47) {
        println("\r\nError: Pin number must be 0-47\r\n");
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
    var end_pin: u9 = 47;

    const start_str = iter.next();
    if (start_str) |s| {
        start_pin = std.fmt.parseInt(u9, s, 10) catch {
            printf("\r\nError: Invalid start pin: {s}\r\n\r\n", .{s});
            return;
        };
        if (start_pin > 47) {
            println("\r\nError: Start pin must be 0-47\r\n");
            return;
        }

        const end_str = iter.next();
        if (end_str) |e| {
            end_pin = std.fmt.parseInt(u9, e, 10) catch {
                printf("\r\nError: Invalid end pin: {s}\r\n\r\n", .{e});
                return;
            };
            if (end_pin > 47) {
                println("\r\nError: End pin must be 0-47\r\n");
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
        // Configure as input to read actual pin state
        gpio.configureAsInput(pin_num);

        const pin = gpio.num(pin_num);
        const value = gpio.read(pin);
        printf("  GPIO {d: >2}: {d}\r\n", .{ pin_num, value });
    }
    println("");
}

// Storage Statistics Command - Show filesystem details
fn cmdStorage(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;

    println("\r\n=== Storage Filesystem Statistics ===\r\n");

    const stats = storage.getStats();

    // Overall filesystem info
    printf("Total Storage:     {d} KB ({d} bytes)\r\n", .{ stats.total_size_bytes / 1024, stats.total_size_bytes });
    printf("FAT12 Filesystem:  {d} sectors x 512 bytes\r\n\r\n", .{storage.totalSectors()});

    // Filesystem layout
    println("--- Filesystem Layout ---");
    printf("FAT Tables:        {d} KB  (2 copies)\r\n", .{stats.fat_size_bytes / 1024});
    printf("Root Directory:    {d} KB  ({d} entries max)\r\n", .{ stats.root_size_bytes / 1024, stats.root_total_entries });
    printf("Data Region:       {d} KB  ({d} clusters)\r\n\r\n", .{ stats.data_size_bytes / 1024, stats.total_clusters });

    // Cluster usage
    println("--- Cluster Usage ---");
    printf("Total Clusters:    {d}\r\n", .{stats.total_clusters});
    printf("Used Clusters:     {d}\r\n", .{stats.used_clusters});
    printf("Free Clusters:     {d}\r\n", .{stats.free_clusters});

    const used_pct = if (stats.total_clusters > 0)
        (@as(u32, stats.used_clusters) * 100) / stats.total_clusters
    else
        0;
    printf("Usage:             {d}%\r\n\r\n", .{used_pct});

    // Space usage
    println("--- Space Usage ---");
    const used_kb = (@as(u32, stats.used_clusters) * 512) / 1024;
    const free_kb = stats.free_space_bytes / 1024;
    printf("Used Space:        {d} KB\r\n", .{used_kb});
    printf("Free Space:        {d} KB\r\n\r\n", .{free_kb});

    // Root directory usage
    println("--- Root Directory ---");
    printf("Total Entries:     {d}\r\n", .{stats.root_total_entries});
    printf("Used Entries:      {d}\r\n", .{stats.root_used_entries});
    printf("  Active Files:    {d}\r\n", .{stats.file_count});
    printf("  Deleted (0xE5):  {d}\r\n", .{stats.root_deleted_entries});
    printf("Free Entries:      {d}\r\n", .{stats.root_free_entries});

    if (stats.root_free_entries < 5) {
        println("\r\nWARNING: Root directory nearly full!");
        println("Use 'cart wipeall confirm' to reclaim space.\r\n");
    } else {
        println("");
    }
}

// Wipe Command - Erase cart/XIP flash and process RAM
fn cmdWipe(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const confirm = iter.next();

    if (confirm == null or !std.mem.eql(u8, confirm.?, "confirm")) {
        println("\r\nWARNING: This will erase all cart XIP flash and process RAM!");
        println("To proceed, type: wipe confirm\r\n");
        return;
    }

    // Stop any running cart first
    if (loader.getState() == .running or loader.getState() == .ready) {
        println("\r\nStopping running cart...");
        multicore.haltCore1();
        loader.stop();
        multicore.resetCore1();
    }

    // Erase cart XIP flash region
    println("Erasing cart XIP flash region...");
    loader.eraseCartRegion() catch {
        println("ERROR: Failed to erase cart XIP region\r\n");
        return;
    };

    // Clear process RAM (Core 1 RAM: 0x20020000 - 0x20080000, 384KB)
    println("Clearing process RAM...");
    const PROCESS_RAM_START: u32 = 0x20020000;
    const PROCESS_RAM_SIZE: usize = 384 * 1024;
    const process_ram: [*]u8 = @ptrFromInt(PROCESS_RAM_START);
    @memset(process_ram[0..PROCESS_RAM_SIZE], 0);

    printf("\r\nWipe complete!\r\n  Cart XIP: 0x{x} - 0x{x} ({d}KB)\r\n", .{
        loader.getCartXipStart(),
        loader.getCartXipEnd(),
        loader.getCartXipSize() / 1024,
    });
    printf("  Process RAM: 0x{x} - 0x{x} ({d}KB)\r\n\r\n", .{
        PROCESS_RAM_START,
        PROCESS_RAM_START + PROCESS_RAM_SIZE,
        PROCESS_RAM_SIZE / 1024,
    });
}

// Reboot Command
fn cmdReboot(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    println("\r\nRebooting system...\r\n");

    // Small delay to allow message to be sent
    timer.sleep_ms(50);

    // Disconnect USB to properly signal disconnection to the host
    // This prevents the terminal from thinking the connection is still active
    usb.disconnect();

    // Small delay to allow host to detect disconnection
    timer.sleep_ms(10);

    // Trigger system reset via SCB (System Control Block)
    const SCB_BASE = 0xE000ED00;
    const AIRCR = @as(*volatile u32, @ptrFromInt(SCB_BASE + 0x0C));

    // Write SYSRESETREQ bit with VECTKEY
    // VECTKEY = 0x5FA, SYSRESETREQ = bit 2
    microzig.cpu.dsb();
    microzig.cpu.isb();

    // Write: VECTKEY (0x5FA) in upper 16 bits, SYSRESETREQ (bit 2) set
    AIRCR.* = 0x05FA0004;

    microzig.cpu.dsb();
    microzig.cpu.isb();

    // Wait for reset to occur (should happen immediately)
    while (true) {
        microzig.cpu.wfi();
    }
}

// Reboot to BootSelect Command
fn cmdRebootBootSel(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;
    println("\r\nRebooting to BootSelect...\r\n");

    // Small delay to allow message to be sent
    timer.sleep_ms(50);

    // Use ROM function to reset to USB bootloader
    rom.reset_to_usb_boot();
}

// Menu Command - Return to cart selection screen
var menu_y_pos: u16 = 0;

fn menuCartVisitor(name: []const u8, size: u32) void {
    _ = size;
    if (menu_y_pos < 220) { // Don't draw past screen bottom
        lcd.drawString(20, menu_y_pos, name, lcd.GREEN, lcd.BLACK, 1);
        menu_y_pos += 12;
    }
}

fn cmdMenu(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    _ = iter;

    // Stop any running cart first
    const cart_state = loader.getState();
    if (cart_state == .running or cart_state == .ready) {
        println("\r\nStopping cart...");
        multicore.haltCore1();
        loader.stop();
        multicore.resetCore1();

        // Give the system a moment to settle
        timer.sleep_ms(50);
    }

    // Restore the default cart selection screen
    println("Restoring menu...\r\n");

    // Reinitialize LCD display (fixes color mode if cart changed it)
    lcd.reinitDisplay();

    // Clear screen and draw header
    lcd.fillScreen(lcd.BLACK);
    lcd.drawString(10, 20, "SYCL Badge OS", lcd.WHITE, lcd.BLACK, 1);
    lcd.drawString(10, 40, "Available Carts:", lcd.CYAN, lcd.BLACK, 1);

    // List available carts
    menu_y_pos = 60;
    storage.listCarts(menuCartVisitor);

    println("Menu restored. Use buttons to navigate and select carts.\r\n");
}
// LCD Test Command
fn cmdLcd(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const action = iter.next() orelse {
        println("\r\nUsage: lcd <test|red|green|blue|yellow|cyan|magenta|white|black|fps>\r\n");
        return;
    };

    if (std.mem.eql(u8, action, "test")) {
        println("\r\nRunning LCD test pattern...");
        lcd.testPattern();
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "red")) {
        println("\r\nFilling LCD with RED...");
        lcd.clearScreen(lcd.RED);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "green")) {
        println("\r\nFilling LCD with GREEN...");
        lcd.clearScreen(lcd.GREEN);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "blue")) {
        println("\r\nFilling LCD with BLUE...");
        lcd.clearScreen(lcd.BLUE);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "yellow")) {
        println("\r\nFilling LCD with YELLOW...");
        lcd.clearScreen(lcd.YELLOW);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "cyan")) {
        println("\r\nFilling LCD with CYAN...");
        lcd.clearScreen(lcd.CYAN);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "magenta")) {
        println("\r\nFilling LCD with MAGENTA...");
        lcd.clearScreen(lcd.MAGENTA);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "white")) {
        println("\r\nFilling LCD with WHITE...");
        lcd.clearScreen(lcd.WHITE);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "black")) {
        println("\r\nFilling LCD with BLACK...");
        lcd.clearScreen(lcd.BLACK);
        println("Done\r\n");
    } else if (std.mem.eql(u8, action, "fps")) {
        println("\r\nRunning FPS benchmark...");
        lcdFpsBenchmark();
        println("Done\r\n");
    } else {
        printf("\r\nUnknown LCD action: {s}\r\n", .{action});
        println("Available: test, red, green, blue, yellow, cyan, magenta, white, black, fps\r\n");
    }
}

// LCD FPS Benchmark
fn lcdFpsBenchmark() void {
    const colors = [_]lcd.Color16{ lcd.RED, lcd.GREEN, lcd.BLUE, lcd.YELLOW, lcd.CYAN, lcd.MAGENTA };

    println("\r\nMeasuring DMA-based screen fill perf...");
    println("Filling screen 100 times with diff colors...");

    const start_time = timer.get_time_since_boot();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const color = colors[i % colors.len];
        lcd.clearScreen(color);
        lcd.vsync();
    }

    const end_time = timer.get_time_since_boot();
    const elapsed_us = end_time.to_us() - start_time.to_us();
    const elapsed_ms = elapsed_us / 1000;
    const avg_frame_time_ms = elapsed_ms / 100;
    const fps = if (avg_frame_time_ms > 0) 1000 / avg_frame_time_ms else 0;

    printf("\r\nResults:\r\n", .{});
    printf("  Total time: {d}ms\r\n", .{elapsed_ms});
    printf("  Average frame time: {d}ms\r\n", .{avg_frame_time_ms});
    printf("  Estimated FPS: {d}\r\n", .{fps});
    println("");
}

// Static counter for ls command (needed because callbacks can't capture locals)
var ls_file_count: usize = 0;
var ls_lcd_y: u16 = 0;

// Overlay Command Handler
fn cmdOverlay(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const feature = iter.next() orelse {
        println("\r\nUsage: overlay fps [on|off]\r\n");
        return;
    };

    if (std.mem.eql(u8, feature, "fps")) {
        const state_arg = iter.next();
        if (state_arg) |state| {
            if (std.mem.eql(u8, state, "on")) {
                fps_overlay.setEnabled(true);
                println("\r\nFPS overlay enabled\r\n");
            } else if (std.mem.eql(u8, state, "off")) {
                fps_overlay.setEnabled(false);
                println("\r\nFPS overlay disabled\r\n");
            } else {
                printf("\r\nUnknown state '{s}'. Use 'on' or 'off'.\r\n", .{state});
            }
        } else {
            // No argument — toggle
            const new_state = !fps_overlay.isEnabled();
            fps_overlay.setEnabled(new_state);
            if (new_state) {
                println("\r\nFPS overlay enabled\r\n");
            } else {
                println("\r\nFPS overlay disabled\r\n");
            }
        }
    } else {
        printf("\r\nUnknown overlay feature '{s}'. Available: fps\r\n", .{feature});
    }
}

fn lsVisitor(name: []const u8, size: u32) void {
    ls_file_count += 1;
    printf("  {s}  ({d} bytes)\r\n", .{ name, size });
    lcd.drawString(10, ls_lcd_y, name, lcd.GREEN, lcd.BLACK, 1);
    ls_lcd_y += 15;
}

fn cmdLoad(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const name = iter.next() orelse {
        println("\r\nUsage: load <filename.uf2>\r\n");
        return;
    };

    // Load the UF2 cart
    println("\r\n");
    const entry_point = loader.loadUF2Cart(name) catch |err| {
        switch (err) {
            loader.LoadError.FileNotFound => printf("File not found: {s}\r\n\r\n", .{name}),
            loader.LoadError.FileTooLarge => println("UF2 file too large (max 256KB binary)\r\n"),
            loader.LoadError.InvalidUF2 => println("Invalid UF2 format\r\n"),
            loader.LoadError.UnsupportedFamily => println("Unsupported chip family (need RP2354B)\r\n"),
            loader.LoadError.AddressMismatch => println("UF2 not linked for cart_xip region (0x101C0000)\r\n"),
            loader.LoadError.FlashWriteError => println("Flash write error\r\n"),
            loader.LoadError.ReadError => println("Storage read error\r\n"),
        }
        return;
    };

    printf("Cart loaded at entry point 0x{x}\r\n", .{entry_point});
    println("Use 'run' to execute, or 'cart run <name>' for one-step load+run\r\n");
}

fn cmdCart(iter: *std.mem.TokenIterator(u8, .scalar)) void {
    const subcmd = iter.next() orelse {
        println("\r\nUsage: cart <list|run|stop|status|info|delete|wipeall> [name]\r\n");
        return;
    };

    if (std.mem.eql(u8, subcmd, "list")) {
        println("\r\nCarts:");
        storage.listCarts(struct {
            fn visit(name: []const u8, size: u32) void {
                printf("  {s}  ({d} bytes)\r\n", .{ name, size });
            }
        }.visit);
        println("");
        return;
    }

    if (std.mem.eql(u8, subcmd, "stop")) {
        // Use multicore to forcefully halt Core 1 (uses PSM hardware reset)
        // This is necessary because the cart has taken over Core 1 and is no longer
        // processing mailbox messages
        multicore.haltCore1();
        loader.stop();

        // Reset Core 1 so it's ready for the next cart
        multicore.resetCore1();

        println("\r\nCart stopped\r\n");
        return;
    }

    if (std.mem.eql(u8, subcmd, "status")) {
        println("\r\nCart Status:");
        const state = loader.getState();
        const state_str = switch (state) {
            .none => "none",
            .loading => "loading",
            .ready => "ready",
            .running => "running",
            .error_state => "error",
        };
        printf("  State: {s}\r\n", .{state_str});
        if (state == .ready or state == .running) {
            printf("  Entry point: 0x{x}\r\n", .{loader.getEntryPoint()});
        }
        printf("  Cart XIP region: 0x{x} - 0x{x} ({d}KB)\r\n", .{
            loader.getCartXipStart(),
            loader.getCartXipEnd(),
            loader.getCartXipSize() / 1024,
        });

        // ROMFS / storage info
        printf("  ROMFS base: 0x{x} size: {d}KB\r\n", .{ storage.romfsBaseAddr(), storage.romfsSizeBytes() / 1024 });
        printf("  ROMFS formatted this boot: {s}\r\n", .{if (storage.getFormattedThisBoot()) "yes" else "no"});

        println("");
        return;
    }

    if (std.mem.eql(u8, subcmd, "wipe")) {
        const confirm = iter.next() orelse {
            println("\r\nThis will erase all cart storage.\r\nUsage: cart wipe YES\r\n");
            return;
        };

        if (!std.ascii.eqlIgnoreCase(confirm, "YES")) {
            println("\r\nAborted. Type: cart wipe YES\r\n");
            return;
        }

        println("\r\nWiping cart storage...\r\n");
        storage.wipeStorage();
        println("Cart storage wiped\r\n");
        return;
    }

    if (std.mem.eql(u8, subcmd, "exec")) {
        // Execute already-loaded cart
        if (!loader.isReady()) {
            println("\r\nNo cart loaded. Use 'load <file.uf2>' first.\r\n");
            return;
        }
        const entry = loader.getEntryPoint();
        if (multicore.executeCart(entry)) {
            printf("\r\nExecuting cart at 0x{x}...\r\n", .{entry});
        } else {
            println("\r\nFailed to execute cart\r\n");
        }
        return;
    }

    if (std.mem.eql(u8, subcmd, "wipeall")) {
        const confirm = iter.next();

        if (confirm == null or !std.mem.eql(u8, confirm.?, "confirm")) {
            println("\r\nWARNING: This will COMPLETELY WIPE the storage filesystem!");
            println("ALL carts will be permanently deleted!");
            println("This reformats the FAT12 filesystem and clears all deleted entries.");
            println("\r\nTo proceed, type: cart wipeall confirm\r\n");
            return;
        }

        // Stop any running cart first
        if (loader.getState() == .running or loader.getState() == .ready) {
            println("\r\nStopping running cart...");
            multicore.haltCore1();
            loader.stop();
            multicore.resetCore1();
        }

        println("Wiping storage filesystem...");
        storage.wipeStorage();
        println("\r\nStorage filesystem wiped! All carts deleted.\r\n");
        return;
    }

    const name = iter.next() orelse {
        println("\r\nCart name required\r\n");
        return;
    };

    if (std.mem.eql(u8, subcmd, "run")) {
        // Stop any currently running cart first
        // This is necessary because Core 1 won't process new CART_EXECUTE messages
        // while it's already running a cart (it jumped to the cart's code)
        if (loader.getState() == .running or loader.getState() == .ready) {
            multicore.haltCore1();
            loader.stop();
            multicore.resetCore1();
        }

        // Load and execute UF2 cart in one step
        println("\r\n");

        const entry_point = loader.loadUF2Cart(name) catch |err| {
            switch (err) {
                loader.LoadError.FileNotFound => printf("Cart not found: {s}\r\n\r\n", .{name}),
                loader.LoadError.FileTooLarge => println("UF2 file too large (max 256KB binary)\r\n"),
                loader.LoadError.InvalidUF2 => println("Invalid UF2 format\r\n"),
                loader.LoadError.UnsupportedFamily => println("Unsupported chip family (need RP2354B)\r\n"),
                loader.LoadError.AddressMismatch => println("UF2 not linked for cart_xip region (0x101C0000)\r\n"),
                loader.LoadError.FlashWriteError => println("Flash write error\r\n"),
                loader.LoadError.ReadError => println("Storage read error\r\n"),
            }

            // Dump debug logs to console for diagnostic info
            debug_log.forEachEntry(consolePrintLog);
            return;
        };

        // Dump loader/storage logs (verification/erase info)
        debug_log.forEachEntry(consolePrintLog);

        // Execute the loaded cart
        if (multicore.executeCart(entry_point)) {
            // Mark as running from Core 0 side
            // (Core 1 also calls markRunning but this ensures state is set immediately)
            loader.markRunning();
            printf("Cart running at 0x{x}\r\n\r\n", .{entry_point});
        } else {
            println("Failed to start cart execution\r\n");
        }
        return;
    }

    if (std.mem.eql(u8, subcmd, "info")) {
        const cart = storage.findCart(name) orelse {
            printf("\r\nCart not found: {s}\r\n\r\n", .{name});
            return;
        };

        // Disp long name if avail
        const display_name = if (cart.long_name_len > 0)
            cart.long_name[0..cart.long_name_len]
        else blk: {
            const end = std.mem.indexOfScalar(u8, cart.short_name[0..], 0) orelse cart.short_name.len;
            break :blk cart.short_name[0..end];
        };

        printf("\r\n{s}\r\n  Size: {d} bytes\r\n  Cluster: {d}\r\n", .{ display_name, cart.size, cart.start_cluster });

        // Check if the cart is a UF2 file
        if (cart.size >= 512) {
            println("  Format: Likely UF2 (check with 'load' command)");
        }
        println("\r\n");
        return;
    }

    if (std.mem.eql(u8, subcmd, "delete")) {
        if (storage.deleteCart(name)) {
            println("\r\nCart deleted\r\n");
        } else {
            printf("\r\nCart not found: {s}\r\n\r\n", .{name});
        }
        return;
    }

    if (std.mem.eql(u8, subcmd, "diag")) {
        println("\r\nCart diagnostic log:\r\n");
        debug_log.forEachEntry(consolePrintLog);
        println("");
        return;
    }

    println("\r\nUnknown cart subcommand\r\n");
}

//TODO:
// - left direction key + ctrl to move cursor word by word
// - ctrl + shift + left/right to select text
// - command to print text to LCD screen (probably not necessary other than debugging)
// - fix extra newline character when using up arrow
