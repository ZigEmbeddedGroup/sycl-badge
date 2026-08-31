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
// Optional: selects the cart-specific behaviour checks at the bottom.
const kind = process.argv[3] ?? "";
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

/// Encode a 0xRRGGBB literal the way the simulator's framebuffer stores it.
const enc = (hex) => {
  const r = ((hex >> 16) & 255) >> 3;
  const g = ((hex >> 8) & 255) >> 2;
  const b = (hex & 255) >> 3;
  const v = (r << 11) | (g << 5) | b;
  return ((v & 0xff) << 8) | (v >> 8);
};

const press = (mask, hold = 1, release = 6) => {
  view.setUint16(ADDR_CONTROLS, mask, true);
  for (let i = 0; i < hold; i++) exports.update();
  const sample = pixel(0, 0);
  view.setUint16(ADDR_CONTROLS, 0, true);
  for (let i = 0; i < release; i++) exports.update();
  return sample;
};

const idle = (n) => {
  view.setUint16(ADDR_CONTROLS, 0, true);
  for (let i = 0; i < n; i++) exports.update();
};

// Drive the cart. Each kind gets input that actually exercises it; unknown carts
// just get a periodic button so something happens.
const itest = { white: 0, red: 0, completed: false, sclera: 0, iris: 0, pupil: 0 };
let FRAMES = 260;

if (kind === "itest") {
  idle(140); // past the intro

  // Measure the eye over a stretch of frames, taking the widest opening seen so
  // a blink cannot skew it.
  const BG = enc(0x282a36);
  const SOCKET = enc(0x44475a);
  const isEye = (px) => px !== BG && px !== SOCKET;
  const EYE_CX = 80;
  const EYE_CY = 50;
  // Restrict to the eye's own region: the HUD text, pips and corner brackets are
  // also "not background", and counting them made the opening look square.
  const X0 = 41;
  const X1 = 120;
  const Y0 = 14;
  const Y1 = 72;

  // Long enough to cover several fixations, since the gaze holds for up to two
  // seconds at a time.
  for (let f = 0; f < 240; f++) {
    // Height of the opening at the centre column, and at 80% of the way out.
    for (const [dx, key] of [[0, "hCentre"], [27, "hOuter"]]) {
      // Walk outward from the eye's centre while the pixel still belongs to the
      // opening. The lid band terminates the run, so anything drawn beyond it --
      // lashes, brackets, HUD -- cannot inflate the measurement. Taking the
      // whole column's extent instead was fragile: longer lashes reaching into
      // this column made the lids look like they barely tapered at all.
      const x = EYE_CX + dx;
      let lo = EYE_CY;
      let hi = EYE_CY;
      if (!isEye(pixel(x, EYE_CY))) continue;
      while (lo > Y0 && isEye(pixel(x, lo - 1))) lo--;
      while (hi < Y1 - 1 && isEye(pixel(x, hi + 1))) hi++;
      if (hi - lo + 1 > (itest[key] ?? 0)) {
        itest[key] = hi - lo + 1;
        if (dx === 0) itest.midY = (lo + hi) / 2;
      }
    }
    // Width of the opening.
    // Width: columns whose opening is open at the eye's vertical centre.
    let cols = 0;
    for (let x = X0; x < X1; x++) {
      if (isEye(pixel(x, EYE_CY))) cols++;
    }
    itest.width = Math.max(itest.width ?? 0, cols);

    // Iris horizontal extent, to observe foreshortening as the eye rotates.
    let ilo = Infinity;
    let ihi = -Infinity;
    const CYAN = enc(0x8be9fd);
    const PURPLE = enc(0xbd93f9);
    for (let x = X0; x < X1; x++) {
      for (let y = Y0; y < Y1; y++) {
        const px = pixel(x, y);
        if (px === CYAN || px === PURPLE) {
          ilo = Math.min(ilo, x);
          ihi = Math.max(ihi, x);
          break;
        }
      }
    }
    if (ihi >= ilo) {
      const w = ihi - ilo + 1;
      itest.irisMax = Math.max(itest.irisMax ?? 0, w);
      itest.irisMin = Math.min(itest.irisMin ?? 999, w);
    }
    idle(1);
  }

  // Layer census on the final frame.
  const FGC = enc(0xf8f8f2);
  const CYANC = enc(0x8be9fd);
  for (let x = 0; x < WIDTH; x++) {
    for (let y = 0; y < HEIGHT; y++) {
      const px = pixel(x, y);
      if (px === FGC) itest.sclera++;
      if (px === CYANC) itest.iris++;
      if (px === 0) itest.pupil++;
    }
  }

  // The prompt order is shuffled, so press buttons in turn like a player would.
  const BUTTONS = Object.values(CONTROLS);
  const FG = enc(0xf8f8f2);
  const RED = enc(0xff5555);
  const GREEN = enc(0x50fa7b);
  outer: for (let round = 0; round < 24 && !itest.completed; round++) {
    for (const mask of BUTTONS) {
      const flash = press(mask);
      if (flash === FG) itest.white++;
      else if (flash === RED) itest.red++;

      // Completion shows all nine pips filled green: 9 pips x 8px = 72 pixels on
      // that row. Eight pips is 64, so the threshold has to sit above that or we
      // stop a step early.
      let greens = 0;
      for (let x = 0; x < WIDTH; x++) if (pixel(x, 108) === GREEN) greens++;
      if (greens >= 70) {
        itest.completed = true;
        break outer;
      }
    }
  }
  FRAMES = 0;
} else {
  // flappy: a flap every 25 frames is roughly neutral buoyancy for its tuning,
  // so the bird survives long enough to pass a pipe and score.
  for (let f = 0; f < FRAMES; f++) {
    view.setUint16(ADDR_CONTROLS, f % 25 === 0 ? CONTROLS.a : 0, true);
    exports.update();
  }
}

const distinct = new Set();
for (let x = 0; x < WIDTH; x++) for (let y = 0; y < HEIGHT; y++) distinct.add(pixel(x, y));
check(distinct.size >= 4, "renders several distinct colors", `${distinct.size} distinct`);
check(!distinct.has((POISON << 8) | POISON), "every pixel was written at least once");

console.log("\nservices:");
check(unexpected.length === 0, "does not call the host drawing imports", unexpected.map(([n]) => n).join(", "));
// Silencing a channel is an all-zero call, and the framework makes several of
// those per note, so look only at the calls that actually sound.
const sounding = tones.filter((t) => t.frequency > 0 && t.volume > 0);
check(sounding.length > 0, "played audio", `${sounding.length} of ${tones.length} tone calls sound`);
if (sounding.length) {
  // The badge buzzer has three wave shapes, and each maps onto exactly one set
  // of APU flags. Anything else means a cart is composing against audio the
  // hardware cannot reproduce.
  const SHAPES = new Map([
    [2 << 2, "square (pulse 0, 50% duty)"],
    [2, "triangle (channel 2)"],
    [1 << 2, "sawtooth (pulse 0, 25% duty)"],
  ]);
  const strays = [...new Set(sounding.map((t) => t.flags))].filter((f) => !SHAPES.has(f));
  check(
    strays.length === 0,
    "every note uses a wave shape the badge can reproduce",
    strays.length
      ? `stray flags=${strays.join(",")}`
      : [...new Set(sounding.map((t) => SHAPES.get(t.flags)))].join(", "),
  );

  const t = sounding[0];
  check(
    (t.volume & 0xff) === ((t.volume >> 8) & 0xff),
    "sustain and peak volume are equal",
    `volume=0x${t.volume.toString(16)}`,
  );
  check((t.duration & 0xffffff00) === 0, "duration fits the sustain byte only (no stray ADSR)", `duration=${t.duration}`);
}
check(traces.length > 0, "emitted trace output", `${traces.length} messages`);
for (const t of traces.slice(0, 6)) console.log(`       trace: ${t}`);

if (kind === "flappy") {
  console.log("\nflappy:");
  // Ground band should be a solid horizontal stripe near the bottom.
  const groundRow = HEIGHT - 4;
  const groundColor = pixel(0, groundRow);
  let solid = true;
  for (let x = 0; x < WIDTH; x++) if (pixel(x, groundRow) !== groundColor) solid = false;
  check(solid, "ground is a solid stripe", `row ${groundRow} = rgb565 ${decode(groundColor).join(",")}`);

  // Sprite transparency, end to end. The bird's palette contains no value that
  // encodes to 0, so the framework's transparency stand-in is 0x0000 — and nothing
  // in this cart draws pure black. Any black pixel therefore means a transparent
  // sprite pixel leaked through the blit.
  let leaked = 0;
  for (let x = 0; x < WIDTH; x++) for (let y = 0; y < HEIGHT; y++) if (pixel(x, y) === 0) leaked++;
  check(leaked === 0, "sprite transparency does not leak the key colour", `${leaked} black pixels`);

  // And the sprite is actually on screen, so the check above isn't vacuous.
  const BIRD_BODY = (() => {
    // 0xf8d828 -> rgb565 (31, 54, 5), stored byte-swapped.
    const rgb = (31 << 11) | (54 << 5) | 5;
    return ((rgb & 0xff) << 8) | (rgb >> 8);
  })();
  let bodyPixels = 0;
  for (let x = 0; x < WIDTH; x++) for (let y = 0; y < HEIGHT; y++) if (pixel(x, y) === BIRD_BODY) bodyPixels++;
  check(bodyPixels > 10, "the bird sprite is drawn", `${bodyPixels} body pixels`);
}

if (kind === "itest") {
  console.log("\nitest:");
  check(itest.sclera > 300, "sclera is drawn", `${itest.sclera} px`);
  check(itest.iris > 40, "iris is drawn", `${itest.iris} px`);
  check(itest.pupil > 15, "pupil is drawn", `${itest.pupil} px`);

  // Proportions: a real palpebral fissure is roughly 2.7x wider than tall.
  const aspect = itest.width / itest.hCentre;
  check(
    aspect > 2.2 && aspect < 3.2,
    "opening is proportioned like an eye, not a circle",
    `${itest.width}x${itest.hCentre} = ${aspect.toFixed(2)}:1`,
  );

  // The upper lid arcs higher than the lower drops, so the opening's vertical
  // midpoint sits above the eye's centre.
  check(itest.midY < 50, "widest point sits above centre", `mid y ${itest.midY} vs centre 50`);

  // Almond, not ellipse. At 80% of the half-width an ellipse would still be 60%
  // of its centre height; two circular arcs come in much lower than that, which
  // is what gives the pointed corners.
  const taper = itest.hOuter / itest.hCentre;
  check(
    taper < 0.55,
    "lids taper to pointed corners rather than bulging like an ellipse",
    `${(taper * 100).toFixed(0)}% of centre height at 80% out (ellipse would be 60%)`,
  );

  // Reported, not asserted: the gaze is random, so how far the eye happens to
  // rotate during the sample varies run to run.
  // Reported rather than asserted: how far the eye happens to rotate during the
  // sample is random. 21 px is the unforeshortened iris body; anything less is
  // the cosine of the rotation angle showing up.
  console.log(
    `       iris body ${itest.irisMin}-${itest.irisMax} px wide across the sample ` +
      `(21 = facing you, less = rotated away and foreshortened)`,
  );

  check(itest.white === 9, "exactly nine correct answers flashed white", `${itest.white} white flashes`);
  check(itest.red > 0, "wrong answers flashed red", `${itest.red} red flashes`);
  check(itest.completed, "walked through every input to completion");
}

// ── Picture, for eyeballing ──────────────────────────────────────────────────

const RAMP = " .:-=+*#%@";
console.log("\nfinal frame:");
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
