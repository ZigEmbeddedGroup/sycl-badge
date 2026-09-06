//! Sprites, sheets, and compile-time sprite authoring.
//!
//! Declare art with [`sprite!`](crate::sprite) or
//! [`sprite_sheet!`](crate::sprite_sheet) and the layout details stay here:
//!
//! ```
//! use sycl_cart::Color;
//!
//! sycl_cart::sprite_sheet! {
//!     /// Two frames of a blinking eye.
//!     const EYE;
//!     palette: {
//!         'w' => Color::WHITE,
//!         'k' => Color::BLACK,
//!     },
//!     frames: [
//!         [
//!             ".www.",
//!             "wwkww",
//!             ".www.",
//!         ],
//!         [
//!             ".....",
//!             "wwwww",
//!             ".....",
//!         ],
//!     ],
//! }
//!
//! assert_eq!((EYE.tile_w(), EYE.tile_h(), EYE.len()), (5, 3, 2));
//! ```
//!
//! Any character absent from the palette — `.` by convention — is transparent.
//! Dimensions come from the art itself; mismatched row lengths or frame sizes are
//! compile-time errors.
//!
//! # What the encoder works out for you
//!
//! Pixels are transposed to the framebuffer's column-major order and encoded to
//! the target's pixel format, both at compile time, so a blit never converts
//! anything per pixel.
//!
//! It also records the vertical extent of the opaque pixels in each column, and
//! whether any column has a *hole* — a transparent pixel with opaque pixels above
//! and below it. That distinction decides how fast the blit is:
//!
//! * **No holes** (the usual case, even for sprites with plenty of transparency
//!   around their silhouette): each column is one contiguous run, so the blit is
//!   a `copy_from_slice` per column with no per-pixel test at all.
//! * **Holes**: only those columns fall back to a per-pixel loop, and even then
//!   the loop is bounded to the column's opaque span.
//!
//! Either way the transparent margins are never touched, and they do not enlarge
//! the dirty rectangle.

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

/// The vertical extent of the opaque pixels in one sprite column.
///
/// `len == 0` means the column is entirely transparent and is skipped.
#[derive(Copy, Clone, PartialEq, Eq, Debug)]
pub struct Span {
    pub start: u8,
    pub len: u8,
}

impl Span {
    pub const EMPTY: Span = Span { start: 0, len: 0 };
}

/// A single image.
///
/// Build one with [`sprite!`](crate::sprite), or take a frame from a
/// [`SpriteSheet`]. [`Sprite::opaque`] is the low-level door for data that did
/// not come from the macros.
#[derive(Copy, Clone)]
pub struct Sprite {
    pub(crate) data: &'static [u16],
    pub(crate) w: u16,
    pub(crate) h: u16,
    /// Per-column opaque extent. Empty means every column is fully opaque.
    pub(crate) spans: &'static [Span],
    /// Stand-in colour for transparency *inside* a span. `None` unless some
    /// column has a hole, which is what enables the copy path.
    pub(crate) key: Option<Color>,
}

impl Sprite {
    /// A fully opaque sprite from column-major, pre-encoded pixels.
    ///
    /// Column-major means `data[x * h + y]`, and "pre-encoded" means the values
    /// already passed through [`Color`] for *this* target. Prefer
    /// [`sprite!`](crate::sprite) unless you are writing an asset pipeline.
    pub const fn opaque(data: &'static [u16], w: u16, h: u16) -> Sprite {
        assert!(
            data.len() == w as usize * h as usize,
            "sprite data length != w * h"
        );
        Sprite {
            data,
            w,
            h,
            spans: &[],
            key: None,
        }
    }

    #[doc(hidden)]
    pub const fn from_parts(
        data: &'static [u16],
        w: u16,
        h: u16,
        spans: &'static [Span],
        key: Option<Color>,
    ) -> Sprite {
        assert!(
            data.len() == w as usize * h as usize,
            "sprite data length != w * h"
        );
        assert!(spans.len() == w as usize, "one span per column required");
        Sprite {
            data,
            w,
            h,
            spans,
            key,
        }
    }

    #[inline]
    pub const fn w(&self) -> u16 {
        self.w
    }

    #[inline]
    pub const fn h(&self) -> u16 {
        self.h
    }

    /// True when the blit needs no per-pixel transparency test.
    #[inline]
    pub const fn takes_fast_path(&self) -> bool {
        self.key.is_none()
    }

    /// Opaque extent of column `c`.
    #[inline]
    pub(crate) fn span(&self, c: usize) -> Span {
        if self.spans.is_empty() {
            Span {
                start: 0,
                len: self.h as u8,
            }
        } else {
            self.spans[c]
        }
    }
}

/// Equally sized frames, stored one whole tile after another.
///
/// Build one with [`sprite_sheet!`](crate::sprite_sheet).
#[derive(Copy, Clone)]
pub struct SpriteSheet {
    data: &'static [u16],
    spans: &'static [Span],
    tile_w: u16,
    tile_h: u16,
    count: u16,
    key: Option<Color>,
}

impl SpriteSheet {
    #[doc(hidden)]
    pub const fn from_parts(
        data: &'static [u16],
        spans: &'static [Span],
        tile_w: u16,
        tile_h: u16,
        count: u16,
        key: Option<Color>,
    ) -> SpriteSheet {
        assert!(
            data.len() == tile_w as usize * tile_h as usize * count as usize,
            "sheet data length != tile_w * tile_h * count"
        );
        assert!(
            spans.len() == tile_w as usize * count as usize,
            "one span per column per tile"
        );
        SpriteSheet {
            data,
            spans,
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
        let pixels = self.tile_w as usize * self.tile_h as usize;
        let cols = self.tile_w as usize;
        Sprite {
            data: &self.data[i * pixels..(i + 1) * pixels],
            spans: &self.spans[i * cols..(i + 1) * cols],
            w: self.tile_w,
            h: self.tile_h,
            key: self.key,
        }
    }

    #[inline]
    pub const fn tile_w(&self) -> u16 {
        self.tile_w
    }

    #[inline]
    pub const fn tile_h(&self) -> u16 {
        self.tile_h
    }

    /// Number of frames.
    #[inline]
    pub const fn len(&self) -> u16 {
        self.count
    }

    #[inline]
    pub const fn is_empty(&self) -> bool {
        self.count == 0
    }

    /// True when blits from this sheet need no per-pixel transparency test.
    #[inline]
    pub const fn takes_fast_path(&self) -> bool {
        self.key.is_none()
    }
}

// ── Compile-time encoding, used by the macros ────────────────────────────────

/// Convert a palette character, rejecting anything that would truncate.
///
/// Going through a function rather than casting the literal in the macro keeps
/// `clippy::char_lit_as_u8` quiet in *user* crates, and turns a non-ASCII palette
/// character into a compile error instead of a silent truncation.
#[doc(hidden)]
pub const fn palette_char(c: char) -> u8 {
    assert!((c as u32) < 128, "sprite palette characters must be ASCII");
    c as u8
}

/// Pick a stand-in colour for transparency that cannot collide with the art.
///
/// The palette is known at compile time, so we can simply take the first value
/// it does not contain.
#[doc(hidden)]
pub const fn pick_key(palette: &[(u8, Color)]) -> Color {
    let mut candidate: u16 = 0;
    loop {
        let mut i = 0;
        let mut clash = false;
        while i < palette.len() {
            if palette[i].1 .0 == candidate {
                clash = true;
                break;
            }
            i += 1;
        }
        if !clash {
            return Color(candidate);
        }
        // A 16-bit palette cannot exhaust every value in practice, and the
        // assert documents the impossible case rather than wrapping silently.
        assert!(
            candidate != u16::MAX,
            "palette leaves no free colour for transparency"
        );
        candidate += 1;
    }
}

/// Transpose ASCII art to column-major, encoded pixels, one whole tile at a time.
#[doc(hidden)]
pub const fn encode_art<const N: usize>(
    frames: &[&[&str]],
    palette: &[(u8, Color)],
    key: Color,
) -> [u16; N] {
    assert!(!frames.is_empty(), "a sprite needs at least one frame");
    let h = frames[0].len();
    assert!(h > 0, "a sprite needs at least one row");
    let w = frames[0][0].len();
    assert!(w > 0, "a sprite needs at least one column");
    assert!(h <= 255, "sprites taller than 255 pixels are not supported");
    assert!(
        N == w * h * frames.len(),
        "pixel array length must equal w * h * frames"
    );

    let mut out = [key.0; N];
    let mut f = 0;
    while f < frames.len() {
        let rows = frames[f];
        assert!(
            rows.len() == h,
            "every frame must have the same number of rows"
        );
        let base = f * w * h;
        let mut y = 0;
        while y < h {
            let row = rows[y].as_bytes();
            assert!(row.len() == w, "every row must be the same length");
            let mut x = 0;
            while x < w {
                let ch = row[x];
                let mut i = 0;
                while i < palette.len() {
                    if palette[i].0 == ch {
                        // The transpose happens here.
                        out[base + x * h + y] = palette[i].1 .0;
                        break;
                    }
                    i += 1;
                }
                x += 1;
            }
            y += 1;
        }
        f += 1;
    }
    out
}

/// Record the opaque extent of every column of every tile.
#[doc(hidden)]
pub const fn compute_spans<const M: usize>(
    data: &[u16],
    w: usize,
    h: usize,
    count: usize,
    key: Color,
) -> [Span; M] {
    assert!(M == w * count, "span array length must equal w * frames");
    let mut out = [Span::EMPTY; M];
    let mut c = 0;
    while c < w * count {
        let col = c * h;
        let mut first = h;
        let mut last = 0;
        let mut y = 0;
        while y < h {
            if data[col + y] != key.0 {
                if first == h {
                    first = y;
                }
                last = y;
            }
            y += 1;
        }
        out[c] = if first == h {
            Span::EMPTY
        } else {
            Span {
                start: first as u8,
                len: (last - first + 1) as u8,
            }
        };
        c += 1;
    }
    out
}

/// Whether any column has a transparent pixel *inside* its opaque span.
///
/// False for the vast majority of game art, which is what lets the blit skip
/// per-pixel transparency tests entirely.
#[doc(hidden)]
pub const fn has_holes(data: &[u16], w: usize, h: usize, count: usize, key: Color) -> bool {
    let mut c = 0;
    while c < w * count {
        let col = c * h;
        let mut first = h;
        let mut last = 0;
        let mut y = 0;
        while y < h {
            if data[col + y] != key.0 {
                if first == h {
                    first = y;
                }
                last = y;
            }
            y += 1;
        }
        if first < h {
            let mut y = first;
            while y <= last {
                if data[col + y] == key.0 {
                    return true;
                }
                y += 1;
            }
        }
        c += 1;
    }
    false
}

/// Declare a single sprite from ASCII art. See the [module docs](crate::sprite).
///
/// ```
/// use sycl_cart::Color;
///
/// sycl_cart::sprite! {
///     const BALL;
///     palette: { 'o' => Color::WHITE },
///     art: [
///         ".oo.",
///         "oooo",
///         ".oo.",
///     ],
/// }
///
/// assert_eq!((BALL.w(), BALL.h()), (4, 3));
/// assert!(BALL.takes_fast_path(), "no interior holes, so no per-pixel test");
/// ```
#[macro_export]
macro_rules! sprite {
    (
        $(#[$meta:meta])*
        $vis:vis const $name:ident;
        palette: { $($ch:literal => $color:expr),* $(,)? },
        art: [ $($row:literal),* $(,)? ] $(,)?
    ) => {
        $(#[$meta])*
        $vis const $name: $crate::sprite::Sprite = {
            const ART: &[&[&str]] = &[&[$($row),*]];
            const PALETTE: &[(u8, $crate::Color)] =
                &[$(($crate::sprite::palette_char($ch), $color)),*];
            const H: usize = ART[0].len();
            const W: usize = ART[0][0].len();
            const KEY: $crate::Color = $crate::sprite::pick_key(PALETTE);
            const DATA: [u16; W * H] = $crate::sprite::encode_art(ART, PALETTE, KEY);
            const SPANS: [$crate::sprite::Span; W] =
                $crate::sprite::compute_spans(&DATA, W, H, 1, KEY);
            const HOLES: bool = $crate::sprite::has_holes(&DATA, W, H, 1, KEY);
            $crate::sprite::Sprite::from_parts(
                &DATA,
                W as u16,
                H as u16,
                &SPANS,
                if HOLES { Some(KEY) } else { None },
            )
        };
    };
}

/// Declare a multi-frame sprite sheet from ASCII art. See the
/// [module docs](crate::sprite).
#[macro_export]
macro_rules! sprite_sheet {
    (
        $(#[$meta:meta])*
        $vis:vis const $name:ident;
        palette: { $($ch:literal => $color:expr),* $(,)? },
        frames: [ $([ $($row:literal),* $(,)? ]),* $(,)? ] $(,)?
    ) => {
        $(#[$meta])*
        $vis const $name: $crate::sprite::SpriteSheet = {
            const ART: &[&[&str]] = &[$(&[$($row),*]),*];
            const PALETTE: &[(u8, $crate::Color)] =
                &[$(($crate::sprite::palette_char($ch), $color)),*];
            const COUNT: usize = ART.len();
            const H: usize = ART[0].len();
            const W: usize = ART[0][0].len();
            const KEY: $crate::Color = $crate::sprite::pick_key(PALETTE);
            const DATA: [u16; W * H * COUNT] = $crate::sprite::encode_art(ART, PALETTE, KEY);
            const SPANS: [$crate::sprite::Span; W * COUNT] =
                $crate::sprite::compute_spans(&DATA, W, H, COUNT, KEY);
            const HOLES: bool = $crate::sprite::has_holes(&DATA, W, H, COUNT, KEY);
            $crate::sprite::SpriteSheet::from_parts(
                &DATA,
                &SPANS,
                W as u16,
                H as u16,
                COUNT as u16,
                if HOLES { Some(KEY) } else { None },
            )
        };
    };
}

// ── Animation ───────────────────────────────────────────────────────────────

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

    const RED: Color = Color::RED;
    const GREEN: Color = Color::GREEN;

    sprite! {
        const PLAIN;
        palette: { 'R' => RED, 'G' => GREEN },
        art: ["RG.", ".GR"],
    }

    #[test]
    fn ascii_art_is_transposed_to_column_major() {
        // Column 0 = (R, transparent), column 1 = (G, G), column 2 = (transparent, R).
        assert_eq!(PLAIN.data[0], RED.0);
        assert_eq!(PLAIN.data[2], GREEN.0);
        assert_eq!(PLAIN.data[3], GREEN.0);
        assert_eq!(PLAIN.data[5], RED.0);
    }

    #[test]
    fn dimensions_come_from_the_art() {
        assert_eq!((PLAIN.w(), PLAIN.h()), (3, 2));
    }

    #[test]
    fn spans_bound_each_column_to_its_opaque_pixels() {
        assert_eq!(PLAIN.span(0), Span { start: 0, len: 1 });
        assert_eq!(PLAIN.span(1), Span { start: 0, len: 2 });
        assert_eq!(PLAIN.span(2), Span { start: 1, len: 1 });
    }

    #[test]
    fn edge_transparency_still_takes_the_fast_path() {
        // Transparency around the silhouette is not a hole.
        sprite! {
            const ROUND;
            palette: { 'o' => RED },
            art: [".oo.", "oooo", "oooo", ".oo."],
        }
        assert!(ROUND.takes_fast_path());
        assert_eq!(ROUND.span(0), Span { start: 1, len: 2 });
        assert_eq!(ROUND.span(1), Span { start: 0, len: 4 });
    }

    #[test]
    fn interior_holes_force_the_per_pixel_path() {
        sprite! {
            const DONUT;
            palette: { 'o' => RED },
            art: ["ooo", "o.o", "ooo"],
        }
        assert!(!DONUT.takes_fast_path());
        // The middle column spans the full height but has a gap inside it.
        assert_eq!(DONUT.span(1), Span { start: 0, len: 3 });
    }

    #[test]
    fn fully_transparent_columns_are_empty_spans() {
        sprite! {
            const GAPPED;
            palette: { 'o' => RED },
            art: ["o.o", "o.o"],
        }
        assert_eq!(GAPPED.span(1), Span::EMPTY);
    }

    #[test]
    fn transparency_key_never_collides_with_the_palette() {
        // Black encodes to 0, so the key must not be 0 here.
        sprite! {
            const WITH_BLACK;
            palette: { 'k' => Color::BLACK, 'w' => Color::WHITE },
            art: ["kw", "wk"],
        }
        assert!(WITH_BLACK.takes_fast_path());
        let key = pick_key(&[(b'k', Color::BLACK), (b'w', Color::WHITE)]);
        assert_ne!(key, Color::BLACK);
        assert_ne!(key, Color::WHITE);
    }

    sprite_sheet! {
        const SHEET;
        palette: { 'a' => RED, 'b' => GREEN },
        frames: [["aa", "aa"], ["bb", "bb"]],
    }

    #[test]
    fn sheet_slices_whole_tiles_and_their_spans() {
        assert_eq!((SHEET.tile_w(), SHEET.tile_h(), SHEET.len()), (2, 2, 2));
        assert_eq!(SHEET.tile(0).data, &[RED.0; 4]);
        assert_eq!(SHEET.tile(1).data, &[GREEN.0; 4]);
        assert_eq!(SHEET.tile(2).data, &[RED.0; 4], "index wraps");
        assert_eq!(SHEET.tile(1).span(0), Span { start: 0, len: 2 });
    }

    #[test]
    fn opaque_sprites_need_no_span_table() {
        static DATA: [u16; 4] = [1, 2, 3, 4];
        let s = Sprite::opaque(&DATA, 2, 2);
        assert!(s.takes_fast_path());
        assert_eq!(s.span(0), Span { start: 0, len: 2 });
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
