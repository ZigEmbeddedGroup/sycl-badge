const cart = @import("cart-api");
const std = @import("std");

comptime {
    cart.export_start_code();
}

pub fn start() void {
    cart.set_vsync_enabled(1000.0 / 60.0);
    cart.set_double_buffer_mode(.{ .clear_full_frame = .rgb(0x202020) });
}

var last_controls: cart.Controls = @bitCast(@as(u16, 0));
var level: u8 = 10;

pub fn update() void {
    const controls = cart.controls.*;
    defer last_controls = controls;

    const pressed: cart.Controls = @fromBackingInt(@backingInt(controls) & ~@backingInt(last_controls));
    if (pressed.up) {
        level +|= 0x10;
    }
    if (pressed.right) {
        level +|= 1;
    }
    if (pressed.left) {
        level -|= 1;
    }
    if (pressed.down) {
        level -|= 0x10;
    }

    cart.neopixels.* = .{
        .{ .r = level, .g = 0, .b = 0 },
        .{ .r = 0, .g = level, .b = 0 },
        .{ .r = 0, .g = 0, .b = level },
        .{ .r = level >> 1, .g = 0, .b = level },
        .{ .r = level, .g = level, .b = level },
    };

    var buf: [20]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "LED: 0x{x:0>2}", .{level}) catch unreachable;

    cart.text(.{
        .str = text,
        .x = @intCast(cart.screen_width / 2 - 4 * text.len),
        .y = cart.screen_height / 2 - 4,
        .text_color = .rgb(0x7F00FF),
    });
}
