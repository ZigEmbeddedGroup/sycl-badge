# Showcase Carts Index

This folder contains cart examples and experiments for SYCL Badge.

## How to Build

From repository root:

```bash
zig build
```

Built firmware artifacts are installed to `zig-out/firmware`.

## Hardware vs Simulator

- Most package carts under this folder are built via `sycl_badge.add_cart(...)` and can target both hardware and simulator workflows.
- Some carts in this folder are wired directly from root [../../build.zig](../../build.zig) as MicroZig or OS-cart examples.

## Curated Cart Docs

- [blobs](blobs/README.md)
- [plasma](plasma/README.md)
- [raytracer](raytracer/README.md)
- [dvd](dvd/README.md)
- [zeroman](zeroman/README.md)
- [lcd-text](lcd-text/README.md)

## Add Documentation for Another Cart

Use [TEMPLATE.md](TEMPLATE.md) and add a README to that cart folder.
