//! Badge backend (`thumbv8m.main-none-eabihf`, RP2354B Cortex-M33, Core 1).
//!
//! The OS kernel runs on Core 0 and owns every peripheral. A cart talks to it
//! through the shared IPC block and the RP2350 inter-core SIO FIFO — there is no
//! syscall table and nothing to link against. See `src/os/ipc/mailbox.zig`.
//!
//! The entry point is `cortex-m-rt`'s, laid out by `../../memory.x`; `cart!`
//! supplies the frame loop and `cargo xtask uf2` packs the result.
//!
//! **Status: runs on hardware.** `showcase/fill` draws, reads buttons and paces
//! on `present`, so the display, input and handshake paths below are confirmed.
//! The audio path and the neopixels are not: nothing has driven them on a badge.

use crate::audio::{Shape, ToneLen};
use crate::gfx::{self, Rect, HEIGHT, WIDTH};
use crate::platform::ipc;
use core::sync::atomic::{AtomicBool, Ordering};

/// Base of `CartIPCData`, at the start of `process_ram` (`src/os/cart/api.zig`).
const BASE: usize = 0x2002_0004;

// Badge-only fields, which sit after the *two* framebuffers. Offsets derived
// from the field order in `CartIPCData`; note that the address comments in
// `src/cart/cart_xip.ld` are stale (they place the dirty rect at 0x200340B0,
// but the struct puts it at 0x200340A8). The struct is the source of truth.
const AFTER_FRAMEBUFFERS: usize = ipc::FRAMEBUFFER + 2 * ipc::FRAMEBUFFER_BYTES;
const TRACE_BUF: usize = AFTER_FRAMEBUFFERS; // 0x20034020, 128 bytes
const TONE_FREQ: usize = TRACE_BUF + 0x80; // 0x200340A0, f32
const TONE_DURATION: usize = TONE_FREQ + 4; // 0x200340A4, f32 seconds
const DIRTY_X: usize = TONE_DURATION + 4; // 0x200340A8, u16 x4
const TONE_VOLUME: usize = DIRTY_X + 8; // 0x200340B0, f32
const TONE_FLAGS: usize = TONE_VOLUME + 4; // 0x200340B4, u32
const GLOBAL_VOLUME: usize = TONE_FLAGS + 4; // 0x200340B8, f32

/// Longest trace message the kernel will read, minus the NUL it expects.
const TRACE_MAX: usize = 127;

// RP2350 SIO inter-core FIFO. Same addresses on both cores; each sees its own
// side of the pair.
const SIO_FIFO_ST: *mut u32 = 0xD000_0050 as *mut u32;
const SIO_FIFO_WR: *mut u32 = 0xD000_0054 as *mut u32;
const SIO_FIFO_RD: *mut u32 = 0xD000_0058 as *mut u32;
const FIFO_VLD: u32 = 1 << 0; // read FIFO has data
const FIFO_RDY: u32 = 1 << 1; // write FIFO has space

// Message types, from `MessageType` in `src/os/ipc/mailbox.zig`.
const FRAMEBUFFER_READY_V2: u32 = 0x28;
const FRAMEBUFFER_DONE: u32 = 0x2500_0002;
const CART_TRACE: u32 = 0x26;
const CART_TONE: u32 = 0x27;
const CART_VOLUME: u32 = 0x29;

/// Bounds every FIFO wait so a wedged kernel cannot hang the cart forever.
/// Mirrors `present_wait_time_limit` in `src/os/cart/api.zig`.
const WAIT_LIMIT_MICROS: u64 = 500_000;

/// True while the kernel is DMA'ing a published frame to the LCD.
static FRAME_IN_FLIGHT: AtomicBool = AtomicBool::new(false);

// ── Pixel encoding ──────────────────────────────────────────────────────────
//
// The kernel DMAs the framebuffer straight out to the ST7735S. The panel reads
// each pixel as the two bytes [BBBBB_GGG, ggg_RRRRR] — R and B swapped relative
// to the simulator — and the SPI block runs in 16-bit mode, which shifts each
// halfword out most-significant byte first. So the halfword we store is plain
// BGR565 and nothing byte-swaps it.
//
// This mirrors `Pixel.fromDisplayColor` in `src/os/cart/api.zig`, whose
// `DisplayColor` carries `r` in the low five bits and goes to the framebuffer
// with a bare `@bitCast`. Both halves changed together in PR #123, which moved
// the LCD from byte-at-a-time SPI to 16-bit DMA; the bytes on the wire are the
// same as before, so a swap here would now put them in the wrong order.

#[inline]
pub const fn encode565(r: u8, g: u8, b: u8) -> u16 {
    ((b as u16) << 11) | ((g as u16) << 5) | (r as u16)
}

#[inline]
pub const fn decode565(v: u16) -> (u8, u8, u8) {
    ((v & 0x1f) as u8, ((v >> 5) & 0x3f) as u8, (v >> 11) as u8)
}

// Pin the wire format. A silent R/B swap is the failure mode here, and it costs
// a hardware flash to notice, so make the byte order a build error instead.
const _: () = assert!(
    encode565(31, 0, 0) == 0x001f,
    "red goes in the low five bits"
);
const _: () = assert!(
    encode565(0, 0, 31) == 0xf800,
    "blue goes in the high five bits"
);
const _: () = assert!(encode565(0, 63, 0) == 0x07e0);

// ── Raw IPC access ──────────────────────────────────────────────────────────

#[inline]
fn read_at<T>(offset: usize) -> T {
    // SAFETY: `offset` is a compile-time constant inside the IPC block, which
    // the kernel keeps mapped and populated. Volatile because Core 0 writes it
    // concurrently.
    unsafe { ((BASE + offset) as *const T).read_volatile() }
}

#[inline]
fn write_at<T>(offset: usize, value: T) {
    // SAFETY: as above; these fields are the cart's to write.
    unsafe { ((BASE + offset) as *mut T).write_volatile(value) }
}

/// Send one message to Core 0, after making sure everything it describes is
/// visible.
///
/// Every message here is a pointer in disguise: `CART_TONE` means "the tone
/// fields are set", `CART_TRACE` means "the buffer holds a string". Those fields
/// are ordinary SRAM and the FIFO is Device memory, and the two are not ordered
/// against each other on a Cortex-M33 — the store buffer can still be holding
/// the SRAM writes when Core 0 reads them. Core 0 drains this FIFO every pass of
/// its main loop, so it is genuinely quick enough to look early, and what it
/// would read is the previous message's values, or zeroes on the first one. A
/// zero frequency reads as `stop()` in `src/os/drivers/audio.zig`.
///
/// So: barrier first, every time. It is one instruction on a path that already
/// costs a FIFO round trip.
#[inline]
fn fifo_write(msg: u32) -> bool {
    let start = micros_since_boot();
    // SAFETY: barrier instruction, then fixed MMIO addresses on the RP2350.
    unsafe {
        core::arch::asm!("dsb", options(nomem, nostack));
        while SIO_FIFO_ST.read_volatile() & FIFO_RDY == 0 {
            if micros_since_boot().wrapping_sub(start) >= WAIT_LIMIT_MICROS {
                return false;
            }
            core::arch::asm!("nop", options(nomem, nostack));
        }
        SIO_FIFO_WR.write_volatile(msg);
        // Wake Core 0 if it parked in WFE.
        core::arch::asm!("sev", options(nomem, nostack));
    }
    true
}

/// Drain the reply FIFO, clearing the in-flight flag if the kernel finished a
/// flush. Never blocks.
fn drain_replies() {
    // SAFETY: fixed MMIO addresses.
    unsafe {
        while SIO_FIFO_ST.read_volatile() & FIFO_VLD != 0 {
            if SIO_FIFO_RD.read_volatile() == FRAMEBUFFER_DONE {
                FRAME_IN_FLIGHT.store(false, Ordering::Relaxed);
            }
        }
    }
}

/// Block until the kernel has finished DMA'ing the previously published frame.
///
/// We publish a single shared buffer, so the copy in [`present`] must not begin
/// until the DMA reading that buffer has completed. Bounded by wall-clock time
/// rather than a spin count, so the limit means the same thing whatever the
/// optimizer does to the loop — the same reason `src/os/cart/api.zig` switched.
fn wait_for_flush() {
    if !FRAME_IN_FLIGHT.load(Ordering::Relaxed) {
        return;
    }
    let start = micros_since_boot();
    while FRAME_IN_FLIGHT.load(Ordering::Relaxed) {
        drain_replies();
        if !FRAME_IN_FLIGHT.load(Ordering::Relaxed) {
            break;
        }
        if micros_since_boot().wrapping_sub(start) >= WAIT_LIMIT_MICROS {
            // Give up rather than wedge Core 1. The next frame will re-publish.
            FRAME_IN_FLIGHT.store(false, Ordering::Relaxed);
            return;
        }
        // SAFETY: hint instruction, no memory effects.
        unsafe { core::arch::asm!("nop", options(nomem, nostack)) };
    }
}

// ── Display ─────────────────────────────────────────────────────────────────

#[inline]
fn shared_fb() -> *mut u32 {
    (BASE + ipc::FRAMEBUFFER) as *mut u32
}

/// Publish the dirty region: wait for the previous flush, copy, then hand the
/// rectangle to Core 0.
///
/// Only framebuffer 0 is ever used. The OS provides two so a cart can draw while
/// a DMA is in flight, but we already get that from the private backbuffer — and
/// alternating buffers would mean each one is two frames stale outside the dirty
/// region, forcing every flush to cover a two-frame union.
pub fn present(buf: &[u16; WIDTH * HEIGHT], dirty: Option<Rect>) {
    let Some(r) = dirty else { return };

    wait_for_flush();

    // SAFETY: `shared_fb()` is framebuffer 0 inside the IPC block, and
    // `flush_rect` writes only within `r`, which is clipped to the screen.
    unsafe { gfx::flush_rect(buf, r, shared_fb()) };

    write_at::<u16>(DIRTY_X, r.x);
    write_at::<u16>(DIRTY_X + 2, r.y);
    write_at::<u16>(DIRTY_X + 4, r.w);
    write_at::<u16>(DIRTY_X + 6, r.h);

    // The pixels and the rect have to land before Core 0 sees the message;
    // `fifo_write` carries the barrier that guarantees it.
    // payload bit 0 = buffer index (always 0), bit 1 = dirty rect valid.
    if fifo_write((FRAMEBUFFER_READY_V2 << 24) | 0x2) {
        FRAME_IN_FLIGHT.store(true, Ordering::Relaxed);
    }
}

// ── Input and sensors ───────────────────────────────────────────────────────

pub fn controls() -> u16 {
    read_at::<u16>(ipc::CONTROLS)
}

pub fn light_level() -> u16 {
    read_at::<u16>(ipc::LIGHT_LEVEL) & 0x0fff
}

pub fn battery_level() -> u16 {
    read_at::<u16>(ipc::BATTERY_LEVEL) & 0x0fff
}

pub fn set_neopixel(index: usize, r: u8, g: u8, b: u8) {
    if index >= 5 {
        return;
    }
    let off = ipc::NEOPIXELS + index * 3;
    write_at::<u8>(off, g);
    write_at::<u8>(off + 1, r);
    write_at::<u8>(off + 2, b);
}

pub fn set_red_led(on: bool) {
    write_at::<u8>(ipc::RED_LED, on as u8);
}

// ── Audio ───────────────────────────────────────────────────────────────────

pub fn tone(freq_hz: f32, len: ToneLen, volume: f32, shape: Shape) {
    let duration = match len {
        // The kernel arms a DMA transfer count, so finite notes end on their own.
        ToneLen::Frames(f) => f as f32 / 60.0,
        // Exactly -1.0 means endless; see `src/os/drivers/audio.zig`.
        ToneLen::Sustained => -1.0,
    };
    write_at::<f32>(TONE_FREQ, freq_hz);
    write_at::<f32>(TONE_DURATION, duration);
    write_at::<f32>(TONE_VOLUME, volume);
    // Bits 0-2 select the wave shape. The kernel passes them straight to
    // `audio.tone` (`src/os/kernel.zig`), which reads `flags & 0x7`.
    write_at::<u32>(TONE_FLAGS, shape as u32);
    fifo_write(CART_TONE << 24);
}

pub fn stop() {
    tone(0.0, ToneLen::Frames(0), 0.0, Shape::Square);
}

pub fn set_global_volume(volume: f32) {
    write_at::<f32>(GLOBAL_VOLUME, volume);
    fifo_write(CART_VOLUME << 24);
}

/// The OS applies global volume in the buzzer driver, so notes must not be
/// pre-scaled by it as well.
pub const GLOBAL_VOLUME_IN_HARDWARE: bool = true;

/// Zero means "no refresh needed": the buzzer holds an endless tone by itself.
pub const SUSTAIN_REFRESH_FRAMES: u16 = 0;

// ── Misc services ───────────────────────────────────────────────────────────

/// Copy into the shared trace buffer and ask the kernel to print it over USB CDC.
///
/// The kernel drains the FIFO once per loop iteration, so several traces inside
/// one frame can be coalesced or lost. Treat this as a low-rate debug channel,
/// not a log stream.
pub fn trace(bytes: &[u8]) {
    let len = if bytes.len() > TRACE_MAX {
        TRACE_MAX
    } else {
        bytes.len()
    };
    for (i, b) in bytes[..len].iter().enumerate() {
        write_at::<u8>(TRACE_BUF + i, *b);
    }
    write_at::<u8>(TRACE_BUF + len, 0);
    fifo_write((CART_TRACE << 24) | len as u32);
}

/// One `u32` from the RP2350 ring oscillator. Slow (32 sampled bits), so use it
/// to seed [`crate::Rng`] rather than calling it per frame.
pub fn entropy() -> u32 {
    const ROSC_STATUS: *const u32 = 0x4006_000C as *const u32;
    let mut out: u32 = 0;
    for _ in 0..32 {
        // SAFETY: fixed MMIO address, read-only.
        let bit = unsafe { ROSC_STATUS.read_volatile() } >> 16 & 1;
        out = (out << 1) | bit;
    }
    out
}

/// Free-running 1 MHz microsecond counter (`TIMER0`). Read LR before HR: reading
/// LR latches HR on this hardware.
pub fn micros_since_boot() -> u64 {
    const TIMER0_TIMEHR: *const u32 = 0x400b_0008 as *const u32;
    const TIMER0_TIMELR: *const u32 = 0x400b_000c as *const u32;
    // SAFETY: fixed MMIO addresses, read-only.
    unsafe {
        let lo = TIMER0_TIMELR.read_volatile();
        let hi = TIMER0_TIMEHR.read_volatile();
        ((hi as u64) << 32) | lo as u64
    }
}

/// No cart save-data region exists on v2 yet: `read_flash`/`write_flash_page`
/// are no-op stubs in `src/os/cart/api.zig`. The API is reserved so adding
/// storage later is additive.
pub fn save_read(_offset: u32, _dst: &mut [u8]) -> usize {
    0
}

pub fn save_write_page(_page: u16, _src: &[u8; 256]) {}

/// Park. Holding Start+Select for 250 ms makes the OS halt Core 1 and return to
/// the menu, so a panicked cart is recoverable without a power cycle.
pub fn abort() -> ! {
    loop {
        // SAFETY: wait-for-event, no memory effects.
        unsafe { core::arch::asm!("wfe", options(nomem, nostack)) };
    }
}

/// Take over Core 1: mask interrupts and set the FPU up for our own use.
///
/// Called once from the entry point, before any cart code runs. Everything the
/// framework does is polled, so interrupts stay masked for the life of the
/// cart, exactly as `cart_entry.zig` does for a Zig cart.
///
/// The OS has already masked interrupts and cleared Core 1's NVIC and fault
/// state before it jumps here (`src/os/cart.zig`), and `cortex-m-rt` enables
/// CP10/CP11 for an `-eabihf` target. Both are repeated anyway: they are two
/// register writes, they are idempotent, and depending on the last thing that
/// ran on this core is how bring-up bugs get written.
pub fn init() {
    const CPACR: *mut u32 = 0xE000_ED88 as *mut u32;
    const FPCCR: *mut u32 = 0xE000_EF34 as *mut u32;

    // SAFETY: interrupt-mask instruction, then two fixed system-control
    // addresses. Core 1's FPU context is ours alone.
    unsafe {
        core::arch::asm!("cpsid i", options(nomem, nostack));

        // Full access to CP10 and CP11, so FPU instructions do not trap.
        CPACR.write_volatile(CPACR.read_volatile() | (0xF << 20));
        // ASPEN | LSPEN: automatic and lazy FP context preservation.
        FPCCR.write_volatile(FPCCR.read_volatile() | (1 << 31) | (1 << 30));

        core::arch::asm!("dsb", "isb", options(nomem, nostack));
    }
}

/// Report a fault through the trace channel, then park.
///
/// Worth the flash during bring-up: without it a fault is a silent freeze, and
/// with it the address that faulted reaches the console over USB CDC.
pub fn report_fault(kind: &str, pc: u32, lr: u32) -> ! {
    let mut buf = [0u8; 64];
    let mut n = 0;
    let mut put = |bytes: &[u8]| {
        for &b in bytes {
            if n < buf.len() {
                buf[n] = b;
                n += 1;
            }
        }
    };
    put(b"[FAULT] ");
    put(kind.as_bytes());
    put(b" pc=");
    put(&hex32(pc));
    put(b" lr=");
    put(&hex32(lr));
    trace(&buf[..n]);
    abort()
}

fn hex32(v: u32) -> [u8; 8] {
    const DIGITS: &[u8; 16] = b"0123456789abcdef";
    let mut out = [b'0'; 8];
    let mut i = 0;
    while i < 8 {
        out[7 - i] = DIGITS[((v >> (i * 4)) & 0xf) as usize];
        i += 1;
    }
    out
}
