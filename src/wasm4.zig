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

pub const palette: *[4]u32 = @ptrFromInt(base + 0x04);
pub const draw_colors: *u16 = @ptrFromInt(base + 0x14);
pub const gamepad1: *const u8 = @ptrFromInt(base + 0x16);
pub const gamepad2: *const u8 = @ptrFromInt(base + 0x17);
pub const gamepad3: *const u8 = @ptrFromInt(base + 0x18);
pub const gamepad4: *const u8 = @ptrFromInt(base + 0x19);
pub const mouse_x: *const i16 = @ptrFromInt(base + 0x1a);
pub const mouse_y: *const i16 = @ptrFromInt(base + 0x1c);
pub const mouse_buttons: *const u8 = @ptrFromInt(base + 0x1e);
pub const system_flags: *u8 = @ptrFromInt(base + 0x1f);
pub const framebuffer: *[6400]u8 = @ptrFromInt(base + 0xa0);

pub const button_1: u8 = 1;
pub const button_2: u8 = 2;
pub const button_left: u8 = 16;
pub const button_right: u8 = 32;
pub const button_up: u8 = 64;
pub const button_down: u8 = 128;

pub const mouse_left: u8 = 1;
pub const mouse_right: u8 = 2;
pub const mouse_middle: u8 = 4;

pub const system_preserve_framebuffer: u8 = 1;
pub const system_hide_gamepad_overlay: u8 = 2;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Drawing Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

const platform_specific = if (builtin.target.isWasm())
    struct {
        extern fn blit(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: u32) void;
        extern fn blitSub(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: u32) void;
        extern fn line(x1: i32, y1: i32, x2: i32, y2: i32) void;
        extern fn oval(x: i32, y: i32, width: u32, height: u32) void;
        extern fn rect(x: i32, y: i32, width: u32, height: u32) void;
        extern fn text(strPtr: [*]const u8, strLen: usize, x: i32, y: i32) void;
        extern fn vline(x: i32, y: i32, len: u32) void;
        extern fn hline(x: i32, y: i32, len: u32) void;
        extern fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void;
        extern fn diskr(dest: [*]u8, size: u32) u32;
        extern fn diskw(src: [*]const u8, size: u32) u32;
        extern fn trace(strPtr: [*]const u8, strLen: usize) void;
    }
else
    struct {
        export fn __return_thunk__() noreturn {
            asm volatile (" svc #12");
            unreachable;
        }
    };

/// Copies pixels to the framebuffer.
pub inline fn blit(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.blit(sprite, x, y, width, height, flags);
    } else {
        const rest: extern struct {
            width: u32,
            height: u32,
            flags: u32,
        } = .{
            .width = width,
            .height = height,
            .flags = flags,
        };
        asm volatile (" svc #0"
            :
            : [sprite] "{r0}" (sprite),
              [x] "{r1}" (x),
              [y] "{r2}" (y),
              [rest] "{r3}" (&rest),
            : "memory"
        );
    }
}

/// Copies a subregion within a larger sprite atlas to the framebuffer.
pub inline fn blit_sub(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.blitSub(sprite, x, y, width, height, src_x, src_y, stride, flags);
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

pub const blit_2bpp: u32 = 1;
pub const blit_1bpp: u32 = 0;
pub const blit_flip_x: u32 = 2;
pub const blit_flip_y: u32 = 4;
pub const blit_rotate: u32 = 8;

/// Draws a line between two points.
pub inline fn line(x1: i32, y1: i32, x2: i32, y2: i32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.line(x1, y1, x2, y2);
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
pub inline fn oval(x: i32, y: i32, width: u32, height: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.oval(x, y, width, height);
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
pub inline fn rect(x: i32, y: i32, width: u32, height: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.rect(x, y, width, height);
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
pub inline fn text(str: []const u8, x: i32, y: i32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.text(str.ptr, str.len, x, y);
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

/// Draws a vertical line
pub inline fn vline(x: i32, y: i32, len: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.vline(x, y, len);
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

/// Draws a horizontal line
pub inline fn hline(x: i32, y: i32, len: u32) void {
    if (comptime builtin.target.isWasm()) {
        platform_specific.hline(x, y, len);
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

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Plays a sound tone.
pub inline fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void {
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

pub const tone_pulse1: u32 = 0;
pub const tone_pulse2: u32 = 1;
pub const tone_triangle: u32 = 2;
pub const tone_noise: u32 = 3;
pub const tone_mode1: u32 = 0;
pub const tone_mode2: u32 = 4;
pub const tone_mode3: u32 = 8;
pub const tone_mode4: u32 = 12;
pub const tone_pan_left: u32 = 16;
pub const tone_pan_right: u32 = 32;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Storage Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Reads up to `size` bytes from persistent storage into the pointer `dest`.
pub inline fn diskr(dest: [*]u8, size: u32) u32 {
    if (comptime builtin.target.isWasm()) {
        return platform_specific.diskr(dest, size);
    } else {
        return asm volatile (" svc #9"
            : [result] "={r0}" (-> u32),
            : [dest] "{r0}" (dest),
              [size] "{r1}" (size),
        );
    }
}

/// Writes up to `size` bytes from the pointer `src` into persistent storage.
pub inline fn diskw(src: [*]const u8, size: u32) u32 {
    if (comptime builtin.target.isWasm()) {
        return platform_specific.diskw(src, size);
    } else {
        return asm volatile (" svc #10"
            : [result] "={r0}" (-> u32),
            : [src] "{r0}" (src),
              [size] "{r1}" (size),
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
