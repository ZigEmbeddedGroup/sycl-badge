const std = @import("std");
const cart = @import("cart-api");

const WIDTH: i32 = @intCast(cart.screen_width);
const HEIGHT: i32 = @intCast(cart.screen_height);

const MAX_BULLETS = 24;
const MAX_ENEMY_BULLETS = 16;
const MAX_ENEMIES = 6;

const Col = struct {
    pub const bg: cart.DisplayColor = .{ .r = 0, .g = 1, .b = 2 };
    pub const ship: cart.DisplayColor = .{ .r = 31, .g = 42, .b = 4 };
    pub const bullet: cart.DisplayColor = .{ .r = 31, .g = 63, .b = 31 };
    pub const enemy: cart.DisplayColor = .{ .r = 31, .g = 8, .b = 8 };
    pub const enemy_hit: cart.DisplayColor = .{ .r = 31, .g = 40, .b = 0 };
    pub const text: cart.DisplayColor = .{ .r = 28, .g = 54, .b = 24 };
    pub const text_dim: cart.DisplayColor = .{ .r = 10, .g = 20, .b = 10 };
};

const Mode = enum {
    intro,
    game,
    game_over,
};

const Player = struct {
    x: i32,
    y: i32,
    hp: u8,
    shot_cd: u8,
    score: u32,
    vy: i32,
};

const Bullet = struct {
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    alive: bool,
    hostile: bool,
};

const EnemyState = enum {
    dead,
    live,
    dying,
};

const Enemy = struct {
    x: i32,
    y: i32,
    vx: i32,
    hp: u8,
    cooldown: u8,
    fire_cd: u8,
    phase: u8,
    state: EnemyState,
};

var mode: Mode = .intro;
var rng_state: u32 = 0x1234ABCD;
var tick_count: u32 = 0;
var player: Player = undefined;
var bullets: [MAX_BULLETS]Bullet = undefined;
var enemy_bullets: [MAX_ENEMY_BULLETS]Bullet = undefined;
var enemies: [MAX_ENEMIES]Enemy = undefined;
var intro_a_released = false;
var intro_blink: u8 = 0;
var game_over_a_released = false;
var game_over_blink: u8 = 0;
var level: u8 = 0;
var level_time: u16 = 0;
var should_spawn: u8 = 0;

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
    var xx: i32 = x0;
    while (xx < x1) : (xx += 1) {
        @memset(cart.framebuffer[@intCast(xx)][@intCast(y0)..@intCast(y1)], px);
    }
}

fn overlapRect(ax: i32, ay: i32, aw: i32, ah: i32, bx: i32, by: i32, bw: i32, bh: i32) bool {
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by;
}

fn resetRun() void {
    tick_count = 0;
    level = 0;
    level_time = 0;
    should_spawn = 1;
    player = .{ .x = 14, .y = HEIGHT / 2 - 4, .hp = 5, .shot_cd = 0, .score = 0, .vy = 0 };

    for (&bullets) |*b| b.* = .{ .x = 0, .y = 0, .dx = 0, .dy = 0, .alive = false, .hostile = false };
    for (&enemy_bullets) |*b| b.* = .{ .x = 0, .y = 0, .dx = 0, .dy = 0, .alive = false, .hostile = true };
    for (&enemies) |*e| e.* = .{ .x = 0, .y = 0, .vx = 0, .hp = 0, .cooldown = 0, .fire_cd = 0, .phase = 0, .state = .dead };
}

fn spawnEnemy(slot: usize) void {
    const hp_boost: i32 = @min(@divTrunc(@as(i32, level), 4), 1);
    enemies[slot] = .{
        .x = WIDTH + randRange(0, 40),
        .y = randRange(8, HEIGHT - 18),
        .vx = randRange(1, 2),
        .hp = @intCast(randRange(1, 2) + hp_boost),
        .cooldown = 0,
        .fire_cd = 0,
        .phase = @intCast(nextRand() & 31),
        .state = .live,
    };
}

fn fireBullet() void {
    for (&bullets) |*b| {
        if (!b.alive) {
            b.* = .{ .x = player.x + 8, .y = player.y + 3, .dx = 4, .dy = 0, .alive = true, .hostile = false };
            return;
        }
    }
}

fn fireEnemyBullet(ex: i32, ey: i32) void {
    for (&enemy_bullets) |*b| {
        if (!b.alive) {
            b.* = .{
                .x = ex - 1,
                .y = ey + 3,
                .dx = -2 - @as(i32, @intCast(@min(level / 4, 1))),
                .dy = randRange(-1, 1),
                .alive = true,
                .hostile = true,
            };
            return;
        }
    }
}

fn activeEnemies() u8 {
    var n: u8 = 0;
    for (enemies) |e| {
        if (e.state != .dead) n += 1;
    }
    return n;
}

fn allEnemiesCleared() bool {
    for (enemies) |e| {
        if (e.state != .dead) return false;
    }
    return true;
}

fn tickGame() void {
    tick_count +%= 1;
    level_time +%= 1;

    if (cart.controls.up) player.vy -= 1;
    if (cart.controls.down) player.vy += 1;
    if (!cart.controls.up and !cart.controls.down) {
        if (player.vy > 0) player.vy -= 1;
        if (player.vy < 0) player.vy += 1;
    }
    player.vy = clamp(player.vy, -3, 3);
    player.y += player.vy;
    player.y = clamp(player.y, 4, HEIGHT - 12);

    if (player.shot_cd > 0) player.shot_cd -= 1;
    if (cart.controls.a and player.shot_cd == 0) {
        fireBullet();
        player.shot_cd = 5;
    }

    for (&bullets) |*b| {
        if (!b.alive) continue;
        b.x += b.dx;
        b.y += b.dy;
        if (b.x >= WIDTH + 2 or b.y < -2 or b.y > HEIGHT + 2) b.alive = false;
    }

    for (&enemy_bullets) |*b| {
        if (!b.alive) continue;
        b.x += b.dx;
        b.y += b.dy;
        if (b.x < -3 or b.y < -3 or b.y > HEIGHT + 3) {
            b.alive = false;
            continue;
        }
        if (overlapRect(b.x, b.y, 3, 3, player.x, player.y, 9, 8)) {
            b.alive = false;
            if (player.hp > 0) player.hp -= 1;
        }
    }

    if (level_time > 100 and should_spawn == 0 and allEnemiesCleared()) {
        level +%= 1;
        level_time = 0;
        should_spawn = @intCast(@min(@as(i32, MAX_ENEMIES), @as(i32, @intCast(level))));
    }

    if (level_time > 0 and (level_time % 50) == 0 and should_spawn > 0 and activeEnemies() < MAX_ENEMIES) {
        for (&enemies, 0..) |*e, i| {
            if (e.state == .dead) {
                spawnEnemy(i);
                should_spawn -= 1;
                break;
            }
        }
    }

    for (&enemies) |*e| {
        switch (e.state) {
            .dead => {},
            .dying => {
                if (e.cooldown < 20) {
                    e.cooldown += 1;
                } else {
                    e.state = .dead;
                }
            },
            .live => {
                e.phase +%= 1;
                e.x -= e.vx;

                if ((tick_count & 3) == 0) {
                    if (e.phase < 16) {
                        e.y -= 1;
                    } else {
                        e.y += 1;
                    }
                }
                e.y = clamp(e.y, 6, HEIGHT - 14);

                if (e.x < -12) {
                    e.state = .dead;
                } else {
                    for (&bullets) |*b| {
                        if (!b.alive) continue;
                        if (overlapRect(b.x, b.y, 2, 2, e.x, e.y, 10, 8)) {
                            b.alive = false;
                            if (e.hp > 1) {
                                e.hp -= 1;
                            } else {
                                e.state = .dying;
                                e.cooldown = 0;
                                player.score += 1;
                            }
                            break;
                        }
                    }

                    if (e.state == .live and overlapRect(player.x, player.y, 9, 8, e.x, e.y, 10, 8)) {
                        e.state = .dying;
                        e.cooldown = 0;
                        if (player.hp > 0) player.hp -= 1;
                    }

                    if (e.fire_cd > 0) e.fire_cd -= 1;
                    if (e.state == .live and level >= 2 and e.fire_cd == 0 and (nextRand() & 63) == 0) {
                        fireEnemyBullet(e.x, e.y);
                        e.fire_cd = 18;
                    }
                }
            },
        }
    }

    if (player.hp == 0) {
        mode = .game_over;
        game_over_a_released = false;
        game_over_blink = 0;
    }
}

fn drawHud() void {
    var i: u8 = 0;
    while (i < 5) : (i += 1) {
        const on = i < player.hp;
        fillRect(4 + @as(i32, i) * 6, 4, 4, 3, if (on) Col.text else Col.text_dim);
    }

    var buf: [24]u8 = undefined;
    const s = stdfmt(player.score, &buf);
    cart.text(.{ .str = s, .x = WIDTH - 52, .y = 2, .text_color = Col.text });

    var wave_buf: [16]u8 = undefined;
    const wave_s = u8fmt(level, &wave_buf);
    cart.text(.{ .str = "W", .x = WIDTH - 52, .y = 12, .text_color = Col.text_dim });
    cart.text(.{ .str = wave_s, .x = WIDTH - 44, .y = 12, .text_color = Col.text });

    if (level_time < 64 and level > 1 and (tick_count & 8) == 0) {
        cart.text(.{ .str = "NEW WAVE", .x = @divTrunc(WIDTH - 64, 2), .y = @divTrunc(HEIGHT - 8, 2), .text_color = Col.text_dim });
    }
}

fn stdfmt(v: u32, buf: *[24]u8) []const u8 {
    var tmp: [24]u8 = undefined;
    var n = v;
    var len: usize = 0;
    if (n == 0) {
        buf[0] = '0';
        return buf[0..1];
    }
    while (n > 0) : (n /= 10) {
        tmp[len] = @as(u8, @intCast('0' + (n % 10)));
        len += 1;
    }
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = tmp[len - 1 - i];
    }
    return buf[0..len];
}

fn u8fmt(v: u8, buf: *[16]u8) []const u8 {
    var tmp: [16]u8 = undefined;
    var n: u32 = v;
    var len: usize = 0;
    if (n == 0) {
        buf[0] = '0';
        return buf[0..1];
    }
    while (n > 0) : (n /= 10) {
        tmp[len] = @as(u8, @intCast('0' + (n % 10)));
        len += 1;
    }
    var i: usize = 0;
    while (i < len) : (i += 1) {
        buf[i] = tmp[len - 1 - i];
    }
    return buf[0..len];
}

fn drawGame() void {
    fillScreen(Col.bg);

    // Ship body
    fillRect(player.x, player.y, 9, 8, Col.ship);
    fillRect(player.x - 2, player.y + 2, 2, 4, Col.ship);

    for (&bullets) |*b| {
        if (!b.alive) continue;
        fillRect(b.x, b.y, 2, 2, Col.bullet);
    }

    for (&enemy_bullets) |*b| {
        if (!b.alive) continue;
        fillRect(b.x - 1, b.y, 3, 1, Col.enemy_hit);
        fillRect(b.x, b.y - 1, 1, 3, Col.enemy_hit);
    }

    for (&enemies) |*e| {
        switch (e.state) {
            .dead => {},
            .live => {
                fillRect(e.x, e.y, 10, 8, Col.enemy);
                fillRect(e.x + 2, e.y + 2, 2, 2, Col.bg);
                fillRect(e.x + 6, e.y + 2, 2, 2, Col.bg);
            },
            .dying => {
                const sz = @as(i32, 2) + @divTrunc(@as(i32, e.cooldown), 3);
                fillRect(e.x + 5 - sz, e.y + 4 - sz, sz * 2, sz * 2, Col.enemy_hit);
            },
        }
    }

    drawHud();
}

fn tickIntro() void {
    intro_blink +%= 1;
    if (!cart.controls.a) intro_a_released = true;
    if (intro_a_released and cart.controls.a) {
        resetRun();
        mode = .game;
    }
}

fn tickGameOver() void {
    game_over_blink +%= 1;
    if (!cart.controls.a) game_over_a_released = true;
    if (game_over_a_released and cart.controls.a) {
        intro_a_released = false;
        intro_blink = 0;
        mode = .intro;
    }
}

fn drawIntro() void {
    fillScreen(Col.bg);
    cart.text(.{ .str = "SPACE SHOOTER V2", .x = 20, .y = 40, .text_color = Col.text });
    cart.text(.{ .str = "OS Compatible", .x = 30, .y = 52, .text_color = Col.text_dim });

    if ((intro_blink / 24) % 2 == 0) {
        cart.text(.{ .str = "PRESS A TO START", .x = 24, .y = 78, .text_color = Col.text });
    }
}

fn drawGameOver() void {
    fillScreen(Col.bg);
    cart.text(.{ .str = "GAME OVER", .x = 44, .y = 48, .text_color = Col.enemy_hit });

    var buf: [24]u8 = undefined;
    const s = stdfmt(player.score, &buf);
    cart.text(.{ .str = "SCORE", .x = 50, .y = 62, .text_color = Col.text_dim });
    cart.text(.{ .str = s, .x = 90, .y = 62, .text_color = Col.text });

    if ((game_over_blink / 24) % 2 == 0) {
        cart.text(.{ .str = "PRESS A", .x = 56, .y = 80, .text_color = Col.text });
    }
}

export fn start() void {
    rng_state = 0xC001D00D;
    mode = .intro;
    intro_a_released = false;
    intro_blink = 0;
}

export fn update() void {
    switch (mode) {
        .intro => {
            tickIntro();
            drawIntro();
        },
        .game => {
            tickGame();
            drawGame();
        },
        .game_over => {
            tickGameOver();
            drawGameOver();
        },
    }
}
