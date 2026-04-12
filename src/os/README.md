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

## Button Commands

The OS intercepts button input for system operations. Carts receive updated button state every frame but cannot prevent these system commands.

### Menu Navigation (Cart Not Running)

- **Up/Down**: Navigate the cart selection list
- **A**: Launch the selected cart

### System Controls (Always Active)

- **Joystick Click (press-in)**: Toggle FPS overlay on/off at any time
- **Start + Select** (hold 250ms): Stop running cart and return to cart selection menu
  - Prevents accidental exit since Start may be used by carts
  - Halts Core 1, resets all hardware (buzzer, PWM, display, etc.), and restores the menu display

## Build Notes

OS kernel artifacts are configured in [../../build.zig](../../build.zig) through `add_os`.

The kernel linker layout is defined in [linker.ld](linker.ld).
