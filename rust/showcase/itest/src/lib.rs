//! `itest` — an interactive hardware test that looks back at you.
//!
//! A cyberpunk eye sits in the middle of the screen, glancing around and
//! blinking, while the cart walks you through every input on the badge. Press
//! the one it asks for and the screen flashes white with a chirp. Press the
//! wrong one and it flashes red, the eye snaps round to stare straight at you,
//! and the tone is decidedly less pleased.
//!
//! The point is to confirm all nine inputs work — the four joystick directions,
//! the joystick click, A, B, Start and Select — without it feeling like a
//! diagnostic.
//!
//! Two things to know when running this on real hardware:
//!
//! * The joystick **click** also toggles the OS FPS overlay, every time. That is
//!   the kernel's doing and a cart cannot suppress it, so expect the overlay to
//!   appear when you pass that step.
//! * Holding **Start and Select together** for half a second quits to the menu.
//!   The prompts never ask for both at once, but do not go looking for trouble.

#![no_std]

use sycl_cart::audio::notes::*;
use sycl_cart::prelude::*;
use sycl_cart::{math, Track};

// ── Dracula ─────────────────────────────────────────────────────────────────

const BG: Color = Color::hex(0x28_2a_36);
const CURRENT: Color = Color::hex(0x44_47_5a);
const FG: Color = Color::hex(0xf8_f8_f2);
const COMMENT: Color = Color::hex(0x62_72_a4);
const CYAN: Color = Color::hex(0x8b_e9_fd);
const GREEN: Color = Color::hex(0x50_fa_7b);
const PINK: Color = Color::hex(0xff_79_c6);
const PURPLE: Color = Color::hex(0xbd_93_f9);
const RED: Color = Color::hex(0xff_55_55);
const YELLOW: Color = Color::hex(0xf1_fa_8c);

// ── Layout ──────────────────────────────────────────────────────────────────

const EYE_CX: i32 = 80;
const EYE_CY: i32 = 46;
const SCLERA_RX: u32 = 44;
const SCLERA_RY: u32 = 26;
const RIM: u32 = 3;

/// How far the iris centre may stray from the middle, in pixels.
const GAZE_X: f32 = 24.0;
const GAZE_Y: f32 = 11.0;

const PROMPT_Y: i32 = 88;
const DOTS_Y: i32 = 106;
const STATUS_Y: i32 = 118;

// ── Art ─────────────────────────────────────────────────────────────────────
//
// The sclera and eyelids are drawn with ellipses and rectangles, because they
// have to move every frame. Only the iris is a sprite: it is the detailed part,
// and blitting it at an offset is what makes the gaze smooth.
//
// Frame 0 is the calm iris, frame 1 the alarmed one it wears while staring you
// down after a wrong answer.

sprite_sheet! {
    /// Calm iris, then alarmed iris.
    const IRIS;
    palette: {
        'c' => CYAN,
        'p' => PURPLE,
        'k' => Color::BLACK,
        'w' => FG,
        'r' => RED,
        'o' => Color::hex(0xff_b8_6c), // Dracula orange
    },
    frames: [
        [
            ".......c.......",
            "....ccccccc....",
            "...ccpppppcc...",
            "..ccpppppppcc..",
            ".ccppwwkkkppcc.",
            "ccppwwkkkkkppcc",
            "ccpppkkkkkkppcc",
            "ccpppkkkkkkppcc",
            "ccpppkkkkkkppcc",
            "ccpppkkkkkkppcc",
            ".ccpppkkkkppcc.",
            "..ccpppppppcc..",
            "...ccpppppcc...",
            "....ccccccc....",
            ".......c.......",
        ],
        [
            ".......r.......",
            "....rrrrrrr....",
            "...rrooooorr...",
            "..rrooooooorr..",
            ".rrookkkkkoorr.",
            "rrookkkkkkkoorr",
            "rrookkkkkkkoorr",
            "rrookkkkkkkoorr",
            "rrookkkkkkkoorr",
            "rrookkkkkkkoorr",
            ".rrookkkkkoorr.",
            "..rrooooooorr..",
            "...rrooooorr...",
            "....rrrrrrr....",
            ".......r.......",
        ],
    ],
}

// Transparent corners only, no interior holes, so every blit is a contiguous
// copy per column.
const _: () = assert!(IRIS.takes_fast_path());

const IRIS_HALF: i32 = IRIS.tile_w() as i32 / 2;

// ── Audio ───────────────────────────────────────────────────────────────────

/// Soft haunted-house loop: a minor rise, a chromatic descent, then a tritone
/// sting. Kept in octaves 5 and 6 so it carries on the badge's buzzer, and quiet
/// enough to sit under the sound effects.
static HAUNT: Track = Track::looping(&[
    Step::at(A5, 16, 0.16),
    Step::rest(4),
    Step::at(C6, 16, 0.16),
    Step::rest(4),
    Step::at(E6, 16, 0.16),
    Step::rest(4),
    Step::at(F6, 20, 0.18),
    Step::rest(8),
    // The creepy bit: walking down a semitone at a time.
    Step::at(E6, 14, 0.16),
    Step::rest(2),
    Step::at(DS6, 14, 0.16),
    Step::rest(2),
    Step::at(D6, 14, 0.16),
    Step::rest(2),
    Step::at(CS6, 18, 0.18),
    Step::rest(6),
    Step::at(A5, 24, 0.14),
    Step::rest(6),
    Step::at(GS5, 28, 0.14),
    Step::rest(18),
    // Tritone against the A, then let the room breathe.
    Step::at(DS6, 10, 0.20),
    Step::rest(2),
    Step::at(A5, 22, 0.14),
    Step::rest(28),
]);

static SFX_RIGHT: Track = Track::once(&[Step::at(E7, 3, 0.55), Step::at(A7, 6, 0.5)]);

/// Descending tritone. Unpleasant on purpose, and high enough to be audible on
/// the buzzer rather than merely felt.
static SFX_WRONG: Track = Track::once(&[
    Step::at(B6, 4, 0.7),
    Step::at(F6, 6, 0.7),
    Step::at(B5, 14, 0.6),
]);

static SFX_DONE: Track = Track::once(&[
    Step::at(C7, 4, 0.5),
    Step::at(E7, 4, 0.5),
    Step::at(G7, 4, 0.5),
    Step::at(C7, 12, 0.55),
]);

// ── Prompts ─────────────────────────────────────────────────────────────────

const STEPS: usize = 9;

/// Every input, with the label to show and the direction the eye glances when
/// you get it right.
const PROMPTS: [(Button, &str, (f32, f32)); STEPS] = [
    (Button::Up, "UP", (0.0, -1.0)),
    (Button::Down, "DOWN", (0.0, 1.0)),
    (Button::Left, "LEFT", (-1.0, 0.0)),
    (Button::Right, "RIGHT", (1.0, 0.0)),
    (Button::Click, "CLICK", (0.0, 0.0)),
    (Button::A, "A", (0.6, 0.5)),
    (Button::B, "B", (-0.6, 0.5)),
    (Button::Start, "START", (0.8, -0.4)),
    (Button::Select, "SELECT", (-0.8, -0.4)),
];

// ── State ───────────────────────────────────────────────────────────────────

#[derive(Copy, Clone, PartialEq, Eq)]
enum Phase {
    Intro,
    Test,
    Done,
}

struct ITest {
    phase: Phase,
    /// Indices into `PROMPTS`, shuffled so the order differs each run.
    order: [u8; STEPS],
    step: u8,
    /// Bit per prompt index that has been passed.
    passed: u16,
    mistakes: u32,
    gaze: (f32, f32),
    target: (f32, f32),
    gaze_timer: u16,
    /// Counts down through a blink; 0 means eyes open.
    blink: u16,
    blink_timer: u16,
    /// Frames left glaring at the player after a wrong answer.
    stare: u16,
    flash: u16,
    flash_color: Color,
    intro: u16,
    scan: i32,
}

const FLASH_FRAMES: u16 = 5;
const BLINK_FRAMES: u16 = 10;
const STARE_FRAMES: u16 = 50;
const INTRO_FRAMES: u16 = 130;

impl Cart for ITest {
    const INIT: Self = ITest {
        phase: Phase::Intro,
        order: [0, 1, 2, 3, 4, 5, 6, 7, 8],
        step: 0,
        passed: 0,
        mistakes: 0,
        gaze: (0.0, 0.0),
        target: (0.0, 0.0),
        gaze_timer: 0,
        blink: 0,
        blink_timer: 40,
        stare: 0,
        flash: 0,
        flash_color: FG,
        intro: INTRO_FRAMES,
        scan: 0,
    };

    fn start(&mut self, c: &mut Ctx) {
        self.shuffle(c);
        c.audio.set_volume(0.7);
        c.audio.play_music(&HAUNT);
        info!("itest: {} inputs to check", STEPS as u32);
    }

    fn update(&mut self, c: &mut Ctx) {
        self.animate(c);

        match self.phase {
            Phase::Intro => {
                self.intro = self.intro.saturating_sub(1);
                if self.intro == 0 || any_press(c) {
                    self.phase = Phase::Test;
                }
            }
            Phase::Test => self.check_input(c),
            Phase::Done => {
                if c.input.just_pressed(Button::Start) {
                    self.restart(c);
                }
            }
        }

        self.draw(c);
    }
}

impl ITest {
    fn shuffle(&mut self, c: &mut Ctx) {
        // Fisher-Yates over a fixed array: no allocation, every input still used.
        let mut i = STEPS - 1;
        while i > 0 {
            let j = c.rng.below(i as u32 + 1) as usize;
            self.order.swap(i, j);
            i -= 1;
        }
    }

    fn restart(&mut self, c: &mut Ctx) {
        self.step = 0;
        self.passed = 0;
        self.mistakes = 0;
        self.phase = Phase::Test;
        self.shuffle(c);
        c.audio.play_music(&HAUNT);
    }

    fn expected(&self) -> (Button, &'static str, (f32, f32)) {
        PROMPTS[self.order[self.step as usize] as usize]
    }

    fn check_input(&mut self, c: &mut Ctx) {
        let (want, _, glance) = self.expected();
        for (index, (button, _, _)) in PROMPTS.iter().enumerate() {
            if !c.input.just_pressed(*button) {
                continue;
            }
            if *button == want {
                self.passed |= 1 << self.order[self.step as usize];
                self.flash(FG);
                c.audio.play_sfx(&SFX_RIGHT);
                // A glance in the direction you just pressed, as acknowledgement.
                self.target = glance;
                self.gaze_timer = 30;
                self.step += 1;
                if self.step as usize == STEPS {
                    self.phase = Phase::Done;
                    c.audio.stop_music();
                    c.audio.play_sfx(&SFX_DONE);
                    info!("itest: complete, {} mistakes", self.mistakes);
                }
            } else {
                self.mistakes += 1;
                self.flash(RED);
                self.stare = STARE_FRAMES;
                c.audio.play_sfx(&SFX_WRONG);
                info!("itest: wanted {} got index {}", want as u32, index as u32);
            }
            break;
        }
    }

    fn flash(&mut self, color: Color) {
        self.flash = FLASH_FRAMES;
        self.flash_color = color;
    }

    /// Gaze, blinking and the scan line, all independent of the test logic.
    fn animate(&mut self, c: &mut Ctx) {
        self.flash = self.flash.saturating_sub(1);
        self.stare = self.stare.saturating_sub(1);
        self.scan = (self.scan + 1) % (SCLERA_RY as i32 * 2 + 24);

        if self.stare > 0 {
            // Locked on. No wandering, no blinking.
            self.target = (0.0, 0.0);
            self.blink = 0;
            self.blink_timer = 30;
        } else {
            self.gaze_timer = self.gaze_timer.saturating_sub(1);
            if self.gaze_timer == 0 {
                self.target = (c.rng.unit() * 2.0 - 1.0, c.rng.unit() * 2.0 - 1.0);
                // Hold a new direction for between a third of a second and two.
                self.gaze_timer = 20 + c.rng.below(100) as u16;
            }

            if self.blink > 0 {
                self.blink -= 1;
            } else {
                self.blink_timer = self.blink_timer.saturating_sub(1);
                if self.blink_timer == 0 {
                    self.blink = BLINK_FRAMES;
                    self.blink_timer = 90 + c.rng.below(180) as u16;
                }
            }
        }

        // Ease toward the target so the eye never snaps.
        let speed = if self.stare > 0 { 0.22 } else { 0.06 };
        self.gaze.0 = math::lerp(self.gaze.0, self.target.0, speed);
        self.gaze.1 = math::lerp(self.gaze.1, self.target.1, speed);
    }

    /// 0.0 fully open, 1.0 fully shut.
    fn lid_closed(&self) -> f32 {
        if self.blink == 0 {
            return 0.0;
        }
        // Down and back up over the blink.
        let half = BLINK_FRAMES as f32 / 2.0;
        let t = self.blink as f32;
        let progress = if t > half {
            (BLINK_FRAMES as f32 - t) / half
        } else {
            t / half
        };
        progress.clamp(0.0, 1.0)
    }

    fn draw(&self, c: &mut Ctx) {
        // A hard flash reads better than a fade we cannot alpha-blend, so the
        // first frames are the flash colour outright and the tail is a mix.
        if self.flash > FLASH_FRAMES - 2 {
            c.gfx.clear(self.flash_color);
            return;
        }
        let bg = if self.flash > 0 {
            BG.mix(self.flash_color, self.flash as f32 / FLASH_FRAMES as f32)
        } else {
            BG
        };
        c.gfx.clear(bg);

        self.draw_eye(c, bg);
        self.draw_brackets(c);

        match self.phase {
            Phase::Intro => self.draw_intro(c),
            Phase::Test => self.draw_test(c),
            Phase::Done => self.draw_done(c),
        }
    }

    fn draw_eye(&self, c: &mut Ctx, bg: Color) {
        let g = &mut c.gfx;

        // Rim, then sclera inside it.
        let rim = if self.stare > 0 { RED } else { PURPLE };
        g.fill_ellipse(EYE_CX, EYE_CY, SCLERA_RX + RIM, SCLERA_RY + RIM, rim);
        g.fill_ellipse(EYE_CX, EYE_CY, SCLERA_RX, SCLERA_RY, CURRENT);

        // Iris, offset by the gaze.
        let ix = EYE_CX + (self.gaze.0 * GAZE_X) as i32 - IRIS_HALF;
        let iy = EYE_CY + (self.gaze.1 * GAZE_Y) as i32 - IRIS_HALF;
        let frame = if self.stare > 0 { 1 } else { 0 };
        g.blit(&IRIS.tile(frame), ix, iy);

        // Eyelids: two rectangles closing over the eye from top and bottom.
        let closed = self.lid_closed();
        if closed > 0.0 {
            let reach = (closed * (SCLERA_RY + RIM) as f32) as i32;
            if reach > 0 {
                let span = (SCLERA_RX + RIM) * 2 + 1;
                let left = EYE_CX - (SCLERA_RX + RIM) as i32;
                let top = EYE_CY - (SCLERA_RY + RIM) as i32;
                g.fill_rect(left, top, span, reach as u32, bg);
                g.fill_rect(
                    left,
                    EYE_CY + (SCLERA_RY + RIM) as i32 - reach,
                    span,
                    reach as u32,
                    bg,
                );
            }
        }

        // A single scan line sweeping down the eye. Cheap and unmistakably
        // cyberpunk. `hline` is the slow direction here, but one line is nothing.
        let scan_y = EYE_CY - (SCLERA_RY as i32 + 12) + self.scan;
        if (scan_y - EYE_CY).abs() < SCLERA_RY as i32 {
            let t = 1.0 - (scan_y - EYE_CY).abs() as f32 / SCLERA_RY as f32;
            let width = (SCLERA_RX as f32 * 2.0 * t) as u32;
            g.hline(
                EYE_CX - width as i32 / 2,
                scan_y,
                width,
                CYAN.mix(CURRENT, 0.55),
            );
        }
    }

    /// HUD corner brackets around the eye.
    fn draw_brackets(&self, c: &mut Ctx) {
        let g = &mut c.gfx;
        let (l, r) = (EYE_CX - 66, EYE_CX + 66);
        let (t, b) = (EYE_CY - 38, EYE_CY + 38);
        let len = 9;
        for &(x, dx) in &[(l, 1i32), (r, -1i32)] {
            for &(y, dy) in &[(t, 1i32), (b, -1i32)] {
                g.hline(if dx > 0 { x } else { x - len + 1 }, y, len as u32, COMMENT);
                g.vline(x, if dy > 0 { y } else { y - len + 1 }, len as u32, COMMENT);
            }
        }
    }

    fn draw_intro(&self, c: &mut Ctx) {
        center_text(c, "I T E S T", PROMPT_Y, CYAN);
        center_text(c, "HARDWARE EYE EXAM", PROMPT_Y + 12, COMMENT);
        if (self.intro / 20).is_multiple_of(2) {
            center_text(c, "LOOK ALIVE", STATUS_Y, PINK);
        }
    }

    fn draw_test(&self, c: &mut Ctx) {
        let (_, label, _) = self.expected();
        center_text(c, "PRESS", PROMPT_Y - 10, COMMENT);
        center_text(
            c,
            label,
            PROMPT_Y + 2,
            if self.stare > 0 { RED } else { YELLOW },
        );
        self.draw_dots(c);

        let status = uformat!(
            24,
            "{}/{}  ERR {}",
            self.step as u32,
            STEPS as u32,
            self.mistakes
        );
        center_text(c, status, STATUS_Y, COMMENT);
    }

    fn draw_done(&self, c: &mut Ctx) {
        let ok = self.mistakes == 0;
        center_text(
            c,
            "ALL INPUTS OK",
            PROMPT_Y,
            if ok { GREEN } else { YELLOW },
        );
        self.draw_dots(c);
        let status = uformat!(24, "ERR {}  START=AGAIN", self.mistakes);
        center_text(c, status, STATUS_Y, COMMENT);
    }

    /// One pip per input: filled once passed, hollow until then.
    fn draw_dots(&self, c: &mut Ctx) {
        let pitch = 11;
        let total = STEPS as i32 * pitch - 3;
        let x0 = (WIDTH as i32 - total) / 2;
        for i in 0..STEPS {
            let x = x0 + i as i32 * pitch;
            let done = self.passed & (1 << self.order[i]) != 0;
            let current = self.phase == Phase::Test && i == self.step as usize;
            let color = if done {
                GREEN
            } else if current {
                YELLOW
            } else {
                CURRENT
            };
            if done || current {
                c.gfx.fill_rect(x, DOTS_Y, 8, 6, color);
            } else {
                c.gfx.stroke_rect(x, DOTS_Y, 8, 6, color);
            }
        }
    }
}

fn any_press(c: &Ctx) -> bool {
    PROMPTS.iter().any(|(b, _, _)| c.input.just_pressed(*b))
}

/// Centred text. Layout lives in the cart; the framework only measures.
fn center_text(c: &mut Ctx, s: impl AsRef<[u8]>, y: i32, color: Color) {
    let s = s.as_ref();
    let x = (WIDTH as i32 - c.gfx.text_width(s, 1) as i32) / 2;
    c.gfx.text(s, x, y, color);
}

sycl_cart::cart!(ITest);
