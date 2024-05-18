const std = @import("std");
const cart = @import("cart-api");

const total_width = 67;
const total_height = 54;
const black: cart.DisplayColor = .{ .r = 0, .g = 0, .b = 0 };
const red: cart.DisplayColor = .{ .r = 31, .g = 0, .b = 0 };
const dark_red: cart.DisplayColor = .{ .r = 25, .g = 0, .b = 0 };

var tx: usize = 0;
var ty: usize = 0;
var sx: usize = 1;
var sy: usize = 1;
var color: cart.DisplayColor = black;

export fn start() void {
    r(0, 0, cart.screen_width, cart.screen_height);
    tx = cart.screen_width / 2 - total_width;
    ty = cart.screen_height / 2 - total_height;
    sx = 2;
    sy = 2;
}

fn r(x: usize, y: usize, w: usize, h: usize) void {
    // TODO: use cart API once it actually works on hardware
    if (false) {
        // cart.rect(.{
        //     .x = @intCast(tx + sx * x),
        //     .y = @intCast(ty + sy * y),
        //     .width = @intCast(sx * w),
        //     .height = @intCast(sy * h),
        //     .fill_color = color,
        // });
    } else {
        // backup impl
        const x0 = tx + sx * x;
        const x1 = x0 + sx * w;
        const y0 = ty + sy * y;
        const y1 = y0 + sy * h;
        for (y0..y1) |yi| {
            for (x0..x1) |xi| {
                cart.framebuffer[xi][yi].setColor(color);
            }
        }
    }
}

var save_tx: usize = undefined;
var save_ty: usize = undefined;
fn save() void {
    save_tx = tx;
    save_ty = ty;
}
fn restore() void {
    tx = save_tx;
    ty = save_ty;
}

fn alert() void {
    save();
    defer restore();
    tx += sx * 11;
    ty += sy * 2;

    r(1, 0, 6, 1);
    r(0, 1, 3, 5);
    r(3, 2, 3, 1);
    r(6, 1, 2, 5);

    r(9, 0, 3, 5);
    r(9, 5, 8, 1);

    r(18, 0, 3, 6);
    r(21, 0, 5, 1);
    r(21, 2, 4, 1);
    r(21, 5, 5, 1);

    r(27, 0, 3, 6);
    r(30, 0, 4, 1);
    r(33, 1, 2, 1);
    r(30, 2, 4, 1);
    r(33, 3, 2, 3);

    r(36, 0, 8, 1);
    r(38, 1, 3, 5);

    r(4, 7, 3, 1);
    r(8, 7, 1, 1);
    r(10, 7, 5, 1);
    r(17, 7, 5, 1);
    r(24, 7, 6, 1);
    r(32, 7, 1, 1);
    r(34, 7, 3, 1);
    r(38, 7, 1, 1);
}

fn alert_jap() void {
    save();
    defer restore();
    tx += sx * 8;
    ty += sy * 13;

    r(2, 0, 7, 1);
    r(1, 1, 3, 1);
    r(6, 1, 3, 1);
    r(5, 2, 2, 1);
    r(1, 3, 11, 1);
    r(1, 4, 2, 7);
    r(0, 11, 2, 1);
    r(4, 5, 6, 1);
    r(4, 6, 2, 5);
    r(8, 6, 2, 1);
    r(7, 7, 3, 1);
    r(5, 11, 7, 1);
    r(10, 10, 2, 1);

    r(14, 0, 5, 1);
    r(21, 0, 4, 1);
    r(14, 1, 2, 1);
    r(17, 1, 2, 1);
    r(20, 1, 2, 1);
    r(24, 1, 2, 1);
    r(14, 2, 4, 1);
    r(19, 2, 2, 1);
    r(25, 2, 2, 1);
    r(14, 3, 3, 1);
    r(20, 3, 6, 1);
    r(14, 4, 5, 1);
    r(14, 5, 2, 7);
    r(17, 5, 10, 1);
    r(17, 6, 4, 1);
    r(22, 6, 2, 1);
    r(25, 6, 2, 1);
    r(17, 7, 10, 1);
    r(17, 8, 2, 1);
    r(16, 9, 2, 1);
    r(22, 8, 2, 1);
    r(21, 9, 4, 1);
    r(20, 10, 2, 1);
    r(24, 10, 2, 1);
    r(19, 11, 2, 1);
    r(25, 11, 2, 1);
}

var pulse: u5 = 0;

const Segments = struct {
    t: bool = true,
    c: bool = true,
    b: bool = true,
    l0: bool = true,
    l1: bool = true,
    r0: bool = true,
    r1: bool = true,

    fn fromNum(num: usize) Segments {
        return switch (num) {
            0 => .{ .c = false },
            1 => .{ .t = false, .c = false, .b = false, .l0 = false, .l1 = false },
            2 => .{ .l0 = false, .r1 = false },
            3 => .{ .l0 = false, .l1 = false },
            4 => .{ .t = false, .b = false, .l1 = false },
            5 => .{ .l1 = false, .r0 = false },
            6 => .{ .r0 = false },
            7 => .{ .c = false, .b = false, .l0 = false, .l1 = false },
            8 => .{},
            9 => .{ .l1 = false },
            else => unreachable,
        };
    }
};

fn digit(x: usize, y: usize, num: usize) void {
    save();
    defer restore();
    tx += sx * x;
    ty += sy * y;

    const segments = Segments.fromNum(num);

    color = if (segments.t) black else dark_red;
    r(1, 0, 8, 1);
    r(2, 1, 6, 1);

    color = if (segments.c) black else dark_red;
    r(2, 7, 6, 1);
    r(1, 8, 8, 1);

    color = if (segments.b) black else dark_red;
    r(2, 14, 6, 1);
    r(1, 15, 8, 1);

    color = if (segments.l0) black else dark_red;
    r(0, 1, 1, 7);
    r(1, 2, 1, 5);

    color = if (segments.l1) black else dark_red;
    r(0, 9, 1, 6);
    r(1, 10, 1, 4);

    color = if (segments.r0) black else dark_red;
    r(9, 1, 1, 7);
    r(8, 2, 1, 5);

    color = if (segments.r1) black else dark_red;
    r(9, 9, 1, 6);
    r(8, 10, 1, 4);
    color = black;
}

var counter: usize = 0;

fn text_lines() void {
    save();
    defer restore();
    tx += sx * 37;
    ty += sy * 14;

    const lines = [_][]const u8{
        &.{ 0, 3, 4, 8, 13, 1, 15, 6, 22, 2 },
        &.{ 3, 2, 6, 8, 15, 7, 23, 1 },
        &.{ 0, 6, 8, 7, 16, 1, 18, 6 },
        &.{ 0, 5, 7, 9, 17, 7 },
        &.{ 0, 3, 4, 8, 14, 6, 21, 3 },
        &.{ 0, 1, 2, 9, 12, 4, 18, 4 },
    };
    const max_char = counter / 20;
    const max_x = max_char % 24;
    const line1 = max_char / 24;
    var line0: usize = 0;
    if (line1 > 6) line0 = line1 - 6;
    var y: usize = 0;
    for (line0..line1) |line_i| {
        const line = lines[line_i % lines.len];
        for (0..line.len / 2) |i| {
            r(line[2 * i + 0], y, line[2 * i + 1], 1);
        }
        y += 2;
    }
    const line = lines[line1 % lines.len];
    for (0..line.len / 2) |i| {
        const x0 = line[2 * i + 0];
        if (x0 >= max_x) break;
        const x1 = @min(max_x, x0 + line[2 * i + 1]);
        r(x0, y, x1 - x0, 1);
    }
}

export fn update() void {
    color = red;
    r(0, 0, total_width, 1);
    r(0, 11, total_width, total_height - 11);
    pulse +%= 2;
    color = .{ .r = 31 - pulse, .g = 0, .b = 0 };
    r(0, 1, total_width, 10);
    color = red;
    alert();
    color = black;
    alert_jap();
    text_lines();
    r(6, 29, 55, 2);
    counter += 17;
    if (counter > 9999) counter = 9999;
    if (cart.controls.start) counter = 0;
    const num = 9999 - counter;
    digit(8, 33, num / 1000);
    digit(20, 33, (num / 100) % 10);
    r(32, 47, 3, 2);
    digit(37, 33, (num / 10) % 10);
    digit(49, 33, num % 10);
    r(6, 51, 55, 2);
}
