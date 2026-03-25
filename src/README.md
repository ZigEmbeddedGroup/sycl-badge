# Firmware Source Guide

This folder contains SYCL Badge firmware sources for OS runtime, cart runtime, and legacy code.

## Build

From repository root:

```bash
zig build
```

Primary outputs are in `zig-out/firmware`.

## Architecture Overview

SYCL Badge V2 firmware is split across two cores:

- Core 0: OS kernel in [os](os)
- Core 1: cart runtime and cart execution entry in [os/cart.zig](os/cart.zig)

## Cart Models

The repository currently contains three cart build styles:

- OS cart API carts: linked against [os/cart/api.zig](os/cart/api.zig)
- MicroZig carts: built through helpers in [../build.zig](../build.zig)
- XIP-style runtime carts: minimal runtime path in [cart](cart)

## Directory Map

- [os](os): kernel, drivers, loader, IPC, and cart API
- [cart](cart): cart runtime glue and standalone HAL
- [badge-v1](badge-v1): legacy badge v1 firmware code
- [board_v2.zig](board_v2.zig): board definition for v2
- [font.zig](font.zig): bitmap font used by cart APIs

## Next Docs

- [os/README.md](os/README.md)
- [cart/README.md](cart/README.md)
