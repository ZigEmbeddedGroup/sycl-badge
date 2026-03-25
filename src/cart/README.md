# Cart Runtime and HAL

This folder contains runtime glue used by carts that run on Core 1.

## Key Files

- [cart_entry.zig](cart_entry.zig): MicroZig cart wrapper entry path
- [cart_runtime.zig](cart_runtime.zig): minimal startup/runtime path
- [cart_hal.zig](cart_hal.zig): standalone HAL helpers used by cart runtime paths
- [cart_xip.ld](cart_xip.ld): linker script for cart execution mapping

## When This Is Used

These sources are used by root build helpers in [../../build.zig](../../build.zig), including MicroZig and low-level cart build paths.

## Relationship to OS Cart API

OS-cart style programs in [../os/cart/api.zig](../os/cart/api.zig) consume the shared API contract. Runtime setup in this folder supports execution handoff and low-level startup behavior on Core 1.
