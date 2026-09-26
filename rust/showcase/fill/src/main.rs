//! The first thing to run on real hardware: solid fills in known colours.
//!
//! Everything here is chosen to make one specific failure legible. The badge
//! and the simulator encode a pixel differently — byte-swapped RGB565 in the
//! simulator, plain BGR565 on the badge — and getting that wrong swaps red and
//! blue. A photo of a game does not tell you which of the two you are looking
//! at; a screen that says RED while showing blue does.
//!
//! So each mode names the colour it is drawing. Read the label, look at the
//! screen, and the encoding is either right or it is not.
//!
//! * A / B — next and previous mode.
//! * Left / Right — also next and previous, for a badge with a stiff button.
//!
//! Modes: three labelled bands, then solid red, green, blue, white and black.

#![no_std]
#![no_main]

use sycl_cart::info;
use sycl_cart::prelude::*;

/// A colour, and the name the screen claims it is.
struct Named {
    name: &'static [u8],
    color: Color,
}

const RED: Named = Named {
    name: b"RED",
    color: Color::RED,
};
const GREEN: Named = Named {
    name: b"GREEN",
    color: Color::GREEN,
};
const BLUE: Named = Named {
    name: b"BLUE",
    color: Color::BLUE,
};
const WHITE: Named = Named {
    name: b"WHITE",
    color: Color::WHITE,
};
const BLACK: Named = Named {
    name: b"BLACK",
    color: Color::BLACK,
};

/// Mode 0 is the band view; the rest are solid fills of `SOLIDS[mode - 1]`.
const SOLIDS: [Named; 5] = [RED, GREEN, BLUE, WHITE, BLACK];
const MODES: i32 = 1 + SOLIDS.len() as i32;

struct Fill {
    mode: i32,
    /// Redraw only when something changed. A solid fill every frame would work,
    /// but then a wedged `present` would look exactly like a working one.
    dirty: bool,
}

impl Cart for Fill {
    const INIT: Self = Fill {
        mode: 0,
        dirty: true,
    };

    fn start(&mut self, _c: &mut Ctx) {
        info!("fill: bands, then red green blue white black");
    }

    fn update(&mut self, c: &mut Ctx) {
        let step =
            i32::from(c.input.just_pressed(Button::A) || c.input.just_pressed(Button::Right))
                - i32::from(c.input.just_pressed(Button::B) || c.input.just_pressed(Button::Left));
        if step != 0 {
            self.mode = (self.mode + step).rem_euclid(MODES);
            self.dirty = true;
            info!("mode {}", self.mode);
        }

        if !self.dirty {
            return;
        }
        self.dirty = false;

        if self.mode == 0 {
            self.draw_bands(c);
        } else {
            self.draw_solid(c, &SOLIDS[self.mode as usize - 1]);
        }
    }
}

impl Fill {
    /// Three vertical bands, each labelled. The label sits on black so it stays
    /// readable whatever the band is doing.
    fn draw_bands(&self, c: &mut Ctx) {
        let band = WIDTH as i32 / 3;
        for (i, named) in [RED, GREEN, BLUE].iter().enumerate() {
            let x = band * i as i32;
            // The last band takes the remainder, so no seam of stale pixels is
            // left at the right edge when the width does not divide by three.
            let w = if i == 2 { WIDTH as i32 - x } else { band };
            c.gfx.fill_rect(x, 0, w as u32, HEIGHT as u32, named.color);
            c.gfx
                .text_with(named.name, x + 2, 4, 1, Color::WHITE, Some(Color::BLACK));
        }
    }

    /// One colour edge to edge, named in the middle.
    fn draw_solid(&self, c: &mut Ctx, named: &Named) {
        c.gfx.clear(named.color);

        // White on black, except on white — where it would vanish.
        let (fg, bg) = if named.color == Color::WHITE {
            (Color::BLACK, Color::WHITE)
        } else {
            (Color::WHITE, Color::BLACK)
        };
        let scale = 2;
        let w = c.gfx.text_width(named.name, scale) as i32;
        let x = (WIDTH as i32 - w) / 2;
        c.gfx
            .text_with(named.name, x, HEIGHT as i32 / 2 - 4, scale, fg, Some(bg));
    }
}

sycl_cart::cart!(Fill);
