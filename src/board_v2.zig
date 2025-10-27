//! Raspberry Pi Pico 2 Board Configuration (RP2350)

const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;

// Crystal oscillator frequency (12 MHz for Pico 2)
pub const xosc_freq = 12_000_000;

// Pico 2 has onboard LED on GPIO 25
pub const led_pin = gpio.num(25);

// Alias for compatibility with existing demos
pub const A5_D13 = led_pin;
