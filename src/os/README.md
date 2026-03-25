# OS Kernel Guide

The OS kernel runs on Core 0 and manages hardware, storage, display updates, and cart lifecycle.

## Entry Points

- Kernel main: [kernel.zig](kernel.zig)
- Core 1 cart loop: [cart.zig](cart.zig)
- Startup sequencing: [system/init.zig](system/init.zig)

## Core Responsibilities

- Initialize device drivers and system services
- Launch and supervise Core 1 cart execution
- Maintain button and sensor state for carts
- Load carts from storage via UF2 and filesystem support
- Handle console interactions over USB CDC

## Subsystems

- Drivers: [drivers](drivers)
- IPC: [ipc](ipc)
- Loader and storage: [loader](loader)
- System services: [system](system)
- Cart API exposed to cart code: [cart/api.zig](cart/api.zig)

## Build Notes

OS kernel artifacts are configured in [../../build.zig](../../build.zig) through `add_os`.

The kernel linker layout is defined in [linker.ld](linker.ld).
