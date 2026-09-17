const std = @import("std");
const builtin = @import("builtin");
const q = @import("tracy_protocol");

const is_wasm = switch (builtin.target.cpu.arch) {
    .wasm32, .wasm64 => true,
    else => false,
};

const platform = if (is_wasm)
    @import("platform_wasm.zig")
else
    @import("platform_cart_ram.zig");

pub fn export_start_code() void {
    platform.export_start_code();
}

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

pub fn micros_since_boot() u64 {
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

/// A 64 bit offset to align core 1 times with core 0 times. This is set before
/// cart startup by the OS.
var cycles_offset: i64 = 0;
var last_cycles: u32 = 0;
/// Cycle count for profiling. This must be called at least once every 30
/// seconds to maintain accuracy. The OS will call it before every update() to
/// maintain this, but if update() ever takes more than 30 seconds there may be
/// mistakes.
pub fn cycles() linksection(".ramfunc") i64 {
    if (is_wasm) {
        return @bitCast(micros_since_boot());
    } else {
        const DWT_CYCCNT: *volatile u32 = @ptrFromInt(0xe0001004);
        const cycles_low = DWT_CYCCNT.*;
        if (cycles_low < last_cycles) {
            @branchHint(.unlikely);
            cycles_offset += (1 << 32);
        }
        last_cycles = cycles_low;
        return cycles_offset + cycles_low;
    }
}

/// Aligns core 0 and core 1 cycle counts for profiling. If you have an
/// extremely long update (30+ seconds), or you put core 1 to sleep, you can
/// call this to resynchronize and restore correct timing in tracy. This
/// function must wait until the OS is ready to synchronize timing, which could
/// take several milliseconds in the worst case.
pub fn os_align_cycles() void {
    if (!is_wasm) {
        // RP2350 SIO FIFO registers (same address on both cores, core-local view)
        const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
        const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
        const SIO_FIFO_RD: *volatile u32 = @ptrFromInt(0xD0000058);

        const FIFO_RDY: u32 = 1 << 1; // write-FIFO ready (space available)
        const FIFO_VLD: u32 = 1 << 0; // read-FIFO valid (data available)

        // Message constants — must match mailbox.MessageType values in the OS.
        const SYNC_TIME_REQ_CLR: u32 = 0x2a000001;
        const SYNC_TIME_ACK_CLR: u32 = 0x2a000002;
        const SYNC_TIME_REQ_TIME: u32 = 0x2a000003;

        // Clear OS FIFO
        while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
            _ = SIO_FIFO_RD.*;
        }

        // Tell OS to clear its fifo
        while (SIO_FIFO_ST.* & FIFO_RDY == 0) {}
        SIO_FIFO_WR.* = SYNC_TIME_REQ_CLR;

        // Wait for OS to acknowledge clearing its fifo
        while (true) {
            while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
            if (SIO_FIFO_RD.* == SYNC_TIME_ACK_CLR) break;
        }

        // Send time request for immediate processing
        while (SIO_FIFO_ST.* & FIFO_RDY == 0) {}
        SIO_FIFO_WR.* = SYNC_TIME_REQ_TIME;

        // Read cycle count at approx same time as other core
        const DWT_CYCCNT: *volatile u32 = @ptrFromInt(0xe0001004);
        const cycles_low = DWT_CYCCNT.*;

        while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
        const time_high = SIO_FIFO_RD.*;

        while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
        const time_low = SIO_FIFO_RD.*;

        const target_time: i64 = @bitCast(@as(u64, time_high) << 32 | time_low);
        cycles_offset = target_time - cycles_low;
        last_cycles = cycles_low;
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Memory Addresses                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

var vsync_updated: bool = false;

pub fn set_vsync_disabled() void {
    ipc_data.vsync_flags = 0;
    vsync_updated = true;
}

pub fn set_vsync_enabled(target_frame_ms: f32) void {
    ipc_data.vsync_frame_ms = target_frame_ms;
    ipc_data.vsync_flags = 1;
    vsync_updated = true;
}

pub fn set_vsync_dynamic() void {
    set_vsync_enabled(0);
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

    pub const Optional = enum(i32) {
        none = -1,
        _,

        pub fn from(color: ?DisplayColor) Optional {
            return if (color) |c| @fromBackingInt(@intCast(@as(u16, @bitCast(c)))) else .none;
        }

        pub fn unwrap(opt: Optional) ?DisplayColor {
            return if (opt == .none) null else @bitCast(@as(u16, @truncate(@as(u32, @intCast(@backingInt(opt))))));
        }
    };
};

pub const Pixel = packed struct(u16) {
    bits: u16,

    pub fn from_color(color: DisplayColor) Pixel {
        if (is_wasm) {
            // WASM/simulator: standard RGB565 big-endian (matches old behavior)
            return .{ .bits = @byteSwap(@as(u16, @bitCast(color))) };
        } else {
            return @bitCast(color);
        }
    }

    pub fn to_color(pixel: Pixel) DisplayColor {
        if (is_wasm) {
            return @bitCast(@byteSwap(pixel.bits));
        } else {
            return @bitCast(pixel);
        }
    }

    pub fn set_color(pixel: *Pixel, color: DisplayColor) void {
        pixel.* = from_color(color);
    }
};

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

// Cart IPC block lives at the start of process_ram (0x20020000).
// The OS kernel (Core 0) writes sensor/button data here each frame, and reads
// the framebuffer back to DMA it to the LCD. The cart (Core 1) reads inputs
// and writes pixels. Using process_ram avoids colliding with kernel_ram
// (0x20000000) where the OS keeps its own data structures.
const base = 0x20020000;
// zig fmt: off
pub const CartIPCData = extern struct {
    framebuffers: [2][screen_width][screen_height]Pixel, // x0..xA000, xA000..x14000
    tracy_ring: [tracy_buffer_size]u8, // x14000..x15000
    trace_buf: [0x80]u8,               // x15000..x15080
    neopixels: [5]NeopixelColor,       // x15080..x1508F
    _pad1: u8 = 0,                     // x1508F..x15090

    controls: Controls,                // x15090..x15092
    light_level: u16,                  // x15092..x15094

    user_led: bool,                    // x15094..x15095
    _pad2: u8 = 0,                     // x15095..x15096
    battery_level: u16,                // x15096..x15098

    dirty_rect: Rect8,                 // x15098..x1509C

    tone_freq: f32,                    // x1509C..x150A0
    tone_duration: f32,                // x150A0..x150A4
    tone_volume: f32,                  // x150A4..x150A8
    tone_flags: u32,                   // x150A8..x150AC
    global_volume: f32,                // x150AC..x150B0

    tracy_read_pos: u32,               // x150B0..x150B4, align(16)
    _pad3: [3]u32 = @splat(0),         // x150B4..x150C0, tracy_read_pos gets its own granule
    tracy_write_ctrl: u32,             // x150C0..x150C4, align(16)
    _pad4: [3]u32 = @splat(0),         // x150C4..x150D0, tracy_write_ctrl gets its own granule
    tracy_spinlock: u32,               // x150D0..x150D4, align(16)
    _pad5: [3]u32 = @splat(0),         // x150D4..x150E0, tracy_spinlock gets its own granule

    vsync_flags: u32,                  // x150E0..x150E4
    vsync_frame_ms: f32,               // x150E4..x150E8
    clear_color: Pixel,                // x150E8..x150EA
    _pad6: u16 = 0,                    // x150EA..x150EC

    comptime {
        // cart_xip.ld reserves 0x15100 bytes for IPC data.
        // If it grows more than that, the linker script needs to be updated.
        std.debug.assert(@sizeOf(CartIPCData) <= 0x15100);
    }
};
// zig fmt: on

var wasm_ipc_data: CartIPCData align(0x2000) = .{
    .framebuffers = @splat(@splat(@splat(@bitCast(@as(u16, 0))))),
    .tracy_ring = undefined,
    .trace_buf = @splat(0),
    .neopixels = @splat(.{ .r = 0, .g = 0, .b = 0 }),
    .controls = @bitCast(@as(u16, 0)),
    .light_level = 0,
    .user_led = false,
    .battery_level = 100,
    .dirty_rect = undefined,
    .tone_freq = undefined,
    .tone_duration = undefined,
    .tone_volume = undefined,
    .tone_flags = undefined,
    .global_volume = undefined,
    .tracy_read_pos = 0,
    .tracy_write_ctrl = 0,
    .tracy_spinlock = 0,
    .vsync_flags = 0,
    .vsync_frame_ms = 0,
    .clear_color = @bitCast(@as(u16, 0)),
};
const ipc_data: *align(0x2000) volatile CartIPCData = if (is_wasm) &wasm_ipc_data else @ptrFromInt(base);

/// Volatile: kernel (Core 0) writes button state every frame; cart must read fresh each access.
pub const controls: *const volatile Controls = &ipc_data.controls;
pub const light_level: *volatile u12 = @ptrCast(&ipc_data.light_level);
pub const neopixels: *volatile [5]NeopixelColor = &ipc_data.neopixels;
pub const user_led: *volatile bool = &ipc_data.user_led;
pub const battery_level: *volatile u12 = @ptrCast(&ipc_data.battery_level);
const framebuffer0: *align(0x2000) [screen_width][screen_height]Pixel = @volatileCast(&ipc_data.framebuffers[0]);
const framebuffer1: *align(0x2000) [screen_width][screen_height]Pixel = @volatileCast(&ipc_data.framebuffers[1]);
pub var framebuffer: *align(0x2000) [screen_width][screen_height]Pixel = framebuffer0;
pub var frontbuffer: *align(0x2000) [screen_width][screen_height]Pixel = framebuffer1;
const tracy_ring: [*]u8 = @volatileCast(&ipc_data.tracy_ring);
const tracy_atomic_write_ctrl: *u32 = @volatileCast(&ipc_data.tracy_write_ctrl);
const tracy_atomic_read_pos: *u32 = @volatileCast(&ipc_data.tracy_read_pos);
const tracy_spinlock: *u32 = @volatileCast(&ipc_data.tracy_spinlock);
var tracy_ref_time: i64 = 0;
var draw_buffer_index: u1 = 0;
var has_in_flight_frame: bool = false;
var present_timeout_events: u32 = 0;

const present_wait_time_limit: u32 = 500_000; // 0.5 seconds

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

var prev_dirty_rect: Rect8 = .none;
var dirty_rect: Rect8 = .all;

fn update_draw_buffer_pointer() void {
    framebuffer, frontbuffer = if (draw_buffer_index == 0) .{ framebuffer0, framebuffer1 } else .{ framebuffer1, framebuffer0 };
}

pub fn mark_dirty_rect(x: i32, y: i32, w: i32, h: i32) void {
    dirty_rect = .contain(dirty_rect, .clip_relative(i32, .{ x, y, w, h }));
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

fn clip_pixel(x: i32, y: i32, pixel: Pixel) void {
    if (x < 0 or x >= screen_width) return;
    if (y < 0 or y >= screen_height) return;
    framebuffer[@intCast(x)][@intCast(y)] = pixel;
}

/// Copies pixels to the framebuffer.
pub fn blit(options: BlitOptions) void {
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

                // Use clip_pixel and Pixel.from_color so any out-of-bounds tx/ty are safely
                // discarded instead of causing a hard fault when indexing the framebuffer.
                if (tx < screen_width and ty < screen_height) {
                    framebuffer[tx][ty] = Pixel.from_color(options.sprite[sy * stride + sx]);
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
pub fn line(options: LineOptions) void {
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
        const pixel = Pixel.from_color(options.color);

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

            const fill_pixel = Pixel.from_color(fill_color.unwrap().?);
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

        const stroke_pixel = if (stroke_color.unwrap()) |sc| Pixel.from_color(sc) else null;

        while (true) {
            if (stroke_pixel) |sp| {
                clip_pixel(east, north, sp);
                clip_pixel(west, north, sp);
                clip_pixel(west, south, sp);
                clip_pixel(east, south, sp);
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
                clip_pixel(west - 1, north, sp);
                clip_pixel(east + 1, north, sp);
                north += 1;
                clip_pixel(west - 1, south, sp);
                clip_pixel(east + 1, south, sp);
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
pub fn rect(options: RectOptions) linksection(".ramfunc") void {
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

        mark_dirty_rect(options.x, options.y, @intCast(end_x - options.x), @intCast(end_y - options.y));

        if (stroke_color) |sc| {
            const stroke_pixel = Pixel.from_color(sc);
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
                const fill_pixel = Pixel.from_color(fc);
                if (max_x > min_x + 2 and max_y > min_y + 2) {
                    for (framebuffer[min_x + 1 .. max_x - 1]) |*col| {
                        @memset(col[min_y + 1 .. max_y - 1], fill_pixel);
                    }
                }
            }
        } else if (fill_color) |fc| {
            const fill_pixel = Pixel.from_color(fc);
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
pub fn text(options: TextOptions) void {
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
        const text_pixel: ?Pixel = if (options.text_color) |c| Pixel.from_color(c) else null;
        const bg_pixel: ?Pixel = if (options.background_color) |c| Pixel.from_color(c) else null;
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
}

pub const StraightLineOptions = struct {
    x: i32,
    y: i32,
    len: u32,
    color: DisplayColor,
};

/// Draws a horizontal line
pub fn hline(options: StraightLineOptions) void {
    if (is_wasm) {
        struct {
            extern fn hline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        }.hline(options.color, options.x, options.y, options.len);
    } else {
        if (options.len == 0 or options.y < 0 or options.y >= screen_height or options.x >= screen_width) return;
        const end_x = options.x +| @min(options.len, std.math.maxInt(i32));
        if (end_x <= 0) return;
        const pixel = Pixel.from_color(options.color);
        mark_dirty_rect(options.x, options.y, @intCast(end_x - options.x), 1);
        const start_x: usize = @intCast(@max(options.x, 0));
        const end_x_clamped: usize = @intCast(@min(end_x, screen_width));
        const y_idx: usize = @intCast(options.y);
        for (framebuffer[start_x..end_x_clamped]) |*col| {
            col[y_idx] = pixel;
        }
    }
}

/// Draws a vertical line
pub fn vline(options: StraightLineOptions) void {
    if (is_wasm) {
        struct {
            extern fn vline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        }.vline(options.color, options.x, options.y, options.len);
    } else {
        if (options.len == 0 or options.x < 0 or options.x >= screen_width or options.y >= screen_height) return;
        const end_y = options.y +| @min(options.len, std.math.maxInt(i32));
        if (end_y <= 0) return;
        const pixel = Pixel.from_color(options.color);
        mark_dirty_rect(options.x, options.y, 1, @intCast(end_y - options.y));
        @memset(framebuffer[@intCast(options.x)][@max(options.y, 0)..@intCast(@min(end_y, screen_height))], pixel);
    }
}

pub fn framebufferIndex() u1 {
    return draw_buffer_index;
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

    pub const Shape = enum(u3) {
        square, // ---___---___, clarinet-ish
        triangle, // /\/\/\/\, flute-ish
        sawtooth, // |\|\|\|\, violin-ish
        sine, // u^u^u^
        major, // Major chord with frequency as the fundamental
        minor, // Minor chord with frequency as the fundamental
    };

    pub const Flags = packed struct(u32) {
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
pub fn tone2(options: Tone2Options) void {
    if (is_wasm) {
        // TODO: Update wasm to handle new float values
        const adj_duration: u32 = if (options.duration == -1)
            std.math.maxInt(u32)
        else
            @intFromFloat(@round(options.duration * 60.0));
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
pub fn set_global_volume(volume: f32) void {
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
// │ Profiling Functions                                                       │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const tracy_buffer_size = 4096;

pub const Zone = struct {
    pub const inactive: Zone = .{ .active = false };

    active: bool,

    pub inline fn end(z: Zone) void {
        if (is_wasm or !z.active) return;

        outline_zone_end(cycles(), true);
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
    if (is_wasm or !active) return .inactive;

    const src_loc = external_source_location(name, loc, color);
    return .{ .active = outline_zone_begin_static(cycles(), true, src_loc) };
}

const external_linksection = ".rodata";

fn StringWrap(comptime str: [:0]const u8) type {
    return struct {
        const bytes linksection(external_linksection) = str[0..str.len :0].*;
    };
}

inline fn external_string(comptime str: [:0]const u8) [*:0]const u8 {
    return &StringWrap(str).bytes;
}

fn SourceLocationWrap(name: ?[:0]const u8, zig_src_loc: std.builtin.SourceLocation, color: u32) type {
    return struct {
        pub const src_loc: q.SourceLocationData linksection(external_linksection) = .{
            .name = if (name) |n| external_string(n) else null,
            .function = external_string(zig_src_loc.fn_name),
            .file = external_string(zig_src_loc.file),
            .line = zig_src_loc.line,
            .color = color,
        };
    };
}

inline fn external_source_location(comptime name: ?[:0]const u8, comptime zig_src_loc: std.builtin.SourceLocation, comptime color: u32) *const q.SourceLocationData {
    return &SourceLocationWrap(name, zig_src_loc, color).src_loc;
}

pub const TracyAtomicWriteCtrl = packed struct(u32) {
    write_pos: u16,
    _pad: u12 = 0,
    server_connected: bool,
    cart_buffer_active: bool,
    rtt_buffer_active: bool,
    has_thread_ctx: bool,

    pub const zero: TracyAtomicWriteCtrl = .{
        .write_pos = 0,
        .server_connected = false,
        .cart_buffer_active = false,
        .rtt_buffer_active = false,
        .has_thread_ctx = false,
    };

    fn inactive(ctrl: TracyAtomicWriteCtrl) bool {
        return !(ctrl.server_connected and ctrl.cart_buffer_active and ctrl.rtt_buffer_active);
    }
};

inline fn ring_available(read_pos: u16, write_pos: u16, size: u16) u16 {
    return (read_pos -% 1 -% write_pos) & (size - 1);
}

const RingBufferWriter = struct {
    buf: [*]u8,
    size: u16,
    write_pos: u16,
    read_pos: u16,

    inline fn available(w: *RingBufferWriter) u16 {
        return ring_available(w.read_pos, w.write_pos, w.size);
    }

    inline fn write_assume_available(w: *RingBufferWriter, bytes: []const u8) void {
        const first_len = @min(w.size - w.write_pos, bytes.len);
        @memcpy(w.buf[w.write_pos..][0..first_len], bytes[0..first_len]);
        if (first_len < bytes.len) {
            const second_len = bytes.len - first_len;
            @memcpy(w.buf[0..second_len], bytes[first_len..]);
        }
        w.write_pos = @intCast((w.write_pos +% bytes.len) & (w.size - 1));
    }
};

inline fn spin_lock_acquire_hw(_: *u32) void {
    const spinlock: *volatile u32 = @ptrFromInt(0xd0000128);
    while (spinlock.* == 0) {}
}

inline fn spin_lock_release_hw(_: *u32) void {
    const spinlock: *volatile u32 = @ptrFromInt(0xd0000128);
    spinlock.* = 0;
}

inline fn spin_lock_acquire_sw(lock: *u32) void {
    var tmp0: u32 = undefined;
    var tmp1: u32 = undefined;
    // Copied from pico SDK spin_lock.h
    asm volatile (
        \\ 1: ldaex %[t1], [%[lock]]         // Load the lock value with linked store
        \\    movs %[t0], #1                 // From PICO: "fill dependency slot" ...?
        \\    cmp %[t1], #0                  // check if lock is taken
        \\    bne 1b                         // retry if lock is taken
        \\    strex %[t1], %[t0], [%[lock]]  // attempt to claim the lock
        \\   cmp %[t1], #0                 //  check if we got it
        \\  bne 1b                       //   retry if not
        //\\ dmb                         //    finally, memory barrier
        : [t0] "=&r" (tmp0),
          [t1] "=&r" (tmp1),
        : [lock] "r" (lock),
        : .{ .memory = true });
}

inline fn spin_lock_release_sw(lock: *u32) void {
    const zero: u32 = 0;
    asm volatile (
        \\ stl %[zero], [%[lock]] // store with release semantics
        :
        : [zero] "r" (zero),
          [lock] "r" (lock),
    );
}

pub const spin_lock_acquire = spin_lock_acquire_hw;
pub const spin_lock_release = spin_lock_release_hw;

inline fn cmpxchg_strong(ptr: *volatile u32, expected: u32, new: u32) ?u32 {
    spin_lock_acquire(tracy_spinlock);
    defer spin_lock_release(tracy_spinlock);

    const value = ptr.*;
    if (value != expected) {
        @branchHint(.unlikely);
        return value;
    }
    ptr.* = new;
    return null;

    // var actual: u32 = undefined;
    // var failure: u32 = undefined;
    // asm volatile (
    //     \\ 1: ldaex %[actual], [%[ptr]]
    //     \\    movs %[failure], #1
    //     \\    cmp %[actual], %[expected]
    //     \\    bne 1f
    //     \\    strex %[failure], %[new], [%[ptr]]
    //     \\    cmp %[failure], #0
    //     \\    bne 1b
    //     \\    dmb
    //     \\ 1:
    //     : [actual] "=&r" (actual)
    //     , [failure] "=&r" (failure)
    //     : [ptr] "r" (ptr)
    //     , [expected] "r" (expected)
    //     , [new] "r" (new)
    //     : .{ .memory = true }
    // );

    // return if (failure != 0) actual else null;
    // return @cmpxchgStrong(T, ptr, expected, new, success, fail);
}

inline fn write_tracy_data_with_delta_time(time: i64, record_block: bool, data_wrapper: anytype) bool {
    var write_ctrl_word = @atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst);
    while (true) {
        var write_ctrl: TracyAtomicWriteCtrl = @bitCast(write_ctrl_word);
        if (write_ctrl.inactive()) return false;

        var ref_time = tracy_ref_time;
        if (!write_ctrl.has_thread_ctx) {
            @branchHint(.unlikely);
            ref_time = 0;
            write_ctrl.has_thread_ctx = true;
        }

        {
            const delta = time - ref_time;
            ref_time = time;

            var writer: RingBufferWriter = .{
                .buf = tracy_ring,
                .size = tracy_buffer_size,
                .write_pos = write_ctrl.write_pos,
                .read_pos = @truncate(@atomicLoad(u32, tracy_atomic_read_pos, .seq_cst)),
            };

            const bytes = data_wrapper.set(delta);

            if (writer.available() < bytes.len) {
                @branchHint(.unlikely);

                if (!record_block) continue;
                return write_tracy_data_blocking_with_delta_time(time, write_ctrl.write_pos, data_wrapper);
            }

            writer.write_assume_available(bytes);

            write_ctrl.write_pos = writer.write_pos;
        }

        write_ctrl_word = if (cmpxchg_strong(tracy_atomic_write_ctrl, write_ctrl_word, @bitCast(write_ctrl))) |v| v else {
            tracy_ref_time = ref_time;
            return true;
        };
    }
}

noinline fn write_tracy_data_blocking_with_delta_time(time: i64, write_pos: u16, data_wrapper: anytype) linksection(".ramfunc") bool {
    const src_loc = external_source_location("Too Much Data!", @src(), 0xDF0F3F);

    // TODO handle graceful data loss rather than blocking
    const space_needed = data_wrapper.max_size() + @sizeOf(q.Packet(q.ZoneBegin16)) + @sizeOf(q.ZoneEndData);
    while (true) {
        // Check if we have space
        const read_pos = @atomicLoad(u32, tracy_atomic_read_pos, .acquire);
        if (space_needed <= ring_available(@intCast(read_pos), write_pos, tracy_buffer_size)) break;

        // Check if server disconnected
        var new_write_ctrl: TracyAtomicWriteCtrl = @bitCast(@atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst));
        if (new_write_ctrl.inactive()) return false;
    }

    // We have space! Record the new delta.
    // It might be impossible for this loop to actually loop,
    // but we have it just in case.
    var write_ctrl_word = @atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst);
    while (true) {
        var write_ctrl: TracyAtomicWriteCtrl = @bitCast(write_ctrl_word);
        if (write_ctrl.inactive()) return false;

        var ref_time = tracy_ref_time;
        if (!write_ctrl.has_thread_ctx) {
            @branchHint(.unlikely);
            ref_time = 0;
            write_ctrl.has_thread_ctx = true;
        }

        {
            const delta = time - ref_time;
            ref_time = time;

            var writer: RingBufferWriter = .{
                .buf = tracy_ring,
                .size = tracy_buffer_size,
                .write_pos = write_ctrl.write_pos,
                .read_pos = @truncate(@atomicLoad(u32, tracy_atomic_read_pos, .seq_cst)),
            };

            const bytes = data_wrapper.set(delta);

            writer.write_assume_available(bytes);

            const begin = q.packet(.ZoneBegin16, .{ .time = 0, .srcloc = @intFromPtr(src_loc) });
            writer.write_assume_available(std.mem.asBytes(&begin));

            var end: q.ZoneEndData = undefined;
            const post_time = cycles();
            writer.write_assume_available(end.set(post_time - ref_time));
            ref_time = post_time;

            write_ctrl.write_pos = writer.write_pos;
        }

        write_ctrl_word = if (cmpxchg_strong(tracy_atomic_write_ctrl, write_ctrl_word, @bitCast(write_ctrl))) |v| v else {
            tracy_ref_time = ref_time;
            return true;
        };
    }
}

noinline fn outline_zone_begin_static(time: i64, record_block: bool, src_loc: *const q.SourceLocationData) linksection(".ramfunc") bool {
    const ZoneBegin = struct {
        data: q.ZoneBeginData = undefined,
        src_loc: *const q.SourceLocationData,

        pub fn set(self: *@This(), dt: i64) []const u8 {
            return self.data.set(dt, self.src_loc);
        }

        pub fn max_size(_: *@This()) usize {
            return @sizeOf(q.ZoneBeginData);
        }
    };

    var data: ZoneBegin = .{ .src_loc = src_loc };
    return write_tracy_data_with_delta_time(time, record_block, &data);
}

noinline fn outline_zone_end(time: i64, record_block: bool) linksection(".ramfunc") void {
    var data: q.ZoneEndData = undefined;
    _ = write_tracy_data_with_delta_time(time, record_block, &data);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Returns a random number from the RP2350 ring oscillator random bit.
/// Useful for seeding a faster PRNG.
pub fn rand() u32 {
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
pub fn trace(x: []const u8) void {
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

pub const PresentFlags = packed struct(u32) {
    const FRAMEBUFFER_READY_V2: u8 = 0x28; // see os/ipc/mailbox.zig

    framebuffer_index: u1,
    has_dirty_rect: bool,
    vsync_updated: bool,
    clear_frame: bool,
    _reserved: u20 = 0,
    tag: u8 = FRAMEBUFFER_READY_V2,
};

/// Signal Core 0 that the framebuffer is ready and wait for the
/// LCD flush to complete before returning.
///
/// Call this once per frame (typically at the end of `update()`).
/// On WASM this is a no-op because the simulator owns the display.
pub fn present() void {
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
    const FRAMEBUFFER_DONE: u32 = 0x25000002;

    // Drain completion messages to release the in-flight slot.
    while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
        const reply = SIO_FIFO_RD.*;
        if (reply == FRAMEBUFFER_DONE) {
            has_in_flight_frame = false;
        }
    }

    if (has_in_flight_frame) {
        const spin_start_time = micros_since_boot();
        while (has_in_flight_frame) {
            while (SIO_FIFO_ST.* & FIFO_VLD == 0) {
                asm volatile ("nop");
                const now = micros_since_boot();
                if (now - spin_start_time >= present_wait_time_limit) {
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

    // Some carts don't properly set up the dirty rect.
    // If a cart never calls set_double_buffer_mode, we
    // assume it is unaware of the dirty rect, and
    // compute it internally instead.
    if (!has_set_double_buffer_mode and !dirty_rect.has_area()) {
        dirty_rect = compute_dirty_rect_legacy_fallback();
    }

    const message: PresentFlags = .{
        .framebuffer_index = draw_buffer_index,
        .has_dirty_rect = dirty_rect.has_area(),
        .vsync_updated = vsync_updated,
        .clear_frame = (double_buffer_mode == .clear_full_frame),
    };
    vsync_updated = false;

    ipc_data.dirty_rect = dirty_rect;

    if (double_buffer_mode == .clear_full_frame) {
        ipc_data.clear_color = .from_color(double_buffer_mode.clear_full_frame);
    }

    const spin_start_time = micros_since_boot();
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
        asm volatile ("nop");
        const now = micros_since_boot();
        if (now - spin_start_time >= present_wait_time_limit) {
            present_timeout_events +%= 1;
            if ((present_timeout_events & 0x3f) == 0x01) {
                trace("[PRESENT] timeout waiting FIFO_RDY");
            }
            return;
        }
    }

    // Ensure all framebuffer and IPC writes are available for the other core
    asm volatile ("dmb" ::: .{ .memory = true });
    // Send the message
    SIO_FIFO_WR.* = @bitCast(message);
    // SEV to wake Core 0 in case it's in WFE.
    asm volatile ("sev");

    has_in_flight_frame = true;

    prev_dirty_rect = dirty_rect;
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
    update_draw_buffer_pointer();
}

fn compute_dirty_rect_legacy_fallback() Rect8 {
    const cur_raw = if (draw_buffer_index == 0) framebuffer0 else framebuffer1;
    const prev_raw = if (draw_buffer_index == 0) framebuffer1 else framebuffer0;

    const simd_len = @divExact(@sizeOf(u32), @sizeOf(Pixel));
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
