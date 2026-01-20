/// Program loader, loads user programs from flash to RAM
const std = @import("std");
const storage = @import("storage.zig");
const wasm = @import("wasm.zig");

pub const CartLoadRequest = extern struct {
    start_cluster: u16,
    size: u32,
};

var runtime: wasm.Runtime = .{};
var cart_loaded: bool = false;

pub fn loadCart(info: storage.CartInfo) bool {
    if (info.size == 0 or info.size > wasm.MAX_CART_SIZE) {
        return false;
    }
    const bytes = storage.readCart(info, wasm.cartBuffer()[0..info.size]);
    if (bytes != info.size) {
        return false;
    }
    runtime.stop();
    if (runtime.load(wasm.cartBuffer()[0..bytes])) {
        runtime.start();
        cart_loaded = true;
        return true;
    }
    return false;
}

pub fn tick() void {
    if (cart_loaded) {
        runtime.update();
    }
}

pub fn stop() void {
    runtime.stop();
    cart_loaded = false;
}
