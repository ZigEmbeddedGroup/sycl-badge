const cart = @import("cart-api");

export fn update() void {
    // Set background to a nice gray
    @memset(cart.framebuffer, cart.DisplayColor{
        .r = 10,
        .g = 20,
        .b = 10,
    });
}
