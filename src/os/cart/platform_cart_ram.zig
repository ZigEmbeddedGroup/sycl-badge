//! OS Cart Platform Wrapper
//!

// Pull in the user cart module so its exported symbols are linked.
const root = @import("root");
const cart_api = @import("api.zig");

const start_code = struct {
    const cd = @import("cart_descriptor.zig");

    // Variables exported by the linker script
    extern var __bss_start__: u8;
    extern var __bss_end__: u8;

    export const cart_descriptor: cd.CartDescriptorTable linksection(".cart_descriptor") = .{
        .bss_start = &__bss_start__,
        .bss_end = &__bss_end__,
        .entry_point = &_start,
    };
};

pub fn export_start_code() void {
    comptime {
        _ = start_code;
    }
}

export fn _start() callconv(.c) void {
    // Sync the timer with the other core for tracy
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
