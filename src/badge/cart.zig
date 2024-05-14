const std = @import("std");
pub const api = @import("../cart/api.zig");

const libcart = struct {
    extern var cart_data_start: u8;
    extern var cart_data_end: u8;
    extern var cart_bss_start: u8;
    extern var cart_bss_end: u8;
    extern const cart_data_load_start: u8;

    extern fn start() void;
    extern fn update() void;
};

export fn __return_thunk__() noreturn {
    asm volatile (" svc #12");
    unreachable;
}

pub fn svcall_handler() callconv(.Naked) void {
    asm volatile (
        \\ mvns r0, lr, lsl #31 - 2
        \\ bcc 1f
        \\ ite mi
        \\ movmi r1, sp
        \\ mrspl r1, psp
        \\ ldr r2, [r1, #6 * 4]
        \\ subs r2, #2
        \\ ldrb r3, [r2, #1 * 1]
        \\ cmp r3, #0xDF
        \\ bne 1f
        \\ ldrb r3, [r2, #0 * 1]
        \\ cmp r3, #12
        \\ bhi 1f
        \\ tbb [pc, r3]
        \\0:
        \\ .byte (0f - 0b) / 2
        \\ .byte (9f - 0b) / 2
        \\ .byte (9f - 0b) / 2
        \\ .byte (2f - 0b) / 2
        \\ .byte (3f - 0b) / 2
        \\ .byte (4f - 0b) / 2
        \\ .byte (5f - 0b) / 2
        \\ .byte (6f - 0b) / 2
        \\ .byte (7f - 0b) / 2
        \\ .byte (8f - 0b) / 2
        \\ .byte (8f - 0b) / 2
        \\ .byte (10f - 0b) / 2
        \\1:
        \\ .byte (11f - 0b) / 2
        \\ .byte 0xDE
        \\ .align 1
        \\0:
        \\ ldm r1, {r0-r3}
        \\ b %[blit:P]
        \\2:
        \\ ldm r1, {r0-r3}
        \\ b %[oval:P]
        \\3:
        \\ ldm r1, {r0-r3}
        \\ b %[rect:P]
        \\4:
        \\ ldm r1, {r0-r3}
        \\ b %[text:P]
        \\5:
        \\ ldm r1, {r0-r2}
        \\ b %[vline:P]
        \\6:
        \\ ldm r1, {r0-r2}
        \\ b %[hline:P]
        \\7:
        \\ ldm r1, {r0-r3}
        \\ b %[tone:P]
        \\8:
        \\ movs r0, #0
        \\ str r0, [r1, #0 * 4]
        \\9:
        \\ bx lr
        \\10:
        \\ ldm r1, {r0-r1}
        \\ b %[trace:P]
        \\11:
        \\ lsrs r0, #31
        \\ msr control, r0
        \\ it eq
        \\ popeq {r3, r5-r11, pc}
        \\ subs r0, #1 - 0xFFFFFFFD
        \\ push {r4-r11, lr}
        \\ movs r4, #0
        \\ movs r5, #0
        \\ movs r6, #0
        \\ movs r7, #0
        \\ mov r8, r4
        \\ mov r9, r5
        \\ mov r10, r6
        \\ mov r11, r7
        \\ bx r0
        :
        : [blit] "X" (&blit),
          [oval] "X" (&oval),
          [rect] "X" (&rect),
          [text] "X" (&text),
          [vline] "X" (&vline),
          [hline] "X" (&hline),
          [tone] "X" (&tone),
          [trace] "X" (&trace),
    );
}
pub const HSRAM = struct {
    pub const SIZE: usize = 0x00030000; // 192 kB
    pub const ADDR: *align(SIZE / 3) volatile [SIZE]u8 = @ptrFromInt(0x20000000);
};

pub fn start() void {
    // Initialize API Global state

    //for (&api.neopixels) |*pixel|
    //    pixel.* = .{ .r = 0, .g = 0, .b = 0 };

    //for (&api.framebuffer) |*pixel|
    //    pixel.* = .{ .r = 0, .g = 0, .b = 0 };

    call(&libcart.start);
}
pub fn tick() void {
    // TODO: check if frame is ready

    // read gamepad
    //if (SYSTEM_FLAGS.* & SYSTEM_PRESERVE_FRAMEBUFFER == 0) @memset(FRAMEBUFFER, 0b00_00_00_00);
    call(&libcart.update);
}

fn call(func: *const fn () callconv(.C) void) void {
    const process_stack = HSRAM.ADDR[HSRAM.SIZE - @divExact(
        HSRAM.SIZE,
        3 * 2,
    ) ..][0..@divExact(HSRAM.SIZE, 3 * 4)];
    const frame = comptime std.mem.bytesAsSlice(u32, process_stack[process_stack.len - 0x20 ..]);
    @memset(frame[0..5], 0);
    frame[5] = @intFromPtr(&__return_thunk__);
    frame[6] = @intFromPtr(func);
    frame[7] = 1 << 24;
    asm volatile (
        \\ msr psp, %[process_stack]
        \\ svc #12
        :
        : [process_stack] "r" (frame.ptr),
        : "memory"
    );
}

fn User(comptime T: type) type {
    return extern struct {
        const Self = @This();
        const suffix = switch (@sizeOf(T)) {
            1 => "b",
            2 => "h",
            4 => "",
            else => @compileError("loadUser doesn't support " ++ @typeName(T)),
        };

        unsafe: T,

        pub inline fn load(user: *const Self) T {
            return asm ("ldr" ++ suffix ++ "t %[value], [%[pointer]]"
                : [value] "=r" (-> T),
                : [pointer] "r" (&user.unsafe),
            );
        }

        pub inline fn store(user: *Self, value: T) void {
            asm volatile ("str" ++ suffix ++ "t %[value], [%pointer]]"
                :
                : [value] "r" (value),
                  [pointer] "r" (&user.unsafe),
            );
        }
    };
}

fn blit(sprite: [*]const User(u8), x: i32, y: i32, rest: *const extern struct { width: User(u32), height: User(u32), flags: User(u32) }) callconv(.C) void {
    _ = sprite;
    _ = x;
    _ = y;
    _ = rest;
}

pub fn oval(x: i32, y: i32, width: u32, height: u32) callconv(.C) void {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
}

pub fn rect(x: i32, y: i32, width: u32, height: u32) callconv(.C) void {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
}

pub fn text(str: [*]const User(u8), len: usize, x: i32, y: i32) callconv(.C) void {
    _ = str;
    _ = len;
    _ = x;
    _ = y;
}

pub fn vline(x: i32, y: i32, len: u32) callconv(.C) void {
    _ = x;
    _ = y;
    _ = len;
}

pub fn hline(x: i32, y: i32, len: u32) callconv(.C) void {
    _ = x;
    _ = y;
    _ = len;
}

pub fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) callconv(.C) void {
    _ = frequency;
    _ = duration;
    _ = volume;
    _ = flags;
}

pub fn trace(str: [*]const User(u8), len: usize) callconv(.C) void {
    _ = str;
    _ = len;
}
