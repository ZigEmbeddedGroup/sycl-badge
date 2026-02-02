/// Test XIP Cart
/// A simple test cart that demonstrates using the cart runtime with microzig
/// This cart turns on the LED solidly to show it's running
const std = @import("std");
const cart = @import("cart_runtime");

// Use cart runtime's panic handler
pub const panic = cart.panic;

// LED pin (GPIO 25 on Pico 2)
const LED_PIN: u5 = 25;

/// Cart main function - called by cart runtime after initialization
pub fn main() void {
    // Initialize GPIO 25 as output
    cart.gpio.initOutput(LED_PIN);

    // Turn LED ON solidly (not blinking) to show cart is running
    cart.gpio.setHigh(LED_PIN);

    // Loop forever - LED stays on, Core 0 continues running
    while (true) {
        asm volatile ("nop");
    }
}
