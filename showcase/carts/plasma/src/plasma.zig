const std = @import("std");
const cart = @import("cart-api");
const gfx = @import("gfx");

export fn start() void {}

export fn update() void {
    updatePlasma();
}

const hue_colors = init_hue_colors: {
    var initial_hue_colors: [256]cart.DisplayColor = undefined;
    for (0..initial_hue_colors.len) |i| {
        const fi: f32 = @floatFromInt(i);
        const rgb = hsv2rgb(fi * 360.0 / 256.0, 1, 1);
        initial_hue_colors[i] = .{
            .r = @intFromFloat(rgb.r * 31),
            .g = @intFromFloat(rgb.g * 63),
            .b = @intFromFloat(rgb.b * 31),
        };
    }
    break :init_hue_colors initial_hue_colors;
};

var plasma_buffer = init_plasma_buffer: {
    @setEvalBranchQuota(100000);
    var initial_plasma_buffer: [cart.screen_width][cart.screen_height]u8 = undefined;
    var y: usize = 0;
    while (y < cart.screen_height) : (y += 1) {
        var x: usize = 0;
        while (x < cart.screen_width) : (x += 1) {
            const fx: f32 = @floatFromInt(x);
            const fy: f32 = @floatFromInt(y);
            var value: f32 = @sin(fx / 16.0);
            value += @sin(fy / 8.0);
            value += @sin((fx + fy) / 16.0);
            value += @sin(@sqrt(fx * fx + fy * fy) / 8.0);
            // shift range from -4 .. 4 to 0 .. 255
            value = std.math.clamp((value + 4) * 32, 0, 255);
            initial_plasma_buffer[x][y] = @intFromFloat(value);
        }
    }
    break :init_plasma_buffer initial_plasma_buffer;
};

fn updatePlasma() void {
    for (cart.framebuffer, &plasma_buffer) |*fb_col, *plasma_col| {
        for (fb_col, plasma_col) |*fb_pix, *plasma_pix| {
            plasma_pix.* +%= 2;
            fb_pix.setColor(hue_colors[plasma_pix.*]);
        }
    }
}

const RGB = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub fn hsv2rgb(h: f32, s: f32, v: f32) RGB {
    const c = v * s;
    const x = c * (1 - @abs(@mod(h / 60.0, 2) - 1));
    const m = v - c;

    var r: f32 = 0.0;
    var g: f32 = 0.0;
    var b: f32 = 0.0;

    if (h < 60.0) {
        r = c;
        g = x;
        b = 0.0;
    } else if (h < 120.0) {
        r = x;
        g = c;
        b = 0.0;
    } else if (h < 180.0) {
        r = 0.0;
        g = c;
        b = x;
    } else if (h < 240.0) {
        r = 0.0;
        g = x;
        b = c;
    } else if (h < 300.0) {
        r = x;
        g = 0.0;
        b = c;
    } else {
        r = c;
        g = 0.0;
        b = x;
    }

    return RGB{
        .r = r + m,
        .g = g + m,
        .b = b + m,
    };
}
