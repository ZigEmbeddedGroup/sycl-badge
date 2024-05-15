const std = @import("std");
const cart = @import("cart-api");
const builtin = @import("builtin");

export fn start() void {}

var scene: enum { mnist } = .mnist;

var step: usize = 0;

export fn update() void {
    step +%= 1;
    switch (scene) {
        // .intro => scene_intro(),
        // .game => scene_game(),
        .mnist => scene_mnist(),
    }
}

const Img = [28][28]u8;
const MNIST_DATA = @embedFile("t10k-images.idx3-ubyte.small");
const n_images = @divExact(MNIST_DATA.len - 16, @sizeOf(Img));

pub fn randomDigit() Img {
    const n = @rem(@divTrunc(step, 2), n_images);
    const img: Img = @bitCast(MNIST_DATA[16 + n * @sizeOf(Img) ..][0..@sizeOf(Img)].*);
    return img;
}

const lines = &[_][]const u8{
    "Guillaume Wenzek",
    " //---\\\\ ",
    "//  Z  \\\\",
    "\\\\  ML //",
    " \\\\---// ",

    "",

    "SYCL24",
    "Press START",
};
const spacing = (cart.font_height * 4 / 3);

var ticks: u8 = 0;

fn scene_intro() void {
    set_background();

    @memset(cart.neopixels, .{
        .r = 0,
        .g = 0,
        .b = 0,
    });

    if (ticks / 128 == 0) {
        // Make the neopixel 24-bit color LEDs a nice Zig orange
        @memset(cart.neopixels, .{
            .r = @divFloor(247, 4),
            .g = @divFloor(164, 4),
            .b = @divFloor(29, 4),
        });
    }

    const y_start = (cart.screen_height - (cart.font_height + spacing * (lines.len - 1))) / 2;

    // Write it out!
    for (lines, 0..) |line, i| {
        cart.text(.{
            .text_color = .{ .r = 31, .g = 63, .b = 31 },
            .str = line,
            .x = @intCast((cart.screen_width - cart.font_width * line.len) / 2),
            .y = @intCast(y_start + spacing * i),
        });
    }

    if (ticks == 0) cart.red_led.* = !cart.red_led.*;
    if (cart.controls.start) scene = .mnist;

    ticks +%= 4;
}

const Player = enum(u8) { x = 0, o = 1, none = std.math.maxInt(u8) };

var selected_x: u8 = 0;
var selected_y: u8 = 0;
var control_cooldown: bool = false;
var turn: Player = .x;
var state: [3][3]Player = @bitCast([1]Player{.none} ** 9);

fn scene_mnist() void {
    set_background();
    const img = randomDigit();
    const scale = 2;
    const offy = @divExact(cart.screen_height - 28 * scale, 2);
    const offx = @divExact(cart.screen_width - 28 * scale, 2);
    for (img, 0..) |row, i| {
        for (row, 0..) |px, j| {
            for (0..scale) |ii| {
                for (0..scale) |jj| {
                    const x = offx + scale * j + jj;
                    const y = offy + scale * i + ii;
                    const p: u5 = @intCast(px >> 3);
                    cart.framebuffer[y * cart.screen_width + x] = .{ .r = p, .g = p, .b = p };
                }
            }
        }
    }
}

fn set_background() void {
    @memset(cart.framebuffer, cart.DisplayColor{
        .r = 0,
        .g = 0,
        .b = 0,
    });
}
