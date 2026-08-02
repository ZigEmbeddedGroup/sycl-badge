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
// │ Time Functions                                                            │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn microsSinceBoot() u64 {
    if (is_wasm) {
        // TODO
        const statics = struct {
            var last_val: u64 = 0;
        };
        statics.last_val += 1000;
        return statics.last_val;
    } else {
        const TIMER0_TIMEHR: *volatile u32 = @ptrFromInt(0x400b0008);
        const TIMER0_TIMELR: *volatile u32 = @ptrFromInt(0x400b000c);
        const lr = TIMER0_TIMELR.*; // always lr first
        const hr = TIMER0_TIMEHR.*;
        return (@as(u64, hr) << 32) | lr;
    }
}

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
pub const Controls = packed struct(u16) {
    start: bool,
    select: bool,
    a: bool,
    b: bool,
    click: bool,
    up: bool,
    down: bool,
    left: bool,
    right: bool,
    _: u7,
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
const base = if (is_wasm) 4 else 0x20020004;
pub const CartIPCData = extern struct {
    controls: Controls,
    light_level: u16,
    neopixels: [5]NeopixelColor,
    _pad1: [5]u8,
    red_led: bool,
    _pad2: u8,
    battery_level: u16,
    framebuffers: [2][screen_width][screen_height]Pixel,
    trace_buf: [0x80]u8,
    tone_freq: f32,
    tone_duration: f32,
    dirty_rect_x: u16,
    dirty_rect_y: u16,
    dirty_rect_w: u16,
    dirty_rect_h: u16,
    tone_volume: f32,
    tone_flags: u32,
    global_volume: f32,
};
const ipc_data: *volatile CartIPCData = @ptrFromInt(base);

/// Volatile: kernel (Core 0) writes button state every frame; cart must read fresh each access.
pub const controls: *const volatile Controls = &ipc_data.controls;
pub const light_level: *volatile u12 = @ptrCast(&ipc_data.light_level);
pub const neopixels: *volatile [5]NeopixelColor = &ipc_data.neopixels;
pub const red_led: *volatile bool = &ipc_data.red_led;
pub const battery_level: *volatile u12 = @ptrCast(&ipc_data.battery_level);
const framebuffer0: *volatile [screen_width][screen_height]Pixel = &ipc_data.framebuffers[0];
const framebuffer1: *volatile [screen_width][screen_height]Pixel = &ipc_data.framebuffers[1];
pub var framebuffer: *volatile [screen_width][screen_height]Pixel = framebuffer0;
var draw_buffer_index: u1 = 0;
var has_in_flight_frame: bool = false;
var present_timeout_events: u32 = 0;

const present_wait_spin_limit: u32 = 8_000_000;

var dirty_any: bool = false;
var dirty_min_x: u16 = 0;
var dirty_min_y: u16 = 0;
var dirty_max_x: u16 = 0;
var dirty_max_y: u16 = 0;

fn updateDrawBufferPointer() void {
    framebuffer = if (draw_buffer_index == 0) framebuffer0 else framebuffer1;
}

fn resetDirtyRect() void {
    dirty_any = false;
    dirty_min_x = 0;
    dirty_min_y = 0;
    dirty_max_x = 0;
    dirty_max_y = 0;
}

pub inline fn markDirtyRect(x: i32, y: i32, w: i32, h: i32) void {
    if (w <= 0 or h <= 0) return;

    const x0 = @max(x, 0);
    const y0 = @max(y, 0);
    const x1 = @min(x +| w, @as(i32, @intCast(screen_width)));
    const y1 = @min(y +| h, @as(i32, @intCast(screen_height)));
    if (x0 >= x1 or y0 >= y1) return;

    const ux0: u16 = @intCast(x0);
    const uy0: u16 = @intCast(y0);
    const ux1: u16 = @intCast(x1 - 1);
    const uy1: u16 = @intCast(y1 - 1);

    if (!dirty_any) {
        dirty_any = true;
        dirty_min_x = ux0;
        dirty_min_y = uy0;
        dirty_max_x = ux1;
        dirty_max_y = uy1;
        return;
    }

    if (ux0 < dirty_min_x) dirty_min_x = ux0;
    if (uy0 < dirty_min_y) dirty_min_y = uy0;
    if (ux1 > dirty_max_x) dirty_max_x = ux1;
    if (uy1 > dirty_max_y) dirty_max_y = uy1;
}

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

        markDirtyRect(options.x, options.y, if (flags.rotate) signed_height else signed_width, if (flags.rotate) signed_width else signed_height);

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

                // Use clipPixel and Pixel.fromColor so any out-of-bounds tx/ty are safely
                // discarded instead of causing a hard fault when indexing the framebuffer.
                if (tx < screen_width and ty < screen_height) {
                    framebuffer[tx][ty] = Pixel.fromColor(options.sprite[sy * stride + sx]);
                }
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

        markDirtyRect(@min(options.x1, options.x2), @min(options.y1, options.y2), @abs(options.x2 - options.x1) + 1, @abs(options.y2 - options.y1) + 1);

        while (true) {
            if (x0 >= 0 and x0 < screen_width and y0 >= 0 and y0 < screen_height) {
                framebuffer[@intCast(x0)][@intCast(y0)] = pixel;
            }
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

        // Fast path: small fill-only ovals use direct memset instead of ellipse algorithm
        // This is crucial for performance when rendering many small circles (e.g., pellets).
        // Threshold: width/height <= 8 pixels and fill-only (no stroke).
        if (options.width <= 8 and options.height <= 8 and stroke_color == .none and fill_color != .none) {
            const x = options.x;
            const y = options.y;
            const w = @as(i32, @intCast(options.width));
            const h = @as(i32, @intCast(options.height));

            const min_x: usize = @intCast(@max(x, 0));
            const min_y: usize = @intCast(@max(y, 0));
            const max_x: usize = @intCast(@min(x + w, @as(i32, @intCast(screen_width))));
            const max_y: usize = @intCast(@min(y + h, @as(i32, @intCast(screen_height))));

            if (min_x >= max_x or min_y >= max_y) return;

            const fill_pixel = Pixel.fromColor(fill_color.unwrap().?);
            for (framebuffer[min_x..max_x]) |*col| {
                @memset(col[min_y..max_y], fill_pixel);
            }
            markDirtyRect(x, y, w, h);
            return;
        }

        const signed_width: i32 = @intCast(options.width);
        const signed_height: i32 = @intCast(options.height);

        markDirtyRect(options.x, options.y, signed_width, signed_height);

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

        markDirtyRect(options.x, options.y, @intCast(end_x - options.x), @intCast(end_y - options.y));

        if (stroke_color) |sc| {
            const stroke_pixel = Pixel.fromColor(sc);
            if (min_x < max_x and min_y < max_y) {
                @memset(framebuffer[min_x][min_y..max_y], stroke_pixel);
                if (max_x > min_x + 1) {
                    @memset(framebuffer[max_x - 1][min_y..max_y], stroke_pixel);
                }
            }
            if (max_x > min_x + 2 and min_y + 1 < max_y) {
                for (framebuffer[min_x + 1 .. max_x - 1]) |*col| {
                    col[min_y] = stroke_pixel;
                    col[max_y - 1] = stroke_pixel;
                }
            }
            if (fill_color) |fc| {
                const fill_pixel = Pixel.fromColor(fc);
                if (max_x > min_x + 2 and max_y > min_y + 2) {
                    for (framebuffer[min_x + 1 .. max_x - 1]) |*col| {
                        @memset(col[min_y + 1 .. max_y - 1], fill_pixel);
                    }
                }
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
    scale: u32 = 1,
    text_color: ?DisplayColor = null,
    background_color: ?DisplayColor = null,
};

/// Draws text using the built-in system font.
pub inline fn text(options: TextOptions) void {
    if (is_wasm) {
        struct {
            extern fn text(text_color: DisplayColor.Optional, background_color: DisplayColor.Optional, str_ptr: [*]const u8, str_len: usize, x: i32, y: i32, scale: u32) void;
        }.text(
            DisplayColor.Optional.from(options.text_color),
            DisplayColor.Optional.from(options.background_color),
            options.str.ptr,
            options.str.len,
            options.x,
            options.y,
            options.scale,
        );
    } else {
        // Font bitmap: [char - ' '][row] where each byte is 8 pixels, 0-bit = foreground.
        // Accessed here (not at file scope) so that @import("board") is only resolved
        // for native builds — WASM builds take the branch above and never reach this.
        const font_data = @import("board").font.font;
        const text_pixel: ?Pixel = if (options.text_color) |c| Pixel.fromColor(c) else null;
        const bg_pixel: ?Pixel = if (options.background_color) |c| Pixel.fromColor(c) else null;
        const scale = @max(options.scale, 1);
        const scale_usize: usize = @intCast(scale);
        const line_step: i32 = @as(i32, @intCast(@as(u32, 8) * scale));

        var longest_line: i32 = 0;
        var current_line: i32 = 0;
        var line_count: i32 = 1;
        for (options.str) |char| {
            if (char == '\n') {
                if (current_line > longest_line) longest_line = current_line;
                current_line = 0;
                line_count += 1;
            } else if (char >= 32 and char <= 255) {
                current_line += 1;
            }
        }
        if (current_line > longest_line) longest_line = current_line;
        if (longest_line > 0 and line_count > 0) {
            markDirtyRect(options.x, options.y, longest_line * line_step, line_count * line_step);
        }

        var char_x: i32 = options.x;
        var char_y: i32 = options.y;
        for (options.str) |char| {
            if (char == '\n') {
                char_y += line_step;
                char_x = options.x;
                continue;
            }
            if (char < 32 or char > 255) {
                char_x += line_step;
                continue;
            }

            const glyph = font_data[char - 32];
            for (0..8) |row| {
                const row_bits = glyph[row];
                for (0..8) |col| {
                    const is_fg = (row_bits & (@as(u8, 1) << @as(u3, @intCast(7 - col)))) == 0;
                    const px = if (is_fg) text_pixel else bg_pixel;
                    if (px) |p| {
                        const base_dx = char_x + @as(i32, @intCast(col * scale_usize));
                        const base_dy = char_y + @as(i32, @intCast(row * scale_usize));
                        for (0..scale_usize) |sy| {
                            const dy: i32 = base_dy + @as(i32, @intCast(sy));
                            if (dy >= 0 and dy < screen_height) {
                                for (0..scale_usize) |sx| {
                                    const dx: i32 = base_dx + @as(i32, @intCast(sx));
                                    if (dx >= 0 and dx < screen_width) {
                                        framebuffer[@intCast(dx)][@intCast(dy)] = p;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            char_x += line_step;
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
        markDirtyRect(options.x, options.y, @intCast(end_x - options.x), 1);
        const start_x: usize = @intCast(@max(options.x, 0));
        const end_x_clamped: usize = @intCast(@min(end_x, screen_width));
        const y_idx: usize = @intCast(options.y);
        for (framebuffer[start_x..end_x_clamped]) |*col| {
            col[y_idx] = pixel;
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
        markDirtyRect(options.x, options.y, 1, @intCast(end_y - options.y));
        @memset(framebuffer[@intCast(options.x)][@max(options.y, 0)..@intCast(@min(end_y, screen_height))], pixel);
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Deprecated, Mostly unsupported on Badge v2. Use Tone2Options and tone2() instead.
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

/// Deprecated, Mostly unsupported on Badge v2. Use tone2() instead.
pub inline fn tone(options: ToneOptions) void {
    tone2(.{
        .frequency = @floatFromInt(options.frequency),
        .duration = @as(f32, @floatFromInt(options.duration)) * (1.0 / 60.0),
        .volume = @as(f32, @floatFromInt(options.duration)) * 0.01,
        .flags = .{
            .shape = switch (options.flags.channel) {
                .triangle => .triangle,
                else => .square,
            },
        },
    });
}

pub const Tone2Options = struct {
    // Use this value to stop playing audio
    pub const stop: Tone2Options = .{ .frequency = 0.0 };

    pub const Flags = packed struct(u32) {
        pub const Shape = enum(u3) {
            square,   // ---___---___, flute-ish
            triangle, // /\/\/\/\, string-ish
            sawtooth, // |\|\|\|\
            sine, // u^u^u^
            major, // Major chord with frequency as the fundamental
            minor, // Minor chord with frequency as the fundamental
        };

        /// Type of wave to play
        shape: Shape = .square,
        padding: u29 = undefined,
    };

    /// Frequency of the tone, in Hz. If set to 0.0, audio is stopped.
    frequency: f32,

    /// Duration in seconds. A duration of exactly -1.0 means infinite.
    duration: f32 = -1.0,

    /// Volume, 0-1, perceptually linear scale
    volume: f32 = 1.0,

    /// Wave shape and other parameters
    flags: Flags = .{},
};

/// Plays a sound tone via the hardware buzzer.
/// Cancels any other audio that might be playing.
/// On native: sends CART_TONE IPC to kernel; kernel plays via gpio.buzzer.
pub inline fn tone2(options: Tone2Options) void {
    if (is_wasm) {
        // TODO: Update wasm to handle new float values
        const adj_duration: u32 = if (options.duration == -1)
            std.math.maxInt(u32)
        else @intFromFloat(@round(options.duration * 60.0));
        struct {
            extern fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void;
        }.tone(
            @intFromFloat(@round(options.frequency)),
            adj_duration,
            @intFromFloat(@round(options.volume * 100.0)),
            0,
        );
    } else {
        const CART_TONE: u32 = 0x27000000;
        const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
        const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
        const FIFO_RDY: u32 = 1 << 1;


        ipc_data.tone_freq = options.frequency;
        ipc_data.tone_duration = options.duration;
        ipc_data.tone_volume = options.volume;
        ipc_data.tone_flags = @bitCast(options.flags);

        while (SIO_FIFO_ST.* & FIFO_RDY == 0) asm volatile ("nop");
        SIO_FIFO_WR.* = CART_TONE;
        asm volatile ("sev");
    }
}

/// Adjust the volume of all audio, 0.0 - 1.0. This is a perceptually
/// linear scale from about -50dB to 0dB adjustment from the maximum
/// speaker volume.
pub inline fn setGlobalVolume(volume: f32) void {
    if (is_wasm) {
        // TODO wasm volume
    } else {
        const CART_VOLUME: u32 = 0x29000000;
        const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
        const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
        const FIFO_RDY: u32 = 1 << 1;

        ipc_data.global_volume = volume;

        while (SIO_FIFO_ST.* & FIFO_RDY == 0) asm volatile ("nop");
        SIO_FIFO_WR.* = CART_VOLUME;
        asm volatile ("sev");
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
/// On native: copies string to shared buffer and sends CART_TRACE via FIFO;
/// kernel prints to UART. Used by Blobs and other carts for panic/debug output.
pub inline fn trace(x: []const u8) void {
    if (is_wasm) {
        struct {
            extern fn trace(str_ptr: [*]const u8, str_len: usize) void;
        }.trace(x.ptr, x.len);
    } else {
        const TRACE_BUF_SIZE: usize = 128;
        const CART_TRACE: u8 = 0x26;
        const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
        const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
        const FIFO_RDY: u32 = 1 << 1;

        const len: u24 = @intCast(@min(x.len, TRACE_BUF_SIZE - 1));
        const buf: [*]volatile u8 = &ipc_data.trace_buf;
        for (x[0..len], 0..) |c, i| buf[i] = c;
        buf[len] = 0;

        const msg: u32 = (@as(u32, CART_TRACE) << 24) | len;
        while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
            asm volatile ("nop");
        }
        SIO_FIFO_WR.* = msg;
        asm volatile ("sev");
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
    const FRAMEBUFFER_READY_V2: u8 = 0x28;
    const FRAMEBUFFER_DONE: u32 = 0x25000002;

    // Drain completion messages to release the in-flight slot.
    while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
        const reply = SIO_FIFO_RD.*;
        if (reply == FRAMEBUFFER_DONE) {
            has_in_flight_frame = false;
        }
    }

    if (has_in_flight_frame) {
        var spins: u32 = 0;
        while (has_in_flight_frame) {
            while (SIO_FIFO_ST.* & FIFO_VLD == 0) {
                asm volatile ("nop");
                spins +%= 1;
                if (spins >= present_wait_spin_limit) {
                    // Stop waiting rather than deadlocking Core 1 forever.
                    present_timeout_events +%= 1;
                    // Keep trace volume low: log only occasionally.
                    if ((present_timeout_events & 0x3f) == 0x01) {
                        trace("[PRESENT] timeout waiting FRAMEBUFFER_DONE");
                    }
                    return;
                }
            }
            const reply = SIO_FIFO_RD.*;
            if (reply == FRAMEBUFFER_DONE) {
                has_in_flight_frame = false;
            }
        }
    }

    // Publish the completed draw buffer.
    // payload bit0 = buffer index, bit1 = dirty-rect present.
    var payload: u32 = draw_buffer_index;
    if (dirty_any) {
        ipc_data.dirty_rect_x = dirty_min_x;
        ipc_data.dirty_rect_y = dirty_min_y;
        ipc_data.dirty_rect_w = dirty_max_x - dirty_min_x + 1;
        ipc_data.dirty_rect_h = dirty_max_y - dirty_min_y + 1;
        payload |= 0x2;
    } else if (computeDirtyRectLegacyFallback()) |r| {
        ipc_data.dirty_rect_x = r.x;
        ipc_data.dirty_rect_y = r.y;
        ipc_data.dirty_rect_w = r.w;
        ipc_data.dirty_rect_h = r.h;
        payload |= 0x2;
    }

    const ready_v2: u32 = (@as(u32, FRAMEBUFFER_READY_V2) << 24) | payload;
    var ready_spins: u32 = 0;
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
        asm volatile ("nop");
        ready_spins +%= 1;
        if (ready_spins >= present_wait_spin_limit) {
            present_timeout_events +%= 1;
            if ((present_timeout_events & 0x3f) == 0x01) {
                trace("[PRESENT] timeout waiting FIFO_RDY");
            }
            return;
        }
    }
    SIO_FIFO_WR.* = ready_v2;
    // SEV to wake Core 0 in case it's in WFE.
    asm volatile ("sev");

    has_in_flight_frame = true;
    // Switch draw buffer immediately so cart can render next frame while
    // Core 0 flushes the published one.
    draw_buffer_index = if (draw_buffer_index == 0) 1 else 0;
    updateDrawBufferPointer();
    resetDirtyRect();

    // Keep backward compatibility in case kernel only supports v1 ready.
    _ = FRAMEBUFFER_READY;
}

fn computeDirtyRectLegacyFallback() ?struct { x: u16, y: u16, w: u16, h: u16 } {
    const cur = if (draw_buffer_index == 0) framebuffer0 else framebuffer1;
    const prev = if (draw_buffer_index == 0) framebuffer1 else framebuffer0;

    var any = false;
    var min_x: u32 = screen_width;
    var min_y: u32 = screen_height;
    var max_x: u32 = 0;
    var max_y: u32 = 0;

    var x: u32 = 0;
    while (x < screen_width) : (x += 1) {
        var y: u32 = 0;
        while (y < screen_height) : (y += 1) {
            if (cur[x][y].bits != prev[x][y].bits) {
                any = true;
                if (x < min_x) min_x = x;
                if (y < min_y) min_y = y;
                if (x > max_x) max_x = x;
                if (y > max_y) max_y = y;
            }
        }
    }

    if (!any) return null;

    return .{
        .x = @intCast(min_x),
        .y = @intCast(min_y),
        .w = @intCast(max_x - min_x + 1),
        .h = @intCast(max_y - min_y + 1),
    };
}
