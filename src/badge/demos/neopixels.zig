const cart = @import("cart-api");

pub export fn start() void {
    cart.neopixels.* = .{
        .{ .r = 0, .g = 0, .b = 31 },
        .{ .r = 0, .g = 31, .b = 0 },
        .{ .r = 0, .g = 31, .b = 0 },
        .{ .r = 0, .g = 31, .b = 0 },
        .{ .r = 0, .g = 31, .b = 0 },
    };
}

pub export fn update() void {}
