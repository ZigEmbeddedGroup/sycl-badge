/// LCD Text Viewer Cart
///
/// Edit text_blocks below to display any text you want.
const cart = @import("cart-api");
comptime {
    cart.export_start_code();
}

const MIN_CHAR: u8 = 33;
const MAX_CHAR: u8 = 127;
const CHARACTER_SET_SIZE: u8 = MAX_CHAR - MIN_CHAR;

const FONT_WIDTH: u8 = @as(u8, @intCast(cart.font_width));
const FONT_HEIGHT: u8 = @as(u8, @intCast(cart.font_height));

const LCD_WIDTH_PIXELS: u8 = @as(u8, @intCast(cart.screen_width));
const LCD_HEIGHT_PIXELS: u8 = @as(u8, @intCast(cart.screen_height));

const CHAR_WIDTH: u8 = LCD_WIDTH_PIXELS / FONT_WIDTH;
const CHAR_HEIGHT: u8 = LCD_HEIGHT_PIXELS / FONT_HEIGHT;

const TEXT_COLOR = cart.DisplayColor{ .r = 31, .g = 63, .b = 31 };

const TEXT_SCALE: u32 = 1;

pub fn start() void {
    draw_page();
}

pub fn update() void {
    draw_page();
}

fn get_character(idx: u32) u8 {
    return MIN_CHAR + @as(u8, @intCast(@mod(idx, CHARACTER_SET_SIZE)));
}

fn draw_page() void {
    // Blank the page
    cart.rect(.{
        .x = 0,
        .y = 0,
        .width = cart.screen_width,
        .height = cart.screen_height,
        .fill_color = .{ .r = 0, .g = 0, .b = 0 },
    });

    // Main text content
    // cart.DisplayColor{ .r = 31, .g = 63, .b = 31 };

    var character = [1]u8{0};

    var character_idx: u32 = 0;
    var y: i32 = 0;
    var x: i32 = 0;

    for (0..CHAR_HEIGHT) |yc| {
        for (0..CHAR_WIDTH) |xc| {
            character[0] = get_character(character_idx);
            y = @intCast(yc * FONT_HEIGHT);
            x = @intCast(xc * FONT_WIDTH);
            cart.text(.{
                .str = &character,
                .x = x,
                .y = y,
                .scale = TEXT_SCALE,
                .text_color = TEXT_COLOR,
            });
            character_idx += 1;
        }
    }
}
