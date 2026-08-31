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
cargo xtask watch -p itest         # a different cart
cargo test                         # host tests for the portable code
cargo clippy --all-targets         # lints
node tools/sim_check.mjs target/cart.wasm flappy   # headless: renders? audio? memory sane?
node tools/shot.mjs target/cart.wasm 200 /tmp/a.png 5   # render a frame to a PNG
node tools/shot.mjs target/cart.wasm 200 /tmp/a.png 14 40,22,80,34   # ...cropped
```

The last one instantiates a cart exactly as the browser does and asserts on the
things a normal build cannot catch — memory imported, stack clear of the
framebuffer, pixels actually written, audio encoded for the badge's buzzer. The
optional second argument selects extra per-cart checks, and for `itest` it drives
every input through to completion.

`shot.mjs` writes the framebuffer out as a PNG at whole-pixel scale, which is the
quickest way to inspect pixel-level detail — a seam between two fills, a stray
pixel outside a clip — without a browser scaling it first. The trailing
`x,y,w,h` crops. It stubs `env.rand` with a fixed value so the same frame number
is the same picture every run, which is what makes two renders comparable.

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

`Cargo.toml` needs `crate-type = ["cdylib"]`. Two complete carts to read:

* [`showcase/flappy`](showcase/flappy/src/lib.rs) — a game, in one file: sprite
  sheet, animation, collision, scoring, sound effects.
* [`showcase/itest`](showcase/itest/src/lib.rs) — an interactive hardware test
  that walks you through all nine inputs while a cyberpunk eye watches you.
  Ellipse drawing, colour mixing, a shuffled prompt sequence and a looping
  chiptune track.

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
* Sprites are stored column-major and pre-encoded too, so a blit is one
  `copy_from_slice` per column. `flip_y` is a reversed copy within a column and
  `flip_x` a reversed column order, so both flips are nearly free.
* `fill_ellipse` is unusually cheap: each column's vertical extent is a single
  contiguous `fill`, so a circle costs about what its bounding rectangle would.

### Sprites

Declare art and the layout details stay inside the framework — no dimensions to
restate, no array lengths, no pixel order to know about:

```rust
sprite_sheet! {
    /// Three wing positions.
    const BIRD;
    palette: {
        'Y' => Color::hex(0xf8d828),
        'k' => Color::hex(0x302010),
    },
    frames: [
        [
            "..YYYY...",
            ".YYYYYYk.",
            "..YYYY...",
        ],
        [ /* ... */ ],
    ],
}

const BIRD_H: i32 = BIRD.tile_h() as i32;   // single-sourced from the art
c.gfx.blit(&BIRD.tile(frame), x, y);
```

Any character absent from the palette — `.` by convention — is transparent.
Mismatched row lengths, differing frame sizes and non-ASCII palette characters
are all compile-time errors, and the transparency stand-in colour is chosen
automatically so it cannot collide with the palette.

Alongside the pixels, the encoder records **the vertical extent of the opaque
pixels in each column**, and whether any column has a *hole* — a transparent
pixel with opaque pixels above and below. That distinction sets the blit speed:

* **No holes** — the usual case, however much transparency surrounds the
  silhouette — means each column is one contiguous run, so the blit is a
  `copy_from_slice` per column with no per-pixel test at all.
* **Holes** send only the affected columns down a per-pixel loop, still bounded
  to that column's span.

Either way transparent margins are never touched and never enlarge the dirty
rectangle. `Sprite::takes_fast_path()` is `const`, so you can hold the line on
it: `const _: () = assert!(BIRD.takes_fast_path());` turns art edits that would
slow the blit down into build failures. `showcase/flappy` does exactly that.

For an asset pipeline that produces pixels some other way, `Sprite::opaque`
takes column-major pre-encoded data directly.

### Colors

`Color` wraps an already-encoded `u16`, built by a `const fn` that picks the
target's layout: byte-swapped RGB565 in the simulator, and plain BGR565 on the
badge, where a 16-bit SPI DMA shifts each halfword out high byte first, straight
to the ST7735. Literals and sprite data are converted at compile time, so no
drawing path converts anything per pixel. The raw `u16` is therefore not
portable — never persist it.

Both encodings are pinned by `const` assertions in `src/platform/`, because an
R/B swap is invisible until you flash a badge.

`Color::mix(other, t)` blends at runtime, for flashes and fades. It decodes and
re-encodes, so hoist it out of per-pixel loops.

### Platform matrix

|  | simulator (`wasm32`) | badge (`thumbv8m.main`) |
|---|---|---|
| framebuffer | wasm memory `0x20`, one buffer | `0x20020020`, one of two used |
| pixel encoding | byte-swapped RGB565 | BGR565 |
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

## Text and numbers

`TextBuf<N>` is a fixed-capacity string you can format into, and `uformat!` fills
one the way `format!` fills a `String` — capacity first:

```rust
let label = uformat!(16, "BEST {}", self.best);
c.gfx.text(&label, x, y, Color::WHITE);
```

Simple cases need no macro:

```rust
let mut b = TextBuf::<16>::new();
b.push_str("BEST ");
b.push_u32(self.best);
```

`Gfx::text` takes `impl AsRef<[u8]>`, so string literals, byte literals and
`TextBuf` all work without conversion. Overflow truncates and sets
`TextBuf::truncated()` rather than panicking.

Two limits inherited from `ufmt`:

* **Positional arguments only.** `uformat!(8, "{score}")` does not compile —
  write `uformat!(8, "{}", score)`. Implicit capture would need our own proc
  macro. (Field access like `{self.score}` is not valid in `std`'s `format!`
  either, only plain identifiers are.)
* **No floats.** Wrap them: `uformat!(16, "vy={}", text::fx(self.vy, 2))`.

For layout, `Gfx::text_width(s, scale)` measures; positioning is the cart's job.
There is no alignment API yet.

## Logging

```rust
info!("score {}", self.score);
debug!("vy={}", sycl_cart::text::fx(self.vy, 2));
```

Levels cascade through cargo features (`log-error` ⊂ `log-warn` ⊂ `log-info` ⊂
`log-debug`); `log-warn` is on by default. Disabled levels are compiled out
*entirely*, format strings included — verified by grepping the built wasm. They
are still type-checked, so disabled logging cannot rot.

Formatting uses [`ufmt`], not `core::fmt`, which would cost 10–20 KiB of a
~160 KiB cart budget. `ufmt` has no float support, so use `text::fx` for those.

Keep the rate low. On the badge the kernel drains the message FIFO once per loop
iteration, so several traces in one frame may be coalesced or lost, and each one
costs a FIFO round trip shared with `present`. Log state changes, not per-frame
values.

## Audio

One monophonic voice, because that is what the badge has: `src/os/drivers/audio.zig`
drives GPIO9 with a PWM carrier whose duty sets amplitude, and a DMA channel
walks a wave table at the note frequency. It plays one note at a time in one of
three shapes. The simulator runs the full WASM-4 APU — four channels, ADSR,
slides, panning — and we deliberately drive only the common subset, so a cart
sounds the same in both places.

`Audio::tone` is the raw primitive. Above it, a sequencer plays `&'static`
tracks at three priorities (one-shot beep > SFX > music), resolves one winning
note per frame, and only touches the hardware when that note *changes* — every
`tone()` on the badge aborts a DMA channel and reprograms a PWM slice, so
re-issuing the same note 60 times a second is audible as clicking.

```rust
static SFX_FLAP: Track = Track::once(&[Step::at(notes::G6, 2, 0.55)]);
c.audio.play_sfx(&SFX_FLAP);

static BASS: Track = Track::looping(&[Step::shaped(notes::C6, 8, 0.5, Shape::Triangle)]);
c.audio.play_music(&BASS);
```

`Shape` is `Square` (the default, and the loudest), `Triangle` or `Sawtooth`.
The badge's `Tone2Options.Shape` also lists `sine`, `major` and `minor`, but all
three fall through to `stop()` in the driver, so the framework does not offer
them. Sawtooth is the one shape without a simulator equivalent: the APU has no
saw, so it plays as a 25 % duty pulse, which is brighter than a square but not
the same timbre.

`audio::notes` covers C4 to B7 chromatically, `S` meaning sharp — `DS6` is D#6.
Octaves 6 and 7 are the ones that carry on the buzzer.

Two hardware caveats we do not paper over: pitch is currently about 400 cents
sharp on real hardware (`src/os/drivers/audio.zig:32`), and the buzzer's response
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
Note that `build.zig:535` uses `0xA01E`, which is two bytes *inside* it — benign
because the linker rounds the first segment up, but don't copy the value.

## Layout

```
sycl-cart/          the framework
  src/platform/     wasm.rs, badge.rs, host.rs (for tests), ipc.rs (shared layout)
  src/gfx.rs        backbuffer, drawing, dirty tracking, volatile flush
  src/sprite.rs     sprites, sheets, sprite!/sprite_sheet!, animation
  src/text.rs       TextBuf, uformat!, fixed-point floats
  src/math.rs       sin, cos, sqrt and friends that core lacks
  src/audio.rs      tone primitive + sequencer
  src/log.rs        ufmt-based logging, compiled out when disabled
  src/rt.rs         Cart trait, Ctx, cart! macro, panic handler
  src/font.rs       generated — see tools/gen_font.py
showcase/flappy/    a complete game
showcase/itest/     interactive hardware test
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
(`src/os/loader/loader.zig:233` against a 320 KiB staging buffer, 256 payload
bytes per 512-byte UF2 block).

[`ufmt`]: https://docs.rs/ufmt
