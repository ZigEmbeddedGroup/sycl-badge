pub const sample_buffer: *volatile [2][512]u16 = &sample_buffer_storage;

pub const Channel = struct {
    duty: u32,
    phase: u32,
    phase_step: u31,
    phase_step_step: i32,

    duration: u31,
    attack_duration: u31,
    decay_duration: u31,
    sustain_duration: u31,
    release_duration: u31,

    volume: u31,
    volume_step: i32,
    peak_volume: u31,
    sustain_volume: u31,
    attack_volume_step: i32,
    decay_volume_step: i32,
    release_volume_step: i32,
};

pub fn init() void {
    @branchHint(.cold);

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
        .REFSEL = .VREFPU,
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
        .CCTRL = .CC12M,
        .reserved5 = 0,
        .FEXT = 0,
        .RUNSTDBY = 0,
        .DITHER = 1,
        .REFRESH = .REFRESH_0,
        .reserved13 = 0,
        .OSR = .OSR_1,
    });
    DAC.CTRLA.write(.{ .SWRST = 0, .ENABLE = 1, .padding = 0 });
    while (DAC.SYNCBUSY.read().ENABLE != 0) {}

    TC5.COUNT8.CTRLA.write(.{
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
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}

    //clocks.gclk.set_peripheral_clk_gen(.GCLK_TC4_TC5, .GCLK3);
    TC5.COUNT8.CTRLA.write(.{
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
    while (TC5.COUNT8.SYNCBUSY.read().SWRST != 0) {}
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .COUNT8,
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
    TC5.COUNT8.EVCTRL.write(.{
        .EVACT = @enumFromInt(0),
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
        .MODE = .COUNT8,
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
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}
    TC5.COUNT8.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .RETRIGGER,
    });
    while (TC5.COUNT8.SYNCBUSY.read().CTRLB != 0) {}

    for (&EVSYS.CHANNEL) |*channel| channel.CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.NONE,
        .reserved8 = 0,
        .PATH = @enumFromInt(0),
        .EDGSEL = @enumFromInt(0),
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    EVSYS.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    EVSYS.CHANNEL[evsys.CHANNEL.AUDIO].CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.TC5_OVF,
        .reserved8 = 0,
        .PATH = .ASYNCHRONOUS,
        .EDGSEL = .NO_EVT_OUTPUT,
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

pub fn mix() callconv(.c) void {
    var local_channels = channels.*;
    var speaker_enable: port.Level = .low;
    for (&sample_buffer[
        (dma.get_audio_part() + sample_buffer.len - 1) % sample_buffer.len
    ]) |*out_sample| {
        var sample: i32 = 0;
        inline for (&local_channels) |*channel| {
            if (channel.duty > 0) {
                // generate sample;
                if (channel.phase < channel.duty) {
                    sample += channel.volume;
                } else {
                    sample -= channel.volume;
                }
                // update
                channel.phase +%= channel.phase_step;
                channel.phase_step = @intCast(channel.phase_step + channel.phase_step_step);
                if (channel.duration > 0) {
                    channel.duration -= 1;
                    channel.volume = @intCast(channel.volume + channel.volume_step);
                } else if (channel.attack_duration > 0) {
                    channel.duration = channel.attack_duration;
                    channel.attack_duration = 0;
                    channel.volume = 0;
                    channel.volume_step = channel.attack_volume_step;
                } else if (channel.decay_duration > 0) {
                    channel.duration = channel.decay_duration;
                    channel.decay_duration = 0;
                    channel.volume = channel.peak_volume;
                    channel.volume_step = channel.decay_volume_step;
                } else if (channel.sustain_duration > 0) {
                    channel.duration = channel.sustain_duration;
                    channel.sustain_duration = 0;
                    channel.volume = channel.sustain_volume;
                    channel.volume_step = 0;
                } else if (channel.release_duration > 0) {
                    channel.duration = channel.release_duration;
                    channel.release_duration = 0;
                    channel.volume = channel.sustain_volume;
                    channel.volume_step = channel.release_volume_step;
                } else {
                    channel.duty = 0;
                }
            }
        }
        if (sample != 0) speaker_enable = .high;
        out_sample.* = @intCast((sample >> 16) - std.math.minInt(i16));
    }
    channels.* = local_channels;
    board.SPKR_EN.write(speaker_enable);
    dma.ack_audio();
}

pub fn set_channel(channel: usize, state: Channel) void {
    NVIC.ICER[32 / 32].write(.{ .CLRENA = 1 << 32 % 32 });
    channels[channel] = state;
    NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

var channels_storage: [4]Channel = .{Channel{
    .duty = 0,
    .phase = 0,
    .phase_step = 0,
    .phase_step_step = 0,

    .duration = 0,
    .attack_duration = 0,
    .decay_duration = 0,
    .sustain_duration = 0,
    .release_duration = 0,

    .volume = 0,
    .volume_step = 0,
    .peak_volume = 0,
    .sustain_volume = 0,
    .attack_volume_step = 0,
    .decay_volume_step = 0,
    .release_volume_step = 0,
}} ** 4;
const channels: *volatile [4]Channel = &channels_storage;

var sample_buffer_storage: [2][512]u16 = .{.{0} ** 512} ** 2;

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
