//! Puts `memory.x` where `cortex-m-rt`'s `link.x` can find it.
//!
//! `link.x` does `INCLUDE memory.x`, and the linker resolves that against its
//! search path. Emitting the search path from here rather than from each cart
//! means a cart crate needs no build script of its own — the same reason a HAL
//! crate normally does this.

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

    println!("cargo:rerun-if-changed=memory.x");
    let out = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR"));
    fs::write(out.join("memory.x"), include_bytes!("memory.x")).expect("write memory.x");
    println!("cargo:rustc-link-search={}", out.display());
}
