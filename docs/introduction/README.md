# Introduction

This is a short introduction with a small cart example so you can quickly get from source code to running on the simulator and badge hardware.

## Quick Badge Facts

The badge is equipped with:

- A 32-bit ARM CPU
- A light sensor
- A 160x128 16-bit RGB screen (RGB565)
- 5 RGB LEDs (neopixels)
- 1 red LED on the back
- A speaker
- Start/select buttons
- A/B buttons
- A navstick (up/down/left/right + click)
- 2MB external flash separate from MCU flash

## Setup

Install Zig 0.15.1 from [ziglang.org](https://ziglang.org/download/) or a version manager such as [zigup](https://github.com/marler8997/zigup).

Clone the repository:

```bash
git clone https://github.com/ZigEmbeddedGroup/sycl-badge
cd sycl-badge
cd docs/introduction
```

## Example Cart

Edit [src/hello.zig](src/hello.zig) in this folder.

### Build the Example

```bash
zig build
```

### Run in Simulator (Live Reload)

This folder defines a `watch` step in [build.zig](build.zig).

1. Start the watcher in this folder:

```bash
zig build watch
```

2. Open the simulator:
- Hosted: <https://badgesim.microzig.tech/>
- Local UI: run [simulator](../../simulator/README.md) and open `http://localhost:1234`

When `zig build watch` is active, the simulator can fetch `cart.wasm` from `http://localhost:2468` and reload on changes.

## Run on Hardware

### Power and Boot

The badge can be powered from USB-C or battery. When charging over USB-C, do not leave the badge unattended.

### Uploading a UF2

1. Build your cart in this folder:

```bash
zig build
```

2. Find `hello.uf2` in `zig-out/firmware`.
3. Plug in the badge so it appears as a mass storage drive.
4. Copy `hello.uf2` to the badge drive, replacing `CURRENT.UF2`.
5. The new program runs immediately.

### Resetting

Use the reset button on the back of the board near the top:

- Press once to restart the current program.
- Press twice to enter bootloader mode for uploading.

## Need Help?

Ask a staff member at the event or post in the project Discord thread.

