const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const mclk = hal.clocks.mclk;
const gclk = hal.clocks.gclk;

const peripherals = microzig.chip.peripherals;
const TC0 = peripherals.TC0;
const TC1 = peripherals.TC1;
const MCLK = peripherals.MCLK;

pub fn init() void {
    TC0.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = @enumFromInt(0),
        .PRESCSYNC = @enumFromInt(0),
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = @enumFromInt(0),
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = @enumFromInt(0),
        .reserved27 = 0,
        .CAPTMODE1 = @enumFromInt(0),
        .padding = 0,
    });
    while (TC0.COUNT32.SYNCBUSY.read().ENABLE != 0) {}
    TC1.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = @enumFromInt(0),
        .PRESCSYNC = @enumFromInt(0),
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = @enumFromInt(0),
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = @enumFromInt(0),
        .reserved27 = 0,
        .CAPTMODE1 = @enumFromInt(0),
        .padding = 0,
    });
    while (TC1.COUNT32.SYNCBUSY.read().ENABLE != 0) {}

    TC0.COUNT32.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = @enumFromInt(0),
        .PRESCSYNC = @enumFromInt(0),
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = @enumFromInt(0),
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = @enumFromInt(0),
        .reserved27 = 0,
        .CAPTMODE1 = @enumFromInt(0),
        .padding = 0,
    });
    while (TC0.COUNT32.SYNCBUSY.read().SWRST != 0) {}
    TC1.COUNT32.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = @enumFromInt(0),
        .PRESCSYNC = @enumFromInt(0),
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = @enumFromInt(0),
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = @enumFromInt(0),
        .reserved27 = 0,
        .CAPTMODE1 = @enumFromInt(0),
        .padding = 0,
    });
    while (TC1.COUNT32.SYNCBUSY.read().SWRST != 0) {}

    TC0.COUNT32.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .COUNT32,
        .PRESCSYNC = .GCLK,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .DIV1,
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = @enumFromInt(0),
        .reserved27 = 0,
        .CAPTMODE1 = @enumFromInt(0),
        .padding = 0,
    });
    while (TC0.COUNT32.SYNCBUSY.read().ENABLE != 0) {}
    TC0.COUNT32.CTRLBSET.write(.{
        .DIR = 1,
        .LUPD = 0,
        .ONESHOT = 1,
        .reserved5 = 0,
        .CMD = .STOP,
    });
    while (TC0.COUNT32.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn start_delay_us(us: u32) void {
    TC0.COUNT32.COUNT.write(.{ .COUNT = us });
    while (TC0.COUNT32.SYNCBUSY.read().COUNT != 0) {}
    TC0.COUNT32.CTRLBSET.write(.{
        .DIR = 1,
        .LUPD = 0,
        .ONESHOT = 1,
        .reserved5 = 0,
        .CMD = .RETRIGGER,
    });
    while (TC0.COUNT32.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn finish_delay() void {
    while (TC0.COUNT32.STATUS.read().STOP != 1) {}
}

pub fn delay_us(us: u32) void {
    start_delay_us(us);
    finish_delay();
}
