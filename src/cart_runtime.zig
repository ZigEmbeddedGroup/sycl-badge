/// Cart Runtime - Minimal startup for carts running on Core 1
///
/// This provides a safe startup for carts that:
/// - Initializes .data and .bss sections (for global variables)
/// - Does NOT reinitialize clocks or peripherals (Core 0 handles this)
/// - Allows carts to use microzig HAL for peripheral access
///
/// Usage in cart main.zig:
///   const cart = @import("cart_runtime");
///   pub const panic = cart.panic;
///
///   pub fn main() void {
///       // Your cart code here - use cart.gpio, cart.delay, etc.
///   }
const std = @import("std");
pub const microzig = @import("microzig");

// Linker symbols for data/bss initialization
extern var microzig_data_start: [*]u8;
extern var microzig_data_end: [*]u8;
extern const microzig_data_load_start: [*]const u8;
extern var microzig_bss_start: [*]u8;
extern var microzig_bss_end: [*]u8;

// Stack top (from linker script)
extern const __stack_top__: u32;

/// Vector table - placed at start of flash by linker
/// ARM Cortex-M: [0] = initial SP, [1] = Reset_Handler
export const vector_table linksection(".vectors") = [_]usize{
    @intFromPtr(&__stack_top__), // Initial stack pointer
    @intFromPtr(&_start), // Reset handler
};

/// Cart entry point - called from vector table
/// Initializes data/bss then calls user's main
export fn _start() callconv(.c) noreturn {
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

// Re-export useful microzig components for carts
pub const hal = microzig.hal;
pub const chip = microzig.chip;
pub const cpu = microzig.cpu;
pub const peripherals = microzig.chip.peripherals;

// Convenience peripheral access
pub const SIO = peripherals.SIO;
pub const IO_BANK0 = peripherals.IO_BANK0;
pub const PADS_BANK0 = peripherals.PADS_BANK0;
pub const TIMER0 = peripherals.TIMER0;

/// GPIO helper functions that are safe for carts (only affect specified pins)
pub const gpio = struct {
    /// Set a GPIO pin to SIO function and configure as output
    pub fn initOutput(comptime pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;

        // Set function to SIO (function 5)
        const ctrl_reg = @as(*volatile u32, @ptrFromInt(
            @intFromPtr(IO_BANK0) + 0x04 + (@as(usize, pin) * 8),
        ));
        ctrl_reg.* = 5; // SIO function

        // Enable output
        SIO.GPIO_OE_SET.write(.{ .GPIO_OE_SET = pin_mask });
    }

    /// Set a GPIO pin high
    pub fn setHigh(comptime pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;
        SIO.GPIO_OUT_SET.write(.{ .GPIO_OUT_SET = pin_mask });
    }

    /// Set a GPIO pin low
    pub fn setLow(comptime pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;
        SIO.GPIO_OUT_CLR.write(.{ .GPIO_OUT_CLR = pin_mask });
    }

    /// Toggle a GPIO pin
    pub fn toggle(comptime pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;
        SIO.GPIO_OUT_XOR.write(.{ .GPIO_OUT_XOR = pin_mask });
    }

    /// Read a GPIO pin state
    pub fn read(comptime pin: u5) bool {
        const pin_mask: u32 = @as(u32, 1) << pin;
        return (SIO.GPIO_IN.read().GPIO_IN & pin_mask) != 0;
    }
};

/// Simple delay using busy loop
pub fn delay(cycles: u32) void {
    var i: u32 = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("nop");
    }
}

/// Delay in approximate milliseconds (assuming 150MHz clock)
pub fn delayMs(ms: u32) void {
    delay(ms * 150_000);
}

/// Panic handler for carts - blinks LED rapidly
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = msg;

    // Try to blink LED on GPIO 25 to indicate panic
    const LED_PIN: u5 = 25;
    gpio.initOutput(LED_PIN);

    while (true) {
        gpio.toggle(LED_PIN);
        delay(500_000); // Fast blink
    }
}
