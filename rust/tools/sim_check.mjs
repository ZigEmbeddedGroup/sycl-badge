// Headless simulator harness: instantiate a cart the same way the browser
// simulator does and check it actually renders. Catches the failure modes that
// are invisible in a normal build — a stack that overlaps the framebuffer, an
// unimported memory, drawing that the optimizer deleted.
//
//   node rust/tools/sim_check.mjs [path/to/cart.wasm]
//
// Mirrors simulator/src/runtime.ts and simulator/src/constants.ts.

import { readFileSync } from "node:fs";

const WIDTH = 160;
const HEIGHT = 128;
const ADDR_CONTROLS = 0x04;
const ADDR_NEOPIXELS = 0x08;
const ADDR_RED_LED = 0x1c;
const ADDR_FRAMEBUFFER = 0x20;
const FB_END = ADDR_FRAMEBUFFER + WIDTH * HEIGHT * 2;

const CONTROLS = { start: 1, select: 2, a: 4, b: 8, click: 16, up: 32, down: 64, left: 128, right: 256 };

const cartPath = process.argv[2] ?? new URL("../target/cart.wasm", import.meta.url).pathname;
const bytes = readFileSync(cartPath);

let failures = 0;
function check(ok, label, detail = "") {
  console.log(`${ok ? "  ok  " : " FAIL "} ${label}${detail ? ` — ${detail}` : ""}`);
  if (!ok) failures++;
}

// ── Module-level checks, before instantiating ────────────────────────────────

const module_ = await WebAssembly.compile(bytes);
const imports = WebAssembly.Module.imports(module_);
const exports_ = WebAssembly.Module.exports(module_);

console.log(`cart: ${cartPath} (${bytes.length} bytes)`);
console.log("\nmodule:");
check(
  imports.some((i) => i.module === "env" && i.name === "memory" && i.kind === "memory"),
  "imports env.memory",
  "without --import-memory the cart runs against its own memory and renders nothing",
);
check(exports_.some((e) => e.name === "start"), "exports start");
check(exports_.some((e) => e.name === "update"), "exports update");
check(bytes.length <= 64 * 1024, "within the simulator's 64 KiB soft limit", `${bytes.length} bytes`);

// ── Instantiate exactly as the simulator does ───────────────────────────────

const memory = new WebAssembly.Memory({ initial: 64, maximum: 64 });
const traces = [];
const tones = [];
const unexpected = [];

const notImplemented = (name) => (...args) => unexpected.push([name, args]);

const env = {
  memory,
  rect: notImplemented("rect"),
  oval: notImplemented("oval"),
  line: notImplemented("line"),
  hline: notImplemented("hline"),
  vline: notImplemented("vline"),
  text: notImplemented("text"),
  blit: notImplemented("blit"),
  tone: (frequency, duration, volume, flags) => tones.push({ frequency, duration, volume, flags }),
  read_flash: () => 0,
  write_flash_page: () => {},
  rand: () => (Math.random() * 0x100000000) >>> 0,
  trace: (ptr, len) => traces.push(Buffer.from(memory.buffer, ptr, len).toString("utf8")),
};

const { exports } = await WebAssembly.instantiate(module_, { env });
const u8 = new Uint8Array(memory.buffer);
const u16 = new Uint16Array(memory.buffer);
const view = new DataView(memory.buffer);

console.log("\nmemory layout:");
if (exports.__data_end && exports.__heap_base) {
  const dataEnd = exports.__data_end.value;
  check(dataEnd > FB_END, "static data sits above the framebuffer", `__data_end=0x${dataEnd.toString(16)}`);
}
if (exports.__stack_pointer) {
  const sp = exports.__stack_pointer.value;
  check(sp >= FB_END, "stack starts above the framebuffer", `__stack_pointer=0x${sp.toString(16)}`);
} else {
  console.log("  --   stack pointer not exported; skipping stack-overlap check");
}

// ── Run frames ──────────────────────────────────────────────────────────────

// Poison the framebuffer so anything we see afterwards was really written.
const POISON = 0xab;
u8.fill(POISON, ADDR_FRAMEBUFFER, FB_END);

exports.start();

const framebufferWritten = () => {
  for (let i = ADDR_FRAMEBUFFER; i < FB_END; i++) if (u8[i] !== POISON) return true;
  return false;
};

console.log("\nrendering:");
check(framebufferWritten(), "start() drew something", "plain stores to shared memory can be optimized away");

const pixel = (x, y) => u16[ADDR_FRAMEBUFFER / 2 + x * HEIGHT + y];
const decode = (v) => {
  const rgb = ((v & 0xff) << 8) | (v >> 8);
  return [(rgb >> 11) & 0x1f, (rgb >> 5) & 0x3f, rgb & 0x1f];
};

// A flap every 25 frames is roughly neutral buoyancy for this cart's tuning, so
// the bird survives long enough to pass a pipe and score.
const FRAMES = 260;
for (let f = 0; f < FRAMES; f++) {
  view.setUint16(ADDR_CONTROLS, f % 25 === 0 ? CONTROLS.a : 0, true);
  exports.update();
}

const distinct = new Set();
for (let x = 0; x < WIDTH; x++) for (let y = 0; y < HEIGHT; y++) distinct.add(pixel(x, y));
check(distinct.size >= 4, "renders several distinct colors", `${distinct.size} distinct`);
check(!distinct.has((POISON << 8) | POISON), "every pixel was written at least once");

// Ground band should be a solid horizontal stripe near the bottom.
const groundRow = HEIGHT - 4;
const groundColor = pixel(0, groundRow);
let solid = true;
for (let x = 0; x < WIDTH; x++) if (pixel(x, groundRow) !== groundColor) solid = false;
check(solid, "ground is a solid stripe", `row ${groundRow} = rgb565 ${decode(groundColor).join(",")}`);

console.log("\nservices:");
check(unexpected.length === 0, "does not call the host drawing imports", unexpected.map(([n]) => n).join(", "));
check(tones.length > 0, "played audio", `${tones.length} tone calls`);
if (tones.length) {
  const t = tones[0];
  const duty = (t.flags >> 2) & 0x3;
  const channel = t.flags & 0x3;
  check(channel === 0, "uses pulse channel 0", `channel=${channel}`);
  check(duty === 2, "uses 50% duty, matching the badge buzzer", `duty mode=${duty}`);
  check(
    (t.volume & 0xff) === ((t.volume >> 8) & 0xff),
    "sustain and peak volume are equal",
    `volume=0x${t.volume.toString(16)}`,
  );
  check((t.duration & 0xffffff00) === 0, "duration fits the sustain byte only (no stray ADSR)", `duration=${t.duration}`);
}
check(traces.length > 0, "emitted trace output", `${traces.length} messages`);
for (const t of traces.slice(0, 6)) console.log(`       trace: ${t}`);

// ── Picture, for eyeballing ──────────────────────────────────────────────────

const RAMP = " .:-=+*#%@";
console.log("\nframe after " + FRAMES + " updates:");
for (let y = 0; y < HEIGHT; y += 4) {
  let row = "      ";
  for (let x = 0; x < WIDTH; x += 2) {
    const [r, g, b] = decode(pixel(x, y));
    const lum = (r / 31 + g / 63 + b / 31) / 3;
    row += RAMP[Math.min(RAMP.length - 1, Math.floor(lum * RAMP.length))];
  }
  console.log(row);
}

console.log(failures === 0 ? "\nall checks passed" : `\n${failures} check(s) failed`);
process.exit(failures === 0 ? 0 : 1);
