//! A test pattern for judging the display, because "washed out" is not a number
//! anyone can act on.
//!
//! Each mode asks one question you can answer by looking and report back as a
//! figure. What the answers separate:
//!
//! * **Backlight too strong for the panel's contrast.** Patch 0 looks grey
//!   rather than black, the darkest few patches are hard to tell apart, and the
//!   ramp is otherwise even. Whites are fierce. The fix is dimming GPIO16, which
//!   drives the panel's LED cathodes.
//! * **Gamma set wrong.** The ramp is uneven — a run of patches that look
//!   identical and then a jump — while black is still properly black. The fix is
//!   in the OS's panel init, in `src/os/drivers/lcd.zig`. Note that this panel
//!   ignores the `GMCTRP1`/`GMCTRN1` gamma tables entirely; `GAMSET` and VCOM are
//!   the controls it responds to.
//!
//! The two want different fixes, which is why it is worth ten seconds of
//! counting patches before changing anything.
//!
//! A steps through the modes, B goes back.

#![no_std]
#![no_main]

use sycl_cart::info;
use sycl_cart::prelude::*;

/// RGB565 gives green one bit more than red and blue, so a neutral grey at
/// 5-bit level `l` is exactly `(l, 2l, l)`. No rounding, nothing to explain away
/// if a patch looks off-colour.
const fn grey(level: u8) -> Color {
    Color::new(level, level * 2, level)
}

const HEX: &[u8; 16] = b"0123456789ABCDEF";

const MODES: i32 = 4;

struct Levels {
    mode: i32,
    dirty: bool,
}

impl Cart for Levels {
    const INIT: Self = Levels {
        mode: 0,
        dirty: true,
    };

    fn start(&mut self, _c: &mut Ctx) {
        info!("levels: dark, ramp, rgb, contrast");
    }

    fn update(&mut self, c: &mut Ctx) {
        let step =
            i32::from(c.input.just_pressed(Button::A)) - i32::from(c.input.just_pressed(Button::B));
        if step != 0 {
            self.mode = (self.mode + step).rem_euclid(MODES);
            self.dirty = true;
        }
        if !self.dirty {
            return;
        }
        self.dirty = false;

        c.gfx.clear(Color::BLACK);
        match self.mode {
            0 => self.dark(c),
            1 => self.ramp(c),
            2 => self.rgb(c),
            _ => self.contrast(c),
        }
    }
}

/// Patches across the full width, with a hex label under each.
fn strip(c: &mut Ctx, y: i32, h: u32, n: i32, color: impl Fn(i32) -> Color) {
    let w = WIDTH as i32 / n;
    for i in 0..n {
        c.gfx.fill_rect(i * w, y, w as u32, h, color(i));
        // Labels go on black below the patches, so they stay readable no matter
        // how dark or bright the patch above them is.
        let label = [HEX[i as usize & 0xf]];
        c.gfx.text_with(
            label,
            i * w + (w - 8) / 2,
            y + h as i32 + 2,
            1,
            Color::WHITE,
            Some(Color::BLACK),
        );
    }
}

fn title(c: &mut Ctx, s: &[u8]) {
    c.gfx.text_with(s, 2, 2, 1, Color::CYAN, Some(Color::BLACK));
}

impl Levels {
    /// The bottom eight levels, large. The question: counting up from 0, which
    /// is the first patch you can tell apart from the one before it?
    fn dark(&self, c: &mut Ctx) {
        title(c, b"DARK 0-7");
        strip(c, 16, 76, 8, |i| grey(i as u8));
        c.gfx.text_with(
            b"first patch you can\ntell from 0?",
            2,
            106,
            1,
            Color::hex(0x8090a0),
            Some(Color::BLACK),
        );
    }

    /// The whole range in sixteen steps. The question: is it even, or does it
    /// stall somewhere and then jump?
    fn ramp(&self, c: &mut Ctx) {
        title(c, b"RAMP 0-F");
        strip(c, 16, 76, 16, |i| grey((i * 2) as u8));
        c.gfx.text_with(
            b"even steps, or a\nstall then a jump?",
            2,
            106,
            1,
            Color::hex(0x8090a0),
            Some(Color::BLACK),
        );
    }

    /// One channel at a time, in case only one of them is misbehaving.
    fn rgb(&self, c: &mut Ctx) {
        title(c, b"RGB");
        let rows: [(i32, fn(u8) -> Color); 3] = [
            (14, |l| Color::new(l, 0, 0)),
            (48, |l| Color::new(0, l * 2, 0)),
            (82, |l| Color::new(0, 0, l)),
        ];
        for (y, make) in rows {
            let w = WIDTH as i32 / 8;
            for i in 0..8 {
                c.gfx
                    .fill_rect(i * w, y, w as u32, 30, make((i * 4 + 3) as u8));
            }
        }
    }

    /// Black against white, with nothing else on screen. The question: does the
    /// black half look black, or grey?
    fn contrast(&self, c: &mut Ctx) {
        let half = WIDTH as i32 / 2;
        c.gfx
            .fill_rect(0, 0, half as u32, HEIGHT as u32, Color::BLACK);
        c.gfx
            .fill_rect(half, 0, half as u32, HEIGHT as u32, Color::WHITE);
        c.gfx
            .text_with(b"BLACK", 8, 4, 1, Color::WHITE, Some(Color::BLACK));
        c.gfx
            .text_with(b"WHITE", half + 8, 4, 1, Color::BLACK, Some(Color::WHITE));
    }
}

sycl_cart::cart!(Levels);
