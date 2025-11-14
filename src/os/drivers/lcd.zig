/// LCD Driver for RP2350 SYCL Badge OS
/// Supports ST7735/ST7789 based displays (like DT018BTFT)
/// 1.8" TFT Display - 128x160 RGB
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const spi = hal.spi;
const timer = @import("timer.zig");

/// Display Configuration
pub const width = 128;
pub const height = 160;

// Pin assignments
pub const Pins = struct {
    cs: gpio.Pin, // Chip Select
    dc: gpio.Pin, // Data/Command
    rst: gpio.Pin, // Reset
    bl: ?gpio.Pin, // Backlight ???
    //TODO: go over pin assignments
};

// Color formats
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
};

pub const Color24 = extern struct {
    r: u8,
    g: u8,
    b: u8,
};

// Common colors (RGB565 format)
// TODO: add more colours if needed... like purple!!
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
var initialized: bool = false;

/// ST7735/ST7789 Commands
const Command = enum(u8) {
    NOP = 0x00,
    SWRESET = 0x01,
    RDDID = 0x04,
    RDDST = 0x09,
    SLPIN = 0x10,
    SLPOUT = 0x11,
    PTLON = 0x12,
    NORON = 0x13,
    INVOFF = 0x20,
    INVON = 0x21,
    DISPOFF = 0x28,
    DISPON = 0x29,
    CASET = 0x2A, // Column Address Set
    RASET = 0x2B, // Row Address Set
    RAMWR = 0x2C, // Memory Write
    RAMRD = 0x2E, // Memory Read
    PTLAR = 0x30,
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

// MADCTL bits
const MADCTL = struct {
    const MY: u8 = 0x80; // Row address order
    const MX: u8 = 0x40; // Column address order
    const MV: u8 = 0x20; // Row/Column exchange
    const ML: u8 = 0x10; // Vertical refresh order
    const RGB: u8 = 0x00; // RGB color order
    const BGR: u8 = 0x08; // BGR color order
    const MH: u8 = 0x04; // Horizontal refresh order
};

// Color modes
const ColorMode = enum(u8) {
    RGB444 = 0x03, // 12-bit
    RGB565 = 0x05, // 16-bit
    RGB666 = 0x06, // 18-bit
};

/// Low-level SPI communication
fn writeCommand(cmd: Command) void {
    pins.dc.put(0); // Command mode
    pins.cs.put(0); // Select
    spi_instance.transceive_blocking(&.{@intFromEnum(cmd)});
    pins.cs.put(1); // Deselect
}

fn writeData(data: []const u8) void {
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select
    spi_instance.transceive_blocking(data);
    pins.cs.put(1); // Deselect
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
    spi_instance_num: u8 = 0, // Which SPI peripheral to use
    spi_baudrate: u32 = 8_000_000, // 8 MHz
    rotation: u8 = 0, // 0, 1, 2, or 3 (0/90/180/270 degrees)
};

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
    pins.rst.put(1);

    if (pins.bl) |bl| {
        bl.set_function(.sio);
        bl.set_direction(.out);
        bl.put(1); // Turn on backlight
    }

    // Initialize SPI
    // TODO: configure SPI pins (SCK, MOSI) separately
    // based on hardware setup - datasheet says SCK=18, MOSI=19 ??
    spi_instance = spi.instance.num(config.spi_instance_num);

    // TODO: configure SPI with proper clock config and baudrate
    // Depends on MicroZig HAL's SPI API - haven't checked

    // spi_instance.apply(.{
    //     .clock_config = hal.clock_config,
    //     .baud_rate = config.spi_baudrate,
    // });

    // Hardware reset
    hardwareReset();

    // Initialize display
    initDisplay(config.rotation);

    initialized = true;
}

fn hardwareReset() void {
    pins.rst.put(1);
    timer.sleep_ms(10);
    pins.rst.put(0);
    timer.sleep_ms(10);
    pins.rst.put(1);
    timer.sleep_ms(120);
}

fn initDisplay(rotation: u8) void {
    // Software reset
    writeCommand(.SWRESET);
    timer.sleep_ms(150);

    // Sleep out
    writeCommand(.SLPOUT);
    timer.sleep_ms(120);

    // Color mode - 16-bit RGB565
    writeCommandWithData(.COLMOD, &.{@intFromEnum(ColorMode.RGB565)});

    // Set rotation
    setRotation(rotation);

    // Frame rate control (normal mode)
    writeCommandWithData(.FRMCTR1, &.{ 0x01, 0x2C, 0x2D });
    writeCommandWithData(.FRMCTR2, &.{ 0x01, 0x2C, 0x2D });
    writeCommandWithData(.FRMCTR3, &.{ 0x01, 0x2C, 0x2D, 0x01, 0x2C, 0x2D });

    // Inversion control
    writeCommandWithData(.INVCTR, &.{0x07});

    // Power control
    writeCommandWithData(.PWCTR1, &.{ 0xA2, 0x02, 0x84 });
    writeCommandWithData(.PWCTR2, &.{0xC5});
    writeCommandWithData(.PWCTR3, &.{ 0x0A, 0x00 });
    writeCommandWithData(.PWCTR4, &.{ 0x8A, 0x2A });
    writeCommandWithData(.PWCTR5, &.{ 0x8A, 0xEE });

    // VCOM control
    writeCommandWithData(.VMCTR1, &.{0x0E});

    // Inversion off
    writeCommand(.INVOFF);

    // Normal display mode
    writeCommand(.NORON);
    timer.sleep_ms(10);

    // Display on
    writeCommand(.DISPON);
    timer.sleep_ms(100);

    // Clear screen to black
    fillScreen(BLACK);
}

/// Display Control
pub fn setRotation(rotation: u8) void {
    var madctl: u8 = MADCTL.RGB; // Use RGB order

    switch (rotation & 0x03) {
        0 => {
            // Portrait
            madctl |= MADCTL.MX;
        },
        1 => {
            // Landscape
            madctl |= MADCTL.MV;
        },
        2 => {
            // Portrait inverted
            madctl |= MADCTL.MY;
        },
        3 => {
            // Landscape inverted
            madctl |= MADCTL.MV | MADCTL.MY | MADCTL.MX;
        },
        else => unreachable,
    }

    writeCommandWithData(.MADCTL, &.{madctl});
}

pub fn setBacklight(on: bool) void {
    if (pins.bl) |bl| {
        bl.put(if (on) 1 else 0);
    }
}

pub fn displayOn(on: bool) void {
    writeCommand(if (on) .DISPON else .DISPOFF);
}

pub fn invertDisplay(invert: bool) void {
    writeCommand(if (invert) .INVON else .INVOFF);
}

/// Drawing Functions
pub fn setWindow(x0: u16, y0: u16, x1: u16, y1: u16) void {
    // Column address set
    writeCommand(.CASET);
    writeU16(x0);
    writeU16(x1);

    // Row address set
    writeCommand(.RASET);
    writeU16(y0);
    writeU16(y1);

    // Write to RAM
    writeCommand(.RAMWR);
}

pub fn drawPixel(x: u16, y: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    setWindow(x, y, x, y);
    writeU16(@bitCast(color));
}

pub fn fillScreen(color: Color16) void {
    fillRect(0, 0, width, height, color);
}

pub fn fillRect(x: u16, y: u16, w: u16, h: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    const x1 = @min(x + w - 1, width - 1);
    const y1 = @min(y + h - 1, height - 1);

    setWindow(x, y, x1, y1);

    const color_bytes: u16 = @bitCast(color);
    const pixel_count = (x1 - x + 1) * (y1 - y + 1);

    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select

    // Send color data for each pixel
    var i: u32 = 0;
    while (i < pixel_count) : (i += 1) {
        spi_instance.transceive_blocking(&.{
            @truncate(color_bytes >> 8),
            @truncate(color_bytes & 0xFF),
        });
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
    _ = x;
    _ = y;
    _ = char;
    _ = color;
    _ = bg_color;
    _ = size;
    // TODO: Import fonts?
}

pub fn drawString(x: u16, y: u16, text: []const u8, color: Color16, bg_color: Color16, size: u8) void {
    var cursor_x = x;
    for (text) |char| {
        drawChar(cursor_x, y, char, color, bg_color, size);
        cursor_x += 6 * size; // 5 pixels + 1 space
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

/// Write RGB565 framebuffer to display
pub fn writeFramebuffer(framebuffer: []const Color16) void {
    if (framebuffer.len != width * height) {
        return; // Invalid framebuffer size
    }

    setWindow(0, 0, width - 1, height - 1);

    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select

    // Write entire framebuffer
    for (framebuffer) |pixel| {
        const color_bytes: u16 = @bitCast(pixel);
        spi_instance.transceive_blocking(&.{
            @truncate(color_bytes >> 8),
            @truncate(color_bytes & 0xFF),
        });
    }

    pins.cs.put(1); // Deselect
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
