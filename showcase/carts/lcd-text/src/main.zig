/// LCD Text Viewer Cart
///
/// Edit text_blocks below to display any text you want.
/// Use joystick LEFT/RIGHT to switch between blocks.
/// Use UP/DOWN to scale text, and A button to toggle color.
const std = @import("std");
const cart = @import("cart-api");

const FONT_WIDTH: u32 = cart.font_width;
const FONT_HEIGHT: u32 = cart.font_height;

// Edit these blocks to display your own text pages.
const text_blocks = [_][]const u8{
    "\n\n\n\n\n\n\nHello World!",
    "WHAT\nDOES",
    "THAT\nMEAN?",
    "ALSO!",
};

var block_idx: usize = 0;
var last_left = false;
var last_right = false;
var last_up = false;
var last_down = false;
var last_a = false;
var text_scale: u32 = 1;
var use_zig_color = false;

export fn start() void {
    draw_page();
}

export fn update() void {
    const left_pressed = cart.controls.left;
    const right_pressed = cart.controls.right;
    const up_pressed = cart.controls.up;
    const down_pressed = cart.controls.down;
    const a_pressed = cart.controls.a;

    if (left_pressed and !last_left) {
        if (block_idx == 0) {
            block_idx = text_blocks.len - 1;
        } else {
            block_idx -= 1;
        }
        draw_page();
    }

    if (right_pressed and !last_right) {
        block_idx = (block_idx + 1) % text_blocks.len;
        draw_page();
    }

    if (up_pressed and !last_up) {
        if (text_scale < 4) {
            text_scale += 1;
            draw_page();
        }
    }

    if (down_pressed and !last_down) {
        if (text_scale > 1) {
            text_scale -= 1;
            draw_page();
        }
    }

    if (a_pressed and !last_a) {
        use_zig_color = !use_zig_color;
        draw_page();
    }

    last_left = left_pressed;
    last_right = right_pressed;
    last_up = up_pressed;
    last_down = down_pressed;
    last_a = a_pressed;
}

fn draw_page() void {
    cart.rect(.{
        .x = 0,
        .y = 0,
        .width = cart.screen_width,
        .height = cart.screen_height,
        .fill_color = .{ .r = 0, .g = 0, .b = 0 },
    });

    // Main text content
    const text_color = if (use_zig_color)
        cart.DisplayColor{ .r = 30, .g = 41, .b = 4 }
    else
        cart.DisplayColor{ .r = 31, .g = 63, .b = 31 };

    cart.text(.{
        .str = text_blocks[block_idx],
        .x = 30, //@as(i32, @intCast(cart.screen_width / 2)) - @as(i32, @intCast((FONT_WIDTH * text_scale * text_blocks[block_idx].len) / 2)),
        .y = 0,
        .scale = text_scale,
        .text_color = text_color,
    });
}
