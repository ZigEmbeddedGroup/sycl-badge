// Render a cart's framebuffer to a PNG, headlessly.
//
//   node rust/tools/shot.mjs [cart.wasm] [frames] [out.png] [scale] [x,y,w,h]
//
// The last argument crops, which is how you inspect a few pixels closely.
//
// Useful for looking at pixel-level detail without a browser in the way: the
// output is exactly what the simulator would composite, at whole-pixel scale.

import { readFileSync, writeFileSync } from "node:fs";
import { deflateSync } from "node:zlib";

const WIDTH = 160;
const HEIGHT = 128;
const ADDR_CONTROLS = 0x04;
const ADDR_FRAMEBUFFER = 0x20;

const cartPath = process.argv[2] ?? new URL("../target/cart.wasm", import.meta.url).pathname;
const frames = Number(process.argv[3] ?? 200);
const outPath = process.argv[4] ?? "/tmp/cart.png";
const scale = Number(process.argv[5] ?? 4);
const crop = process.argv[6]
  ? process.argv[6].split(",").map(Number)
  : [0, 0, WIDTH, HEIGHT];
const [cx, cy, cw, ch] = crop;

const memory = new WebAssembly.Memory({ initial: 64, maximum: 64 });
const env = {
  memory,
  rect: () => {},
  oval: () => {},
  line: () => {},
  hline: () => {},
  vline: () => {},
  text: () => {},
  blit: () => {},
  tone: () => {},
  read_flash: () => 0,
  write_flash_page: () => {},
  // Fixed, so the same frame number is the same picture every run. Without this
  // the cart's RNG differs per run and two renders cannot be compared.
  rand: () => 0x5eed_1234,
  trace: () => {},
};

const { instance } = await WebAssembly.instantiate(readFileSync(cartPath), { env });
const { exports } = instance;
const u16 = new Uint16Array(memory.buffer);
const view = new DataView(memory.buffer);

exports.start();
for (let f = 0; f < frames; f++) {
  view.setUint16(ADDR_CONTROLS, 0, true);
  exports.update();
}

// Framebuffer is column-major and byte-swapped RGB565.
const rgb = (x, y) => {
  const v = u16[ADDR_FRAMEBUFFER / 2 + x * HEIGHT + y];
  const p = ((v & 0xff) << 8) | (v >> 8);
  const r5 = (p >> 11) & 0x1f;
  const g6 = (p >> 5) & 0x3f;
  const b5 = p & 0x1f;
  // Replicate high bits so mid-tones do not come out dark.
  return [(r5 << 3) | (r5 >> 2), (g6 << 2) | (g6 >> 4), (b5 << 3) | (b5 >> 2)];
};

const outW = cw * scale;
const outH = ch * scale;
const raw = Buffer.alloc((outW * 3 + 1) * outH);
let at = 0;
for (let y = 0; y < outH; y++) {
  raw[at++] = 0; // filter: none
  for (let x = 0; x < outW; x++) {
    const [r, g, b] = rgb(cx + ((x / scale) | 0), cy + ((y / scale) | 0));
    raw[at++] = r;
    raw[at++] = g;
    raw[at++] = b;
  }
}

// ── Minimal PNG writer ───────────────────────────────────────────────────────

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

const crc32 = (buf) => {
  let c = ~0;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return ~c >>> 0;
};

const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(outW, 0);
ihdr.writeUInt32BE(outH, 4);
ihdr[8] = 8; // bit depth
ihdr[9] = 2; // truecolour
writeFileSync(
  outPath,
  Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(raw)),
    chunk("IEND", Buffer.alloc(0)),
  ]),
);

console.log(
  `${outPath}  ${outW}x${outH}  (${frames} frames, ${scale}x, crop ${crop.join(",")})`,
);
