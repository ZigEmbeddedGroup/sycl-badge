//! The cart entry points, the frame loop, and the state that lives in `.bss`.

use crate::audio::Audio;
use crate::gfx::{Gfx, PIXELS};
use crate::input::Input;
use crate::leds::Leds;
use crate::platform;
use crate::rng::Rng;
use crate::save::Save;
use core::cell::UnsafeCell;
use core::mem::MaybeUninit;

/// Implement this on your game type, then hand it to [`crate::cart!`].
///
/// ```ignore
/// struct Game { score: u32 }
///
/// impl Cart for Game {
///     const INIT: Self = Game { score: 0 };
///     fn update(&mut self, c: &mut Ctx) { /* ... */ }
/// }
///
/// sycl_cart::cart!(Game);
/// ```
pub trait Cart: Sized + 'static {
    /// The starting state, evaluated at compile time.
    ///
    /// This is a `const`, so it costs no code to build: it is either baked into
    /// `.data` or — when every byte is zero — costs nothing at all in `.bss`.
    /// Prefer zeroes where you can.
    ///
    /// It cannot do anything requiring runtime information (random level layout,
    /// reading save data). Do that in [`Cart::start`].
    const INIT: Self;

    /// Called once before the first frame, with the context available.
    ///
    /// Use it for setup that `INIT` cannot express — seeding a level from
    /// `c.rng`, loading a high score, starting background music.
    fn start(&mut self, _c: &mut Ctx) {}

    /// Called once per frame at 60 Hz.
    ///
    /// Draw everything you want on screen; the framework tracks which pixels
    /// changed and pushes only those. Input edges for this frame are already in
    /// `c.input`.
    ///
    /// Note the simulator runs a fixed timestep with catch-up, so after a stall
    /// this may be called several times in quick succession. Frame-counted logic
    /// handles that correctly; wall-clock logic would not.
    fn update(&mut self, c: &mut Ctx);
}

/// Everything the platform offers, handed to [`Cart::update`].
///
/// The subsystems are separate fields so they can be borrowed independently:
/// `&mut c.gfx` and `&mut c.audio` coexist, and `c.input` is `Copy` so it never
/// borrows at all.
pub struct Ctx {
    /// The drawing surface.
    pub gfx: Gfx,
    /// Tones, sound effects and music.
    pub audio: Audio,
    /// This frame's button state, with edges.
    pub input: Input,
    /// Neopixels and the red LED.
    pub leds: Leds,
    /// Seeded once at startup from platform entropy.
    pub rng: Rng,
    /// Persistent storage. Not yet functional on the badge; see [`Save`].
    pub save: Save,
    frame: u32,
}

impl Ctx {
    fn new(buf: &'static mut [u16; PIXELS]) -> Ctx {
        Ctx {
            gfx: Gfx::new(buf),
            audio: Audio::NEW,
            input: Input::NEW,
            leds: Leds::NEW,
            rng: Rng::from_entropy(),
            save: Save::NEW,
            frame: 0,
        }
    }

    /// Frames elapsed since the cart started. Wraps after ~2.3 years at 60 Hz.
    ///
    /// This is the only portable clock: the simulator exposes no wall time, so
    /// count frames rather than measuring seconds.
    #[inline]
    pub fn frame(&self) -> u32 {
        self.frame
    }

    /// Seconds since start, derived from the frame counter.
    #[inline]
    pub fn seconds(&self) -> f32 {
        self.frame as f32 / 60.0
    }

    /// Ambient light, 0..4095.
    #[inline]
    pub fn light_level(&self) -> u16 {
        platform::light_level()
    }

    /// Battery level, 0..4095.
    #[inline]
    pub fn battery_level(&self) -> u16 {
        platform::battery_level()
    }
}

// ── Statics ─────────────────────────────────────────────────────────────────
//
// Zero-initialized, so these land in .bss rather than shipping 40 KiB of data
// segment. `Ctx` is written once by `start()`.

struct Shared<T>(UnsafeCell<T>);
// SAFETY: a cart is single-threaded. The simulator drives it from one JS thread;
// on the badge it owns Core 1 with interrupts masked (src/os/cart.zig).
unsafe impl<T> Sync for Shared<T> {}

static BACKBUFFER: Shared<[u16; PIXELS]> = Shared(UnsafeCell::new([0; PIXELS]));
static CTX: Shared<MaybeUninit<Ctx>> = Shared(UnsafeCell::new(MaybeUninit::uninit()));

/// Storage for the user's cart type. Created by [`crate::cart!`]; not for direct
/// use.
#[doc(hidden)]
pub struct CartCell<T>(UnsafeCell<MaybeUninit<T>>);

// SAFETY: as above.
unsafe impl<T> Sync for CartCell<T> {}

impl<T> CartCell<T> {
    #[allow(clippy::new_without_default)]
    pub const fn new() -> CartCell<T> {
        CartCell(UnsafeCell::new(MaybeUninit::uninit()))
    }
}

/// Entry point body for `start`. Called by [`crate::cart!`].
///
/// # Safety
///
/// Must be called exactly once, before any [`update`], from the platform's
/// `start` export.
#[doc(hidden)]
pub unsafe fn start<C: Cart>(cell: &'static CartCell<C>) {
    // SAFETY: single-threaded, and these are two distinct statics, so the
    // mutable borrows do not alias. `Ctx` is initialized before it is read.
    unsafe {
        let backbuffer = &mut *BACKBUFFER.0.get();
        let ctx = (*CTX.0.get()).write(Ctx::new(backbuffer));
        let cart = (*cell.0.get()).write(C::INIT);

        ctx.input.poll();
        cart.start(ctx);
        ctx.audio.tick();
        ctx.gfx.present();
    }
}

/// Entry point body for `update`. Called by [`crate::cart!`].
///
/// # Safety
///
/// Must only be called after [`start`], from the platform's `update` export.
#[doc(hidden)]
pub unsafe fn update<C: Cart>(cell: &'static CartCell<C>) {
    // SAFETY: as in `start`; `start` has already initialized both cells.
    unsafe {
        let ctx = (*CTX.0.get()).assume_init_mut();
        let cart = (*cell.0.get()).assume_init_mut();

        ctx.frame = ctx.frame.wrapping_add(1);
        ctx.input.poll();
        cart.update(ctx);
        ctx.audio.tick();

        #[cfg(feature = "debug-overlay")]
        overlay(ctx);

        ctx.gfx.present();
    }
}

/// Frame counter and flushed-pixel count, drawn top-left.
///
/// Flushed pixels is the number worth watching: the OS skips the LCD transfer
/// entirely when nothing is dirty, so shrinking this is what buys frame rate.
#[cfg(feature = "debug-overlay")]
fn overlay(ctx: &mut Ctx) {
    use crate::color::Color;

    let area = ctx.gfx.dirty().map_or(0, |r| r.area());
    let mut line = [0u8; 24];
    let mut at = 0;
    push_bytes(&mut line, &mut at, b"f");
    push_u32(&mut line, &mut at, ctx.frame);
    push_bytes(&mut line, &mut at, b" px");
    push_u32(&mut line, &mut at, area);

    ctx.gfx
        .text_with(&line[..at], 1, 1, 1, Color::WHITE, Some(Color::BLACK));
}

#[cfg(feature = "debug-overlay")]
fn push_bytes(out: &mut [u8], at: &mut usize, s: &[u8]) {
    for &b in s {
        if *at < out.len() {
            out[*at] = b;
            *at += 1;
        }
    }
}

#[cfg(feature = "debug-overlay")]
fn push_u32(out: &mut [u8], at: &mut usize, mut v: u32) {
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
        if *at < out.len() {
            out[*at] = digits[n];
            *at += 1;
        }
    }
}

/// Declare your cart type as the program entry point.
///
/// Emits the `start` and `update` symbols the simulator calls (and, on the
/// badge, that the frame loop drives). Use it exactly once, at the crate root.
#[macro_export]
macro_rules! cart {
    ($ty:ty) => {
        #[doc(hidden)]
        static __SYCL_CART: $crate::rt::CartCell<$ty> = $crate::rt::CartCell::new();

        #[doc(hidden)]
        #[no_mangle]
        pub extern "C" fn start() {
            // SAFETY: the platform calls `start` once, before any `update`.
            unsafe { $crate::rt::start::<$ty>(&__SYCL_CART) }
        }

        #[doc(hidden)]
        #[no_mangle]
        pub extern "C" fn update() {
            // SAFETY: the platform calls `update` only after `start`.
            unsafe { $crate::rt::update::<$ty>(&__SYCL_CART) }
        }
    };
}

/// Report the panic through the trace channel, then stop.
///
/// On wasm this must *trap*, not spin: an infinite loop would hang the browser's
/// main thread and the message would never reach the console. The trap becomes
/// the simulator's blue screen. On the badge it parks, and holding Start+Select
/// returns to the menu.
#[cfg(all(
    feature = "panic-handler",
    not(test),
    any(target_arch = "wasm32", target_arch = "arm")
))]
#[panic_handler]
fn on_panic(info: &core::panic::PanicInfo) -> ! {
    crate::log::emit("PANIC ", |w| {
        if let Some(loc) = info.location() {
            let _ = ufmt::uwrite!(w, "{}:{}", loc.file(), loc.line());
        }
        #[cfg(feature = "panic-messages")]
        {
            use core::fmt::Write as _;
            let _ = w.write_str(" ");
            let _ = core::write!(w, "{}", info.message());
        }
    });
    platform::abort()
}
