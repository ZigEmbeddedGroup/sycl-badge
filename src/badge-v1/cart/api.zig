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
        return .{ .bits = @byteSwap(@as(u16, @bitCast(color))) };
    }

    pub fn toColor(pixel: Pixel) DisplayColor {
        return @bitCast(@byteSwap(pixel.bits));
    }

    pub fn setColor(pixel: *volatile Pixel, color: DisplayColor) void {
        pixel.* = fromColor(color);
    }
};

pub const Controls = packed struct(u9) {
    /// START button
    start: bool,
    /// SELECT button
    select: bool,
    /// A button
    a: bool,
    /// B button
    b: bool,

    /// Tactile click
    click: bool,
    /// Tactile up
    up: bool,
    /// Tactile down
    down: bool,
    /// Tactile left
    left: bool,
    /// Tactile right
    right: bool,
};

const base = if (is_wasm) 0 else 0x20000000;

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
        const rest: extern struct {
            width: u32,
            height: u32,
            src_x: u32,
            src_y: u32,
            stride: u32,
            flags: BlitOptions.Flags,
        } = .{
            .width = options.width,
            .height = options.height,
            .src_x = options.src_x,
            .src_y = options.src_y,
            .stride = options.stride orelse options.width,
            .flags = options.flags,
        };
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #0"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [sprite] "{r0}" (options.sprite),
              [x] "{r1}" (options.x),
              [y] "{r2}" (options.y),
              [rest] "{r3}" (&rest),
            : .{ .memory = true });
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
        const rest: extern struct {
            y2: i32,
            color: DisplayColor,
        } = .{
            .y2 = options.y2,
            .color = options.color,
        };
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #1"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [x1] "{r0}" (options.x1),
              [y1] "{r1}" (options.y1),
              [x2] "{r2}" (options.x2),
              [rest] "{r3}" (&rest),
            : .{ .memory = true });
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
        const rest: extern struct {
            height: u32,
            stroke_color: DisplayColor.Optional,
            fill_color: DisplayColor.Optional,
        } = .{
            .height = options.height,
            .stroke_color = DisplayColor.Optional.from(options.stroke_color),
            .fill_color = DisplayColor.Optional.from(options.fill_color),
        };
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #2"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [x] "{r0}" (options.x),
              [y] "{r1}" (options.y),
              [width] "{r2}" (options.width),
              [rest] "{r3}" (&rest),
            : .{ .memory = true });
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
        const rest: extern struct {
            height: u32,
            stroke_color: DisplayColor.Optional,
            fill_color: DisplayColor.Optional,
        } = .{
            .height = options.height,
            .stroke_color = DisplayColor.Optional.from(options.stroke_color),
            .fill_color = DisplayColor.Optional.from(options.fill_color),
        };
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #3"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [x] "{r0}" (options.x),
              [y] "{r1}" (options.y),
              [width] "{r2}" (options.width),
              [rest] "{r3}" (&rest),
            : .{ .memory = true });
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
        const rest: extern struct {
            y: i32,
            text_color: DisplayColor.Optional,
            background_color: DisplayColor.Optional,
        } = .{
            .y = options.y,
            .text_color = DisplayColor.Optional.from(options.text_color),
            .background_color = DisplayColor.Optional.from(options.background_color),
        };
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #4"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [str_ptr] "{r0}" (options.str.ptr),
              [str_len] "{r1}" (options.str.len),
              [x] "{r2}" (options.x),
              [rest] "{r3}" (&rest),
            : .{ .memory = true });
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
        }.hline(
            options.color,
            options.x,
            options.y,
            options.len,
        );
    } else {
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #5"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [x] "{r0}" (options.x),
              [y] "{r1}" (options.y),
              [len] "{r2}" (options.len),
              [color] "{r3}" (options.color),
            : .{ .memory = true });
    }
}

/// Draws a vertical line
pub inline fn vline(options: StraightLineOptions) void {
    if (is_wasm) {
        struct {
            extern fn vline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        }.vline(
            options.color,
            options.x,
            options.y,
            options.len,
        );
    } else {
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #6"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [x] "{r0}" (options.x),
              [y] "{r1}" (options.y),
              [len] "{r2}" (options.len),
              [color] "{r3}" (options.color),
            : .{ .memory = true });
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

const is_wasm = switch (builtin.target.cpu.arch) {
    .wasm32, .wasm64 => true,
    else => false,
};

/// Plays a sound tone.
pub inline fn tone(options: ToneOptions) void {
    if (is_wasm) {
        struct {
            extern fn tone(frequency: u32, duration: u32, volume: u32, flags: ToneOptions.Flags) void;
        }.tone(
            options.frequency,
            options.duration,
            options.volume,
            options.flags,
        );
    } else {
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        var clobber_r3: usize = undefined;
        asm volatile (" svc #7"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
              [clobber_r3] "={r3}" (clobber_r3),
            : [frequency] "{r0}" (options.frequency),
              [duration] "{r1}" (options.duration),
              [volume] "{r2}" (options.volume),
              [flags] "{r3}" (options.flags),
        );
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Storage Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const flash_page_size = 256;
pub const flash_page_count = 8000;

/// Attempts to fill `dst`, returns the amount of bytes actually read
pub inline fn read_flash(offset: u32, dst: []u8) u32 {
    if (is_wasm) {
        return struct {
            extern fn read_flash(offset: u32, dst: [*]u8, len: u32) u32;
        }.read_flash(offset, dst.ptr, dst.len);
    } else {
        var clobber_r1: usize = undefined;
        var clobber_r2: usize = undefined;
        return asm volatile (" svc #8"
            : [result] "={r0}" (-> u32),
              [clobber_r1] "={r1}" (clobber_r1),
              [clobber_r2] "={r2}" (clobber_r2),
            : [offset] "{r0}" (offset),
              [dst_ptr] "{r1}" (dst.ptr),
              [dst_len] "{r2}" (dst.len),
            : .{ .r3 = true });
    }
}

pub inline fn write_flash_page(page: u16, src: [flash_page_size]u8) void {
    if (is_wasm) {
        struct {
            extern fn write_flash_page(page: u32, src: [*]const u8) void;
        }.write_flash_page(page, &src);
    } else {
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        asm volatile (" svc #9"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
            : [page] "{r0}" (page),
              [src] "{r1}" (&src),
            : .{ .r2 = true, .r3 = true, .memory = true });
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Returns a random number, useful for seeding a faster prng.
pub inline fn rand() u32 {
    if (is_wasm) {
        return struct {
            extern fn rand() u32;
        }.rand();
    } else {
        return asm volatile (" svc #10"
            : [result] "={r0}" (-> u32),
            :
            : .{ .r1 = true, .r2 = true, .r3 = true });
    }
}

/// Prints a message to the debug console.
pub inline fn trace(x: []const u8) void {
    if (is_wasm) {
        struct {
            extern fn trace(str_ptr: [*]const u8, str_len: usize) void;
        }.trace(x.ptr, x.len);
    } else {
        var clobber_r0: usize = undefined;
        var clobber_r1: usize = undefined;
        asm volatile (" svc #11"
            : [clobber_r0] "={r0}" (clobber_r0),
              [clobber_r1] "={r1}" (clobber_r1),
            : [x_ptr] "{r0}" (x.ptr),
              [x_len] "{r1}" (x.len),
            : .{ .r2 = true, .r3 = true });
    }
}
