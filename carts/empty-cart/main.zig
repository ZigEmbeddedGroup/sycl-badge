//! This file is the minimum boilerplate for a cart.
//! Fill it in with your code!

/// The cart module contains utilities for interacting
/// with the badge. Check src/os/cart/api.zig for details!
const cart = @import("cart-api");

// This block exports the hooks that the platform
// (either the badge OS or the simulator)
// will use to start the cart.
comptime {
    cart.export_start_code();
}

/// This function runs first, to set up the cart.
pub fn start() void {
    // Your code here!
}

/// This function is called repeatedly. The screen
/// will be updated every time this function returns.
pub fn update() void {
    // Your code here!
}
