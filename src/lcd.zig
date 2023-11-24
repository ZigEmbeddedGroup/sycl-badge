pub var fb: FrameBuffer = .{ .bpp24 = .{.{.{ .r = 0, .g = 0, .b = 0 }} ** height} ** width };
var dst: u32 = 0x55555555;

const FrameBuffer = union {
    bpp12: [width][@divExact(height, 2)]Color12,
    bpp16: [width][height]Color16,
    bpp24: [width][height]Color24,
};
pub const Bpp = std.meta.FieldEnum(FrameBuffer);
pub const Color12 = extern struct {
    r0_g0: packed struct(u8) { r0: u4, g0: u4 },
    b0_r1: packed struct(u8) { b0: u4, r1: u4 },
    g1_b1: packed struct(u8) { g1: u4, b1: u4 },
};
pub const Color16 = packed struct(u16) { r: u5, g: u6, b: u5 };
pub const Color24 = extern struct { r: u8, g: u8, b: u8 };
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
    Port.TFT_RST.setDir(.out);
    Port.TFT_LITE.setDir(.out);
    Port.TFT_DC.setDir(.out);
    Port.TFT_CS.setDir(.out);
    Port.TFT_SCK.setDir(.out);
    Port.TFT_MOSI.setDir(.out);

    Port.TFT_CS.write(true);
    Port.TFT_DC.write(true);
    Port.TFT_SCK.write(true);
    Port.TFT_MOSI.write(true);

    Port.TFT_LITE.write(true);
    Port.TFT_RST.write(false);
    timer.delay(20 * std.time.ms_per_s);
    Port.TFT_RST.write(true);
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
        .RGB = .RGB,
        .ML = .TOP_TO_BOTTOM,
        .MV = false,
        .MX = false,
        .MY = false,
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
        Port.TFT_CS.write(false);
        timer.delay(1);
        dma.init(bpp);
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
    Port.TFT_CS.write(false);
    Port.TFT_DC.write(false);
    timer.delay(1);
    io.SERCOM4.SPIM.DATA.write(.{ .DATA = cmd });
    while (io.SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay(1);
    Port.TFT_DC.write(true);
    for (params) |param| {
        while (io.SERCOM4.SPIM.INTFLAG.read().DRE == 0) {}
        io.SERCOM4.SPIM.DATA.write(.{ .DATA = param });
    }
    while (io.SERCOM4.SPIM.INTFLAG.read().TXC == 0) {}
    timer.delay(1);
    Port.TFT_CS.write(true);
    timer.delay(delay_us);
}

fn start() void {
    if (dma.enable) {
        sendCmd(ST7735.RAMWR, &.{}, 1);
        Port.TFT_CS.write(false);
        timer.delay(1);
        dma.start();
    }
}

fn stop() void {
    if (dma.enable) {
        dma.stop();
        timer.delay(1);
        Port.TFT_CS.write(true);
        timer.delay(1);
    }
}

pub const dma = struct {
    const enable = true;

    const TRIGSRC = enum(u7) {
        const DISABLE = 0x00;
        const RTC_TIMESTAMP = 0x01;
        const DSU_DCC0 = 0x02;
        const DSU_DCC1 = 0x03;
        const SERCOM0_RX = 0x04;
        const SERCOM0_TX = 0x05;
        const SERCOM1_RX = 0x06;
        const SERCOM1_TX = 0x07;
        const SERCOM2_RX = 0x08;
        const SERCOM2_TX = 0x09;
        const SERCOM3_RX = 0x0A;
        const SERCOM3_TX = 0x0B;
        const SERCOM4_RX = 0x0C;
        const SERCOM4_TX = 0x0D;
        const SERCOM5_RX = 0x0E;
        const SERCOM5_TX = 0x0F;
        const SERCOM6_RX = 0x10;
        const SERCOM6_TX = 0x11;
        const SERCOM7_RX = 0x12;
        const SERCOM7_TX = 0x13;
        const CAN0_DEBUG = 0x14;
        const CAN1_DEBUG = 0x15;
        const TCC0_OVF = 0x16;
        const TCC0_MC0 = 0x17;
        const TCC0_MC1 = 0x18;
        const TCC0_MC2 = 0x19;
        const TCC0_MC3 = 0x1A;
        const TCC0_MC4 = 0x1B;
        const TCC0_MC5 = 0x1C;
        const TCC1_OVF = 0x1D;
        const TCC1_MC0 = 0x1E;
        const TCC1_MC1 = 0x1F;
        const TCC1_MC2 = 0x20;
        const TCC1_MC3 = 0x21;
        const TCC2_OVF = 0x22;
        const TCC2_MC0 = 0x23;
        const TCC2_MC1 = 0x24;
        const TCC2_MC2 = 0x25;
        const TCC3_OVF = 0x26;
        const TCC3_MC0 = 0x27;
        const TCC3_MC1 = 0x28;
        const TCC4_OVF = 0x29;
        const TCC4_MC0 = 0x2A;
        const TCC4_MC1 = 0x2B;
        const TC0_OVF = 0x2C;
        const TC0_MC0 = 0x2D;
        const TC0_MC1 = 0x2E;
        const TC1_OVF = 0x2F;
        const TC1_MC0 = 0x30;
        const TC1_MC1 = 0x31;
        const TC2_OVF = 0x32;
        const TC2_MC0 = 0x33;
        const TC2_MC1 = 0x34;
        const TC3_OVF = 0x35;
        const TC3_MC0 = 0x36;
        const TC3_MC1 = 0x37;
        const TC4_OVF = 0x38;
        const TC4_MC0 = 0x39;
        const TC4_MC1 = 0x3A;
        const TC5_OVF = 0x3B;
        const TC5_MC0 = 0x3C;
        const TC5_MC1 = 0x3D;
        const TC6_OVF = 0x3E;
        const TC6_MC0 = 0x3F;
        const TC6_MC1 = 0x40;
        const TC7_OVF = 0x41;
        const TC7_MC0 = 0x42;
        const TC7_MC1 = 0x43;
        const ADC0_RESRDY = 0x44;
        const ADC0_SEQ = 0x45;
        const ADC1_RESRDY = 0x46;
        const ADC1_SEQ = 0x47;
        const DAC_EMPTY0 = 0x48;
        const DAC_EMPTY1 = 0x49;
        const DAC_RESRDY0 = 0x4A;
        const DAC_RESRDY1 = 0x4B;
        const I2S_RX0 = 0x4C;
        const IS2_RX1 = 0x4D;
        const I2S_TX0 = 0x4E;
        const IS2_TX1 = 0x4F;
        const PCC_RX = 0x50;
        const AES_WR = 0x51;
        const AES_RD = 0x52;
        const QSPI_RX = 0x53;
        const QSPI_TX = 0x54;
    };

    var desc: [1]io_types.DMAC.DMAC_DESCRIPTOR align(8) = .{.{
        .BTCTRL = .{ .raw = 0 },
        .BTCNT = .{ .raw = 0 },
        .SRCADDR = .{ .raw = 0 },
        .DSTADDR = .{ .raw = 0 },
        .DESCADDR = .{ .raw = 0 },
    }} ** 1;
    var desc_wb: [1]io_types.DMAC.DMAC_DESCRIPTOR align(8) = undefined;

    fn init(bpp: Bpp) void {
        io.MCLK.AHBMASK.modify(.{ .DMAC_ = 1 });
        io.DMAC.CTRL.write(.{
            .SWRST = 0,
            .DMAENABLE = 0,
            .reserved8 = 0,
            .LVLEN0 = 0,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (io.DMAC.CTRL.read().DMAENABLE != 0) {}
        io.DMAC.CRCSTATUS.write(.{
            .CRCBUSY = 1,
            .CRCZERO = 0,
            .CRCERR = 0,
            .padding = 0,
        });
        while (io.DMAC.CRCSTATUS.read().CRCBUSY != 0) {}
        io.DMAC.CTRL.write(.{
            .SWRST = 1,
            .DMAENABLE = 0,
            .reserved8 = 0,
            .LVLEN0 = 0,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (io.DMAC.CTRL.read().SWRST != 0) {}
        io.DMAC.BASEADDR.write(.{ .BASEADDR = @intFromPtr(&desc) });
        io.DMAC.WRBADDR.write(.{ .WRBADDR = @intFromPtr(&desc_wb) });
        io.DMAC.CTRL.write(.{
            .SWRST = 0,
            .DMAENABLE = 1,
            .reserved8 = 0,
            .LVLEN0 = 1,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (io.DMAC.CTRL.read().DMAENABLE == 0) {}
        io.DMAC.CHANNEL[0].CHCTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = 0 },
            .reserved20 = 0,
            .TRIGACT = .{ .raw = 0 },
            .reserved24 = 0,
            .BURSTLEN = .{ .raw = 0 },
            .THRESHOLD = .{ .raw = 0 },
            .padding = 0,
        });
        while (io.DMAC.CHANNEL[0].CHCTRLA.read().ENABLE != 0) {}
        io.DMAC.CHANNEL[0].CHCTRLA.write(.{
            .SWRST = 1,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = 0 },
            .reserved20 = 0,
            .TRIGACT = .{ .raw = 0 },
            .reserved24 = 0,
            .BURSTLEN = .{ .raw = 0 },
            .THRESHOLD = .{ .raw = 0 },
            .padding = 0,
        });
        while (io.DMAC.CHANNEL[0].CHCTRLA.read().SWRST != 0) {}
        desc[0].BTCTRL.write(.{
            .VALID = 1,
            .EVOSEL = .{ .value = .DISABLE },
            .BLOCKACT = .{ .value = .NOACT },
            .reserved8 = 0,
            .BEATSIZE = .{ .value = .BYTE },
            .SRCINC = 1,
            .DSTINC = 0,
            .STEPSEL = .{ .value = .SRC },
            .STEPSIZE = .{ .value = .X1 },
        });
        switch (bpp) {
            inline else => |tag| {
                const len = @sizeOf(std.meta.FieldType(FrameBuffer, tag));
                desc[0].BTCNT.write(.{ .BTCNT = len });
                desc[0].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&@field(fb, @tagName(tag))) + len });
            },
        }
        desc[0].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&io.SERCOM4.SPIM.DATA) });
        desc[0].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[0]) });
        microzig.cpu.dmb();
        io.DMAC.CHANNEL[0].CHCTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 1,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = TRIGSRC.SERCOM4_TX },
            .reserved20 = 0,
            .TRIGACT = .{ .value = .BURST },
            .reserved24 = 0,
            .BURSTLEN = .{ .value = .SINGLE },
            .THRESHOLD = .{ .value = .@"1BEAT" },
            .padding = 0,
        });
    }

    fn start() void {
        io.DMAC.CHANNEL[0].CHCTRLA.modify(.{ .ENABLE = 1 });
        while (io.DMAC.CHANNEL[0].CHCTRLA.read().ENABLE != 1) {}
    }

    fn stop() void {
        io.DMAC.CHANNEL[0].CHCTRLA.modify(.{ .ENABLE = 0 });
        while (io.DMAC.CHANNEL[0].CHCTRLA.read().ENABLE != 0) {}
    }
};

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

const GCLK = @import("chip.zig").GCLK;
const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const microzig = @import("microzig");
const Port = @import("Port.zig");
const std = @import("std");
const timer = @import("timer.zig");
