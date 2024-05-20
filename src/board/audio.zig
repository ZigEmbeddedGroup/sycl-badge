pub const sample_buffer: *volatile [2][512]i16 = @ptrFromInt(0x20000000 + 0xa020);
var call_audio: ?*const fn () void = null;

pub fn init(call_audio_fn: *const fn () void) void {
    @setCold(true);
    call_audio = call_audio_fn;

    board.A0_SPKR.set_dir(.out);
    board.A1_VCC.set_dir(.in);
    board.SPKR_EN.set_dir(.out);
    board.SPKR_EN.write(.low);

    clocks.gclk.set_peripheral_clk_gen(.GCLK_DAC, .GCLK3);
    DAC.CTRLA.write(.{ .SWRST = 1, .ENABLE = 0, .padding = 0 });
    while (DAC.SYNCBUSY.read().SWRST != 0) {}
    board.A0_SPKR.set_mux(.B);
    board.A1_VCC.set_mux(.B);
    DAC.CTRLB.write(.{
        .DIFF = 0,
        .REFSEL = .{ .value = .VREFPU },
        .padding = 0,
    });
    DAC.EVCTRL.write(.{
        .STARTEI0 = 1,
        .STARTEI1 = 0,
        .EMPTYEO0 = 0,
        .EMPTYEO1 = 0,
        .INVEI0 = 0,
        .INVEI1 = 0,
        .RESRDYEO0 = 0,
        .RESRDYEO1 = 0,
    });
    DAC.DACCTRL[0].write(.{
        .LEFTADJ = 0,
        .ENABLE = 1,
        .CCTRL = .{ .value = .CC12M },
        .reserved5 = 0,
        .FEXT = 0,
        .RUNSTDBY = 0,
        .DITHER = 1,
        .REFRESH = .{ .value = .REFRESH_0 },
        .reserved13 = 0,
        .OSR = .{ .value = .OSR_1 },
    });
    DAC.CTRLA.write(.{ .SWRST = 0, .ENABLE = 1, .padding = 0 });
    while (DAC.SYNCBUSY.read().ENABLE != 0) {}

    TC5.COUNT8.CTRLA.write(.{
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
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}

    //clocks.gclk.set_peripheral_clk_gen(.GCLK_TC4_TC5, .GCLK3);
    TC5.COUNT8.CTRLA.write(.{
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
    while (TC5.COUNT8.SYNCBUSY.read().SWRST != 0) {}
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .value = .COUNT8 },
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
    TC5.COUNT8.EVCTRL.write(.{
        .EVACT = .{ .raw = 0 },
        .reserved4 = 0,
        .TCINV = 0,
        .TCEI = 0,
        .reserved8 = 0,
        .OVFEO = 1,
        .reserved12 = 0,
        .MCEO0 = 0,
        .MCEO1 = 0,
        .padding = 0,
    });
    TC5.COUNT8.PER.write(.{ .PER = 12 - 1 });
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .COUNT8 },
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
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}
    TC5.COUNT8.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (TC5.COUNT8.SYNCBUSY.read().CTRLB != 0) {}

    for (&EVSYS.CHANNEL) |*channel| channel.CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.NONE,
        .reserved8 = 0,
        .PATH = .{ .raw = 0 },
        .EDGSEL = .{ .raw = 0 },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    EVSYS.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    EVSYS.CHANNEL[evsys.CHANNEL.AUDIO].CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.TC5_OVF,
        .reserved8 = 0,
        .PATH = .{ .value = .ASYNCHRONOUS },
        .EDGSEL = .{ .value = .NO_EVT_OUTPUT },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    EVSYS.USER[evsys.USER.DAC_START0].write(.{ .CHANNEL = evsys.CHANNEL.AUDIO + 1, .padding = 0 });

    dma.init_audio();
    while (DAC.STATUS.read().READY0 != 1) {}
    NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

pub fn mix() callconv(.C) void {
    // var speaker_enable: port.Level = .low;
    const speaker_enable: port.Level = .low;

    // if (call_audio) |ca| ca();

    // for (&sample_buffer[
    //     (dma.get_audio_part() + sample_buffer.len - 1) % sample_buffer.len
    // ]) |sample| {
    //     if (sample != 0) speaker_enable = .high;
    // }

    board.SPKR_EN.write(speaker_enable);
    dma.ack_audio();
}

const board = @import("../board.zig");
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const port = hal.port;
const clocks = hal.clocks;
const chip = microzig.chip;
const DAC = chip.peripherals.DAC;
const TC5 = chip.peripherals.TC5;
const NVIC = chip.peripherals.NVIC;
const EVSYS = chip.peripherals.EVSYS;
const dma = @import("dma.zig");
const evsys = @import("evsys.zig");
