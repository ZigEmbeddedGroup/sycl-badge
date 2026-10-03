# Software You Can Love Badge

Welcome to the SYCL badge repository.

## Quick Start

### Prerequisites

- Zig `0.17.0`

### Build Firmware and Carts

```bash
zig build
```

This will create:
- zig-out/carts: Built cart(ridge)s ready to be installed
- zig-out/sim: Simulator executables for easy debugging
- zig-out/firmware: Badge OS binary
- zig-out/bin: Miscellaneous tools for the host computer

### Add a cart to the Badge

1. Plug in the badge over USB so it mounts as a mass storage drive.
2. Copy a `.uf2` from `zig-out/carts` onto the badge drive.
3. On the badge, select the cart from the menu.

### Debugging a cart with the simulator

Use your favorite local debugger to debug the executable in zig-out\sim.
The cart code runs on its own thread, which you may need to find.

### Flash the Badge OS

Warning! Changing the OS ABI may make it impossible to run carts made by other attendees,
or to share your carts with others!

To replace the OS,
1. Plug in the badge over USB.
2. Hold the button marked "BOOT_SEL" on the back of the badge
3. While holding the button, turn the badge off and on again.
4. The badge screen will not turn on, but it will still mount as a mass storage drive.
5. Copy zig-out\firmware\sycl-os-kernel.uf2 to the badge
6. The badge will automatically restart with the new OS.

## Documentation

The SYCL Badge V2 User Manual can be found [here](https://zigembeddedgroup.github.io/sycl-badge/).
