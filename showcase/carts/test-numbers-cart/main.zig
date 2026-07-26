/// Test MicroZig Cart - LCD Demo Display Letters
///
/// This cart demonstrates using the LCD via MicroZig's SPI HAL.
/// It cycles through letters of the alphabet displayed large on screen.
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

const COLOR_WHITE: u16 = 0xFFFF;
const COLOR_BLACK: u16 = 0x0000;
const COLOR_YELLOW: u16 = 0xFFE0;
const COLOR_BLUE: u16 = 0x001F;


fn convert_font(font: [8]u8) [8]u8 {
    var ret: [8]u8 = @splat(0);
    for (0..8) |i| {
        ret[i] = ~@bitReverse(font[i]);
    }
    return ret;
}
// ============================================================================
// 8x8 Font Data (embedded subset for A-Z)
// Font bits are inverted: 0 = pixel on, 1 = pixel off
// ============================================================================

const font_data: [6][8]u8 = .{
    convert_font(.{ 0x3F, 0x03, 0x1F, 0x30, 0x30, 0x33, 0x1E, 0x00}),   // U+0035 (5)
    convert_font(.{ 0x38, 0x3C, 0x36, 0x33, 0x7F, 0x30, 0x78, 0x00}),   // U+0034 (4)
    convert_font(.{ 0x1E, 0x33, 0x30, 0x1C, 0x30, 0x33, 0x1E, 0x00}),   // U+0033 (3)
    convert_font(.{ 0x1E, 0x33, 0x30, 0x1C, 0x06, 0x33, 0x3F, 0x00}),   // U+0032 (2)
    convert_font(.{ 0x0C, 0x0E, 0x0C, 0x0C, 0x0C, 0x0C, 0x3F, 0x00}),   // U+0031 (1)
    convert_font(.{ 0x3E, 0x63, 0x73, 0x7B, 0x6F, 0x67, 0x3E, 0x00}),   // U+0030 (0)
    // convert_font(.{ 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00}),   // U+002A (*)
};

fn draw_checker() void {
    for (0..160/16) |i| {
        for (0..128/16) |j| {
            const color = if ((i + j) % 2 == 0) COLOR_WHITE else COLOR_BLACK;
            fillRect(@as(u16, @intCast(i))*16, @as(u16, @intCast(j))*16, 16, 16, color);
        }
    }
}

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

    for (font_data, 0..) |_, i| {
        // Clear screen to blue
        fillScreen(COLOR_BLUE);

        // Draw the current letter large and centered
        drawLargeLetter(i, COLOR_YELLOW);

        // Toggle LED to show activity
        LED_PIN.toggle();

        // Wait before changing letter
        time.sleep_ms(1000);
    }

    draw_checker();
    time.sleep_ms(5000);
}

// ============================================================================
// LCD Functions
// ============================================================================

/// Draw a letter scaled up large and centered on screen
/// Scale factor of 12 makes the 8x8 font into 96x96 pixels
fn drawLargeLetter(letter_idx: usize, color: u16) void {
    const scale: u16 = 12;
    const char_width: u16 = 8 * scale; // 96 pixels
    const char_height: u16 = 8 * scale; // 96 pixels

    // Center the letter on screen
    const start_x: u16 = (LCD_WIDTH - char_width) / 2;
    const start_y: u16 = (LCD_HEIGHT - char_height) / 2;

    const glyph = font_data[letter_idx];

    // Draw each row of the glyph
    for (0..8) |row| {
        const row_bits = glyph[row];

        // Draw each column of the glyph
        for (0..8) |col| {
            // Check if pixel is on (bit is 0 in inverted font)
            const bit: u3 = @intCast(7 - col);
            const pixel_on = ((row_bits >> bit) & 1) == 0;

            if (pixel_on) {
                // Draw a scaled pixel block
                const px: u16 = start_x + @as(u16, @intCast(col)) * scale;
                const py: u16 = start_y + @as(u16, @intCast(row)) * scale;
                fillRect(px, py, scale, scale, color);
            }
        }
    }
}

/// Fill a rectangle with a solid color
fn fillRect(x: u16, y: u16, w: u16, h: u16, color: u16) void {
    // Set column address range
    sendCommand(CMD_CASET);
    sendData16(x);
    sendData16(x + w - 1);

    // Set row address range
    sendCommand(CMD_RASET);
    sendData16(y);
    sendData16(y + h - 1);

    // Start memory write
    sendCommand(CMD_RAMWR);

    // Send pixel data
    TFT_DC.put(1); // Data mode
    TFT_CS.put(0); // Select

    const color_hi: u8 = @truncate(color >> 8);
    const color_lo: u8 = @truncate(color);

    const lcd_spi = spi.instance.SPI0;
    const pixel_count = @as(u32, w) * @as(u32, h);

    var i: u32 = 0;
    while (i < pixel_count) : (i += 1) {
        lcd_spi.write_blocking(u8, &.{ color_hi, color_lo });
    }

    TFT_CS.put(1); // Deselect
}

/// Fill the entire screen with a solid color
fn fillScreen(color: u16) void {
    fillRect(0, 0, LCD_WIDTH, LCD_HEIGHT, color);
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
