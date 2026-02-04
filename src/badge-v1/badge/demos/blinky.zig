const microzig = @import("microzig");

// this file has been updated for SYCL Badge V2 (RP2354B)
const gpio = microzig.hal.gpio;
const time = microzig.hal.time;

// Pico 2 has LED on GPIO 25
const led_pin = gpio.num(25);

pub fn main() !void {
    // Initialize the LED pin as output
    led_pin.set_function(.sio);
    led_pin.set_direction(.out);

    while (true) {
        led_pin.put(1); // Turn LED on
        time.sleep_ms(250);
        led_pin.put(0); // Turn LED off
        time.sleep_ms(250);
    }
}
