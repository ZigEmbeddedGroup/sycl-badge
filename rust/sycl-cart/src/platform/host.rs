//! Host stub, so `cargo test` can exercise the portable code (drawing, sprite
//! transposition, the audio sequencer) without a simulator or hardware.
//!
//! Uses the simulator's pixel encoding so tests match what the simulator sees.
//! The badge's encoding differs — see `badge::encode565` — so a test must never
//! assert on a raw `Color` value, only on components round-tripped through
//! `decode565`.

use crate::audio::{Shape, ToneLen};
use crate::gfx::{Rect, HEIGHT, WIDTH};

#[inline]
pub const fn encode565(r: u8, g: u8, b: u8) -> u16 {
    let rgb = ((r as u16) << 11) | ((g as u16) << 5) | (b as u16);
    rgb.swap_bytes()
}

#[inline]
pub const fn decode565(v: u16) -> (u8, u8, u8) {
    let rgb = v.swap_bytes();
    (
        (rgb >> 11) as u8,
        ((rgb >> 5) & 0x3f) as u8,
        (rgb & 0x1f) as u8,
    )
}

// A stand-in for the shared framebuffer, so the real flush path is exercised on
// the host and tests can assert on what would have reached the display.
struct Shadow(core::cell::UnsafeCell<[u16; WIDTH * HEIGHT]>);
unsafe impl Sync for Shadow {}
static SHADOW: Shadow = Shadow(core::cell::UnsafeCell::new([0; WIDTH * HEIGHT]));

pub fn present(buf: &[u16; WIDTH * HEIGHT], dirty: Option<Rect>) {
    if let Some(r) = dirty {
        // SAFETY: single-threaded, and `SHADOW` is exactly one framebuffer laid
        // out like the backbuffer.
        unsafe { crate::gfx::flush_rect(buf, r, SHADOW.0.get() as *mut u32) };
    }
}

/// What the display would be showing. Host builds only.
pub fn displayed() -> &'static [u16; WIDTH * HEIGHT] {
    // SAFETY: single-threaded; callers only read.
    unsafe { &*SHADOW.0.get() }
}

pub fn controls() -> u16 {
    0
}
pub fn light_level() -> u16 {
    0
}
pub fn battery_level() -> u16 {
    0
}
pub fn set_neopixel(_index: usize, _r: u8, _g: u8, _b: u8) {}
pub fn set_red_led(_on: bool) {}

pub fn tone(_freq_hz: f32, _len: ToneLen, _volume: f32, _shape: Shape) {}
pub fn stop() {}
pub fn set_global_volume(_volume: f32) {}
pub const SUSTAIN_REFRESH_FRAMES: u16 = 200;
pub const GLOBAL_VOLUME_IN_HARDWARE: bool = false;

pub fn trace(_bytes: &[u8]) {
    #[cfg(test)]
    if let Ok(s) = core::str::from_utf8(_bytes) {
        std::println!("[cart] {s}");
    }
}

pub fn entropy() -> u32 {
    0x1234_5678
}

pub fn save_read(_offset: u32, _dst: &mut [u8]) -> usize {
    0
}
pub fn save_write_page(_page: u16, _src: &[u8; 256]) {}

pub fn abort() -> ! {
    panic!("cart aborted")
}
