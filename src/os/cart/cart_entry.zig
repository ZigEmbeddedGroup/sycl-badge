//! OS Cart Entry Wrapper
//!
//! Bridges the old badge-v1 cart ABI (export fn start / export fn update)
//! into a single main() loop expected by MicroZig's startup.
//!
//! The build system injects the cart's source as "user_cart". Because the cart
//! uses `export fn start/update` (not `pub`), we declare them as extern symbols
//! and let the linker resolve them from the same binary.
const cart_api = @import("cart-api");

// Pull in the user cart module so its exported symbols are linked.
comptime {
    _ = @import("user_cart");
}

/// These are provided by the user cart as `export fn start()`/`export fn update()`.
extern fn start() void;
extern fn update() void;

/// Enable the FPU on Core 1.
///
/// MicroZig's start.zig calls app.init() instead of hal.init() when the app
/// provides one. The HAL init normally enables the FPU (CPACR bits [23:20])
pub fn init() void {
    // CPACR — Coprocessor Access Control Register (0xE000ED88)
    // Bits [23:20] = CP11:CP10 access. 0b11 each = full access.
    const CPACR: *volatile u32 = @ptrFromInt(0xE000ED88);
    // FPCCR — Floating-Point Context Control Register (0xE000EF34)
    const FPCCR: *volatile u32 = @ptrFromInt(0xE000EF34);

    // Enable lazy FP state preservation (bits 31:30 = ASPEN:LSPEN).
    FPCCR.* = FPCCR.* | (1 << 31) | (1 << 30);

    // Grant full access to CP10 and CP11 (the FPU).
    CPACR.* = CPACR.* | (0xF << 20);

    // Barriers so subsequent instructions see the new FPU state.
    asm volatile ("dsb");
    asm volatile ("isb");
}

pub fn main() noreturn {
    start();
    while (true) {
        update();
        // Signal Core 0 that this frame is complete and wait for the
        // LCD flush to finish before starting the next frame.
        cart_api.present();
    }
}
