/// LCD Driver for RP2354B SYCL Badge OS
/// 160x128 LCD (90° counter-clockwise rotation for the badge)
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const spi = hal.spi;
const timer = @import("timer.zig");
const dma = @import("dma.zig");
const board = microzig.board;
const font = board.font;

/// Display Configuration
pub const width: u16 = 160;
pub const height: u16 = 128;
pub const xstart: u16 = 0;
pub const ystart: u16 = 0;

// Pin assignments (control pins only)
pub const Pins = struct {
    cs: gpio.Pin, // Chip Select
    dc: gpio.Pin, // Data/Command
    rst: gpio.Pin, // Reset
    bl: ?gpio.Pin, // Backlight (this pin is tied to ground)
};

/// SPI pin configuration for LCD
pub const SPIPins = struct {
    scl: gpio.Pin, // LCD_SCL (Serial Clock)
    sdo: gpio.Pin, // LCD_SDIO (Serial Data I/O (MOSI))
};

/// Combined LCD pin configuration
pub const LCDPins = struct {
    /// Control pins for LCD driver
    control: Pins,
    /// SPI pins (LCD_SCL and LCD_SDIO)
    spi: SPIPins,
    /// TE (Tearing Effect) pin (optional and we aren't using for now)
    te: ?gpio.Pin = null,
};

// Color formats
// RGB565: High byte = RRRRR GGG, Low byte = GGG BBBBB
pub const Color16 = packed struct(u16) {
    b: u5,
    g: u6,
    r: u5,

    pub fn rgb(r: u8, g: u8, b: u8) Color16 {
        return .{
            .r = @truncate(r >> 3),
            .g = @truncate(g >> 2),
            .b = @truncate(b >> 3),
        };
    }

    pub fn toBytes(self: Color16) [2]u8 {
        // ST7735 expects BGR565 format: [BBBBB GGG] [GGG RRRRR]
        const hi: u8 = (@as(u8, self.b) << 3) | @as(u8, self.g >> 3);
        const lo: u8 = (@as(u8, self.g & 0x07) << 5) | @as(u8, self.r);
        return .{ hi, lo };
    }
};

// Common colors (RGB565 format)
pub const BLACK: Color16 = .{ .r = 0x00, .g = 0x00, .b = 0x00 };
pub const WHITE: Color16 = .{ .r = 0x1F, .g = 0x3F, .b = 0x1F };
pub const RED: Color16 = .{ .r = 0x1F, .g = 0x00, .b = 0x00 };
pub const GREEN: Color16 = .{ .r = 0x00, .g = 0x3F, .b = 0x00 };
pub const BLUE: Color16 = .{ .r = 0x00, .g = 0x00, .b = 0x1F };
pub const YELLOW: Color16 = .{ .r = 0x1F, .g = 0x3F, .b = 0x00 };
pub const CYAN: Color16 = .{ .r = 0x00, .g = 0x3F, .b = 0x1F };
pub const MAGENTA: Color16 = .{ .r = 0x1F, .g = 0x00, .b = 0x1F };

/// Driver State
var pins: Pins = undefined;
var spi_instance: spi.SPI = undefined;
var spi_instance_num: u1 = 0;
var spi_baudrate: u32 = 62_500_000; // Fixed baudrate for LCD (max for RP2350 SPI is 62.5 MHz)

/// Framebuffer for DMA transfers (160x128 pixels, RGB565 = 2 bytes per pixel)
var framebuffer: [width * height * 2]u8 align(4) = undefined;
var dma_enabled: bool = false;
var dma_active: bool = false;

/// ST7735/ST7789 Commands
const Command = enum(u8) {
    SWRESET = 0x01,
    SLPOUT = 0x11,
    NORON = 0x13,
    INVOFF = 0x20,
    INVON = 0x21,
    DISPOFF = 0x28,
    DISPON = 0x29,
    CASET = 0x2A, // Column Address Set
    RASET = 0x2B, // Row Address Set
    RAMWR = 0x2C, // Memory Write
    MADCTL = 0x36, // Memory Access Control
    COLMOD = 0x3A, // Color Mode
    FRMCTR1 = 0xB1,
    FRMCTR2 = 0xB2,
    FRMCTR3 = 0xB3,
    INVCTR = 0xB4,
    PWCTR1 = 0xC0,
    PWCTR2 = 0xC1,
    PWCTR3 = 0xC2,
    PWCTR4 = 0xC3,
    PWCTR5 = 0xC4,
    VMCTR1 = 0xC5,
    GMCTRP1 = 0xE0,
    GMCTRN1 = 0xE1,
};

/// Low-level SPI communication
fn writeCommand(cmd: Command) void {
    pins.cs.put(1); // Deselect first
    pins.dc.put(0); // Command mode
    pins.cs.put(0); // Select
    const data = [_]u8{@intFromEnum(cmd)};
    var dummy: [1]u8 = undefined;
    spi_instance.transceive_blocking(u8, &data, &dummy);
    pins.cs.put(1); // Deselect
}

fn writeData(data: []const u8) void {
    pins.cs.put(1); // Deselect first
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select
    // Allocate dummy buffer for receive (we don't need the data)
    var dummy = std.mem.zeroes([256]u8);
    const chunk_size = @min(data.len, dummy.len);
    var offset: usize = 0;
    while (offset < data.len) {
        const len = @min(chunk_size, data.len - offset);
        spi_instance.transceive_blocking(u8, data[offset..][0..len], dummy[0..len]);
        offset += len;
    }
    pins.cs.put(1); // Deselect
}

// Helper: start a data transfer without toggling CS/DC for each chunk
fn startData() void {
    pins.dc.put(1);
    pins.cs.put(0);
}

// Helper: end a data transfer (deselect)
fn endData() void {
    pins.cs.put(1);
}

// Helper: write data while assuming CS already low and DC set to data mode
fn writeDataNoCS(data: []const u8) void {
    var dummy = std.mem.zeroes([256]u8);
    const chunk_size = @min(data.len, dummy.len);
    var offset: usize = 0;
    while (offset < data.len) {
        const len = @min(chunk_size, data.len - offset);
        spi_instance.transceive_blocking(u8, data[offset..][0..len], dummy[0..len]);
        offset += len;
    }
}

fn writeCommandWithData(cmd: Command, data: []const u8) void {
    writeCommand(cmd);
    if (data.len > 0) {
        writeData(data);
    }
}

fn writeU8(value: u8) void {
    writeData(&.{value});
}

fn writeU16(value: u16) void {
    writeData(&.{
        @truncate(value >> 8),
        @truncate(value & 0xFF),
    });
}

/// Initialization
pub const Config = struct {
    spi_instance_num: u1 = 0, // Which SPI peripheral to use (0 or 1 for RP2354B)
    spi_baudrate: u32 = 62_500_000, // 62.5 MHz
    use_dma: bool = true, // Enable DMA flag
};

/// Low-level initialization (control pins only)
/// Use initWithAllPins() for full initialization including SPI and TE pins
pub fn init(pin_config: Pins, config: Config) !void {
    pins = pin_config;

    // Configure GPIO pins
    pins.cs.set_function(.sio);
    pins.cs.set_direction(.out);
    pins.cs.put(1); // Deselect

    pins.dc.set_function(.sio);
    pins.dc.set_direction(.out);
    pins.dc.put(1);

    pins.rst.set_function(.sio);
    pins.rst.set_direction(.out);
    pins.rst.put(0);

    if (pins.bl) |bl| {
        bl.set_function(.sio);
        bl.set_direction(.out);
        bl.put(1); // Turn on backlight
    }

    // Store SPI instance num and baudrate for DMA config
    spi_instance_num = config.spi_instance_num;
    spi_baudrate = config.spi_baudrate;

    // Initialize SPI peripheral
    spi_instance = spi.instance.num(config.spi_instance_num);

    // Reset and configure SPI peripheral
    // Must pass baud_rate, otherwise HAL defaults to 1 MHz
    const spi_config = spi.Config{
        .clock_config = hal.clock_config,
        .baud_rate = 62_500_000, // 62.5 MHz
    };
    try spi_instance.apply(spi_config);

    // Enable DMA if requested
    dma_enabled = config.use_dma;
    if (dma_enabled) {
        dma.init();
        // Clear framebuffer to black
        @memset(&framebuffer, 0);
    }

    // Hardware reset sequence
    pins.rst.put(1);
    timer.sleep_ms(5);
    pins.rst.put(0);
    timer.sleep_ms(20);
    pins.rst.put(1);
    timer.sleep_ms(50);

    // Initialize display
    initDisplay();
}

fn initDisplay() void {
    // Software reset
    writeCommand(.SWRESET);
    timer.sleep_ms(50);

    // Sleep out
    writeCommand(.SLPOUT);
    timer.sleep_ms(50);

    // Frame rate control (normal mode (ST7735S values))
    writeCommandWithData(.FRMCTR1, &.{ 0x05, 0x3C, 0x3C });
    timer.sleep_ms(1);

    // Frame rate control (idle mode)
    writeCommandWithData(.FRMCTR2, &.{ 0x05, 0x3C, 0x3C });
    timer.sleep_ms(1);

    // Frame rate control (partial mode)
    writeCommandWithData(.FRMCTR3, &.{ 0x05, 0x3C, 0x3C, 0x05, 0x3C, 0x3C });
    timer.sleep_ms(1);

    // Display inversion control
    writeCommandWithData(.INVCTR, &.{0x03});

    // Power control settings (ST7735S values)
    writeCommandWithData(.PWCTR1, &.{ 0x28, 0x08, 0x04 }); // GVDD = 4.7V, 1.0uA
    writeCommandWithData(.PWCTR2, &.{0xC0}); // VGH=14.7V, VGL=-7.35V
    writeCommandWithData(.PWCTR3, &.{ 0x0D, 0x00 }); // Opamp current small
    writeCommandWithData(.PWCTR4, &.{ 0x8D, 0x2A }); // BCLK/2
    writeCommandWithData(.PWCTR5, &.{ 0x8D, 0xEE }); // BCLK/2

    // VCOM control
    writeCommandWithData(.VMCTR1, &.{0x1A}); // VCOM = -0.775V

    // Memory access control with 90° clockwise rotation
    // MV (0x20) = Row/Column exchange, MY (0x80) = Row address order
    writeCommandWithData(.MADCTL, &.{0xA0}); // 90° CW rotation, RGB

    // Color mode (16-bit RGB565)
    writeCommandWithData(.COLMOD, &.{0x05});

    // Gamma correction (positive)
    writeCommandWithData(.GMCTRP1, &.{
        0x04, 0x22, 0x07, 0x0A,
        0x2E, 0x30, 0x25, 0x2A,
        0x28, 0x26, 0x2E, 0x3A,
        0x00, 0x01, 0x03, 0x13,
    });

    // Gamma correction (negative)
    writeCommandWithData(.GMCTRN1, &.{
        0x04, 0x16, 0x06, 0x0D,
        0x2D, 0x26, 0x23, 0x27,
        0x27, 0x25, 0x2D, 0x3B,
        0x00, 0x01, 0x04, 0x13,
    });

    // Normal display mode
    writeCommand(.NORON);
    timer.sleep_ms(1);

    // Display on
    writeCommand(.DISPON);
    timer.sleep_ms(20);

    // DMA inits on first present() call
    dma_active = false;
}

/// Re-initialize display registers (call after cart stops to restore LCD settings)
/// This performs a quick reinit without full hardware reset for faster recovery
pub fn reinitDisplay() void {
    // Reconfigure critical GPIO pins (cart may have changed them)
    pins.cs.set_function(.sio);
    pins.cs.set_direction(.out);
    pins.cs.put(1); // Deselect

    pins.dc.set_function(.sio);
    pins.dc.set_direction(.out);

    // Reset SPI peripheral (cart may have changed SPI settings)
    const spi_config = spi.Config{
        .clock_config = hal.clock_config,
        .baud_rate = 62_500_000,
    };
    spi_instance.apply(spi_config) catch {};

    // Quick software reset (no hardware reset pin toggle)
    writeCommand(.SWRESET);
    timer.sleep_ms(10); // Reduced from 50ms

    // Wake up display
    writeCommand(.SLPOUT);
    timer.sleep_ms(10); // Reduced from 50ms

    // Restore critical registers only
    writeCommandWithData(.MADCTL, &.{0xA0}); // 90° CW rotation, RGB
    writeCommandWithData(.COLMOD, &.{0x05}); // 16-bit RGB565
    writeCommand(.NORON); // Normal display mode
    writeCommand(.DISPON); // Display on
    timer.sleep_ms(5); // Short delay for display to stabilize
}

/// Display Control
pub fn setBacklight(on: bool) void {
    if (pins.bl) |bl| {
        bl.put(if (on) 1 else 0);
    }
}

/// Prepare LCD for cart execution
/// Ensures clean state with proper color mode
pub fn prepareForCart() void {
    // Ensure LCD is in normal, non-inverted mode with correct orientation
    writeCommand(.NORON); // Normal display mode (not partial)
    writeCommand(.INVOFF); // Turn off color inversion
    writeCommandWithData(.MADCTL, &.{0xA0}); // 90° CW rotation, RGB
    writeCommandWithData(.COLMOD, &.{0x05}); // 16-bit RGB565
}

pub fn displayOn(on: bool) void {
    writeCommand(if (on) .DISPON else .DISPOFF);
}

pub fn invertDisplay(invert: bool) void {
    writeCommand(if (invert) .INVON else .INVOFF);
}

/// Drawing Functions
fn setWindow(x0: u16, y0: u16, x1: u16, y1: u16) void {
    const x0_offset = x0 + xstart;
    const x1_offset = x1 + xstart;
    const y0_offset = y0 + ystart;
    const y1_offset = y1 + ystart;

    // Column address set - send all 4 bytes at once
    writeCommand(.CASET);
    const col_data = [_]u8{
        0x00,
        @truncate(x0_offset),
        0x00,
        @truncate(x1_offset),
    };
    writeData(&col_data);

    // Row address set - send all 4 bytes at once
    writeCommand(.RASET);
    const row_data = [_]u8{
        0x00,
        @truncate(y0_offset),
        0x00,
        @truncate(y1_offset),
    };
    writeData(&row_data);

    writeCommand(.RAMWR);
}

/// Set win for DMA streaming, keep CS low and DC high after RAMWR
fn setWindowForDMA(x0: u16, y0: u16, x1: u16, y1: u16) void {
    // setWindow to send CASET, RASET, RAMWR (ends with CS high)
    // Blocking SPI calls handle synch internally
    setWindow(x0, y0, x1, y1);

    // Set DC to data mode and CS low
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select and keep selected for DMA streaming
}

pub fn drawPixel(x: u16, y: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    setWindow(x, y, x, y);
    const bytes = color.toBytes();
    writeData(&bytes);
}

pub fn fillScreen(color: Color16) void {
    fillRect(0, 0, width, height, color);
}

pub fn fillRect(x: u16, y: u16, w: u16, h: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    const x_clamped = @min(x, width - 1);
    const y_clamped = @min(y, height - 1);
    const w_actual = @min(w, width - x_clamped);
    const h_actual = @min(h, height - y_clamped);

    if (w_actual == 0 or h_actual == 0) return;

    const x1 = x_clamped + w_actual - 1;
    const y1 = y_clamped + h_actual - 1;

    setWindow(x_clamped, y_clamped, x1, y1);

    const color_bytes = color.toBytes();

    // Create a line buffer
    var line: [320]u8 = undefined; // 160 pixels * 2 bytes = 320 bytes max
    const line_bytes = w_actual * 2;

    var i: usize = 0;
    while (i < w_actual) : (i += 1) {
        line[i * 2] = color_bytes[0];
        line[i * 2 + 1] = color_bytes[1];
    }

    // Keep CS selected for entire fill operation to reduce overhead
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select

    var dummy = std.mem.zeroes([320]u8);

    // Write each line
    var row: u16 = 0;
    while (row < h_actual) : (row += 1) {
        spi_instance.transceive_blocking(u8, line[0..line_bytes], dummy[0..line_bytes]);
    }

    pins.cs.put(1); // Deselect
}

pub fn drawHLine(x: u16, y: u16, w: u16, color: Color16) void {
    fillRect(x, y, w, 1, color);
}

pub fn drawVLine(x: u16, y: u16, h: u16, color: Color16) void {
    fillRect(x, y, 1, h, color);
}

pub fn drawRect(x: u16, y: u16, w: u16, h: u16, color: Color16) void {
    drawHLine(x, y, w, color);
    drawHLine(x, y + h - 1, w, color);
    drawVLine(x, y, h, color);
    drawVLine(x + w - 1, y, h, color);
}

pub fn drawChar(x: u16, y: u16, char: u8, color: Color16, bg_color: Color16, size: u8) void {
    if (x >= width or y >= height) return;
    if (size == 0) return;

    // Get font data for this character (font starts at space ' ')
    const char_index = if (char >= ' ') char - ' ' else 0;
    if (char_index >= font.font.len) return;

    const glyph = font.font[char_index];

    // Draw the character bitmap
    if (size == 1) {
        // Single-size characters: write each row as a contiguous 8-pixel transfer
        var row_idx: u8 = 0;
        while (row_idx < 8) : (row_idx += 1) {
            const line = glyph[row_idx];
            var buf: [16]u8 = undefined; // 8 pixels * 2 bytes
            var cidx: usize = 0;
            var col: u8 = 0;
            while (col < 8) : (col += 1) {
                // Check if pixel is set (0 = foreground, 1 = background in this font)
                const bit_set = (line & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                const pixel_color = if (bit_set) color else bg_color;
                const bytes = pixel_color.toBytes();
                buf[cidx] = bytes[0];
                buf[cidx + 1] = bytes[1];
                cidx += 2;
            }
            // Set window for this row and stream it as one transfer
            setWindow(x, y + @as(u16, row_idx), x + 7, y + @as(u16, row_idx));
            startData();
            writeDataNoCS(buf[0..16]);
            endData();
        }
    } else {
        // Draw the scaled character bitmap
        var row: u8 = 0;
        while (row < 8) : (row += 1) {
            const line = glyph[row];
            var col: u8 = 0;
            while (col < 8) : (col += 1) {
                // Check if pixel is set (0 = foreground, 1 = background in this font)
                const bit_set = (line & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                const pixel_color = if (bit_set) color else bg_color;
                // Draw scaled pixel block
                fillRect(x + @as(u16, col) * size, y + @as(u16, row) * size, size, size, pixel_color);
            }
        }
    }
}

pub fn drawString(x: u16, y: u16, text: []const u8, color: Color16, bg_color: Color16, size: u8) void {
    var cursor_x = x;
    for (text) |char| {
        drawChar(cursor_x, y, char, color, bg_color, size);
        cursor_x += 8 * size; // 8 pixels per character
    }
}

/// Direct buffer writing (for framebuffer updates)
pub fn writeBuffer(x: u16, y: u16, w: u16, h: u16, buffer: []const u8) void {
    if (x >= width or y >= height) return;

    const x1 = @min(x + w - 1, width - 1);
    const y1 = @min(y + h - 1, height - 1);

    setWindow(x, y, x1, y1);
    writeData(buffer);
}

/// Write a column-major framebuffer (the cart API layout) to the full display.
///
/// Temporarily switches to MADCTL=0x40 (MV=0, MX=1) so the
/// native column axis (128 = screen-Y) is the fast scan direction, matching
/// the framebuffer memory order.
pub fn writeCartBuffer(buffer: []const u8) void {
    // MV=0: fast axis = native columns (128 = screen Y).
    // MX=1: columns scan 127→0 so Y=0 maps to native col 127 (screen top).
    // MY=0: rows scan 0→159 so X=0 maps to native row 0 (screen left).
    writeCommandWithData(.MADCTL, &.{0x40});

    // With MV=0: CASET = native columns (0-127), RASET = native rows (0-159).
    // Send CASET/RASET directly to avoid confusion with setWindow's x/y naming.
    writeCommand(.CASET);
    writeData(&[_]u8{ 0x00, 0x00 + xstart, 0x00, 127 + xstart });
    writeCommand(.RASET);
    writeData(&[_]u8{ 0x00, 0x00 + ystart, 0x00, 159 + ystart });
    writeCommand(.RAMWR);

    writeData(buffer);

    // Restore landscape MADCTL for direct-draw UI operations.
    writeCommandWithData(.MADCTL, &.{0xA0});
}

/// Write RGB565 framebuffer to display
/// Copies to internal buffer and triggers DMA transfer
pub fn writeFramebuffer(source_fb: []const Color16) void {
    if (source_fb.len != width * height) {
        return; // Invalid framebuffer size
    }

    if (dma_enabled) {
        // Convert Color16 to bytes and copy to DMA framebuffer
        for (source_fb, 0..) |pixel, i| {
            const bytes = pixel.toBytes();
            framebuffer[i * 2] = bytes[0];
            framebuffer[i * 2 + 1] = bytes[1];
        }
        // Trigger DMA transfer
        present();
    } else {
        // Fallback: write pixel by pixel (it's slow)
        setWindow(0, 0, width - 1, height - 1);
        for (source_fb) |pixel| {
            const data = pixel.toBytes();
            writeData(&data);
        }
    }
}

/// Test Functions
pub fn testPattern() void {
    // Draw color bars
    const bar_height = height / 8;
    const colors = [_]Color16{ RED, GREEN, BLUE, YELLOW, CYAN, MAGENTA, WHITE, BLACK };

    for (colors, 0..) |color, i| {
        fillRect(0, @intCast(i * bar_height), width, bar_height, color);
    }
}

pub fn testText() void {
    fillScreen(BLACK);
    drawString(10, 10, "SYCL Badge OS", WHITE, BLACK, 2);
    drawString(10, 30, "LCD Driver Test", GREEN, BLACK, 1);
}

pub fn createDT018BTFTPins() LCDPins {
    return .{
        .control = .{
            // LCD_CS: Chip Select
            .cs = board.TFT_CS,

            // LCD_D/CX: Data/Command
            .dc = board.TFT_DC,

            // RST: Reset
            .rst = board.TFT_RST,

            // BKLT_PWM: Backlight (connected to VBUS/5V, no GPIO control)
            .bl = null,
        },
        .spi = .{
            // LCD_SCL: Serial Clock
            .scl = board.TFT_SCK,

            // LCD_SDIO: Serial Data I/O MOSI
            .sdo = board.TFT_MOSI,
        },
        // TE: Tearing Effect (optional, leave it disconnected for now)
        .te = null,
    };
}

/// Create default LCD configuration for DT018BTFT-SHB
pub fn createDT018BTFTConfig() Config {
    return .{
        .spi_instance_num = 0, // SPI instance number
        .spi_baudrate = 62_500_000, // 62.5 MHz (maximum)
        .use_dma = true,
    };
}

/// Configure SPI pins for LCD communication
/// This sets the GPIO pins to their SPI function
fn configureLCDSPIPins(spi_pins: SPIPins) void {
    // Configure SCK (Serial Clock) pin for SPI function
    spi_pins.scl.set_function(.spi);
    spi_pins.scl.set_direction(.out);

    // Configure MOSI (Master Out Slave In) pin for SPI function
    spi_pins.sdo.set_function(.spi);
    spi_pins.sdo.set_direction(.out);
}

/// Configure TE (Tearing Effect) pin if provided
/// TE pin is used for frame synchronization and is optional
fn configureLCDTEPin(te: ?gpio.Pin) void {
    if (te) |te_pin| {
        // Configure TE pin as input (it's driven by the display)
        te_pin.set_function(.sio);
        te_pin.set_direction(.in);
    }
}

/// High-level initialization function that handles all pin configuration
pub fn initWithAllPins(all_pins: LCDPins, config: Config) !void {
    // Configure SPI pins
    configureLCDSPIPins(all_pins.spi);

    // Configure TE pin if provided
    configureLCDTEPin(all_pins.te);

    // Initialize LCD with control pins
    try init(all_pins.control, config);
}

pub fn drawImg(x: u16, y: u16, w: u16, h: u16, img_data: []const u8) void {
    _ = x;
    _ = y;
    _ = w;
    _ = h;
    writeBuffer(0, 0, width, height, img_data);
}

// DMA Functions

/// Get pointer to internal framebuffer for dir access
/// Fastest way to draw - write dir to framebuffer then call present()
pub fn getFramebuffer() *[width * height * 2]u8 {
    return &framebuffer;
}

/// Trigger DMA transfer of framebuffer to LCD
/// Call after drawing to framebuffer to update screen
pub fn present() void {
    if (!dma_enabled) return;

    if (!dma_active) {
        // Set up LCD for DMA streaming and init DMA
        setWindowForDMA(0, 0, width - 1, height - 1);
        dma.initLCD(spi_instance_num, &framebuffer);
        dma_active = true;
    } else {
        // Wait for prev transfer to complete
        vsync();
    }

    // Start/restart DMA transfer (CS stays low, DC stays high)
    dma.startLCD();
}

pub fn vsync() void {
    if (!dma_enabled or !dma_active) return;

    // Wait for DMA to finish transferring data
    dma.waitLCD();
}

/// Stop DMA transfers
pub fn stopDMA() void {
    if (!dma_active) return;

    // Stop DMA and wait
    dma.stopLCD();

    dma_active = false;

    // Deselect LCD
    pins.cs.put(1);
}

/// Check if DMA transfer in progress
pub fn isBusy() bool {
    if (!dma_enabled or !dma_active) return false;
    return dma.isLCDbusy();
}

/// Fast fill screen with single color
pub fn clearScreen(color: Color16) void {
    if (dma_enabled) {
        const bytes = color.toBytes();
        // Fill framebuffer with color
        var i: usize = 0;
        while (i < framebuffer.len) : (i += 2) {
            framebuffer[i] = bytes[0];
            framebuffer[i + 1] = bytes[1];
        }
        present();
        vsync();
    } else {
        fillScreen(color);
    }
}

/// Fast pixel write to framebuffer (no bounds checking for speed)
/// Only use when x, y are within bounds
pub inline fn setPixelUnsafe(x: u16, y: u16, color: Color16) void {
    const offset = (y * width + x) * 2;
    const bytes = color.toBytes();
    framebuffer[offset] = bytes[0];
    framebuffer[offset + 1] = bytes[1];
}

/// Safe pixel write to framebuffer with bounds checking
pub fn setPixel(x: u16, y: u16, color: Color16) void {
    if (x >= width or y >= height) return;
    setPixelUnsafe(x, y, color);
}

/// Horizontal line
pub fn setHLine(x: u16, y: u16, w: u16, color: Color16) void {
    if (y >= height or x >= width) return;
    const actual_w = @min(w, width - x);
    const bytes = color.toBytes();
    const start_offset = (y * width + x) * 2;

    var i: usize = 0;
    while (i < actual_w) : (i += 1) {
        const offset = start_offset + i * 2;
        framebuffer[offset] = bytes[0];
        framebuffer[offset + 1] = bytes[1];
    }
}

/// Vertical line
pub fn setVLine(x: u16, y: u16, h: u16, color: Color16) void {
    if (x >= width or y >= height) return;
    const actual_h = @min(h, height - y);
    const bytes = color.toBytes();

    var row: usize = 0;
    while (row < actual_h) : (row += 1) {
        const offset = ((y + row) * width + x) * 2;
        framebuffer[offset] = bytes[0];
        framebuffer[offset + 1] = bytes[1];
    }
}

pub fn setRect(x: u16, y: u16, w: u16, h: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    const actual_w = @min(w, width - x);
    const actual_h = @min(h, height - y);
    const bytes = color.toBytes();

    var row: usize = 0;
    while (row < actual_h) : (row += 1) {
        const row_offset = ((y + row) * width + x) * 2;
        var col: usize = 0;
        while (col < actual_w) : (col += 1) {
            const offset = row_offset + col * 2;
            framebuffer[offset] = bytes[0];
            framebuffer[offset + 1] = bytes[1];
        }
    }
}
