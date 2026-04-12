# Cart API Guide

This folder defines the API surface carts use when running on badge OS.

## Main API File

- [api.zig](api.zig)

## API Surface

`api.zig` provides:

- Input controls (start/select/a/b/click/up/down/left/right)
- Sensor values (light and battery)
- Display framebuffer access
- LED and neopixel state access
- Drawing helpers such as text, lines, rectangles, and blits

## Memory Contract

The API maps to a shared memory block populated by Core 0 and consumed by Core 1 cart code. Address details and layout are documented inline in [api.zig](api.zig).

## Cart Lifecycle

Carts typically export:

- `start()` for initialization
- `update()` for per-frame logic

Examples:

- [../../../showcase/carts/lcd-text/src/main.zig](../../../showcase/carts/lcd-text/src/main.zig)
- [../../../showcase/carts/plasma/src/plasma.zig](../../../showcase/carts/plasma/src/plasma.zig)
