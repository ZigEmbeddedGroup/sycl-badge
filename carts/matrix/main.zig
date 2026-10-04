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

// a fully boosted character glows this color: almost white, tinted green
const BOOST_COLOR = cart.DisplayColor{ .r = 26, .g = 63, .b = 26 };

// the boost a freshly drawn character starts with
const BOOST_MAX: u5 = 16;

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

// the name is written vertically, in its own color, by any cursor that
// draws over its spot
const NAME = "NEIL K";
const NAME_COLOR = cart.DisplayColor{ .r = 31, .g = 63, .b = 31 };

// where the top of the name sits on the character grid
var name_x: u8 = undefined;
var name_y: u8 = undefined;

fn name_reset() void {
    // use the column of a random cursor, so the name is likely to be written
    // soon. Prefer cursors that draw, since an erasing one can't write it.
    var chosen = cursors[random.uintLessThan(usize, cursor_count)];
    var draw_count: u8 = 0;
    for (cursors) |cursor| {
        if (!cursor.is_draw) continue;
        // each drawing cursor replaces the choice with probability
        // 1/draw_count, which picks evenly among them
        draw_count += 1;
        if (random.uintLessThan(u8, draw_count) == 0) chosen = cursor;
    }
    name_x = chosen.x;

    // start high enough that the whole name fits on the screen, and at or
    // below the cursor if there's still room there, so it hasn't gone past
    const max_y = CHAR_HEIGHT - NAME.len;
    const min_y = if (chosen.y <= max_y) chosen.y else 0;
    name_y = random.intRangeAtMost(u8, min_y, max_y);
}

// which letter of the name belongs at this position, or null if the
// position is outside the name's spot
fn name_index(x: u8, y: u8) ?usize {
    if (x != name_x or y < name_y or y >= name_y + NAME.len) return null;
    return y - name_y;
}

fn name_erase() void {
    for (0..NAME.len) |i| {
        characters[name_y + i][name_x] = EMPTY_CHAR;
    }
}

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

    // the name's spot depends on where the cursors are
    name_reset();

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
            const c = &cursors[cursor_idx];
            // a drawing cursor in the name's column can't stop until it has
            // drawn the whole name
            const is_writing_name = c.is_draw and c.x == name_x and c.y < name_y + NAME.len;
            const should_reset = !is_writing_name and random.int(u8) < RESET_CHANCE;
            if (should_reset) {
                cursor_reset(cursor_idx);
            } else {
                if (c.y < CHAR_HEIGHT) {
                    if (c.is_draw) {
                        const glowy_char: GlowyChar = if (name_index(c.x, c.y)) |i| .{
                            .c = NAME[i],
                            .base_color = NAME_COLOR,
                            .boost = BOOST_MAX,
                        } else .{
                            .c = get_random_character(),
                            .base_color = BASE_COLOR,
                            .boost = BOOST_MAX,
                        };
                        characters[c.y][c.x] = glowy_char;
                    } else if (name_index(c.x, c.y) != null) {
                        // erasing any part of the name wipes all of it and
                        // moves it somewhere new
                        name_erase();
                        name_reset();
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

// blend one color channel from its base toward the boost color. Boost only
// ever brightens: a channel already at or above the boost color is unchanged.
fn boost_channel(comptime T: type, base: T, target: T, boost: u5) T {
    const range: u16 = target -| base;
    return base + @as(T, @intCast(range * boost / BOOST_MAX));
}

fn get_color(glowy_char: GlowyChar) cart.DisplayColor {
    const base = glowy_char.base_color;
    const boost = glowy_char.boost;
    return cart.DisplayColor{
        .r = boost_channel(u5, base.r, BOOST_COLOR.r, boost),
        .g = boost_channel(u6, base.g, BOOST_COLOR.g, boost),
        .b = boost_channel(u5, base.b, BOOST_COLOR.b, boost),
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
