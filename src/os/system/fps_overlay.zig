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

        pub fn submit(self: *@This(), value: T) void {
            self.sum -= self.values[self.index];
            self.values[self.index] = value;
            self.sum += value;
            self.index = (self.index + 1) % window;
        }
    };
} 

var frame_times: AveragingBuffer(u32, 8) = .{};
var poll_times: AveragingBuffer(u32, 32) = .{};

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
}

pub fn poll() void {
    const now = timer.micros();

    if (last_poll_us != 0) {
        const elapsed = time_delta(last_poll_us, now);
        poll_times.submit(elapsed);
    }

    last_poll_us = now;
}

/// Draw the FPS counter onto the top-right corner of the LCD.
/// Call after the frame has been flushed to the display (after
/// lcd.writeCartBuffer() or lcd.present()), while the SPI bus is idle,
/// so the overlay renders on top of the cart frame.
pub fn render() void {
    if (!enabled) return;

    // Black background box.
    lcd.fillRect(OVERLAY_X, OVERLAY_Y, OVERLAY_W, OVERLAY_H, lcd.BLACK);

    // Right-justify the FPS value in 3 characters
    const avg: u32 = frame_times.average();
    const fps_display = if (avg > 0) 1_000_000 / avg else 0;
    var buf: [4]u8 = undefined;
    const fps_str = std.fmt.bufPrint(&buf, "{d:>3}", .{fps_display}) catch "???";

    // Yellow text on black.
    lcd.drawString(TEXT_X, TEXT_Y, fps_str, lcd.YELLOW, lcd.BLACK, 1);

    const poll_rate = poll_times.average();
    const pps_display = if (poll_rate > 0) 1_000_000 / poll_rate else 0;
    const pps_str = std.fmt.bufPrint(&buf, "{d:>3}", .{pps_display}) catch "???";
    lcd.drawString(TEXT_X, TEXT_Y + 9, pps_str, lcd.MAGENTA, lcd.BLACK, 1);
}
