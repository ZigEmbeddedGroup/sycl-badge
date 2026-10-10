//! @author_name    Loris Cro
//! @author_handle  kristoff
//! @cart_title     zig-zag-zoe?
//! @description    Tic tac toe with a twizt!

/// The cart module contains utilities for interacting
/// with the badge. Check src/os/cart/api.zig for details!
const cart = @import("cart-api");

// This block exports the hooks that the platform
// (either the badge OS or the simulator)
// will use to start the cart.
comptime {
    cart.export_start_code();
}

var game: Game = .{};
pub fn start() void {
    game.last_controls.a = true;
    cart.set_double_buffer_mode(.{ .clear_full_frame = .rgb(0x131315) });
}

/// This function is called repeatedly. The screen
/// will be updated every time this function returns.
pub fn update() void {
    //title
    {
        const title = switch (game.state) {
            .playing => switch (game.turn) {
                .X => "-- X's TURN --",
                .O => "-- O's TURN --",
                .@" " => unreachable,
            },
            .done => switch (game.turn) {
                .X => "-- X WINS!! --",
                .O => "-- O WINS!! --",
                .@" " => unreachable,
            },
            .done_tie => "--   TIED   --",
        };

        cart.text(.{
            .str = title,
            .x = 25,
            .y = 10,
            .text_color = .rgb(0xFFFF54),
        });

        cart.line(.{
            .x1 = 25,
            .y1 = 20,
            .x2 = 135,
            .y2 = 20,
            .color = .rgb(0xFFFFFF),
        });
    }
    // grid
    {
        const segment = 28;
        const x_off = 37;
        const y_off = 25;

        cart.line(.{
            .x1 = x_off + @divTrunc(segment, 4),
            .y1 = y_off + segment,
            .x2 = x_off + (segment * 3) - @divTrunc(segment, 4),
            .y2 = y_off + segment,
            .color = .rgb(0xFFFF54),
        });
        cart.line(.{
            .x1 = x_off + @divTrunc(segment, 4),
            .y1 = y_off + (segment * 2),
            .x2 = x_off + (segment * 3) - @divTrunc(segment, 4),
            .y2 = y_off + (segment * 2),
            .color = .rgb(0xFFFF54),
        });
        cart.line(.{
            .x1 = x_off + segment,
            .y1 = y_off + @divTrunc(segment, 4),
            .x2 = x_off + segment,
            .y2 = y_off + (segment * 3) - @divTrunc(segment, 4),
            .color = .rgb(0xFFFF54),
        });
        cart.line(.{
            .x1 = x_off + (segment * 2),
            .y1 = y_off + @divTrunc(segment, 4),
            .x2 = x_off + (segment * 2),
            .y2 = y_off + (segment * 3) - @divTrunc(segment, 4),
            .color = .rgb(0xFFFF54),
        });

        for (game.grid, 0..) |cell, idx| {
            const col: u32 = @intCast(idx % 3);
            const row: u32 = @intCast(@divTrunc(idx, 3));

            const x: i32 = @intCast(x_off + (segment / 4) + (segment * col));
            const y: i32 = @intCast(y_off + (segment / 4) + (segment * row));

            cart.text(.{
                .str = @tagName(cell),
                .x = x,
                .y = y,
                .scale = 2,
                .text_color = if (idx == game.history[game.history_idx])
                    .rgb(0x7baaf7)
                else
                    .rgb(0xFFFFFF),
            });

            if (idx == game.selected) {
                cart.rect(.{
                    .x = x - (segment / 4),
                    .y = y - (segment / 4),
                    .width = segment,
                    .height = segment,
                    .stroke_color = .rgb(0xFFFFFF),
                });
            }
        }

        const controls = game.controls(cart.controls.*);
        switch (game.state) {
            .done, .done_tie => {
                cart.text(.{
                    .str = "   press 'start'\n   to play again",
                    .x = 0,
                    .y = 110,
                    .scale = 1,
                    .text_color = .rgb(0x7F00FF),
                });

                if (controls.start) {
                    game.reset();
                }
            },
            .playing => {
                const col: u32 = @intCast(game.selected % 3);
                const row: u32 = @intCast(@divTrunc(game.selected, 3));
                if (controls.right) game.selected = (row * 3) + @min(2, col + 1);
                if (controls.left) game.selected = (row * 3) + (col -| 1);
                if (controls.up) game.selected = ((row -| 1) * 3) + col;
                const three: u32 = 3;
                if (controls.down) game.selected = col + (@min(2, row + 1) * three);
                if (controls.a) game.addMark();
            },
        }
    }
}

const Mark = enum { X, O, @" " };
const Game = struct {
    turn: Mark = .X,
    grid: [9]Mark = @splat(.@" "),
    selected: u32 = 0,
    last_controls: cart.Controls = .none,
    state: enum { playing, done, done_tie } = .playing,
    history: [6]u32 = @splat(9),
    history_idx: u32 = 0,

    fn reset(g: *Game) void {
        g.* = .{};
    }

    fn controls(g: *Game, c: cart.Controls) cart.Controls {
        const last = @backingInt(g.last_controls);
        const new = @backingInt(c);
        g.last_controls = c;
        return @fromBackingInt(new & ~last);
    }

    fn addMark(g: *Game) void {
        if (g.grid[g.selected] != .@" ") return;

        g.grid[g.selected] = g.turn;
        const to_delete = &g.history[g.history_idx];
        if (to_delete.* < 9) {
            g.grid[to_delete.*] = .@" ";
        }
        to_delete.* = g.selected;
        g.history_idx = (g.history_idx + 1) % 6;

        // check win conditions
        {
            const lines: []const [3]usize = &.{
                .{ 0, 1, 2 },
                .{ 3, 4, 5 },
                .{ 6, 7, 8 },
                .{ 0, 3, 6 },
                .{ 1, 4, 7 },
                .{ 2, 5, 8 },
                .{ 0, 4, 8 },
                .{ 2, 4, 6 },
            };

            for (lines) |line| {
                if (g.grid[line[0]] == .@" ") continue;
                if (g.grid[line[0]] == g.grid[line[1]] and
                    g.grid[line[1]] == g.grid[line[2]])
                {
                    g.state = .done;
                    return;
                }
            }

            for (g.grid) |cell| {
                if (cell == .@" ") break;
            } else {
                g.state = .done_tie;
            }
        }

        g.turn = switch (g.turn) {
            .X => .O,
            .O => .X,
            .@" " => unreachable,
        };
    }
};
