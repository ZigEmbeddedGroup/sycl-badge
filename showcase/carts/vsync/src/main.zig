const cart = @import("cart-api");
const std = @import("std");

comptime {
    cart.export_start_code();
}

const min_ms = 10; // 100 FPS
const max_ms = 100; // 10 FPS
const speed = 4.0;

var target_ms: f32 = min_ms;
var last_time: u64 = 0;
var dirty_frames: u32 = 2;

pub fn start() void {
    last_time = cart.micros_since_boot();

    // Update the whole screen every frame, without copying
    // changes between frames.
    cart.setDoubleBufferMode(.no_copy_full_frame);

    // Start with vsync disabled
    cart.setVsyncDisabled();

    // Set the two buffers to all black and all white. Tearing lines will show clearly in the LCD.
    @memset(@as(*[cart.screen_width * cart.screen_height]u16, @ptrCast(cart.framebuffer)), 0);
    @memset(@as(*[cart.screen_width * cart.screen_height]u16, @ptrCast(cart.frontbuffer)), 0xFFFF);
}

pub fn update() void {
    const time = cart.micros_since_boot();
    defer last_time = time;

    const delta_sec = @as(f32, @floatFromInt(time - last_time)) * 0.000001;

    var changed = false;
    const controls = cart.controls;
    if (controls.left and target_ms != min_ms) {
        target_ms -= delta_sec * speed;
        target_ms = @max(target_ms, min_ms);
        changed = true;
    }
    if (controls.right and target_ms != max_ms) {
        target_ms += delta_sec * speed;
        target_ms = @min(target_ms, max_ms);
        changed = true;
    }

    if (changed) {
        if (target_ms == min_ms) {
            cart.setVsyncDisabled();
        } else {
            cart.setVsyncEnabled(target_ms);
        }

        dirty_frames = 2;
    }

    if (dirty_frames > 0) {
        const inv_color: cart.DisplayColor = if (cart.framebufferIndex() == 0) @bitCast(@as(u16, 0xFFFF)) else @bitCast(@as(u16, 0x0000));
        const max_len = "100.0 mS".len;
        const max_width = max_len * 8;
        const max_height = 8;
        const border = 2;
        cart.rect(.{
            .x = @intCast(cart.screen_width / 2 - max_width / 2 - border),
            .y = @intCast(cart.screen_height / 2 - max_height / 2 - border),
            .width = max_width + 2 * border,
            .height = max_height + 2 * border,
            .fill_color = inv_color,
        });

        const ms_dec_int: u32 = @intFromFloat(target_ms * 10 + 0.5);
        var text_buf: [max_len]u8 = undefined;
        const text = if (target_ms == min_ms) "off >" else std.fmt.bufPrint(&text_buf, "{d}.{d} mS", .{ ms_dec_int / 10, ms_dec_int % 10 }) catch "panik";
        const text_width = text.len * 8;
        cart.text(.{
            .str = text,
            .x = @intCast(cart.screen_width / 2 - text_width / 2),
            .y = @intCast(cart.screen_height / 2 - 8 / 2),
            .text_color = .rgb(0x7F00FF),
        });

        dirty_frames -= 1;
    }
}

fn render_frame() void {}
