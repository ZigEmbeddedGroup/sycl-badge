const std = @import("std");
const wasm4 = @import("wasm4");

export fn start() void {}

var green: u6 = 0;

export fn update() void {
    if (wasm4.controls.up) {
        green +%= 1;
    } else if (wasm4.controls.down) {
        green -%= 1;
    }

    for (0..wasm4.screen_height) |y| {
        for (0..wasm4.screen_width) |x| {
            wasm4.framebuffer[y * wasm4.screen_width + x] = .{
                .red = @intFromFloat(@as(f32, @floatFromInt(x)) / wasm4.screen_width * 31.0),
                .green = green,
                .blue = @intFromFloat(@as(f32, @floatFromInt(y)) / wasm4.screen_height * 31.0),
            };
        }
    }
}
