//! Puts `cart_ram.x` where the linker can find it.
//!
//! `.cargo/config.toml` links every badge build with `-Tcart_ram.x`, and the
//! linker resolves that name against its search path. Emitting the search path
//! from here rather than from each cart means a cart crate needs no build
//! script of its own — the same reason a HAL crate normally does this.

use std::env;
use std::fs;
use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    // Only the badge links against a fixed memory map. The simulator gets its
    // layout from the wasm link flags in `.cargo/config.toml` instead.
    if env::var("CARGO_CFG_TARGET_ARCH").as_deref() != Ok("arm") {
        return;
    }

    println!("cargo:rerun-if-changed=cart_ram.x");
    let out = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
    fs::write(out.join("cart_ram.x"), include_bytes!("cart_ram.x")).expect("write cart_ram.x");
    println!("cargo:rustc-link-search={}", out.display());
}
