//! OS Cart Entry Wrapper
//!
//! Bridges the old badge-v1 cart ABI (export fn start / export fn update)
//! into a single main() loop expected by MicroZig's startup.
//!
//! The build system injects the cart's source as "user_cart". Because the cart
//! uses `export fn start/update` (not `pub`), we declare them as extern symbols
//! and let the linker resolve them from the same binary.
const builtin = @import("builtin");
const cart_api = @import("cart-api");
const cd = @import("cart_descriptor.zig");

// Variables exported by the linker script
extern var __bss_start__: u8;
extern var __bss_end__: u8;

export const cart_descriptor: cd.CartDescriptorTable linksection(".cart_descriptor") = .{
    .bss_start = &__bss_start__,
    .bss_end = &__bss_end__,
    .entry_point = &_start,
};

// Pull in the user cart module so its exported symbols are linked.
const user_cart = @import("user_cart");
comptime {
    _ = user_cart;
}

// ─── Panic Handler ────────────────────────────────────────────────────────────
// If the user cart defines `pub fn panic`, wire it up as the root-module panic
// so Zig uses it instead of microzig.panic (which calls @breakpoint() → HardFault).
// If not, fall back to a default that sends the message via cart.trace() and halts
// with WFE so Core 0 has time to print it before the system freezes.

fn default_panic(msg: []const u8, _: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    cart_api.trace(msg);
    while (true) {
        switch (comptime builtin.cpu.arch) {
            .wasm32, .wasm64 => {},
            else => asm volatile ("wfe"),
        }
    }
}

pub const panic = if (@hasDecl(user_cart, "panic"))
    user_cart.panic
else
    default_panic;

/// These are provided by the user cart as `export fn start()`/`export fn update()`.
extern fn start() void;
extern fn update() void;

export fn _start() callconv(.c) void {
    start();
    while (true) {
        update();
        // Signal Core 0 that this frame is complete and wait for the
        // LCD flush to finish before starting the next frame.
        cart_api.present();
    }
}
