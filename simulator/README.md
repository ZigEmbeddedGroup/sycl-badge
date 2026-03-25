# SYCL Badge V2 Simulator

Web simulator for SYCL Badge carts.

## Quick Start

### Prerequisites

- Node.js 20.x or newer
- Zig 0.15.1 (needed for building and serving carts)

### Run the Simulator UI Locally

From this folder:

```bash
npm install
npm run dev
```

Open `http://localhost:1234`.

### Serve a Cart with Live Reload

The simulator expects a watcher service at `http://localhost:2468`.

A simple way to start one is the introduction example:

```bash
cd ../docs/introduction
zig build watch
```

That watcher serves:

- `http://localhost:2468/cart.wasm`
- `ws://localhost:2468/ws` for reload events

If this service is not running, the simulator shows: `Watcher not found. Start and reload.`

## Production Build

```bash
npm install
npm run build
```

The production web build is emitted by Parcel.

## Hosted Simulator

Use the hosted simulator directly at:

- <https://badgesim.microzig.tech/>

## Controls

- Joystick: Arrow keys or WASD
- Joystick click: Shift
- A: Z or K
- B: X or J
- Start: Enter or Y
- Select: Backspace or T
- Open system menu: Escape

## Supported Hardware Components

- Light sensor
- 160x128 RGB screen
- 5 RGB LEDs (neopixels)
- Back red LED
- Speaker
- Start/select buttons
- A/B buttons
- Navstick (up/down/left/right + click)
- 4MB flash model (2MB internal + 2MB external)

## Troubleshooting

- `Watcher not found. Start and reload.`:
  Start a watcher process (`zig build watch`) in a cart project that supports it.
- `Watcher was disconnected.`:
  Restart the watcher and reload the page.
- UI starts but no cart appears:
  Confirm `http://localhost:2468/cart.wasm` is reachable.

