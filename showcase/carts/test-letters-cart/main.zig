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

// ============================================================================
// 8x8 Font Data (embedded subset for A-Z)
// Font bits are inverted: 0 = pixel on, 1 = pixel off
// ============================================================================

const font_data: [26][8]u8 = .{
    // A
    .{ 0b11000111, 0b10010011, 0b00111001, 0b00111001, 0b00000001, 0b00111001, 0b00111001, 0b11111111 },
    // B
    .{ 0b00000011, 0b00111001, 0b00111001, 0b00000011, 0b00111001, 0b00111001, 0b00000011, 0b11111111 },
    // C
    .{ 0b10000011, 0b00111001, 0b00111111, 0b00111111, 0b00111111, 0b00111001, 0b10000011, 0b11111111 },
    // D
    .{ 0b00000111, 0b00110011, 0b00111001, 0b00111001, 0b00111001, 0b00110011, 0b00000111, 0b11111111 },
    // E
    .{ 0b00000001, 0b00111111, 0b00111111, 0b00000111, 0b00111111, 0b00111111, 0b00000001, 0b11111111 },
    // F
    .{ 0b00000001, 0b00111111, 0b00111111, 0b00000111, 0b00111111, 0b00111111, 0b00111111, 0b11111111 },
    // G
    .{ 0b10000011, 0b00111001, 0b00111111, 0b00100001, 0b00111001, 0b00111001, 0b10000011, 0b11111111 },
    // H
    .{ 0b00111001, 0b00111001, 0b00111001, 0b00000001, 0b00111001, 0b00111001, 0b00111001, 0b11111111 },
    // I
    .{ 0b10000011, 0b11100111, 0b11100111, 0b11100111, 0b11100111, 0b11100111, 0b10000011, 0b11111111 },
    // J
    .{ 0b11000001, 0b11110011, 0b11110011, 0b11110011, 0b00110011, 0b00110011, 0b10000111, 0b11111111 },
    // K
    .{ 0b00111001, 0b00110011, 0b00100111, 0b00001111, 0b00100111, 0b00110011, 0b00111001, 0b11111111 },
    // L
    .{ 0b00111111, 0b00111111, 0b00111111, 0b00111111, 0b00111111, 0b00111111, 0b00000001, 0b11111111 },
    // M
    .{ 0b00111001, 0b00010001, 0b00101001, 0b00000001, 0b00111001, 0b00111001, 0b00111001, 0b11111111 },
    // N
    .{ 0b00111001, 0b00011001, 0b00001001, 0b00000001, 0b00100001, 0b00110001, 0b00111001, 0b11111111 },
    // O
    .{ 0b10000011, 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b10000011, 0b11111111 },
    // P
    .{ 0b00000011, 0b00111001, 0b00111001, 0b00000011, 0b00111111, 0b00111111, 0b00111111, 0b11111111 },
    // Q
    .{ 0b10000011, 0b00111001, 0b00111001, 0b00111001, 0b00101001, 0b00110001, 0b10000001, 0b11111111 },
    // R
    .{ 0b00000011, 0b00111001, 0b00111001, 0b00000011, 0b00100111, 0b00110011, 0b00111001, 0b11111111 },
    // S
    .{ 0b10000011, 0b00111001, 0b00111111, 0b10000011, 0b11111001, 0b00111001, 0b10000011, 0b11111111 },
    // T
    .{ 0b00000001, 0b11100111, 0b11100111, 0b11100111, 0b11100111, 0b11100111, 0b11100111, 0b11111111 },
    // U
    .{ 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b10000011, 0b11111111 },
    // V
    .{ 0b00111001, 0b00111001, 0b00111001, 0b00111001, 0b00010001, 0b10000011, 0b11000111, 0b11111111 },
    // W
    .{ 0b00111001, 0b00111001, 0b00111001, 0b00101001, 0b00000001, 0b00010001, 0b00111001, 0b11111111 },
    // X
    .{ 0b00111001, 0b00010001, 0b10000011, 0b11000111, 0b10000011, 0b00010001, 0b00111001, 0b11111111 },
    // Y
    .{ 0b00111001, 0b00111001, 0b00010001, 0b10000011, 0b11000111, 0b11000111, 0b11000111, 0b11111111 },
    // Z
    .{ 0b00000001, 0b11110001, 0b11100011, 0b11000111, 0b10001111, 0b00011111, 0b00000001, 0b11111111 },
};

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

    // Letter index (0 = A, 25 = Z)
    var letter_idx: usize = 0;

    while (true) {
        // Clear screen to blue
        fillScreen(COLOR_BLUE);

        // Draw the current letter large and centered
        drawLargeLetter(letter_idx, COLOR_YELLOW);

        // Toggle LED to show activity
        LED_PIN.toggle();

        // Next letter
        letter_idx = (letter_idx + 1) % 26;

        // Wait before changing letter
        time.sleep_ms(500);
    }
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
