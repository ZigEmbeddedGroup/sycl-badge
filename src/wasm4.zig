//
// WASM-4: https://wasm4.org/docs

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Platform Constants                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const SCREEN_SIZE: u32 = 160;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Memory Addresses                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const PALETTE: *[4]u32 = @ptrFromInt(0x20000004);
pub const DRAW_COLORS: *u16 = @ptrFromInt(0x20000014);
pub const GAMEPAD1: *const u8 = @ptrFromInt(0x20000016);
pub const GAMEPAD2: *const u8 = @ptrFromInt(0x20000017);
pub const GAMEPAD3: *const u8 = @ptrFromInt(0x20000018);
pub const GAMEPAD4: *const u8 = @ptrFromInt(0x20000019);
pub const MOUSE_X: *const i16 = @ptrFromInt(0x2000001a);
pub const MOUSE_Y: *const i16 = @ptrFromInt(0x2000001c);
pub const MOUSE_BUTTONS: *const u8 = @ptrFromInt(0x2000001e);
pub const SYSTEM_FLAGS: *u8 = @ptrFromInt(0x2000001f);
pub const NETPLAY: *const u8 = @ptrFromInt(0x20000020);
pub const FRAMEBUFFER: *[6400]u8 = @ptrFromInt(0x200000A0);

pub const BUTTON_1: u8 = 1;
pub const BUTTON_2: u8 = 2;
pub const BUTTON_LEFT: u8 = 16;
pub const BUTTON_RIGHT: u8 = 32;
pub const BUTTON_UP: u8 = 64;
pub const BUTTON_DOWN: u8 = 128;

pub const MOUSE_LEFT: u8 = 1;
pub const MOUSE_RIGHT: u8 = 2;
pub const MOUSE_MIDDLE: u8 = 4;

pub const SYSTEM_PRESERVE_FRAMEBUFFER: u8 = 1;
pub const SYSTEM_HIDE_GAMEPAD_OVERLAY: u8 = 2;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Drawing Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Copies pixels to the framebuffer.
pub inline fn blit(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, flags: u32) void {
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

/// Copies a subregion within a larger sprite atlas to the framebuffer.
pub inline fn blitSub(sprite: [*]const u8, x: i32, y: i32, width: u32, height: u32, src_x: u32, src_y: u32, stride: u32, flags: u32) void {
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

pub const BLIT_2BPP: u32 = 1;
pub const BLIT_1BPP: u32 = 0;
pub const BLIT_FLIP_X: u32 = 2;
pub const BLIT_FLIP_Y: u32 = 4;
pub const BLIT_ROTATE: u32 = 8;

/// Draws a line between two points.
pub inline fn line(x1: i32, y1: i32, x2: i32, y2: i32) void {
    asm volatile (" svc #2"
        :
        : [x1] "{r0}" (x1),
          [y1] "{r1}" (y1),
          [x2] "{r2}" (x2),
          [y2] "{r3}" (y2),
        : "memory"
    );
}

/// Draws an oval (or circle).
pub inline fn oval(x: i32, y: i32, width: u32, height: u32) void {
    asm volatile (" svc #3"
        :
        : [x] "{r0}" (x),
          [y] "{r1}" (y),
          [width] "{r2}" (width),
          [height] "{r3}" (height),
        : "memory"
    );
}

/// Draws a rectangle.
pub inline fn rect(x: i32, y: i32, width: u32, height: u32) void {
    asm volatile (" svc #4"
        :
        : [x] "{r0}" (x),
          [y] "{r1}" (y),
          [width] "{r2}" (width),
          [height] "{r3}" (height),
        : "memory"
    );
}

/// Draws text using the built-in system font.
pub inline fn text(str: []const u8, x: i32, y: i32) void {
    asm volatile (" svc #5"
        :
        : [str_ptr] "{r0}" (str.ptr),
          [str_len] "{r1}" (str.len),
          [x] "{r2}" (x),
          [y] "{r3}" (y),
        : "memory"
    );
}

/// Draws a vertical line
pub inline fn vline(x: i32, y: i32, len: u32) void {
    asm volatile (" svc #6"
        :
        : [x] "{r0}" (x),
          [y] "{r1}" (y),
          [len] "{r2}" (len),
        : "memory"
    );
}

/// Draws a horizontal line
pub inline fn hline(x: i32, y: i32, len: u32) void {
    asm volatile (" svc #7"
        :
        : [x] "{r0}" (x),
          [y] "{r1}" (y),
          [len] "{r2}" (len),
        : "memory"
    );
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Plays a sound tone.
pub inline fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void {
    asm volatile (" svc #8"
        :
        : [frequency] "{r0}" (frequency),
          [duration] "{r1}" (duration),
          [volume] "{r2}" (volume),
          [flags] "{r3}" (flags),
    );
}

pub const TONE_PULSE1: u32 = 0;
pub const TONE_PULSE2: u32 = 1;
pub const TONE_TRIANGLE: u32 = 2;
pub const TONE_NOISE: u32 = 3;
pub const TONE_MODE1: u32 = 0;
pub const TONE_MODE2: u32 = 4;
pub const TONE_MODE3: u32 = 8;
pub const TONE_MODE4: u32 = 12;
pub const TONE_PAN_LEFT: u32 = 16;
pub const TONE_PAN_RIGHT: u32 = 32;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Storage Functions                                                         │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Reads up to `size` bytes from persistent storage into the pointer `dest`.
pub inline fn diskr(dest: [*]u8, size: u32) u32 {
    return asm volatile (" svc #9"
        : [result] "={r0}" (-> u32),
        : [dest] "{r0}" (dest),
          [size] "{r1}" (size),
    );
}

/// Writes up to `size` bytes from the pointer `src` into persistent storage.
pub inline fn diskw(src: [*]const u8, size: u32) u32 {
    return asm volatile (" svc #10"
        : [result] "={r0}" (-> u32),
        : [src] "{r0}" (src),
          [size] "{r1}" (size),
    );
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Prints a message to the debug console.
pub inline fn trace(x: []const u8) void {
    asm volatile (" svc #11"
        :
        : [x_ptr] "{r0}" (x.ptr),
          [x_len] "{r1}" (x.len),
    );
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Internal Use                                                              │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub export fn __return_thunk__() noreturn {
    asm volatile (" svc #12");
    unreachable;
}
