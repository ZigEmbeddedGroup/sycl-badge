pub const FrameBuffer = extern union {
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

pub fn init(bpp: Bpp, fb: *const volatile FrameBuffer) void {
    @branchHint(.cold);

    board.TFT_RST.set_dir(.out);
    board.TFT_LITE.set_dir(.out);
    board.TFT_DC.set_dir(.out);
    board.TFT_CS.set_dir(.out);
    board.TFT_SCK.set_dir(.out);
    board.TFT_MOSI.set_dir(.out);

    board.TFT_CS.write(.high);
    board.TFT_DC.write(.high);
    board.TFT_SCK.write(.high);
    board.TFT_MOSI.write(.high);

    board.TFT_LITE.write(.high);
    board.TFT_RST.write(.low);
    timer.delay_us(20 * std.time.ms_per_s);
    board.TFT_RST.write(.high);
    timer.delay_us(20 * std.time.ms_per_s);

    SERCOM4.SPIM.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = @enumFromInt(0),
        .reserved7 = 0,
        .RUNSTDBY = 0,
        .IBON = 0,
        .reserved16 = 0,
        .DOPO = @enumFromInt(0),
        .reserved20 = 0,
        .DIPO = @enumFromInt(0),
        .reserved24 = 0,
        .FORM = @enumFromInt(0),
        .CPHA = @enumFromInt(0),
        .CPOL = @enumFromInt(0),
        .DORD = @enumFromInt(0),
        .padding = 0,
    });
    while (SERCOM4.SPIM.SYNCBUSY.read().SWRST != 0) {}
    board.TFT_SCK.set_mux(.C);
    board.TFT_MOSI.set_mux(.C);
    SERCOM4.SPIM.BAUD.write(.{ .BAUD = 3 });
    SERCOM4.SPIM.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .SPI_MASTER,
        .reserved7 = 0,
        .RUNSTDBY = 0,
        .IBON = 0,
        .reserved16 = 0,
        .DOPO = .PAD2,
        .reserved20 = 0,
        .DIPO = .PAD0,
        .reserved24 = 0,
        .FORM = .SPI_FRAME,
        .CPHA = .LEADING_EDGE,
        .CPOL = .IDLE_LOW,
        .DORD = .MSB,
        .padding = 0,
    });
    while (SERCOM4.SPIM.SYNCBUSY.read().ENABLE != 0) {}

    send_cmd(ST7735.SWRESET, &.{}, 120 * std.time.us_per_ms);
    send_cmd(ST7735.SLPOUT, &.{}, 120 * std.time.us_per_ms);
    send_cmd(ST7735.INVOFF, &.{}, 1);
    send_cmd(ST7735.COLMOD, &.{@intFromEnum(@as(ST7735.COLMOD_PARAM0, switch (bpp) {
        .bpp12 => .@"12BPP",
        .bpp16 => .@"16BPP",
        .bpp24 => .@"24BPP",
    }))}, 1);
    var ca: [4]u8 = undefined;
    std.mem.writeInt(u16, ca[0..2], 0, .big);
    std.mem.writeInt(u16, ca[2..4], height - 1, .big);
    send_cmd(ST7735.CASET, &ca, 1);
    var ra: [4]u8 = undefined;
    std.mem.writeInt(u16, ra[0..2], 0, .big);
    std.mem.writeInt(u16, ra[2..4], width - 1, .big);
    send_cmd(ST7735.RASET, &ra, 1);
    send_cmd(ST7735.MADCTL, &.{@bitCast(ST7735.MADCTL_PARAM0{
        .MH = .LEFT_TO_RIGHT,
        .RGB = .RGB,
        .ML = .TOP_TO_BOTTOM,
        .MV = false,
        .MX = false,
        .MY = true,
    })}, 1);
    send_cmd(ST7735.FRMCTR1, &.{ 15, 24, 24 }, 1);
    send_cmd(ST7735.GMCTRP1, &.{
        0x02, 0x1c, 0x07, 0x12,
        0x37, 0x32, 0x29, 0x2d,
        0x29, 0x25, 0x2B, 0x39,
        0x00, 0x01, 0x03, 0x10,
    }, 1);
    send_cmd(ST7735.NORON, &.{}, 10 * std.time.us_per_ms);
    send_cmd(ST7735.DISPON, &.{}, 10 * std.time.us_per_ms);
    send_cmd(ST7735.RAMWR, &.{}, 1);

    board.TFT_CS.write(.low);
    timer.delay_us(1);
    dma.init_lcd(bpp, fb);
}

fn send_cmd(cmd: u8, params: []const u8, delay_us: u32) void {
    timer.delay_us(1);
    board.TFT_CS.write(.low);
    board.TFT_DC.write(.low);
    timer.delay_us(1);
    SERCOM4.SPIM.DATA.write(.{ .DATA = cmd });
    while (SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay_us(1);
    board.TFT_DC.write(.high);
    for (params) |param| {
        while (SERCOM4.SPIM.INTFLAG.read().DRE == 0) {}
        SERCOM4.SPIM.DATA.write(.{ .DATA = param });
    }
    while (SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay_us(1);
    board.TFT_CS.write(.high);
    timer.delay_us(delay_us);
}

var inverted = false;
pub fn invert() void {
    stop();
    inverted = !inverted;
    send_cmd(switch (inverted) {
        false => ST7735.INVOFF,
        true => ST7735.INVON,
    }, &.{}, 1);
    start();
}

fn start() void {
    send_cmd(ST7735.RAMWR, &.{}, 1);
    board.TFT_CS.write(.low);
    timer.delay_us(1);
    dma.start_lcd();
}

fn stop() void {
    dma.stop_lcd();
    timer.delay_us(1);
    board.TFT_CS.write(.high);
    timer.delay_us(1);
}

pub fn vsync() void {
    dma.poll_ack_lcd();
}

pub fn update() void {
    dma.resume_lcd();
}

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

const board = @import("../board.zig");
const dma = @import("dma.zig");
const microzig = @import("microzig");
const hal = microzig.hal;
const timer = hal.timer;
const clocks = hal.clocks;
const chip = microzig.chip;
const std = @import("std");
const SERCOM4 = chip.peripherals.SERCOM4;
const NVIC = chip.peripherals.NVIC;
