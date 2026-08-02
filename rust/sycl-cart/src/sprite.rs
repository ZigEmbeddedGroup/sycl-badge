//! Sprites, sheets, and compile-time sprite authoring.
//!
//! Sprite pixels are stored **column-major and pre-encoded** for the active
//! target, which makes an unflipped opaque blit one `copy_from_slice` per
//! column. Row-major data would stride 256 bytes per pixel against the
//! column-major framebuffer — painful anywhere, and worse on the badge where
//! sprite bytes come from XIP flash through a cache.
//!
//! Multi-frame sheets store each tile contiguously (tile 0's columns, then tile
//! 1's, …) rather than as one atlas image, so slicing out a frame is free.

use crate::color::Color;

/// Optional per-blit transforms. Flips are cheap in this layout: `flip_y`
/// reverses within a column, `flip_x` reverses column order.
#[derive(Copy, Clone, PartialEq, Eq, Default, Debug)]
pub struct BlitFlags {
    pub flip_x: bool,
    pub flip_y: bool,
}

impl BlitFlags {
    pub const NONE: BlitFlags = BlitFlags {
        flip_x: false,
        flip_y: false,
    };
    pub const FLIP_X: BlitFlags = BlitFlags {
        flip_x: true,
        flip_y: false,
    };
    pub const FLIP_Y: BlitFlags = BlitFlags {
        flip_x: false,
        flip_y: true,
    };
    pub const FLIP_BOTH: BlitFlags = BlitFlags {
        flip_x: true,
        flip_y: true,
    };
}

/// A single image. `data` is `w * h` pre-encoded pixels, column-major.
///
/// `key` names a color that is skipped when blitting. `None` means the sprite is
/// fully opaque and takes the fast path.
#[derive(Copy, Clone)]
pub struct Sprite {
    pub data: &'static [u16],
    pub w: u16,
    pub h: u16,
    pub key: Option<Color>,
}

impl Sprite {
    /// Build a sprite from column-major, pre-encoded data.
    ///
    /// Panics at compile time when used in a `const` and the length is wrong.
    pub const fn new(data: &'static [u16], w: u16, h: u16, key: Option<Color>) -> Sprite {
        assert!(
            data.len() == w as usize * h as usize,
            "sprite data length != w * h"
        );
        Sprite { data, w, h, key }
    }
}

/// A strip of equally sized frames, stored one whole tile after another.
#[derive(Copy, Clone)]
pub struct SpriteSheet {
    pub data: &'static [u16],
    pub tile_w: u16,
    pub tile_h: u16,
    pub count: u16,
    pub key: Option<Color>,
}

impl SpriteSheet {
    pub const fn new(
        data: &'static [u16],
        tile_w: u16,
        tile_h: u16,
        count: u16,
        key: Option<Color>,
    ) -> SpriteSheet {
        assert!(
            data.len() == tile_w as usize * tile_h as usize * count as usize,
            "sheet data length != tile_w * tile_h * count"
        );
        SpriteSheet {
            data,
            tile_w,
            tile_h,
            count,
            key,
        }
    }

    /// Borrow one frame. Indices past the end wrap, so animation code cannot
    /// panic on an off-by-one.
    #[inline]
    pub fn tile(&self, index: u16) -> Sprite {
        let i = (index % self.count) as usize;
        let stride = self.tile_w as usize * self.tile_h as usize;
        Sprite {
            data: &self.data[i * stride..(i + 1) * stride],
            w: self.tile_w,
            h: self.tile_h,
            key: self.key,
        }
    }

    #[inline]
    pub const fn len(&self) -> u16 {
        self.count
    }

    #[inline]
    pub const fn is_empty(&self) -> bool {
        self.count == 0
    }
}

/// Build column-major, pre-encoded sprite data from ASCII art, at compile time.
///
/// `rows` is the image in reading order; `palette` maps characters to colors.
/// Characters not in the palette become `transparent`, which is also the color
/// you should pass as the sprite's `key`.
///
/// The const generic `N` must equal `width * height`; a mismatch is a
/// compile-time error. Until PNG import lands (`sycl-cart-build`), this is the
/// intended way to author art for small games.
///
/// ```
/// use sycl_cart::{ascii_sprite, Color, Sprite};
///
/// const KEY: Color = Color::MAGENTA;
/// const PAL: [(u8, Color); 2] = [(b'Y', Color::YELLOW), (b'k', Color::BLACK)];
/// static BIRD_DATA: [u16; 4 * 3] = ascii_sprite(
///     &["YYYY", "YkYY", "YYYY"],
///     &PAL,
///     KEY,
/// );
/// static BIRD: Sprite = Sprite::new(&BIRD_DATA, 4, 3, Some(KEY));
/// ```
pub const fn ascii_sprite<const N: usize>(
    rows: &[&str],
    palette: &[(u8, Color)],
    transparent: Color,
) -> [u16; N] {
    let h = rows.len();
    assert!(h > 0, "sprite needs at least one row");
    let w = rows[0].len();
    assert!(w > 0, "sprite needs at least one column");
    assert!(N == w * h, "sprite array length must equal width * height");

    let mut out = [transparent.0; N];
    let mut y = 0;
    while y < h {
        let row = rows[y].as_bytes();
        assert!(row.len() == w, "all sprite rows must be the same length");
        let mut x = 0;
        while x < w {
            let ch = row[x];
            let mut i = 0;
            while i < palette.len() {
                if palette[i].0 == ch {
                    // Transpose here: column-major destination.
                    out[x * h + y] = palette[i].1 .0;
                    break;
                }
                i += 1;
            }
            x += 1;
        }
        y += 1;
    }
    out
}

/// A frame-based animation over a [`SpriteSheet`].
#[derive(Copy, Clone)]
pub struct Anim {
    /// First tile index in the sheet.
    pub first: u16,
    /// Number of tiles in the animation.
    pub frames: u16,
    /// Frames of hold per animation step (1 = change every frame).
    pub ticks_per_frame: u16,
    pub looping: bool,
}

impl Anim {
    pub const fn new(first: u16, frames: u16, ticks_per_frame: u16, looping: bool) -> Anim {
        Anim {
            first,
            frames,
            ticks_per_frame,
            looping,
        }
    }
}

/// Playback position for an [`Anim`]. Keep one per animated entity.
#[derive(Copy, Clone, Default)]
pub struct AnimState {
    step: u16,
    tick: u16,
    finished: bool,
}

impl AnimState {
    pub const NEW: AnimState = AnimState {
        step: 0,
        tick: 0,
        finished: false,
    };

    /// Restart from the beginning.
    #[inline]
    pub fn restart(&mut self) {
        *self = AnimState::NEW;
    }

    /// Advance by one frame. Call once per frame per entity.
    pub fn advance(&mut self, anim: &Anim) {
        if self.finished || anim.frames == 0 {
            return;
        }
        self.tick += 1;
        if self.tick >= anim.ticks_per_frame.max(1) {
            self.tick = 0;
            self.step += 1;
            if self.step >= anim.frames {
                if anim.looping {
                    self.step = 0;
                } else {
                    self.step = anim.frames - 1;
                    self.finished = true;
                }
            }
        }
    }

    /// The sheet tile index to draw.
    #[inline]
    pub fn tile(&self, anim: &Anim) -> u16 {
        anim.first + self.step
    }

    /// True once a non-looping animation has reached its last frame.
    #[inline]
    pub fn finished(&self) -> bool {
        self.finished
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: Color = Color::MAGENTA;
    const PAL: [(u8, Color); 2] = [(b'R', Color::RED), (b'G', Color::GREEN)];

    // 3 wide, 2 tall.
    static DATA: [u16; 6] = ascii_sprite(&["RG.", ".GR"], &PAL, KEY);

    #[test]
    fn ascii_art_is_transposed_to_column_major() {
        // Column 0 = (R, key), column 1 = (G, G), column 2 = (key, R).
        assert_eq!(DATA[0], Color::RED.0);
        assert_eq!(DATA[1], KEY.0);
        assert_eq!(DATA[2], Color::GREEN.0);
        assert_eq!(DATA[3], Color::GREEN.0);
        assert_eq!(DATA[4], KEY.0);
        assert_eq!(DATA[5], Color::RED.0);
    }

    #[test]
    fn sheet_slices_whole_tiles() {
        static SHEET_DATA: [u16; 8] = [1, 2, 3, 4, 5, 6, 7, 8];
        let sheet = SpriteSheet::new(&SHEET_DATA, 2, 2, 2, None);
        assert_eq!(sheet.tile(0).data, &[1, 2, 3, 4]);
        assert_eq!(sheet.tile(1).data, &[5, 6, 7, 8]);
        assert_eq!(sheet.tile(2).data, &[1, 2, 3, 4], "index wraps");
    }

    #[test]
    fn anim_holds_then_loops() {
        let anim = Anim::new(0, 3, 2, true);
        let mut s = AnimState::NEW;
        assert_eq!(s.tile(&anim), 0);
        s.advance(&anim);
        assert_eq!(s.tile(&anim), 0, "held for ticks_per_frame");
        s.advance(&anim);
        assert_eq!(s.tile(&anim), 1);
        for _ in 0..4 {
            s.advance(&anim);
        }
        assert_eq!(s.tile(&anim), 0, "wrapped");
        assert!(!s.finished());
    }

    #[test]
    fn anim_clamps_when_not_looping() {
        let anim = Anim::new(5, 2, 1, false);
        let mut s = AnimState::NEW;
        for _ in 0..10 {
            s.advance(&anim);
        }
        assert_eq!(s.tile(&anim), 6);
        assert!(s.finished());
    }
}
