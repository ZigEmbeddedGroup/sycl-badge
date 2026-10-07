//! Target-specific glue. Everything above this module is portable.
//!
//! Three backends, selected at compile time:
//!
//! * `wasm32` — the browser simulator. Framebuffer at `0x20` in the imported
//!   `env.memory`; services via `env` imports.
//! * `arm` — the badge. Framebuffer at `0x20020020`; services via the shared
//!   IPC block and the RP2350 inter-core SIO FIFO.
//! * anything else — a host stub so `cargo test` can exercise the portable code.
//!
//! Each backend exposes the same items; see [`ipc`] for the parts of the memory
//! layout that are genuinely shared between the badge and the simulator.

pub mod ipc;

#[cfg(target_arch = "wasm32")]
mod wasm;
#[cfg(target_arch = "wasm32")]
pub use wasm::*;

#[cfg(target_arch = "arm")]
mod badge;
#[cfg(target_arch = "arm")]
pub use badge::*;

#[cfg(not(any(target_arch = "wasm32", target_arch = "arm")))]
mod host;
#[cfg(not(any(target_arch = "wasm32", target_arch = "arm")))]
pub use host::*;
