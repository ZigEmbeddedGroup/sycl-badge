# Software You Can Love Badge

Welcome to the SYCL badge repository.

## Quick Start

### Prerequisites

- Zig `0.17.0-dev.1936+5a625d5f3`

### Build Firmware and Carts

```bash
zig build
```

Build outputs are installed under `zig-out/firmware`.

### Flash a UF2 to the Badge

1. Plug in the badge over USB so it mounts as a mass storage drive.
2. Copy a `.uf2` from `zig-out/firmware` onto the badge drive, replacing `CURRENT.UF2`.
3. The new program starts immediately.

## Documentation

The SYCL Badge V2 User Manual can be found [here](https://zigembeddedgroup.github.io/sycl-badge/).
