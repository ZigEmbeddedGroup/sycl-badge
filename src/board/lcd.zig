const std = @import("std");

const microzig = @import("microzig");
const hal = microzig.hal;
const sercom = hal.sercom;
const port = hal.port;
const timer = hal.timer;

pub const FrameBuffer = union {
    bpp12: *[width][@divExact(height, 2)]Color12,
    bpp16: *[width][height]Color16,
    bpp24: *[width][height]Color24,
};
pub const Bpp = std.meta.FieldEnum(FrameBuffer);
pub const Color12 = extern struct {
    b0_g0: packed struct(u8) { b0: u4, g0: u4 },
    r0_b1: packed struct(u8) { r0: u4, b1: u4 },
    g1_r1: packed struct(u8) { g1: u4, r1: u4 },
};

pub const Color16 = packed struct(u16) { b: u5, g: u6, r: u5 };
pub const Color24 = extern struct { b: u8, g: u8, r: u8 };
pub const Rect = struct { x: u8, y: u8, width: u8, height: u8 };

pub const width = 160;
pub const height = 128;

pub const black16: Color16 = .{ .r = 0x00, .g = 0x00, .b = 0x00 };
pub const red16: Color16 = .{ .r = 0x1f, .g = 0x00, .b = 0x00 };
pub const green16: Color16 = .{ .r = 0x00, .g = 0x3f, .b = 0x00 };
pub const blue16: Color16 = .{ .r = 0x00, .g = 0x00, .b = 0x1f };
pub const white16: Color16 = .{ .r = 0x1f, .g = 0x3f, .b = 0x1f };

pub const black24: Color24 = .{ .r = 0x00, .g = 0x00, .b = 0x00 };
pub const red24: Color24 = .{ .r = 0xff, .g = 0x00, .b = 0x00 };
pub const green24: Color24 = .{ .r = 0x00, .g = 0xff, .b = 0x00 };
pub const blue24: Color24 = .{ .r = 0x00, .g = 0x00, .b = 0xff };
pub const white24: Color24 = .{ .r = 0xff, .g = 0xff, .b = 0xff };

pub const Lcd = struct {
    spi: sercom.spi.Master,
    pins: Pins,
    inverted: bool = false,
    bpp: Bpp,
    fb: FrameBuffer,

    pub const Pins = struct {
        rst: port.Pin,
        lite: port.Pin,
        dc: port.Pin,
        cs: port.Pin,
        sck: port.Pin,
        mosi: port.Pin,
    };

    pub const InitOptions = struct {
        spi: sercom.spi.Master,
        pins: Pins,
        bpp: Bpp,
        fb: FrameBuffer,
    };

    pub fn init(opts: InitOptions) Lcd {
        // initialize pins
        const lcd = Lcd{
            .spi = opts.spi,
            .pins = opts.pins,
            .fb = opts.fb,
        };

        // TODO: I think this has to be initialized before init atm
        lcd.pins.rst.set_dir(.out);
        lcd.pins.lite.set_dir(.out);
        lcd.pins.dc.set_dir(.out);
        lcd.pins.cs.set_dir(.out);
        lcd.pins.sck.set_dir(.out);
        lcd.pins.mosi.set_dir(.out);

        lcd.pins.cs.write(.high);
        lcd.pins.dc.write(.high);

        lcd.pins.lite.write(.high);
        lcd.pins.rst.write(.low);
        timer.delay_us(20 * std.time.us_per_ms);
        lcd.pins.rst.write(.high);
        timer.delay_us(20 * std.time.us_per_ms);

        // TODO: analyze this from the circuitpython repo:
        // uint8_t display_init_sequence[] = {
        //     0x01, 0 | DELAY, 150, // SWRESET
        //     0x11, 0 | DELAY, 255, // SLPOUT
        //     0xb1, 3, 0x01, 0x2C, 0x2D, // _FRMCTR1
        //     0xb2, 3, 0x01, 0x2C, 0x2D, //
        //     0xb3, 6, 0x01, 0x2C, 0x2D, 0x01, 0x2C, 0x2D,
        //     0xb4, 1, 0x07, // _INVCTR line inversion
        //     0xc0, 3, 0xa2, 0x02, 0x84, // _PWCTR1 GVDD = 4.7V, 1.0uA
        //     0xc1, 1, 0xc5, // _PWCTR2 VGH=14.7V, VGL=-7.35V
        //     0xc2, 2, 0x0a, 0x00, // _PWCTR3 Opamp current small, Boost frequency
        //     0xc3, 2, 0x8a, 0x2a,
        //     0xc4, 2, 0x8a, 0xee,
        //     0xc5, 1, 0x0e, // _VMCTR1 VCOMH = 4V, VOML = -1.1V
        //     0x2a, 0, // _INVOFF
        //     0x36, 1, 0b10100000,  // _MADCTL for rotation 0
        //     // 1 clk cycle nonoverlap, 2 cycle gate rise, 3 cycle osc equalie,
        //     // fix on VTL
        //     0x3a, 1, 0x05, // COLMOD - 16bit color
        //     0xe0, 16, 0x02, 0x1c, 0x07, 0x12, // _GMCTRP1 Gamma
        //     0x37, 0x32, 0x29, 0x2d,
        //     0x29, 0x25, 0x2B, 0x39,
        //     0x00, 0x01, 0x03, 0x10,
        //     0xe1, 16, 0x03, 0x1d, 0x07, 0x06, // _GMCTRN1
        //     0x2E, 0x2C, 0x29, 0x2D,
        //     0x2E, 0x2E, 0x37, 0x3F,
        //     0x00, 0x00, 0x02, 0x10,
        //     0x2a, 3, 0x02, 0x00, 0x81, // _CASET XSTART = 2, XEND = 129
        //     0x2b, 3, 0x02, 0x00, 0x81, // _RASET XSTART = 2, XEND = 129
        //     0x13, 0 | DELAY, 10, // _NORON
        //     0x29, 0 | DELAY, 100, // _DISPON

        lcd.send_cmd(ST7735.SWRESET, &.{}, 120 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.SLPOUT, &.{}, 120 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.INVOFF, &.{}, 1);
        lcd.send_cmd(ST7735.COLMOD, &.{@intFromEnum(@as(ST7735.COLMOD_PARAM0, switch (opts.fb) {
            .bpp12 => .@"12BPP",
            .bpp16 => .@"16BPP",
            .bpp24 => .@"24BPP",
        }))}, 1);
        lcd.send_cmd(ST7735.GMCTRP1, &.{
            0x02, 0x1c, 0x07, 0x12,
            0x37, 0x32, 0x29, 0x2d,
            0x29, 0x25, 0x2B, 0x39,
            0x00, 0x01, 0x03, 0x10,
        }, 1);
        lcd.send_cmd(ST7735.NORON, &.{}, 10 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.DISPON, &.{}, 10 * std.time.us_per_ms);
        //lcd.send_cmd(ST7735.RAMWR, &.{}, 1);

        //if (dma.enable) {
        //    Port.TFT_CS.write(.low);
        //    timer.delay(1);
        //    dma.init_lcd(bpp);
        //}
        //
        lcd.send_cmd(ST7735.MADCTL, &.{@as(u8, @bitCast(ST7735.MADCTL_PARAM0{
            .MH = .LEFT_TO_RIGHT,
            .RGB = .BGR,
            .ML = .TOP_TO_BOTTOM,
            .MV = false,
            .MX = false,
            .MY = true,
        }))}, 1);

        const frmctr1: u32 = 0; // TODO: get this value
        lcd.send_cmd(ST7735.FRMCTR1, &.{
            @truncate(frmctr1 >> 16),
            @truncate(frmctr1 >> 8),
            @truncate(frmctr1),
        }, 0);

        const x = 0;
        const y = 0;
        const w = 0;
        const h = 0;
        lcd.send_cmd(ST7735.RASET, &.{ 0, x, 0, (x + w - 1) }, 0);
        lcd.send_cmd(ST7735.CASET, &.{ 0, y, 0, (y + h - 1) }, 0);

        @memset(lcd.fb, 0);

        return lcd;
    }

    fn send_cmd(lcd: Lcd, cmd: u8, params: []const u8, delay_us: u32) void {
        lcd.pins.cs.write(.low);
        lcd.pins.dc.write(.low);

        lcd.spi.write_blocking(cmd);

        lcd.pins.dc.write(.high);

        if (params.len > 0)
            lcd.spi.write_all_blocking(params);

        lcd.pins.cs.write(.high);

        timer.delay_us(delay_us);
    }

    pub fn invert(lcd: *Lcd) void {
        lcd.stop();
        defer lcd.start();

        lcd.inverted = !lcd.inverted;
        lcd.send_cmd(switch (lcd.inverted) {
            false => ST7735.INVOFF,
            true => ST7735.INVON,
        }, &.{}, 1);
    }

    pub fn send_color(lcd: Lcd, color: Color16, count: u32) void {
        timer.delay_us(1);
        lcd.pins.cs.write(.low);
        lcd.pins.dc.write(.low);
        timer.delay_us(1);
        lcd.spi.write_blocking(ST7735.RAMWR);
        timer.delay_us(1);
        lcd.pins.dc.write(.high);
        for (0..count) |_| {
            const raw: u16 = @bitCast(color);
            lcd.spi.write_blocking(@truncate(raw >> 8));
            lcd.spi.write_blocking(@truncate(raw));
        }

        timer.delay_us(1);
        lcd.pins.cs.write(.high);
        timer.delay_us(1);
    }

    pub fn send_colors(lcd: Lcd, colors: []const Color16) void {
        timer.delay_us(1);
        lcd.pins.cs.write(.low);
        lcd.pins.dc.write(.low);
        timer.delay_us(1);
        lcd.spi.write_blocking(ST7735.RAMWR);
        timer.delay_us(1);
        lcd.pins.dc.write(.high);
        for (colors) |color| {
            const raw: u16 = @bitCast(color);
            lcd.spi.write_blocking(@truncate(raw >> 8));
            lcd.spi.write_blocking(@truncate(raw));
        }

        timer.delay_us(1);
        lcd.pins.cs.write(.high);
        timer.delay_us(1);
    }

    pub fn clear_screen(lcd: Lcd, color: Color16) void {
        lcd.set_window(0, 0, 128, 160);
        lcd.send_color(color, 128 * 160);
    }

    pub fn set_window(lcd: Lcd, x0: u8, y0: u8, x1: u8, y1: u8) void {
        lcd.send_cmd(ST7735.CASET, &.{ 0x00, x0, 0x00, x1 }, 1);
        lcd.send_cmd(ST7735.RASET, &.{ 0x00, y0, 0x00, y1 }, 1);
    }

    pub fn fill16(lcd: Lcd, color: Color16) void {
        for (&lcd.fb.bpp16) |*col| @memset(col, color);
    }

    pub fn fill24(lcd: Lcd, color: Color24) void {
        for (&lcd.fb.bpp24) |*col| @memset(col, color);
    }

    pub fn rect16(lcd: Lcd, rect: Rect, fill: Color16, line: Color16) void {
        for (0..rect.height) |yo| {
            lcd.fb.bpp16[rect.x][rect.y + yo] = line;
        }
        for (0..rect.width) |xo| {
            lcd.fb.bpp16[rect.x + xo][rect.y] = line;
            @memset(lcd.fb.bpp16[rect.x + xo][rect.y + 1 .. rect.y + rect.height - 1], fill);
            lcd.fb.bpp16[rect.x + xo][rect.y + rect.height - 1] = line;
        }
        for (0..rect.height) |yo| {
            lcd.fb.bpp16[rect.x + rect.width - 1][rect.y + yo] = line;
        }
    }

    pub fn rect24(lcd: Lcd, rect: Rect, fill: Color24, line: Color24) void {
        for (0..rect.height) |yo| {
            lcd.fb.bpp24[rect.x][rect.y + yo] = line;
        }
        for (1..rect.width - 1) |xo| {
            lcd.fb.bpp24[rect.x + xo][rect.y] = line;
            @memset(lcd.fb.bpp24[rect.x + xo][rect.y + 1 .. rect.y + rect.height - 1], fill);
            lcd.fb.bpp24[rect.x + xo][rect.y + rect.height - 1] = line;
        }
        for (0..rect.height) |yo| {
            lcd.fb.bpp24[rect.x + rect.width - 1][rect.y + yo] = line;
        }
    }

    pub fn blit12(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&lcd.fb.bpp12), 1);
    }

    pub fn blit16(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&lcd.bpp16), 1);
    }

    pub fn blit24(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&lcd.bpp24), 1);
    }

    fn start(lcd: Lcd) void {
        _ = lcd;
        //if (dma.enable) {
        //    send_cmd(ST7735.RAMWR, &.{}, 1);
        //    Port.TFT_CS.write(.low);
        //    timer.delay(1);
        //    dma.start_lcd();
        //}
    }

    fn stop(lcd: Lcd) void {
        _ = lcd;
        //if (dma.enable) {
        //    dma.stop_lcd();
        //    timer.delay(1);
        //    Port.TFT_CS.write(.high);
        //    timer.delay(1);
        //}
    }
};

const ST7735 = struct {
    const NOP = 0x00;
    const SWRESET = 0x01;
    const RDDID = 0x04;
    const RDDST = 0x09;

    const SLPIN = 0x10;
    const SLPOUT = 0x11;
    const PTLON = 0x12;
    const NORON = 0x13;

    const INVOFF = 0x20;
    const INVON = 0x21;
    const DISPOFF = 0x28;
    const DISPON = 0x29;
    const CASET = 0x2A;
    const RASET = 0x2B;
    const RAMWR = 0x2C;
    const RAMRD = 0x2E;

    const PTLAR = 0x30;
    const COLMOD = 0x3A;
    const COLMOD_PARAM0 = enum(u8) {
        @"12BPP" = 0b011,
        @"16BPP" = 0b101,
        @"24BPP" = 0b110,
    };
    const MADCTL = 0x36;
    const MADCTL_PARAM0 = packed struct(u8) {
        reserved: u2 = 0,
        MH: enum(u1) {
            LEFT_TO_RIGHT = 0,
            RIGHT_TO_LEFT = 1,
        },
        RGB: enum(u1) {
            RGB = 0,
            BGR = 1,
        },
        ML: enum(u1) {
            TOP_TO_BOTTOM = 0,
            BOTTOM_TO_TOP = 1,
        },
        MV: bool,
        MX: bool,
        MY: bool,
    };

    const FRMCTR1 = 0xB1;
    const FRMCTR2 = 0xB2;
    const FRMCTR3 = 0xB3;
    const INVCTR = 0xB4;
    const DISSET5 = 0xB6;

    const PWCTR1 = 0xC0;
    const PWCTR2 = 0xC1;
    const PWCTR3 = 0xC2;
    const PWCTR4 = 0xC3;
    const PWCTR5 = 0xC4;
    const VMCTR1 = 0xC5;

    const RDID1 = 0xDA;
    const RDID2 = 0xDB;
    const RDID3 = 0xDC;
    const RDID4 = 0xDD;

    const PWCTR6 = 0xFC;

    const GMCTRP1 = 0xE0;
    const GMCTRN1 = 0xE1;
};
