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

pub fn init(bpp: Bpp) void {
    @setCold(true);

    Port.TFT_RST.setDir(.out);
    Port.TFT_LITE.setDir(.out);
    Port.TFT_DC.setDir(.out);
    Port.TFT_CS.setDir(.out);
    Port.TFT_SCK.setDir(.out);
    Port.TFT_MOSI.setDir(.out);

    Port.TFT_CS.write(.high);
    Port.TFT_DC.write(.high);
    Port.TFT_SCK.write(.high);
    Port.TFT_MOSI.write(.high);

    Port.TFT_LITE.write(.high);
    Port.TFT_RST.write(.low);
    timer.delay(20 * std.time.ms_per_s);
    Port.TFT_RST.write(.high);
    timer.delay(20 * std.time.ms_per_s);

    io.MCLK.APBDMASK.modify(.{ .SERCOM4_ = 1 });
    io.SERCOM4.SPIM.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .reserved7 = 0,
        .RUNSTDBY = 0,
        .IBON = 0,
        .reserved16 = 0,
        .DOPO = .{ .raw = 0 },
        .reserved20 = 0,
        .DIPO = .{ .raw = 0 },
        .reserved24 = 0,
        .FORM = .{ .raw = 0 },
        .CPHA = .{ .raw = 0 },
        .CPOL = .{ .raw = 0 },
        .DORD = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.SERCOM4.SPIM.SYNCBUSY.read().SWRST != 0) {}
    Port.TFT_SCK.setMux(.C);
    Port.TFT_MOSI.setMux(.C);
    io.GCLK.PCHCTRL[GCLK.PCH.SERCOM4_CORE].write(.{
        .GEN = .{ .value = GCLK.GEN.@"120MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.SERCOM4.SPIM.BAUD.write(.{ .BAUD = 3 });
    io.SERCOM4.SPIM.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .SPI_MASTER },
        .reserved7 = 0,
        .RUNSTDBY = 0,
        .IBON = 0,
        .reserved16 = 0,
        .DOPO = .{ .value = .PAD2 },
        .reserved20 = 0,
        .DIPO = .{ .value = .PAD0 },
        .reserved24 = 0,
        .FORM = .{ .value = .SPI_FRAME },
        .CPHA = .{ .value = .LEADING_EDGE },
        .CPOL = .{ .value = .IDLE_LOW },
        .DORD = .{ .value = .MSB },
        .padding = 0,
    });
    while (io.SERCOM4.SPIM.SYNCBUSY.read().ENABLE != 0) {}

    sendCmd(ST7735.SWRESET, &.{}, 120 * std.time.us_per_ms);
    sendCmd(ST7735.SLPOUT, &.{}, 120 * std.time.us_per_ms);
    sendCmd(ST7735.INVOFF, &.{}, 1);
    sendCmd(ST7735.COLMOD, &.{@intFromEnum(@as(ST7735.COLMOD_PARAM0, switch (bpp) {
        .bpp12 => .@"12BPP",
        .bpp16 => .@"16BPP",
        .bpp24 => .@"24BPP",
    }))}, 1);
    sendCmd(ST7735.MADCTL, &.{@as(u8, @bitCast(ST7735.MADCTL_PARAM0{
        .MH = .LEFT_TO_RIGHT,
        .RGB = .BGR,
        .ML = .TOP_TO_BOTTOM,
        .MV = false,
        .MX = false,
        .MY = true,
    }))}, 1);
    sendCmd(ST7735.GMCTRP1, &.{
        0x02, 0x1c, 0x07, 0x12,
        0x37, 0x32, 0x29, 0x2d,
        0x29, 0x25, 0x2B, 0x39,
        0x00, 0x01, 0x03, 0x10,
    }, 1);
    sendCmd(ST7735.NORON, &.{}, 10 * std.time.us_per_ms);
    sendCmd(ST7735.DISPON, &.{}, 10 * std.time.us_per_ms);
    sendCmd(ST7735.RAMWR, &.{}, 1);

    if (dma.enable) {
        Port.TFT_CS.write(.low);
        timer.delay(1);
        dma.initLcd(bpp);
    }
}

pub fn invert() void {
    stop();
    inverted = !inverted;
    sendCmd(switch (inverted) {
        false => ST7735.INVOFF,
        true => ST7735.INVON,
    }, &.{}, 1);
    start();
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

pub fn blit12() void {
    if (!dma.enable) sendCmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp12), 1);
}

pub fn blit16() void {
    if (!dma.enable) sendCmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp16), 1);
}

pub fn blit24() void {
    if (!dma.enable) sendCmd(ST7735.RAMWR, std.mem.asBytes(&fb.bpp24), 1);
}

fn sendCmd(cmd: u8, params: []const u8, delay_us: u32) void {
    timer.delay(1);
    Port.TFT_CS.write(.low);
    Port.TFT_DC.write(.low);
    timer.delay(1);
    io.SERCOM4.SPIM.DATA.write(.{ .DATA = cmd });
    while (io.SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay(1);
    Port.TFT_DC.write(.high);
    for (params) |param| {
        while (io.SERCOM4.SPIM.INTFLAG.read().DRE == 0) {}
        io.SERCOM4.SPIM.DATA.write(.{ .DATA = param });
    }
    while (io.SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay(1);
    Port.TFT_CS.write(.high);
    timer.delay(delay_us);
}

fn start() void {
    if (dma.enable) {
        sendCmd(ST7735.RAMWR, &.{}, 1);
        Port.TFT_CS.write(.low);
        timer.delay(1);
        dma.startLcd();
    }
}

fn stop() void {
    if (dma.enable) {
        dma.stopLcd();
        timer.delay(1);
        Port.TFT_CS.write(.high);
        timer.delay(1);
    }
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

const dma = @import("dma.zig");
const GCLK = @import("chip.zig").GCLK;
const io = microzig.chip.peripherals;
const microzig = @import("microzig");
const Port = @import("Port.zig");
const std = @import("std");
const timer = @import("timer.zig");
