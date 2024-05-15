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

fn point(x: usize, y: usize, color: api.DisplayColor) void {
    api.framebuffer[y * api.screen_width + x] = color;
}

fn pointUnclipped(x: i32, y: i32, color: api.DisplayColor) void {
    if (x >= 0 and x < api.screen_width and y >= 0 and y < api.screen_height) {
        point(@intCast(x), @intCast(y), color);
    }
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

    var x1_moving = x1;
    var y1_adjusted, const y2_adjusted = if (y1 > y2)
        .{ y2, y1 }
    else
        .{ y1, y2 };

    const dx: i32 = @intCast(@abs(x2 - x1_moving));
    const sx: i32 = if (x1_moving < x2) 1 else -1;
    const dy = y2_adjusted - y1_adjusted;
    var err: i32 = @divTrunc(if (dx > dy) dx else -dy, 2);
    var e2: i32 = 0;

    while (true) {
        pointUnclipped(x1_moving, y1_adjusted, color);

        if (x1_moving == x2 and y1_adjusted == y2_adjusted) {
            break;
        }
        e2 = err;
        if (e2 > -dx) {
            err -= dy;
            x1_moving += sx;
        }
        if (e2 < dy) {
            err += dx;
            y1_adjusted += 1;
        }
    }
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

    const signed_width: i32 = @intCast(width);
    const signed_height: i32 = @intCast(height);

    var a = signed_width - 1;
    const b = signed_height - 1;
    var b1 = @rem(b, 2); // Compensates for precision loss when dividing

    var north = y + @divFloor(signed_height, 2); // Precision loss here
    var west = x;
    var east = x + signed_width - 1;
    var south = north - b1; // Compensation here. Moves the bottom line up by
    // one (overlapping the top line) for even heights

    const a2 = a * a;
    const b2 = b * b;

    // Error increments. Also known as the decision parameters
    var dx = 4 * (1 - a) * b2;
    var dy = 4 * (b1 + 1) * a2;

    // Error of 1 step
    var err = dx + dy + b1 * a2;

    a = 8 * a2;
    b1 = 8 * b2;

    while (true) {
        if (stroke_color.unwrap()) |sc| {
            pointUnclipped(east, north, sc); // I. Quadrant
            pointUnclipped(west, north, sc); // II. Quadrant
            pointUnclipped(west, south, sc); // III. Quadrant
            pointUnclipped(east, south, sc); // IV. Quadrant
        }

        const oval_start = west + 1;
        const len = east - oval_start;

        if (fill_color != .none and len > 0) { // Only draw fill if the length from west to east is not 0
            hline(oval_start, north, @intCast(east - oval_start), fill_color.unwrap().?); // I and III. Quadrant
            hline(oval_start, south, @intCast(east - oval_start), fill_color.unwrap().?); // II and IV. Quadrant
        }

        const err2 = 2 * err;

        if (err2 <= dy) {
            // Move vertical scan
            north += 1;
            south -= 1;
            dy += a;
            err += dy;
        }

        if (err2 >= dx or err2 > dy) {
            // Move horizontal scan
            west += 1;
            east -= 1;
            dx += b1;
            err += dx;
        }

        if (!(west <= east)) break;
    }

    if (stroke_color.unwrap()) |sc| {
        // Make sure north and south have moved the entire way so top/bottom aren't missing
        while (north - south < signed_height) {
            pointUnclipped(west - 1, north, sc); // II. Quadrant
            pointUnclipped(east + 1, north, sc); // I. Quadrant
            north += 1;
            pointUnclipped(west - 1, south, sc); // III. Quadrant
            pointUnclipped(east + 1, south, sc); // IV. Quadrant
            south -= 1;
        }
    }
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
    const stroke_color = rest.stroke_color.load().unwrap();
    const fill_color = rest.fill_color.load().unwrap();

    if (stroke_color) |sc| {
        hline(x, y, width, sc);
        hline(x, y + @as(i32, @intCast(height)), width + 1, sc);

        vline(x, y, height, sc);
        vline(x + @as(i32, @intCast(width)), y, height, sc);
    }

    if (fill_color) |fc| {
        for (@as(u32, @intCast(y)) + 1..@as(u32, @intCast(y)) + height) |yy| {
            hline(x + 1, @intCast(yy), width - 1, fc);
        }
    }
}

const font = @import("font.zig").font;

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
    // const str = str_ptr[0].load();
    const y = rest.y.load();
    const text_color = rest.text_color.load();
    const background_color = rest.background_color.load();

    const colors = &[_]api.DisplayColor.Optional{ text_color, background_color };

    var char_x_offset = x;
    var char_y_offset = y;

    for (0..str_len) |char_idx| {
        const char = str_ptr[char_idx].load();

        if (char == 10) {
            char_y_offset += 8;
            char_x_offset = x;
        } else if (char >= 32 and char <= 255) {
            const base = (@as(usize, char) - 32) * 64;
            for (0..8) |y_offset| {
                const dst_y = char_y_offset + @as(i32, @intCast(y_offset));
                for (0..8) |x_offset| {
                    const dst_x = char_x_offset + @as(i32, @intCast(x_offset));

                    const color = colors[std.mem.readPackedIntNative(u1, &font, base + y_offset * 8 + (7 - x_offset))];
                    if (color.unwrap()) |dc| {
                        // TODO: this is slow; check bounds once instead
                        pointUnclipped(dst_x, dst_y, dc);
                    }
                }
            }

            char_x_offset += 8;
        } else {
            char_x_offset += 8;
        }
    }
}

fn hline(
    x: i32,
    y: i32,
    len: u32,
    color: api.DisplayColor,
) callconv(.C) void {
    if (y < 0 or y >= api.screen_height) return;

    const clamped_x: u32 = @intCast(std.math.clamp(x, 0, @as(i32, @intCast(api.screen_width - 1))));
    const clamped_len = @min(clamped_x + len, api.screen_width) - clamped_x;

    const y_offset = api.screen_width * @as(u32, @intCast(y));
    @memset(api.framebuffer[y_offset + clamped_x ..][0..clamped_len], color);
}

fn vline(
    x: i32,
    y: i32,
    len: u32,
    color: api.DisplayColor,
) callconv(.C) void {
    if (y + @as(i32, @intCast(len)) <= 0 or x < 0 or x >= @as(i32, @intCast(api.screen_width))) return;

    const start_y: u32 = @intCast(@max(0, y));
    const end_y: u32 = @intCast(@min(api.screen_height, y + @as(i32, @intCast(len))));

    for (start_y..end_y) |yy| {
        point(@intCast(x), yy, color);
    }
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

    switch (flags.channel) {
        .pulse1, .pulse2 => {
            state.duty = switch (flags.duty_cycle) {
                .@"1/8" => (1 << 32) / 8,
                .@"1/4" => (1 << 32) / 4,
                .@"1/2" => (1 << 32) / 2,
                .@"3/4" => (3 << 32) / 4,
            };
        },
        .triangle => {
            state.duty = (1 << 32) / 2;
        },
        .noise => {
            state.duty = (1 << 32) / 2;
        },
    }

    audio.set_channel(@intFromEnum(flags.channel), state);
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
