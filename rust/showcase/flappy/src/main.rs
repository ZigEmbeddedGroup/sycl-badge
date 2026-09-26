//! A complete flappy-bird-style cart in one file.
//!
//! Demonstrates the intended shape of a cart: plain structs for state, fixed
//! arrays instead of collections, immediate-mode drawing, compile-time sprite
//! art, and the audio sequencer.
//!
//! Controls: A or Up to flap, Start to restart after a crash.

#![no_std]
#![no_main]

use sycl_cart::audio::notes;
use sycl_cart::math;
use sycl_cart::prelude::*;
use sycl_cart::Track;

// ── Tuning ──────────────────────────────────────────────────────────────────

const GRAVITY: f32 = 0.20;
const FLAP_VELOCITY: f32 = -2.4;
const MAX_FALL: f32 = 3.2;
const SCROLL_SPEED: f32 = 1.0;

const GROUND_Y: i32 = HEIGHT as i32 - 16;
const GAP_HEIGHT: i32 = 42;
const PIPE_WIDTH: i32 = 18;
const PIPE_SPACING: i32 = 62;
const PIPE_COUNT: usize = 3;

const BIRD_X: i32 = 40;

// ── Palette ─────────────────────────────────────────────────────────────────

const SKY: Color = Color::hex(0x4a_9c_d8);
const GROUND: Color = Color::hex(0xd8_c0_78);
const GROUND_EDGE: Color = Color::hex(0x8c_6c_3c);
const PIPE: Color = Color::hex(0x4c_b8_4c);
const PIPE_DARK: Color = Color::hex(0x2c_7c_2c);
const TEXT: Color = Color::WHITE;
const SHADOW: Color = Color::hex(0x1c_38_50);

// ── Art ─────────────────────────────────────────────────────────────────────
//
// Dimensions, transposition, pixel encoding and per-column opacity are all
// worked out at compile time. `.` is transparent because it is not in the
// palette.

sprite_sheet! {
    /// Three wing positions.
    const BIRD;
    palette: {
        'Y' => Color::hex(0xf8_d8_28), // body
        'O' => Color::hex(0xe0_78_10), // beak
        'k' => Color::hex(0x30_20_10), // eye
        'w' => Color::WHITE,           // wing highlight
    },
    frames: [
        [
            "..YYYY...",
            ".YYYYYYk.",
            "YwwYYYYYO",
            "YwwwYYYOO",
            "YwwYYYYYO",
            ".YYYYYYk.",
            "..YYYY...",
        ],
        [
            "..YYYY...",
            ".YYYYYYk.",
            "YYYYYYYYO",
            "wwwYYYYOO",
            "YYYYYYYYO",
            ".YYYYYYk.",
            "..YYYY...",
        ],
        [
            "..YYYY...",
            ".YYYYYYk.",
            "YYYYYYYYO",
            "YYYYYYYOO",
            "YwwYYYYYO",
            ".YwwYYYk.",
            "..YwYY...",
        ],
    ],
}

static FLAP_ANIM: Anim = Anim::new(0, 3, 3, true);

// The art has no interior holes, so every blit is a contiguous copy per column
// with no per-pixel transparency test. Compile-time check, so art edits that
// would slow the blit down cannot pass unnoticed.
const _: () = assert!(BIRD.takes_fast_path());

// Single-sourced from the art above rather than restated.
const BIRD_W: i32 = BIRD.tile_w() as i32;
const BIRD_H: i32 = BIRD.tile_h() as i32;

// ── Audio ───────────────────────────────────────────────────────────────────

static SFX_FLAP: Track = Track::once(&[Step::at(notes::G6, 2, 0.55)]);

static SFX_SCORE: Track = Track::once(&[Step::at(notes::C7, 3, 0.7), Step::at(notes::E7, 4, 0.7)]);

static SFX_CRASH: Track = Track::once(&[
    Step::at(notes::A5, 4, 0.9),
    Step::at(notes::F5, 5, 0.8),
    Step::at(notes::C5, 8, 0.7),
]);

// ── State ───────────────────────────────────────────────────────────────────

#[derive(Copy, Clone, PartialEq, Eq)]
enum Phase {
    Ready,
    Playing,
    Dead,
}

#[derive(Copy, Clone)]
struct Pipe {
    x: i32,
    /// Top of the gap.
    gap_y: i32,
    scored: bool,
}

impl Pipe {
    const INIT: Pipe = Pipe {
        x: 0,
        gap_y: 40,
        scored: false,
    };
}

struct Flappy {
    phase: Phase,
    y: f32,
    vy: f32,
    /// Sub-pixel scroll accumulator, so speed is not quantized to whole pixels.
    scroll: f32,
    pipes: [Pipe; PIPE_COUNT],
    anim: AnimState,
    score: u32,
    best: u32,
}

impl Cart for Flappy {
    const INIT: Self = Flappy {
        phase: Phase::Ready,
        y: 0.0,
        vy: 0.0,
        scroll: 0.0,
        pipes: [Pipe::INIT; PIPE_COUNT],
        anim: AnimState::NEW,
        score: 0,
        best: 0,
    };

    fn start(&mut self, c: &mut Ctx) {
        // Layout needs the RNG, so it belongs here rather than in `INIT`.
        self.reset(c);
        info!("flappy ready");
    }

    fn update(&mut self, c: &mut Ctx) {
        match self.phase {
            Phase::Ready => self.update_ready(c),
            Phase::Playing => self.update_playing(c),
            Phase::Dead => self.update_dead(c),
        }
        self.draw(c);
    }
}

impl Flappy {
    fn reset(&mut self, c: &mut Ctx) {
        self.y = (HEIGHT as f32) / 2.0 - BIRD_H as f32 / 2.0;
        self.vy = 0.0;
        self.scroll = 0.0;
        self.score = 0;
        self.anim.restart();
        for i in 0..PIPE_COUNT {
            self.pipes[i] = Pipe {
                x: WIDTH as i32 + 20 + i as i32 * PIPE_SPACING,
                gap_y: Self::random_gap(c),
                scored: false,
            };
        }
    }

    fn random_gap(c: &mut Ctx) -> i32 {
        c.rng.range(12, GROUND_Y - GAP_HEIGHT - 12)
    }

    fn flap_pressed(c: &Ctx) -> bool {
        c.input.just_pressed(Button::A) || c.input.just_pressed(Button::Up)
    }

    fn update_ready(&mut self, c: &mut Ctx) {
        // Idle bob so the screen is not static while waiting.
        self.y =
            (HEIGHT as f32) / 2.0 - BIRD_H as f32 / 2.0 + math::sin(c.frame() as f32 * 0.08) * 4.0;
        self.anim.advance(&FLAP_ANIM);
        if Self::flap_pressed(c) {
            self.phase = Phase::Playing;
            self.vy = FLAP_VELOCITY;
            c.audio.play_sfx(&SFX_FLAP);
        }
    }

    fn update_playing(&mut self, c: &mut Ctx) {
        if Self::flap_pressed(c) {
            self.vy = FLAP_VELOCITY;
            c.audio.play_sfx(&SFX_FLAP);
        }

        self.vy = (self.vy + GRAVITY).min(MAX_FALL);
        self.y += self.vy;
        self.anim.advance(&FLAP_ANIM);

        // Scroll pipes, recycling any that leave the screen.
        self.scroll += SCROLL_SPEED;
        let step = self.scroll as i32;
        self.scroll -= step as f32;
        for i in 0..PIPE_COUNT {
            self.pipes[i].x -= step;
            if self.pipes[i].x + PIPE_WIDTH < 0 {
                let furthest = self.furthest_pipe_x();
                self.pipes[i].x = furthest + PIPE_SPACING;
                self.pipes[i].gap_y = Self::random_gap(c);
                self.pipes[i].scored = false;
            }
        }

        for i in 0..PIPE_COUNT {
            if !self.pipes[i].scored && self.pipes[i].x + PIPE_WIDTH < BIRD_X {
                self.pipes[i].scored = true;
                self.score += 1;
                c.audio.play_sfx(&SFX_SCORE);
                info!("score {}", self.score);
            }
        }

        if self.collides() {
            self.die(c);
        }
    }

    fn update_dead(&mut self, c: &mut Ctx) {
        // Fall to the ground and stay there.
        if self.y < (GROUND_Y - BIRD_H) as f32 {
            self.vy = (self.vy + GRAVITY).min(MAX_FALL);
            self.y += self.vy;
        } else {
            self.y = (GROUND_Y - BIRD_H) as f32;
        }
        if c.input.just_pressed(Button::Start) || Self::flap_pressed(c) {
            self.reset(c);
            self.phase = Phase::Ready;
        }
    }

    fn die(&mut self, c: &mut Ctx) {
        self.phase = Phase::Dead;
        self.best = self.best.max(self.score);
        c.audio.play_sfx(&SFX_CRASH);
        c.leds.set_hex(2, 0xff_00_00);
        info!("died with {}", self.score);
    }

    fn furthest_pipe_x(&self) -> i32 {
        let mut max = 0;
        for p in &self.pipes {
            max = max.max(p.x);
        }
        max
    }

    fn collides(&self) -> bool {
        let top = self.y as i32;
        let bottom = top + BIRD_H;

        if bottom >= GROUND_Y || top < 0 {
            return true;
        }
        for p in &self.pipes {
            let overlaps_x = BIRD_X + BIRD_W > p.x && BIRD_X < p.x + PIPE_WIDTH;
            if overlaps_x && (top < p.gap_y || bottom > p.gap_y + GAP_HEIGHT) {
                return true;
            }
        }
        false
    }

    fn draw(&self, c: &mut Ctx) {
        let g = &mut c.gfx;
        g.clear(SKY);

        for p in &self.pipes {
            // Upper pipe, then lower, each with a darker inner edge. `fill_rect`
            // fills whole columns, which is the fast direction here.
            g.fill_rect(p.x, 0, PIPE_WIDTH as u32, p.gap_y as u32, PIPE);
            g.fill_rect(p.x + PIPE_WIDTH - 3, 0, 3, p.gap_y as u32, PIPE_DARK);

            let lower_y = p.gap_y + GAP_HEIGHT;
            let lower_h = (GROUND_Y - lower_y).max(0) as u32;
            g.fill_rect(p.x, lower_y, PIPE_WIDTH as u32, lower_h, PIPE);
            g.fill_rect(p.x + PIPE_WIDTH - 3, lower_y, 3, lower_h, PIPE_DARK);
        }

        g.fill_rect(
            0,
            GROUND_Y,
            WIDTH as u32,
            (HEIGHT as i32 - GROUND_Y) as u32,
            GROUND,
        );
        g.fill_rect(0, GROUND_Y, WIDTH as u32, 2, GROUND_EDGE);

        let tile = self.anim.tile(&FLAP_ANIM);
        // Tilt the sprite when diving: flip_y is a per-column reverse, so it is
        // just as cheap as the unflipped path.
        let flags = if self.vy > 2.0 {
            BlitFlags::FLIP_Y
        } else {
            BlitFlags::NONE
        };
        g.blit_with(&BIRD.tile(tile), BIRD_X, self.y as i32, flags);

        self.draw_hud(c);
    }

    fn draw_hud(&self, c: &mut Ctx) {
        center_text(c, uformat!(12, "{}", self.score), 4);

        match self.phase {
            Phase::Ready => center_text(c, "PRESS A", 96),
            Phase::Dead => {
                center_text(c, "GAME OVER", 88);
                center_text(c, uformat!(16, "BEST {}", self.best), 100);
            }
            Phase::Playing => {}
        }
    }
}

/// Centred text with a drop shadow.
///
/// Layout stays in the cart for now — the framework only measures.
fn center_text(c: &mut Ctx, s: impl AsRef<[u8]>, y: i32) {
    let s = s.as_ref();
    let x = (WIDTH as i32 - c.gfx.text_width(s, 1) as i32) / 2;
    c.gfx.text(s, x + 1, y + 1, SHADOW);
    c.gfx.text(s, x, y, TEXT);
}

sycl_cart::cart!(Flappy);
