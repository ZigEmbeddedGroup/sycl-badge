/// Test XIP Cart
/// A simple test cart that demonstrates using the cart runtime
/// This cart turns on the LED solidly to show it's running on Core 1
///
/// Works on all RP2354B family boards (Pico 2, custom SYCL-badge, etc.)
const std = @import("std");
const cart = @import("cart_runtime");

// Memory constants for cart execution
// Stack is at top of process_ram: 0x20020000 + 384KB = 0x20080000
const STACK_TOP: u32 = 0x20080000;

// Entry point type for vector table
const EntryPoint = *const fn () callconv(.c) noreturn;

// Vector table - MUST be at the very start of the binary (offset 0)
// ARM Cortex-M: [0] = initial SP, [1] = Reset_Handler
// Using extern struct like zig-vector-table project
export var vector_table linksection(".isr_vector") = extern struct {
    initial_sp: u32 = STACK_TOP,
    reset: EntryPoint = _start,
}{};

/// Cart entry point - called directly from vector table
/// Initializes .data/.bss then calls main
fn _start() callconv(.c) noreturn {
    // Initialize .data and .bss sections using cart runtime
    cart.initSections();

    // Call user's main function
    main();

    // If main returns, loop forever
    while (true) {
        asm volatile ("wfi");
    }
}

// ============================================================================
// Board Configuration - Change these for your hardware
// ============================================================================

/// LED pin - GPIO 25 on Pico 2 dev board, TODO change for SYCL Badge V2
pub const LED_PIN: u5 = 25;

// ============================================================================
// Cart Setup
// ============================================================================

/// Use cart runtime's panic handler (blinks LED rapidly on panic)
pub const panic = cart.panic;

// ============================================================================
// Main Entry Point
// ============================================================================

/// Cart main function - called after safe initialization
/// At this point:
/// - .data section has been initialized (global variables work)
/// - .bss section has been zeroed
/// - Clocks and peripherals are NOT touched (Core 0 set them up)
pub fn main() void {
    // Initialize LED pin as output
    cart.hal.gpio.initOutput(LED_PIN);

    // Blink LED to verify cart is actually executing
    // Slow blink: 500ms on, 500ms off
    while (true) {
        cart.hal.gpio.setHigh(LED_PIN);
        cart.hal.timer.delayMs(500);
        cart.hal.gpio.setLow(LED_PIN);
        cart.hal.timer.delayMs(500);
    }
}
