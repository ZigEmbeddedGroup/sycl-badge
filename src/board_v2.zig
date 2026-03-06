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

// ========================================
// TC2030-CTX-NL Debug Connector (6-pin Tag-Connect)
// ========================================
// This connector provides SWD debugging via external debugger (J-Link, Black Magic Probe, etc.):
//   Pin 1: VCC (target voltage reference)
//   Pin 2: SWDIO (Serial Wire Debug I/O)
//   Pin 3: nRESET (Reset)
//   Pin 4: SWCLK (Serial Wire Debug Clock)
//   Pin 5: GND
//   Pin 6: SWO/TDO (Serial Wire Output for printf-style debugging via debugger)
//
// Note: SWDIO, SWCLK, and SWO are dedicated ARM Cortex debug signals on the RP2354B.
// No firmware driver needed - debugging is handled by external hardware debugger.
// For printf-style debug output, use SWO with your debugger software (e.g., RTT or SWO viewer).

// LCD Display Pins (DT018BTFT-SHB on SPI0)
pub const TFT_CS = gpio.num(17); // SPI0 CSn
pub const TFT_SCK = gpio.num(18); // SPI0 SCK
pub const TFT_MOSI = gpio.num(19); // SPI0 TX (SDIO)
// pub const TFT_RST = gpio.num(21); // Reset (GPIO), tied to hardware
pub const TFT_DC = gpio.num(21); // Data/Command (GPIO)
pub const BKLT_PWM = gpio.num(16); // Backlight PWM (controls LED_K1 and LED_K2)
// Note: TFT_LITE (backlight) connected directly to VBUS (5V)
// Note: SPI4W tied to 3V3 (High = 4-wire SPI mode)

// LEDs
pub const led_pin = gpio.num(14); // regular LED
pub const neopixel_pin = gpio.num(15); // Neopixel data pin

// Buttons and Joystick
pub const joystick_up = gpio.num(37); // Connected to joystick up
pub const joystick_down = gpio.num(24); // Connected to joystick down
pub const joystick_left = gpio.num(35); // Connected to joystick left
pub const joystick_right = gpio.num(25); // Connected to joystick right
pub const joystick_click = gpio.num(36); // Joystick press in button
pub const button_a = gpio.num(6); // A1
pub const button_b = gpio.num(7); // B1
pub const button_start = gpio.num(5); // START1
pub const button_select = gpio.num(38); // SELECT1

// Alias for compatibility with existing demos
pub const A5_D13 = led_pin;

// Buzzer / Speaker (CMT-7525-80-SMT-TR)
pub const buzzer_enable = gpio.num(8); // SPKR_EN  - speaker enable (active-high)
pub const buzzer_pwm = gpio.num(9); // SPKR_A0  - PWM audio output (PWM slice 4, channel B)
