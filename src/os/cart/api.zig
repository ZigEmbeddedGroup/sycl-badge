const std = @import("std");
const builtin = @import("builtin");

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Platform Constants                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const screen_width: u32 = 160;
pub const screen_height: u32 = 128;

pub const font_width: u32 = 8;
pub const font_height: u32 = 8;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Memory Addresses                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// RGB888, true color
pub const NeopixelColor = extern struct { g: u8, r: u8, b: u8 };

/// RGB565, high color
pub const DisplayColor = packed struct(u16) {
    /// 0-31
    b: u5,
    /// 0-63
    g: u6,
    /// 0-31
    r: u5,

    pub const Optional = enum(i32) {
        none = -1,
        _,

        pub fn from(color: ?DisplayColor) Optional {
            return if (color) |c| @enumFromInt(@as(u16, @bitCast(c))) else .none;
        }

        pub fn unwrap(opt: Optional) ?DisplayColor {
            return if (opt == .none) null else @bitCast(@as(u16, @truncate(@as(u32, @intCast(@intFromEnum(opt))))));
        }
    };
};

pub const Pixel = extern struct {
    bits: u16,

    pub fn fromColor(color: DisplayColor) Pixel {
        if (is_wasm) {
            // WASM/simulator: standard RGB565 big-endian (matches old behavior)
            return .{ .bits = @byteSwap(@as(u16, @bitCast(color))) };
        } else {
            // Native: Our ST7735S LCD expects BGR565 big-endian byte order
            // over SPI, i.e. [BBBBB_GGG, ggg_RRRRR]. Construct a BGR565
            // value (R and B swapped compared to standard RGB565) and then
            // byte-swap it so the bytes sit in memory in the correct SPI
            // transmission order.
            const bgr: u16 = (@as(u16, color.b) << 11) | (@as(u16, color.g) << 5) | @as(u16, color.r);
            return .{ .bits = @byteSwap(bgr) };
        }
    }

    pub fn toColor(pixel: Pixel) DisplayColor {
        if (is_wasm) {
            return @bitCast(@byteSwap(pixel.bits));
        } else {
            const bgr = @byteSwap(pixel.bits);
            return .{
                .r = @truncate(bgr),
                .g = @truncate(bgr >> 5),
                .b = @truncate(bgr >> 11),
            };
        }
    }

    pub fn setColor(pixel: *volatile Pixel, color: DisplayColor) void {
        pixel.* = fromColor(color);
    }
};

/// Button layout must match kernel.zig ButtonPoller.Buttons exactly:
/// start, select, a, b, click, up, down, left, right (bits 0-8).
/// Kernel writes u9 to ipc_controls (0x20020004) each frame when cart sends FRAMEBUFFER_READY.
pub const Controls = packed struct(u9) {
    start: bool,
    select: bool,
    a: bool,
    b: bool,
    click: bool,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
};

const is_wasm = switch (builtin.target.cpu.arch) {
    .wasm32, .wasm64 => true,
    else => false,
};

// Cart IPC block lives at the start of process_ram (0x20020000).
// The OS kernel (Core 0) writes sensor/button data here each frame, and reads
// the framebuffer back to DMA it to the LCD. The cart (Core 1) reads inputs
// and writes pixels. Using process_ram avoids colliding with kernel_ram
// (0x20000000) where the OS keeps its own data structures.
const base = if (is_wasm) 0 else 0x20020000;

pub const controls: *Controls = @ptrFromInt(base + 0x04);
pub const light_level: *u12 = @ptrFromInt(base + 0x06);
pub const neopixels: *[5]NeopixelColor = @ptrFromInt(base + 0x08);
pub const red_led: *bool = @ptrFromInt(base + 0x1c);
pub const battery_level: *u12 = @ptrFromInt(base + 0x1e);
pub const framebuffer: *volatile [screen_width][screen_height]Pixel = @ptrFromInt(base + 0x20);

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Drawing Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const BlitOptions = struct {
    pub const Flags = packed struct(u32) {
        flip_x: bool = false,
        flip_y: bool = false,
        rotate: bool = false,
        padding: u29 = undefined,
    };

    sprite: [*]const DisplayColor,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    /// x within the sprite atlas.
    src_x: u32 = 0,
    /// y within the sprite atlas.
    src_y: u32 = 0,
    /// Width of the entire sprite atlas.
    stride: ?u32 = null,
    flags: Flags = .{},
};

fn clipPixel(x: i32, y: i32, pixel: Pixel) void {
    if (x < 0 or x >= screen_width) return;
    if (y < 0 or y >= screen_height) return;
    framebuffer[@intCast(x)][@intCast(y)] = pixel;
}

/// Copies pixels to the framebuffer.
pub inline fn blit(options: BlitOptions) void {
    if (is_wasm) {
        struct {
            extern fn blit(sprite: [*]const DisplayColor, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: BlitOptions.Flags) void;
        }.blit(
            options.sprite,
            options.x,
            options.y,
            options.width,
            options.height,
            options.src_x,
            options.src_y,
            options.stride orelse options.width,
            options.flags,
        );
    } else {
        const stride = options.stride orelse options.width;
        const flags = options.flags;
        const signed_width: i32 = @intCast(options.width);
        const signed_height: i32 = @intCast(options.height);

        // Clip rectangle to screen, accounting for rotation swap of axes
        const flip_x, const clip_x_min: u32, const clip_y_min: u32, const clip_x_max: u32, const clip_y_max: u32 =
            if (flags.rotate) .{
                !flags.flip_x,
                @intCast(@max(0, options.y) - options.y),
                @intCast(@max(0, options.x) - options.x),
                @intCast(@min(signed_width, @as(i32, @intCast(screen_height)) - options.y)),
                @intCast(@min(signed_height, @as(i32, @intCast(screen_width)) - options.x)),
            } else .{
                flags.flip_x,
                @intCast(@max(0, options.x) - options.x),
                @intCast(@max(0, options.y) - options.y),
                @intCast(@min(signed_width, @as(i32, @intCast(screen_width)) - options.x)),
                @intCast(@min(signed_height, @as(i32, @intCast(screen_height)) - options.y)),
            };

        for (clip_y_min..clip_y_max) |y| {
            for (clip_x_min..clip_x_max) |x| {
                const signed_x: i32 = @intCast(x);
                const signed_y: i32 = @intCast(y);

                // Target pixel on screen
                const tx: u32 = @intCast(options.x + (if (flags.rotate) signed_y else signed_x));
                const ty: u32 = @intCast(options.y + (if (flags.rotate) signed_x else signed_y));

                // Source pixel in sprite atlas
                const sx = options.src_x + @as(u32, @intCast(if (flip_x) signed_width - signed_x - 1 else signed_x));
                const sy = options.src_y + @as(u32, @intCast(if (flags.flip_y) signed_height - signed_y - 1 else signed_y));

                framebuffer[tx][ty].setColor(options.sprite[sy * stride + sx]);
            }
        }
    }
}

pub const LineOptions = struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,
    color: DisplayColor,
};

/// Draws a line between two points.
pub inline fn line(options: LineOptions) void {
    if (is_wasm) {
        struct {
            extern fn line(color: DisplayColor, x1: i32, y1: i32, x2: i32, y2: i32) void;
        }.line(options.color, options.x1, options.y1, options.x2, options.y2);
    } else {
        // Bresenham's line algorithm
        var x0 = options.x1;
        var y0 = options.y1;
        const x1 = options.x2;
        const y1 = options.y2;
        const pixel = Pixel.fromColor(options.color);

        const dx: i32 = @intCast(@abs(x1 - x0));
        const sx: i32 = if (x0 < x1) 1 else -1;
        const dy = -@as(i32, @intCast(@abs(y1 - y0)));
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err = dx + dy;

        while (true) {
            clipPixel(x0, y0, pixel);
            if (x0 == x1 and y0 == y1) break;
            const e2 = 2 * err;
            if (e2 >= dy) {
                if (x0 == x1) break;
                err += dy;
                x0 += sx;
            }
            if (e2 <= dx) {
                if (y0 == y1) break;
                err += dx;
                y0 += sy;
            }
        }
    }
}

pub const OvalOptions = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    stroke_color: ?DisplayColor = null,
    fill_color: ?DisplayColor = null,
};

/// Draws an oval (or circle).
pub inline fn oval(options: OvalOptions) void {
    if (is_wasm) {
        struct {
            extern fn oval(stroke_color: DisplayColor.Optional, fill_color: DisplayColor.Optional, x: i32, y: i32, width: u32, height: u32) void;
        }.oval(
            DisplayColor.Optional.from(options.stroke_color),
            DisplayColor.Optional.from(options.fill_color),
            options.x,
            options.y,
            options.width,
            options.height,
        );
    } else {
        const stroke_color = DisplayColor.Optional.from(options.stroke_color);
        const fill_color = DisplayColor.Optional.from(options.fill_color);

        const signed_width: i32 = @intCast(options.width);
        const signed_height: i32 = @intCast(options.height);

        var a = signed_width - 1;
        const b = signed_height - 1;
        var b1 = @rem(b, 2);

        var north = options.y + @divFloor(signed_height, 2);
        var west = options.x;
        var east = options.x + signed_width - 1;
        var south = north - b1;

        const a2 = a * a;
        const b2 = b * b;
        var dx = 4 * (1 - a) * b2;
        var dy = 4 * (b1 + 1) * a2;
        var err = dx + dy + b1 * a2;

        a = 8 * a2;
        b1 = 8 * b2;

        const stroke_pixel = if (stroke_color.unwrap()) |sc| Pixel.fromColor(sc) else null;

        while (true) {
            if (stroke_pixel) |sp| {
                clipPixel(east, north, sp);
                clipPixel(west, north, sp);
                clipPixel(west, south, sp);
                clipPixel(east, south, sp);
            }

            const oval_start = west + 1;
            const len = east - oval_start;
            if (fill_color != .none and len > 0) {
                hline(.{ .x = oval_start, .y = north, .len = @intCast(len), .color = fill_color.unwrap().? });
                hline(.{ .x = oval_start, .y = south, .len = @intCast(len), .color = fill_color.unwrap().? });
            }

            const err2 = 2 * err;
            if (err2 <= dy) {
                north += 1;
                south -= 1;
                dy += a;
                err += dy;
            }
            if (err2 >= dx or err2 > dy) {
                west += 1;
                east -= 1;
                dx += b1;
                err += dx;
            }
            if (!(west <= east)) break;
        }

        if (stroke_pixel) |sp| {
            while (north - south < signed_height) {
                clipPixel(west - 1, north, sp);
                clipPixel(east + 1, north, sp);
                north += 1;
                clipPixel(west - 1, south, sp);
                clipPixel(east + 1, south, sp);
                south -= 1;
            }
        }
    }
}

pub const RectOptions = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    stroke_color: ?DisplayColor = null,
    fill_color: ?DisplayColor = null,
};

/// Draws a rectangle.
pub inline fn rect(options: RectOptions) void {
    if (is_wasm) {
        struct {
            extern fn rect(stroke_color: DisplayColor.Optional, fill_color: DisplayColor.Optional, x: i32, y: i32, width: u32, height: u32) void;
        }.rect(
            DisplayColor.Optional.from(options.stroke_color),
            DisplayColor.Optional.from(options.fill_color),
            options.x,
            options.y,
            options.width,
            options.height,
        );
    } else {
        const stroke_color = options.stroke_color;
        const fill_color = options.fill_color;

        if (stroke_color == null and fill_color == null) return;
        if (options.width == 0 or options.height == 0) return;
        if (options.x >= screen_width or options.y >= screen_height) return;

        const end_x = options.x +| @min(options.width, std.math.maxInt(i32));
        const end_y = options.y +| @min(options.height, std.math.maxInt(i32));
        if (end_x <= 0 or end_y <= 0) return;

        const min_x: usize = @intCast(@max(options.x, 0));
        const min_y: usize = @intCast(@max(options.y, 0));
        const max_x: usize = @intCast(@min(end_x, screen_width));
        const max_y: usize = @intCast(@min(end_y, screen_height));

        if (stroke_color) |sc| {
            const stroke_pixel = Pixel.fromColor(sc);
            if (options.x >= 0) @memset(framebuffer[min_x][min_y..max_y], stroke_pixel);
            if (options.width > 1 and end_x <= screen_width) @memset(framebuffer[max_x - 1][min_y..max_y], stroke_pixel);
            if (options.width > 2) {
                if (options.y >= 0) {
                    for (framebuffer[min_x + 1 .. max_x - 1]) |*col| col[min_y] = stroke_pixel;
                }
                if (options.height > 1 and end_y <= screen_height) {
                    for (framebuffer[min_x + 1 .. max_x - 1]) |*col| col[max_y - 1] = stroke_pixel;
                }
                if (options.height > 2) if (fill_color) |fc| {
                    const fill_pixel = Pixel.fromColor(fc);
                    for (framebuffer[min_x + 1 .. max_x - 1]) |*col| @memset(col[min_y + 1 .. max_y - 1], fill_pixel);
                };
            }
        } else if (fill_color) |fc| {
            const fill_pixel = Pixel.fromColor(fc);
            for (framebuffer[min_x..max_x]) |*col| @memset(col[min_y..max_y], fill_pixel);
        }
    }
}

pub const TextOptions = struct {
    str: []const u8,
    x: i32,
    y: i32,
    text_color: ?DisplayColor = null,
    background_color: ?DisplayColor = null,
};

/// Draws text using the built-in system font.
pub inline fn text(options: TextOptions) void {
    if (is_wasm) {
        struct {
            extern fn text(text_color: DisplayColor.Optional, background_color: DisplayColor.Optional, str_ptr: [*]const u8, str_len: usize, x: i32, y: i32) void;
        }.text(
            DisplayColor.Optional.from(options.text_color),
            DisplayColor.Optional.from(options.background_color),
            options.str.ptr,
            options.str.len,
            options.x,
            options.y,
        );
    } else {
        // Font bitmap: [char - ' '][row] where each byte is 8 pixels, 0-bit = foreground.
        // Accessed here (not at file scope) so that @import("board") is only resolved
        // for native builds — WASM builds take the branch above and never reach this.
        const font_data = @import("board").font.font;
        const text_pixel: ?Pixel = if (options.text_color) |c| Pixel.fromColor(c) else null;
        const bg_pixel: ?Pixel = if (options.background_color) |c| Pixel.fromColor(c) else null;

        var char_x: i32 = options.x;
        var char_y: i32 = options.y;

        for (options.str) |char| {
            if (char == '\n') {
                char_y += 8;
                char_x = options.x;
                continue;
            }
            if (char < 32 or char > 255) {
                char_x += 8;
                continue;
            }

            const glyph = font_data[char - 32];
            for (0..8) |row| {
                const row_bits = glyph[row];
                for (0..8) |col| {
                    const is_fg = (row_bits & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                    const px = if (is_fg) text_pixel else bg_pixel;
                    if (px) |p| {
                        clipPixel(char_x + @as(i32, @intCast(col)), char_y + @as(i32, @intCast(row)), p);
                    }
                }
            }
            char_x += 8;
        }
    }
}

pub const StraightLineOptions = struct {
    x: i32,
    y: i32,
    len: u32,
    color: DisplayColor,
};

/// Draws a horizontal line
pub inline fn hline(options: StraightLineOptions) void {
    if (is_wasm) {
        struct {
            extern fn hline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        }.hline(options.color, options.x, options.y, options.len);
    } else {
        if (options.len == 0 or options.y < 0 or options.y >= screen_height or options.x >= screen_width) return;
        const end_x = options.x +| @min(options.len, std.math.maxInt(i32));
        if (end_x <= 0) return;
        const pixel = Pixel.fromColor(options.color);
        for (framebuffer[@max(options.x, 0)..@intCast(@min(end_x, screen_width))]) |*col| {
            col[@intCast(options.y)] = pixel;
        }
    }
}

/// Draws a vertical line
pub inline fn vline(options: StraightLineOptions) void {
    if (is_wasm) {
        struct {
            extern fn vline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        }.vline(options.color, options.x, options.y, options.len);
    } else {
        if (options.len == 0 or options.x < 0 or options.x >= screen_width or options.y >= screen_height) return;
        const end_y = options.y +| @min(options.len, std.math.maxInt(i32));
        if (end_y <= 0) return;
        const pixel = Pixel.fromColor(options.color);
        @memset(framebuffer[@intCast(options.x)][@max(options.y, 0)..@intCast(@min(end_y, screen_height))], pixel);
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const ToneOptions = struct {
    pub const Flags = packed struct(u32) {
        pub const Channel = enum(u2) {
            pulse1,
            pulse2,
            triangle,
            noise,
        };

        pub const DutyCycle = enum(u2) {
            @"1/8",
            @"1/4",
            @"1/2",
            @"3/4",
        };

        pub const Panning = enum(u2) {
            stereo,
            left,
            right,
        };

        channel: Channel,
        /// `duty_cycle` is only used when `channel` is set to `pulse1` or `pulse2`
        duty_cycle: DutyCycle = .@"1/8",
        panning: Panning = .stereo,
        padding: u26 = undefined,
    };

    frequency: u32,
    duration: u32,
    volume: u32,
    flags: Flags,
};

/// Plays a sound tone.
/// NOTE: Audio driver not yet implemented; this is a no-op stub.
pub inline fn tone(options: ToneOptions) void {
    if (is_wasm) {
        struct {
            extern fn tone(frequency: u32, duration: u32, volume: u32, flags: ToneOptions.Flags) void;
        }.tone(options.frequency, options.duration, options.volume, options.flags);
    } else {
        // no-op stub: audio driver not yet implemented
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Storage Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const flash_page_size = 256;
pub const flash_page_count = 8000;

/// Attempts to fill `dst`, returns the amount of bytes actually read.
/// NOTE: No dedicated cart save-data flash region exists yet; returns 0.
pub inline fn read_flash(offset: u32, dst: []u8) u32 {
    if (is_wasm) {
        return struct {
            extern fn read_flash(offset: u32, dst: [*]u8, len: u32) u32;
        }.read_flash(offset, dst.ptr, dst.len);
    } else {
        // no-op stub: no cart save-data flash region yet
        return 0;
    }
}

/// NOTE: No dedicated cart save-data flash region exists yet; this is a no-op stub.
pub inline fn write_flash_page(page: u16, src: [flash_page_size]u8) void {
    if (is_wasm) {
        struct {
            extern fn write_flash_page(page: u32, src: [*]const u8) void;
        }.write_flash_page(page, &src);
    } else {
        // no-op stub: no cart save-data flash region yet
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Returns a random number from the RP2350 ring oscillator random bit.
/// Useful for seeding a faster PRNG.
pub inline fn rand() u32 {
    if (is_wasm) {
        return struct {
            extern fn rand() u32;
        }.rand();
    } else {
        // RP2350 ROSC STATUS register: bit 16 = RANDOMBIT
        const ROSC_STATUS: *const volatile u32 = @ptrFromInt(0x4006000C);
        var result: u32 = 0;
        var i: u5 = 0;
        while (i < 32) : (i += 1) {
            result = (result << 1) | ((ROSC_STATUS.* >> 16) & 1);
        }
        return result;
    }
}

/// Prints a message to the debug console.
/// NOTE: UART is owned by the kernel; trace is a no-op from the cart side.
/// Use a JTAG/SWD debugger or a shared ring buffer (future work) for cart logging.
pub inline fn trace(x: []const u8) void {
    if (is_wasm) {
        struct {
            extern fn trace(str_ptr: [*]const u8, str_len: usize) void;
        }.trace(x.ptr, x.len);
    } else {
        // no-op stub: UART is owned by kernel, no cart trace output
    }
}

/// Signal Core 0 that the framebuffer is ready and wait for the
/// LCD flush to complete before returning.
///
/// Call this once per frame (typically at the end of `update()`).
/// On WASM this is a no-op because the simulator owns the display.
pub inline fn present() void {
    if (is_wasm) {
        // Simulator flushes automatically — nothing to do.
        return;
    }

    // RP2350 SIO FIFO registers (same address on both cores, core-local view)
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const SIO_FIFO_RD: *volatile u32 = @ptrFromInt(0xD0000058);

    const FIFO_RDY: u32 = 1 << 1; // write-FIFO ready (space available)
    const FIFO_VLD: u32 = 1 << 0; // read-FIFO valid (data available)

    // Message constants — must match mailbox.MessageType values in the OS.
    const FRAMEBUFFER_READY: u32 = 0x25000001;
    const FRAMEBUFFER_DONE: u32 = 0x25000002;

    // Drain any stale messages so we don't mistake an old reply for DONE.
    while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
        _ = SIO_FIFO_RD.*;
    }

    // Wait until the write FIFO has space, then send FRAMEBUFFER_READY.
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
        asm volatile ("nop");
    }
    SIO_FIFO_WR.* = FRAMEBUFFER_READY;
    // SEV to wake Core 0 in case it's in WFE.
    asm volatile ("sev");

    // Block until Core 0 replies with FRAMEBUFFER_DONE.
    // This ensures we don't start writing the next frame while the DMA
    // transfer from the shared framebuffer is still in progress.
    while (true) {
        while (SIO_FIFO_ST.* & FIFO_VLD == 0) {
            asm volatile ("nop");
        }
        const reply = SIO_FIFO_RD.*;
        if (reply == FRAMEBUFFER_DONE) break;
        // Ignore other messages (e.g. leftover control messages).
    }
}
