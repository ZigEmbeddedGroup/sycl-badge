const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const audio = board.audio;
const timer = microzig.hal.timer;
pub const api = @import("../cart/api.zig");

const libcart = struct {
    extern var cart_data_start: u8;
    extern var cart_data_end: u8;
    extern var cart_bss_start: u8;
    extern var cart_bss_end: u8;
    extern const cart_data_load_start: u8;

    extern fn start() void;
    extern fn update() void;
    extern fn __return_thunk__() noreturn;
};

pub fn svcall_handler() callconv(.Naked) void {
    asm volatile (
        \\ mvns r0, lr, lsl #31 - 2
        \\ bcc 12f
        \\ ite mi
        \\ movmi r1, sp
        \\ mrspl r1, psp
        \\ ldr r2, [r1, #6 * 4]
        \\ subs r2, #2
        \\ ldrb r3, [r2, #1 * 1]
        \\ cmp r3, #0xDF
        \\ bne 12f
        \\ ldrb r3, [r2, #0 * 1]
        \\ cmp r3, #11
        \\ bhi 12f
        \\ tbb [pc, r3]
        \\0:
        \\ .byte (0f - 0b) / 2
        \\ .byte (1f - 0b) / 2
        \\ .byte (2f - 0b) / 2
        \\ .byte (3f - 0b) / 2
        \\ .byte (4f - 0b) / 2
        \\ .byte (5f - 0b) / 2
        \\ .byte (6f - 0b) / 2
        \\ .byte (7f - 0b) / 2
        \\ .byte (8f - 0b) / 2
        \\ .byte (9f - 0b) / 2
        \\ .byte (10f - 0b) / 2
        \\12:
        \\ .byte (11f - 0b) / 2
        \\ .byte 0xDE
        \\ .align 1
        \\0:
        \\ ldm r1, {r0-r3}
        \\ b %[blit:P]
        \\1:
        \\ ldm r1, {r0-r3}
        \\ b %[line:P]
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
        \\ ldm r1, {r0-r3}
        \\ b %[hline:P]
        \\6:
        \\ ldm r1, {r0-r3}
        \\ b %[vline:P]
        \\7:
        \\ ldm r1, {r0-r3}
        \\ b %[tone:P]
        \\8:
        \\ ldm r1, {r0-r2}
        \\ b %[read_flash:P]
        \\9:
        \\ ldm r1, {r0-r1}
        \\ b %[write_flash_page:P]
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
          [line] "X" (&line),
          [oval] "X" (&oval),
          [rect] "X" (&rect),
          [text] "X" (&text),
          [hline] "X" (&hline),
          [vline] "X" (&vline),
          [tone] "X" (&tone),
          [read_flash] "X" (&read_flash),
          [write_flash_page] "X" (&write_flash_page),
          [trace] "X" (&trace),
    );
}
pub const HSRAM = struct {
    pub const SIZE: usize = 0x00030000; // 192 kB
    pub const ADDR: *align(SIZE / 3) volatile [SIZE]u8 = @ptrFromInt(0x20000000);
};

pub fn start() void {
    @memset(@as(*[0x19A0]u8, @ptrFromInt(0x20000000)), 0);
    api.neopixels.* = .{
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
    };

    // fill .bss with zeroes
    {
        const bss_start: [*]u8 = @ptrCast(&libcart.cart_bss_start);
        const bss_end: [*]u8 = @ptrCast(&libcart.cart_bss_end);
        const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

        @memset(bss_start[0..bss_len], 0);
    }

    // load .data from flash
    {
        const data_start: [*]u8 = @ptrCast(&libcart.cart_data_start);
        const data_end: [*]u8 = @ptrCast(&libcart.cart_data_end);
        const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
        const data_src: [*]const u8 = @ptrCast(&libcart.cart_data_load_start);

        @memcpy(data_start[0..data_len], data_src[0..data_len]);
    }

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
    frame[5] = @intFromPtr(&libcart.__return_thunk__);
    frame[6] = @intFromPtr(func);
    frame[7] = 1 << 24;
    asm volatile (
        \\ msr psp, %[process_stack]
        \\ svc #11
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

fn blit(
    sprite: [*]const User(u8),
    x: i32,
    y: i32,
    rest: *const extern struct {
        width: User(u32),
        height: User(u32),
        src_x: User(u32),
        src_y: User(u32),
        stride: User(u32),
        flags: User(api.BlitOptions.Flags),
    },
) callconv(.C) void {
    const width = rest.width.load();
    const height = rest.height.load();
    const src_x = rest.src_x.load();
    const src_y = rest.src_y.load();
    const stride = rest.stride.load();
    const flags = rest.flags.load();

    _ = sprite;
    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = src_x;
    _ = src_y;
    _ = stride;
    _ = flags;
}

fn line(
    x1: i32,
    y1: i32,
    x2: i32,
    rest: *const extern struct {
        y2: User(i32),
        color: User(api.DisplayColor),
    },
) callconv(.C) void {
    const y2 = rest.y2.load();
    const color = rest.color.load();

    _ = x1;
    _ = y1;
    _ = x2;
    _ = y2;
    _ = color;
}

fn oval(
    x: i32,
    y: i32,
    width: u32,
    rest: *const extern struct {
        height: User(u32),
        stroke_color: User(api.DisplayColor.Optional),
        fill_color: User(api.DisplayColor.Optional),
    },
) callconv(.C) void {
    const height = rest.height.load();
    const stroke_color = rest.stroke_color.load();
    const fill_color = rest.fill_color.load();

    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = stroke_color;
    _ = fill_color;
}

fn rect(
    x: i32,
    y: i32,
    width: u32,
    rest: *const extern struct {
        height: User(u32),
        stroke_color: User(api.DisplayColor.Optional),
        fill_color: User(api.DisplayColor.Optional),
    },
) callconv(.C) void {
    const height = rest.height.load();
    const stroke_color = rest.stroke_color.load();
    const fill_color = rest.fill_color.load();

    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = stroke_color;
    _ = fill_color;
}

fn text(
    str_ptr: [*]const User(u8),
    str_len: usize,
    x: i32,
    rest: *const extern struct {
        y: User(i32),
        text_color: User(api.DisplayColor.Optional),
        background_color: User(api.DisplayColor.Optional),
    },
) callconv(.C) void {
    const str = str_ptr[0..str_len];
    const y = rest.y.load();
    const text_color = rest.text_color.load();
    const background_color = rest.background_color.load();

    _ = str;
    _ = x;
    _ = y;
    _ = text_color;
    _ = background_color;
}

fn hline(
    x: i32,
    y: i32,
    len: u32,
    color: api.DisplayColor,
) callconv(.C) void {
    _ = x;
    _ = y;
    _ = len;
    _ = color;
}

fn vline(
    x: i32,
    y: i32,
    len: u32,
    color: api.DisplayColor,
) callconv(.C) void {
    _ = x;
    _ = y;
    _ = len;
    _ = color;
}

fn tone(
    frequency: u32,
    duration: u32,
    volume: u32,
    flags: api.ToneOptions.Flags,
) callconv(.C) void {
    const start_frequency: u16 = @truncate(frequency >> 0);
    const end_frequency = switch (@as(u16, @truncate(frequency >> 16))) {
        0 => start_frequency,
        else => |end_frequency| end_frequency,
    };
    const sustain_time: u8 = @truncate(duration >> 0);
    const release_time: u8 = @truncate(duration >> 8);
    const decay_time: u8 = @truncate(duration >> 16);
    const attack_time: u8 = @truncate(duration >> 24);
    const total_time = @as(u10, attack_time) + decay_time + sustain_time + release_time;
    const sustain_volume: u8 = @truncate(volume >> 0);
    const peak_volume = switch (@as(u8, @truncate(volume >> 8))) {
        0 => 100,
        else => |attack_volume| attack_volume,
    };

    var state: audio.Channel = .{
        .duty = 0,
        .phase = 0,
        .phase_step = 0,
        .phase_step_step = 0,

        .duration = 0,
        .attack_duration = 0,
        .decay_duration = 0,
        .sustain_duration = 0,
        .release_duration = 0,

        .volume = 0,
        .volume_step = 0,
        .peak_volume = 0,
        .sustain_volume = 0,
        .attack_volume_step = 0,
        .decay_volume_step = 0,
        .release_volume_step = 0,

        .function = @enumFromInt(@intFromEnum(flags.function)),
    };

    const start_phase_step = @mulWithOverflow((1 << 32) / 44100, @as(u31, start_frequency));
    const end_phase_step = @mulWithOverflow((1 << 32) / 44100, @as(u31, end_frequency));
    if (start_phase_step[1] != 0 or end_phase_step[1] != 0) return;
    state.phase_step = start_phase_step[0];
    state.phase_step_step = @divTrunc(@as(i32, end_phase_step[0]) - start_phase_step[0], @as(u20, total_time) * @divExact(44100, 60));

    state.attack_duration = @as(u18, attack_time) * @divExact(44100, 60);
    state.decay_duration = @as(u18, decay_time) * @divExact(44100, 60);
    state.sustain_duration = @as(u18, sustain_time) * @divExact(44100, 60);
    state.release_duration = @as(u18, release_time) * @divExact(44100, 60);

    state.peak_volume = @as(u29, peak_volume) << 21;
    state.sustain_volume = @as(u29, sustain_volume) << 21;
    if (state.attack_duration > 0) {
        state.attack_volume_step = @divTrunc(@as(i32, state.peak_volume) - 0, state.attack_duration);
    }
    if (state.decay_duration > 0) {
        state.decay_volume_step = @divTrunc(@as(i32, state.sustain_volume) - state.peak_volume, state.decay_duration);
    }
    if (state.release_duration > 0) {
        state.release_volume_step = @divTrunc(@as(i32, 0) - state.sustain_volume, state.release_duration);
    }

    switch (flags.function) {
        .pulse1, .pulse2 => {
            state.duty = switch (flags.duty_cycle) {
                .@"1/8" => (1 << 32) / 8,
                .@"1/4" => (1 << 32) / 4,
                .@"1/2" => (1 << 32) / 2,
                .@"3/4" => (3 << 32) / 4,
            };
        },
        else => {},
    }

    audio.set_channel(flags.channel, state);
}

fn read_flash(
    offset: u32,
    dst_ptr: [*]User(u8),
    dst_len: usize,
) callconv(.C) u32 {
    const dst = dst_ptr[0..dst_len];

    _ = offset;
    _ = dst;

    return 0;
}

fn write_flash_page(
    page: u16,
    src: *const [api.flash_page_size]User(u8),
) callconv(.C) void {
    _ = page;
    _ = src;
}

fn trace(
    str_ptr: [*]const User(u8),
    str_len: usize,
) callconv(.C) void {
    const str = str_ptr[0..str_len];

    _ = str;
}
