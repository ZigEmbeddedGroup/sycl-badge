//! # sycl-cart
//!
//! A lightweight framework for writing [SYCL Badge v2] carts in Rust.
//!
//! ## Model
//!
//! A cart is a plain Rust type that owns all of its state. You implement
//! [`Cart`] and hand it to the [`cart!`] macro, which emits the `start`/`update`
//! entry points the platform expects:
//!
//! ```ignore
//! use sycl_cart::prelude::*;
//!
//! struct Game { y: i32 }
//!
//! impl Cart for Game {
//!     const INIT: Self = Game { y: 64 };
//!
//!     fn update(&mut self, c: &mut Ctx) {
//!         if c.input.just_pressed(Button::A) { self.y -= 8; }
//!         c.gfx.clear(Color::rgb8(0x20, 0x40, 0x60));
//!         c.gfx.text(b"HELLO", 4, self.y, Color::WHITE);
//!     }
//! }
//!
//! sycl_cart::cart!(Game);
//! ```
//!
//! There is no engine, no scheduler, and no inversion of control beyond those
//! two entry points. Rendering is immediate-mode: you draw every frame, and the
//! framework tracks the dirty region for you so only changed pixels reach the
//! display.
//!
//! ## Allocation
//!
//! None, anywhere. The cart state lives in `.bss` and is written once by
//! `start()`. The framebuffer is a `static`. Sprites and audio tracks are
//! `&'static` const data. There is no allocator and no `alloc` dependency.
//!
//! ## Platforms
//!
//! One rasterizer serves both targets, because the badge OS and the browser
//! simulator both expose a column-major framebuffer in shared memory:
//!
//! | | simulator (`wasm32`) | badge (`thumbv8m.main`) |
//! |---|---|---|
//! | framebuffer | wasm memory `0x20`, 1 buffer | `0x20020020`, 2 buffers |
//! | pixel encoding | byte-swapped RGB565 | byte-swapped BGR565 |
//! | present | host composites after `update` | dirty rect + SIO FIFO handshake |
//! | trace/tone | `env` imports | shared buffer + FIFO messages |
//!
//! [SYCL Badge v2]: https://github.com/ZigEmbeddedGroup/sycl-badge

#![cfg_attr(not(test), no_std)]
#![deny(unsafe_op_in_unsafe_fn)]

pub mod audio;
pub mod color;
pub mod font;
pub mod gfx;
pub mod input;
pub mod leds;
pub mod log;
pub mod platform;
pub mod rng;
pub mod rt;
pub mod save;
pub mod sprite;

#[doc(hidden)]
pub use ufmt;

pub use audio::{Audio, Step, ToneLen, Track};
pub use color::Color;
pub use gfx::{Gfx, Rect, HEIGHT, WIDTH};
pub use input::{Button, Input};
pub use leds::Leds;
pub use rng::Rng;
pub use rt::{Cart, Ctx};
pub use save::Save;
pub use sprite::{ascii_sprite, Anim, AnimState, BlitFlags, Sprite, SpriteSheet};

/// Everything you normally want in scope inside a cart.
pub mod prelude {
    pub use crate::{
        cart, debug, error, info, warn, Anim, AnimState, BlitFlags, Button, Cart, Color, Ctx, Rect,
        Sprite, SpriteSheet, Step, ToneLen, Track, HEIGHT, WIDTH,
    };
}
