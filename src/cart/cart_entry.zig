/// Cart Entry Wrapper for MicroZig Carts
///
/// This module is automatically used by the build system when building MicroZig carts.
/// It provides:
/// - Init override that prevents hardware reinitialization (Core 0 already did that)
/// - Re-exports user's main function
///
/// The vector table and _start are provided by MicroZig's CPU startup code.
/// Our linker script (cart_xip.ld) places them at 0x101C0000.
///
/// Users don't need to import this - the build system handles it automatically.
/// Just write normal MicroZig code with a `main` function.
const std = @import("std");
const microzig = @import("microzig");

/// User's cart code (injected by build system as "user_main" module)
const user = @import("user_main");

// ============================================================================
// Init Override
// ============================================================================

/// Override MicroZig's init function
/// MicroZig checks for this and calls it instead of HAL init if present.
/// We leave it empty because Core 0 already configured all hardware.
/// This is critical for carts running on Core 1!
pub fn init() void {
    // Do nothing - Core 0 has already initialized:
    // - Clocks (XOSC, PLLs, clock generators)
    // - Peripheral resets
    // - GPIO pads
    // - Timers
    // Reinitializing these would crash Core 0.
}

// ============================================================================
// Re-exports
// ============================================================================

/// Re-export user's main function
/// MicroZig's start.zig will call this after init()
pub const main = user.main;

/// Re-export user's panic handler if they provide one
/// Otherwise use microzig's panic handler
pub const panic = if (@hasDecl(user, "panic"))
    user.panic
else
    microzig.panic;

/// Re-export std_options if user provides them
pub const std_options = if (@hasDecl(user, "std_options")) user.std_options else struct {};
