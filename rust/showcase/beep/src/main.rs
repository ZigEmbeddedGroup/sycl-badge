//! Audio bring-up, the way `fill` did the display: put every number that
//! matters on the screen and make the sound impossible to miss.
//!
//! It starts a *sustained* tone at 2700 Hz and full volume the moment it loads.
//! Both of those are deliberate. The buzzer's response peaks near 2700 Hz and
//! rolls off steeply either side, and the notes in `flappy` and `itest` are
//! short, quiet, and mostly below 1 kHz — so "I hear nothing" from those two is
//! not yet evidence that anything is broken. If this cart is also silent, that
//! is evidence.
//!
//! On the badge it also reads the IPC block back and shows what is actually
//! sitting at the addresses the kernel reads (`CartIPCData` in
//! `src/os/cart/api.zig`). Matching numbers mean the cart wrote where it meant
//! to and the problem is downstream; wrong numbers mean it did not.
//!
//! One simulator-only wrinkle: the WASM-4 APU's sustain field is eight bits of
//! frames, so a `DIRECT` note lapses after about four seconds there. The
//! sequencer re-arms itself and does not. On the badge, sustained is endless in
//! both routes — the buzzer holds the note until something stops it.
//!
//! * Start — play / stop.
//! * A — swap between calling the platform directly and going through the
//!   sequencer, which separates a sequencer bug from an IPC or driver one.
//! * Up / Down — frequency.  Left / Right — wave shape.  Select — volume.

#![no_std]
#![no_main]

use sycl_cart::prelude::*;
use sycl_cart::{info, platform, text};

/// Worth having 2700 Hz in the middle: it is where the buzzer is loudest, so it
/// is the frequency most likely to prove the path works. The rest bracket it.
const FREQS: [f32; 8] = [220.0, 440.0, 880.0, 1568.0, 2093.0, 2700.0, 3136.0, 3951.0];
const START_FREQ: usize = 5;

const SHAPES: [(Shape, &str); 3] = [
    (Shape::Square, "SQUARE"),
    (Shape::Triangle, "TRIANGLE"),
    (Shape::Sawtooth, "SAWTOOTH"),
];

const VOLUMES: [f32; 4] = [1.0, 0.5, 0.25, 0.1];

struct Beep {
    freq: usize,
    shape: usize,
    volume: usize,
    /// False routes through `Ctx::audio`, the sequencer.
    direct: bool,
    playing: bool,
    dirty: bool,
}

impl Cart for Beep {
    const INIT: Self = Beep {
        freq: START_FREQ,
        shape: 0,
        volume: 0,
        direct: true,
        playing: true,
        dirty: true,
    };

    fn start(&mut self, c: &mut Ctx) {
        // Ask for full master volume explicitly. The driver already defaults to
        // 1.0, so this is really a test of the CART_VOLUME message.
        c.audio.set_volume(1.0);
        info!(
            "beep: sustained {} hz, full volume",
            FREQS[self.freq] as u32
        );
        self.apply(c);
    }

    fn update(&mut self, c: &mut Ctx) {
        let mut changed = true;
        if c.input.just_pressed(Button::Start) {
            self.playing = !self.playing;
        } else if c.input.just_pressed(Button::A) {
            self.direct = !self.direct;
        } else if c.input.just_pressed(Button::Up) {
            self.freq = (self.freq + 1) % FREQS.len();
        } else if c.input.just_pressed(Button::Down) {
            self.freq = (self.freq + FREQS.len() - 1) % FREQS.len();
        } else if c.input.just_pressed(Button::Right) {
            self.shape = (self.shape + 1) % SHAPES.len();
        } else if c.input.just_pressed(Button::Left) {
            self.shape = (self.shape + SHAPES.len() - 1) % SHAPES.len();
        } else if c.input.just_pressed(Button::Select) {
            self.volume = (self.volume + 1) % VOLUMES.len();
        } else {
            changed = false;
        }

        if changed {
            self.apply(c);
            self.dirty = true;
        }
        // The IPC readback changes without any input, so redraw while playing.
        if self.dirty || cfg!(target_arch = "arm") {
            self.dirty = false;
            self.draw(c);
        }
    }
}

impl Beep {
    /// Push the current settings at the hardware, by whichever route is selected.
    ///
    /// Both routes are stopped first: switching route while a note sounds would
    /// otherwise leave the old one running with nothing tracking it.
    fn apply(&self, c: &mut Ctx) {
        c.audio.stop_all();
        platform::stop();

        if !self.playing {
            return;
        }
        let (shape, _) = SHAPES[self.shape];
        let freq = FREQS[self.freq];
        let volume = VOLUMES[self.volume];
        if self.direct {
            platform::tone(freq, ToneLen::Sustained, volume, shape);
        } else {
            c.audio.tone_with(freq, ToneLen::Sustained, volume, shape);
        }
    }

    fn draw(&self, c: &mut Ctx) {
        const FG: Color = Color::WHITE;
        const BG: Color = Color::hex(0x101018);
        c.gfx.clear(BG);

        let (_, shape_name) = SHAPES[self.shape];
        let mut y = 2;
        let line = |c: &mut Ctx, y: &mut i32, s: &[u8], color: Color| {
            c.gfx.text_with(s, 2, *y, 1, color, Some(BG));
            *y += 10;
        };

        line(c, &mut y, b"BEEP TEST", Color::CYAN);
        line(
            c,
            &mut y,
            &uformat!(24, "FREQ  {} HZ", FREQS[self.freq] as u32),
            FG,
        );
        line(c, &mut y, &uformat!(24, "SHAPE {}", shape_name), FG);
        line(
            c,
            &mut y,
            &uformat!(24, "VOL   {}", text::fx(VOLUMES[self.volume], 2)),
            FG,
        );
        line(
            c,
            &mut y,
            if self.direct {
                b"PATH  DIRECT" as &[u8]
            } else {
                b"PATH  SEQUENCER"
            },
            FG,
        );
        line(
            c,
            &mut y,
            if self.playing {
                b"STATE PLAYING" as &[u8]
            } else {
                b"STATE STOPPED"
            },
            if self.playing {
                Color::GREEN
            } else {
                Color::YELLOW
            },
        );

        y += 4;
        self.draw_readback(c, &mut y);

        c.gfx.text_with(
            b"START play  A path\nUP/DN freq  SEL vol\nL/R shape",
            2,
            HEIGHT as i32 - 32,
            1,
            Color::hex(0x8090a0),
            Some(BG),
        );
    }

    /// What is actually sitting in the IPC block the kernel reads.
    #[cfg(target_arch = "arm")]
    fn draw_readback(&self, c: &mut Ctx, y: &mut i32) {
        // Absolute addresses rather than the framework's constants on purpose:
        // if the two disagree, this cart should show the hardware's answer.
        // Derived from `CartIPCData` in `src/os/cart/api.zig`.
        const TONE_FREQ: *const f32 = 0x2003_40A0 as *const f32;
        const TONE_DURATION: *const f32 = 0x2003_40A4 as *const f32;
        const TONE_VOLUME: *const f32 = 0x2003_40B0 as *const f32;
        const TONE_FLAGS: *const u32 = 0x2003_40B4 as *const u32;

        // SAFETY: fixed addresses inside the IPC block the OS keeps mapped.
        let (freq, duration, volume, flags) = unsafe {
            (
                TONE_FREQ.read_volatile(),
                TONE_DURATION.read_volatile(),
                TONE_VOLUME.read_volatile(),
                TONE_FLAGS.read_volatile(),
            )
        };

        // A frequency that matches the line above proves the write landed where
        // the kernel looks; -1.0 duration is what "sustained" should read as.
        let ok = freq as u32 == FREQS[self.freq] as u32;
        c.gfx.text_with(
            &uformat!(32, "IPC F {} HZ", freq as u32),
            2,
            *y,
            1,
            if ok { Color::GREEN } else { Color::RED },
            Some(Color::hex(0x101018)),
        );
        *y += 10;
        c.gfx.text_with(
            &uformat!(
                32,
                "IPC D {} V {}",
                text::fx(duration, 2),
                text::fx(volume, 2)
            ),
            2,
            *y,
            1,
            Color::WHITE,
            Some(Color::hex(0x101018)),
        );
        *y += 10;
        c.gfx.text_with(
            &uformat!(32, "IPC FLAGS {}", flags),
            2,
            *y,
            1,
            Color::WHITE,
            Some(Color::hex(0x101018)),
        );
        *y += 10;
    }

    /// The simulator has no IPC block at those addresses, and reading them would
    /// trap out of bounds.
    #[cfg(not(target_arch = "arm"))]
    fn draw_readback(&self, c: &mut Ctx, y: &mut i32) {
        c.gfx.text_with(
            b"IPC   (badge only)",
            2,
            *y,
            1,
            Color::hex(0x8090a0),
            Some(Color::hex(0x101018)),
        );
        *y += 10;
    }
}

sycl_cart::cart!(Beep);
