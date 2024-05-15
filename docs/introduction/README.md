# Introduction

This is a short introduction containing some information and a small example meant to show how to use the badge.

**It is strongly recommended that you read through this entire document.**

## Quick Badge Facts

The badge is based on the PyBadge and is equipped with:

- A 32-bit ARM CPU
- A light sensor
- A 160x128 16-bit RGB (RGB565) screen
- 5 24-bit RGB LEDs (neopixels)
- 1 red LED on the back
- A speaker
- Start/option buttons
- A/B buttons
- A navstick/d-pad with up/down/left/right + click
- 2MB flash separate from the microcontroller's flash

## Setup

Install Zig 0.12.0. You can find [the binaries on the Zig website](https://ziglang.org/download/#release-0.12.0), or obtain them via a version manager such as [`zigup`](https://github.com/marler8997/zigup).

Clone this repository and enter this directory:

```bash
git clone https://github.com/ZigEmbeddedGroup/sycl-badge
cd sycl-badge
cd docs/introduction
```

## The Example

See `src/hello.zig` and tweak the the values to your liking.

### Running on the simulator

The simulator is ideal for fast iteration as it supports live reloading.

Run `zig build` and wait for build to finish.

Run `zig build watch` and head over to https://badgesim.microzig.tech/.

(It's been noted that the live reloaders may be a little finnicky. If they don't work at all, please let Auguste know.)

Once you're happy with what you've made, read on to learn how to flash your code onto the badge!

## Hard(ware) mode

**Please wait until the afternoon before trying to upload programs onto badges as the badge is still being worked on.**

Currently, only the neopixels are functional.

### Power and Boot

Your badge can be powered via the USB-C port, but to allow cordless use of the badge, you've been provided with a battery and two pieces of velcro.

Place one piece of velcro on the back of the board where space has been left available, and the other piece of velcro on the battery. Then plug the connector on the battery into the similar connector on the back of the board. Finally, attach the battery's velcro to the board's.

Once the battery is connected, it can be charged via the USB-C port. **NOTE:** As this is an educational tool and not a piece of consumer electronics, this badge has not undergone rigorous power testing. When charging your battery please don't leave it unattended.

There is an on/off switch located at the top of the badge. Try booting the badge now if you haven't already!

### Uploading

Run `zig build`, then find `hello.uf2` in the `zig-cache/zig-out/firmware` directory.

Plug in your badge. It should appear as a mass storage device/USB drive.

Copy `hello.uf2` in place of the `CURRENT.UF2` present on the badge USB drive.

Your program will run immediately.

### Resetting

You'll find a brass colored button on the back of the board, at the top. This is the reset button. Press it once to restart your program and twice to go back to the bootloader and upload a new program.

## Need help?

Please ask someone with a staff badge (most likely Auguste) - we'd be happy to help!

If you can't locate one of us, please post your question in the Discord thread and we'll get back to you as quickly as possible!

## Have fun!
