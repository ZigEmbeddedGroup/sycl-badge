# Rust carts for the SYCL Badge

Write badge carts in Rust. `no_std`, zero allocation, one rasterizer that serves
both the browser simulator and the badge itself.

```bash
cd rust
rustup target add wasm32-unknown-unknown
cargo xtask watch                  # build + serve on :2468 with live reload

# in another terminal
cd ../simulator && npm install && npm run dev   # then open http://localhost:1234
```

The simulator picks the cart up automatically: it fetches `cart.wasm` from
`localhost:2468` and reloads whenever `xtask` rebuilds.

Other commands:

```bash
cargo xtask build                  # one-shot build to target/cart.wasm
cargo xtask build -p mycart        # a different package
cargo test                         # host tests for the portable code
cargo clippy --all-targets         # lints
node tools/sim_check.mjs           # headless check: renders? audio? memory sane?
```

Carts are `no_std` cross-compiled artifacts and cannot build for the host, so
they are excluded from the workspace's `default-members`. Root-level `cargo
build`/`test`/`clippy` cover the framework and tooling; build a cart through
`xtask` or with `-p <cart> --target wasm32-unknown-unknown`.

## Writing a cart

```rust
#![no_std]
use sycl_cart::prelude::*;

struct Game { x: i32 }

impl Cart for Game {
    const INIT: Self = Game { x: 0 };

    fn start(&mut self, c: &mut Ctx) {
        self.x = c.rng.range(0, WIDTH as i32);
    }

    fn update(&mut self, c: &mut Ctx) {
        self.x += c.input.dx();
        c.gfx.clear(Color::hex(0x102030));
        c.gfx.fill_rect(self.x, 60, 8, 8, Color::WHITE);
        if c.input.just_pressed(Button::A) {
            c.audio.tone(880.0, ToneLen::Frames(4), 0.8);
        }
    }
}

sycl_cart::cart!(Game);
```

`Cargo.toml` needs `crate-type = ["cdylib"]`. See
[`examples/flappy`](examples/flappy/src/lib.rs) for a complete game — sprites,
animation, audio, scoring — in one file.

## How it works

A cart is a plain Rust type that owns all of its state. `Cart::INIT` is a
`const`, so the state lives in `.bss` (given zero-valued fields) and is written
once by `start()`. There is no allocator, no `alloc` dependency, and no engine —
just the two entry points the platform requires.

Rendering is immediate-mode: draw everything each frame and the framework unions
the bounding boxes of your draw calls into a dirty rectangle, pushing only that
region to the display.

### The backbuffer, and why it exists

Both targets expose their framebuffer in memory shared with something the
compiler cannot see — the browser host, or Core 0's DMA engine. **Plain stores
into that memory are dead code as far as LLVM is concerned, and get deleted in
release builds.** This is measurable: a per-pixel fill loop writing to the
simulator's framebuffer at `0x20` vanishes at `opt-level = "z"`.

So drawing goes into a private `static` backbuffer with ordinary stores — kept,
because the flush reads them back — and one bulk volatile pass per frame pushes
the dirty region out. All the optimizations that make a software rasterizer
viable stay available.

### Column-major, and what follows from it

The framebuffer is indexed `x * HEIGHT + y`. A column is contiguous; a row is
strided by 256 bytes. Consequences:

* `vline` is a `fill`. `hline` touches one pixel per stride. That is the
  opposite of most engines — prefer vertical spans and `fill_rect` in hot code.
* Sprites are stored **column-major and pre-encoded**, so an unflipped opaque
  blit is one `copy_from_slice` per column. `ascii_sprite` does the transpose and
  the pixel encoding at compile time.
* `flip_y` is a reversed copy within a column and `flip_x` is a reversed column
  order, so both flips are nearly free.

### Colors

`Color` wraps an already-encoded `u16`, built by a `const fn` that picks the
target's byte order: byte-swapped RGB565 in the simulator, byte-swapped BGR565 on
the badge (whose bytes go straight to the ST7735 over SPI). Literals and sprite
data are converted at compile time, so no drawing path converts anything per
pixel. The raw `u16` is therefore not portable — never persist it.

### Platform matrix

|  | simulator (`wasm32`) | badge (`thumbv8m.main`) |
|---|---|---|
| framebuffer | wasm memory `0x20`, one buffer | `0x20020020`, one of two used |
| pixel encoding | byte-swapped RGB565 | byte-swapped BGR565 |
| present | host composites after `update` | dirty rect + SIO FIFO handshake |
| trace / tone / rand | `env` imports | shared IPC block + FIFO messages |
| panic | trap → simulator blue screen | trace, then park |
| save data | 4 MiB host buffer | not implemented on v2 |

Only the badge's `present` is interesting: it waits for `FRAMEBUFFER_DONE` from
Core 0, copies the dirty rectangle into shared framebuffer 0, then publishes it.
The OS offers two framebuffers so a cart can draw while a DMA is in flight, but
the private backbuffer already provides that, and alternating buffers would leave
each one two frames stale outside the dirty region — forcing every flush to cover
a two-frame union. One buffer is simpler and correct.

## Logging

```rust
info!("score {}", self.score);
debug!("vy={}", sycl_cart::log::fx(self.vy, 2));
```

Levels cascade through cargo features (`log-error` ⊂ `log-warn` ⊂ `log-info` ⊂
`log-debug`); `log-warn` is on by default. Disabled levels are compiled out
*entirely*, format strings included — verified by grepping the built wasm. They
are still type-checked, so disabled logging cannot rot.

Formatting uses [`ufmt`], not `core::fmt`, which would cost 10–20 KiB of a
~160 KiB cart budget. `ufmt` has no float support, so use `log::fx` for those.

Keep the rate low. On the badge the kernel drains the message FIFO once per loop
iteration, so several traces in one frame may be coalesced or lost, and each one
costs a FIFO round trip shared with `present`. Log state changes, not per-frame
values.

## Audio

One monophonic square wave, because that is what the badge has: `src/os/drivers/audio.zig`
drives GPIO9 with a PWM carrier whose duty sets amplitude, and its entire state
is `enum { off, square }`. The simulator runs the full WASM-4 APU — four
channels, ADSR, slides, panning — and we deliberately drive only the common
subset, so a cart sounds the same in both places.

`Audio::tone` is the raw primitive. Above it, a sequencer plays `&'static`
tracks at three priorities (one-shot beep > SFX > music), resolves one winning
note per frame, and only touches the hardware when that note *changes* — every
`tone()` on the badge aborts a DMA channel and reprograms a PWM slice, so
re-issuing the same note 60 times a second is audible as clicking.

```rust
static SFX_FLAP: Track = Track::once(&[Step::at(notes::G6, 2, 0.55)]);
c.audio.play_sfx(&SFX_FLAP);
```

Two hardware caveats we do not paper over: pitch is currently about 400 cents
sharp on real hardware (`src/os/drivers/audio.zig:23`), and the buzzer's response
peaks near 2700 Hz and rolls off steeply either side, so low notes will be quiet
on the badge however good they sound in the simulator.

## Wasm link flags

[`.cargo/config.toml`](.cargo/config.toml) is load-bearing. Two of the flags fail
in ways that are hard to diagnose:

* **`--import-memory`.** The simulator owns the memory and composites the
  framebuffer out of it. Without this the module exports its own memory instead,
  instantiation still *succeeds* (JS ignores unneeded imports), and you get a
  silent black screen.
* **`--no-stack-first`.** rustc defaults to putting the wasm stack at
  `[0, size)` growing down, which lands inside the framebuffer at `0x20`.
  `--global-base` does not move it. The trade-off is that stack overflow now
  corrupts static data rather than trapping at address 0; `tools/sim_check.mjs`
  checks the stack pointer starts above the framebuffer.

`--global-base=41248` is the first 32-byte boundary past the framebuffer.
Note that `build.zig:315` uses `0xA01E`, which is two bytes *inside* it — benign
because the linker rounds the first segment up, but don't copy the value.

## Layout

```
sycl-cart/          the framework
  src/platform/     wasm.rs, badge.rs, host.rs (for tests), ipc.rs (shared layout)
  src/gfx.rs        backbuffer, drawing, dirty tracking, volatile flush
  src/sprite.rs     sprites, sheets, ascii_sprite, animation
  src/audio.rs      tone primitive + sequencer
  src/log.rs        ufmt-based logging, compiled out when disabled
  src/rt.rs         Cart trait, Ctx, cart! macro, panic handler
  src/font.rs       generated — see tools/gen_font.py
examples/flappy/    a complete game
xtask/              build, and the watch server the simulator expects
tools/              gen_font.py, sim_check.mjs
```

`src/font.rs` is generated from the Zig `src/font.zig` by
`python3 tools/gen_font.py` and committed, the same way `simulator/src/font.ts`
is. The Zig table stores 0 as *foreground*; the generator inverts it so the Rust
table reads the intuitive way.

## Status

Working: the whole simulator path, verified by `tools/sim_check.mjs` — memory
layout, rendering, audio encoding, trace output.

Not yet done: **the badge backend has never been run on hardware.** It compiles
for `thumbv8m.main-none-eabihf` and matches the documented protocol, but the
entry point is missing — there is no vector table, no `.data`/`.bss` init, and no
ELF→UF2 packer. That is the next milestone:

1. `cortex-m-rt` with a `memory.x` placing `FLASH` at `0x101C0000` (256 KiB) and
   `RAM` at `0x20034100` (`0x4BF00`). It handles scatter-init and enables the FPU
   for `-eabihf` targets; call `platform::badge::init_fpu` for `FPCCR` as well.
2. A `cart!` arm that emits the `cortex-m-rt` entry instead of wasm exports, with
   the frame loop calling `update` then `present`.
3. `cargo xtask uf2` — pack to UF2 with family `0xE48BFF59` and all target
   addresses inside the cart window, then copy onto the badge's USB drive.

Watch the size: the loader caps a cart image at roughly 160 KiB
(`src/os/loader/loader.zig:228` against a 320 KiB staging buffer, 256 payload
bytes per 512-byte UF2 block).

[`ufmt`]: https://docs.rs/ufmt
