//! Colors, stored pre-encoded for the active target.

use crate::platform;

/// A screen color, stored in the exact layout the target's framebuffer wants —
/// byte-swapped RGB565 in the simulator, plain BGR565 on the badge (whose
/// halfwords are DMA'd straight to the ST7735 over 16-bit SPI).
///
/// Because the encoding happens in a `const fn`, color literals and sprite data
/// are converted at compile time and every drawing routine is a plain memory
/// write. There is no per-pixel conversion anywhere in the framework.
///
/// Consequence worth knowing: the raw `u16` is *not* portable. Never persist it
/// or share it between targets; rebuild it from components instead.
#[derive(Copy, Clone, PartialEq, Eq, Default, Debug)]
#[repr(transparent)]
pub struct Color(pub u16);

impl Color {
    /// From native RGB565 components: `r`/`b` are 0..=31, `g` is 0..=63.
    /// Out-of-range values are masked, not clamped.
    #[inline]
    pub const fn new(r: u8, g: u8, b: u8) -> Self {
        Color(platform::encode565(r & 0x1f, g & 0x3f, b & 0x1f))
    }

    /// From 8-bit-per-channel components, truncating to 5/6/5.
    #[inline]
    pub const fn rgb8(r: u8, g: u8, b: u8) -> Self {
        Color::new(r >> 3, g >> 2, b >> 3)
    }

    /// From a `0xRRGGBB` literal.
    #[inline]
    pub const fn hex(rgb: u32) -> Self {
        Color::rgb8((rgb >> 16) as u8, (rgb >> 8) as u8, rgb as u8)
    }

    /// Decode back into native RGB565 components. Mostly for tests.
    #[inline]
    pub const fn components(self) -> (u8, u8, u8) {
        platform::decode565(self.0)
    }

    /// Blend toward `other`, with `t` clamped to `0.0..=1.0`.
    ///
    /// Runs at runtime (unlike the constructors) because it decodes, mixes and
    /// re-encodes. Cheap enough for a per-frame flash or fade, but do not put it
    /// in a per-pixel loop — pre-compute the colour and reuse it.
    pub fn mix(self, other: Color, t: f32) -> Color {
        let t = t.clamp(0.0, 1.0);
        let (r0, g0, b0) = self.components();
        let (r1, g1, b1) = other.components();
        let blend = |a: u8, b: u8| (a as f32 + (b as f32 - a as f32) * t + 0.5) as u8;
        Color::new(blend(r0, r1), blend(g0, g1), blend(b0, b1))
    }

    pub const BLACK: Color = Color::new(0, 0, 0);
    pub const WHITE: Color = Color::new(31, 63, 31);
    pub const RED: Color = Color::new(31, 0, 0);
    pub const GREEN: Color = Color::new(0, 63, 0);
    pub const BLUE: Color = Color::new(0, 0, 31);
    pub const YELLOW: Color = Color::new(31, 63, 0);
    pub const CYAN: Color = Color::new(0, 63, 31);
    pub const MAGENTA: Color = Color::new(31, 0, 31);
}

#[cfg(test)]
mod tests {
    use super::Color;

    #[test]
    fn round_trips_components() {
        for (r, g, b) in [(0, 0, 0), (31, 63, 31), (1, 2, 3), (17, 40, 9)] {
            assert_eq!(Color::new(r, g, b).components(), (r, g, b));
        }
    }

    #[test]
    fn distinct_channels_encode_distinctly() {
        assert_ne!(Color::RED, Color::BLUE);
        assert_ne!(Color::RED.0, 0);
        assert_ne!(Color::BLUE.0, 0);
    }
}
