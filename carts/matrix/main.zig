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

const BASE_COLOR = cart.DisplayColor{ .r = 0, .g = 32, .b = 0 };

// out of 256, what is the chance that a cursor randomly resets while
// drawing a line
const RESET_CHANCE: u8 = 30;

const TEXT_SCALE: u32 = 1;

const Cursor = struct {
    x: u8,
    y: u8,
    is_draw: bool,
};

const GlowyChar: type = struct {
    c: u8,
    base_color: cart.DisplayColor,
    boost: u5,
};

const cursor_count = 3;
var cursors: [cursor_count]Cursor = undefined;

var prng: std.Random.DefaultPrng = undefined;
var random: std.Random = undefined;

// Space character is empty
const EMPTY = 32;
const EMPTY_CHAR: GlowyChar = .{
    .c = EMPTY,
    .base_color = BASE_COLOR,
    .boost = 0,
};

var characters: [CHAR_HEIGHT][CHAR_WIDTH]GlowyChar = undefined;

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
            characters[yc][xc] = EMPTY_CHAR;
        }
    }

    draw_page();
}

pub fn decrease_boosts() void {
    for (0..CHAR_HEIGHT) |yc| {
        for (0..CHAR_WIDTH) |xc| {
            const boost = characters[yc][xc].boost;
            if (boost > 0) {
                characters[yc][xc].boost = boost - 1;
            }
        }
    }
}

// how long between cursor steps: 500ms = 2 per second
const STEP_MICROS: u64 = 130_000;
var next_step_time: u64 = 0;

// how long between boost decreases
const BOOST_STEP_MICROS: u64 = 50_000;
var next_boost_time: u64 = 0;

pub fn update() void {
    const now = cart.micros_since_boot();
    if (now >= next_boost_time) {
        next_boost_time = now + BOOST_STEP_MICROS;
        decrease_boosts();
    }
    if (now >= next_step_time) {
        next_step_time = now + STEP_MICROS;

        // advance all cursors
        for (0..cursor_count) |cursor_idx| {
            const should_reset = random.int(u8) < RESET_CHANCE;
            if (should_reset) {
                cursor_reset(cursor_idx);
            } else {
                const c = &cursors[cursor_idx];
                if (c.y < CHAR_HEIGHT) {
                    if (c.is_draw) {
                        const glowy_char: GlowyChar = .{
                            .c = get_random_character(),
                            .base_color = BASE_COLOR,
                            .boost = 16,
                        };
                        characters[c.y][c.x] = glowy_char;
                    } else {
                        characters[c.y][c.x] = EMPTY_CHAR;
                    }
                    c.y = c.y + 1;
                }
            }
        }
    }
    draw_page();
}

fn get_character(idx: i8) u8 {
    return MIN_CHAR + @as(u8, @intCast(@mod(idx, CHARACTER_SET_SIZE)));
}

fn get_color(glowy_char: GlowyChar) cart.DisplayColor {
    const base = glowy_char.base_color;
    const boost = glowy_char.boost;
    // saturate, so a bright base color can't overflow its channel
    return cart.DisplayColor{
        .r = base.r +| boost,
        .g = base.g +| boost,
        .b = base.b +| boost,
    };
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
    var x: i32 = 0;

    for (0..CHAR_HEIGHT) |yc| {
        y = @intCast(yc * FONT_HEIGHT);
        for (0..CHAR_WIDTH) |xc| {
            x = @intCast(xc * FONT_WIDTH);
            const text_color = get_color(characters[yc][xc]);
            cart.text(.{
                .str = (&characters[yc][xc].c)[0..1],
                .x = x,
                .y = y,
                .scale = TEXT_SCALE,
                .text_color = text_color,
            });
        }
    }
}
