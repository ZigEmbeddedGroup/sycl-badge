const cart = @import("cart-api");

const WIDTH: i32 = @intCast(cart.screen_width);
const HEIGHT: i32 = @intCast(cart.screen_height);

const MAX_PELLETS = 70; // 56; // I've tried larger numbers, it crashes
const MAX_BOTS = 6;
const PELLET_SIZE_PT: i32 = 24;
const ARENA_HALF_WIDTH_PT: i32 = 3200;
const ARENA_HALF_HEIGHT_PT: i32 = 2560;
const MAX_POINTS_PER_PIXEL: i32 = @divTrunc(ARENA_HALF_WIDTH_PT * 2, WIDTH);
const EAT_SIZE_MARGIN_PT: i32 = 12;

const Col = struct {
    pub const bg: cart.DisplayColor = .{ .r = 1, .g = 2, .b = 3 };
    pub const player: cart.DisplayColor = .{ .r = 8, .g = 46, .b = 18 };
    pub const pellet: cart.DisplayColor = .{ .r = 31, .g = 48, .b = 0 };
    pub const enemy: cart.DisplayColor = .{ .r = 31, .g = 0, .b = 8 };
    pub const hud_on: cart.DisplayColor = .{ .r = 4, .g = 40, .b = 16 };
    pub const hud_off: cart.DisplayColor = .{ .r = 3, .g = 6, .b = 4 };
    pub const game_over: cart.DisplayColor = .{ .r = 31, .g = 0, .b = 0 };
};

const Control = enum {
    none,
    dec,
    inc,
};

const Player = struct {
    x: i32,
    y: i32,
    size: i32,
    dir: u8,
    score: u32,
    hp: u8,
};

const Pellet = struct {
    x: i32,
    y: i32,
    alive: bool,
};

const Bot = struct {
    x: i32,
    y: i32,
    dir: u8,
    ai_control: Control,
    size: i32,
    alive: bool,
};

const StartMenu = struct {
    a_released: bool = false,
};

const Play = struct {
    a_released: bool = false,
};

const Settings = struct {
    a_released: bool = false,
    up_released: bool = false,
    down_released: bool = false,
    selection: enum {
        return_to_game,
        new_game,
    } = .return_to_game,
};

const Mode = union(enum) {
    start_menu: StartMenu,
    play: Play,
    settings: Settings,
};

var rng_state: u32 = 0x9e3779b9;
var tick_count: u32 = 0;
var player: Player = undefined;
var pellets: [MAX_PELLETS]Pellet = undefined;
var bots: [MAX_BOTS]Bot = undefined;
var game_over: bool = false;
var game_over_flash: u8 = 0;
var mode: Mode = .{ .start_menu = .{} };
const Camera = struct { x: i32, y: i32 };
var points_per_pixel: i32 = 6;
var camera_center: Camera = .{ .x = 0, .y = 0 };

const DIRS = 16;
const DirVec = struct { x: i32, y: i32 };
const DIR_VECS = [DIRS]DirVec{
    .{ .x = 2, .y = 0 },
    .{ .x = 2, .y = 1 },
    .{ .x = 1, .y = 1 },
    .{ .x = 1, .y = 2 },
    .{ .x = 0, .y = 2 },
    .{ .x = -1, .y = 2 },
    .{ .x = -1, .y = 1 },
    .{ .x = -2, .y = 1 },
    .{ .x = -2, .y = 0 },
    .{ .x = -2, .y = -1 },
    .{ .x = -1, .y = -1 },
    .{ .x = -1, .y = -2 },
    .{ .x = 0, .y = -2 },
    .{ .x = 1, .y = -2 },
    .{ .x = 1, .y = -1 },
    .{ .x = 2, .y = -1 },
};

fn nextRand() u32 {
    rng_state = rng_state *% 1664525 +% 1013904223;
    return rng_state;
}

fn randRange(min_incl: i32, max_incl: i32) i32 {
    if (max_incl <= min_incl) return min_incl;
    const span: u32 = @intCast(max_incl - min_incl + 1);
    return min_incl + @as(i32, @intCast(nextRand() % span));
}

fn clamp(v: i32, lo: i32, hi: i32) i32 {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

fn overlapSquare(ax: i32, ay: i32, as: i32, bx: i32, by: i32, bs: i32) bool {
    const a_right = ax + as;
    const a_bottom = ay + as;
    const b_right = bx + bs;
    const b_bottom = by + bs;

    return ax < b_right and a_right > bx and ay < b_bottom and a_bottom > by;
}

fn fillScreen(color: cart.DisplayColor) void {
    const px = cart.Pixel.fromColor(color);
    for (cart.framebuffer) |*col| {
        @memset(col, px);
    }
}

fn fillRect(x: i32, y: i32, w: i32, h: i32, color: cart.DisplayColor) void {
    if (w <= 0 or h <= 0) return;

    const x0 = clamp(x, 0, WIDTH);
    const y0 = clamp(y, 0, HEIGHT);
    const x1 = clamp(x + w, 0, WIDTH);
    const y1 = clamp(y + h, 0, HEIGHT);
    if (x0 >= x1 or y0 >= y1) return;

    const px = cart.Pixel.fromColor(color);
    var yy: i32 = y0;
    while (yy < y1) : (yy += 1) {
        var xx: i32 = x0;
        while (xx < x1) : (xx += 1) {
            cart.framebuffer[@intCast(xx)][@intCast(yy)] = px;
        }
    }
}

fn spawnPellet(i: usize) void {
    const margin = PELLET_SIZE_PT;
    var tries: u8 = 0;
    while (true) {
        const px = randRange(-ARENA_HALF_WIDTH_PT + margin, ARENA_HALF_WIDTH_PT - margin);
        const py = randRange(-ARENA_HALF_HEIGHT_PT + margin, ARENA_HALF_HEIGHT_PT - margin);
        if (!overlapSquare(player.x - 80, player.y - 80, player.size + 160, px, py, PELLET_SIZE_PT) or tries >= 6) {
            pellets[i] = .{ .x = px, .y = py, .alive = true };
            return;
        }
        tries +%= 1;
    }
}

fn spawnBot(idx: usize) void {
    const large_min = clamp(player.size + 24, 48, 260);
    const large_max = clamp(player.size + 120, large_min, 320);
    const small_min = clamp(player.size - 56, 36, 220);
    const small_max = clamp(player.size + 16, small_min, 260);
    const size = if ((nextRand() % 100) < 70)
        randRange(large_min, large_max)
    else
        randRange(small_min, small_max);

    bots[idx] = .{
        .x = randRange(-ARENA_HALF_WIDTH_PT, ARENA_HALF_WIDTH_PT - size),
        .y = randRange(-ARENA_HALF_HEIGHT_PT, ARENA_HALF_HEIGHT_PT - size),
        .dir = @intCast(nextRand() % DIRS),
        .ai_control = .none,
        .size = size,
        .alive = true,
    };
}

fn resetGame() void {
    tick_count = 0;
    game_over = false;
    game_over_flash = 0;
    player = .{ .x = 0, .y = 0, .size = 96, .dir = 0, .score = 0, .hp = 5 };
    points_per_pixel = 6;
    camera_center = .{ .x = 0, .y = 0 };

    for (&pellets, 0..) |*p, i| {
        p.* = .{ .x = 0, .y = 0, .alive = false };
        spawnPellet(i);
    }

    for (&bots, 0..) |*b, i| {
        b.* = .{ .x = 0, .y = 0, .dir = 0, .ai_control = .none, .size = 0, .alive = false };
        if (i < 4) spawnBot(i);
    }
}

export fn start() void {
    mode = .{ .start_menu = .{} };
}

const Button = enum {
    start,
    a,
    up,
    down,
    left,
    right,

    fn isDown(self: Button) bool {
        return switch (self) {
            .start => cart.controls.start,
            .a => cart.controls.a,
            .up => cart.controls.up,
            .down => cart.controls.down,
            .left => cart.controls.left,
            .right => cart.controls.right,
        };
    }
};

fn isButtonTriggered(button: Button, released_state: *bool) bool {
    const pressed = button.isDown();
    if (released_state.*) {
        if (pressed) released_state.* = false;
        return pressed;
    }

    if (!pressed) released_state.* = true;
    return false;
}

fn textCenter(str: []const u8, y: i32, color: cart.DisplayColor) void {
    const x: i32 = @divTrunc(WIDTH - @as(i32, @intCast(str.len * 8)), 2);
    cart.text(.{ .str = str, .x = x, .y = y, .text_color = color });
}

fn ptToPxX(pt: i32) i32 {
    return @divTrunc(WIDTH, 2) + @divTrunc(pt - camera_center.x, points_per_pixel);
}

fn ptToPxY(pt: i32) i32 {
    return @divTrunc(HEIGHT, 2) + @divTrunc(pt - camera_center.y, points_per_pixel);
}

fn sizePtToPx(size_pt: i32) i32 {
    const px = @divTrunc(size_pt, points_per_pixel);
    return if (px < 2) 2 else px;
}

fn updateCameraAndZoom() void {
    const desired_player_px = 18;
    const desired_ppp = clamp(@divTrunc(player.size, desired_player_px), 1, MAX_POINTS_PER_PIXEL);

    if (points_per_pixel < desired_ppp) {
        points_per_pixel += 1;
    } else if (points_per_pixel > desired_ppp) {
        points_per_pixel -= 1;
    }

    const half_view_w = @divTrunc(WIDTH, 2) * points_per_pixel;
    const half_view_h = @divTrunc(HEIGHT, 2) * points_per_pixel;
    const target_x = player.x + @divTrunc(player.size, 2);
    const target_y = player.y + @divTrunc(player.size, 2);

    const min_cam_x = -ARENA_HALF_WIDTH_PT + half_view_w;
    const max_cam_x = ARENA_HALF_WIDTH_PT - half_view_w;
    const min_cam_y = -ARENA_HALF_HEIGHT_PT + half_view_h;
    const max_cam_y = ARENA_HALF_HEIGHT_PT - half_view_h;

    camera_center.x = if (min_cam_x > max_cam_x) 0 else clamp(target_x, min_cam_x, max_cam_x);
    camera_center.y = if (min_cam_y > max_cam_y) 0 else clamp(target_y, min_cam_y, max_cam_y);
}

fn updatePlayer() void {
    if (cart.controls.left and !cart.controls.right) {
        player.dir = if (player.dir == 0) (DIRS - 1) else (player.dir - 1);
    } else if (cart.controls.right and !cart.controls.left) {
        player.dir = if (player.dir + 1 >= DIRS) 0 else (player.dir + 1);
    }

    const v = DIR_VECS[player.dir];
    const speed_mul: i32 = if (cart.controls.b) 12 else 7;
    const dx = v.x * speed_mul;
    const dy = v.y * speed_mul;

    player.x = clamp(player.x + dx, -ARENA_HALF_WIDTH_PT, ARENA_HALF_WIDTH_PT - player.size);
    player.y = clamp(player.y + dy, -ARENA_HALF_HEIGHT_PT, ARENA_HALF_HEIGHT_PT - player.size);
}

fn updatePellets() void {
    for (&pellets, 0..) |*p, i| {
        if (!p.alive) {
            spawnPellet(i);
            continue;
        }

        if (overlapSquare(player.x, player.y, player.size, p.x, p.y, PELLET_SIZE_PT)) {
            p.alive = false;
            player.score +%= 1;
            if ((player.score % 10) == 0 and player.size < 220) {
                player.size += 8;
            }
        }
    }
}

fn maybeSpawnBot() void {
    if ((tick_count % 75) != 0) return;

    var alive_count: usize = 0;
    for (bots) |b| {
        if (b.alive) alive_count += 1;
    }

    const cap = @min(MAX_BOTS, 2 + @as(usize, @intCast(player.score / 12)));
    if (alive_count >= cap) return;

    for (&bots, 0..) |*b, i| {
        if (!b.alive) {
            spawnBot(i);
            break;
        }
    }
}

fn updateBots() void {
    for (&bots) |*b| {
        if (!b.alive) continue;

        const r: u8 = @intCast(nextRand() & 0xff);
        switch (b.ai_control) {
            .none => {
                if (r < 30) {
                    b.ai_control = .dec;
                } else if (r < 60) {
                    b.ai_control = .inc;
                }
            },
            .dec, .inc => {
                if (r < 40) b.ai_control = .none;
            },
        }

        switch (b.ai_control) {
            .none => {},
            .dec => b.dir = if (b.dir == 0) (DIRS - 1) else (b.dir - 1),
            .inc => b.dir = if (b.dir + 1 >= DIRS) 0 else (b.dir + 1),
        }

        const v = DIR_VECS[b.dir];
        b.x = clamp(b.x + v.x * 6, -ARENA_HALF_WIDTH_PT, ARENA_HALF_WIDTH_PT - b.size);
        b.y = clamp(b.y + v.y * 6, -ARENA_HALF_HEIGHT_PT, ARENA_HALF_HEIGHT_PT - b.size);

        if (overlapSquare(player.x, player.y, player.size, b.x, b.y, b.size)) {
            // OG-like rule: you must be strictly larger to consume.
            if (player.size > b.size) {
                b.alive = false;
                // Reward scales with consumed bot size.
                const bot_points: u32 = @intCast(@max(1, @divTrunc(b.size, PELLET_SIZE_PT)));
                const bot_growth: i32 = clamp(@divTrunc(b.size, 10), 4, 24);
                player.score +%= bot_points;
                if (player.size < 260) {
                    player.size = @min(260, player.size + bot_growth);
                }
            } else {
                // On contact with equal-or-larger enemy, die immediately.
                player.hp = 0;
                game_over = true;
                return;
            }
        }
    }
}

fn drawHud() void {
    fillRect(0, 0, WIDTH, 8, Col.hud_off);

    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        const on = i < @as(i32, player.hp);
        fillRect(2 + i * 5, 1, 4, 6, if (on) Col.hud_on else Col.hud_off);
    }

    const bar_w: i32 = 60;
    const percent: i32 = @intCast(player.score % 100);
    const fill_w: i32 = @divTrunc(percent * bar_w, 100);
    fillRect(WIDTH - bar_w - 2, 1, bar_w, 6, Col.hud_off);
    fillRect(WIDTH - bar_w - 2, 1, fill_w, 6, Col.hud_on);
}

fn drawScene() void {
    fillScreen(Col.bg);
    drawHud();

    for (pellets) |p| {
        if (!p.alive) continue;

        const px = ptToPxX(p.x);
        const py = ptToPxY(p.y);
        const ps = clamp(sizePtToPx(PELLET_SIZE_PT), 2, 3);
        if (px + ps < 0 or py + ps < 0 or px >= WIDTH or py >= HEIGHT) continue;

        fillRect(px, py, ps, ps, Col.pellet);
    }

    for (bots) |b| {
        if (!b.alive) continue;

        const bx = ptToPxX(b.x);
        const by = ptToPxY(b.y);
        const bs = sizePtToPx(b.size);
        if (bx + bs < 0 or by + bs < 0 or bx >= WIDTH or by >= HEIGHT) continue;

        cart.oval(.{
            .x = bx,
            .y = by,
            .width = @intCast(bs),
            .height = @intCast(bs),
            .fill_color = Col.enemy,
        });
    }

    const px = ptToPxX(player.x);
    const py = ptToPxY(player.y);
    const ps = sizePtToPx(player.size);
    cart.oval(.{
        .x = px,
        .y = py,
        .width = @intCast(ps),
        .height = @intCast(ps),
        .fill_color = Col.player,
    });

    const v = DIR_VECS[player.dir];
    const cx = px + @divTrunc(ps, 2);
    const cy = py + @divTrunc(ps, 2);
    const dir_x = cx + @divTrunc(v.x * ps, 4);
    const dir_y = cy + @divTrunc(v.y * ps, 4);
    cart.oval(.{
        .x = dir_x - 1,
        .y = dir_y - 1,
        .width = 3,
        .height = 3,
        .fill_color = Col.hud_off,
        .stroke_color = Col.hud_on,
    });

    if (game_over) {
        game_over_flash +%= 1;
        if ((game_over_flash & 0x08) != 0) {
            fillRect(20, @divTrunc(HEIGHT, 2) - 10, WIDTH - 40, 20, Col.game_over);
        }
    }
}

fn updatePlayMode(play: *Play) void {
    tick_count +%= 1;

    if (isButtonTriggered(.a, &play.a_released)) {
        mode = .{ .settings = .{} };
        return;
    }

    if (game_over) {
        if (cart.controls.start) resetGame();
        drawScene();
        return;
    }

    updatePlayer();
    updatePellets();
    maybeSpawnBot();
    updateBots();
    updateCameraAndZoom();
    drawScene();
}

fn updateStartMenu(start_menu: *StartMenu) void {
    fillScreen(Col.bg);
    textCenter("BLOBS V2", 24, Col.player);
    textCenter("Press A to Start", 108, Col.pellet);

    if (isButtonTriggered(.a, &start_menu.a_released)) {
        resetGame();
        mode = .{ .play = .{} };
    }
}

fn updateSettingsMode(settings: *Settings) void {
    fillScreen(Col.bg);
    textCenter("Settings", 30, Col.player);
    textCenter("Return to Game", 56, if (settings.selection == .return_to_game) Col.pellet else Col.hud_on);
    textCenter("New Game", 70, if (settings.selection == .new_game) Col.pellet else Col.hud_on);
    textCenter("Use Up/Down + A", 98, Col.hud_on);

    if (isButtonTriggered(.up, &settings.up_released) and settings.selection == .new_game) {
        settings.selection = .return_to_game;
    }
    if (isButtonTriggered(.down, &settings.down_released) and settings.selection == .return_to_game) {
        settings.selection = .new_game;
    }

    if (isButtonTriggered(.a, &settings.a_released)) {
        switch (settings.selection) {
            .return_to_game => mode = .{ .play = .{} },
            .new_game => {
                resetGame();
                mode = .{ .play = .{} };
            },
        }
    }
}

export fn update() void {
    switch (mode) {
        .start_menu => updateStartMenu(&mode.start_menu),
        .play => updatePlayMode(&mode.play),
        .settings => updateSettingsMode(&mode.settings),
    }
}
