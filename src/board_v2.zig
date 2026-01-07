//! Raspberry Pi Pico 2 Board Configuration (RP2350)
//!
//! LCD Pin Assignments for DT018BTFT-SHB:
//! - GP17: TFT_CS (Chip Select)
//! - GP18: TFT_SCK (SPI Clock)
//! - GP19: TFT_MOSI (SPI Data/SDIO)
//! - GP20: TFT_RST (Reset)
//! - GP21: TFT_DC (Data/Command)

const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;

// Export font for use by drivers
pub const font = @import("font.zig");

// Crystal oscillator frequency (12 MHz for Pico 2)
pub const xosc_freq = 12_000_000;

// Pico 2 has onboard LED on GPIO 25
pub const led_pin = gpio.num(25);

// Alias for compatibility with existing demos
pub const A5_D13 = led_pin;

// LCD Display Pins (DT018BTFT-SHB on SPI0)
pub const TFT_CS = gpio.num(17); // SPI0 CSn
pub const TFT_SCK = gpio.num(18); // SPI0 SCK
pub const TFT_MOSI = gpio.num(19); // SPI0 TX (SDIO)
pub const TFT_RST = gpio.num(20); // Reset (GPIO)
pub const TFT_DC = gpio.num(21); // Data/Command (GPIO)
// Note: TFT_LITE (backlight) connected directly to VBUS (5V)
// Note: SPI4W tied to 3V3 (High = 4-wire SPI mode)
