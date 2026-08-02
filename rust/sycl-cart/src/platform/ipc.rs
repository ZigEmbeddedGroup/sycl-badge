//! The shared cart/OS memory block.
//!
//! Mirrors `CartIPCData` in `src/os/cart/api.zig`. The badge maps it at
//! `0x20020004` and the simulator at `4`, but the *offsets within it* are
//! identical, so they live here once. Cross-checked against
//! `simulator/src/constants.ts`.
//!
//! ```text
//! offset  field                       badge addr    sim addr
//! 0x00    controls: u16               0x20020004    0x04
//! 0x02    light_level: u16            0x20020006    0x06
//! 0x04    neopixels: [{g,r,b}; 5]     0x20020008    0x08
//! 0x13    (padding)
//! 0x18    red_led: u8                 0x2002001C    0x1c
//! 0x1a    battery_level: u16          0x2002001E    0x1e
//! 0x1c    framebuffer(s)              0x20020020    0x20
//! ```
//!
//! The badge has two framebuffers and a further block of fields after them
//! (trace buffer, tone parameters, dirty rect); those are badge-only and live in
//! `platform::badge`.

/// Button/joystick bitfield. Bit order must match `ButtonPoller.Buttons` in
/// `src/os/kernel.zig` and `Controls` in `src/os/cart/api.zig`.
pub const CONTROLS: usize = 0x00;
/// Ambient light sensor, 12 bits significant.
pub const LIGHT_LEVEL: usize = 0x02;
/// Five neopixels, three bytes each, in **G, R, B** order.
pub const NEOPIXELS: usize = 0x04;
/// The red LED on the back of the board.
pub const RED_LED: usize = 0x18;
/// Battery level, 12 bits significant.
pub const BATTERY_LEVEL: usize = 0x1a;
/// Start of the framebuffer region.
pub const FRAMEBUFFER: usize = 0x1c;

/// Bytes in one framebuffer: 160 * 128 * 2.
pub const FRAMEBUFFER_BYTES: usize = crate::gfx::WIDTH * crate::gfx::HEIGHT * 2;
