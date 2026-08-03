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
const ORANGE: Color = Color::hex(0xff_b8_6c);
const PURPLE: Color = Color::hex(0xbd_93_f9);
const RED: Color = Color::hex(0xff_55_55);
const YELLOW: Color = Color::hex(0xf1_fa_8c);

// ── Layout ──────────────────────────────────────────────────────────────────

const PROMPT_Y: i32 = 88;
const DOTS_Y: i32 = 106;
const STATUS_Y: i32 = 118;

// ── Eye geometry ────────────────────────────────────────────────────────────
//
// Proportions follow a real eye rather than a cartoon one.
//
// The opening between the lids -- the palpebral fissure -- is roughly 2.7 times
// wider than it is tall, and it is an almond, not an ellipse: each lid is a
// circular arc through the two corners, which is what gives the pointed canthi.
// Its widest point sits slightly above centre, because the upper lid arcs higher
// than the lower one drops.
//
// The iris is deliberately *taller* than the opening, so the lids clip the top
// and bottom of it. A fully visible iris is most of why a drawn eye reads as a
// cartoon; a relaxed human eye always has some of it covered.
//
// Most importantly the eyeball is a sphere that rotates. The iris rides on its
// surface, so as it turns away from the viewer two things happen at once: the
// pupil's travel goes with the *sine* of the rotation, and the iris foreshortens
// by the cosine, narrowing into an ellipse. Sliding a fixed-size disc across a
// flat backdrop is the thing that looks wrong.

const EYE_CX: i32 = 80;
const EYE_CY: i32 = 50;

/// Half-width of the opening.
const OPEN_W: i32 = 34;
/// How far the upper lid arcs above centre, and the lower lid drops below it.
const LID_UP: f32 = 14.0;
const LID_DN: f32 = 11.0;

/// Eyeball radius. Sets both how far the pupil travels and how much it
/// foreshortens on the way, because both fall out of the same rotation.
const EYE_R: f32 = 30.0;
/// Largest sine of rotation per axis: about 33 degrees across and 17 up or down,
/// which is roughly where a real eye stops and the head takes over.
const MAX_SIN_X: f32 = 0.55;
const MAX_SIN_Y: f32 = 0.30;

/// Lid thickness. It follows the almond outward rather than being an ellipse
/// behind it, so the band stays even all the way round and tapers to nothing at
/// the canthi -- which is where the lids actually meet.
const LID_T: i32 = 3;

const IRIS_R: f32 = 12.0;
const PUPIL_R: f32 = 4.2;
/// Pupils dilate under threat, so the stare gets a wider one.
const PUPIL_R_ALARMED: f32 = 6.8;

// ── Art ─────────────────────────────────────────────────────────────────────
//
// The eye is drawn rather than blitted: it changes shape every frame, and the
// iris has to foreshorten, which no fixed sprite can do.
//
// The one sprite is the catchlight -- the corneal reflection of the light in the
// room. It tracks the corneal bulge, which follows the gaze at less than the
// iris's own travel, so it drifts across the iris as the eye turns rather than
// being glued to it. That detail sells the sphere more than anything else here.

sprite! {
    /// Corneal catchlight.
    const GLINT;
    palette: {
        'w' => Color::WHITE,
    },
    art: [
        ".ww.",
        "wwww",
        ".ww.",
    ],
}

const _: () = assert!(GLINT.takes_fast_path());

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
/// Rows the scan sweep travels, then how long until it starts again.
const SCAN_TRAVEL: i32 = 19;
const SCAN_PERIOD: i32 = 96;
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

    /// Gaze, blinking and the scan sweep, all independent of the test logic.
    fn animate(&mut self, c: &mut Ctx) {
        self.flash = self.flash.saturating_sub(1);
        self.stare = self.stare.saturating_sub(1);
        self.scan = (self.scan + 1) % SCAN_PERIOD;

        if self.stare > 0 {
            // Locked on. No wandering, no blinking.
            self.target = (0.0, 0.0);
            self.blink = 0;
            self.blink_timer = 30;
        } else {
            self.gaze_timer = self.gaze_timer.saturating_sub(1);
            if self.gaze_timer == 0 {
                self.target = (c.rng.unit() * 2.0 - 1.0, c.rng.unit() * 2.0 - 1.0);
                // Fixate for between a third of a second and two.
                self.gaze_timer = 20 + c.rng.below(100) as u16;
            } else {
                // Microsaccades: a fixating eye is never still, it drifts by a
                // fraction of a degree and twitches back.
                self.target.0 = (self.target.0 + (c.rng.unit() - 0.5) * 0.03).clamp(-1.0, 1.0);
                self.target.1 = (self.target.1 + (c.rng.unit() - 0.5) * 0.03).clamp(-1.0, 1.0);
            }

            if self.blink > 0 {
                self.blink -= 1;
            } else {
                self.blink_timer = self.blink_timer.saturating_sub(1);
                if self.blink_timer == 0 {
                    self.blink = BLINK_FRAMES;
                    // Humans blink every two to ten seconds.
                    self.blink_timer = 120 + c.rng.below(420) as u16;
                }
            }
        }

        // Eyes move in saccades: a ballistic jump of 30-80ms, then a hold. They
        // do not glide, and easing slowly is what makes a drawn eye look like a
        // puppet, so this is deliberately fast.
        let speed = 0.45;
        self.gaze.0 = math::lerp(self.gaze.0, self.target.0, speed);
        self.gaze.1 = math::lerp(self.gaze.1, self.target.1, speed);
    }

    /// Row the scan sweep is currently on, if it is sweeping at all.
    ///
    /// Confined to the middle of the opening: out near the canthi the almond is
    /// only a pixel or two tall, and a line clipped to that reads as a stray dot
    /// rather than a sweep.
    fn scan_y(&self) -> Option<i32> {
        (self.scan < SCAN_TRAVEL).then_some(EYE_CY - SCAN_TRAVEL / 2 + self.scan)
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

        self.draw_eye(c);
        self.draw_brackets(c);

        match self.phase {
            Phase::Intro => self.draw_intro(c),
            Phase::Test => self.draw_test(c),
            Phase::Done => self.draw_done(c),
        }
    }

    fn draw_eye(&self, c: &mut Ctx) {
        let alarmed = self.stare > 0;
        // Startled eyes widen; threatened pupils dilate.
        let widen = if alarmed { 1.16 } else { 1.0 };
        let closed = self.lid_closed();

        let sclera_lit = FG;
        let sclera_shade = FG.mix(COMMENT, 0.30);
        let lid_shadow = COMMENT.mix(BG, 0.30);
        let lash = BG.mix(Color::BLACK, 0.75);
        let iris_body = if alarmed { RED } else { CYAN };
        let iris_fibre = if alarmed { ORANGE } else { PURPLE };
        let limbus = iris_fibre.mix(BG, 0.55);
        let collarette = iris_body.mix(FG, 0.30);
        let scan = CYAN.mix(FG, 0.62);

        // Rotate the eyeball. Travel follows the sine of the angle; the iris
        // foreshortens by the cosine, which is sqrt(1 - sin^2).
        let sx = self.gaze.0 * MAX_SIN_X;
        let sy = self.gaze.1 * MAX_SIN_Y;
        let icx = EYE_CX as f32 + sx * EYE_R;
        let icy = EYE_CY as f32 + sy * EYE_R;
        let squash_x = math::sqrt(1.0 - sx * sx);
        let squash_y = math::sqrt(1.0 - sy * sy);
        let irx = IRIS_R * squash_x;
        let iry = IRIS_R * squash_y;
        let pupil = if alarmed { PUPIL_R_ALARMED } else { PUPIL_R };
        let prx = pupil * squash_x;
        let pry = pupil * squash_y;

        // One pass per column: every layer is a contiguous vertical fill, which
        // is the cheap direction here, and clipping the iris to the lid span
        // falls out for free.
        for dx in -OPEN_W..=OPEN_W {
            let x = EYE_CX + dx;
            if x < 0 || x >= WIDTH as i32 {
                continue;
            }
            let (topf, botf) = lid_span(dx, widen, closed);
            let top = topf as i32;
            let bot = botf as i32;
            if bot <= top {
                continue;
            }

            // Lid first, so the sclera paints over its inner edge and the two
            // meet without a seam. Offsetting the almond outward keeps the band
            // even all the way round, and it tapers to nothing at the canthi,
            // which is where the lids actually meet.
            fill_span(c, x, top - LID_T, bot + LID_T, CURRENT);

            // Sclera, shading gradually toward the corners where the lids
            // overhang it. A hard step here reads as a change of material rather
            // than a shadow, and leaves a visible seam.
            let edge = dx.abs() as f32 / OPEN_W as f32;
            let shade = ((edge - 0.55) / 0.45).clamp(0.0, 1.0);
            fill_span(c, x, top, bot, sclera_lit.mix(sclera_shade, shade));

            // Limbal ring, iris with radial fibres, collarette, pupil.
            ellipse_span(c, x, icx, icy, irx, iry, limbus, top, bot);
            let fibre = (x - icx as i32).rem_euclid(3) == 0;
            ellipse_span(
                c,
                x,
                icx,
                icy,
                irx - 1.5,
                iry - 1.5,
                if fibre { iris_fibre } else { iris_body },
                top,
                bot,
            );
            ellipse_span(c, x, icx, icy, prx + 1.3, pry + 1.3, collarette, top, bot);
            ellipse_span(c, x, icx, icy, prx, pry, Color::BLACK, top, bot);

            // Scan sweep, clipped to this column's opening. Drawn per column
            // rather than as one `hline` because the almond narrows toward the
            // corners and a straight line of fixed width pokes past the lids.
            if let Some(sy) = self.scan_y() {
                if sy >= top && sy < bot {
                    fill_span(c, x, sy, sy + 1, scan);
                }
            }

            // The upper lid casts a shadow on whatever is beneath it, and the
            // lash line above reads as the lid edge.
            fill_span(c, x, top, (top + 2).min(bot), lid_shadow);
            fill_span(c, x, top - 1, top, lash);
        }

        // Lashes: a graded fringe, shortest at the apex and longest in the outer
        // third, which is how a real one is distributed. The lid normal is nearly
        // vertical at the apex, so those lashes stand close to upright -- correct
        // for a front-on view, and short enough not to read as antennae.
        for &(dx, len) in &[
            (-29, 9),
            (-23, 11),
            (-17, 10),
            (-11, 7),
            (-5, 5),
            (5, 5),
            (11, 7),
            (17, 10),
            (23, 11),
            (29, 9),
        ] {
            let (topf, _) = lid_span(dx, widen, closed);
            // Shortened as the lid closes: the lashes rotate toward the viewer
            // and foreshorten, and it keeps them from standing up out of a shut
            // eye during a blink.
            let steps = (len as f32 * (1.0 - closed)) as u32;
            draw_lash(
                c,
                EYE_CX + dx,
                topf as i32 - LID_T + 1,
                lid_normal(dx, widen),
                steps,
                lash,
                lash.mix(BG, 0.3),
            );
        }

        // Catchlight last: a reflection off the cornea, so nothing occludes it.
        // It tracks the corneal bulge, which follows the gaze at a fraction of
        // the iris's travel, so it drifts across the iris as the eye turns
        // instead of being glued to it.
        // Tracks at 0.8 of the iris's travel, and sits close enough to the iris
        // centre to stay on it across the whole gaze range. On the white sclera a
        // white glint is invisible -- which is true of real eyes too, but it
        // would read here as the highlight blinking out.
        let gx = EYE_CX - 6 + (sx * EYE_R * 0.8) as i32;
        let gy = EYE_CY - 6 + (sy * EYE_R * 0.8) as i32;
        let (t, b) = lid_span(gx - EYE_CX, widen, closed);
        if (gy as f32) > t + 1.0 && ((gy + GLINT.h() as i32) as f32) < b {
            c.gfx.blit(&GLINT, gx, gy);
        }
    }

    /// HUD corner brackets around the eye.
    fn draw_brackets(&self, c: &mut Ctx) {
        let g = &mut c.gfx;
        let (l, r) = (EYE_CX - 50, EYE_CX + 50);
        let (t, b) = (EYE_CY - 28, EYE_CY + 26);
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

/// Top and bottom of the opening at a horizontal offset from centre.
///
/// Each lid is a circular arc through both corners and its own apex, which is
/// what produces an almond with pointed canthi. An ellipse would bulge at the
/// corners and read as a cartoon.
fn lid_span(dx: i32, widen: f32, closed: f32) -> (f32, f32) {
    let w = OPEN_W as f32;
    let dxf = dx as f32;
    // Circle through (-w, 0), (0, apex), (w, 0).
    let arc = |apex: f32| {
        let r = (w * w + apex * apex) / (2.0 * apex);
        math::sqrt((r * r - dxf * dxf).max(0.0)) - (r - apex)
    };
    let top = EYE_CY as f32 - arc(LID_UP * widen);
    let bot = EYE_CY as f32 + arc(LID_DN * widen);
    // A blink is mostly the upper lid: it travels four times as far as the lower.
    let span = bot - top;
    (top + closed * span * 0.8, bot - closed * span * 0.2)
}

/// How sharply a lash bends toward vertical per pixel of length.
const LASH_CURL: f32 = 0.17;
/// Lashes lie back rather than standing up, so they start flatter than the true
/// lid normal.
const LASH_SWEEP: f32 = 2.8;

fn normalize((x, y): (f32, f32)) -> (f32, f32) {
    let m = math::hypot(x, y);
    if m <= 0.0 {
        (0.0, -1.0)
    } else {
        (x / m, y / m)
    }
}

/// Walk a curled lash outward from the lid edge.
///
/// A lash leaves the lid along its normal and curls away from the eyeball, so the
/// tip is markedly more upright than the root. Rotating the direction toward
/// vertical at every step produces that hook; a straight line reads as a bristle.
/// The outer third is drawn dimmer, which at one pixel wide is the only way to
/// suggest a taper.
fn draw_lash(
    c: &mut Ctx,
    x0: i32,
    y0: i32,
    normal: (f32, f32),
    steps: u32,
    root: Color,
    tip: Color,
) {
    let mut dir = normalize((normal.0 * LASH_SWEEP, normal.1));
    let mut x = x0 as f32;
    let mut y = y0 as f32;
    for i in 0..steps {
        c.gfx.pixel(
            x as i32,
            y as i32,
            if i * 3 >= steps * 2 { tip } else { root },
        );
        x += dir.0 * 0.85;
        y += dir.1 * 0.85;
        // Bend toward straight up.
        dir = normalize((
            dir.0 * (1.0 - LASH_CURL),
            dir.1 * (1.0 - LASH_CURL) - LASH_CURL,
        ));
    }
}

/// Outward normal of the upper lid arc at a horizontal offset from centre.
///
/// The arc is part of a circle, so the normal is just the direction away from
/// that circle's centre: straight up at the apex, swinging out toward 45 degrees
/// by the corners, which is how a real fringe fans.
fn lid_normal(dx: i32, widen: f32) -> (f32, f32) {
    let w = OPEN_W as f32;
    let up = LID_UP * widen;
    let r = (w * w + up * up) / (2.0 * up);
    let dxf = dx as f32;
    (dxf / r, -math::sqrt((r * r - dxf * dxf).max(0.0)) / r)
}

/// One column of colour, clipped to `y0..y1`.
fn fill_span(c: &mut Ctx, x: i32, y0: i32, y1: i32, color: Color) {
    if y1 > y0 {
        c.gfx.vline(x, y0, (y1 - y0) as u32, color);
    }
}

/// The slice of an ellipse that falls in column `x`, clipped to the lid span.
#[allow(clippy::too_many_arguments)]
fn ellipse_span(
    c: &mut Ctx,
    x: i32,
    ecx: f32,
    ecy: f32,
    erx: f32,
    ery: f32,
    color: Color,
    top: i32,
    bot: i32,
) {
    if erx <= 0.0 || ery <= 0.0 {
        return;
    }
    let d = x as f32 - ecx;
    if d.abs() >= erx {
        return;
    }
    let t = d / erx;
    let half = ery * math::sqrt(1.0 - t * t);
    fill_span(
        c,
        x,
        ((ecy - half) as i32).max(top),
        ((ecy + half) as i32).min(bot),
        color,
    );
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
