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
//! * **`ufmt` cannot format floats.** Use [`crate::text::fx`] for those.
//!
//! ```ignore
//! use sycl_cart::prelude::*;
//! info!("spawned pipe at {}", x);
//! debug!("vy={}", sycl_cart::text::fx(self.vy, 2));
//! ```

use crate::platform;
use crate::text::TextBuf;
use core::cell::UnsafeCell;

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

/// The scratch buffer messages are formatted into.
///
/// One shared buffer rather than 128 bytes of stack per call site. Sound because
/// carts are single-threaded: the simulator calls `update` on one thread, and on
/// the badge a cart owns Core 1 with interrupts masked.
#[doc(hidden)]
pub type Buf = TextBuf<MAX_LEN>;

struct Scratch(UnsafeCell<Buf>);
unsafe impl Sync for Scratch {}
static SCRATCH: Scratch = Scratch(UnsafeCell::new(Buf::new()));

/// Format into the scratch buffer and hand it to the platform.
#[doc(hidden)]
pub fn emit(prefix: &str, f: impl FnOnce(&mut Buf)) {
    // SAFETY: single-threaded by construction (see above), and the borrow does
    // not escape this call.
    let buf = unsafe { &mut *SCRATCH.0.get() };
    buf.clear();
    buf.push_str(prefix);
    f(buf);
    platform::trace(buf.as_bytes());
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
            // Needed by some `uwrite!` expansions and not others, hence the allow.
            #[allow(unused_imports)]
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
