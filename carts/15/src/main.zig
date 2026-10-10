/// The cart module contains utilities for interacting
/// with the badge. Check src/os/cart/api.zig for details!
const cart = @import("cart-api");
const std = @import("std");

const josh: cart.Framebuffer = @import("josh.zon");

// This block exports the hooks that the platform
// (either the badge OS or the simulator)
// will use to start the cart.
comptime {
    cart.export_start_code();
}

pub const Tile = union(enum) {
    // 0-3 on background x
    // 0-3 on background y
    empty: BGCoords,
    full: BGCoords,

    pub const BGCoords = struct {
        x: u2,
        y: u2,
    };
};

pub const Game = struct {
    state: enum {
        // show title screen
        title,
        // show board
        play,
    } = .title,

    board: Board = .solved,

    pub const Board = struct {
        tiles: [4][4]Tile,
        const solved: Board = .{
            .tiles = .{
                // x = 0
                .{
                    .{ .full = .{ .x = 0, .y = 0 } },
                    .{ .full = .{ .x = 0, .y = 1 } },
                    .{ .full = .{ .x = 0, .y = 2 } },
                    .{ .full = .{ .x = 0, .y = 3 } },
                },
                // x = 1
                .{
                    .{ .full = .{ .x = 1, .y = 0 } },
                    .{ .full = .{ .x = 1, .y = 1 } },
                    .{ .full = .{ .x = 1, .y = 2 } },
                    .{ .full = .{ .x = 1, .y = 3 } },
                },
                // x = 2
                .{
                    .{ .full = .{ .x = 2, .y = 0 } },
                    .{ .full = .{ .x = 2, .y = 1 } },
                    .{ .full = .{ .x = 2, .y = 2 } },
                    .{ .full = .{ .x = 2, .y = 3 } },
                },
                // x = 3
                .{
                    .{ .full = .{ .x = 3, .y = 0 } },
                    .{ .full = .{ .x = 3, .y = 1 } },
                    .{ .full = .{ .x = 3, .y = 2 } },
                    .{ .empty = .{ .x = 3, .y = 3 } },
                },
            },
        };
    };
};

var game: Game = .{};

/// This function runs first, to set up the cart.
pub fn start() void {
    // Run at 60 FPS with vsync
    cart.set_vsync_enabled(1000.0 / 30.0);
    cart.set_double_buffer_mode(.no_copy_full_frame);
}

// for button state edge detection
var prev_start: bool = false;
var prev_right: bool = false;
var prev_left: bool = false;
var prev_up: bool = false;
var prev_down: bool = false;

/// This function is called repeatedly. The screen
/// will be updated every time this function returns.
pub fn update() void {
    // Your code here!

    switch (game.state) {
        .title => {
            drawTitle();
            if (cart.controls.start and !prev_start) {
                game.state = .play;
            }
        },
        .play => {
            drawBoard();
            if (cart.controls.select) {
                drawDebugBoard();
            }

            if (cart.controls.right and !prev_right) {
                doRight();
            }

            if (cart.controls.left and !prev_left) {
                doLeft();
            }

            if (cart.controls.up and !prev_up) {
                doUp();
            }

            if (cart.controls.down and !prev_down) {
                doDown();
            }

            if (cart.controls.a) {
                game.board = .solved;
            }
            if (cart.controls.b) {
                doScramble();
            }
            if (cart.controls.start and !prev_start) {
                game.state = .title;
            }
        },
    }

    prev_start = cart.controls.start;
    prev_right = cart.controls.right;
    prev_left = cart.controls.left;
    prev_up = cart.controls.up;
    prev_down = cart.controls.down;

    // cart.framebuffer.* = josh;
}

pub fn drawTitle() void {
    const logo_color = cart.DisplayColor.rgb(0xFFFFFF);
    const logo_color_inv = cart.DisplayColor.rgb(0x000000);
    cart.rect(.{
        .x = 0,
        .y = 0,
        .width = cart.screen_width,
        .height = cart.screen_height,
        .fill_color = .{ .r = 0, .g = 0, .b = 0 },
    });

    const tile_height: i32 = cart.screen_height / 8;
    const tile_width: i32 = cart.screen_width / 8;
    for (0..4) |x| {
        for (0..4) |y| {
            if (x == 3 and y == 3) {
                continue;
            }
            cart.rect(.{
                .x = @intCast((x + 2) * tile_width),
                .y = @intCast((y + 2) * tile_height),
                .width = tile_width,
                .height = tile_height,
                .fill_color = logo_color,
            });
        }
    }
    if (cart.micros_since_boot() % 1_000_000 > 500_000) {
        cart.text(.{
            .str = "press\nstart",
            .x = 41,
            .y = 31,
            .text_color = logo_color_inv,
            .scale = 1,
        });
    }

    cart.text(.{
        .str = "a: reset",
        .x = 41,
        .y = 49,
        .text_color = logo_color_inv,
        .scale = 1,
    });

    cart.text(.{
        .str = "b: mix",
        .x = 41,
        .y = 58,
        .text_color = logo_color_inv,
        .scale = 1,
    });

    cart.text(.{
        .str = "by jeff",
        .x = 41,
        .y = 87,
        .text_color = .rgb(0xFFA500),
        .scale = 1,
    });

    cart.text(.{
        .str = "15",
        .x = 104,
        .y = 87,
        .text_color = .{ .r = 31, .g = 63, .b = 31 },
        .scale = 1,
    });

    // const bot: i32 = tile_height * 7;
    // const top: i32 = tile_height;
    // const right: i32 = tile_width * 7;
    // const left: i32 = tile_width;
    // cart.hline(.{ .x = left, .y = top, .len = tile_width * 6, .color = logo_color });
    // cart.hline(.{ .x = left, .y = bot, .len = tile_width * 6, .color = logo_color });
    // cart.vline(.{ .x = left, .y = top, .len = tile_height * 6, .color = logo_color });
    // cart.vline(.{ .x = right, .y = top, .len = tile_height * 5, .color = logo_color });
    // cart.hline(.{ .x = tile_width * 5, .y = tile_width * 5, .len = tile_width, .color = logo_color });
}

var rand = std.Random.DefaultPrng.init(42);
pub fn doScramble() void {
    switch (rand.random().int(u32) % 4) {
        0 => doUp(),
        1 => doDown(),
        2 => doRight(),
        3 => doLeft(),
        else => unreachable,
    }
}

pub fn doUp() void {
    for (0..4) |x| {
        for (1..4) |y| {
            if (game.board.tiles[x][y - 1] == .empty) {
                const top = game.board.tiles[x][y - 1];
                const bot = game.board.tiles[x][y];
                game.board.tiles[x][y] = top;
                game.board.tiles[x][y - 1] = bot;
                return;
            }
        }
    }
}

pub fn doDown() void {
    for (0..4) |x| {
        for (0..3) |y| {
            if (game.board.tiles[x][y + 1] == .empty) {
                const top = game.board.tiles[x][y];
                const bot = game.board.tiles[x][y + 1];
                game.board.tiles[x][y + 1] = top;
                game.board.tiles[x][y] = bot;
                return;
            }
        }
    }
}

pub fn doLeft() void {
    for (1..4) |x| {
        for (0..4) |y| {
            if (game.board.tiles[x - 1][y] == .empty) {
                const left = game.board.tiles[x - 1][y];
                const right = game.board.tiles[x][y];
                game.board.tiles[x - 1][y] = right;
                game.board.tiles[x][y] = left;
                return;
            }
        }
    }
}

pub fn doRight() void {
    for (0..3) |x| {
        for (0..4) |y| {
            if (game.board.tiles[x + 1][y] == .empty) {
                const left = game.board.tiles[x][y];
                const right = game.board.tiles[x + 1][y];
                game.board.tiles[x][y] = right;
                game.board.tiles[x + 1][y] = left;
                return;
            }
        }
    }
}

pub fn drawBoard() void {
    for (game.board.tiles, 0..) |col, x| {
        for (col, 0..) |tile, y| {
            drawTile(tile, @intCast(x), @intCast(y));
        }
    }
}

pub fn drawDebugBoard() void {
    for (game.board.tiles, 0..) |col, x| {
        for (col, 0..) |tile, y| {
            drawDebugTile(tile, @intCast(x), @intCast(y));
        }
    }
}

pub fn drawDebugTile(
    tile: Tile,
    pos_x: u2,
    pos_y: u2,
) void {
    switch (tile) {
        .empty, .full => |t| {
            const tile_width = @divExact(cart.screen_width, 4);
            const tile_height = @divExact(cart.screen_height, 4);

            cart.rect(.{
                .x = @as(i32, pos_x) * tile_width,
                .y = @as(i32, pos_y) * tile_height,
                .width = tile_width,
                .height = tile_height,
                .stroke_color = .{ .r = 31, .g = 63, .b = 31 },
            });

            var text_buff: [3]u8 = undefined;
            var writer = std.Io.Writer.fixed(&text_buff);
            writer.print("P{}{}", .{ pos_x, pos_y }) catch {};
            cart.text(.{
                .str = writer.buffered(),
                .x = @as(i32, pos_x) * tile_width + 1,
                .y = @as(i32, pos_y) * tile_height + 1,
                .text_color = .{ .r = 31, .g = 63, .b = 31 },
                .scale = 1,
            });

            var text_buff2: [3]u8 = undefined;
            var writer2 = std.Io.Writer.fixed(&text_buff2);
            writer2.print("T{}{}", .{ t.x, t.y }) catch {};
            cart.text(.{
                .str = writer2.buffered(),
                .x = @as(i32, pos_x) * tile_width + 10,
                .y = @as(i32, pos_y) * tile_height + 10,
                .text_color = .{ .r = 31, .g = 63, .b = 31 },
                .scale = 1,
            });
        },
    }
}

pub fn drawTile(
    tile: Tile,
    pos_x: u2,
    pos_y: u2,
) void {
    switch (tile) {
        .empty => {
            const tile_width = @divExact(cart.screen_width, 4);
            const tile_height = @divExact(cart.screen_height, 4);

            cart.rect(.{
                .x = @as(i32, pos_x) * tile_width,
                .y = @as(i32, pos_y) * tile_height,
                .width = tile_width,
                .height = tile_height,
                .fill_color = .{ .r = 0, .g = 0, .b = 0 },
            });
        },
        .full => |tile_coord| {
            const tile_width = @divExact(cart.screen_width, 4);
            const tile_height = @divExact(cart.screen_height, 4);
            const bg_x_start: u32 = @as(u32, tile_coord.x) * tile_width;
            const bg_y_start: u32 = @as(u32, tile_coord.y) * tile_height;

            blit(.{
                .sprite = &josh,
                .x = @as(i32, pos_x) * tile_width,
                .y = @as(i32, pos_y) * tile_height,
                .width = tile_width,
                .height = tile_height,
                .src_x = bg_x_start,
                .src_y = bg_y_start,
            });
        },
    }
}

pub const BlitOptions = struct {
    sprite: *const cart.Framebuffer,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    src_x: u32 = 0,
    src_y: u32 = 0,
};

/// Need my own blit since the
pub fn blit(options: BlitOptions) void {
    for (options.sprite[options.src_x..][0..options.width], cart.framebuffer[@intCast(options.x)..][0..options.width]) |src_col, *dest_col| {
        @memcpy(dest_col[@intCast(options.y)..][0..options.height], src_col[options.src_y..][0..options.height]);
    }
}
