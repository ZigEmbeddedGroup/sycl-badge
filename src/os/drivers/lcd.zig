/// LCD Driver for RP2354B SYCL Badge OS
/// 160x128 LCD (90° clockwise rotation for the badge)
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const spi = hal.spi;
const timer = @import("timer.zig");
const dma = @import("dma.zig");
const board = microzig.board;
const font = board.font;
const terry = @import("../system/terry.zig");

/// Display Configuration
pub const width: u16 = 160;
pub const height: u16 = 128;
pub const xstart: u16 = 0;
pub const ystart: u16 = 0;

/// State machine for tracking pending DMA
const State = enum {
    /// Ready to send new data
    /// any draw operation will transition
    ready,
    /// Waiting for a pending DMA.
    /// interrupt will handle transition
    wait_dma,
    /// Waiting for a pending DMA to shutdown
    /// interrupt will handle transition
    shutdown_dma,
    /// The DMA has finished but the SPI queue needs to
    /// be flushed before we can modify control signals.
    /// poll() will handle transition.
    flush_spi,

    pub fn is_waiting_for_interrupt(st: State) bool {
        return st == .wait_dma or st == .shutdown_dma;
    }
};

/// Cleanup to do after DMA finishes, for any persistent
/// screen state
const PostDMACommands = enum {
    none,
    reset_orientation,
};

var _state: State = .ready;
var state: *volatile State = &_state;

var remaining_dmas: u32 = 0;
var dma_ptr: [*]const u16 = undefined;
var dma_len: usize = 0;
var dma_stride: usize = 0;
var dma_size: @TypeOf(microzig.chip.peripherals.DMA.CH0_CTRL_TRIG.read().DATA_SIZE) = .size_8;
var post_dma_commands: PostDMACommands = .none;

var int_running: bool = false;

pub fn interrupt_DMA_0() callconv(.c) void {
    const DMA = microzig.chip.peripherals.DMA;
    const flags = DMA.INTS0.raw;

    if (flags & 0b1 != 0) {
        // TODO this causes a double-end, figure out why. Probably missing volatile on some tracy state.
        //const z = terry.core0.zone_color_cond("INTERRUPT DMA_0 (LCD)", @src(), 0x00FF7F, terry.client.interrupt_trace_enabled); defer z.end();

        if (int_running) {
            board.led_pin.put(1);
        }
        int_running = true;

        var start_dma_buf: ?[]const u16 = null;

        switch (state.*) {
            .wait_dma => {
                if (remaining_dmas > 1) {
                    // Schedule the next DMA
                    remaining_dmas -= 1;
                    start_dma_buf = dma_ptr[0..dma_len];
                    dma_ptr += dma_stride;
                } else {
                    remaining_dmas = 0;
                    state.* = .flush_spi; // poll() will continue
                }
            },
            .shutdown_dma => {
                remaining_dmas = 0;
                state.* = .flush_spi;
            },
            .ready, .flush_spi => {},
        }

        int_running = false;

        DMA.INTS0.write_raw(0b1);

        // Don't start the new DMA until after clearing the status register!
        if (start_dma_buf) |buf| {
            dma.startLCD(buf);
        }
    }
}

pub fn poll() void {
    sync_resolve_state(false); // Don't wait for SPI to flush, we will poll again soon.
}

/// Microzig's write implementation doesn't compile with
/// u16, so this is a copy.
fn write_spi_16(data: []const u16) void {
    write_spi_16_no_flush(data);
    flush_spi();
}

fn write_spi_16_no_flush(data: []const u16) void {
    const spi_regs = spi_instance.get_regs();

    var idx: usize = 0;

    // Prime the fifo if it isn't already running
    if (spi_regs.SSPSR.read().BSY == 0) {
        spi_regs.SSPCR1.modify(.{
            .SSE = 0,
        });
        while (spi_instance.is_writable() and idx < data.len) : (idx += 1) {
            spi_regs.SSPDR.write_raw(data[idx]);
        }
        spi_regs.SSPCR1.modify(.{
            .SSE = 1,
        });
    }

    for (data[idx..]) |datum| {
        while (!spi_instance.is_writable()) {}
        spi_regs.SSPDR.write_raw(datum);
    }
}

fn flush_spi() void {
    const spi_regs = spi_instance.get_regs();

    const z = terry.core0.fn_zone_cond(@src(), spi_regs.SSPSR.read().BSY != 0);
    defer z.end();

    // Drain RX FIFO, then wait for shifting to finish (which may be *after*
    // TX FIFO drains), then drain RX FIFO again
    while (spi_instance.is_readable()) {
        _ = spi_regs.SSPDR.read();
    }
    while (spi_regs.SSPSR.read().BSY != 0) {}
    flush_spi_rx_values();
}

fn is_spi_active() bool {
    const spi_regs = spi_instance.get_regs();
    return spi_regs.SSPSR.read().BSY != 0;
}

fn flush_spi_rx_values() void {
    const spi_regs = spi_instance.get_regs();
    while (spi_instance.is_readable()) {
        _ = spi_regs.SSPDR.read();
    }
    // Don't leave overrun flag set
    spi_regs.SSPICR.modify(.{ .RORIC = 1 });
}

fn sync_resolve_state(wait_for_transfer: bool) void {
    if (state.* == .flush_spi) {
        if (wait_for_transfer) {
            flush_spi();
        } else if (is_spi_active()) {
            return;
        } else {
            flush_spi_rx_values();
        }
        finish_DMA_data();
        switch (post_dma_commands) {
            .none => {},
            .reset_orientation => {
                writeCommandWithData(.MADCTL, &.{0x60});
            },
        }
        state.* = .ready;
    }
}

fn wait_for_ready() void {
    const z = terry.core0.fn_zone_cond(@src(), state.*.is_waiting_for_interrupt());
    defer z.end();

    while (state.*.is_waiting_for_interrupt()) {}
    sync_resolve_state(true); // force synchronous SPI flush
}

fn ensure_ready() void {
    if (state.* != .ready) {
        // TODO: this is a programmer error, it will likely
        // cause an audio glitch. Find a way to report this
        // for OS debugging without crashing everything.
        wait_for_ready();
    }
}

// Pin assignments (control pins only)
pub const Pins = struct {
    cs: gpio.Pin, // Chip Select
    dc: gpio.Pin, // Data/Command
    rst: ?gpio.Pin, // Reset (optional, may be tied to hardware)
    bl: gpio.Pin, // Backlight (this pin is tied to ground)
};

pub const backlight = hal.pwm.Pwm{
    .slice_number = 0,
    .channel = .a,
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
    te: ?gpio.Pin,
};

// Color formats
// RGB565: High byte = RRRRR GGG, Low byte = GGG BBBBB
pub const Color16 = packed struct(u16) {
    r: u5,
    g: u6,
    b: u5,

    pub fn rgb(r: u8, g: u8, b: u8) Color16 {
        return .{
            .r = @truncate(r >> 3),
            .g = @truncate(g >> 2),
            .b = @truncate(b >> 3),
        };
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
    spi_instance.write_blocking(u8, &.{@backingInt(cmd)});
    pins.cs.put(1); // Deselect
}

fn writeData8(data: []const u8) void {
    pins.cs.put(1); // Deselect first
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select
    spi_instance.write_blocking(u8, data);
    pins.cs.put(1); // Deselect
}

fn writeData16(data: []const u16) void {
    pins.cs.put(1); // Deselect first
    pins.dc.put(1); // Data mode
    pins.cs.put(0); // Select
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 15 });
    write_spi_16(data);
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 7 });
    pins.cs.put(1); // Deselect
}

fn startData() void {
    pins.dc.put(1);
    pins.cs.put(0);
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 15 });
}

fn endData() void {
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 7 });
    pins.cs.put(1);
}

fn start_DMA_data() void {
    startData();
    dma.set_DMA_enabled(true);
}

fn finish_DMA_data() void {
    dma.set_DMA_enabled(false);
    endData();
}

fn writeCommandWithData(cmd: Command, data: []const u8) void {
    writeCommand(cmd);
    if (data.len > 0) {
        writeData8(data);
    }
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
    const z = terry.core0.zone("lcd.init", @src());
    defer z.end();

    pins = pin_config;

    // Configure GPIO pins
    pins.cs.set_function(.sio);
    pins.cs.set_direction(.out);
    pins.cs.put(1); // Deselect

    pins.dc.set_function(.sio);
    pins.dc.set_direction(.out);
    pins.dc.put(1);

    if (pins.rst) |rst| {
        rst.set_function(.sio);
        rst.set_direction(.out);
        rst.put(0);
    }

    pins.bl.set_function(.pwm);
    backlight.slice().set_clk_div(150, 0);
    backlight.slice().set_wrap(1023);
    backlight.set_level(512);
    backlight.slice().enable();

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

    // Enable DMA
    dma.init();

    // Hardware reset sequence
    if (pins.rst) |rst| {
        rst.put(1);
        timer.sleep_ms(5);
        rst.put(0);
        timer.sleep_ms(20);
        rst.put(1);
        timer.sleep_ms(50);
    } else {
        timer.sleep_ms(50);
    }

    // Initialize display
    initDisplay();
}

fn initDisplay() void {
    const z = terry.core0.fn_zone(@src());
    defer z.end();

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
    // MV (0x20) = Row/Column exchange, MX (0x40) = Column address order
    writeCommandWithData(.MADCTL, &.{0x60}); // 90° CW rotation, RGB

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

    // Enable DMA to send data to the screen
    dma.initLCD(spi_instance_num);
}

/// Re-initialize display registers (call after cart stops to restore LCD settings)
/// This performs a quick reinit without full hardware reset for faster recovery
pub fn reinitDisplay() void {
    const z = terry.core0.fn_zone(@src());
    defer z.end();

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
    writeCommandWithData(.MADCTL, &.{0x60}); // 90° CW rotation, RGB
    writeCommandWithData(.COLMOD, &.{0x05}); // 16-bit RGB565
    writeCommand(.NORON); // Normal display mode
    writeCommand(.DISPON); // Display on
    timer.sleep_ms(5); // Short delay for display to stabilize
}

pub fn set_backlight(level: u10) void {
    backlight.set_level(level);
}

/// Prepare LCD for cart execution
/// Ensures clean state with proper color mode
pub fn prepareForCart() void {
    // Ensure LCD is in normal, non-inverted mode with correct orientation
    writeCommand(.NORON); // Normal display mode (not partial)
    writeCommand(.INVOFF); // Turn off color inversion
    writeCommandWithData(.MADCTL, &.{0x60}); // 90° CW rotation, RGB
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
    writeData8(&col_data);

    // Row address set - send all 4 bytes at once
    writeCommand(.RASET);
    const row_data = [_]u8{
        0x00,
        @truncate(y0_offset),
        0x00,
        @truncate(y1_offset),
    };
    writeData8(&row_data);

    writeCommand(.RAMWR);
}

pub fn drawPixel(x: u16, y: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    ensure_ready();

    setWindow(x, y, x, y);
    writeData16(@ptrCast(@as(*const [1]Color16, &color)));
}

pub fn fillScreen(color: Color16) void {
    fillRect(0, 0, width, height, color);
}

pub fn fillRect(x: u16, y: u16, w: u16, h: u16, color: Color16) void {
    if (x >= width or y >= height) return;

    const z = terry.core0.fn_zone_cond(@src(), w * h > 16);
    defer z.end();

    const x_clamped = @min(x, width - 1);
    const y_clamped = @min(y, height - 1);
    const w_actual = @min(w, width - x_clamped);
    const h_actual = @min(h, height - y_clamped);

    if (w_actual == 0 or h_actual == 0) return;

    const x1 = x_clamped + w_actual - 1;
    const y1 = y_clamped + h_actual - 1;

    ensure_ready();

    setWindow(x_clamped, y_clamped, x1, y1);

    // Create a line buffer
    var line: [width]u16 = undefined;
    @memset(line[0..w_actual], @bitCast(color));

    // Keep CS selected for entire fill operation to reduce overhead
    startData();

    // Write each line
    var row: u16 = 0;
    while (row < h_actual) : (row += 1) {
        write_spi_16_no_flush(line[0..w_actual]);
    }

    flush_spi();

    endData();
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

    ensure_ready();

    // Draw the character bitmap
    if (size == 1) {
        // Single-size characters: write each row as a contiguous 8-pixel transfer
        setWindow(x, y, x + 7, y + 7);
        startData();
        var row_idx: u8 = 0;
        while (row_idx < 8) : (row_idx += 1) {
            const line = glyph[row_idx];
            var buf: [8]u16 = undefined; // 8 pixels * 2 bytes
            var col: u8 = 0;
            while (col < 8) : (col += 1) {
                // Check if pixel is set (0 = foreground, 1 = background in this font)
                const bit_set = (line & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                const pixel_color = if (bit_set) color else bg_color;
                buf[col] = @bitCast(pixel_color);
            }
            // Set window for this row and stream it as one transfer
            write_spi_16_no_flush(&buf);
        }
        flush_spi();
        endData();
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
    const z = terry.core0.fn_zone(@src());
    defer z.end();

    var cursor_x = x;
    for (text) |char| {
        drawChar(cursor_x, y, char, color, bg_color, size);
        cursor_x += 8 * size; // 8 pixels per character
    }
}

pub fn drawImageClipped(x: i32, y: i32, w: u32, h: u32, data: [*]const Color16, pitch: u32) void {
    const right = x +% @as(i32, @intCast(w));
    const bottom = y +% @as(i32, @intCast(h));
    if (right < 0) return; // Offscreen left
    if (x >= width) return; // Offscreen right
    if (bottom < 0) return; // Offscreen top
    if (y >= height) return; // Offscreen bottom
    if (w == 0 or h == 0) return; // No Area

    const z = terry.core0.fn_zone(@src());
    defer z.end();

    var start = data;
    var draw_width = w;
    var draw_height = h;
    if (x < 0) {
        start += @intCast(-x);
        draw_width -= @intCast(-x);
    }
    if (y < 0) {
        start += @intCast(@as(u32, @intCast(-y)) * pitch);
        draw_height -= @intCast(-y);
    }
    if (right > width) {
        draw_width -= @intCast(right - width);
    }
    if (bottom > height) {
        draw_height -= @intCast(bottom - height);
    }

    const x0: u16 = @intCast(@max(x, 0));
    const y0: u16 = @intCast(@max(y, 0));
    const x1: u16 = @intCast(x0 + draw_width - 1);
    const y1: u16 = @intCast(y0 + draw_height - 1);

    ensure_ready();

    setWindow(x0, y0, x1, y1);
    if (draw_width == pitch) {
        {
            const cs = microzig.interrupt.enter_critical_section();
            defer cs.leave();

            remaining_dmas = 1;
            state.* = .wait_dma;
            post_dma_commands = .none;
        }

        start_DMA_data();

        dma.startLCD(@ptrCast(start[0 .. draw_height * draw_width]));
    } else {
        {
            const cs = microzig.interrupt.enter_critical_section();
            defer cs.leave();

            remaining_dmas = draw_height;
            state.* = .wait_dma;
            dma_stride = pitch;
            dma_ptr = @ptrCast(start + pitch);
            dma_len = draw_width;
            post_dma_commands = .none;
        }

        start_DMA_data();

        dma.startLCD(@ptrCast(start[0..draw_width]));
    }
}

/// Direct buffer writing (for framebuffer updates)
pub fn writeBuffer(x: u16, y: u16, w: u16, h: u16, buffer: []const u16) void {
    if (x >= width or y >= height) return;

    const z = terry.core0.fn_zone(@src());
    defer z.end();

    const x1 = @min(x + w - 1, width - 1);
    const y1 = @min(y + h - 1, height - 1);

    ensure_ready();

    setWindow(x, y, x1, y1);
    writeData16(buffer);
}

/// Write a column-major framebuffer (the cart API layout) to the full display.
///
/// Temporarily switches to MADCTL=0x40 (MV=0, MX=1, MY=0) so the
/// native column axis (128 = screen-Y) is the fast scan direction, matching
/// the framebuffer memory order, and the image orientation matches the
/// right-side-up landscape MADCTL=0x60 used for normal UI rendering.
pub fn writeCartBuffer(buffer: []const u16) void {
    ensure_ready();

    // MV=0: no row/column exchange; CASET = native cols (0-127), RASET = native rows (0-159).
    // MX=1: columns scan 127→0 so cart_y=0 maps to native col 127 (screen top, since
    //        landscape MADCTL=0x60 maps native_col=127-screen_y).
    // MY=0: rows scan 0→159 so cart_x=0 maps to native row 0 (screen left).
    writeCommandWithData(.MADCTL, &.{0x40});

    // With MV=0: CASET = native columns (0-127), RASET = native rows (0-159).
    // Send CASET/RASET directly to avoid confusion with setWindow's x/y naming.
    writeCommand(.CASET);
    writeData8(&[_]u8{ 0x00, 0x00 + xstart, 0x00, 127 + xstart });
    writeCommand(.RASET);
    writeData8(&[_]u8{ 0x00, 0x00 + ystart, 0x00, 159 + ystart });
    writeCommand(.RAMWR);

    start_DMA_data();

    {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        remaining_dmas = 1;
        state.* = .wait_dma;
        post_dma_commands = .reset_orientation;
    }

    dma.startLCD(buffer);
}

/// Write only a rectangle from a column-major cart framebuffer.
///
/// Rect is in cart coordinates (x:0..159, y:0..127), where x is horizontal
/// and y is vertical on the user-facing display.
pub fn writeCartBufferRect(buffer: []const u16, x: u16, y: u16, w: u16, h: u16) void {
    // If the update is very large, full-frame transfer is usually cheaper.
    const area: u32 = @as(u32, w) * @as(u32, h);
    if (area >= (width * height * 3) / 4) {
        writeCartBuffer(buffer);
        return;
    }

    if (x >= width or y >= height or w == 0 or h == 0) return;

    const x0: u16 = x;
    const y0: u16 = y;
    const x1: u16 = @min(x + w - 1, width - 1);
    const y1: u16 = @min(y + h - 1, height - 1);

    const rw: u16 = 1 + x1 - x0;
    const rh: u16 = 1 + y1 - y0;
    if (rw == 0 or rh == 0) return;

    ensure_ready();

    // MV=0/MX=1/MY=0 mode matching writeCartBuffer.
    writeCommandWithData(.MADCTL, &.{0x40});

    // In this mode, cart x maps to native row and cart y maps to native col (reversed).
    const col_start: u16 = y0;
    const col_end: u16 = y1;
    const row_start: u16 = x0;
    const row_end: u16 = x1;

    writeCommand(.CASET);
    writeData8(&[_]u8{ 0x00, @truncate(col_start + xstart), 0x00, @truncate(col_end + xstart) });
    writeCommand(.RASET);
    writeData8(&[_]u8{ 0x00, @truncate(row_start + ystart), 0x00, @truncate(row_end + ystart) });
    writeCommand(.RAMWR);

    const col_base = @as(usize, x0) * height + y0;

    start_DMA_data();

    {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        remaining_dmas = rw;
        state.* = .wait_dma;
        dma_stride = height;
        dma_ptr = buffer.ptr + col_base + height;
        dma_len = rh;
        post_dma_commands = .reset_orientation;
    }

    dma.startLCD(buffer[col_base..][0..rh]);
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

            // RST: Reset (tied to hardware on v2, no GPIO control)
            .rst = null,

            // BKLT_PWM: Backlight (connected to VBUS/5V, no GPIO control)
            .bl = board.BKLT_PWM,
        },
        .spi = .{
            // LCD_SCL: Serial Clock
            .scl = board.TFT_SCK,

            // LCD_SDIO: Serial Data I/O MOSI
            .sdo = board.TFT_MOSI,
        },
        // TE: Tearing Effect (optional, leave it disconnected for now)
        .te = board.LCD_TE,
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

// DMA Functions

pub fn vsync() void {
    wait_for_ready();
}

/// Stop DMA transfers
pub fn stopDMA() void {
    var wait_for_shutdown = false;
    {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        if (state.*.is_waiting_for_interrupt()) {
            state.* = .shutdown_dma;
            wait_for_shutdown = true;
        }
    }
    if (wait_for_shutdown) {
        wait_for_ready();
    } else {
        sync_resolve_state(true); // synchronously wait for flush
    }

    // Deselect LCD
    pins.cs.put(1);
}

/// Check if DMA transfer in progress
pub fn isBusy() bool {
    sync_resolve_state(false); // Don't wait for synchronous flush
    return state.* != .ready;
}

/// Fast fill screen with single color
var clear_val: [1]u16 = undefined;
pub fn clearScreen(color: Color16) void {
    ensure_ready();

    clear_val[0] = @bitCast(color);

    setWindow(0, 0, width - 1, height - 1);

    start_DMA_data();

    {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        remaining_dmas = 1;
        state.* = .wait_dma;
        post_dma_commands = .none;
    }

    // Start/restart DMA transfer (CS stays low, DC stays high)
    dma.startLCDPattern(&clear_val, 0, width * height);
}
