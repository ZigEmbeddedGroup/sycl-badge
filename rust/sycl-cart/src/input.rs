//! Buttons and joystick, with edge detection.

use crate::platform;

/// A physical control. Bit positions must match `Controls` in
/// `src/os/cart/api.zig` and `ButtonPoller.Buttons` in `src/os/kernel.zig`.
#[derive(Copy, Clone, PartialEq, Eq, Debug)]
#[repr(u8)]
pub enum Button {
    Start = 0,
    Select = 1,
    A = 2,
    B = 3,
    /// The joystick pressed straight in.
    Click = 4,
    Up = 5,
    Down = 6,
    Left = 7,
    Right = 8,
}

impl Button {
    #[inline]
    pub const fn mask(self) -> u16 {
        1 << self as u16
    }
}

/// A two-frame snapshot of the controls, so edges are available without the
/// cart tracking previous state itself.
///
/// This is `Copy` and four bytes wide on purpose: it never participates in a
/// borrow, so `c.input` stays readable while other parts of [`crate::Ctx`] are
/// mutably borrowed.
#[derive(Copy, Clone, PartialEq, Eq, Default, Debug)]
pub struct Input {
    held: u16,
    prev: u16,
}

impl Input {
    pub const NEW: Input = Input { held: 0, prev: 0 };

    pub(crate) fn poll(&mut self) {
        self.prev = self.held;
        self.held = platform::controls() & 0x01ff;
    }

    /// Currently down.
    #[inline]
    pub fn held(self, b: Button) -> bool {
        self.held & b.mask() != 0
    }

    /// Went down this frame.
    #[inline]
    pub fn just_pressed(self, b: Button) -> bool {
        let m = b.mask();
        self.held & m != 0 && self.prev & m == 0
    }

    /// Came up this frame.
    #[inline]
    pub fn just_released(self, b: Button) -> bool {
        let m = b.mask();
        self.held & m == 0 && self.prev & m != 0
    }

    /// True if anything at all is held.
    #[inline]
    pub fn any_held(self) -> bool {
        self.held != 0
    }

    /// -1, 0 or 1 from Left/Right.
    #[inline]
    pub fn dx(self) -> i32 {
        self.held(Button::Right) as i32 - self.held(Button::Left) as i32
    }

    /// -1, 0 or 1 from Up/Down. Positive is *down*, matching screen coordinates.
    #[inline]
    pub fn dy(self) -> i32 {
        self.held(Button::Down) as i32 - self.held(Button::Up) as i32
    }

    /// The raw bitfield, for logging.
    #[inline]
    pub fn bits(self) -> u16 {
        self.held
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn edges_need_a_transition() {
        let i = Input {
            held: Button::A.mask(),
            prev: 0,
        };
        assert!(i.held(Button::A));
        assert!(i.just_pressed(Button::A));
        assert!(!i.just_released(Button::A));

        let i = Input {
            held: Button::A.mask(),
            prev: Button::A.mask(),
        };
        assert!(i.held(Button::A));
        assert!(!i.just_pressed(Button::A), "still held is not a new press");

        let i = Input {
            held: 0,
            prev: Button::A.mask(),
        };
        assert!(i.just_released(Button::A));
    }

    #[test]
    fn axes_cancel_when_opposed() {
        let i = Input {
            held: Button::Left.mask() | Button::Right.mask(),
            prev: 0,
        };
        assert_eq!(i.dx(), 0);
        let i = Input {
            held: Button::Down.mask(),
            prev: 0,
        };
        assert_eq!(i.dy(), 1);
    }

    #[test]
    fn masks_match_the_zig_bit_order() {
        assert_eq!(Button::Start.mask(), 1 << 0);
        assert_eq!(Button::A.mask(), 1 << 2);
        assert_eq!(Button::Right.mask(), 1 << 8);
    }
}
