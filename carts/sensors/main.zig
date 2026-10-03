const cart = @import("cart-api");
const std = @import("std");

comptime {
    cart.export_start_code();
}

pub fn start() void {
    cart.set_vsync_enabled(1000.0 / 60.0);
    cart.set_double_buffer_mode(.{ .clear_full_frame = .rgb(0x202020) });
}

pub fn update() void {
    var y: i32 = 5;
    line(&y, "light", cart.light_level.val);
    line(&y, "bat", cart.battery_level.*);
}

fn line(cur_y: *i32, name: []const u8, raw_level: anytype) void {
    var buf: [64]u8 = undefined;
    const raw_level_fmt: []const u8 = switch (@TypeOf(raw_level)) {
        // zig fmt: off
        u8  => " 0x{x:0>2}",
        u12 => "0x{x:0>3}",
        // zig fmt: on
        else => comptime unreachable,
    };
    const str = std.fmt.bufPrint(&buf, "{s:>5}  " ++ raw_level_fmt ++ "  {d: >3}%", .{
        name,
        raw_level,
        @as(u32, raw_level) * 100 / std.math.maxInt(@TypeOf(raw_level)),
    }) catch unreachable;
    cart.text(.{ .str = str, .x = 5, .y = cur_y.*, .text_color = .rgb(0xFFFFFF) });
    cur_y.* += 10;
}
