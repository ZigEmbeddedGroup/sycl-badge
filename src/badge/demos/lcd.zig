const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const mclk = hal.mclk;
const gclk = hal.gclk;
const sercom = hal.sercom;
const port = hal.port;
const timer = hal.timer;

const board = microzig.board;
const tft_rst_pin = board.TFT_RST;
const tft_lite_pin = board.TFT_LITE;
const tft_dc_pin = board.TFT_DC;
const tft_cs_pin = board.TFT_CS;
const tft_sck_pin = board.TFT_SCK;
const tft_mosi_pin = board.TFT_MOSI;

pub var fb: FrameBuffer = .{ .bpp24 = .{.{.{ .r = 0, .g = 0, .b = 0 }} ** height} ** width };

pub const FrameBuffer = union {
    bpp12: [width][@divExact(height, 2)]Color12,
    bpp16: [width][height]Color16,
    bpp24: [width][height]Color24,
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

const Lcd = struct {
    spi: sercom.spi.Master,
    pins: Pins,

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
    };

    pub fn init(opts: InitOptions) Lcd {
        // initialize pins
        const lcd = Lcd{
            .spi = opts.spi,
            .pins = opts.pins,
        };

        // TODO: I think this has to be initialized before init atm
        //lcd.pins.rst.set_dir(.out);
        //lcd.pins.lite.set_dir(.out);
        //lcd.pins.dc.set_dir(.out);
        //lcd.pins.cs.set_dir(.out);
        //lcd.pins.sck.set_dir(.out);
        //lcd.pins.mosi.set_dir(.out);

        lcd.pins.cs.write(.high);
        lcd.pins.dc.write(.high);
        lcd.pins.sck.write(.high);
        lcd.pins.mosi.write(.high);

        lcd.pins.lite.write(.high);
        lcd.pins.rst.write(.low);
        timer.delay_us(20 * std.time.us_per_ms);
        lcd.pins.rst.write(.high);
        timer.delay_us(20 * std.time.us_per_ms);

        lcd.send_cmd(ST7735.SWRESET, &.{}, 120 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.SLPOUT, &.{}, 120 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.INVOFF, &.{}, 1);
        lcd.send_cmd(ST7735.COLMOD, &.{@intFromEnum(@as(ST7735.COLMOD_PARAM0, switch (opts.bpp) {
            .bpp12 => .@"12BPP",
            .bpp16 => .@"16BPP",
            .bpp24 => .@"24BPP",
        }))}, 1);
        lcd.send_cmd(ST7735.MADCTL, &.{@as(u8, @bitCast(ST7735.MADCTL_PARAM0{
            .MH = .LEFT_TO_RIGHT,
            .RGB = .BGR,
            .ML = .TOP_TO_BOTTOM,
            .MV = false,
            .MX = false,
            .MY = true,
        }))}, 1);
        lcd.send_cmd(ST7735.GMCTRP1, &.{
            0x02, 0x1c, 0x07, 0x12,
            0x37, 0x32, 0x29, 0x2d,
            0x29, 0x25, 0x2B, 0x39,
            0x00, 0x01, 0x03, 0x10,
        }, 1);
        lcd.send_cmd(ST7735.NORON, &.{}, 10 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.DISPON, &.{}, 10 * std.time.us_per_ms);
        lcd.send_cmd(ST7735.RAMWR, &.{}, 1);

        //if (dma.enable) {
        //    Port.TFT_CS.write(.low);
        //    timer.delay(1);
        //    dma.init_lcd(bpp);
        //}

        return lcd;
    }

    fn send_cmd(lcd: Lcd, cmd: u8, params: []const u8, delay_us: u32) void {
        timer.delay_us(1);
        lcd.pins.cs.write(.low);
        lcd.pins.dc.write(.low);
        timer.delay_us(1);
        lcd.spi.write_blocking(cmd);
        timer.delay_us(1);
        lcd.pins.dc.write(.high);
        lcd.spi.write_all_blocking(params);
        timer.delay_us(1);
        lcd.pins.cs.write(.high);
        timer.delay_us(delay_us);
    }

    pub fn invert(lcd: Lcd) void {
        lcd.stop();
        defer lcd.start();

        inverted = !inverted;
        lcd.send_cmd(switch (inverted) {
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

    pub fn clear_screen(lcd: Lcd, color: Color16) void {
        lcd.set_window(0, 0, 128, 160);
        lcd.send_color(color, 128 * 160);
    }

    pub fn set_window(lcd: Lcd, x0: u8, y0: u8, x1: u8, y1: u8) void {
        lcd.send_cmd(ST7735.CASET, &.{ 0x00, x0, 0x00, x1 }, 1);
        lcd.send_cmd(ST7735.RASET, &.{ 0x00, y0, 0x00, y1 }, 1);
    }

    pub fn fill16(color: Color16) void {
        for (&fb.bpp16) |*col| @memset(col, color);
    }

    pub fn fill24(color: Color24) void {
        for (&fb.bpp24) |*col| @memset(col, color);
    }

    pub fn rect16(rect: Rect, fill: Color16, line: Color16) void {
        for (0..rect.height) |yo| {
            fb.bpp16[rect.x][rect.y + yo] = line;
        }
        for (0..rect.width) |xo| {
            fb.bpp16[rect.x + xo][rect.y] = line;
            @memset(fb.bpp16[rect.x + xo][rect.y + 1 .. rect.y + rect.height - 1], fill);
            fb.bpp16[rect.x + xo][rect.y + rect.height - 1] = line;
        }
        for (0..rect.height) |yo| {
            fb.bpp16[rect.x + rect.width - 1][rect.y + yo] = line;
        }
    }

    pub fn rect24(rect: Rect, fill: Color24, line: Color24) void {
        for (0..rect.height) |yo| {
            fb.bpp24[rect.x][rect.y + yo] = line;
        }
        for (1..rect.width - 1) |xo| {
            fb.bpp24[rect.x + xo][rect.y] = line;
            @memset(fb.bpp24[rect.x + xo][rect.y + 1 .. rect.y + rect.height - 1], fill);
            fb.bpp24[rect.x + xo][rect.y + rect.height - 1] = line;
        }
        for (0..rect.height) |yo| {
            fb.bpp24[rect.x + rect.width - 1][rect.y + yo] = line;
        }
    }

    pub fn blit12(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp12), 1);
    }

    pub fn blit16(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp16), 1);
    }

    pub fn blit24(lcd: Lcd) void {
        //if (!dma.enable)
        lcd.send_cmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp24), 1);
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

pub fn main() !void {
    tft_rst_pin.set_dir(.out);
    tft_lite_pin.set_dir(.out);
    tft_dc_pin.set_dir(.out);
    tft_cs_pin.set_dir(.out);
    tft_sck_pin.set_dir(.out);
    tft_mosi_pin.set_dir(.out);

    tft_sck_pin.set_mux(.C);
    tft_mosi_pin.set_mux(.C);

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK0);

    // TODO: pin and clock configuration
    mclk.set_apb_mask(.{
        .SERCOM4 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
    });

    timer.init();
    const lcd = Lcd.init(.{
        .spi = sercom.spi.Master.init(.SERCOM4, .{
            .cpha = .LEADING_EDGE,
            .cpol = .IDLE_LOW,
            .dord = .MSB,
            .dopo = .PAD2,
            .ref_freq_hz = 48_000_000,
            .baud_freq_hz = 4_000_000,
        }),
        .pins = .{
            .rst = tft_rst_pin,
            .lite = tft_lite_pin,
            .dc = tft_dc_pin,
            .cs = tft_cs_pin,
            .sck = tft_sck_pin,
            .mosi = tft_mosi_pin,
        },
        .bpp = .bpp16,
    });

    lcd.clear_screen(red16);
    lcd.set_window(0, 0, 10, 10);

    //Lcd.fill16(red16);
    timer.delay_us(5 * std.time.us_per_s);
    lcd.invert();
    while (true) {}
}

var inverted = false;

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
