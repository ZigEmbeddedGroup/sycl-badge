//! Audio: one square-wave voice, plus a tiny sequencer over `&'static` tracks.
//!
//! # Why the API is this small
//!
//! The badge's buzzer is a single monophonic square wave. `src/os/drivers/audio.zig`
//! drives GPIO9 with a 500 kHz PWM carrier whose duty cycle sets amplitude and a
//! DMA channel flipping between two duty values at the note frequency; its whole
//! state is `enum { off, square }`. There is no envelope, no second voice, no
//! wave shape — the kernel does not even read the `tone_flags` a cart writes.
//!
//! The simulator, meanwhile, runs the full WASM-4 APU: four channels, ADSR,
//! frequency slides, panning. Exposing that would mean composing against audio
//! the badge cannot produce, so we deliberately drive only the common subset. A
//! cart sounds the same in both places.
//!
//! # Structure
//!
//! [`Audio::tone`] is the raw primitive, at exact hardware parity. Above it sits
//! a sequencer with three priority levels — a one-shot beep, an SFX track, and a
//! music track — that resolves a single winning note each frame and only touches
//! the hardware when that note *changes*. That last part matters: every `tone()`
//! on the badge aborts a DMA channel and reprograms a PWM slice, so re-issuing
//! the same note 60 times a second is audible as clicking.
//!
//! # Two hardware caveats
//!
//! * Pitch is currently about 400 cents sharp on real hardware — see the TODO at
//!   `src/os/drivers/audio.zig:23`. We do not compensate, because compensating
//!   would break when the driver is fixed.
//! * The buzzer's response peaks near 2700 Hz and rolls off steeply either side
//!   (`docs/audio_analysis/README.md`). Notes much below ~1 kHz will be quiet on
//!   hardware however good they sound in the simulator.

use crate::platform;

/// How long a note lasts.
#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub enum ToneLen {
    /// A fixed number of 60 Hz frames. The note ends by itself on both
    /// platforms — the badge arms a DMA transfer count, the simulator an
    /// envelope — so you do not have to stop it.
    Frames(u16),
    /// Plays until stopped. Re-armed automatically where the platform needs it.
    Sustained,
}

/// One entry in a [`Track`].
#[derive(Copy, Clone, Debug)]
pub struct Step {
    /// Hz. Zero means silence for the duration.
    pub freq: f32,
    /// Length in 60 Hz frames. Zero is treated as one.
    pub frames: u16,
    /// 0.0..=1.0, perceptually linear (the OS maps it across ~50 dB).
    pub volume: f32,
}

impl Step {
    /// A note at full volume.
    pub const fn note(freq: f32, frames: u16) -> Step {
        Step {
            freq,
            frames,
            volume: 1.0,
        }
    }

    /// A note at a given volume.
    pub const fn at(freq: f32, frames: u16, volume: f32) -> Step {
        Step {
            freq,
            frames,
            volume,
        }
    }

    /// Silence.
    pub const fn rest(frames: u16) -> Step {
        Step {
            freq: 0.0,
            frames,
            volume: 0.0,
        }
    }
}

/// A sequence of steps, held in flash as const data.
#[derive(Copy, Clone)]
pub struct Track {
    pub steps: &'static [Step],
    pub looping: bool,
}

impl Track {
    /// Plays once, then stops.
    pub const fn once(steps: &'static [Step]) -> Track {
        Track {
            steps,
            looping: false,
        }
    }

    /// Repeats forever.
    pub const fn looping(steps: &'static [Step]) -> Track {
        Track {
            steps,
            looping: true,
        }
    }
}

/// Identity of the note currently sounding.
///
/// Keyed on `(source, generation, step)` and deliberately **not** on pitch: two
/// consecutive identical notes must re-trigger, or the second one is never
/// issued and the sound dies early.
#[derive(Copy, Clone, PartialEq, Eq, Debug)]
struct VoiceId {
    src: u8,
    generation: u32,
    step: u16,
}

const SRC_ONESHOT: u8 = 0;
const SRC_SFX: u8 = 1;
const SRC_MUSIC: u8 = 2;

#[derive(Copy, Clone)]
struct Cursor {
    track: Option<&'static Track>,
    step: u16,
    left: u16,
    generation: u32,
}

impl Cursor {
    const EMPTY: Cursor = Cursor {
        track: None,
        step: 0,
        left: 0,
        generation: 0,
    };

    fn start(&mut self, track: &'static Track, generation: u32) {
        self.track = if track.steps.is_empty() {
            None
        } else {
            Some(track)
        };
        self.step = 0;
        self.left = track.steps.first().map_or(0, |s| s.frames.max(1));
        self.generation = generation;
    }

    fn current(&self) -> Option<Step> {
        self.track.map(|t| t.steps[self.step as usize])
    }

    /// Consume one frame, moving to the next step when the current one expires.
    fn advance(&mut self) {
        let Some(track) = self.track else { return };
        if self.left > 0 {
            self.left -= 1;
        }
        if self.left > 0 {
            return;
        }
        self.step += 1;
        if self.step as usize >= track.steps.len() {
            if track.looping {
                self.step = 0;
            } else {
                self.track = None;
                return;
            }
        }
        // Clamped so a zero-length step cannot spin forever.
        self.left = track.steps[self.step as usize].frames.max(1);
    }
}

#[derive(Copy, Clone)]
struct OneShot {
    step: Step,
    left: u16,
    sustained: bool,
    generation: u32,
}

/// The audio mixer. Reached through [`crate::Ctx`].
pub struct Audio {
    oneshot: Option<OneShot>,
    sfx: Cursor,
    music: Cursor,
    playing: Option<VoiceId>,
    /// Frames until a `Sustained` note must be re-armed. 0 = not applicable.
    refresh_in: u16,
    global_volume: f32,
    next_generation: u32,
}

impl Audio {
    pub(crate) const NEW: Audio = Audio {
        oneshot: None,
        sfx: Cursor::EMPTY,
        music: Cursor::EMPTY,
        playing: None,
        refresh_in: 0,
        global_volume: 1.0,
        next_generation: 1,
    };

    fn bump(&mut self) -> u32 {
        let g = self.next_generation;
        self.next_generation = self.next_generation.wrapping_add(1).max(1);
        g
    }

    /// Play a single note immediately, above music and SFX.
    ///
    /// This is the one you want for a jump or a coin pickup:
    /// `c.audio.tone(880.0, ToneLen::Frames(4), 0.8)`.
    pub fn tone(&mut self, freq_hz: f32, len: ToneLen, volume: f32) {
        let generation = self.bump();
        let (left, sustained) = match len {
            ToneLen::Frames(f) => (f.max(1), false),
            ToneLen::Sustained => (u16::MAX, true),
        };
        self.oneshot = Some(OneShot {
            step: Step {
                freq: freq_hz,
                frames: left,
                volume,
            },
            left,
            sustained,
            generation,
        });
    }

    /// Stop a [`Audio::tone`] one-shot, letting SFX or music resume.
    pub fn stop_tone(&mut self) {
        self.oneshot = None;
    }

    /// Start a sound effect. Preempts music for as long as it runs.
    pub fn play_sfx(&mut self, track: &'static Track) {
        let g = self.bump();
        self.sfx.start(track, g);
    }

    /// Start background music.
    pub fn play_music(&mut self, track: &'static Track) {
        let g = self.bump();
        self.music.start(track, g);
    }

    pub fn stop_sfx(&mut self) {
        self.sfx = Cursor::EMPTY;
    }

    pub fn stop_music(&mut self) {
        self.music = Cursor::EMPTY;
    }

    /// Silence everything.
    pub fn stop_all(&mut self) {
        self.oneshot = None;
        self.sfx = Cursor::EMPTY;
        self.music = Cursor::EMPTY;
    }

    /// True while anything is sounding.
    pub fn is_playing(&self) -> bool {
        self.playing.is_some()
    }

    /// Master volume, 0.0..=1.0, perceptually linear.
    ///
    /// The badge applies this in the OS; the simulator has no equivalent, so
    /// there we fold it into each note's volume instead.
    pub fn set_volume(&mut self, volume: f32) {
        self.global_volume = clamp01(volume);
        if platform::GLOBAL_VOLUME_IN_HARDWARE {
            platform::set_global_volume(self.global_volume);
        }
    }

    pub fn volume(&self) -> f32 {
        self.global_volume
    }

    /// Highest-priority active step, with its identity.
    fn winner(&self) -> Option<(VoiceId, Step, bool)> {
        if let Some(o) = self.oneshot {
            let id = VoiceId {
                src: SRC_ONESHOT,
                generation: o.generation,
                step: 0,
            };
            return Some((id, o.step, o.sustained));
        }
        if let Some(step) = self.sfx.current() {
            let id = VoiceId {
                src: SRC_SFX,
                generation: self.sfx.generation,
                step: self.sfx.step,
            };
            return Some((id, step, false));
        }
        if let Some(step) = self.music.current() {
            let id = VoiceId {
                src: SRC_MUSIC,
                generation: self.music.generation,
                step: self.music.step,
            };
            return Some((id, step, false));
        }
        None
    }

    fn emit(&self, step: Step, sustained: bool) {
        if step.freq <= 0.0 || step.volume <= 0.0 {
            platform::stop();
            return;
        }
        let volume = if platform::GLOBAL_VOLUME_IN_HARDWARE {
            step.volume
        } else {
            step.volume * self.global_volume
        };
        let len = if sustained {
            ToneLen::Sustained
        } else {
            ToneLen::Frames(step.frames.max(1))
        };
        platform::tone(step.freq, len, clamp01(volume));
    }

    /// Resolve and drive one frame of audio. Called for you after `update`.
    ///
    /// Order matters: resolve *then* advance, so a note started during `update`
    /// is heard in the same frame it was requested.
    pub(crate) fn tick(&mut self) {
        match self.winner() {
            Some((id, step, sustained)) => {
                if self.playing != Some(id) {
                    self.playing = Some(id);
                    self.emit(step, sustained);
                    self.refresh_in = if sustained {
                        platform::SUSTAIN_REFRESH_FRAMES
                    } else {
                        0
                    };
                } else if sustained && self.refresh_in > 0 {
                    // Where the platform cannot hold a note indefinitely, re-arm
                    // before it lapses. Re-arming a still-sounding note preserves
                    // phase in the simulator's APU, so this does not click.
                    self.refresh_in -= 1;
                    if self.refresh_in == 0 {
                        self.emit(step, sustained);
                        self.refresh_in = platform::SUSTAIN_REFRESH_FRAMES;
                    }
                }
            }
            None => {
                if self.playing.is_some() {
                    self.playing = None;
                    platform::stop();
                }
            }
        }

        if let Some(o) = &mut self.oneshot {
            if !o.sustained {
                o.left = o.left.saturating_sub(1);
                if o.left == 0 {
                    self.oneshot = None;
                }
            }
        }
        self.sfx.advance();
        self.music.advance();
    }
}

fn clamp01(v: f32) -> f32 {
    v.clamp(0.0, 1.0)
}

pub mod notes {
    //! Equal-tempered pitches, A4 = 440 Hz. `S` means sharp, so `DS6` is D#6.
    //!
    //! The badge's buzzer peaks near 2700 Hz and rolls off steeply either side,
    //! so octaves 6 and 7 are the ones that will actually carry on hardware.
    //! Anything below roughly 1 kHz will be quiet however good it sounds in the
    //! simulator. Raw Hz works too — these are only a convenience.

    pub const C4: f32 = 261.63;
    pub const CS4: f32 = 277.18;
    pub const D4: f32 = 293.66;
    pub const DS4: f32 = 311.13;
    pub const E4: f32 = 329.63;
    pub const F4: f32 = 349.23;
    pub const FS4: f32 = 369.99;
    pub const G4: f32 = 392.00;
    pub const GS4: f32 = 415.30;
    pub const A4: f32 = 440.00;
    pub const AS4: f32 = 466.16;
    pub const B4: f32 = 493.88;

    pub const C5: f32 = 523.25;
    pub const CS5: f32 = 554.37;
    pub const D5: f32 = 587.33;
    pub const DS5: f32 = 622.25;
    pub const E5: f32 = 659.25;
    pub const F5: f32 = 698.46;
    pub const FS5: f32 = 739.99;
    pub const G5: f32 = 783.99;
    pub const GS5: f32 = 830.61;
    pub const A5: f32 = 880.00;
    pub const AS5: f32 = 932.33;
    pub const B5: f32 = 987.77;

    pub const C6: f32 = 1046.50;
    pub const CS6: f32 = 1108.73;
    pub const D6: f32 = 1174.66;
    pub const DS6: f32 = 1244.51;
    pub const E6: f32 = 1318.51;
    pub const F6: f32 = 1396.91;
    pub const FS6: f32 = 1479.98;
    pub const G6: f32 = 1567.98;
    pub const GS6: f32 = 1661.22;
    pub const A6: f32 = 1760.00;
    pub const AS6: f32 = 1864.66;
    pub const B6: f32 = 1975.53;

    pub const C7: f32 = 2093.00;
    pub const CS7: f32 = 2217.46;
    pub const D7: f32 = 2349.32;
    pub const DS7: f32 = 2489.02;
    pub const E7: f32 = 2637.02;
    pub const F7: f32 = 2793.83;
    pub const FS7: f32 = 2959.96;
    pub const G7: f32 = 3135.96;
    pub const GS7: f32 = 3322.44;
    pub const A7: f32 = 3520.00;
    pub const AS7: f32 = 3729.31;
    pub const B7: f32 = 3951.07;
}

#[cfg(test)]
mod tests {
    use super::*;

    static TWO_SAME: Track = Track::once(&[Step::note(440.0, 2), Step::note(440.0, 2)]);
    static THREE: Track = Track::once(&[
        Step::note(100.0, 1),
        Step::note(200.0, 1),
        Step::note(300.0, 1),
    ]);
    static LOOP2: Track = Track::looping(&[Step::note(100.0, 1), Step::note(200.0, 1)]);

    fn audio() -> Audio {
        Audio::NEW
    }

    #[test]
    fn identical_consecutive_notes_retrigger() {
        // Keying on pitch would make the second note silent.
        let mut a = audio();
        a.play_sfx(&TWO_SAME);
        a.tick();
        let first = a.playing.expect("first note");
        a.tick();
        assert_eq!(a.playing, Some(first), "still inside the first note");
        a.tick();
        let second = a.playing.expect("second note");
        assert_ne!(second, first, "second note must be a distinct voice");
    }

    #[test]
    fn steps_advance_one_per_frame_and_finish() {
        let mut a = audio();
        a.play_sfx(&THREE);
        let mut seen = std::vec::Vec::new();
        for _ in 0..4 {
            a.tick();
            seen.push(a.playing.map(|v| v.step));
        }
        assert_eq!(seen, std::vec![Some(0), Some(1), Some(2), None]);
        assert!(!a.is_playing(), "non-looping track stops at the end");
    }

    #[test]
    fn looping_track_wraps_forever() {
        let mut a = audio();
        a.play_music(&LOOP2);
        for _ in 0..7 {
            a.tick();
        }
        assert!(a.is_playing());
    }

    #[test]
    fn sfx_preempts_music_then_hands_back() {
        let mut a = audio();
        a.play_music(&LOOP2);
        a.tick();
        assert_eq!(a.playing.unwrap().src, SRC_MUSIC);
        a.play_sfx(&THREE);
        a.tick();
        assert_eq!(a.playing.unwrap().src, SRC_SFX);
        for _ in 0..3 {
            a.tick();
        }
        assert_eq!(a.playing.unwrap().src, SRC_MUSIC, "music resumes");
    }

    #[test]
    fn oneshot_outranks_everything_and_expires() {
        let mut a = audio();
        a.play_music(&LOOP2);
        a.tone(880.0, ToneLen::Frames(2), 1.0);
        a.tick();
        assert_eq!(a.playing.unwrap().src, SRC_ONESHOT);
        a.tick();
        assert_eq!(a.playing.unwrap().src, SRC_ONESHOT);
        a.tick();
        assert_eq!(a.playing.unwrap().src, SRC_MUSIC);
    }

    #[test]
    fn sustained_oneshot_never_expires_on_its_own() {
        let mut a = audio();
        a.tone(440.0, ToneLen::Sustained, 1.0);
        for _ in 0..1000 {
            a.tick();
        }
        assert_eq!(a.playing.unwrap().src, SRC_ONESHOT);
        a.stop_tone();
        a.tick();
        assert!(!a.is_playing());
    }

    #[test]
    fn empty_track_is_ignored() {
        static EMPTY: Track = Track::once(&[]);
        let mut a = audio();
        a.play_sfx(&EMPTY);
        a.tick();
        assert!(!a.is_playing());
    }

    #[test]
    fn zero_length_steps_cannot_spin() {
        static ZEROS: Track = Track::looping(&[Step::note(440.0, 0), Step::note(880.0, 0)]);
        let mut a = audio();
        a.play_music(&ZEROS);
        for _ in 0..10 {
            a.tick();
        }
        assert!(a.is_playing());
    }

    #[test]
    fn volume_is_clamped() {
        let mut a = audio();
        a.set_volume(5.0);
        assert_eq!(a.volume(), 1.0);
        a.set_volume(-1.0);
        assert_eq!(a.volume(), 0.0);
    }
}
