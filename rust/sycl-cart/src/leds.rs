//! The five neopixels and the red LED on the back.

use crate::platform;

/// Write-through access to the board's LEDs. Values land in the shared IPC block
/// and the OS drives the hardware; there is nothing to flush.
pub struct Leds {
    _private: (),
}

/// How many neopixels the board has.
pub const NEOPIXEL_COUNT: usize = 5;

impl Leds {
    pub(crate) const NEW: Leds = Leds { _private: () };

    /// Set one neopixel from 8-bit RGB. Indices past the end are ignored.
    ///
    /// Note these are true-color, unlike the RGB565 screen.
    #[inline]
    pub fn set(&mut self, index: usize, r: u8, g: u8, b: u8) {
        platform::set_neopixel(index, r, g, b);
    }

    /// Set one neopixel from a `0xRRGGBB` literal.
    #[inline]
    pub fn set_hex(&mut self, index: usize, rgb: u32) {
        self.set(index, (rgb >> 16) as u8, (rgb >> 8) as u8, rgb as u8);
    }

    /// Set all five to the same color.
    pub fn set_all(&mut self, r: u8, g: u8, b: u8) {
        for i in 0..NEOPIXEL_COUNT {
            self.set(i, r, g, b);
        }
    }

    /// Turn every neopixel off.
    pub fn clear(&mut self) {
        self.set_all(0, 0, 0);
    }

    /// The red LED on the back of the board.
    #[inline]
    pub fn set_red(&mut self, on: bool) {
        platform::set_red_led(on);
    }
}
