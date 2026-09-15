const cart = @import("cart-api");
const std = @import("std");

comptime {
    cart.export_start_code();
}

pub fn start() void {
    // Set the two buffers to all black and all white. Tearing lines will show clearly in the LCD.
    @memset(@as(*[cart.screen_width * cart.screen_height]u16, @ptrCast(cart.framebuffer)), 0);
    @memset(@as(*[cart.screen_width * cart.screen_height]u16, @ptrCast(cart.frontbuffer)), 0xFFFF);
}

pub fn update() void {
    // Force the whole screen to refresh
    cart.markDirtyRect(0, 0, cart.screen_width, cart.screen_height);
}
