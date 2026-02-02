/// Cart Runtime - Minimal startup for carts running on Core 1
///
/// This provides a safe startup for carts that:
/// - Initializes .data and .bss sections (for global variables)
/// - Does NOT reinitialize clocks or peripherals (Core 0 handles this)
/// - Provides HAL access via cart_hal.zig
///
/// Usage in cart main.zig:
///   const cart = @import("cart_runtime");
///   pub const panic = cart.panic;
///
///   pub fn main() void {
///       // Initialize LED pin (use your board's LED pin)
///       cart.hal.gpio.initOutput(25);
///       cart.hal.gpio.setHigh(25);
///       // ...
///   }
const std = @import("std");

/// Re-export the hardware abstraction layer
pub const hal = @import("cart_hal.zig");

// Linker symbols for data/bss initialization
extern var microzig_data_start: [*]u8;
extern var microzig_data_end: [*]u8;
extern const microzig_data_load_start: [*]const u8;
extern var microzig_bss_start: [*]u8;
extern var microzig_bss_end: [*]u8;

// Vector table is defined in the cart's main.zig using inline assembly
// This ensures it's at offset 0 in the binary

/// Cart entry point - called from vector table
/// Initializes data/bss then calls user's main
pub export fn _start() callconv(.c) noreturn {
    // Initialize .data section (copy from flash to RAM)
    initData();

    // Initialize .bss section (zero fill)
    initBss();

    // Call user's main function
    // The user should define: pub fn main() void { ... }
    if (@hasDecl(root, "main")) {
        root.main();
    }

    // If main returns, loop forever
    while (true) {
        asm volatile ("wfi");
    }
}

/// Initialize .data and .bss sections
/// Call this at the start of your _start function
pub fn initSections() void {
    initData();
    initBss();
}

/// Initialize .data section by copying from flash
fn initData() void {
    const data_start = @intFromPtr(microzig_data_start);
    const data_end = @intFromPtr(microzig_data_end);
    const load_start = @intFromPtr(microzig_data_load_start);

    if (data_end > data_start) {
        const len = data_end - data_start;
        const dest: [*]u8 = @ptrFromInt(data_start);
        const src: [*]const u8 = @ptrFromInt(load_start);
        @memcpy(dest[0..len], src[0..len]);
    }
}

/// Initialize .bss section by zeroing
fn initBss() void {
    const bss_start = @intFromPtr(microzig_bss_start);
    const bss_end = @intFromPtr(microzig_bss_end);

    if (bss_end > bss_start) {
        const len = bss_end - bss_start;
        const dest: [*]u8 = @ptrFromInt(bss_start);
        @memset(dest[0..len], 0);
    }
}

/// Reference to the root module (user's main.zig)
const root = @import("root");

// ============================================================================
// Convenience re-exports from HAL
// ============================================================================

/// GPIO functions
pub const gpio = hal.gpio;

/// Timer functions
pub const timer = hal.timer;

/// Simple delay in cycles
pub const delayCycles = hal.delayCycles;

/// Delay in microseconds
pub fn delayUs(us: u32) void {
    hal.timer.delayUs(us);
}

/// Delay in milliseconds
pub fn delayMs(ms: u32) void {
    hal.timer.delayMs(ms);
}

// ============================================================================
// Panic Handler
// ============================================================================

/// Panic handler for carts - blinks LED rapidly
/// Cart should set: pub const panic = cart.panic;
/// And define LED_PIN or it will use GPIO 25 by default
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = msg;

    // Try to get LED pin from user code, default to 25
    const led_pin: u5 = if (@hasDecl(root, "LED_PIN")) root.LED_PIN else 25;

    // Initialize LED pin for panic indication
    hal.gpio.initOutput(led_pin);

    // Rapid blink to indicate panic
    while (true) {
        hal.gpio.toggle(led_pin);
        hal.delayCycles(500_000); // Fast blink
    }
}
