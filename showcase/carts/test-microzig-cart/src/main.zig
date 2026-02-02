/// Test MicroZig Cart
///
/// This is a standard MicroZig program - no special cart imports needed!
/// The build system automatically handles the init override to safely run on Core 1.
///
/// This cart blinks the LED using MicroZig's HAL to demonstrate full HAL access.
const microzig = @import("microzig");
const hal = microzig.hal;
const time = hal.time;
const gpio = hal.gpio;

/// LED pin - GPIO 25 on Pico 2
const LED_PIN = gpio.num(25);

/// Standard MicroZig main function
/// The build system wraps this with cart_entry.zig which:
/// - Provides empty init() to skip hardware reinitialization
/// - Re-exports this main function
/// This prevents crashing Core 0 which already initialized hardware.
pub fn main() !void {
    // Configure LED pin as SIO (software-controlled GPIO) and output
    LED_PIN.set_function(.sio);
    LED_PIN.set_direction(.out);

    // Blink LED to show cart is running
    // Slow blink (1 second period) to differentiate from panic blink
    while (true) {
        LED_PIN.toggle();
        time.sleep_ms(500);
    }
}
