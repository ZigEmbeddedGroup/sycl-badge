//! Simulator backend (`wasm32-unknown-unknown`).
//!
//! The simulator owns the linear memory (`env.memory`, 64 fixed pages) and
//! composites the framebuffer out of it after each `update()`. See
//! `simulator/src/runtime.ts` and `simulator/src/framebuffer.ts`.

use crate::audio::ToneLen;
use crate::gfx::{self, Rect, HEIGHT, WIDTH};
use crate::platform::ipc;

/// Base of the shared IPC block in the simulator's memory map.
const BASE: usize = 4;

mod env {
    #[link(wasm_import_module = "env")]
    extern "C" {
        pub fn trace(ptr: *const u8, len: usize);
        pub fn tone(frequency: u32, duration: u32, volume: u32, flags: u32);
        pub fn rand() -> u32;
        pub fn read_flash(offset: u32, dst: *mut u8, len: u32) -> u32;
        pub fn write_flash_page(page: u32, src: *const u8);
    }
}

// ── Pixel encoding ──────────────────────────────────────────────────────────
//
// `Framebuffer.drawPoint` stores `((color & 0xff) << 8) | (color >> 8)`, i.e.
// byte-swapped RGB565.

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

// ── Display ─────────────────────────────────────────────────────────────────

#[inline]
fn shared_fb() -> *mut u32 {
    (BASE + ipc::FRAMEBUFFER) as *mut u32
}

/// Copy the dirty region of the backbuffer into the simulator's framebuffer.
///
/// There is no handshake: the host composites once `update()` returns.
pub fn present(buf: &[u16; WIDTH * HEIGHT], dirty: Option<Rect>) {
    if let Some(r) = dirty {
        // SAFETY: `shared_fb()` points at 40 KiB of framebuffer inside the
        // imported memory, and `flush_rect` writes only within `r`, which is
        // already clipped to the screen.
        unsafe { gfx::flush_rect(buf, r, shared_fb()) };
    }
}

// ── Input and sensors ───────────────────────────────────────────────────────

macro_rules! read_ipc {
    ($ty:ty, $off:expr) => {
        // SAFETY: the offset is inside the IPC block, which the host keeps
        // populated. Volatile because the host writes it between our frames.
        unsafe { ((BASE + $off) as *const $ty).read_volatile() }
    };
}

macro_rules! write_ipc {
    ($ty:ty, $off:expr, $val:expr) => {
        // SAFETY: as above; this field is ours to write.
        unsafe { ((BASE + $off) as *mut $ty).write_volatile($val) }
    };
}

pub fn controls() -> u16 {
    read_ipc!(u16, ipc::CONTROLS)
}

pub fn light_level() -> u16 {
    read_ipc!(u16, ipc::LIGHT_LEVEL) & 0x0fff
}

pub fn battery_level() -> u16 {
    read_ipc!(u16, ipc::BATTERY_LEVEL) & 0x0fff
}

pub fn set_neopixel(index: usize, r: u8, g: u8, b: u8) {
    if index >= 5 {
        return;
    }
    let off = ipc::NEOPIXELS + index * 3;
    write_ipc!(u8, off, g);
    write_ipc!(u8, off + 1, r);
    write_ipc!(u8, off + 2, b);
}

pub fn set_red_led(on: bool) {
    write_ipc!(u8, ipc::RED_LED, on as u8);
}

// ── Audio ───────────────────────────────────────────────────────────────────
//
// The simulator runs the full WASM-4 APU (four channels, ADSR, slides, panning).
// We deliberately drive only what the badge's buzzer can do: one square-wave
// voice, no envelope, no slide. See `simulator/src/apu-worklet.ts`.

/// Channel 0 (pulse1), duty mode 2 (= 50%), centre pan.
///
/// 50% is what the badge drives for maximum volume
/// (`src/os/drivers/audio.zig`); mode 0 would be 1/8 and sound thinner.
const FLAGS_SQUARE_50: u32 = 2 << 2;

pub fn tone(freq_hz: f32, len: ToneLen, volume: f32) {
    let vol = clamp01(volume);
    if freq_hz <= 0.0 || vol <= 0.0 {
        stop();
        return;
    }

    // `sustain` is the low byte of `duration`, in frames. `Sustained` is
    // re-armed by the sequencer well before this expires; re-arming while the
    // note is still sounding preserves phase, so it does not click.
    let frames = match len {
        ToneLen::Frames(f) => f.clamp(1, 255) as u32,
        ToneLen::Sustained => 255,
    };

    let v = (vol * 100.0 + 0.5) as u32;
    let v = if v > 100 { 100 } else { v };

    let f = freq_hz as u32;
    let f = if f > 0xffff { 0xffff } else { f };

    // SAFETY: plain call into a host import.
    unsafe {
        // sustainVolume in the low byte, peakVolume in the next; equal, so the
        // (unused, attack == 0) attack ramp cannot introduce a level jump.
        env::tone(f, frames, v | (v << 8), FLAGS_SQUARE_50)
    };
}

pub fn stop() {
    // All-zero durations put `releaseTime == startTime`, and `process()` gates
    // on `time < releaseTime`, so the channel goes silent immediately.
    unsafe { env::tone(0, 0, 0, FLAGS_SQUARE_50) };
}

/// The simulator has no global volume control, so we fold it into per-note
/// volume instead (see `audio::Audio`).
pub fn set_global_volume(_volume: f32) {}

/// The simulator cannot scale volume for us.
pub const GLOBAL_VOLUME_IN_HARDWARE: bool = false;

/// How many frames a `Sustained` note may run before it must be re-armed.
/// The `sustain` field is 8 bits of frames, so anything below 255 works.
pub const SUSTAIN_REFRESH_FRAMES: u16 = 200;

fn clamp01(v: f32) -> f32 {
    v.clamp(0.0, 1.0)
}

// ── Misc services ───────────────────────────────────────────────────────────

pub fn trace(bytes: &[u8]) {
    // SAFETY: pointer and length describe a live slice in our own memory.
    unsafe { env::trace(bytes.as_ptr(), bytes.len()) };
}

pub fn entropy() -> u32 {
    // SAFETY: plain call into a host import.
    unsafe { env::rand() }
}

/// Frames are exactly 1/60 s: the simulator runs a fixed timestep with catch-up
/// (`simulator/src/ui/app.ts`). There is no wall clock import, so the frame
/// counter in [`crate::Ctx`] is the only portable notion of time.
pub const FRAME_MICROS: u32 = 16_667;

pub fn save_read(offset: u32, dst: &mut [u8]) -> usize {
    // SAFETY: `dst` is a live slice and we pass its true length.
    unsafe { env::read_flash(offset, dst.as_mut_ptr(), dst.len() as u32) as usize }
}

pub fn save_write_page(page: u16, src: &[u8; 256]) {
    // SAFETY: `src` is exactly the 256 bytes the host expects.
    unsafe { env::write_flash_page(page as u32, src.as_ptr()) };
}

/// Trap. The simulator converts the trap into its blue screen; parking in a
/// loop here would instead hang the browser's main thread and the user would
/// never see the panic message.
pub fn abort() -> ! {
    core::arch::wasm32::unreachable()
}
