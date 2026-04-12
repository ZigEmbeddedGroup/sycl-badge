pub fn init_lcd(bpp: lcd.Bpp, fb: *const volatile lcd.FrameBuffer) void {
    @branchHint(.cold);

    init();
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(0),
        .reserved20 = 0,
        .TRIGACT = @enumFromInt(0),
        .reserved24 = 0,
        .BURSTLEN = @enumFromInt(0),
        .THRESHOLD = @enumFromInt(0),
        .padding = 0,
    });
    while (DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 0) {}
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(0),
        .reserved20 = 0,
        .TRIGACT = @enumFromInt(0),
        .reserved24 = 0,
        .BURSTLEN = @enumFromInt(0),
        .THRESHOLD = @enumFromInt(0),
        .padding = 0,
    });
    while (DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().SWRST != 0) {}
    desc[DESC.LCD].BTCTRL.write(.{
        .VALID = 1,
        .EVOSEL = .DISABLE,
        .BLOCKACT = .BOTH,
        .reserved8 = 0,
        .BEATSIZE = .BYTE,
        .SRCINC = 1,
        .DSTINC = 0,
        .STEPSEL = .SRC,
        .STEPSIZE = .X1,
    });

    switch (bpp) {
        inline else => |tag| {
            const field_info = std.meta.fieldInfo(lcd.Bpp, tag);
            const len = @sizeOf(@FieldType(lcd.FrameBuffer, field_info.name));
            desc[DESC.LCD].BTCNT.write(.{ .BTCNT = @divExact(len, 1) });
            desc[DESC.LCD].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&@field(fb, @tagName(tag))) + len });
        },
    }

    desc[DESC.LCD].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&SERCOM4.SPIM.DATA) });
    desc[DESC.LCD].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.LCD]) });
    microzig.cpu.dmb();
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(TRIGSRC.SERCOM4_TX),
        .reserved20 = 0,
        .TRIGACT = .BURST,
        .reserved24 = 0,
        .BURSTLEN = .SINGLE,
        .THRESHOLD = .@"1BEAT",
        .padding = 0,
    });
}

pub fn start_lcd() void {
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.modify(.{ .ENABLE = 1 });
    while (DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 1) {}
}

pub fn stop_lcd() void {
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.modify(.{ .ENABLE = 0 });
    while (DMAC.CHANNEL[CHANNEL.LCD].CHCTRLA.read().ENABLE != 0) {}
}

pub fn poll_ack_lcd() void {
    while (DMAC.CHANNEL[CHANNEL.LCD].CHINTFLAG.read().TCMPL == 0) {}
    DMAC.CHANNEL[CHANNEL.LCD].CHINTFLAG.write(.{
        .TERR = 0,
        .TCMPL = 1,
        .SUSP = 0,
        .padding = 0,
    });
}

pub fn resume_lcd() void {
    DMAC.CHANNEL[CHANNEL.LCD].CHCTRLB.write(.{
        .CMD = .RESUME,
        .padding = 0,
    });
}

pub fn init_audio() void {
    init();
    DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(0),
        .reserved20 = 0,
        .TRIGACT = @enumFromInt(0),
        .reserved24 = 0,
        .BURSTLEN = @enumFromInt(0),
        .THRESHOLD = @enumFromInt(0),
        .padding = 0,
    });
    while (DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().ENABLE != 0) {}
    DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(0),
        .reserved20 = 0,
        .TRIGACT = @enumFromInt(0),
        .reserved24 = 0,
        .BURSTLEN = @enumFromInt(0),
        .THRESHOLD = @enumFromInt(0),
        .padding = 0,
    });
    while (DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().SWRST != 0) {}
    DMAC.CHANNEL[CHANNEL.AUDIO].CHINTENSET.write(.{
        .TERR = 0,
        .TCMPL = 1,
        .SUSP = 0,
        .padding = 0,
    });
    const len0 = @sizeOf(@TypeOf(audio.sample_buffer[0]));
    desc[DESC.AUDIO0].BTCTRL.write(.{
        .VALID = 1,
        .EVOSEL = .DISABLE,
        .BLOCKACT = .INT,
        .reserved8 = 0,
        .BEATSIZE = .HWORD,
        .SRCINC = 1,
        .DSTINC = 0,
        .STEPSEL = .SRC,
        .STEPSIZE = .X1,
    });
    desc[DESC.AUDIO0].BTCNT.write(.{ .BTCNT = @divExact(len0, 2) });
    desc[DESC.AUDIO0].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[0]) + len0 });
    desc[DESC.AUDIO0].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&DAC.DATABUF[0]) });
    desc[DESC.AUDIO0].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO1]) });
    const len1 = @sizeOf(@TypeOf(audio.sample_buffer[1]));
    desc[DESC.AUDIO1].BTCTRL.write(.{
        .VALID = 1,
        .EVOSEL = .DISABLE,
        .BLOCKACT = .INT,
        .reserved8 = 0,
        .BEATSIZE = .HWORD,
        .SRCINC = 1,
        .DSTINC = 0,
        .STEPSEL = .SRC,
        .STEPSIZE = .X1,
    });
    desc[DESC.AUDIO1].BTCNT.write(.{ .BTCNT = @divExact(len1, 2) });
    desc[DESC.AUDIO1].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[1]) + len1 });
    desc[DESC.AUDIO1].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&DAC.DATABUF[0]) });
    desc[DESC.AUDIO1].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO0]) });
    microzig.cpu.dmb();
    DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .reserved8 = 0,
        .TRIGSRC = @enumFromInt(TRIGSRC.DAC_EMPTY0),
        .reserved20 = 0,
        .TRIGACT = .BURST,
        .reserved24 = 0,
        .BURSTLEN = .SINGLE,
        .THRESHOLD = .@"1BEAT",
        .padding = 0,
    });
}

pub fn get_audio_part() usize {
    return (desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR - @intFromPtr(audio.sample_buffer) - 1) /
        @sizeOf(@TypeOf(audio.sample_buffer[0]));
}

pub fn ack_audio() void {
    DMAC.CHANNEL[CHANNEL.AUDIO].CHINTFLAG.write(.{
        .TERR = 0,
        .TCMPL = 1,
        .SUSP = 0,
        .padding = 0,
    });
}

pub fn wait_audio(i: usize) void {
    while (@intFromBool(desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR > @intFromPtr(&audio.buffer[1])) == i) {}
}

fn init() void {
    if (initialized) return;
    DMAC.CTRL.write(.{
        .SWRST = 0,
        .DMAENABLE = 0,
        .reserved8 = 0,
        .LVLEN0 = 0,
        .LVLEN1 = 0,
        .LVLEN2 = 0,
        .LVLEN3 = 0,
        .padding = 0,
    });
    while (DMAC.CTRL.read().DMAENABLE != 0) {}
    DMAC.CRCSTATUS.write(.{
        .CRCBUSY = 1,
        .CRCZERO = 0,
        .CRCERR = 0,
        .padding = 0,
    });
    while (DMAC.CRCSTATUS.read().CRCBUSY != 0) {}
    DMAC.CTRL.write(.{
        .SWRST = 1,
        .DMAENABLE = 0,
        .reserved8 = 0,
        .LVLEN0 = 0,
        .LVLEN1 = 0,
        .LVLEN2 = 0,
        .LVLEN3 = 0,
        .padding = 0,
    });
    while (DMAC.CTRL.read().SWRST != 0) {}
    DMAC.BASEADDR.write(.{ .BASEADDR = @intFromPtr(&desc) });
    DMAC.WRBADDR.write(.{ .WRBADDR = @intFromPtr(&desc_wb) });
    DMAC.CTRL.write(.{
        .SWRST = 0,
        .DMAENABLE = 1,
        .reserved8 = 0,
        .LVLEN0 = 1,
        .LVLEN1 = 0,
        .LVLEN2 = 0,
        .LVLEN3 = 0,
        .padding = 0,
    });
    while (DMAC.CTRL.read().DMAENABLE == 0) {}
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
var desc = std.mem.zeroes([3]DMAC_DESCRIPTOR);

var desc_wb: [2]DMAC_DESCRIPTOR align(8) = undefined;

const std = @import("std");
const audio = @import("audio.zig");
const DMAC = chip.peripherals.DMAC;
const DMAC_DESCRIPTOR = chip.types.peripherals.DMAC.DMAC_DESCRIPTOR;
const DAC = chip.peripherals.DAC;
const microzig = @import("microzig");
const chip = microzig.chip;
const lcd = @import("lcd.zig");
const SERCOM4 = chip.peripherals.SERCOM4;
