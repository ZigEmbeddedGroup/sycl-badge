//! SYCL Badge V2 Board Configuration (RP2354B)
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

// Crystal oscillator frequency (12 MHz for SYCL Badge V2)
pub const xosc_freq = 12_000_000;

// ========================================
// Pin Assignments
// ========================================

// UART Pins (UART0)
pub const UART0_TX = gpio.num(0);
pub const UART0_RX = gpio.num(1);

// LCD Display Pins (DT018BTFT-SHB on SPI0)
pub const TFT_CS = gpio.num(17); // SPI0 CSn
pub const TFT_SCK = gpio.num(18); // SPI0 SCK
pub const TFT_MOSI = gpio.num(19); // SPI0 TX (SDIO)
pub const TFT_RST = gpio.num(20); // Reset (GPIO)
pub const TFT_DC = gpio.num(21); // Data/Command (GPIO)
// Note: TFT_LITE (backlight) connected directly to VBUS (5V)
// Note: SPI4W tied to 3V3 (High = 4-wire SPI mode)

// Onboard LED (GPIO 25)
pub const led_pin = gpio.num(25);

// Navigation / directional buttons
pub const button_up = gpio.num(10);
pub const button_down = gpio.num(11);
// TODO: assign real GPIOs (I put them down as placeholders)
// pub const button_left = gpio.num(4);
// pub const button_right = gpio.num(5);

// Action buttons (I put them down as placeholders)
// TODO: assign real GPIOs 
// pub const button_a = gpio.num(2);
// pub const button_b = gpio.num(3);
// pub const button_start = gpio.num(6);
// pub const button_select = gpio.num(7);
// pub const button_click = gpio.num(8);

// OS-level button (stop running cart)
pub const button_stop = gpio.num(15);

// Alias for compatibility with existing demos
pub const A5_D13 = led_pin;
