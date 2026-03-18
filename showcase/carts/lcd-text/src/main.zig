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
const text_blocks = [_][]const u8{ "Hello\nWorld!", "Lanyard!", "THAT\nMEAN?", "ALSO!", "Tiny\nComputer!" };

var block_idx: usize = 0;
var last_left = false;
var last_right = false;
var last_up = false;
var last_down = false;
var last_a = false;
var last_b = false;
var text_scale: u32 = 1;
var use_zig_color = false;
var blink_count: u32 = 0;
var blink_timer: u32 = 0;
const BLINK_FRAME_RATE: u32 = 15; // Adjust to change blink speed

export fn start() void {
    draw_page();
}

export fn update() void {
    const left_pressed = cart.controls.left;
    const right_pressed = cart.controls.right;
    const up_pressed = cart.controls.up;
    const down_pressed = cart.controls.down;
    const a_pressed = cart.controls.a;
    const b_pressed = cart.controls.b;

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

    if (b_pressed and !last_b) {
        blink_count = 10; // 5 blinks = 10 on/off cycles
        blink_timer = 0;
    }

    last_left = left_pressed;
    last_right = right_pressed;
    last_up = up_pressed;
    last_down = down_pressed;
    last_a = a_pressed;
    last_b = b_pressed;

    // Update blink animation
    if (blink_count > 0) {
        blink_timer += 1;
        if (blink_timer >= BLINK_FRAME_RATE) {
            blink_timer = 0;
            blink_count -= 1;
        }
        draw_page_with_blink(blink_count % 2 == 0);
    } else {
        draw_page();
    }
}

fn get_line_width(text: []const u8) u32 {
    var char_count: u32 = 0;
    for (text) |ch| {
        if (ch == '\n') {
            break;
        }
        char_count += 1;
    }
    return char_count * FONT_WIDTH * text_scale;
}

fn count_lines(text: []const u8) u32 {
    var line_count: u32 = 1;
    for (text) |ch| {
        if (ch == '\n') {
            line_count += 1;
        }
    }
    return line_count;
}

fn get_line(text: []const u8, line_idx: u32) []const u8 {
    var current_line: u32 = 0;
    var start_idx: usize = 0;

    for (text, 0..) |ch, i| {
        if (ch == '\n') {
            if (current_line == line_idx) {
                return text[start_idx..i];
            }
            current_line += 1;
            start_idx = i + 1;
        }
    }

    if (current_line == line_idx) {
        return text[start_idx..];
    }

    return "";
}

fn draw_page() void {
    draw_page_with_blink(true);
}

fn draw_page_with_blink(show_text: bool) void {
    cart.rect(.{
        .x = 0,
        .y = 0,
        .width = cart.screen_width,
        .height = cart.screen_height,
        .fill_color = .{ .r = 0, .g = 0, .b = 0 },
    });

    if (show_text) {
        // Main text content
        const text_color = if (use_zig_color)
            cart.DisplayColor{ .r = 30, .g = 41, .b = 4 }
        else
            cart.DisplayColor{ .r = 31, .g = 63, .b = 31 };

        const text = text_blocks[block_idx];
        const num_lines = count_lines(text);
        const total_height = num_lines * FONT_HEIGHT * text_scale;
        const start_y = @as(i32, @intCast(cart.screen_height / 2)) - @as(i32, @intCast(total_height / 2));

        var line_idx: u32 = 0;
        while (line_idx < num_lines) : (line_idx += 1) {
            const line = get_line(text, line_idx);
            const line_width_px = line.len * FONT_WIDTH * text_scale;
            const line_x = @as(i32, @intCast(cart.screen_width / 2)) - @as(i32, @intCast(line_width_px / 2));

            cart.text(.{
                .str = line,
                .x = line_x,
                .y = start_y + @as(i32, @intCast(line_idx * FONT_HEIGHT * text_scale)),
                .scale = text_scale,
                .text_color = text_color,
            });
        }
    }
}
