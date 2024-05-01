const cart = @import("cart-api");

export fn update() void {
    // Set background to a nice gray
    @memset(cart.framebuffer, cart.DisplayColor{
        .red = 10,
        .green = 20,
        .blue = 10,
    });
}
