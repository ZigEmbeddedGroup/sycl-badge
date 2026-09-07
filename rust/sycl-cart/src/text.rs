//! Building short strings without an allocator.
//!
//! [`TextBuf`] is a fixed-capacity byte buffer you can format into, and
//! [`uformat!`](crate::uformat) is the `format!`-shaped way to fill one:
//!
//! ```
//! use sycl_cart::uformat;
//!
//! let score = 12u32;
//! let label = uformat!(16, "SCORE {}", score);
//! assert_eq!(label.as_bytes(), b"SCORE 12");
//! ```
//!
//! Pass the result straight to [`Gfx::text`](crate::gfx::Gfx::text), or use it as
//! a log message. For the simple cases you do not need the macro at all:
//!
//! ```
//! use sycl_cart::text::TextBuf;
//!
//! let mut b = TextBuf::<16>::new();
//! b.push_str("BEST ");
//! b.push_u32(1234);
//! assert_eq!(b.as_bytes(), b"BEST 1234");
//! ```
//!
//! # Why not `format!`
//!
//! `format!` allocates, and `core::fmt` costs 10–20 KiB of flash against a
//! ~160 KiB cart budget. Formatting here goes through [`ufmt`], which is 1–2 KiB.
//!
//! Two consequences of that choice:
//!
//! * **Positional arguments only.** `ufmt` has no implicit capture, so
//!   `uformat!(8, "{score}")` does not compile — write `uformat!(8, "{}", score)`.
//!   (Field access like `{self.score}` is not valid in `std`'s `format!` either.)
//! * **No float support.** `ufmt` cannot print `f32` at all. Wrap floats in
//!   [`fx`] for fixed-point output.
//!
//! # Overflow
//!
//! Writing past the capacity truncates and sets [`TextBuf::truncated`]. It never
//! panics: losing the tail of a label is always better than taking down the cart.

use core::ops::Deref;
use ufmt::uWrite;

/// A fixed-capacity string buffer.
///
/// `N` is the capacity in bytes. Content is treated as Latin-1 — the same range
/// the built-in font covers — so [`TextBuf::as_bytes`] is the accessor rather
/// than a `&str`.
#[derive(Copy, Clone)]
pub struct TextBuf<const N: usize> {
    bytes: [u8; N],
    len: usize,
    truncated: bool,
}

impl<const N: usize> Default for TextBuf<N> {
    fn default() -> Self {
        Self::new()
    }
}

impl<const N: usize> TextBuf<N> {
    /// An empty buffer.
    pub const fn new() -> TextBuf<N> {
        TextBuf {
            bytes: [0; N],
            len: 0,
            truncated: false,
        }
    }

    /// Capacity in bytes.
    pub const fn capacity(&self) -> usize {
        N
    }

    /// Bytes written so far.
    #[inline]
    pub const fn len(&self) -> usize {
        self.len
    }

    #[inline]
    pub const fn is_empty(&self) -> bool {
        self.len == 0
    }

    /// True if anything was dropped for want of capacity.
    #[inline]
    pub const fn truncated(&self) -> bool {
        self.truncated
    }

    /// Discard the contents, keeping the capacity.
    #[inline]
    pub fn clear(&mut self) {
        self.len = 0;
        self.truncated = false;
    }

    #[inline]
    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes[..self.len]
    }

    /// Append raw bytes, truncating if they do not fit.
    pub fn push_bytes(&mut self, b: &[u8]) {
        let room = N - self.len;
        let n = if b.len() > room {
            self.truncated = true;
            room
        } else {
            b.len()
        };
        self.bytes[self.len..self.len + n].copy_from_slice(&b[..n]);
        self.len += n;
    }

    /// Append a string. Non-ASCII characters are multi-byte in UTF-8 and will not
    /// render correctly in the built-in font.
    #[inline]
    pub fn push_str(&mut self, s: &str) {
        self.push_bytes(s.as_bytes());
    }

    /// Append one byte.
    #[inline]
    pub fn push_byte(&mut self, b: u8) {
        self.push_bytes(&[b]);
    }

    /// Append an unsigned decimal.
    pub fn push_u32(&mut self, mut v: u32) {
        let mut digits = [0u8; 10];
        let mut n = 0;
        loop {
            digits[n] = b'0' + (v % 10) as u8;
            v /= 10;
            n += 1;
            if v == 0 {
                break;
            }
        }
        while n > 0 {
            n -= 1;
            self.push_byte(digits[n]);
        }
    }

    /// Append a signed decimal.
    pub fn push_i32(&mut self, v: i32) {
        if v < 0 {
            self.push_byte(b'-');
        }
        // `unsigned_abs` so `i32::MIN` does not overflow on negation.
        self.push_u32(v.unsigned_abs());
    }

    /// Append a float as fixed point with `decimals` places. See [`fx`].
    pub fn push_fixed(&mut self, v: f32, decimals: u8) {
        if v.is_nan() {
            return self.push_str("NaN");
        }
        if v.is_infinite() {
            return self.push_str(if v < 0.0 { "-inf" } else { "inf" });
        }

        let negative = v < 0.0;
        let mut scale: u32 = 1;
        let mut i = 0;
        while i < decimals {
            scale *= 10;
            i += 1;
        }

        let magnitude = if negative { -v } else { v } * scale as f32 + 0.5;
        // Saturate rather than wrap on absurd magnitudes.
        let scaled = if magnitude >= u32::MAX as f32 {
            u32::MAX
        } else {
            magnitude as u32
        };

        if negative {
            self.push_byte(b'-');
        }
        self.push_u32(scaled / scale);
        if decimals > 0 {
            let frac = scaled % scale;
            self.push_byte(b'.');
            // Leading zeros inside the fraction.
            let mut probe = scale / 10;
            while probe > frac && probe > 1 {
                self.push_byte(b'0');
                probe /= 10;
            }
            self.push_u32(frac);
        }
    }
}

impl<const N: usize> Deref for TextBuf<N> {
    type Target = [u8];

    fn deref(&self) -> &[u8] {
        self.as_bytes()
    }
}

impl<const N: usize> AsRef<[u8]> for TextBuf<N> {
    fn as_ref(&self) -> &[u8] {
        self.as_bytes()
    }
}

impl<const N: usize> uWrite for TextBuf<N> {
    type Error = core::convert::Infallible;

    fn write_str(&mut self, s: &str) -> Result<(), Self::Error> {
        self.push_str(s);
        Ok(())
    }
}

impl<const N: usize> core::fmt::Write for TextBuf<N> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        self.push_str(s);
        Ok(())
    }
}

impl<const N: usize> core::fmt::Debug for TextBuf<N> {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        use core::fmt::Write as _;
        f.write_char('"')?;
        for &b in self.as_bytes() {
            // Printable ASCII as-is, anything else as a dot: enough to read a
            // test failure without dragging in escaping machinery.
            f.write_char(if b.is_ascii_graphic() || b == b' ' {
                b as char
            } else {
                '.'
            })?;
        }
        f.write_char('"')
    }
}

/// Wrap an `f32` so [`ufmt`] can print it, with `decimals` places.
///
/// `ufmt` has no float support, and pulling in `core::fmt` just to print a
/// velocity would cost more flash than the rest of the framework. This converts
/// with integer maths.
///
/// ```
/// use sycl_cart::{text::fx, uformat};
///
/// assert_eq!(uformat!(16, "vy={}", fx(-1.5, 2)).as_bytes(), b"vy=-1.50");
/// ```
pub const fn fx(value: f32, decimals: u8) -> Fx {
    Fx { value, decimals }
}

/// A fixed-point view of an `f32`. See [`fx`].
#[derive(Copy, Clone)]
pub struct Fx {
    value: f32,
    decimals: u8,
}

impl ufmt::uDisplay for Fx {
    fn fmt<W>(&self, w: &mut ufmt::Formatter<'_, W>) -> Result<(), W::Error>
    where
        W: uWrite + ?Sized,
    {
        // Format into a scratch buffer so this works against any sink.
        // 1 sign + 10 integer digits + point + 9 decimals covers every f32.
        let mut scratch = TextBuf::<24>::new();
        scratch.push_fixed(self.value, self.decimals.min(9));
        // Only ever digits and punctuation, so the conversion cannot fail.
        w.write_str(core::str::from_utf8(scratch.as_bytes()).unwrap_or("?"))
    }
}

/// Build a [`TextBuf`] the way `format!` builds a `String`.
///
/// The first argument is the capacity in bytes; the rest is a [`ufmt`] format
/// string and its arguments. Positional `{}` only — see the
/// [module docs](crate::text).
///
/// ```
/// use sycl_cart::uformat;
///
/// let lives = 3u32;
/// assert_eq!(uformat!(16, "LIVES {}", lives).as_bytes(), b"LIVES 3");
/// ```
///
/// Overflow truncates rather than panicking:
///
/// ```
/// use sycl_cart::uformat;
///
/// let s = uformat!(4, "{}", 123456u32);
/// assert_eq!(s.as_bytes(), b"1234");
/// assert!(s.truncated());
/// ```
#[macro_export]
macro_rules! uformat {
    ($cap:expr, $($arg:tt)*) => {{
        let mut __buf = $crate::text::TextBuf::<{ $cap }>::new();
        {
            // `ufmt::uwrite!` expands to paths that assume the `ufmt` crate and
            // its `UnstableDoAsFormatter` trait are nameable here, so bring both
            // into scope. Keeps carts from having to depend on `ufmt` themselves.
            use $crate::ufmt;
            // Needed by some `uwrite!` expansions and not others, hence the allow.
            #[allow(unused_imports)]
            use $crate::ufmt::UnstableDoAsFormatter as _;
            let _ = ufmt::uwrite!(&mut __buf, $($arg)*);
        }
        __buf
    }};
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn push_methods_need_no_macro() {
        let mut b = TextBuf::<16>::new();
        b.push_str("BEST ");
        b.push_u32(1234);
        assert_eq!(b.as_bytes(), b"BEST 1234");
        assert_eq!(b.len(), 9);
        assert!(!b.truncated());
    }

    #[test]
    fn uformat_mirrors_format() {
        assert_eq!(uformat!(16, "SCORE {}", 12u32).as_bytes(), b"SCORE 12");
        assert_eq!(uformat!(8, "{}-{}", 1u32, 2u32).as_bytes(), b"1-2");
        assert_eq!(uformat!(8, "plain").as_bytes(), b"plain");
    }

    #[test]
    fn uformat_accepts_a_const_capacity() {
        const CAP: usize = 12;
        assert_eq!(uformat!(CAP, "{}", 7u32).capacity(), 12);
    }

    #[test]
    fn integers_round_trip() {
        assert_eq!(uformat!(16, "{}", 0u32).as_bytes(), b"0");
        assert_eq!(uformat!(16, "{}", u32::MAX).as_bytes(), b"4294967295");
        let mut b = TextBuf::<16>::new();
        b.push_i32(-42);
        assert_eq!(b.as_bytes(), b"-42");
        let mut b = TextBuf::<16>::new();
        b.push_i32(i32::MIN);
        assert_eq!(b.as_bytes(), b"-2147483648", "i32::MIN must not overflow");
    }

    #[test]
    fn overflow_truncates_and_reports() {
        let s = uformat!(4, "{}", 123456u32);
        assert_eq!(s.as_bytes(), b"1234");
        assert!(s.truncated());

        let mut b = TextBuf::<3>::new();
        b.push_str("abcdef");
        assert_eq!(b.as_bytes(), b"abc");
        assert!(b.truncated());
    }

    #[test]
    fn clear_resets_the_truncation_flag() {
        let mut b = TextBuf::<2>::new();
        b.push_str("xyz");
        assert!(b.truncated());
        b.clear();
        assert!(b.is_empty());
        assert!(!b.truncated());
    }

    fn fixed(v: f32, d: u8) -> TextBuf<24> {
        uformat!(24, "{}", fx(v, d))
    }

    #[test]
    fn floats_format_as_fixed_point() {
        assert_eq!(fixed(1.5, 2).as_bytes(), b"1.50");
        assert_eq!(fixed(-1.5, 2).as_bytes(), b"-1.50");
        assert_eq!(fixed(0.0, 2).as_bytes(), b"0.00");
        assert_eq!(fixed(1.23456, 3).as_bytes(), b"1.235");
        assert_eq!(fixed(12.0, 0).as_bytes(), b"12");
    }

    #[test]
    fn fractions_keep_their_leading_zeros() {
        assert_eq!(fixed(1.0625, 3).as_bytes(), b"1.063");
        assert_eq!(fixed(2.004, 3).as_bytes(), b"2.004");
        assert_eq!(fixed(2.04, 3).as_bytes(), b"2.040");
    }

    #[test]
    fn non_finite_floats_are_readable() {
        assert_eq!(fixed(f32::NAN, 2).as_bytes(), b"NaN");
        assert_eq!(fixed(f32::INFINITY, 2).as_bytes(), b"inf");
        assert_eq!(fixed(f32::NEG_INFINITY, 2).as_bytes(), b"-inf");
    }

    #[test]
    fn derefs_and_converts_for_drawing() {
        let s = uformat!(8, "{}", 5u32);
        // Both of these are how `Gfx::text` will receive it.
        let via_as_ref: &[u8] = s.as_ref();
        let via_deref: &[u8] = &s;
        assert_eq!(via_as_ref, b"5");
        assert_eq!(via_deref, b"5");
    }

    #[test]
    fn debug_output_is_readable() {
        let s = uformat!(8, "{}", 42u32);
        assert_eq!(std::format!("{s:?}"), "\"42\"");
    }
}
