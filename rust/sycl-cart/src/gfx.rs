//! Immediate-mode drawing into a private backbuffer.
//!
//! # Why a backbuffer
//!
//! Both targets expose their framebuffer in memory shared with something outside
//! the compiler's view — the browser host, or Core 0's DMA engine. LLVM cannot
//! see those readers, so **plain stores into the shared framebuffer are dead
//! code and get deleted in release builds.** (Measured: a per-pixel fill loop
//! writing to the simulator's framebuffer vanished at `opt-level = "z"`.)
//!
//! Writing every pixel with `write_volatile` would fix that and cost all the
//! optimizations that make a software rasterizer viable. Instead we draw into a
//! private `static` backbuffer with ordinary stores — which LLVM keeps, because
//! it can see [`flush_rect`] read them back — and then push the dirty region out
//! with one bulk volatile pass per frame.
//!
//! # Layout
//!
//! The framebuffer is **column-major**: `index = x * HEIGHT + y`. A column is
//! contiguous, a row is strided by 256 bytes. That inverts the usual
//! performance intuitions:
//!
//! * [`Gfx::vline`] is a `fill` — cheap.
//! * [`Gfx::hline`] touches one pixel per 256-byte stride — expensive.
//! * Sprites are stored column-major too (see [`crate::sprite`]), so a blit is
//!   one `copy_from_slice` per sprite column.

use crate::color::Color;
use crate::font;
use crate::platform;
use crate::sprite::{BlitFlags, Sprite};

/// Screen width in pixels.
pub const WIDTH: usize = 160;
/// Screen height in pixels.
pub const HEIGHT: usize = 128;
/// Pixels in one frame.
pub const PIXELS: usize = WIDTH * HEIGHT;

/// A screen-space rectangle, already clipped to the display.
#[derive(Copy, Clone, PartialEq, Eq, Default, Debug)]
pub struct Rect {
    pub x: u16,
    pub y: u16,
    pub w: u16,
    pub h: u16,
}

impl Rect {
    /// The whole screen.
    pub const FULL: Rect = Rect {
        x: 0,
        y: 0,
        w: WIDTH as u16,
        h: HEIGHT as u16,
    };

    /// Area in pixels.
    #[inline]
    pub const fn area(&self) -> u32 {
        self.w as u32 * self.h as u32
    }

    /// Smallest rectangle containing both.
    #[inline]
    fn union(self, o: Rect) -> Rect {
        let x = if self.x < o.x { self.x } else { o.x };
        let y = if self.y < o.y { self.y } else { o.y };
        let r = core::cmp::max(self.x + self.w, o.x + o.w);
        let b = core::cmp::max(self.y + self.h, o.y + o.h);
        Rect {
            x,
            y,
            w: r - x,
            h: b - y,
        }
    }
}

/// Clip a signed rectangle to the screen. Returns `None` if nothing is visible.
fn clip(x: i32, y: i32, w: u32, h: u32) -> Option<Rect> {
    if w == 0 || h == 0 {
        return None;
    }
    let x1 = x.saturating_add(w.min(i32::MAX as u32) as i32);
    let y1 = y.saturating_add(h.min(i32::MAX as u32) as i32);
    let x0 = x.max(0);
    let y0 = y.max(0);
    let x1 = x1.min(WIDTH as i32);
    let y1 = y1.min(HEIGHT as i32);
    if x0 >= x1 || y0 >= y1 {
        return None;
    }
    Some(Rect {
        x: x0 as u16,
        y: y0 as u16,
        w: (x1 - x0) as u16,
        h: (y1 - y0) as u16,
    })
}

/// The drawing surface. Obtained from [`crate::Ctx`]; you never construct one.
pub struct Gfx {
    buf: &'static mut [u16; PIXELS],
    dirty: Option<Rect>,
}

impl Gfx {
    pub(crate) fn new(buf: &'static mut [u16; PIXELS]) -> Self {
        Gfx {
            buf,
            dirty: Some(Rect::FULL),
        }
    }

    /// The region that changed this frame, or `None` if nothing was drawn.
    #[inline]
    pub fn dirty(&self) -> Option<Rect> {
        self.dirty
    }

    /// Extend the dirty region. Every drawing method does this for you; call it
    /// directly only if you write to [`Gfx::pixels_mut`] yourself.
    #[inline]
    pub fn mark_dirty(&mut self, x: i32, y: i32, w: u32, h: u32) {
        if let Some(r) = clip(x, y, w, h) {
            self.dirty = Some(match self.dirty {
                Some(d) => d.union(r),
                None => r,
            });
        }
    }

    /// Raw backbuffer access, column-major (`index = x * HEIGHT + y`).
    /// You are responsible for calling [`Gfx::mark_dirty`].
    #[inline]
    pub fn pixels_mut(&mut self) -> &mut [u16; PIXELS] {
        self.buf
    }

    /// Fill the whole screen.
    pub fn clear(&mut self, color: Color) {
        self.buf.fill(color.0);
        self.dirty = Some(Rect::FULL);
    }

    /// Set one pixel. Out-of-bounds coordinates are ignored.
    #[inline]
    pub fn pixel(&mut self, x: i32, y: i32, color: Color) {
        if (0..WIDTH as i32).contains(&x) && (0..HEIGHT as i32).contains(&y) {
            self.buf[x as usize * HEIGHT + y as usize] = color.0;
            self.mark_dirty(x, y, 1, 1);
        }
    }

    /// Filled rectangle, clipped.
    pub fn fill_rect(&mut self, x: i32, y: i32, w: u32, h: u32, color: Color) {
        let Some(r) = clip(x, y, w, h) else { return };
        let (y0, y1) = (r.y as usize, (r.y + r.h) as usize);
        for cx in r.x as usize..(r.x + r.w) as usize {
            let base = cx * HEIGHT;
            self.buf[base + y0..base + y1].fill(color.0);
        }
        self.mark_dirty(x, y, w, h);
    }

    /// Rectangle outline, one pixel wide.
    pub fn stroke_rect(&mut self, x: i32, y: i32, w: u32, h: u32, color: Color) {
        if w == 0 || h == 0 {
            return;
        }
        let (wi, hi) = (w as i32, h as i32);
        self.hline(x, y, w, color);
        self.hline(x, y + hi - 1, w, color);
        self.vline(x, y, h, color);
        self.vline(x + wi - 1, y, h, color);
    }

    /// Vertical line. This is the *fast* direction: one contiguous fill.
    pub fn vline(&mut self, x: i32, y: i32, len: u32, color: Color) {
        let Some(r) = clip(x, y, 1, len) else { return };
        let base = r.x as usize * HEIGHT;
        self.buf[base + r.y as usize..base + (r.y + r.h) as usize].fill(color.0);
        self.mark_dirty(x, y, 1, len);
    }

    /// Horizontal line. One pixel per 256-byte stride — prefer [`Gfx::vline`] or
    /// [`Gfx::fill_rect`] in hot code.
    pub fn hline(&mut self, x: i32, y: i32, len: u32, color: Color) {
        let Some(r) = clip(x, y, len, 1) else { return };
        let y0 = r.y as usize;
        for cx in r.x as usize..(r.x + r.w) as usize {
            self.buf[cx * HEIGHT + y0] = color.0;
        }
        self.mark_dirty(x, y, len, 1);
    }

    /// Bresenham line.
    pub fn line(&mut self, x0: i32, y0: i32, x1: i32, y1: i32, color: Color) {
        let (mut x, mut y) = (x0, y0);
        let dx = (x1 - x0).abs();
        let dy = -(y1 - y0).abs();
        let sx = if x0 < x1 { 1 } else { -1 };
        let sy = if y0 < y1 { 1 } else { -1 };
        let mut err = dx + dy;
        loop {
            if (0..WIDTH as i32).contains(&x) && (0..HEIGHT as i32).contains(&y) {
                self.buf[x as usize * HEIGHT + y as usize] = color.0;
            }
            if x == x1 && y == y1 {
                break;
            }
            let e2 = 2 * err;
            if e2 >= dy {
                if x == x1 {
                    break;
                }
                err += dy;
                x += sx;
            }
            if e2 <= dx {
                if y == y1 {
                    break;
                }
                err += dx;
                y += sy;
            }
        }
        let (lx, ly) = (x0.min(x1), y0.min(y1));
        self.mark_dirty(lx, ly, (dx + 1) as u32, (-dy + 1) as u32);
    }

    /// Draw a sprite with its top-left corner at `(x, y)`.
    #[inline]
    pub fn blit(&mut self, sprite: &Sprite, x: i32, y: i32) {
        self.blit_with(sprite, x, y, BlitFlags::NONE);
    }

    /// Draw a sprite, optionally flipped.
    pub fn blit_with(&mut self, sprite: &Sprite, x: i32, y: i32, flags: BlitFlags) {
        let (sw, sh) = (sprite.w as usize, sprite.h as usize);
        let Some(r) = clip(x, y, sw as u32, sh as u32) else {
            return;
        };
        self.mark_dirty(x, y, sw as u32, sh as u32);

        // Offsets into the sprite corresponding to the clipped screen rect.
        let skip_x = (r.x as i32 - x) as usize;
        let skip_y = (r.y as i32 - y) as usize;
        let cols = r.w as usize;
        let rows = r.h as usize;

        // Fast path: opaque, unflipped. One contiguous copy per column.
        if sprite.key.is_none() && !flags.flip_x && !flags.flip_y {
            for c in 0..cols {
                let src = (skip_x + c) * sh + skip_y;
                let dst = (r.x as usize + c) * HEIGHT + r.y as usize;
                self.buf[dst..dst + rows].copy_from_slice(&sprite.data[src..src + rows]);
            }
            return;
        }

        let key = sprite.key.map(|k| k.0);
        for c in 0..cols {
            let sc = if flags.flip_x {
                sw - 1 - (skip_x + c)
            } else {
                skip_x + c
            };
            let dst_base = (r.x as usize + c) * HEIGHT;
            for row in 0..rows {
                let sr = if flags.flip_y {
                    sh - 1 - (skip_y + row)
                } else {
                    skip_y + row
                };
                let px = sprite.data[sc * sh + sr];
                if Some(px) == key {
                    continue;
                }
                self.buf[dst_base + r.y as usize + row] = px;
            }
        }
    }

    /// Draw text in the built-in 8x8 font. `\n` starts a new line.
    /// Bytes are treated as Latin-1 (the font covers U+0020..=U+00FF).
    #[inline]
    pub fn text(&mut self, s: &[u8], x: i32, y: i32, color: Color) {
        self.text_with(s, x, y, 1, color, None);
    }

    /// Draw text with an integer scale factor and an optional background.
    pub fn text_with(
        &mut self,
        s: &[u8],
        x: i32,
        y: i32,
        scale: u32,
        color: Color,
        background: Option<Color>,
    ) {
        let scale = scale.max(1) as i32;
        let step = font::WIDTH as i32 * scale;
        let mut cx = x;
        let mut cy = y;
        let mut widest = 0i32;
        let mut lines = 1i32;

        for &ch in s {
            if ch == b'\n' {
                widest = widest.max(cx - x);
                cx = x;
                cy += step;
                lines += 1;
                continue;
            }
            if ch >= font::FIRST {
                self.glyph(ch, cx, cy, scale, color, background);
            }
            cx += step;
        }
        widest = widest.max(cx - x);
        self.mark_dirty(x, y, widest.max(0) as u32, (lines * step).max(0) as u32);
    }

    fn glyph(
        &mut self,
        ch: u8,
        x: i32,
        y: i32,
        scale: i32,
        color: Color,
        background: Option<Color>,
    ) {
        let glyph = &font::GLYPHS[(ch - font::FIRST) as usize];
        for (row, bits) in glyph.iter().enumerate() {
            for col in 0..8u32 {
                let on = bits & (0x80 >> col) != 0;
                let px = match (on, background) {
                    (true, _) => color,
                    (false, Some(bg)) => bg,
                    (false, None) => continue,
                };
                let px0 = x + col as i32 * scale;
                let py0 = y + row as i32 * scale;
                for sy in 0..scale {
                    let py = py0 + sy;
                    if !(0..HEIGHT as i32).contains(&py) {
                        continue;
                    }
                    for sx in 0..scale {
                        let pxx = px0 + sx;
                        if (0..WIDTH as i32).contains(&pxx) {
                            self.buf[pxx as usize * HEIGHT + py as usize] = px.0;
                        }
                    }
                }
            }
        }
    }

    /// Push the dirty region to the display and reset it.
    pub(crate) fn present(&mut self) {
        let dirty = self.dirty.take();
        platform::present(self.buf, dirty);
    }
}

/// Copy a rectangle of the backbuffer into a shared framebuffer using volatile
/// word writes, so the compiler cannot elide them.
///
/// Writes `u32` pairs, so the row range is widened to even boundaries. `HEIGHT`
/// is even and columns are `HEIGHT`-aligned, so pairs never straddle columns.
///
/// # Safety
///
/// `dst` must point to at least `PIXELS` `u16`s (40 KiB) laid out column-major
/// exactly like the backbuffer.
pub(crate) unsafe fn flush_rect(buf: &[u16; PIXELS], r: Rect, dst: *mut u32) {
    let y0 = (r.y & !1) as usize;
    let y_end = (r.y + r.h) as usize;
    let y1 = ((y_end + 1) & !1).min(HEIGHT);
    if y0 >= y1 {
        return;
    }

    for cx in r.x as usize..(r.x + r.w) as usize {
        let base = cx * HEIGHT;
        let col = &buf[base..base + HEIGHT];
        let mut y = y0;
        while y < y1 {
            let word = col[y] as u32 | ((col[y + 1] as u32) << 16);
            // SAFETY: `(base + y) / 2` is within `PIXELS / 2` words of `dst`,
            // which the caller guarantees is mapped.
            unsafe { dst.add((base + y) >> 1).write_volatile(word) };
            y += 2;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn surface() -> Gfx {
        let buf = std::boxed::Box::leak(std::boxed::Box::new([0u16; PIXELS]));
        Gfx::new(buf)
    }

    #[test]
    fn clip_rejects_offscreen() {
        assert!(clip(-10, 0, 5, 5).is_none());
        assert!(clip(WIDTH as i32, 0, 5, 5).is_none());
        assert!(clip(0, 0, 0, 5).is_none());
    }

    #[test]
    fn clip_trims_to_screen() {
        let r = clip(-4, -4, 10, 10).unwrap();
        assert_eq!(
            r,
            Rect {
                x: 0,
                y: 0,
                w: 6,
                h: 6
            }
        );
        let r = clip(155, 124, 10, 10).unwrap();
        assert_eq!(
            r,
            Rect {
                x: 155,
                y: 124,
                w: 5,
                h: 4
            }
        );
    }

    #[test]
    fn fill_rect_writes_column_major_and_marks_dirty() {
        let mut g = surface();
        g.dirty = None;
        g.fill_rect(3, 5, 2, 4, Color::WHITE);
        assert_eq!(g.buf[3 * HEIGHT + 5], Color::WHITE.0);
        assert_eq!(g.buf[4 * HEIGHT + 8], Color::WHITE.0);
        assert_eq!(g.buf[3 * HEIGHT + 9], 0, "must not spill past height");
        assert_eq!(g.buf[5 * HEIGHT + 5], 0, "must not spill past width");
        assert_eq!(
            g.dirty,
            Some(Rect {
                x: 3,
                y: 5,
                w: 2,
                h: 4
            })
        );
    }

    #[test]
    fn dirty_region_is_a_union() {
        let mut g = surface();
        g.dirty = None;
        g.pixel(10, 10, Color::RED);
        g.pixel(20, 4, Color::RED);
        assert_eq!(
            g.dirty,
            Some(Rect {
                x: 10,
                y: 4,
                w: 11,
                h: 7
            })
        );
    }

    #[test]
    fn offscreen_drawing_leaves_dirty_alone() {
        let mut g = surface();
        g.dirty = None;
        g.fill_rect(-50, -50, 10, 10, Color::RED);
        assert_eq!(g.dirty, None);
    }

    #[test]
    fn flush_covers_odd_row_ranges() {
        let mut g = surface();
        g.fill_rect(0, 0, WIDTH as u32, HEIGHT as u32, Color::BLUE);
        let mut shadow = std::vec![0u16; PIXELS];
        // A rect starting and ending on odd rows still has to be fully copied.
        let r = Rect {
            x: 2,
            y: 3,
            w: 2,
            h: 3,
        };
        unsafe { flush_rect(g.buf, r, shadow.as_mut_ptr() as *mut u32) };
        for x in 2..4usize {
            for y in 3..6usize {
                assert_eq!(shadow[x * HEIGHT + y], Color::BLUE.0, "({x},{y})");
            }
        }
        assert_eq!(shadow[4 * HEIGHT + 3], 0, "must not touch other columns");
    }

    #[test]
    fn text_stays_in_bounds_at_the_edges() {
        let mut g = surface();
        g.text(b"WW", WIDTH as i32 - 4, HEIGHT as i32 - 4, Color::WHITE);
        g.text(b"WW", -4, -4, Color::WHITE);
    }
}
