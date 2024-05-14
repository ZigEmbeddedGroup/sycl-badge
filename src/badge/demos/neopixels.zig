const cart = @import("cart-api");

pub export fn start() void {
    cart.neopixels.* = if (cart.controls.a) .{
        .{ .r = 31, .g = 0, .b = 0 },
        .{ .r = 31, .g = 0, .b = 0 },
        .{ .r = 31, .g = 0, .b = 0 },
        .{ .r = 31, .g = 0, .b = 0 },
        .{ .r = 31, .g = 0, .b = 0 },
    } else .{
        .{ .r = 0, .g = 0, .b = 31 },
        .{ .r = 0, .g = 255, .b = 0 },
        .{ .r = 0, .g = 31, .b = 0 },
        .{ .r = 0, .g = 31, .b = 0 },
        .{ .r = 0, .g = 31, .b = 31 },
    };
}

pub export fn update() void {}
