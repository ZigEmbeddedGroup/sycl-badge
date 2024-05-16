const std = @import("std");
const cart = @import("cart-api");

export fn start() void {}

var pixel: u5 = 0;
export fn update() void {
    for (cart.framebuffer, 0..) |_, i| {
        @memset(cart.framebuffer[i .. i + 1], cart.DisplayColor{
            .r = pixel,
            .g = pixel + 1,
            .b = pixel + 2,
        });
        pixel += 1;
    }
}
