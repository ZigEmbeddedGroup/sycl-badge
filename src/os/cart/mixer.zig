//! This file contains a default audio mixer which emulates the v1 (2024) audio API.
//! Apps can use this directly for simple audio, or as a reference for building a
//! more custom implementation. The API is tweaked slightly from the original, to
//! take advantage of float support on RP2350.
//!
//! For games doing complicated mixers, copying this file may be a good starting
//! point for a custom mixer.

const std = @import("std");
const cart = @import("api.zig");

const ActiveEnvelope = struct {
    mode: enum { inactive, attack, decay, sustain, release, finish_phase } = .inactive,
    curr_volume: u32 = 0,
    volume_step: i32 = 0,
    mode_samples: u32 = 0,
    attack_samples: u32 = undefined,
    decay_samples: u32 = undefined,
    sustain_samples: u32 = undefined,
    release_samples: u32 = undefined,
    peak_volume: u31 = undefined,
    sustain_volume: u31 = undefined,
    full_phase: bool = undefined,
};

fn update_envelope_mode(env: *ActiveEnvelope) void {
    set_mode: switch (env.mode) {
        .inactive => {
            if (env.attack_samples == 0) continue :set_mode .attack;
            env.curr_volume = 0;
            env.volume_step = @intCast(env.peak_volume / env.decay_samples);
            env.mode = .attack;
            env.mode_samples = env.attack_samples;
        },
        .attack => {
            if (env.decay_samples == 0) continue :set_mode .decay;
            env.curr_volume = env.peak_volume;
            env.volume_step = @divTrunc(@as(i32, env.sustain_volume) - @as(i32, env.peak_volume), @as(i32, @intCast(env.decay_samples)));
            env.mode = .decay;
            env.mode_samples = env.decay_samples;
        },
        .decay => {
            env.curr_volume = env.sustain_volume;
            if (env.sustain_samples == 0) continue :set_mode .sustain;
            env.volume_step = 0;
            env.mode = .sustain;
            env.mode_samples = env.sustain_samples;
        },
        .sustain => {
            if (env.release_samples == 0) {
                if (env.full_phase) {
                    env.mode = .finish_phase;
                    env.volume_step = 0;
                    return;
                } else {
                    continue :set_mode .release;
                }
            }
            env.volume_step = -@as(i32, @intCast(env.sustain_volume / env.release_samples));
            env.mode = .release;
            env.mode_samples = env.release_samples;
        },
        .finish_phase => {},
        .release => {
            env.mode = .inactive;
            env.curr_volume = 0;
        },
    }
}

const Freq = struct {
    phase: u32,
    delta_phase: u32,
    freq: f32,
    delta_freq: f32,

    fn calc_delta_phase(f: *Freq) void {
        // phase_per_sample = phase_per_period * periods_per_second / samples_per_second
        f.delta_phase = @intFromFloat(@as(f64, 0x1_0000_0000) * @as(f64, f.freq) / @as(f64, cart.audio_sample_rate) + 0.5);
    }
};

const Noise = struct {};

/// Duration of a tone and ADSR envelope around it.
/// The default tick length is 1/60th of a second.
/// This can be adjusted with mixer.set_audio_tick.
/// A duration with 0xFF in all fields represents
/// an infinite tone with no envelope.
pub const ToneDuration = packed struct(u32) {
    sustain_ticks: u8,
    release_ticks: u8 = 0,
    decay_ticks: u8 = 0,
    attack_ticks: u8 = 0,

    pub fn adrs(bits: u32) ToneDuration {
        std.debug.assert(bits != 0xFFFFFFFF); // this would be .forever
        return @fromBackingInt(bits);
    }

    pub fn ticks(len: u8) ToneDuration {
        return .{ .sustain_ticks = len };
    }

    pub fn seconds(sec: f32) ToneDuration {
        return .ticks(@min(255, @max(0, @as(u32, @intFromFloat(@max(0.0, sec) * 60)))));
    }

    pub const forever: ToneDuration = @fromBackingInt(0xFFFFFFFF);
};

pub const ToneFrequency = extern union {
    midi_sweep: packed struct(u32) {
        start_note: u8,
        start_bend: u8,
        end_note: u8,
        end_bend: u8,
    },
    freq_sweep: packed struct(u32) {
        start_hz: u16,
        end_hz: u16,
    },
    bits: u32,

    pub fn midi(note: u8) ToneFrequency {
        return .{ .bits = note };
    }
    pub fn midi_bend(note: u8, bend: u8) ToneFrequency {
        return .{ .bits = @as(u32, bend) << 8 | note };
    }
    pub fn hz(value: u16) ToneFrequency {
        return .{ .bits = value };
    }
};

fn freq_from_midi_bits(midi: u8, bend: u8) f32 {
    const midi_note = @as(f32, @floatFromInt(@as(u32, midi) << 8 | bend)) / 256.0;
    return freq_from_midi(midi_note);
}

/// Converts from a midi note to hz (can be non-integer for pitch bends)
pub fn freq_from_midi(midi: f32) f32 {
    return @exp2(midi - 69.0) * 440.0;
}

pub const ToneOptions = struct {
    pub const Flags = packed struct(u32) {
        pub const Channel = enum(u2) {
            pulse1,
            pulse2,
            triangle,
            noise,
        };

        pub const DutyCycle = enum(u2) {
            @"1/8",
            @"1/4",
            @"1/2",
            @"3/4",
        };

        pub const Panning = enum(u2) {
            stereo,
            left,
            right,
        };

        /// The channel to play the sound on
        channel: Channel,
        /// `duty_cycle` is only used when `channel` is set to `pulse1` or `pulse2`
        duty_cycle: DutyCycle = .@"1/2",
        /// Unused, there is only one audio channel on the device
        panning: Panning = .stereo,
        /// If true, frequency is parsed as 0xEB_EN_SB_SN, with
        /// SN = start midi note, SB = 1/256th of midi note pitch up,
        /// EN = end midi note, EB = 1/256th of midi note pitch up.
        /// If EB_EN is 0x00_00, SB_SN is used for the entire note.
        /// If false, frequency is parsed as 0xEEEE_SSSS, with
        /// SSSS is the start frequency, EEEE is the end frequency.
        /// If EEEE is 0x0000, SSSS is used for the entire note.
        midi_freq: bool = false,
        /// If true, the mixer may adjust the durations or volumes
        /// slightly to avoid clicking.
        avoid_clicks: bool = true,

        _pad: u24 = 0,
    };

    /// Frequency information. See Flags.midi_freq for information on how
    /// this field is interpreted.
    frequency: ToneFrequency,
    /// Duration in 60ths of a second, parsed as 0xAA_DD_RR_SS, with
    /// AA = Attack
    /// DD = Decay
    /// SS = Sustain
    /// RR = Release
    duration: ToneDuration,
    /// Volume, parsed as 0xXXXX_PP_SS, with
    /// SS = Sustain volume, 0-100
    /// PP = Peak volume, 0-100
    volume: u32,
    /// Flags for channel and other attributes
    flags: Flags,
};

pub const MixerOptions = struct {
    /// Buffer a relatively conservative 66 mS
    /// of audio by default, to avoid hitches. If your app
    /// hits a consistent framerate, this can be reduced
    /// to improve latency and reduce memory use.
    buffer_size: usize = 4 * 44100 / 60,
};

pub fn Mixer(comptime mix_opts: MixerOptions) type {
    return struct {
        /// Align the size to a multiple of 512 to avoid small
        /// mixes. (the OS will always dequeue power-of-two chunks.)
        pub const buffer_samples = std.mem.alignForward(usize, mix_opts.buffer_size, 512);

        mix_ring_buffer: [buffer_samples]u8 align(8) = undefined,
        samples_mixed: u64 = 0,

        // Mixing state
        envelopes: [4]ActiveEnvelope = @splat(.{}),
        freq: [3]Freq = undefined,
        duty: [2]u32 = undefined,
        noise_val: u32 = 0,

        /// Optional callback, will be called once per tick to update
        /// tones during mixing. Called at sample-accurate positions
        /// for exact audio timing.
        audio_tick_callback: ?*const fn () void = null,
        /// Samples remaining in the current tick.
        /// This is only tracked if the callback is non-null.
        samples_left_in_tick: u32 = 0,

        /// The number of samples per tick. A value of zero
        /// implies the default of 44100/60 (60 ticks per second)
        audio_tick_samples: u32 = 0,

        pub fn start_audio(mixer: *@This()) void {
            mixer.samples_mixed = 0;
            mixer.samples_left_in_tick = 0;
            if (mixer.audio_tick_samples == 0) {
                mixer.audio_tick_samples = @divExact(44100, 60);
            }
            cart.audio_set_buffer(u8, &mixer.mix_ring_buffer);
        }

        pub const AudioTickOptions = struct {
            callback: ?*const fn () void = null,
            samples_per_tick: u32 = @divExact(44100, 60),
            interrupt_prev_tick: bool = false,
        };
        /// Sets the audio tick rate and an optional sample-accurate callback.
        pub fn set_audio_tick(mixer: *@This(), opts: AudioTickOptions) void {
            mixer.audio_tick_callback = opts.callback;
            mixer.audio_tick_samples = if (opts.samples_per_tick == 0) @divExact(44100, 60) else opts.samples_per_tick;
            if (opts.interrupt_prev_tick or opts.callback == null) {
                mixer.samples_left_in_tick = 0;
            }
        }

        /// Returns the time since start_audio was called, according to
        /// the number of mixed samples. For applications like DDR where
        /// visual effects are synced to the audio, this time should be
        /// used instead of cart.micros_since_boot().
        pub fn get_audio_time_seconds(mixer: *@This()) f64 {
            return audio_time_seconds_from_samples(mixer.samples_mixed);
        }

        pub fn audio_time_seconds_from_samples(samples: u64) f64 {
            return @as(f64, @floatFromInt(samples)) * (1.0 / 44100.0);
        }

        pub fn update(mixer: *@This()) void {
            // If the mixer is slow (possibly due to a slow tick callback),
            // the OS can consume samples faster than the mixer can generate
            // them, leading to an infinite mixing loop. To prevent this, we
            // mix a maximum of three times per update.
            var mixes_left: u32 = 3;
            while (cart.audio_get_buffer(u8)) |buf| {
                mixer.mix_samples(buf);
                cart.audio_submit_samples(buf.len);

                mixes_left -= 1;
                if (mixes_left == 0) break;
            }
        }

        // Start a tone at the current sample, which may be out of phase with
        // audio ticks. For exact control over tone timing, call this from the
        // set_audio_tick callback.
        pub fn tone(mixer: *@This(), opts: ToneOptions) void {
            const sustain_volume_raw: u8 = @min(opts.volume & 0xFF, 100);
            const peak_volume_raw: u8 = @min(opts.volume >> 8 & 0xFF, 100);

            const sustain_volume: u31 = @intCast(@as(u64, sustain_volume_raw) * 0x7FFF_FFFF / 100);
            const peak_volume: u31 = if (peak_volume_raw == 0) sustain_volume else @intCast(@as(u64, peak_volume_raw) * 0x7FFF_FFFF / 100);

            const channel = @backingInt(opts.flags.channel);

            const is_infinite = @backingInt(opts.duration) == @backingInt(ToneDuration.forever);
            const env = &mixer.envelopes[channel];
            const was_silent = env.curr_volume == 0;
            env.full_phase = opts.flags.avoid_clicks and opts.duration.release_ticks == 0;
            const samples_per_tick = mixer.audio_tick_samples;
            if (!is_infinite) {
                env.* = .{
                    .attack_samples = @as(u32, opts.duration.attack_ticks) * samples_per_tick,
                    .decay_samples = @as(u32, opts.duration.decay_ticks) * samples_per_tick,
                    .sustain_samples = @as(u32, opts.duration.sustain_ticks) * samples_per_tick,
                    .release_samples = @as(u32, opts.duration.release_ticks) * samples_per_tick,
                    .peak_volume = peak_volume,
                    .sustain_volume = sustain_volume,
                };
                update_envelope_mode(env);
            } else {
                env.mode = .inactive;
                env.curr_volume = sustain_volume;
                env.volume_step = 0;
            }

            if (channel < mixer.freq.len) {
                const has_sweep = !is_infinite and (opts.frequency.bits & 0xFFFF_0000) != 0;

                const start_freq_hz: f32 = if (opts.flags.midi_freq)
                    freq_from_midi_bits(opts.frequency.midi_sweep.start_note, opts.frequency.midi_sweep.start_bend)
                else
                    @floatFromInt(opts.frequency.freq_sweep.start_hz);

                const end_freq_hz: f32 = if (!has_sweep)
                    start_freq_hz
                else if (opts.flags.midi_freq)
                    freq_from_midi_bits(opts.frequency.midi_sweep.end_note, opts.frequency.midi_sweep.end_bend)
                else
                    @floatFromInt(opts.frequency.freq_sweep.end_hz);

                const freq_delta: f32 = if (has_sweep) blk: {
                    const duration_samples = (@as(u32, opts.duration.attack_ticks) + opts.duration.decay_ticks + opts.duration.sustain_ticks + opts.duration.release_ticks) * samples_per_tick;
                    break :blk (end_freq_hz - start_freq_hz) / @as(f32, @floatFromInt(duration_samples));
                } else 0;

                const freq = &mixer.freq[channel];
                freq.freq = start_freq_hz;
                freq.delta_freq = freq_delta;
                freq.calc_delta_phase();

                // Ensure square waves start immediately, triangle waves start without clipping
                if (was_silent) {
                    freq.phase = if (channel < mixer.duty.len) 0 else 0x4000_0000;
                }
            }

            if (channel < mixer.duty.len) {
                mixer.duty[channel] = switch (opts.flags.duty_cycle) {
                    .@"1/2" => 0x8000_0000,
                    .@"1/4" => 0x4000_0000,
                    .@"1/8" => 0x2000_0000,
                    .@"3/4" => 0xC000_0000,
                };
            }
        }

        // Stop noise on a channel. If avoid_clicks is set, the channel will continue for a few samples to avoid a click.
        // Otherwise it will shut down immediately.
        pub fn stop_channel(mixer: *@This(), channel: ToneOptions.Flags.Channel, avoid_clicks: bool) void {
            const chan = @backingInt(channel);
            const env = &mixer.envelopes[chan];
            if (avoid_clicks and chan < mixer.freq.len) {
                if (env.mode != .inactive or env.curr_volume != 0) {
                    env.mode = .finish_phase;
                    env.mode_samples = 1;
                }
            } else {
                env.mode = .inactive;
                env.curr_volume = 0;
                env.volume_step = 0;
            }
        }

        fn mix_samples(mixer: *@This(), buf: []u8) void {
            const z = cart.fn_zone(@src());
            defer z.end();

            var buf_left = buf;
            while (buf_left.len > 0) {
                if (mixer.audio_tick_callback) |callback| {
                    if (mixer.samples_left_in_tick == 0) {
                        callback();
                        mixer.samples_left_in_tick = mixer.audio_tick_samples;
                    }

                    const samples_to_mix = @min(buf_left.len, mixer.samples_left_in_tick);
                    mixer.mix_samples_no_callback(buf_left[0..samples_to_mix]);
                    mixer.samples_left_in_tick -= samples_to_mix;
                    buf_left = buf_left[samples_to_mix..];
                } else {
                    mixer.mix_samples_no_callback(buf_left);
                    mixer.samples_left_in_tick = 0;
                    break;
                }
            }
        }

        fn mix_samples_no_callback(noalias mixer: *@This(), noalias buf: []u8) void {
            for (buf) |*result| {
                // Tick the envelopes
                for (&mixer.envelopes) |*env| {
                    if (env.mode != .inactive) {
                        if (env.mode_samples == 1) {
                            update_envelope_mode(env);
                        } else {
                            env.curr_volume = @intCast(@max(0, @as(i32, @intCast(env.curr_volume)) + env.volume_step));
                            env.mode_samples -= 1;
                        }
                    }
                }

                // Tick the frequencies
                inline for (&mixer.freq, mixer.envelopes[0..mixer.freq.len], 0..) |*freq, *env, i| {
                    const prev_phase = freq.phase;
                    freq.phase +%= freq.delta_phase;
                    if (env.mode == .finish_phase) {
                        if (i < mixer.duty.len and freq.phase < prev_phase or
                            i >= mixer.duty.len and (freq.phase ^ prev_phase) & 0xC000_0000 == 0x4000_0000)
                        {
                            env.mode = .inactive;
                            env.volume_step = 0;
                            env.curr_volume = 0;
                        }
                    }
                    if (env.mode != .inactive and freq.delta_freq != 0) {
                        freq.freq += freq.delta_freq;
                        freq.calc_delta_phase();
                    }
                }

                // Add up the samples for the channels
                var sample: u32 = 0;

                // Square waves
                inline for (0..mixer.duty.len) |i| {
                    const volume = mixer.envelopes[i].curr_volume;
                    const offset = 0x7FFF_FFFF - volume;
                    sample += offset >> 2;

                    if (volume != 0 and mixer.freq[i].phase > mixer.duty[i]) {
                        sample += volume >> 1;
                    }
                }

                // Triangle waves
                inline for (mixer.duty.len..mixer.freq.len) |i| {
                    const volume = mixer.envelopes[i].curr_volume;
                    const offset = 0x7FFF_FFFF - volume;
                    sample += offset >> 2;

                    if (volume != 0) {
                        const phase = mixer.freq[i].phase;
                        // Similar to abs, but negative values are also shifted by 1, giving a more even
                        // triangle that avoids 0x8000_0000 as a possible value
                        const tri_val = if (phase & 0x8000_0000 != 0) ~phase else phase;
                        const tri_volume_shr1: u32 = @intCast(@as(u64, tri_val) * volume >> 32);
                        sample += tri_volume_shr1;
                    }
                }

                // Noise waves
                inline for (mixer.freq.len..mixer.envelopes.len) |i| {
                    const volume = mixer.envelopes[i].curr_volume;
                    const offset = 0x7FFF_FFFF - volume;
                    sample += offset >> 2;

                    if (volume != 0) {
                        const volume_sample: u32 = @intCast(@as(u64, volume) * ~mixer.noise_val >> 32);
                        sample += volume_sample >> 1;

                        // Emulate the NES APU noise sequence. Shift all bits over,
                        // and replace the MSB with the xor of bits 0 and 1. We want
                        // the mixer to be zero-initialized to land in BSS, so we invert
                        // the sequence and use xnor instead.
                        const noise_val_bit: u32 = @as(u32, @bitCast(-@as(i32, @intCast(mixer.noise_val & 0x3)) & 2)) << 30;
                        mixer.noise_val = mixer.noise_val >> 1 | noise_val_bit;
                    }
                }

                result.* = @intCast(sample >> 24);
            }
            mixer.samples_mixed += buf.len;
        }
    };
}
