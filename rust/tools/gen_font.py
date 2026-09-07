#!/usr/bin/env python3
"""Regenerate sycl-cart/src/font.rs from ../src/font.zig.

The Zig font stores 224 glyphs (U+0020..U+00FF) as 8 rows of 8 bits, bit 7 =
leftmost pixel, and *0 means foreground* (see src/os/cart/api.zig `is_fg`).
We invert on the way out so the Rust table uses the intuitive 1 = foreground,
which keeps the glyph blit loop branch-free.

Usage: python3 rust/tools/gen_font.py   (run from the repo root)
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "src" / "font.zig"
DST = REPO / "rust" / "sycl-cart" / "src" / "font.rs"

GLYPHS = 224  # 0x100 - 0x20


def main() -> int:
    text = SRC.read_text()
    bytes_ = [int(m, 2) for m in re.findall(r"0b([01]{8})", text)]
    if len(bytes_) != GLYPHS * 8:
        print(f"expected {GLYPHS * 8} bytes, parsed {len(bytes_)}", file=sys.stderr)
        return 1

    out = [
        "//! 8x8 bitmap font, generated from `src/font.zig` by `rust/tools/gen_font.py`.",
        "//!",
        "//! DO NOT EDIT BY HAND. 224 glyphs covering U+0020..=U+00FF.",
        "//! Row-major within a glyph: `GLYPHS[c - 32][row]`, bit 7 = leftmost pixel.",
        "//! Bits are inverted relative to `font.zig`, so here **1 means foreground**.",
        "",
        "/// First character in the table.",
        "pub const FIRST: u8 = 0x20;",
        "/// Glyph width in pixels.",
        "pub const WIDTH: u32 = 8;",
        "/// Glyph height in pixels.",
        "pub const HEIGHT: u32 = 8;",
        "",
        f"pub static GLYPHS: [[u8; 8]; {GLYPHS}] = [",
    ]

    for g in range(GLYPHS):
        rows = bytes_[g * 8 : g * 8 + 8]
        inverted = ", ".join(f"0x{(~b) & 0xFF:02x}" for b in rows)
        ch = 0x20 + g
        label = chr(ch) if 0x20 < ch < 0x7F else ""
        comment = f" // U+{ch:04X}{' ' + label if label else ''}"
        out.append(f"    [{inverted}],{comment}")

    out.append("];")
    out.append("")
    DST.write_text("\n".join(out))
    print(f"wrote {DST.relative_to(REPO)} ({GLYPHS} glyphs)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
