//! OS Cart Entry Wrapper
//!
//! Bridges the old badge-v1 cart ABI (pub fn start / pub fn update)
//! into a single main() loop expected by MicroZig's startup.
//!
//! The build system injects the cart's source as "user_cart". Because the cart
//! uses `pub fn start/update` (not `pub`), we declare them as extern symbols
//! and let the linker resolve them from the same binary.
const microzig = @import("microzig");
const cart_api = @import("api.zig");

comptime {
    _ = microzig.export_startup();
}

// Pull in the user cart module so its exported symbols are linked.
const root = @import("root");

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

    // Grant full access to CP10, CP11, CP4, CP5 (the FPU).
    CPACR.* = 0xFFFF_FFFF;

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

    root.start();
    while (true) {
        // Keep the cycle counter accurate
        // TODO we could record uS times around each cart call,
        // to handle any large drift.
        _ = cart_api.cycles();

        root.update();
        // Signal Core 0 that this frame is complete and wait for the
        // LCD flush to finish before starting the next frame.
        cart_api.present();
    }
}
