/// SYCL Badge V2 Board Configuration (RP2354B)
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;

// Export font for use by drivers
pub const font = @import("font.zig");

// Crystal oscillator frequency (12 MHz for SYCL Badge V2)
pub const xosc_freq = 12_000_000;

// ========================================
// Pin Assignments
// ========================================

// UART Pins (UART0)
pub const UART0_TX = gpio.num(0);
pub const UART0_RX = gpio.num(1);

// LCD Display Pins (DT018BTFT-SHB on SPI0)
pub const TFT_CS = gpio.num(19); // SPI0 CSn
pub const TFT_SCK = gpio.num(23); // SPI0 SCK
pub const TFT_MOSI = gpio.num(21); // SPI0 TX (SDIO)
// pub const TFT_RST = gpio.num(20); // Reset (GPIO) - tied to hardware
pub const TFT_DC = gpio.num(22); // Data/Command (GPIO)
pub const BKLT_PWM = gpio.num(18); // Backlight PWM
// Note: TFT_LITE (backlight) connected directly to VBUS (5V)
// Note: SPI4W tied to 3V3 (High = 4-wire SPI mode)

// Neopixel LEDs
pub const led_pin = gpio.num(14); // regular LED
pub const neopixel_pin = gpio.num(15); // Neopixel data pin

// Alias for compatibility with existing demos
// pub const A5_D13 = led_pin;
