pub fn init() void {
    @setCold(true);

    io.MCLK.APBAMASK.modify(.{ .TC0_ = 1, .TC1_ = 1 });
    io.TC0.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC0.COUNT32.SYNCBUSY.read().ENABLE != 0) {}
    io.TC1.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC1.COUNT32.SYNCBUSY.read().ENABLE != 0) {}
    io.GCLK.PCHCTRL[GCLK.PCH.TC0].write(.{
        .GEN = .{ .value = GCLK.GEN.@"1MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.TC0.COUNT32.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC0.COUNT32.SYNCBUSY.read().SWRST != 0) {}
    io.GCLK.PCHCTRL[GCLK.PCH.TC1].write(.{
        .GEN = .{ .value = GCLK.GEN.@"1MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.TC1.COUNT32.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC1.COUNT32.SYNCBUSY.read().SWRST != 0) {}
    io.TC0.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .COUNT32 },
        .PRESCSYNC = .{ .value = .GCLK },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV1 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC0.COUNT32.SYNCBUSY.read().ENABLE != 0) {}
    io.TC0.COUNT32.CTRLBSET.write(.{
        .DIR = 1,
        .LUPD = 0,
        .ONESHOT = 1,
        .reserved5 = 0,
        .CMD = .{ .value = .STOP },
    });
    while (io.TC0.COUNT32.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn start_delay(us: u32) void {
    io.TC0.COUNT32.COUNT.write(.{ .COUNT = us });
    while (io.TC0.COUNT32.SYNCBUSY.read().COUNT != 0) {}
    io.TC0.COUNT32.CTRLBSET.write(.{
        .DIR = 1,
        .LUPD = 0,
        .ONESHOT = 1,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (io.TC0.COUNT32.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn finish_delay() void {
    while (io.TC0.COUNT32.STATUS.read().STOP != 1) {}
}

pub fn delay(us: u32) void {
    start_delay(us);
    finish_delay();
}

pub fn init_frame_sync() void {
    io.MCLK.APBCMASK.modify(.{ .TC4_ = 1 });
    io.TC4.COUNT16.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC4.COUNT16.SYNCBUSY.read().ENABLE != 0) {}
    io.GCLK.PCHCTRL[GCLK.PCH.TC4].write(.{
        .GEN = .{ .value = GCLK.GEN.@"8.4672MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.TC4.COUNT16.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC4.COUNT16.SYNCBUSY.read().SWRST != 0) {}
    io.TC4.COUNT16.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .value = .COUNT16 },
        .PRESCSYNC = .{ .value = .PRESC },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV64 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    io.TC4.COUNT16.WAVE.write(.{ .WAVEGEN = .{ .value = .MFRQ }, .padding = 0 });
    io.TC4.COUNT16.CC[0].write(.{ .CC = @divExact(8_467_200, 64 * 60) - 1 });
    while (io.TC4.COUNT16.SYNCBUSY.read().CC0 != 0) {}
    io.TC4.COUNT16.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .COUNT16 },
        .PRESCSYNC = .{ .value = .PRESC },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV64 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (io.TC4.COUNT16.SYNCBUSY.read().ENABLE != 0) {}
    io.TC4.COUNT16.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (io.TC4.COUNT16.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn check_frame_ready() bool {
    if (io.TC4.COUNT16.INTFLAG.read().OVF != 1) return false;
    io.TC4.COUNT16.INTFLAG.write(.{
        .OVF = 1,
        .ERR = 0,
        .reserved4 = 0,
        .MC0 = 0,
        .MC1 = 0,
        .padding = 0,
    });
    return true;
}

const GCLK = @import("chip.zig").GCLK;
const io = microzig.chip.peripherals;
const microzig = @import("microzig");
