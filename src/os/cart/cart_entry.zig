//! OS Cart Entry Wrapper
//!
//! Bridges the old badge-v1 cart ABI (export fn start / export fn update)
//! into a single main() loop expected by MicroZig's startup.
//!
//! The build system injects the cart's source as "user_cart". Because the cart
//! uses `export fn start/update` (not `pub`), we declare them as extern symbols
//! and let the linker resolve them from the same binary.
const builtin = @import("builtin");
const microzig = @import("microzig");
const cart_api = @import("cart-api");

comptime {
    _ = microzig.export_startup();
}

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

    // Barriers so subsequent instructions see the new FPU/VTOR state.
    asm volatile ("dsb");
    asm volatile ("isb");
}

pub fn main() noreturn {
    // Carts use a polling model (buttons from IPC + present handshake), so
    // mask interrupts on Core 1 to avoid unexpected IRQ vectors in user carts.
    microzig.interrupt.disable_interrupts();

    // Enable cycle counter and sync the timer with the other core for tracy
    microzig.chip.peripherals.PPB.DWT_CTRL.modify(.{ .CYCCNTENA = 1 });
    cart_api.os_align_cycles();

    start();
    while (true) {
        // Keep the cycle counter accurate
        // TODO we could record uS times around each cart call,
        // to handle any large drift.
        _ = cart_api.cycles();

        update();
        // Signal Core 0 that this frame is complete and wait for the
        // LCD flush to finish before starting the next frame.
        cart_api.present();
    }
}
