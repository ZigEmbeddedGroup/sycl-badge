const std = @import("std");
const cart = @import("cart-api");
const gfx = @import("gfx");

export fn start() void {
    // Clear garbage bytes from framebuffer at init since the whole screen is not cleared otherwise.
    for (cart.framebuffer[0..]) |*pos| {
        pos.* = .{ .r = 0, .b = 0, .g = 0 };
    }
}

var dvd_hue: f32 = 0;
var dvd_x: isize = 0;
var dvd_y: isize = 0;
var dvd_dx: isize = 2;
var dvd_dy: isize = 1;
var odd_frame = false;

// These things are super bright at full strength.
const neopixel_brightness = 10.0;

export fn update() void {
    const color = hsv_to_rgb(.{ .h = dvd_hue, .s = 1, .v = 1 });
    drawDvd(gfx.dvd, @intCast(dvd_x), @intCast(dvd_y), color);
    dvd_hue += 5;
    if (dvd_hue >= 360.0) dvd_hue = 0;

    // The DVD logo gets stuck hitting the places without a fractional angle.
    // Offset the dx every other frame to make it look a tiny bit more interesting.
    odd_frame = !odd_frame;
    dvd_x += if (odd_frame) dvd_dx else @divFloor((dvd_dx * 3), 2);
    dvd_y += dvd_dy;
    if (dvd_x < 0) {
        dvd_dx *= -1;
        dvd_x = 0;
    }
    if (dvd_y < 0) {
        dvd_dy *= -1;
        dvd_y = 0;
    }
    if (dvd_x >= cart.screen_width - gfx.dvd.width) {
        dvd_dx *= -1;
        dvd_x = cart.screen_width - gfx.dvd.width;
    }
    if (dvd_y >= cart.screen_height - gfx.dvd.height) {
        dvd_dy *= -1;
        dvd_y = cart.screen_height - gfx.dvd.height;
    }

    // Press A to light up the neopixels.
    // This was just so we could create a light show in the theater. :>
    const np_color: cart.NeopixelColor = if (cart.controls.a) .{
        .g = @intFromFloat(color.g * neopixel_brightness),
        .r = @intFromFloat(color.r * neopixel_brightness),
        .b = @intFromFloat(color.b * neopixel_brightness),
    } else .{ .g = 0, .r = 0, .b = 0 };
    cart.neopixels.* = .{np_color} ** 5;
}

pub fn drawDvd(sprite: anytype, pos_x: usize, pos_y: usize, color: Rgb) void {
    var y: usize = 0;
    while (y < sprite.height) : (y += 1) {
        var x: usize = 0;
        while (x < sprite.width) : (x += 1) {
            const dst_x = pos_x + x;
            const dst_y = pos_y + y;
            const index = y * sprite.width + x;
            const src = sprite.colors[sprite.indices.get(index)];
            var dst = &cart.framebuffer[dst_y * cart.screen_width + dst_x];
            dst.r = @intFromFloat(@as(f32, @floatFromInt(src.r)) * color.r);
            dst.g = @intFromFloat(@as(f32, @floatFromInt(src.g)) * color.g);
            dst.b = @intFromFloat(@as(f32, @floatFromInt(src.b)) * color.b);
            cart.framebuffer[dst_y * cart.screen_width + dst_x] = dst.*;
        }
    }
}

const Hsv = struct {
    h: f32,
    s: f32,
    v: f32,
};

const Rgb = struct {
    r: f32,
    g: f32,
    b: f32,
};

fn hsv_to_rgb(in: Hsv) Rgb {
    var hh: f32 = undefined;
    var p: f32 = undefined;
    var q: f32 = undefined;
    var t: f32 = undefined;
    var ff: f32 = undefined;
    var i: i32 = undefined;
    var out: Rgb = undefined;

    if (in.s <= 0.0) {
        out.r = in.v;
        out.g = in.v;
        out.b = in.v;
        return out;
    }
    hh = in.h;
    if (hh >= 360.0) hh = 0.0;
    hh /= 60.0;
    i = @intFromFloat(hh);
    ff = hh - @as(f32, @floatFromInt(i));
    p = in.v * (1.0 - in.s);
    q = in.v * (1.0 - (in.s * ff));
    t = in.v * (1.0 - (in.s * (1.0 - ff)));

    switch (i) {
        0 => {
            out.r = in.v;
            out.g = t;
            out.b = p;
        },
        1 => {
            out.r = q;
            out.g = in.v;
            out.b = p;
        },
        2 => {
            out.r = p;
            out.g = in.v;
            out.b = t;
        },
        3 => {
            out.r = p;
            out.g = q;
            out.b = in.v;
        },
        4 => {
            out.r = t;
            out.g = p;
            out.b = in.v;
        },
        else => {
            out.r = in.v;
            out.g = p;
            out.b = q;
        },
    }
    return out;
}
