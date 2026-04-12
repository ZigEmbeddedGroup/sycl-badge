/// LCD Text Viewer Cart
///
/// Edit text_blocks below to display any text you want.
/// Use joystick LEFT/RIGHT to switch between blocks.
const microzig = @import("microzig");
const hal = microzig.hal;
const time = hal.time;
const gpio = hal.gpio;
const spi = hal.spi;
const board = microzig.board;

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
const COLOR_ZIG: u16 = 0xf524; //30, 84, 4

const FONT_WIDTH: u16 = 8;
const FONT_HEIGHT: u16 = 8;

// Edit these blocks to display your own text pages.
const text_blocks = [_][]const u8{
    "Hello World!",
    "WHAT\n DOES",
    "THAT\n MEAN?",
    "ALSO!",
};

const ButtonState = struct {
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
    a: bool = false,

    fn read() ButtonState {
        return .{
            .left = board.joystick_left.read() == 1,
            .right = board.joystick_right.read() == 1,
            .up = board.joystick_up.read() == 1,
            .down = board.joystick_down.read() == 1,
            .a = board.button_a.read() == 1,
        };
    }
};

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    TFT_CS.set_function(.sio);
    TFT_DC.set_function(.sio);
    LED_PIN.set_function(.sio);

    TFT_CS.set_direction(.out);
    TFT_DC.set_direction(.out);
    LED_PIN.set_direction(.out);

    board.joystick_left.set_function(.sio);
    board.joystick_left.set_direction(.in);
    board.joystick_left.set_pull(.down);

    board.joystick_right.set_function(.sio);
    board.joystick_right.set_direction(.in);
    board.joystick_right.set_pull(.down);

    board.joystick_up.set_function(.sio);
    board.joystick_up.set_direction(.in);
    board.joystick_up.set_pull(.down);

    board.joystick_down.set_function(.sio);
    board.joystick_down.set_direction(.in);
    board.joystick_down.set_pull(.down);

    board.button_a.set_function(.sio);
    board.button_a.set_direction(.in);
    board.button_a.set_pull(.up);

    TFT_CS.put(1);
    LED_PIN.put(1);

    var block_idx: usize = 0;
    var last_buttons = ButtonState{};
    var needs_redraw = true;
    var text_scale: u16 = 1;
    var use_zig_color = false;

    while (true) {
        const buttons = ButtonState.read();

        if (buttons.left and !last_buttons.left) {
            if (block_idx == 0) {
                block_idx = text_blocks.len - 1;
            } else {
                block_idx -= 1;
            }
            needs_redraw = true;
        }

        if (buttons.right and !last_buttons.right) {
            block_idx = (block_idx + 1) % text_blocks.len;
            needs_redraw = true;
        }

        if (buttons.up and !last_buttons.up) {
            if (text_scale < 4) {
                text_scale += 1;
                needs_redraw = true;
            }
        }

        if (buttons.down and !last_buttons.down) {
            if (text_scale > 1) {
                text_scale -= 1;
                needs_redraw = true;
            }
        }

        if (buttons.a and !last_buttons.a) {
            use_zig_color = !use_zig_color;
            needs_redraw = true;
        }

        if (needs_redraw) {
            drawTextBlockPage(block_idx, text_scale, use_zig_color);
            needs_redraw = false;
            LED_PIN.toggle();
        }

        last_buttons = buttons;
        time.sleep_ms(20);
    }
}

// ============================================================================
// LCD Functions
// ============================================================================

fn fillScreen(color: u16) void {
    fillRect(0, 0, LCD_WIDTH, LCD_HEIGHT, color);
}

fn fillRect(x: u16, y: u16, width: u16, height: u16, color: u16) void {
    sendCommand(CMD_CASET);
    sendData16(x);
    sendData16(x + width - 1);

    sendCommand(CMD_RASET);
    sendData16(y);
    sendData16(y + height - 1);

    sendCommand(CMD_RAMWR);

    TFT_DC.put(1);
    TFT_CS.put(0);

    const color_hi: u8 = @truncate(color >> 8);
    const color_lo: u8 = @truncate(color);
    const lcd_spi = spi.instance.SPI0;

    var i: u32 = 0;
    const pixel_count = @as(u32, width) * @as(u32, height);
    while (i < pixel_count) : (i += 1) {
        lcd_spi.write_blocking(u8, &.{ color_hi, color_lo });
    }

    TFT_CS.put(1);
}

fn drawCharScaled(char: u8, x: u16, y: u16, scale: u16, fg: u16, bg: u16) void {
    if (char < ' ' or char == 0x7F) return;

    const glyph_index = @as(usize, char - ' ');
    if (glyph_index >= board.font.font.len) return;

    const glyph = board.font.font[glyph_index];

    for (0..@as(usize, FONT_HEIGHT)) |row| {
        const row_bits = glyph[row];
        for (0..@as(usize, FONT_WIDTH)) |col| {
            const bit: u3 = @intCast(7 - col);
            const pixel_on = ((row_bits >> bit) & 1) == 0;
            const color = if (pixel_on) fg else bg;
            const px = x + @as(u16, @intCast(col)) * scale;
            const py = y + @as(u16, @intCast(row)) * scale;
            fillRect(px, py, scale, scale, color);
        }
    }
}

fn drawTextWrapped(text: []const u8, x: u16, y: u16, width: u16, height: u16, scale: u16, fg: u16, bg: u16) void {
    const char_w = FONT_WIDTH * scale;
    const char_h = FONT_HEIGHT * scale;
    if (char_w == 0 or char_h == 0) return;

    const max_cols = width / char_w;
    const max_rows = height / char_h;
    if (max_cols == 0 or max_rows == 0) return;

    var col: u16 = 0;
    var row: u16 = 0;

    for (text) |ch| {
        if (ch == '\r') continue;

        if (ch == '\n') {
            col = 0;
            row += 1;
            if (row >= max_rows) break;
            continue;
        }

        if (col >= max_cols) {
            col = 0;
            row += 1;
            if (row >= max_rows) break;
        }

        drawCharScaled(
            ch,
            x + col * char_w,
            y + row * char_h,
            scale,
            fg,
            bg,
        );
        col += 1;
    }
}

fn drawTextBlockPage(block_idx: usize, scale: u16, use_zig_color: bool) void {
    fillScreen(COLOR_BLACK);

    const text_color = if (use_zig_color) COLOR_ZIG else COLOR_WHITE;

    drawTextWrapped(
        "LEFT/RIGHT PAGE | UP/DOWN SIZE | A TOGGLES COLOR",
        0,
        0,
        LCD_WIDTH,
        FONT_HEIGHT,
        1,
        COLOR_YELLOW,
        COLOR_BLACK,
    );

    drawTextWrapped(
        text_blocks[block_idx],
        0,
        12,
        LCD_WIDTH,
        LCD_HEIGHT - 12,
        scale,
        text_color,
        COLOR_BLACK,
    );
}

fn sendCommand(cmd: u8) void {
    TFT_DC.put(0);
    TFT_CS.put(0);
    spi.instance.SPI0.write_blocking(u8, &.{cmd});
    TFT_CS.put(1);
}

fn sendData16(value: u16) void {
    TFT_DC.put(1);
    TFT_CS.put(0);
    const hi: u8 = @truncate(value >> 8);
    const lo: u8 = @truncate(value);
    spi.instance.SPI0.write_blocking(u8, &.{ hi, lo });
    TFT_CS.put(1);
}
