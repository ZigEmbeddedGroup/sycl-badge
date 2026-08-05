/// FPS overlay for displaying frame rate information of the LCD display.
const std = @import("std");
const microzig = @import("microzig");
const badge = microzig.board;
const lcd = @import("../drivers/lcd.zig");
const timer = @import("../drivers/timer.zig");

// ── State ─────────────────────────────────────────────────────────────────────

/// Whether the FPS overlay is currently visible.
var enabled: bool = false;

/// Timestamp (µs) of the most recent tick() call.
var last_frame_us: u64 = 0;

/// Timestamp (µs) of the most recent poll() call.
var last_poll_us: u64 = 0;

// ── Rolling averages ───────────────────────────────────────────────────────────
// multi-sample ring buffer so the display doesn't jitter on minor frame-time
// variations.  Pre-filled with ~30 fps so the counter looks sane on first show.

fn AveragingBuffer(comptime T: type, comptime window: u32) type {
    return struct {
        index: usize = 0,
        sum: T = 0,
        values: [window]T = std.mem.zeroes([window]T),

        pub fn average(self: *const @This()) T {
            return self.sum / @as(T, @as(comptime_int, window));
        }

        pub fn max(self: *const @This()) T {
            var max_v: T = 0;
            for (self.values) |v| {
                max_v = @max(max_v, v);
            }
            return max_v;
        }

        pub fn submit(self: *@This(), value: T) void {
            self.sum -= self.values[self.index];
            self.values[self.index] = value;
            self.sum += value;
            self.index = (self.index + 1) % window;
        }
    };
} 

var frame_times: AveragingBuffer(u32, 8) = .{};
var poll_max_history: AveragingBuffer(u32, 32) = .{};
var poll_max: u32 = 0;

// ── Overlay geometry (top-right corner) ──────────────────────────────────────
// Font: 8×8 pixels per character at size 1.
// We reserve space for three digits ("999") plus a 2-px pad on every side.

const PAD: u16 = 2;
const NUM_CHARS: u16 = 3; // maximum "999"
const OVERLAY_W: u16 = NUM_CHARS * 8 + PAD * 2; // 28 px
const OVERLAY_H: u16 = 8 + PAD * 2; // 12 px
const OVERLAY_X: u16 = lcd.width - OVERLAY_W; // 132
const OVERLAY_Y: u16 = 0;
const TEXT_X: u16 = OVERLAY_X + PAD; // 134
const TEXT_Y: u16 = OVERLAY_Y + PAD; // 2

const font = microzig.board.font;
const font_width = 8;
const font_height = 8;

const DebugText = struct {
    str: [debug_img_chars]u8,
    len: u16,
    pos_x: i16,
    pos_y: i16,
    fg_color: lcd.Color16,
    bg_color: lcd.Color16,
};
const max_debug_texts = 32;
var debug_texts: [max_debug_texts]DebugText = undefined;
var num_debug_texts: usize = 0;

var curr_debug_text: usize = 0;
const debug_img_chars = 4;
const debug_pitch = font_width * debug_img_chars;
var debug_img: [debug_pitch * font_height]lcd.Color16 = undefined;

fn reset_debug_text() void {
    num_debug_texts = 0;
    curr_debug_text = 0;
}

const DebugTextOptions = struct {
    text: []const u8,
    x: i16,
    y: i16,
    alignment: enum{ left, center, right },
    color: lcd.Color16,
    bg_color: lcd.Color16 = lcd.BLACK,
};
fn add_debug_text(opts: DebugTextOptions) void {
    if (opts.text.len == 0) return;
    if (num_debug_texts >= max_debug_texts) return;

    // For now truncate the text
    const len = @min(opts.text.len, debug_img_chars);
    const text = opts.text[0..len];
    const width: i16 = @intCast(@as(u32, len) * font_width);
    const pos_x = switch (opts.alignment) {
        .left => opts.x,
        .right => opts.x - width,
        .center => opts.x - (width >> 1),
    };
    debug_texts[num_debug_texts] = .{
        .str = undefined,
        .len = len,
        .pos_x = pos_x,
        .pos_y = opts.y,
        .fg_color = opts.color,
        .bg_color = opts.bg_color,
    };
    @memcpy(debug_texts[num_debug_texts].str[0..len], text);
    num_debug_texts += 1;
}

pub fn is_drawing() bool {
    return curr_debug_text < num_debug_texts;
}

pub fn reset_for_cart() void {
    reset_debug_text();
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Enable or disable the FPS overlay.
pub fn setEnabled(on: bool) void {
    enabled = on;
    if (on) {
        last_frame_us = timer.micros();
    }
}

/// Returns whether the FPS overlay is currently enabled.
pub fn isEnabled() bool {
    return enabled;
}

fn time_delta(from: u64, to: u64) u32 {
    if (from >= to) return 0;

    const elapsed_u64 = to - from;
    // Clamp to u32; any single frame longer than ~71 minutes maps to max.
    return if (elapsed_u64 > 0xFFFF_FFFF)
        0xFFFF_FFFF
    else
        @as(u32, @truncate(elapsed_u64));
}

/// Update the FPS measurement.  Call once per rendered frame (before render()).
/// Returns the current smoothed FPS value.
pub fn tick() void {
    const now = timer.micros();

    if (last_frame_us != 0) {
        const elapsed = time_delta(last_frame_us, now);
        if (elapsed > 0) {
            // Update ring buffer and running sum.
            frame_times.submit(elapsed);
        }
    }

    last_frame_us = now;

    update_debug_text();
}

pub fn poll() void {
    // Update the poll timer
    const now = timer.micros();
    if (last_poll_us != 0) {
        const elapsed = time_delta(last_poll_us, now);
        poll_max = @max(poll_max, elapsed);
    }
    last_poll_us = now;
}

pub fn submit_lcd_work() void {
    // Tick the display state machine
    if (curr_debug_text < num_debug_texts) {
        const curr = &debug_texts[curr_debug_text];
        // Render the text
        draw_str(curr.str[0..curr.len], &debug_img, debug_pitch, curr.fg_color, curr.bg_color);
        // Send the render, clipping against the boundary
        lcd.drawImageClipped(curr.pos_x, curr.pos_y, curr.len * font_width, font_height, &debug_img, debug_pitch);

        curr_debug_text += 1;
    }
}

/// Draw the FPS counter onto the top-right corner of the LCD.
/// Call after the frame has been flushed to the display (after
/// lcd.writeCartBuffer() or lcd.present()), while the SPI bus is idle,
/// so the overlay renders on top of the cart frame.
fn update_debug_text() void {
    reset_debug_text();

    if (!enabled) return;

    // Yellow text on black.
    // Right-justify the FPS value in 3 characters
    const avg: u32 = frame_times.average();
    const fps_display = if (avg > 0) 1_000_000 / avg else 0;
    var buf: [4]u8 = undefined;
    const fps_str = std.fmt.bufPrint(&buf, "{d:>4}", .{fps_display}) catch "???";
    add_debug_text(.{ .text = fps_str, .x = lcd.width, .y = 0, .alignment = .right, .color = lcd.YELLOW });

    if (poll_max > 0) {
        poll_max_history.submit(poll_max);
        poll_max = 0;
    }

    const poll_max_avg = poll_max_history.average();
    const pps_str = std.fmt.bufPrint(&buf, "{d:>4}", .{poll_max_avg}) catch "????";
    add_debug_text(.{ .text = pps_str, .x = lcd.width, .y = 9, .alignment = .right, .color = lcd.MAGENTA });

    const poll_max_max = poll_max_history.max();
    const max_pps_str = std.fmt.bufPrint(&buf, "{d:>4}", .{poll_max_max}) catch "????";
    add_debug_text(.{ .text = max_pps_str, .x = @intCast(lcd.width - 1 - (4 * font_width)), .y = 9, .alignment = .right, .color = lcd.RED });
}

fn draw_str(str: []const u8, base: [*]lcd.Color16, pitch: usize, fg_color: lcd.Color16, bg_color: lcd.Color16) void {
    var pos = base;
    for (str) |char| {
        draw_char(char, pos, pitch, fg_color, bg_color);
        pos += font_width;
    }
}

fn draw_char(char: u8, base: [*]lcd.Color16, pitch: usize, fg_color: lcd.Color16, bg_color: lcd.Color16) void {
    // Get font data for this character (font starts at space ' ')
    var char_index = if (char >= ' ') char - ' ' else 0;
    if (char_index >= font.font.len) char_index = 0;

    const glyph = font.font[char_index];

    // Draw the character bitmap
    var row = base;
    for (0..font_height) |row_idx| {
        const line = glyph[row_idx];
        for (0..font_width) |col_idx| {
            // Check if pixel is set (0 = foreground, 1 = background in this font)
            const bit_set = (line & (@as(u8, 1) << @as(u3, @intCast(7 - col_idx)))) == 0;
            const pixel_color = if (bit_set) fg_color else bg_color;
            row[col_idx] = pixel_color;
        }
        row += pitch;
    }
}
