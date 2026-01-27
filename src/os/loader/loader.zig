/// Program loader, loads user programs from flash to RAM
const std = @import("std");
const storage = @import("storage.zig");

pub const CartLoadRequest = extern struct {
    start_cluster: u16,
    size: u32,
};

var cart_loaded: bool = false;

// Cart buffer placed in dedicated process_ram region (384KB available)
// Using 320KB for cart data, leaving 64KB for interpreter runtime overhead
var cart_buffer: [320 * 1024]u8 linksection(".process_ram") = undefined;
var cart_size: usize = 0;

pub fn loadCart(info: storage.CartInfo) bool {
    if (info.size == 0 or info.size > cart_buffer.len) {
        return false;
    }
    const bytes = storage.readCart(info, cart_buffer[0..info.size]);
    if (bytes != info.size) {
        return false;
    }
    // TODO: Load cart with new interpreter here
    cart_size = bytes;
    cart_loaded = true;
    return true;
}

pub fn tick() void {
    if (cart_loaded) {
        // TODO: Execute cart with new interpreter here
    }
}

pub fn stop() void {
    // TODO: Stop cart execution with new interpreter here
    cart_loaded = false;
}
