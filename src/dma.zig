pub const enable = true;

pub fn initLcd(bpp: lcd.Bpp) void {
    @setCold(true);

    init();
    io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
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
    while (io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 0) {}
    io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
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
    while (io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().SWRST != 0) {}
    desc[DESC.LCD].BTCTRL.write(.{
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
            const len = @sizeOf(std.meta.FieldType(lcd.FrameBuffer, tag));
            desc[DESC.LCD].BTCNT.write(.{ .BTCNT = len });
            desc[DESC.LCD].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&@field(lcd.fb, @tagName(tag))) + len });
        },
    }
    desc[DESC.LCD].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&io.SERCOM4.SPIM.DATA) });
    desc[DESC.LCD].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.LCD]) });
    microzig.cpu.dmb();
    io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
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

pub fn startLcd() void {
    io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.modify(.{ .ENABLE = 1 });
    while (io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 1) {}
}

pub fn stopLcd() void {
    io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.modify(.{ .ENABLE = 0 });
    while (io.DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 0) {}
}

pub fn initAudio() void {
    @setCold(true);

    init();
    io.DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
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
    while (io.DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().ENABLE != 0) {}
    io.DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
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
    while (io.DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().SWRST != 0) {}
    io.DMAC.CHANNEL[CHANNEL.AUDIO].CHINTENSET.write(.{
        .TERR = 0,
        .TCMPL = 1,
        .SUSP = 0,
        .padding = 0,
    });
    const len0 = @sizeOf(@TypeOf(audio.sample_buffer[0]));
    desc[DESC.AUDIO0].BTCTRL.write(.{
        .VALID = 1,
        .EVOSEL = .{ .value = .DISABLE },
        .BLOCKACT = .{ .value = .INT },
        .reserved8 = 0,
        .BEATSIZE = .{ .value = .HWORD },
        .SRCINC = 1,
        .DSTINC = 0,
        .STEPSEL = .{ .value = .SRC },
        .STEPSIZE = .{ .value = .X1 },
    });
    desc[DESC.AUDIO0].BTCNT.write(.{ .BTCNT = @divExact(len0, 2) });
    desc[DESC.AUDIO0].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[0]) + len0 });
    desc[DESC.AUDIO0].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&io.DAC.DATABUF[0]) });
    desc[DESC.AUDIO0].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO1]) });
    const len1 = @sizeOf(@TypeOf(audio.sample_buffer[1]));
    desc[DESC.AUDIO1].BTCTRL.write(.{
        .VALID = 1,
        .EVOSEL = .{ .value = .DISABLE },
        .BLOCKACT = .{ .value = .INT },
        .reserved8 = 0,
        .BEATSIZE = .{ .value = .HWORD },
        .SRCINC = 1,
        .DSTINC = 0,
        .STEPSEL = .{ .value = .SRC },
        .STEPSIZE = .{ .value = .X1 },
    });
    desc[DESC.AUDIO1].BTCNT.write(.{ .BTCNT = @divExact(len1, 2) });
    desc[DESC.AUDIO1].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[1]) + len1 });
    desc[DESC.AUDIO1].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&io.DAC.DATABUF[0]) });
    desc[DESC.AUDIO1].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO0]) });
    microzig.cpu.dmb();
    io.DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = .{ .raw = TRIGSRC.DAC_EMPTY0 },
        .reserved20 = 0,
        .TRIGACT = .{ .value = .BURST },
        .reserved24 = 0,
        .BURSTLEN = .{ .value = .SINGLE },
        .THRESHOLD = .{ .value = .@"1BEAT" },
        .padding = 0,
    });
}

pub fn getAudioPart() usize {
    return (desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR - @intFromPtr(audio.sample_buffer) - 1) /
        @sizeOf(@TypeOf(audio.sample_buffer[0]));
}

pub fn ackAudio() void {
    io.DMAC.CHANNEL[CHANNEL.AUDIO].CHINTFLAG.write(.{
        .TERR = 0,
        .TCMPL = 1,
        .SUSP = 0,
        .padding = 0,
    });
}

pub fn waitAudio(i: usize) void {
    while (@intFromBool(desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR > @intFromPtr(&audio.buffer[1])) == i) {}
}

fn init() void {
    @setCold(true);

    if (initialized) return;
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
    initialized = true;
}

const CHANNEL = struct {
    const LCD = 0;
    const AUDIO = 1;
};

const DESC = struct {
    const LCD = 0;
    const AUDIO0 = 1;
    const AUDIO1 = 2;
};

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

var initialized = false;
var desc: [3]io_types.DMAC.DMAC_DESCRIPTOR align(8) = .{.{
    .BTCTRL = .{ .raw = 0 },
    .BTCNT = .{ .raw = 0 },
    .SRCADDR = .{ .raw = 0 },
    .DSTADDR = .{ .raw = 0 },
    .DESCADDR = .{ .raw = 0 },
}} ** 3;
var desc_wb: [2]io_types.DMAC.DMAC_DESCRIPTOR align(8) = undefined;

const audio = @import("audio.zig");
const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const lcd = @import("lcd.zig");
const microzig = @import("microzig");
const std = @import("std");
