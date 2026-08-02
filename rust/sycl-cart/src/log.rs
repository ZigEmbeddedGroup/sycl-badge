//! Logging that respects the hardware.
//!
//! Messages go to the simulator's console (`env.trace`) or, on the badge, into
//! the 127-byte shared trace buffer for the kernel to print over USB CDC.
//!
//! # Design constraints
//!
//! * **`core::fmt` is not used.** Rust's formatting machinery costs 10–20 KiB of
//!   flash, against a ~160 KiB cart budget. We use [`ufmt`] instead, at 1–2 KiB.
//! * **Disabled levels vanish.** Each macro is wrapped in `if ENABLED`, where
//!   `ENABLED` is a `const bool` from a cargo feature. The call, the arguments
//!   *and the format strings* are dropped by the optimizer, so a release cart
//!   carries no trace of them. They are still type-checked, so disabled logging
//!   cannot rot.
//! * **Low rate, not a stream.** On the badge the kernel drains the FIFO once
//!   per loop iteration, so several messages inside one frame may be coalesced
//!   or lost, and each one costs a FIFO round trip shared with `present`. Log
//!   state changes, not per-frame values.
//! * **`ufmt` cannot format floats.** Use [`fx`] for those.
//!
//! ```ignore
//! use sycl_cart::prelude::*;
//! info!("spawned pipe at {}", x);
//! debug!("vy={}", sycl_cart::log::fx(self.vy, 2));
//! ```

use crate::platform;
use core::cell::UnsafeCell;
use ufmt::uWrite;

/// Longest message that fits the badge's shared trace buffer, minus its NUL.
pub const MAX_LEN: usize = 127;

#[doc(hidden)]
pub const ERROR_ENABLED: bool = cfg!(feature = "log-error");
#[doc(hidden)]
pub const WARN_ENABLED: bool = cfg!(feature = "log-warn");
#[doc(hidden)]
pub const INFO_ENABLED: bool = cfg!(feature = "log-info");
#[doc(hidden)]
pub const DEBUG_ENABLED: bool = cfg!(feature = "log-debug");

/// Fixed-capacity byte sink. Overflow truncates rather than panicking: losing
/// the tail of a debug line is always better than taking down the cart.
#[doc(hidden)]
pub struct Buf {
    bytes: [u8; MAX_LEN],
    len: usize,
}

impl Buf {
    const fn new() -> Buf {
        Buf {
            bytes: [0; MAX_LEN],
            len: 0,
        }
    }

    pub fn push_bytes(&mut self, s: &[u8]) {
        let room = MAX_LEN - self.len;
        let n = if s.len() > room { room } else { s.len() };
        self.bytes[self.len..self.len + n].copy_from_slice(&s[..n]);
        self.len += n;
    }

    fn as_slice(&self) -> &[u8] {
        &self.bytes[..self.len]
    }
}

impl uWrite for Buf {
    type Error = core::convert::Infallible;

    fn write_str(&mut self, s: &str) -> Result<(), Self::Error> {
        self.push_bytes(s.as_bytes());
        Ok(())
    }
}

impl core::fmt::Write for Buf {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        self.push_bytes(s.as_bytes());
        Ok(())
    }
}

// A single scratch buffer rather than 128 bytes of stack per call site. Sound
// because carts are single-threaded: the simulator calls `update` on one thread,
// and on the badge a cart owns Core 1 with interrupts masked.
struct Scratch(UnsafeCell<Buf>);
unsafe impl Sync for Scratch {}
static SCRATCH: Scratch = Scratch(UnsafeCell::new(Buf::new()));

/// Format into the scratch buffer and hand it to the platform.
#[doc(hidden)]
pub fn emit(prefix: &str, f: impl FnOnce(&mut Buf)) {
    // SAFETY: single-threaded by construction (see above), and the borrow does
    // not escape this call.
    let buf = unsafe { &mut *SCRATCH.0.get() };
    buf.len = 0;
    buf.push_bytes(prefix.as_bytes());
    f(buf);
    platform::trace(buf.as_slice());
}

/// Wrap an `f32` so [`ufmt`] can print it, with `decimals` places.
///
/// `ufmt` has no float support at all, and pulling in `core::fmt` just to print
/// a velocity would cost more flash than the rest of the framework. This does
/// fixed-point conversion with integer math.
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
        let v = self.value;
        if v.is_nan() {
            return w.write_str("NaN");
        }
        if v.is_infinite() {
            return w.write_str(if v < 0.0 { "-inf" } else { "inf" });
        }

        let negative = v < 0.0;
        let mut scale: u32 = 1;
        let mut i = 0;
        while i < self.decimals {
            scale *= 10;
            i += 1;
        }

        let abs = if negative { -v } else { v };
        // Saturate rather than wrap on absurd magnitudes.
        let scaled = abs * scale as f32 + 0.5;
        let scaled = if scaled >= u32::MAX as f32 {
            u32::MAX
        } else {
            scaled as u32
        };

        let whole = scaled / scale;
        let frac = scaled % scale;

        if negative {
            w.write_str("-")?;
        }
        ufmt::uwrite!(w, "{}", whole)?;
        if self.decimals > 0 {
            w.write_str(".")?;
            // Leading zeros in the fraction.
            let mut probe = scale / 10;
            while probe > frac && probe > 1 {
                w.write_str("0")?;
                probe /= 10;
            }
            ufmt::uwrite!(w, "{}", frac)?;
        }
        Ok(())
    }
}

/// Shared body of the logging macros.
///
/// `ufmt::uwrite!` expands to paths that assume the `ufmt` crate and its
/// `UnstableDoAsFormatter` trait are nameable at the call site, which they are
/// not inside a cart. Importing both into the closure's scope makes the macro
/// usable from any crate without it having to depend on `ufmt` itself.
#[doc(hidden)]
#[macro_export]
macro_rules! __log {
    ($prefix:literal, $($arg:tt)*) => {
        $crate::log::emit($prefix, |__w| {
            use $crate::ufmt;
            use $crate::ufmt::UnstableDoAsFormatter as _;
            let _ = ufmt::uwrite!(__w, $($arg)*);
        })
    };
}

/// Log unconditionally. Prefer the level macros.
#[macro_export]
macro_rules! trace {
    ($($arg:tt)*) => { $crate::__log!("", $($arg)*) };
}

/// Something went wrong. Enabled by the `log-error` feature (on by default).
#[macro_export]
macro_rules! error {
    ($($arg:tt)*) => {
        if $crate::log::ERROR_ENABLED { $crate::__log!("E ", $($arg)*) }
    };
}

/// Something looks off. Enabled by the `log-warn` feature (on by default).
#[macro_export]
macro_rules! warn {
    ($($arg:tt)*) => {
        if $crate::log::WARN_ENABLED { $crate::__log!("W ", $($arg)*) }
    };
}

/// Notable state change. Enabled by the `log-info` feature.
#[macro_export]
macro_rules! info {
    ($($arg:tt)*) => {
        if $crate::log::INFO_ENABLED { $crate::__log!("I ", $($arg)*) }
    };
}

/// Development detail. Enabled by the `log-debug` feature.
#[macro_export]
macro_rules! debug {
    ($($arg:tt)*) => {
        if $crate::log::DEBUG_ENABLED { $crate::__log!("D ", $($arg)*) }
    };
}

#[cfg(test)]
mod tests {
    use super::*;

    fn render(v: f32, d: u8) -> std::string::String {
        let mut b = Buf::new();
        let _ = ufmt::uwrite!(&mut b, "{}", fx(v, d));
        std::string::String::from_utf8(b.as_slice().to_vec()).unwrap()
    }

    #[test]
    fn formats_floats_without_core_fmt() {
        assert_eq!(render(1.5, 2), "1.50");
        assert_eq!(render(-1.5, 2), "-1.50");
        assert_eq!(render(0.0, 2), "0.00");
        assert_eq!(render(1.23456, 3), "1.235");
        assert_eq!(render(12.0, 0), "12");
    }

    #[test]
    fn pads_leading_zeros_in_the_fraction() {
        assert_eq!(render(1.0625, 3), "1.063");
        assert_eq!(render(2.004, 3), "2.004");
        assert_eq!(render(2.04, 3), "2.040");
    }

    #[test]
    fn handles_non_finite() {
        assert_eq!(render(f32::NAN, 2), "NaN");
        assert_eq!(render(f32::INFINITY, 2), "inf");
        assert_eq!(render(f32::NEG_INFINITY, 2), "-inf");
    }

    #[test]
    fn truncates_instead_of_panicking() {
        let mut b = Buf::new();
        for _ in 0..100 {
            b.push_bytes(b"0123456789");
        }
        assert_eq!(b.as_slice().len(), MAX_LEN);
    }
}
