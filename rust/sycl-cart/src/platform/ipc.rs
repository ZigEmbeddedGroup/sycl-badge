//! The simulator's shared memory block.
//!
//! Mirrors `simulator/src/constants.ts`: the simulator maps the block at
//! address `4` of the imported `env.memory`, and these are the offsets from
//! there. The badge used to share this layout, but `CartIPCData` in
//! `src/os/cart/os_abi.zig` has since been rearranged, so `platform::badge`
//! carries its own offsets.
//!
//! ```text
//! offset  field                       sim addr
//! 0x00    controls: u16               0x04
//! 0x02    light_level: u16            0x06
//! 0x04    neopixels: [{g,r,b}; 5]     0x08
//! 0x13    (padding)
//! 0x18    red_led: u8                 0x1c
//! 0x1a    battery_level: u16          0x1e
//! 0x1c    framebuffer                 0x20
//! ```

/// Button/joystick bitfield. Bit order must match `Controls` in
/// `src/os/cart/api.zig`, which `read_buttons` in `src/os/kernel.zig` fills in.
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
