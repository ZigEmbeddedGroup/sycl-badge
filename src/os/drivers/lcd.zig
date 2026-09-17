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
const fps_overlay = @import("../system/fps_overlay.zig");
const abi = @import("../cart/os_abi.zig");

const Rect8 = abi.Rect8;

const log = std.log.scoped(.lcd);

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
    /// Waiting for vsync before starting the next DMA
    wait_vsync,
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
        return switch (st) {
            .wait_vsync, .wait_dma, .shutdown_dma => true,
            .ready, .flush_spi => false,
        };
    }
};

/// Orientation of the data to be sent to the screen
const DataOrientation = enum {
    row_major, // data[y][x]
    col_major, // data[x][y], scanline rendering order
};

var _state: State = .ready;
var state: *volatile State = &_state;

var dma_buf: [*]const u16 = undefined;
var dma_buf_pitch: usize = 0;
var dma_rects: [5]Rect8 = undefined;
var num_dma_rects: usize = 0;
var next_dma_rect: usize = 0;
var curr_scanlines_left: usize = 0;
var curr_scanline: [*]const u16 = undefined;
var curr_scanline_width: usize = 0;
var dma_orientation: DataOrientation = .row_major;

var cart_vsync_enabled: bool = false;

fn setup_dma_rects(buf: [*]const u16, buf_pitch: usize, num_rects: usize, orientation: DataOrientation) void {
    dma_buf = buf;
    dma_buf_pitch = buf_pitch;
    num_dma_rects = num_rects;
    next_dma_rect = 0;
    curr_scanlines_left = 0;
    curr_scanline = undefined;
    curr_scanline_width = 0;
    dma_orientation = orientation;
}

fn setup_dma_region(buf: [*]const u16, buf_pitch: usize, scanline_width: usize, num_scanlines: usize, orientation: DataOrientation) void {
    dma_buf_pitch = buf_pitch;
    num_dma_rects = 0;
    next_dma_rect = 0;
    curr_scanline = buf;
    if (scanline_width == buf_pitch) {
        curr_scanline_width = scanline_width * num_scanlines;
        curr_scanlines_left = 1;
    } else {
        curr_scanline_width = scanline_width;
        curr_scanlines_left = num_scanlines;
    }
    dma_orientation = orientation;
}

fn start_scanline_dma() void {
    asm volatile ("" ::: .{ .memory = true });
    state.* = .wait_dma;

    std.debug.assert(curr_scanlines_left >= 1);
    dma.startLCD(curr_scanline[0..curr_scanline_width]);
    curr_scanline += dma_buf_pitch;
    curr_scanlines_left -= 1;
}

fn start_next_dma() void {
    if (curr_scanlines_left > 0) {
        start_scanline_dma();
        return;
    } else while (next_dma_rect < num_dma_rects) {
        const rect = &dma_rects[next_dma_rect];
        next_dma_rect += 1;
        if (!rect.has_area()) {
            continue;
        }

        // Update the DMA rect
        flush_spi();
        end_data();
        set_window(rect.*, dma_orientation);
        start_data();

        curr_scanline = dma_buf + (rect.min_x * dma_buf_pitch) + rect.min_y;
        curr_scanline_width = (rect.max_y - rect.min_y);
        curr_scanlines_left = (rect.max_x - rect.min_x);
        if (curr_scanline_width == dma_buf_pitch) {
            curr_scanline_width *= curr_scanlines_left;
            curr_scanlines_left = 1;
        }

        start_scanline_dma();
        return;
    }

    state.* = .flush_spi;
}

var int_running: bool = false;

// Interrupt handler for the "tearing effect" pin.
// Called on vsync when set_vsync_interrupt(true)
// has been called.
pub fn interrupt_te(events: gpio.IrqEvents) void {
    if (events.rise != 0 and state.* == .wait_vsync) {
        state.* = .wait_dma;
        start_next_dma();
        set_vsync_interrupt(false);
    }
}

// Interrupt handler for DMA finished
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

        var should_start_dma = false;

        handle_dma: switch (state.*) {
            .wait_vsync => {
                // Shouldn't happen, we shouldn't be running DMAs
                // while waiting for vsync. To prevent a softlock,
                // chain the DMA anyway.
                log.err("interrupt_DMA_0 called in wait_vsync state", .{});
                continue :handle_dma .wait_dma;
            },
            .wait_dma => {
                should_start_dma = true;
            },
            .shutdown_dma => {
                setup_dma_region(undefined, 1, 0, 0, dma_orientation);
                state.* = .flush_spi;
            },
            .ready, .flush_spi => {},
        }

        int_running = false;

        DMA.INTS0.write_raw(0b1);

        // Don't start the new DMA until after clearing the status register!
        if (should_start_dma) {
            start_next_dma();
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
        end_data();
        switch (dma_orientation) {
            .row_major => {},
            .col_major => {
                writeCommandWithData(.MADCTL, &.{0x60});
            },
        }
        state.* = .ready;
    }
}

pub fn wait_for_ready() void {
    const z = terry.core0.fn_zone_cond(@src(), state.*.is_waiting_for_interrupt());
    defer z.end();

    while (state.*.is_waiting_for_interrupt()) {}
    sync_resolve_state(true); // force synchronous SPI flush
}

// Enable the vsync interrupt.
// This interrupt is "one-shot", it disables itself.
// It must be enabled again any time we want to wait
// for vsync.
fn set_vsync_interrupt(enabled: bool) void {
    const te_pin = board.LCD_TE;
    if (enabled) {
        te_pin.set_irq_enabled(.{ .rise = 1 }, true);
    } else {
        te_pin.set_irq_enabled(.{ .rise = 1 }, false);
    }
}

fn ensure_ready() void {
    if (state.* != .ready) {
        // TODO: this is a programmer error, it will likely
        // cause an audio glitch. Find a way to report this
        // for OS debugging without crashing everything.
        log.warn("Blocking wait for LCD DMA to finish", .{});
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

const Command = enum(u8) {
    SWRESET = 0x01,
    SLPOUT = 0x11,
    NORON = 0x13,
    INVOFF = 0x20,
    INVON = 0x21,
    GAMSET = 0x26,
    DISPOFF = 0x28,
    DISPON = 0x29,
    CASET = 0x2A, // Column Address Set
    RASET = 0x2B, // Row Address Set
    RAMWR = 0x2C, // Memory Write
    TEAROFF = 0x34, // Disable tearing effect (vsync) signal
    TEARON = 0x35, // Enable tearing effect (vsync) signal
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
    VMOFF = 0xC7,
    GMCTRP1 = 0xE0,
    GMCTRN1 = 0xE1,
    gamma_adjustment = 0xF2,
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

fn start_data() void {
    pins.dc.put(1);
    pins.cs.put(0);
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 15 });
}

fn end_data() void {
    spi_instance.get_regs().SSPCR0.modify(.{ .DSS = 7 });
    pins.cs.put(1);
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
pub fn init(lcd_pins: LCDPins, config: Config) !void {
    const z = terry.core0.zone("lcd.init", @src());
    defer z.end();

    pins = lcd_pins.control;

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
    backlight.slice().set_clk_div(.{
        .int = 150,
        .frac = 0,
    });
    backlight.slice().set_wrap(1023);
    backlight.set_level(0);
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
    init_display();
}

fn init_display() void {
    const z = terry.core0.fn_zone(@src());
    defer z.end();

    writeCommandWithData(.SWRESET, &.{});
    timer.sleep_ms(120);

    writeCommandWithData(.SLPOUT, &.{});
    timer.sleep_ms(5);

    writeCommandWithData(.COLMOD, &.{0x05});
    writeCommandWithData(.GAMSET, &.{0x04});
    writeCommandWithData(.gamma_adjustment, &.{0x01});
    writeCommandWithData(.GMCTRP1, &.{
        0x3F, 0x25, 0x1C, 0x1E, 0x20, 0x12, 0x2A, 0x90,
        0x24, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00,
    });
    writeCommandWithData(.GMCTRN1, &.{
        0x20, 0x20, 0x20, 0x20, 0x05, 0x00, 0x15, 0xA7,
        0x3D, 0x18, 0x25, 0x2A, 0x2B, 0x2B, 0x3A,
    });

    set_framerate_no_vsync();

    writeCommandWithData(.INVCTR, &.{0x07});
    writeCommandWithData(.PWCTR1, &.{ 0x0A, 0x02 });
    writeCommandWithData(.PWCTR2, &.{0x02});
    writeCommandWithData(.VMCTR1, &.{ 0x50, 0x5B });
    writeCommandWithData(.VMOFF, &.{0x40});
    writeCommandWithData(.TEARON, &.{0x00}); // enable vsync but not hsync
    writeCommandWithData(.CASET, &.{ 0x00, 0x00, 0x00, 0x7F });
    writeCommandWithData(.RASET, &.{ 0x00, 0x00, 0x00, 0x9F });

    timer.sleep_ms(250);

    writeCommandWithData(.MADCTL, &.{0x60});

    // Display on
    writeCommandWithData(.DISPON, &.{});

    // Enable DMA to send data to the screen
    dma.initLCD(spi_instance_num);
}

fn set_framerate_no_vsync() void {
    ensure_ready();

    writeCommandWithData(.FRMCTR1, &.{ 0x08, 0x08 });
}

fn frame_ms_for_settings(clk_div: f32, vsync_porch: f32) f32 {
    return ((160.0 + vsync_porch) * (clk_div + 4.0)) / 200.0;
}

const FramerateSetting = struct {
    actual_ms: f32,
    sub_frames: u16,
    clk_div: u8,
    vsync_porch: u8,
};

fn find_framerate_setting(raw_frame_ms: f32) FramerateSetting {
    // The maximum refresh time is about 18 mS. For requested times longer than that,
    // we need to divide it into sub-frames.
    const max_single_frame = comptime frame_ms_for_settings(0x0F, 0x1F);
    const min_sub_frames = @max(1, @ceil(raw_frame_ms / max_single_frame));
    const target_frame_ms = raw_frame_ms / min_sub_frames;

    // Testing shows framerates under this may tear.
    // I would love to have math to back up this number.
    // This is ~11.5 mS per frame. We can probably get it down to 9 mS
    // by optimizing the rectangular DMA to avoid needing interrupt
    // attention. We can get it down further by changing SPI to run
    // on a faster clock or by reimplemting SPI to run on PIO (which
    // has a N/M clock divider)
    const min_frame_without_tearing = comptime frame_ms_for_settings(0x08, 0x1F);
    if (target_frame_ms < min_frame_without_tearing) {
        return .{
            .actual_ms = min_frame_without_tearing * min_sub_frames,
            .sub_frames = @intFromFloat(min_sub_frames),
            .clk_div = 0x08,
            .vsync_porch = 0x1F,
        };
    }

    // FRMCTR1 sets the framerate. Params [clk_div: u4, vsync_porch: u5]
    //The formula is
    // FPS = 200_000 / ((160 + vsync_porch) * (clk_div + 4))
    //  mS = ((160 + vsync_porch) * (clk_div + 4)) / 200

    // We want to have a low clock (to conserve power), but we also want
    // a high ratio of porch to refresh, to avoid flashing. To split the
    // difference, find the minimum clock rate that supports the target,
    // then adjust the porch to match it.
    var clk_div: f32 = 0x0F;
    var vsync_porch: f32 = 0x1F;

    var actual_ms = max_single_frame;
    while (clk_div > 0) {
        const next_ms = frame_ms_for_settings(clk_div - 1, vsync_porch);
        if (next_ms < target_frame_ms) break;
        actual_ms = next_ms;
        clk_div -= 1;
    }

    while (vsync_porch > 0) {
        const next_ms = frame_ms_for_settings(clk_div, vsync_porch - 1);
        if (next_ms < target_frame_ms) break;
        actual_ms = next_ms;
        vsync_porch -= 1;
    }

    return .{
        .actual_ms = actual_ms * min_sub_frames,
        .sub_frames = @intFromFloat(min_sub_frames),
        .clk_div = @intFromFloat(clk_div),
        .vsync_porch = @intFromFloat(vsync_porch),
    };
}

fn set_target_framerate_for_vsync(raw_frame_ms: f32) void {
    const setting = find_framerate_setting(raw_frame_ms);

    ensure_ready();

    writeCommandWithData(.FRMCTR1, &.{ setting.clk_div, setting.vsync_porch });
}

pub fn disable_vsync() void {
    set_framerate_no_vsync();
    cart_vsync_enabled = false;
}

pub fn enable_vsync(frame_ms: f32) void {
    set_target_framerate_for_vsync(frame_ms);
    cart_vsync_enabled = true;
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

/// Drawing Functions
fn set_window(raw_rect: Rect8, orientation: DataOrientation) void {
    const rect: Rect8 = switch (orientation) {
        .row_major => raw_rect,
        .col_major => raw_rect.transposed(),
    };

    const x0_offset = rect.min_x + xstart;
    const x1_offset = rect.max_x - 1 + xstart;
    const y0_offset = rect.min_y + ystart;
    const y1_offset = rect.max_y - 1 + ystart;

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

pub fn drawPixel(x: i16, y: i16, color: Color16) void {
    const rect: Rect8 = .clip_relative(i16, .{ x, y, 1, 1 });
    if (!rect.has_area()) return;

    ensure_ready();

    set_window(rect, .row_major);
    writeData16(@ptrCast(@as(*const [1]Color16, &color)));
}

pub fn fillScreen(color: Color16) void {
    fillRect(0, 0, width, height, color);
}

pub fn fillRect(x: i16, y: i16, w: i16, h: i16, color: Color16) void {
    const rect: Rect8 = .clip_relative(i16, .{ x, y, w, h });
    if (!rect.has_area()) return;

    const z = terry.core0.fn_zone_cond(@src(), w * h > 16);
    defer z.end();

    ensure_ready();

    set_window(rect, .row_major);

    const h_actual = rect.max_y - rect.min_y;
    const w_actual = rect.max_x - rect.min_x;

    // Create a line buffer
    var line: [width]u16 = undefined;
    @memset(line[0..w_actual], @bitCast(color));

    // Keep CS selected for entire fill operation to reduce overhead
    start_data();

    // Write each line
    var row: u16 = 0;
    while (row < h_actual) : (row += 1) {
        write_spi_16_no_flush(line[0..w_actual]);
    }

    flush_spi();

    end_data();
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

pub fn drawChar(x: i16, y: i16, char: u8, color: Color16, bg_color: Color16, size: u8) void {
    if (x >= width or y >= height) return;
    if (size == 0) return;

    // Get font data for this character (font starts at space ' ')
    const char_index = if (char >= ' ') char - ' ' else 0;
    if (char_index >= font.font.len) return;

    const glyph = font.font[char_index];

    ensure_ready();

    // Draw the character bitmap
    if (size == 1) {
        const rect: Rect8 = .clip_relative(i16, .{ x, y, 8, 8 });
        if (!rect.has_area()) return;

        const start_col: u8 = @intCast(@max(0, -x));
        const start_row: u8 = @intCast(@max(0, -y));
        const max_col: u8 = @intCast(rect.max_x - x);
        const max_row: u8 = @intCast(rect.max_y - y);
        // Single-size characters: write each row as a contiguous 8-pixel transfer
        set_window(rect, .row_major);
        start_data();
        var row_idx: u8 = start_row;
        while (row_idx < max_row) : (row_idx += 1) {
            const line = glyph[row_idx];
            var buf: [8]u16 = undefined; // 8 pixels * 2 bytes
            var col: u8 = start_col;
            while (col < max_col) : (col += 1) {
                // Check if pixel is set (0 = foreground, 1 = background in this font)
                const bit_set = (line & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                const pixel_color = if (bit_set) color else bg_color;
                buf[col] = @bitCast(pixel_color);
            }
            // Set window for this row and stream it as one transfer
            write_spi_16_no_flush(buf[start_col..max_col]);
        }
        flush_spi();
        end_data();
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
                fillRect(x + @as(i16, col) * size, y + @as(i16, row) * size, size, size, pixel_color);
            }
        }
    }
}

pub fn drawString(x: i16, y: i16, text: []const u8, color: Color16, bg_color: Color16, size: u8) void {
    const z = terry.core0.fn_zone(@src());
    defer z.end();

    var cursor_x = x;
    for (text) |char| {
        drawChar(cursor_x, y, char, color, bg_color, size);
        cursor_x += 8 * size; // 8 pixels per character
    }
}

pub noinline fn drawImageClipped(x: i16, y: i16, w: i16, h: i16, data: [*]const Color16, pitch: u32) void {
    const rect: Rect8 = .clip_relative(i16, .{ x, y, w, h });
    if (!rect.has_area()) return;

    const start_col: u8 = @intCast(@max(0, -x));
    const start_row: u8 = @intCast(@max(0, -y));
    const max_col: u8 = @intCast(rect.max_x - x);
    const max_row: u8 = @intCast(rect.max_y - y);

    ensure_ready();

    if (@sizeOf(@TypeOf(data[0])) != @sizeOf(u16)) @compileError("Image data must be colors");
    const raw_data: [*]const u16 = @ptrCast(data);
    setup_dma_region(raw_data + start_row * pitch + start_col, pitch, max_col - start_col, max_row - start_row, .row_major);

    set_window(rect, .row_major);
    start_data();
    start_next_dma();
}

/// Write a rectangle from a column-major cart framebuffer.
///
/// Rect is in cart coordinates (x:0..159, y:0..127), where x is horizontal
/// and y is vertical on the user-facing display.
/// Temporarily switches to MADCTL=0x40 (MV=0, MX=1, MY=0) so the
/// native column axis (128 = screen-Y) is the fast scan direction, matching
/// the framebuffer memory order, and the image orientation matches the
/// right-side-up landscape MADCTL=0x60 used for normal UI rendering.
pub fn write_cart_buffer(buffer: []const u16, rect: Rect8) void {
    const has_data = rect.has_area();
    if (!has_data and !cart_vsync_enabled) return;

    ensure_ready();

    if (has_data) {
        writeCommandWithData(.MADCTL, &.{0x40});

        const num_rects = fps_overlay.clip_draw_rects(rect, &dma_rects);
        setup_dma_rects(buffer.ptr, height, num_rects, .col_major);
    } else {
        setup_dma_region(undefined, 1, 0, 0, .row_major);
    }

    if (cart_vsync_enabled) {
        asm volatile ("" ::: .{ .memory = true });
        state.* = .wait_vsync;
        set_vsync_interrupt(true);
    } else if (has_data) {
        start_next_dma();
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
    try init(all_pins, config);
}

// DMA Functions

/// Stop DMA transfers
fn stop_DMA() void {
    var wait_for_shutdown = false;
    {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        set_vsync_interrupt(false);

        switch (state.*) {
            .wait_vsync => {
                state.* = .flush_spi;
            },
            .wait_dma => {
                state.* = .shutdown_dma;
                wait_for_shutdown = true;
            },
            .shutdown_dma => {
                wait_for_shutdown = true; // Shouldn't happen but just in case
            },
            .flush_spi, .ready => {},
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

pub fn reset() void {
    stop_DMA();

    disable_vsync();
}

/// Check if DMA transfer in progress
pub fn is_busy() bool {
    sync_resolve_state(false); // Don't wait for synchronous flush
    return state.* != .ready;
}

pub fn is_waiting_for_vsync() bool {
    // No need to sync, that won't affect
    // whether vsync is happening
    return state.* != .wait_vsync;
}

/// Fast fill screen with single color
var clear_val: [1]u16 = undefined;
pub fn clearScreen(color: Color16) void {
    ensure_ready();

    clear_val[0] = @bitCast(color);

    setup_dma_region(undefined, 1, 0, 1, .row_major);

    set_window(.all, .row_major);
    start_data();

    asm volatile ("" ::: .{ .memory = true });
    state.* = .wait_dma;
    dma.startLCDPattern(&clear_val, 0, width * height);
}
