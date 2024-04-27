const std = @import("std");
const builtin = @import("builtin");

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Platform Constants                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const screen_width: u32 = 160;
pub const screen_height: u32 = 128;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Memory Addresses                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

const base = if (builtin.target.isWasm()) 0 else 0x20000000;

/// RGB888, true color
pub const NeopixelColor = packed struct(u24) { blue: u8, green: u8, red: u8 };

/// RGB565, high color
pub const DisplayColor = packed struct(u16) { blue: u5, green: u6, red: u5 };
const OptionalDisplayColor = enum(i32) {
    none = -1,
    _,

    inline fn from(color: ?DisplayColor) OptionalDisplayColor {
        return if (color) |c| @enumFromInt(@as(u16, @bitCast(c))) else .none;
    }
};

pub const Controls = packed struct {
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

pub const controls: *const Controls = @ptrFromInt(base + 0x04);
pub const light_level: *const u12 = @ptrFromInt(base + 0x06);
/// 5 24-bit color LEDs
pub const neopixels: *[5]NeopixelColor = @ptrFromInt(base + 0x08);
pub const red_led: *bool = @ptrFromInt(base + 0x1c);
pub const framebuffer: *[screen_width * screen_height]DisplayColor = @ptrFromInt(base + 0x1e);

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Drawing Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

const platform_specific = if (builtin.target.isWasm())
    struct {
        extern fn blit(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: BlitFlags) void;
        extern fn blit_sub(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: BlitFlags) void;
        extern fn line(color: DisplayColor, x1: i32, y1: i32, x2: i32, y2: i32) void;
        extern fn oval(stroke_color: OptionalDisplayColor, fill_color: OptionalDisplayColor, x: i32, y: i32, width: u32, height: u32) void;
        extern fn rect(stroke_color: OptionalDisplayColor, fill_color: OptionalDisplayColor, x: i32, y: i32, width: u32, height: u32) void;
        extern fn text(text_color: DisplayColor, background_color: OptionalDisplayColor, str_ptr: [*]const u8, str_len: usize, x: i32, y: i32) void;
        extern fn vline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        extern fn hline(color: DisplayColor, x: i32, y: i32, len: u32) void;
        extern fn tone(frequency: u32, duration: u32, volume: u32, flags: ToneFlags) void;
        extern fn read_flash(offset: u32, dst: [*]u8, len: u32) u32;
        extern fn write_flash_page(page: u32, src: [*]const u8) void;
        extern fn trace(str_ptr: [*]const u8, str_len: usize) void;
    }
else
    struct {
        export fn __return_thunk__() noreturn {
            asm volatile (" svc #12");
            unreachable;
        }
    };

comptime {
    _ = platform_specific;
}

pub const BitsPerPixel = enum(u1) { one, two };
pub const BlitFlags = packed struct(u32) {
    bits_per_pixel: BitsPerPixel = .one,
    flip_x: bool = false,
    flip_y: bool = false,
    rotate: bool = false,
    padding: u28 = undefined,
};

/// Copies pixels to the framebuffer.
/// colors.len >= 2 for flags.bits_per_pixel == .one
/// colors.len >= 4 for flags.bits_per_pixel == .two
/// TODO: this is super unsafe also blit is just a basic wrapper over blitSub
pub inline fn blit(colors: [*]const DisplayColor, sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: BlitFlags) void {
    _ = colors;
    if (comptime builtin.target.isWasm()) {
        platform_specific.blit(sprite, x, y, width, height, flags);
    } else {
        @compileError("TODO");
        // const rest: extern struct {
        //     width: u32,
        //     height: u32,
        //     flags: u32,
        // } = .{
        //     .width = width,
        //     .height = height,
        //     .flags = flags,
        // };
        // asm volatile (" svc #0"
        //     :
        //     : [sprite] "{r0}" (sprite),
        //       [x] "{r1}" (x),
        //       [y] "{r2}" (y),
        //       [rest] "{r3}" (&rest),
        //     : "memory"
        // );
    }
}

/// Copies a subregion within a larger sprite atlas to the framebuffer.
/// colors.len >= 2 for flags.bits_per_pixel == .one
/// colors.len >= 4 for flags.bits_per_pixel == .two
/// TODO: this is super unsafe also blit is just a basic wrapper over blitSub
pub inline fn blit_sub(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: BlitFlags) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.blit_sub(sprite, x, y, width, height, src_x, src_y, stride, flags);
    } else {
        const rest: extern struct {
            width: u32,
            height: u32,
            src_x: u32,
            src_y: u32,
            stride: u32,
            flags: u32,
        } = .{
            .width = width,
            .height = height,
            .src_x = src_x,
            .src_y = src_y,
            .stride = stride,
            .flags = flags,
        };
        asm volatile (" svc #1"
            :
            : [sprite] "{r0}" (sprite),
              [x] "{r1}" (x),
              [y] "{r2}" (y),
              [rest] "{r3}" (&rest),
            : "memory"
        );
    }
}

/// Draws a line between two points.
pub inline fn line(color: DisplayColor, x1: i32, y1: i32, x2: i32, y2: i32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.line(color, x1, y1, x2, y2);
    } else {
        asm volatile (" svc #2"
            :
            : [x1] "{r0}" (x1),
              [y1] "{r1}" (y1),
              [x2] "{r2}" (x2),
              [y2] "{r3}" (y2),
            : "memory"
        );
    }
}

/// Draws an oval (or circle).
pub inline fn oval(stroke_color: ?DisplayColor, fill_color: ?DisplayColor, x: i32, y: i32, width: u32, height: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.oval(OptionalDisplayColor.from(stroke_color), OptionalDisplayColor.from(fill_color), x, y, width, height);
    } else {
        asm volatile (" svc #3"
            :
            : [x] "{r0}" (x),
              [y] "{r1}" (y),
              [width] "{r2}" (width),
              [height] "{r3}" (height),
            : "memory"
        );
    }
}

/// Draws a rectangle.
pub inline fn rect(stroke_color: ?DisplayColor, fill_color: ?DisplayColor, x: i32, y: i32, width: u32, height: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.rect(OptionalDisplayColor.from(stroke_color), OptionalDisplayColor.from(fill_color), x, y, width, height);
    } else {
        asm volatile (" svc #4"
            :
            : [x] "{r0}" (x),
              [y] "{r1}" (y),
              [width] "{r2}" (width),
              [height] "{r3}" (height),
            : "memory"
        );
    }
}

/// Draws text using the built-in system font.
pub inline fn text(text_color: DisplayColor, background_color: ?DisplayColor, str: []const u8, x: i32, y: i32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.text(text_color, OptionalDisplayColor.from(background_color), str.ptr, str.len, x, y);
    } else {
        asm volatile (" svc #5"
            :
            : [str_ptr] "{r0}" (str.ptr),
              [str_len] "{r1}" (str.len),
              [x] "{r2}" (x),
              [y] "{r3}" (y),
            : "memory"
        );
    }
}

/// Draws a horizontal line
pub inline fn hline(color: DisplayColor, x: i32, y: i32, len: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.hline(color, x, y, len);
    } else {
        asm volatile (" svc #7"
            :
            : [x] "{r0}" (x),
              [y] "{r1}" (y),
              [len] "{r2}" (len),
            : "memory"
        );
    }
}

/// Draws a vertical line
pub inline fn vline(color: DisplayColor, x: i32, y: i32, len: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.vline(color, x, y, len);
    } else {
        asm volatile (" svc #6"
            :
            : [x] "{r0}" (x),
              [y] "{r1}" (y),
              [len] "{r2}" (len),
            : "memory"
        );
    }
}

pub const ToneFlags = packed struct(u32) {
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
    duty_cycle: DutyCycle,
    panning: Panning,
    padding: u26 = undefined,
};

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Plays a sound tone.
pub inline fn tone(frequency: u32, duration: u32, volume: u32, flags: ToneFlags) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.tone(frequency, duration, volume, flags);
    } else {
        asm volatile (" svc #8"
            :
            : [frequency] "{r0}" (frequency),
              [duration] "{r1}" (duration),
              [volume] "{r2}" (volume),
              [flags] "{r3}" (flags),
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
    if (comptime builtin.target.isWasm()) {
        return platform_specific.read_flash(offset, dst.ptr, dst.len);
    } else {
        @panic("TODO");
    }
}

pub inline fn write_flash_page(page: u16, src: [flash_page_size]u8) void {
    if (comptime builtin.target.isWasm()) {
        return platform_specific.write_flash_page(page, &src);
    } else {
        // TODO: return?
        _ = asm volatile (" svc #10"
            : [result] "={r0}" (-> u32),
            : [src] "{r0}" (src),
              [size] "{r1}" (flash_page_size),
        );
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Prints a message to the debug console.
pub inline fn trace(x: []const u8) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.trace(x.ptr, x.len);
    } else {
        asm volatile (" svc #11"
            :
            : [x_ptr] "{r0}" (x.ptr),
              [x_len] "{r1}" (x.len),
        );
    }
}
