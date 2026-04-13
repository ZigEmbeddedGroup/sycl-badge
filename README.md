# Software You Can Love Badge

Welcome to the SYCL badge repository.

## Quick Start

### Prerequisites

- Zig 0.15.1
- Node.js 20.x or newer (for the local simulator UI)

### Build Firmware and Carts

```bash
zig build
```

Build outputs are installed under `zig-out/firmware`.

### Run the Local Simulator UI

```bash
cd simulator
npm install
npm run dev
```

The simulator UI runs on `http://localhost:1234`.

To provide a cart to the simulator with live reload, run a watcher from a cart project that defines a `watch` step (for example [docs/introduction](docs/introduction/README.md)):

```bash
cd docs/introduction
zig build watch
```

### Flash a UF2 to the Badge

1. Plug in the badge over USB so it mounts as a mass storage drive.
2. Copy a `.uf2` from `zig-out/firmware` onto the badge drive, replacing `CURRENT.UF2`.
3. The new program starts immediately.

## Documentation Map

- [Introduction](docs/introduction/README.md)
- [Firmware architecture](src/README.md)
- [Simulator](simulator/README.md)
- [Showcase carts](showcase/README.md)
- [Pinout](docs/pinout.md)

