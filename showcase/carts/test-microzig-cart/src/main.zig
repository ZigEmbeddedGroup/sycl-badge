/// Test MicroZig Cart - LCD Demo
///
/// This cart demonstrates using the LCD via MicroZig's SPI HAL.
/// It cycles through solid colors to show the cart can control the display.
///
/// The build system automatically handles the init override to safely run on Core 1.
/// Hardware (SPI, clocks) is already configured by the OS on Core 0.
const microzig = @import("microzig");
const hal = microzig.hal;
const time = hal.time;
const gpio = hal.gpio;
const spi = hal.spi;

// ============================================================================
// Pin Configuration (must match board_v2.zig)
// ============================================================================

const TFT_CS = gpio.num(17); // Chip Select
const TFT_DC = gpio.num(21); // Data/Command
const LED_PIN = gpio.num(25); // LED for status

// ============================================================================
// LCD Commands (ST7735)
// ============================================================================

const CMD_CASET: u8 = 0x2A; // Column address set
const CMD_RASET: u8 = 0x2B; // Row address set
const CMD_RAMWR: u8 = 0x2C; // Memory write

// Display dimensions
const LCD_WIDTH: u16 = 160;
const LCD_HEIGHT: u16 = 128;

// ============================================================================
// Colors (RGB565 format)
// ============================================================================

const COLOR_RED: u16 = 0xF800;
const COLOR_GREEN: u16 = 0x07E0;
const COLOR_BLUE: u16 = 0x001F;
const COLOR_WHITE: u16 = 0xFFFF;
const COLOR_BLACK: u16 = 0x0000;
const COLOR_YELLOW: u16 = 0xFFE0;
const COLOR_CYAN: u16 = 0x07FF;
const COLOR_MAGENTA: u16 = 0xF81F;

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    // Configure control pins as GPIO outputs
    TFT_CS.set_function(.sio);
    TFT_DC.set_function(.sio);
    LED_PIN.set_function(.sio);

    TFT_CS.set_direction(.out);
    TFT_DC.set_direction(.out);
    LED_PIN.set_direction(.out);

    // Start with CS high (deselected)
    TFT_CS.put(1);

    // Turn on LED to show cart is running
    LED_PIN.put(1);

    // Color cycle
    const colors = [_]u16{
        COLOR_RED,
        COLOR_GREEN,
        COLOR_BLUE,
        COLOR_YELLOW,
        COLOR_CYAN,
        COLOR_MAGENTA,
        COLOR_WHITE,
        COLOR_BLACK,
    };

    var color_idx: usize = 0;

    while (true) {
        // Fill screen with current color
        fillScreen(colors[color_idx]);

        // Toggle LED to show activity
        LED_PIN.toggle();

        // Next color
        color_idx = (color_idx + 1) % colors.len;

        // Wait before changing color
        time.sleep_ms(1000);
    }
}

// ============================================================================
// LCD Functions
// ============================================================================

/// Fill the entire screen with a solid color
fn fillScreen(color: u16) void {
    // Set column address range (0 to LCD_WIDTH-1)
    sendCommand(CMD_CASET);
    sendData16(0);
    sendData16(LCD_WIDTH - 1);

    // Set row address range (0 to LCD_HEIGHT-1)
    sendCommand(CMD_RASET);
    sendData16(0);
    sendData16(LCD_HEIGHT - 1);

    // Start memory write
    sendCommand(CMD_RAMWR);

    // Send pixel data
    TFT_DC.put(1); // Data mode
    TFT_CS.put(0); // Select

    // Prepare color bytes (big-endian for ST7735)
    const color_hi: u8 = @truncate(color >> 8);
    const color_lo: u8 = @truncate(color);

    // Fill all pixels (160 * 128 = 20480 pixels, 2 bytes each)
    const lcd_spi = spi.instance.SPI0;
    const pixel_count = LCD_WIDTH * LCD_HEIGHT;

    var i: u32 = 0;
    while (i < pixel_count) : (i += 1) {
        // Write two bytes per pixel
        lcd_spi.write_blocking(u8, &.{ color_hi, color_lo });
    }

    TFT_CS.put(1); // Deselect
}

/// Send a command byte to the LCD
fn sendCommand(cmd: u8) void {
    TFT_DC.put(0); // Command mode
    TFT_CS.put(0); // Select
    spi.instance.SPI0.write_blocking(u8, &.{cmd});
    TFT_CS.put(1); // Deselect
}

/// Send a 16-bit data value to the LCD (big-endian)
fn sendData16(value: u16) void {
    TFT_DC.put(1); // Data mode
    TFT_CS.put(0); // Select
    const hi: u8 = @truncate(value >> 8);
    const lo: u8 = @truncate(value);
    spi.instance.SPI0.write_blocking(u8, &.{ hi, lo });
    TFT_CS.put(1); // Deselect
}
