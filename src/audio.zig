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
    @setCold(true);

    Port.A0.setDir(.out);
    Port.AVCC.setDir(.in);
    Port.SPKR_EN.setDir(.out);
    Port.SPKR_EN.write(.low);

    io.MCLK.APBDMASK.modify(.{ .DAC_ = 1 });
    io.GCLK.PCHCTRL[GCLK.PCH.DAC].write(.{
        .GEN = .{ .value = GCLK.GEN.@"8.4672MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.DAC.CTRLA.write(.{ .SWRST = 1, .ENABLE = 0, .padding = 0 });
    while (io.DAC.SYNCBUSY.read().SWRST != 0) {}
    Port.A0.setMux(.B);
    Port.AVCC.setMux(.B);
    io.DAC.CTRLB.write(.{ .DIFF = 0, .REFSEL = .{ .value = .VREFPU }, .padding = 0 });
    io.DAC.EVCTRL.write(.{
        .STARTEI0 = 1,
        .STARTEI1 = 0,
        .EMPTYEO0 = 0,
        .EMPTYEO1 = 0,
        .INVEI0 = 0,
        .INVEI1 = 0,
        .RESRDYEO0 = 0,
        .RESRDYEO1 = 0,
    });
    io.DAC.DACCTRL[0].write(.{
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
    io.DAC.CTRLA.write(.{ .SWRST = 0, .ENABLE = 1, .padding = 0 });
    while (io.DAC.SYNCBUSY.read().ENABLE != 0) {}

    io.MCLK.APBCMASK.modify(.{ .TC5_ = 1 });
    io.TC5.COUNT8.CTRLA.write(.{
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
    while (io.TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}
    io.GCLK.PCHCTRL[GCLK.PCH.TC5].write(.{
        .GEN = .{ .value = GCLK.GEN.@"8.4672MHz".PCHCTRL_GEN },
        .reserved6 = 0,
        .CHEN = 1,
        .WRTLOCK = 0,
        .padding = 0,
    });
    io.TC5.COUNT8.CTRLA.write(.{
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
    while (io.TC5.COUNT8.SYNCBUSY.read().SWRST != 0) {}
    io.TC5.COUNT8.CTRLA.write(.{
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
    io.TC5.COUNT8.EVCTRL.write(.{
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
    io.TC5.COUNT8.PER.write(.{ .PER = 12 - 1 });
    io.TC5.COUNT8.CTRLA.write(.{
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
    while (io.TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}
    io.TC5.COUNT8.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (io.TC5.COUNT8.SYNCBUSY.read().CTRLB != 0) {}

    io.MCLK.APBBMASK.modify(.{ .EVSYS_ = 1 });
    for (&io.EVSYS.CHANNEL) |*channel| channel.CHANNEL.write(.{
        .EVGEN = EVSYS.EVGEN.NONE,
        .reserved8 = 0,
        .PATH = .{ .raw = 0 },
        .EDGSEL = .{ .raw = 0 },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    io.EVSYS.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    io.EVSYS.CHANNEL[EVSYS.CHANNEL.AUDIO].CHANNEL.write(.{
        .EVGEN = EVSYS.EVGEN.TC5_OVF,
        .reserved8 = 0,
        .PATH = .{ .value = .ASYNCHRONOUS },
        .EDGSEL = .{ .value = .NO_EVT_OUTPUT },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    io.EVSYS.USER[EVSYS.USER.DAC_START0].write(.{ .CHANNEL = EVSYS.CHANNEL.AUDIO + 1, .padding = 0 });

    dma.initAudio();
    while (io.DAC.STATUS.read().READY0 != 1) {}
    Port.SPKR_EN.write(.high);
    io.NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

pub fn mix() void {
    var local_channels = channels.*;
    for (&sample_buffer[
        (dma.getAudioPart() + sample_buffer.len - 1) % sample_buffer.len
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
                channel.volume = @intCast(channel.volume + channel.volume_step);
                if (channel.duration > 0) {
                    channel.duration -= 1;
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
        out_sample.* = @intCast((sample >> 16) - std.math.minInt(i16));
    }
    channels.* = local_channels;
    dma.ackAudio();
}

pub fn setChannel(channel: usize, state: Channel) void {
    io.NVIC.ICER[32 / 32].write(.{ .CLRENA = 1 << 32 % 32 });
    channels[channel] = state;
    io.NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

pub fn playNote(channel: usize, note: Note) void {
    const sample_rate: f32 = 44100.0;
    setChannel(channel, .{
        .duty = 1 << 31,
        .phase = 0,
        .phase_step = @intFromFloat(0x1p32 / sample_rate * note.frequency + 0.5),
        .phase_step_step = 0,

        .duration = @intFromFloat(note.duration * sample_rate + 0.5),
        .attack_duration = 0,
        .decay_duration = 0,
        .sustain_duration = 0,
        .release_duration = 0,

        .volume = 0x8000000,
        .volume_step = 0,
        .peak_volume = 0,
        .sustain_volume = 0,
        .attack_volume_step = 0,
        .decay_volume_step = 0,
        .release_volume_step = 0,
    });
}

pub fn playSong(channels_notes: []const []const Note) void {
    var time: f32 = 0.0;
    var channels_note_index = [1]usize{0} ** channels.len;
    var channels_note_start = [1]f32{0.0} ** channels.len;
    while (true) {
        var next_time = std.math.inf(f32);
        for (
            0..,
            channels_note_index[0..channels_notes.len],
            channels_note_start[0..channels_notes.len],
            channels_notes,
        ) |channel_index, *note_index, *note_start, notes| {
            if (note_index.* > notes.len) continue;
            const next_note_time =
                note_start.* + if (note_index.* > 0) notes[note_index.* - 1].duration else 0.0;
            if (time < next_note_time) {
                next_time = @min(next_note_time, next_time);
            } else {
                note_index.* += 1;
                if (note_index.* > notes.len) continue;
                const note = notes[note_index.* - 1];
                note_start.* = next_note_time;
                playNote(channel_index, .{
                    .duration = @max(note.duration - 0.04, 0.0),
                    .frequency = note.frequency,
                });
                next_time = @min(next_note_time + note.duration, next_time);
            }
        }
        if (next_time == std.math.inf(f32)) break;
        timer.delay(@intFromFloat(std.time.us_per_s * 0.95 * (next_time - time)));
        time = next_time;
    }
}

pub fn mute() void {
    Port.SPKR_EN.write(.low);
}

pub const Note = struct {
    duration: f32,
    frequency: f32,

    pub const A5: f32 = 880.0000;
    pub const Ab5: f32 = 830.6094;
    pub const G5: f32 = 783.9909;
    pub const Gb5: f32 = 739.9888;
    pub const F5: f32 = 698.4565;
    pub const E5: f32 = 659.2551;
    pub const Eb5: f32 = 622.2540;
    pub const D5: f32 = 587.3295;
    pub const Db5: f32 = 554.3653;
    pub const C5: f32 = 523.2511;
    pub const B4: f32 = 493.8833;
    pub const Bb4: f32 = 466.1638;
    pub const A4: f32 = 440.0000;
    pub const Ab4: f32 = 415.3047;
    pub const G4: f32 = 391.9954;
    pub const Gb4: f32 = 369.9944;
    pub const F4: f32 = 349.2282;
    pub const E4: f32 = 329.6276;
    pub const Eb4: f32 = 311.1270;
    pub const D4: f32 = 293.6648;
    pub const Db4: f32 = 277.1826;
    pub const C4: f32 = 261.6256;
    pub const B3: f32 = 246.9417;
    pub const Bb3: f32 = 233.0819;
    pub const A3: f32 = 220.0000;
    pub const Ab3: f32 = 207.6523;
    pub const G3: f32 = 195.9977;
    pub const Gb3: f32 = 184.9972;
    pub const F3: f32 = 174.6141;
    pub const E3: f32 = 164.8138;
    pub const Eb3: f32 = 155.5635;
    pub const D3: f32 = 146.8324;
    pub const Db3: f32 = 138.5913;
    pub const C3: f32 = 130.8128;
    pub const B2: f32 = 123.4708;
    pub const Bb2: f32 = 116.5409;
    pub const A2: f32 = 110.0000;
};

var channels_storage: [4]Channel = .{.{
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

const dma = @import("dma.zig");
const EVSYS = @import("chip.zig").EVSYS;
const GCLK = @import("chip.zig").GCLK;
const io = microzig.chip.peripherals;
const microzig = @import("microzig");
const Port = @import("Port.zig");
const std = @import("std");
const timer = @import("timer.zig");
