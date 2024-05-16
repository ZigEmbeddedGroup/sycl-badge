const std = @import("std");
const cart = @import("cart-api");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    @setCold(true);
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    unreachable;
}

const model: *const Mnist = @alignCast(@ptrCast(MNIST_WEIGHT));
export fn start() void {
    set_background();
}

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
const MNIST_WEIGHT: []const u8 align(64) = @embedFile("mnist.q2.bin");

const n_images = @divExact(MNIST_DATA.len - 16, @sizeOf(Img));

pub fn randomDigit() *const Img {
    const n = @rem(@divTrunc(step, 2), n_images);
    return @ptrCast(MNIST_DATA[16 + n * @sizeOf(Img) ..][0..@sizeOf(Img)]);
}

const Mnist = struct {
    //  784*500+500*10
    // 500, 10
    weight0: [500 * 784 / 4]u8,
    bias0: [500]f32,
    weight1: [10 * 500 / 4]u8,
    bias1: [10]f32,

    pub fn load(data: []const u8) Mnist {
        return std.mem.bytesToValue(Mnist, data);
    }

    pub inline fn forward(self: *const Mnist, img: *const Img) u5 {
        const x: *const [28 * 28]u8 = @alignCast(@ptrCast(&img));
        var hidden = quantMatmul(u8, 784, 500, &self.weight0, x);
        addBias(&hidden, &self.bias0);
        var out = quantMatmul(f32, 500, 10, &self.weight1, &hidden);
        addBias(&out, &self.bias1);

        var class: u5 = 0;
        var max: f32 = -1000;
        for (out, 0..) |score, c| {
            if (score > max) {
                class = @intCast(c);
                max = score;
            }
        }
        return class;
    }
};

fn quantMatmul(T: type, comptime N: usize, comptime M: usize, weights: []const u8, input: *const [N]T) [M]f32 {
    var res: [M]f32 = undefined;
    const splat_0: @Vector(8, T) = @splat(0);
    if (weights.len != M * @divExact(N, 4)) @panic("Unexpected weights.len");

    for (0..M) |i| {
        const row = i * @divExact(N, 4);
        var sum: f32 = 0;
        for (0..@divFloor(N, 8)) |j| {
            const x = std.mem.bytesToValue(@Vector(8, T), input[j * 8 .. j * 8 + 8]);
            const pos: @Vector(8, bool) = @bitCast(weights[row + 2 * j]);
            const neg: @Vector(8, bool) = @bitCast(weights[row + 2 * j + 1]);

            sum = accPos(sum, @reduce(.Add, @select(T, pos, x, splat_0)));
            sum = accNeg(sum, @reduce(.Add, @select(T, neg, x, splat_0)));
        }

        res[i] = sum;
    }
    return res;
}

inline fn accPos(sum: f32, x: anytype) f32 {
    return sum + switch (@typeInfo(@TypeOf(x))) {
        .Int => @as(f32, @floatFromInt(x)),
        .Float => x,
        else => @compileError("acc"),
    };
}

inline fn accNeg(sum: f32, x: anytype) f32 {
    return sum - switch (@typeInfo(@TypeOf(x))) {
        .Int => @as(f32, @floatFromInt(x)),
        .Float => x,
        else => @compileError("acc"),
    };
}

fn addBias(input: []f32, bias: []const f32) void {
    for (input, bias) |*x, b| x.* += b;
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
                    // TODO: use fg_color
                    const p: u5 = @intCast(px >> 3);
                    cart.framebuffer[y * cart.screen_width + x] = .{ .r = p, .g = p, .b = p };
                }
            }
        }
    }
    // model.weight0[0][0] = 1;
    var class: u5 = 0;
    // class = @intCast(@mod(@divTrunc(step, 240), 10));
    class = model.forward(img);

    const color = palette[class];
    inline for (cart.neopixels, 0..) |*neopixel, i| {
        const on = (class >> i) & 0x1;
        if (on >= 1) {
            neopixel.* = color;
        } else {
            neopixel.* = .{ .r = 0, .g = 0, .b = 0 };
        }
    }
}

const bg_color: cart.DisplayColor = .{ .r = 0x37 >> 3, .g = 0x2F >> 2, .b = 0x2A >> 3 };

const fg_color: cart.DisplayColor = .{ .r = 0xC2 >> 3, .g = 0xB7 >> 2, .b = 0xAE >> 3 };

const palette = [_]cart.NeopixelColor{
    .{ .r = 0xD0, .g = 0xC5, .b = 0xBC },
    .{ .r = 0x3F, .g = 0xA5, .b = 0xEA },
    .{ .r = 0x22, .g = 0x7E, .b = 0xFF },
    .{ .r = 0xEB, .g = 0x82, .b = 0x48 },
    .{ .r = 0xD6, .g = 0x74, .b = 0x79 },
    .{ .r = 0x7D, .g = 0xCB, .b = 0x6C },
    .{ .r = 0x71, .g = 0x6F, .b = 0xFF },
    .{ .r = 0xBC, .g = 0xBD, .b = 0x74 },
    .{ .r = 0x00, .g = 0x99, .b = 0x07 },
    .{ .r = 0x3E, .g = 0xA5, .b = 0x3E },
};

fn set_background() void {
    @memset(cart.framebuffer, bg_color);
}
