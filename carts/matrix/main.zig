/// LCD Text Viewer Cart
///
/// Edit text_blocks below to display any text you want.
const cart = @import("cart-api");
const std = @import("std");

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

const TEXT_COLOR = cart.DisplayColor{ .r = 0, .g = 32, .b = 0 };

// out of 256, what is the chance that a cursor randomly resets while
// drawing a line
const RESET_CHANCE: u8 = 30;

const TEXT_SCALE: u32 = 1;

const Cursor = struct {
    x: u8,
    y: u8,
    is_draw: bool,
};

const cursor_count = 3;
var cursors: [cursor_count]Cursor = undefined;

var prng: std.Random.DefaultPrng = undefined;
var random: std.Random = undefined;

// Space character is empty
const EMPTY = 32;

var characters: [CHAR_HEIGHT][CHAR_WIDTH]u8 = undefined;

fn cursor_reset(idx: usize) void {
    cursors[idx] = Cursor{
        .x = random.uintLessThan(u8, CHAR_WIDTH),
        .y = 0,
        .is_draw = random.boolean(),
    };
}

fn get_random_character() u8 {
    return MIN_CHAR + @as(u8, random.intRangeAtMost(u8, 1, CHARACTER_SET_SIZE));
}

pub fn start() void {
    prng = std.Random.DefaultPrng.init(cart.rand());
    random = prng.random();

    // reset all cursors (which draw or erase characters)
    for (0..cursor_count) |cursor_idx| {
        cursor_reset(cursor_idx);
    }

    // blank out the screen
    for (0..CHAR_HEIGHT) |yc| {
        for (0..CHAR_WIDTH) |xc| {
            characters[yc][xc] = EMPTY;
        }
    }

    draw_page();
}

pub fn update() void {
    // advance all cursors
    for (0..cursor_count) |cursor_idx| {
        const should_reset = random.int(u8) < RESET_CHANCE;
        if (should_reset) {
            cursor_reset(cursor_idx);
        } else {
            const c = &cursors[cursor_idx];
            if (c.y < CHAR_HEIGHT) {
                if (c.is_draw) {
                    characters[c.y][c.x] = get_random_character();
                } else {
                    characters[c.y][c.x] = EMPTY;
                }
                c.y = c.y + 1;
            }
        }
    }
    draw_page();
}

fn get_character(idx: i8) u8 {
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

    var y: i32 = 0;
    const x: i32 = 0; // we're always drawing the str at left

    for (0..CHAR_HEIGHT) |yc| {
        y = @intCast(yc * FONT_HEIGHT);
        cart.text(.{
            .str = &characters[yc],
            .x = x,
            .y = y,
            .scale = TEXT_SCALE,
            .text_color = TEXT_COLOR,
        });
    }
}
