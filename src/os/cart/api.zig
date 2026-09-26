const std = @import("std");
const builtin = @import("builtin");

/// Whether the app is being built for the simulator or
/// for the device. Apps can switch on this to perform
/// non-standard debug checks. WARNING: Using this may
/// create behavior differences between the simulator
/// and the device.
pub const is_simulator = switch (builtin.os.tag) {
    .freestanding => false,
    else => true,
};

/// The raw platform implementation. WARNING: Using this
/// may create behavior differences between the simulator
/// and the device.
pub const platform = if (is_simulator)
    @import("platform_simulator.zig")
else
    @import("platform_cart_ram.zig");

/// Exports the code to interface with the platform on
/// startup. All carts must call this, either at comptime
/// or at runtime. On device, this exports the cart descriptor
/// table that will be used by the OS to load the app.
/// For the simulator, this exports functions to link against.
pub fn export_start_code() void {
    platform.export_start_code();
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Platform Constants and Types                                              │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const screen_width: u32 = 160;
pub const screen_height: u32 = 128;

pub const font_width: u32 = 8;
pub const font_height: u32 = 8;

/// RGB888, true color
pub const NeopixelColor = extern struct { g: u8, r: u8, b: u8 };

/// RGB565, high color
pub const DisplayColor = packed struct(u16) {
    /// 0-31
    r: u5,
    /// 0-63
    g: u6,
    /// 0-31
    b: u5,

    /// Convert from a 32-bit RGB value to a DisplayColor.
    /// The value should be 0x00RRGGBB. For example,
    /// .rgb(0x7F00FF) is purple.
    pub fn rgb(value: u32) DisplayColor {
        return .{
            .r = @truncate(value >> 19),
            .g = @truncate(value >> 10),
            .b = @truncate(value >> 3),
        };
    }
};

pub const framebuffer_alignment = 0x2000;
pub const Framebuffer = [screen_width][screen_height]DisplayColor;
pub const FramebufferPtr = *align(framebuffer_alignment) Framebuffer;

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
    _pad: u7 = 0,
};

// An absolute AABB Rect 2D clipped to the screen
pub const Rect8 = extern struct {
    min_x: u8, // inclusive
    min_y: u8, // inclusive
    max_x: u8, // exclusive
    max_y: u8, // exclusive

    pub const all: Rect8 = .{
        .min_x = 0,
        .min_y = 0,
        .max_x = screen_width,
        .max_y = screen_height,
    };

    pub const none: Rect8 = .{
        .min_x = screen_width,
        .min_y = screen_height,
        .max_x = 0,
        .max_y = 0,
    };

    pub fn clip_absolute(comptime Int: type, abs: [4]Int) Rect8 {
        return .{
            .min_x = @intCast(@max(0, @min(screen_width, abs[0]))),
            .min_y = @intCast(@max(0, @min(screen_height, abs[1]))),
            .max_x = @intCast(@max(0, @min(screen_width, abs[2]))),
            .max_y = @intCast(@max(0, @min(screen_height, abs[3]))),
        };
    }

    pub fn clip_relative(comptime Int: type, rel: [4]Int) Rect8 {
        return .clip_absolute(Int, .{ rel[0], rel[1], rel[0] +| rel[2], rel[1] +| rel[3] });
    }

    pub fn contain(a: Rect8, b: Rect8) Rect8 {
        return .{
            .min_x = @min(a.min_x, b.min_x),
            .min_y = @min(a.min_y, b.min_y),
            .max_x = @max(a.max_x, b.max_x),
            .max_y = @max(a.max_y, b.max_y),
        };
    }

    pub fn has_area(r: Rect8) bool {
        return r.max_x > r.min_x and r.max_y > r.min_y;
    }

    pub fn transposed(r: Rect8) Rect8 {
        return .{
            .min_x = r.min_y,
            .min_y = r.min_x,
            .max_x = r.max_y,
            .max_y = r.max_x,
        };
    }
};

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Inputs and Outputs                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn micros_since_boot() u64 {
    return platform.micros_since_boot();
}

/// Volatile: kernel (Core 0) writes button state every frame; cart must read fresh each access.
pub const neopixels: *volatile [5]NeopixelColor = platform.neopixels;
pub const user_led: *volatile bool = platform.user_led;

pub const controls: *const volatile Controls = platform.controls;
pub const light_level: *const volatile u12 = platform.light_level;
pub const battery_level: *const volatile u12 = platform.battery_level;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Frame Management                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn set_vsync_disabled() void {
    if (!is_simulator) platform.set_vsync_disabled();
}

pub fn set_vsync_enabled(target_frame_ms: f32) void {
    if (!is_simulator) platform.set_vsync_enabled(target_frame_ms);
}

pub fn set_vsync_dynamic() void {
    if (!is_simulator) platform.set_vsync_dynamic();
}

pub const DoubleBufferMode = union(enum) {
    /// In "copy forward" mode, changes made to the backbuffer
    /// are automatically copied to the new backbuffer on present.
    /// This allows apps to perform incremental updates to their
    /// frame. The copy itself costs 0.07-0.12 mS depending on
    /// hardware contention. The cart API tracks a dirty rect
    /// to perform incremental updates on screen.
    copy_forward: void,

    /// In "no copy dirty rect" mode, changes made to the backbuffer
    /// are not copied forward, but a dirty rect is tracked. In this
    /// mode, the app must perform incremental updates against the
    /// frame *two frames before*. This is because the
    no_copy_dirty_rect: void,

    /// In "no copy full frame" mode, changes made to the backbuffer
    /// are not copied forward, and the entire LCD screen is updated
    /// every frame. This is the fastest option if your app will overwrite
    /// the entire framebuffer every frame.
    no_copy_full_frame: void,

    /// In "clear full frame" mode, the backbuffer is cleared before
    /// every frame. This clear happens inside the OS while data is
    /// being copied to the screen, and has no performance cost
    /// for the app.
    /// TODO This is not implemented yet, for now it's a slow clear
    /// on the app core.
    clear_full_frame: DisplayColor,
};

var has_set_double_buffer_mode: bool = false;
var double_buffer_mode: DoubleBufferMode = .copy_forward;

/// Change the double buffering mode. See DoubleBufferMode for
/// options. The default is .copy_forward.
/// The new mode will be applied for the next frame.
/// N.B. If switching from clear_full_frame mode to copy_forward mode,
/// both the clear and the copy will happen, in that order.
pub fn set_double_buffer_mode(mode: DoubleBufferMode) void {
    double_buffer_mode = mode;
    has_set_double_buffer_mode = true;
}

pub var framebuffer: FramebufferPtr = platform.framebuffers[0];
pub var frontbuffer: FramebufferPtr = platform.framebuffers[1];
var draw_buffer_index: u1 = 0;
var dirty_rect: Rect8 = .all;

pub fn framebufferIndex() u1 {
    return draw_buffer_index;
}

pub fn mark_dirty_rect(x: i32, y: i32, w: i32, h: i32) void {
    dirty_rect = .contain(dirty_rect, .clip_relative(i32, .{ x, y, w, h }));
}

/// Signal Core 0 that the framebuffer is ready and wait for the
/// LCD flush of the previous frame to complete before returning.
/// May also perform copies based on double_buffer_mode.
///
/// Call this to immediately flush framebuffer changes to the LCD.
/// Automatically called after each call to update().
pub fn present() void {
    // Some carts don't properly set up the dirty rect.
    // If a cart never calls set_double_buffer_mode, we
    // assume it is unaware of the dirty rect, and
    // compute it internally instead.
    if (!has_set_double_buffer_mode and !dirty_rect.has_area()) {
        dirty_rect = compute_dirty_rect_legacy_fallback();
    }

    const clear_color = if (double_buffer_mode == .clear_full_frame) double_buffer_mode.clear_full_frame else null;
    platform.present_and_acquire(draw_buffer_index, dirty_rect, clear_color);

    switch (double_buffer_mode) {
        .clear_full_frame => |color| {
            // OS clears frame, just mark full frame as dirty
            dirty_rect = .all;
            // TODO If we do this in the OS, we can do it while the frame is being copied to
            // the lcd, saving lots of time! For now though, just SIMD it.
            const color_16: u16 = @bitCast(color);
            const color_32: u32 = @as(u32, color_16) << 16 | color_16;
            @memset(@as(*[screen_width * screen_height / 2]u32, @ptrCast(frontbuffer)), color_32);
        },
        .no_copy_dirty_rect => {
            dirty_rect = .none;
        },
        .no_copy_full_frame => {
            dirty_rect = .all;
        },
        .copy_forward => {
            dirty_rect = .none;
            // Do the copy
            // TODO DMA would be twice as fast
            const front_32 = @as(*[screen_width * screen_height / 2]u32, @ptrCast(frontbuffer));
            const back_32 = @as(*[screen_width * screen_height / 2]u32, @ptrCast(framebuffer));
            @memcpy(front_32, back_32);
        },
    }

    // Switch draw buffer immediately so cart can render next frame while
    // Core 0 flushes the published one.
    draw_buffer_index = 1 - draw_buffer_index;
    framebuffer = platform.framebuffers[draw_buffer_index];
    frontbuffer = platform.framebuffers[1 - draw_buffer_index];
}

fn compute_dirty_rect_legacy_fallback() Rect8 {
    const cur_raw = framebuffer;
    const prev_raw = frontbuffer;

    const simd_len = @divExact(@sizeOf(u32), @sizeOf(DisplayColor));
    const height_simd = @divExact(screen_height, simd_len);
    const cur: *[screen_width][height_simd]u32 = @ptrCast(cur_raw);
    const prev: *[screen_width][height_simd]u32 = @ptrCast(prev_raw);

    var dirty: Rect8 = .none;

    var x: u8 = 0;
    while (x < screen_width) : (x += 1) {
        var y: u8 = 0;
        while (y < height_simd) : (y += 1) {
            if (cur[x][y] != prev[x][y]) {
                if (x < dirty.min_x) dirty.min_x = x;
                if (y < dirty.min_y) dirty.min_y = y;
                dirty.max_x = x + 1; // This is always greater, as x only increases
                if (y + 1 > dirty.max_y) dirty.max_y = y + 1;
            }
        }
    }

    if (dirty.has_area()) {
        dirty.min_y = dirty.min_y * simd_len;
        dirty.max_y = dirty.max_y * simd_len;
    }

    return dirty;
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

fn clip_pixel(x: i32, y: i32, pixel: DisplayColor) void {
    if (x < 0 or x >= screen_width) return;
    if (y < 0 or y >= screen_height) return;
    framebuffer[@intCast(x)][@intCast(y)] = pixel;
}

/// Copies pixels to the framebuffer.
pub fn blit(options: BlitOptions) void {
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

    mark_dirty_rect(options.x, options.y, if (flags.rotate) signed_height else signed_width, if (flags.rotate) signed_width else signed_height);

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

            // Use clip_pixel so any out-of-bounds tx/ty are safely
            // discarded instead of causing a hard fault when indexing the framebuffer.
            if (tx < screen_width and ty < screen_height) {
                framebuffer[tx][ty] = options.sprite[sy * stride + sx];
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
pub fn line(options: LineOptions) void {
    // Bresenham's line algorithm
    var x0 = options.x1;
    var y0 = options.y1;
    const x1 = options.x2;
    const y1 = options.y2;
    const pixel = options.color;

    const dx: i32 = @intCast(@abs(x1 - x0));
    const sx: i32 = if (x0 < x1) 1 else -1;
    const dy = -@as(i32, @intCast(@abs(y1 - y0)));
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx + dy;

    mark_dirty_rect(@min(options.x1, options.x2), @min(options.y1, options.y2), @abs(options.x2 - options.x1) + 1, @abs(options.y2 - options.y1) + 1);

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

pub const OvalOptions = struct {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    stroke_color: ?DisplayColor = null,
    fill_color: ?DisplayColor = null,
};

/// Draws an oval (or circle).
pub fn oval(options: OvalOptions) void {
    // Fast path: small fill-only ovals use direct memset instead of ellipse algorithm
    // This is crucial for performance when rendering many small circles (e.g., pellets).
    // Threshold: width/height <= 8 pixels and fill-only (no stroke).
    if (options.width <= 8 and options.height <= 8 and options.stroke_color == null and options.fill_color != null) {
        const x = options.x;
        const y = options.y;
        const w = @as(i32, @intCast(options.width));
        const h = @as(i32, @intCast(options.height));

        const min_x: usize = @intCast(@max(x, 0));
        const min_y: usize = @intCast(@max(y, 0));
        const max_x: usize = @intCast(@min(x + w, @as(i32, @intCast(screen_width))));
        const max_y: usize = @intCast(@min(y + h, @as(i32, @intCast(screen_height))));

        if (min_x >= max_x or min_y >= max_y) return;

        const fill_pixel = options.fill_color.?;
        for (framebuffer[min_x..max_x]) |*col| {
            @memset(col[min_y..max_y], fill_pixel);
        }
        mark_dirty_rect(x, y, w, h);
        return;
    }

    const signed_width: i32 = @intCast(options.width);
    const signed_height: i32 = @intCast(options.height);

    mark_dirty_rect(options.x, options.y, signed_width, signed_height);

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

    const stroke_pixel = options.stroke_color;

    while (true) {
        if (stroke_pixel) |sp| {
            clip_pixel(east, north, sp);
            clip_pixel(west, north, sp);
            clip_pixel(west, south, sp);
            clip_pixel(east, south, sp);
        }

        const oval_start = west + 1;
        const len = east - oval_start;
        if (options.fill_color != null and len > 0) {
            hline(.{ .x = oval_start, .y = north, .len = @intCast(len), .color = options.fill_color.? });
            hline(.{ .x = oval_start, .y = south, .len = @intCast(len), .color = options.fill_color.? });
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
            clip_pixel(west - 1, north, sp);
            clip_pixel(east + 1, north, sp);
            north += 1;
            clip_pixel(west - 1, south, sp);
            clip_pixel(east + 1, south, sp);
            south -= 1;
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
pub fn rect(options: RectOptions) void {
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

    mark_dirty_rect(options.x, options.y, @intCast(end_x - options.x), @intCast(end_y - options.y));

    if (stroke_color) |sc| {
        const stroke_pixel = sc;
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
            const fill_pixel = fc;
            if (max_x > min_x + 2 and max_y > min_y + 2) {
                for (framebuffer[min_x + 1 .. max_x - 1]) |*col| {
                    @memset(col[min_y + 1 .. max_y - 1], fill_pixel);
                }
            }
        }
    } else if (fill_color) |fc| {
        const fill_pixel = fc;
        for (framebuffer[min_x..max_x]) |*col| @memset(col[min_y..max_y], fill_pixel);
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
pub fn text(options: TextOptions) void {
    // Font bitmap: [char - ' '][row] where each byte is 8 pixels, 0-bit = foreground.
    // Accessed here (not at file scope) so that @import("board") is only resolved
    // for native builds — WASM builds take the branch above and never reach this.
    const font_data = @import("board").font.font;
    const text_pixel = options.text_color;
    const bg_pixel = options.background_color;
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
        mark_dirty_rect(options.x, options.y, longest_line * line_step, line_count * line_step);
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

pub const StraightLineOptions = struct {
    x: i32,
    y: i32,
    len: u32,
    color: DisplayColor,
};

/// Draws a horizontal line
pub fn hline(options: StraightLineOptions) void {
    if (options.len == 0 or options.y < 0 or options.y >= screen_height or options.x >= screen_width) return;
    const end_x = options.x +| @min(options.len, std.math.maxInt(i32));
    if (end_x <= 0) return;
    const pixel = options.color;
    mark_dirty_rect(options.x, options.y, @intCast(end_x - options.x), 1);
    const start_x: usize = @intCast(@max(options.x, 0));
    const end_x_clamped: usize = @intCast(@min(end_x, screen_width));
    const y_idx: usize = @intCast(options.y);
    for (framebuffer[start_x..end_x_clamped]) |*col| {
        col[y_idx] = pixel;
    }
}

/// Draws a vertical line
pub fn vline(options: StraightLineOptions) void {
    if (options.len == 0 or options.x < 0 or options.x >= screen_width or options.y >= screen_height) return;
    const end_y = options.y +| @min(options.len, std.math.maxInt(i32));
    if (end_y <= 0) return;
    const pixel = options.color;
    mark_dirty_rect(options.x, options.y, 1, @intCast(end_y - options.y));
    @memset(framebuffer[@intCast(options.x)][@max(options.y, 0)..@intCast(@min(end_y, screen_height))], pixel);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// mixer provides a simple audio mixer with two square wave channels, one triangle
/// wave channel, and one noise channel. See blobs or space_shooter for examples.
pub const mixer = @import("mixer.zig");

pub const audio_sample_rate = 44100;

/// Adjust the volume of all audio, 0.0 - 1.0. This is a perceptually
/// linear scale from about -50dB to 0dB adjustment from the maximum
/// speaker volume. This value can also be changed by the player from the
/// OS menu.
pub fn set_global_volume(volume: f32) void {
    platform.set_global_volume(volume);
}

/// Set a buffer to use for streaming audio. This buffer will be managed
/// as a ring buffer for communication between the app and the OS.
/// Use audio_get_buffer to get slices to fill with samples.
/// For now only u8 samples are supported.
///
/// See mixer.zig for example usage.
pub fn audio_set_buffer(comptime T: type, buffer: []align(8) T) void {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }
    platform.audio_set_buffer(T, buffer);
}

/// Get a buffer to fill with samples. This can only be used after
/// audio_set_buffer has been called to initialize audio.
/// Returns the next buffer of samples to be filled. After filling
/// the samples, the user should call audio_submit_samples() with
/// the number of valid samples. If this returns null, the audio
/// buffer is full and the app must wait for the OS to catch up.
///
/// Because the underlying buffer is a ring, this function may
/// not return the entire empty area. If you fill this buffer
/// and would like to submit more samples, call audio_submit_samples
/// to mark the buffer as full, and then audio_get_buffer again
/// to see if there is more space to fill. See mixer.zig for an example.
///
/// Note that this function *does not* mark the returned buffer as
/// filled. You must call audio_submit_samples() after writing
/// samples. Calling this function twice without calling
/// audio_submit_samples will return the same buffer twice.
pub fn audio_get_buffer(comptime T: type) ?[]T {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }
    return platform.audio_get_buffer(T);
}

/// Used with audio_get_buffer to submit samples to the OS.
/// Call audio_get_buffer to get a buffer, and then audio_submit_samples
/// after filling it in. You don't need to fill the entire buffer.
/// If you only want to buffer a limited amount of audio,
pub fn audio_submit_samples(num_samples: usize) void {
    platform.audio_submit_samples(num_samples);
}

/// Get the number of samples which have been submitted but have
/// not yet been consumed by the OS.
/// This is an approximate measure of the latency between newly
/// submitted samples and the speaker.
/// Note that samples are consumed in large batches, so this
/// function will not smoothly count down and should
/// not be used as a timer.
pub fn audio_get_queued_samples() u32 {
    return platform.audio_get_queued_samples();
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
    if (is_simulator) {
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
    if (is_simulator) {
        struct {
            extern fn write_flash_page(page: u32, src: [*]const u8) void;
        }.write_flash_page(page, &src);
    } else {
        // no-op stub: no cart save-data flash region yet
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Profiling Functions                                                       │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const Zone = struct {
    pub const inactive: Zone = .{ .active = false };

    active: bool,

    pub inline fn end(z: Zone) void {
        if (is_simulator or !z.active) return;

        platform.outline_zone_end(platform.cycles(), true);
    }
};

pub inline fn fn_zone(comptime loc: std.builtin.SourceLocation) Zone {
    return zone_color_cond(null, loc, 0, true);
}
pub inline fn fn_zone_color(comptime loc: std.builtin.SourceLocation, comptime color: u32) Zone {
    return zone_color_cond(null, loc, color, true);
}
pub inline fn zone(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation) Zone {
    return zone_color_cond(name, loc, 0, true);
}
pub inline fn zone_color(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, comptime color: u32) Zone {
    return zone_color_cond(name, loc, color, true);
}
pub inline fn fn_zone_cond(comptime loc: std.builtin.SourceLocation, active: bool) Zone {
    return zone_color_cond(null, loc, 0, active);
}
pub inline fn fn_zone_color_cond(comptime loc: std.builtin.SourceLocation, comptime color: u33, active: bool) Zone {
    return zone_color_cond(null, loc, color, active);
}
pub inline fn zone_cond(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, active: bool) Zone {
    return zone_color_cond(name, loc, 0, active);
}
pub inline fn zone_color_cond(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, comptime color: u32, active: bool) Zone {
    // TODO on-demand check connection ID
    if (is_simulator or !active) return .inactive;

    const src_loc = platform.external_source_location(name, loc, color);
    return .{ .active = platform.outline_zone_begin_static(platform.cycles(), true, src_loc) };
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Returns a random number from the RP2350 ring oscillator random bit.
/// Useful for seeding a faster PRNG.
pub fn rand() u32 {
    return platform.rand();
}

/// Prints a message to the debug console.
/// On native: copies string to shared buffer and sends CART_TRACE via FIFO;
/// kernel prints to UART. Used by Blobs and other carts for panic/debug output.
pub fn trace(x: []const u8) void {
    platform.trace(x);
}
