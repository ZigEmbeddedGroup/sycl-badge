const std = @import("std");
const cart = @import("cart-api");

const StartMenu = struct {
    seed: u32,
    start_pressed: bool = false,
};
const Play = struct {
    pos: u3,
    grid: [5][2]bool,
    left_pressed: bool = false,
    right_pressed: bool = false,
    a_pressed: bool = false,
    b_pressed: bool = false,
    start_pressed: bool = false,
};
const Win = struct {
    frame: u32 = 0,
    start_pressed: bool = false,
};
const Mode = union(enum) {
    start_menu: StartMenu,
    play: Play,
    win: Win,
};
const global = struct {
    pub var mode = Mode{
        .start_menu = .{ .seed = 0 },
    };
    pub var bright: u8 = 32;
    pub var up_pressed = false;
    pub var down_pressed = false;
};

const Button = enum {
    start,
    a, b,
    up, down, left, right,
    pub fn isDown(self: Button) bool {
        switch (self) {
            .start => return cart.controls.start,
            .a => return cart.controls.a,
            .b => return cart.controls.b,
            .up => return cart.controls.up,
            .down => return cart.controls.down,
            .left => return cart.controls.left,
            .right => return cart.controls.right,
        }
    }
};

// Used to tell if a button is "triggered".
// Prevents the "down" state from triggering multiple events.
fn isButtonTriggered(
    button: Button,
    released_state_ref: *bool,
) bool {
    const pressed = button.isDown();
    if (released_state_ref.*) {
        if (pressed) released_state_ref.* = false;
        return pressed;
    } else {
        if (!pressed) {
            released_state_ref.* = true;
        }
        return false;
    }
}

fn clear() void {
    cart.neopixels.* =  .{
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
        .{ .r = 0, .g = 0, .b = 0 },
    };
}

export fn start() void {
    clear();
}

export fn update() void {

    if (isButtonTriggered(.up, &global.up_pressed)) {
        if (global.bright == 0) {
            global.bright += 1;
        } else if (global.bright < 128) {
            global.bright *= 2;
        }
    } else if (isButtonTriggered(.down, &global.down_pressed)) {
        global.bright = global.bright / 2;
    }

    switch (global.mode) {
        .start_menu => updateStartMenu(&global.mode.start_menu),
        .play => updatePlayMode(&global.mode.play),
        .win => updateWinMode(&global.mode.win),
    }
}

pub fn on()  cart.NeopixelColor { return .{ .r = 0, .g = global.bright, .b = 0 }; }
pub fn off() cart.NeopixelColor { return .{ .r = 0, .g =             0, .b = 0 }; }
pub fn on_select()  cart.NeopixelColor { return .{ .r = 0, .g = global.bright, .b = global.bright/2 }; }
pub fn off_select() cart.NeopixelColor { return .{ .r = 0, .g =             0, .b = global.bright/2 }; }


fn newGame(seed: u32) void {
    clear();
    global.mode = Mode{
        .play = .{
            .pos = 2,
            .grid = [5][2]bool{
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
            },
        },
    };

    var rand = std.rand.DefaultPrng.init(seed);
    for (0 .. 100) |_| {
        var buf: [1]u8 = undefined;
        rand.fill(&buf);
        rotate(&global.mode.play.grid, @intCast(buf[0] % 5));
    }
}

fn updateStartMenu(start_menu: *StartMenu) void {
    start_menu.seed +%= 1;
    if (isButtonTriggered(.start, &start_menu.start_pressed)) {
        const seed = start_menu.seed;
        newGame(seed);
        return;
    }
    cart.neopixels[(start_menu.seed +% 4) % 5] = off();
    cart.neopixels[start_menu.seed % 5] = on();
}

fn updatePlayMode(play: *Play) void {

    if (isButtonTriggered(.a, &play.a_pressed)) {
        rotate(&play.grid, play.pos);
    } else if (isButtonTriggered(.b, &play.b_pressed)) {
        for (0 .. 3) |_| {
            rotate(&play.grid, play.pos);
        }
    } else if (isButtonTriggered(.right, &play.right_pressed)) {
        play.pos = (play.pos + 1) % 5;
    } else if (isButtonTriggered(.left, &play.left_pressed)) {
        play.pos = @intCast((@as(usize, play.pos) + 4) % 5);
    } else if (isButtonTriggered(.start, &play.start_pressed)) {
        clear();
        global.mode = Mode{ .start_menu = .{ .seed = 0 } };
    }

    var win = true;
    for (0 .. 5) |i| {
        if (!play.grid[i][1]) {
            win = false;
            break;
        }
    }

    if (win) {
        clear();
        global.mode = Mode{ .win = .{} };
        return;
    }

    for (0 .. 5) |i| {
        if (play.pos == i or i == ((play.pos + 1) % 5)) {
            cart.neopixels[i] = if (play.grid[i][1]) on_select() else off_select();
        } else {
            cart.neopixels[i] = if (play.grid[i][1]) on() else off();
        }
    }
}

fn updateWinMode(win: *Win) void {
    if (isButtonTriggered(.start, &win.start_pressed)) {
        const seed = win.frame;
        newGame(seed);
        return;
    }

    win.frame +%= 1;
    cart.neopixels[(win.frame +% 4) % 5] = off();
    cart.neopixels[win.frame % 5] = on_select();
}

fn rotate(grid: *[5][2]bool, pos: u3) void {
    const t = grid[pos][0];
    const pos2 =  (pos + 1) % 5;
    grid[pos][0] = grid[pos][1];
    grid[pos][1] = grid[pos2][1];
    grid[pos2][1] = grid[pos2][0];
    grid[pos2][0] = t;
}
