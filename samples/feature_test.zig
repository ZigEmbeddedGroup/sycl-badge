const std = @import("std");
const wasm4 = @import("wasm4");

export fn start() void {}

var green_565: u6 = 0;

var offset: u16 = 0;

fn read_stored_number() u64 {
    var dst: u64 = undefined;
    std.debug.assert(wasm4.read_flash(0, std.mem.asBytes(&dst)) == @sizeOf(u64));
    return dst;
}

fn write_stored_number(number: u64) void {
    var page: [wasm4.flash_page_size]u8 = undefined;
    // @as(*u64, @alignCast(@ptrCast(page[0..8]))).* = number;
    std.mem.bytesAsSlice(u64, &page)[0] = number;
    wasm4.write_flash_page(0, page);
}

export fn update() void {
    if (offset % (60 * 2) == 0) {
        wasm4.tone(440, 20, 10, .{
            .channel = .pulse1,
            .duty_cycle = .@"1/8",
            .panning = .left,
        });
    }

    offset +%= 1;

    var inputs_buf: [128]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&inputs_buf);

    fbs.writer().print("{d}\n", .{read_stored_number()}) catch unreachable;

    inline for (std.meta.fields(wasm4.Controls)) |control| {
        if (comptime !std.mem.eql(u8, control.name, "padding")) {
            if (@field(wasm4.controls.*, control.name)) {
                fbs.writer().writeAll(control.name) catch unreachable;
                fbs.writer().writeAll("\n") catch unreachable;
            }
        }
    }

    if (wasm4.controls.up) {
        green_565 +%= 1;
    } else if (wasm4.controls.down) {
        green_565 -%= 1;
    }

    if (wasm4.controls.left) {
        write_stored_number(read_stored_number() -| 1);
    } else if (wasm4.controls.right) {
        write_stored_number(read_stored_number() +| 1);
    }

    wasm4.red_led.* = wasm4.controls.click;

    for (0..wasm4.screen_height) |y| {
        for (0..wasm4.screen_width) |x| {
            wasm4.framebuffer[y * wasm4.screen_width + x] = .{
                .red = @intFromFloat(@as(f32, @floatFromInt(x)) / wasm4.screen_width * 31),
                .green = green_565,
                .blue = @intFromFloat(@as(f32, @floatFromInt(y)) / wasm4.screen_height * 31),
            };
        }
    }

    for (wasm4.neopixels, 0..) |*np, i| {
        np.* = .{
            .red = @intFromFloat(@as(f32, @floatFromInt(i)) / 5 * 255),
            .green = @intFromFloat(@as(f32, @floatFromInt(wasm4.light_level.*)) / std.math.maxInt(u12) * 255),
            .blue = @intFromFloat(@as(f32, @floatFromInt(i)) / 5 * 255),
        };
    }

    // TODO: blit, blitSub

    wasm4.line(.{ .red = 0, .green = 63, .blue = 0 }, 50, 50, 70, 70);

    wasm4.hline(.{ .red = 31, .green = 0, .blue = 0 }, 30, 30, 20);
    wasm4.vline(.{ .red = 31, .green = 0, .blue = 0 }, 30, 30, 20);

    wasm4.oval(.{ .red = 0, .green = 0, .blue = 31 }, .{ .red = 31, .green = 0, .blue = 31 }, 80, 80, 10, 10);
    wasm4.rect(.{ .red = 31, .green = 31, .blue = 31 }, .{ .red = 0, .green = 63, .blue = 31 }, 100, 100, 10, 10);

    wasm4.text(.{ .red = 0, .green = 0, .blue = 0 }, .{ .red = 31, .green = 63, .blue = 31 }, fbs.getWritten(), 0, 0);
}
