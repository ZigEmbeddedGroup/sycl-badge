const std = @import("std");
const cart = @import("cart-api");

export fn start() void {}

var green_565: u6 = 0;

var offset: u16 = 0;

fn read_stored_number() u64 {
    var dst: u64 = undefined;
    std.debug.assert(cart.read_flash(0, std.mem.asBytes(&dst)) == @sizeOf(u64));
    return dst;
}

fn write_stored_number(number: u64) void {
    var page: [cart.flash_page_size]u8 = undefined;
    std.mem.bytesAsSlice(u64, &page)[0] = number;
    cart.write_flash_page(0, page);
}

export fn update() void {
    if (offset % (60 * 2) == 0) {
        cart.tone(.{
            .frequency = 440,
            .duration = 20,
            .volume = 10,
            .flags = .{
                .channel = .pulse1,
                .duty_cycle = .@"1/8",
                .panning = .left,
            },
        });
    }

    offset +%= 1;

    var inputs_buf: [128]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&inputs_buf);

    // ENABLE AT YOUR OWN RISK
    // fbs.writer().print("{d}\n", .{read_stored_number()}) catch unreachable;

    inline for (std.meta.fields(cart.Controls)) |control| {
        if (comptime !std.mem.eql(u8, control.name, "padding")) {
            if (@field(cart.controls.*, control.name)) {
                fbs.writer().writeAll(control.name) catch unreachable;
                fbs.writer().writeAll("\n") catch unreachable;
            }
        }
    }

    if (cart.controls.up) {
        green_565 +%= 1;
    } else if (cart.controls.down) {
        green_565 -%= 1;
    }

    // if (cart.controls.left) {
    //     write_stored_number(read_stored_number() -| 1);
    // } else if (cart.controls.right) {
    //     write_stored_number(read_stored_number() +| 1);
    // }

    cart.red_led.* = cart.controls.click;

    for (0..cart.screen_height) |y| {
        for (0..cart.screen_width) |x| {
            cart.framebuffer[y * cart.screen_width + x] = .{
                .r = @intFromFloat(@as(f32, @floatFromInt(x)) / cart.screen_width * 31),
                .g = green_565,
                .b = @intFromFloat(@as(f32, @floatFromInt(y)) / cart.screen_height * 31),
            };
        }
    }

    for (cart.neopixels, 0..) |*np, i| {
        np.* = .{
            .r = @intFromFloat(@as(f32, @floatFromInt(i)) / 5 * 20),
            .g = @intFromFloat(@as(f32, @floatFromInt(cart.light_level.*)) / std.math.maxInt(u12) * 20),
            .b = @intFromFloat(@as(f32, @floatFromInt(i)) / 5 * 20),
        };
    }

    cart.blit(.{
        .sprite = &.{
            .{ .r = 31, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 31 },
            .{ .r = 31, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 31 },
        },
        .x = 40,
        .y = 40,
        .width = 2,
        .height = 2,
        .flags = .{},
    });

    cart.line(.{
        .x1 = 50,
        .y1 = 50,
        .x2 = 70,
        .y2 = 70,
        .color = .{ .r = 0, .g = 63, .b = 0 },
    });

    cart.hline(.{
        .x = 30,
        .y = 30,
        .len = 20,
        .color = .{ .r = 31, .g = 0, .b = 0 },
    });

    cart.vline(.{
        .x = 30,
        .y = 30,
        .len = 20,
        .color = .{ .r = 31, .g = 0, .b = 0 },
    });

    cart.oval(.{
        .x = 80,
        .y = 80,
        .width = 10,
        .height = 10,
        .stroke_color = .{ .r = 0, .g = 0, .b = 31 },
        .fill_color = .{ .r = 31, .g = 0, .b = 31 },
    });

    cart.rect(.{
        .x = 100,
        .y = 100,
        .width = 10,
        .height = 10,
        .stroke_color = .{ .r = 31, .g = 31, .b = 31 },
        .fill_color = .{ .r = 0, .g = 63, .b = 31 },
    });

    cart.text(.{
        .str = fbs.getWritten(),
        .x = 0,
        .y = 0,
        .text_color = .{ .r = 0, .g = 0, .b = 0 },
        .background_color = .{ .r = 31, .g = 63, .b = 31 },
    });

    cart.text(.{
        .str = "\x80\x81\x82\x83\x84\x85\x86\x87\x88",
        .x = 0,
        .y = 120,
        .text_color = .{ .r = 0, .g = 0, .b = 0 },
        .background_color = .{ .r = 31, .g = 63, .b = 31 },
    });
}
