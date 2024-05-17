const std = @import("std");
const cart = @import("cart-api");
const gfx = @import("gfx");

const Renderer = @import("Renderer.zig");
const Rect = Renderer.Rect;
const Sprite = Renderer.Sprite;
const Box = @import("Box.zig");
const Tile = @import("Tile.zig");
const Room = @import("Room.zig");
const Stage = @import("Stage.zig");
const Player = @import("Player.zig");
const Enemy = @import("Enemy.zig");
const effects = @import("effects.zig");
const needleman = @import("stages/needleman.zig").needleman;

const screen_width = cart.screen_width; // 256
const screen_height = cart.screen_height; // 240
const target_frame_time = 1.0 / 60.0;
const min_frame_time = 1.0 / 10.0;

const title_tex = gfx.title;
const healthbar_tex = gfx.healthbar;

const door_sprite = gfx.door;
const spike_sprite = gfx.spike;

const tiles_tex = gfx.needleman;
var prev_room_tex: Renderer.Texture = undefined;
var cur_room_tex: Renderer.Texture = undefined;

const font_tex = gfx.font;
var text_tex: Renderer.Texture = .{ .width = text_w, .height = text_h, .data = undefined };

const text_w = screen_width / 8;
const text_h = screen_height / 8;
var text_buffer: [text_w * text_h]u8 = undefined;

var prng = std.rand.DefaultPrng.init(0);
const rng = prng.random();

const GameState = enum {
    title,
    start,
    playing,
    gameover,
};

const RoomTransition = enum(u8) {
    none,
    vertical,
    door_ltr,
    door_rtl,
};

const door_duration = 16;
var room_transition: RoomTransition = .none;
var mode_frame: i32 = 0;

pub const GameData = struct {
    state: GameState = .title,
    counter: u8 = 0, // number of frames to wait in a state
    title_any_key_pressed: bool = false,
    player: Player = .{},
    input: Player.Input = std.mem.zeroes(Player.Input),
    prev_input: Player.Input = std.mem.zeroes(Player.Input),
    enemies: [16]Enemy = undefined,

    cur_room_index: u8 = 0,
    prev_room_index: u8 = 0,
    door1_h: u8 = 4,
    door2_h: u8 = 4,

    scrollr: Box = Box{
        .x = 0,
        .y = 0,
        .w = screen_width,
        .h = screen_height,
    },

    fn reset(self: *GameData) void {
        self.state = .title;
        self.counter = 0;
        self.input = std.mem.zeroes(Player.Input);
        self.prev_input = std.mem.zeroes(Player.Input);
        self.player.reset();
        self.cur_room_index = 0;
        self.prev_room_index = 0;
        const room = self.getCurrentRoom();
        uploadRoomTexture(&cur_room_tex, room);
        self.scrollr.x = room.bounds.x + 50;
        self.scrollr.y = room.bounds.y + 100;
        for (room.entities) |e| {
            if (e.class == .player) {
                self.player.box = e.box;
                break;
            }
        }
        self.deactivateEnemies();
        self.activateEnemies(room);
    }

    fn activateEnemies(self: *GameData, room: Room) void {
        var i: usize = 0;
        for (room.entities) |e| {
            switch (e.class) {
                .gopher => {
                    self.enemies[i].activate(.gopher, e.box);
                    i += 1;
                },
                else => {},
            }
        }
    }

    fn deactivateEnemies(self: *GameData) void {
        for (&self.enemies) |*e| {
            e.active = false;
        }
    }

    pub fn getCurrentRoom(self: GameData) Room {
        return cur_stage.rooms[self.cur_room_index];
    }

    fn tickTitle(self: *GameData) void {
        if (self.counter % 8 < 4) {
            setText("PRESS ANY KEY", text_w / 2 - 6, text_h / 2 + 3);
        }
        if (self.input.left or self.input.right or self.input.up or self.input.down or self.input.jump) {
            self.title_any_key_pressed = true;
        }
        if (self.title_any_key_pressed) {
            self.counter += 1;
        }
        if (self.counter == 80) {
            self.counter = 0;
            self.state = .start;
        }
    }

    fn tickStart(self: *GameData) void {
        if (self.counter % 16 >= 8 and self.counter < 32) {
            setText("READY", text_w / 2 - 2, text_h / 2);
        }
        self.counter += 1;
        if (self.counter >= 48) {
            self.counter = 0;
            self.state = .playing;
        }
    }

    fn tickGameOver(self: *GameData) void {
        if (self.counter > 60) {
            setText("GAME OVER", text_w / 2 - 4, text_h / 2);

            if (self.input.jump and !self.prev_input.jump) {
                self.reset();
            }
        } else {
            self.counter += 1;
        }

        for (&self.enemies) |*enemy| {
            if (enemy.active) enemy.tick(rng, self, cur_stage.attribs);
        }
    }

    fn doVerticalRoomTransition(self: *GameData) void {
        mode_frame += 1;
        const cur_room = cur_stage.rooms[self.cur_room_index];
        const prev_room = cur_stage.rooms[self.prev_room_index];
        if (cur_room.bounds.y >= prev_room.bounds.y + prev_room.bounds.h) {
            // scroll down
            self.scrollr.y = prev_room.bounds.y + @divTrunc(mode_frame * screen_height, 60);
            self.player.box.y = cur_room.bounds.y - self.player.box.h + @divTrunc(mode_frame * self.player.box.h, 60);
        }
        if (cur_room.bounds.y + cur_room.bounds.h <= prev_room.bounds.y) {
            // scroll up
            self.scrollr.y = prev_room.bounds.y - @divTrunc(mode_frame * screen_height, 60);
            self.player.box.y = prev_room.bounds.y - @divTrunc(mode_frame * self.player.box.h, 60);
        }
        if (mode_frame == 60) {
            //player.vy = 0;
            room_transition = .none;
        }
    }

    fn doLtrDoorTransition(self: *GameData) void {
        mode_frame += 1;
        if (mode_frame <= door_duration) {
            self.door1_h = 4 - @as(u8, @intCast(@divTrunc(4 * mode_frame, door_duration)));
        } else if (mode_frame <= door_duration + 64) {
            self.player.tick();
            const cur_room = cur_stage.rooms[self.cur_room_index];
            // const prev_room = cur_stage.rooms[self.prev_room_index];
            self.scrollr.x = cur_room.bounds.x - screen_width + @divTrunc((mode_frame - door_duration) * screen_width, 64);
            self.player.box.x = cur_room.bounds.x - 2 * self.player.box.w + @divTrunc(3 * self.player.box.w * (mode_frame - door_duration), 64);
        } else if (mode_frame <= door_duration + 64 + door_duration) {
            self.door1_h = @intCast(@divTrunc(4 * (mode_frame - 64 - door_duration), door_duration));
        }
        if (mode_frame == door_duration + 64 + door_duration) {
            room_transition = .none;
        }
    }

    fn doRtlDoorTransition(self: *GameData) void {
        mode_frame += 1;
        if (mode_frame <= door_duration) {
            self.door2_h = 4 - @as(u8, @intCast(@divTrunc(4 * mode_frame, door_duration)));
        } else if (mode_frame <= door_duration + 64) {
            self.player.tick();
            // const cur_room = cur_stage.rooms[self.cur_room_index];
            const prev_room = cur_stage.rooms[self.prev_room_index];
            self.scrollr.x = prev_room.bounds.x - @divTrunc((mode_frame - door_duration) * screen_width, 64);
            self.player.box.x = prev_room.bounds.x + self.player.box.w - @divTrunc(3 * self.player.box.w * (mode_frame - door_duration), 64);
        } else if (mode_frame <= door_duration + 64 + door_duration) {
            self.door2_h = @intCast(@divTrunc(4 * (mode_frame - 64 - door_duration), door_duration));
        }
        if (mode_frame == door_duration + 64 + door_duration) {
            room_transition = .none;
        }
    }

    fn tickPlaying(self: *GameData) void {
        if (room_transition != .none) {
            switch (room_transition) {
                .vertical => self.doVerticalRoomTransition(),
                .door_ltr => self.doLtrDoorTransition(),
                .door_rtl => self.doRtlDoorTransition(),
                .none => {},
            }
            return;
        }

        updatePlayer(&self.player);

        for (&self.enemies) |*enemy| {
            if (enemy.active) enemy.tick(rng, self, cur_stage.attribs);
        }

        // check player shots
        for (&self.player.shots) |*shot| {
            if (shot.active) {
                const box = Box{ .x = shot.x - 4, .y = shot.y - 3, .w = 8, .h = 6 };
                for (&self.enemies) |*enemy| {
                    if (enemy.active and box.overlaps(enemy.box)) {
                        enemy.hurt(1);
                        shot.active = false;
                        break;
                    }
                }
            }
        }

        if (findNextRoom(cur_stage.rooms, self.cur_room_index, self.player.box)) |next_room_index| {
            setNextRoom(next_room_index);
            room_transition = .vertical;
            mode_frame = 0;
        }

        // check bottomless pits
        const cur_room = cur_stage.rooms[self.cur_room_index];
        if (!cur_room.bounds.overlaps(self.player.box)) {
            if (self.player.box.y > cur_room.bounds.y + cur_room.bounds.h) {
                self.player.hurt(100);
            }
        }

        // check spikes
        for (cur_room.entities) |entity| {
            if (entity.class == .spike) {
                if (self.player.box.overlaps(entity.box)) {
                    self.player.hurt(100);
                }
            }
        }

        // check if player is dead
        if (self.player.health == 0) {
            self.state = .gameover;
            self.counter = 0;
            death_frame_counter = 0;
            return;
        }

        // check door 1
        if (cur_room.door1_y != Room.no_door) {
            var door_box = Box{
                .x = cur_room.bounds.x,
                .y = cur_room.bounds.y + @as(i32, @intCast(cur_room.door1_y)) * Tile.size,
                .w = Tile.size,
                .h = 4 * Tile.size,
            };
            if (self.player.box.overlaps(door_box)) {
                door_box.x -= 1;
                if (findNextRoom(cur_stage.rooms, self.cur_room_index, door_box)) |next_room_index| {
                    setNextRoom(next_room_index);
                    room_transition = .door_rtl;
                    mode_frame = 0;
                }
            }
        }

        // check door 2
        if (cur_room.door2_y != Room.no_door) {
            var door_box = Box{
                .x = cur_room.bounds.x + cur_room.bounds.w - Tile.size,
                .y = cur_room.bounds.y + @as(i32, @intCast(cur_room.door2_y)) * Tile.size,
                .w = Tile.size,
                .h = 4 * Tile.size,
            };
            if (self.player.box.overlaps(door_box)) {
                door_box.x += 1;
                if (findNextRoom(cur_stage.rooms, self.cur_room_index, door_box)) |next_room_index| {
                    setNextRoom(next_room_index);
                    room_transition = .door_ltr;
                    mode_frame = 0;
                }
            }
        }
    }

    fn tick(self: *GameData) void {
        clearText();
        self.prev_input = self.input;
        self.input = Player.Input.scanGamepad();
        switch (self.state) {
            .title => self.tickTitle(),
            .start => self.tickStart(),
            .playing => self.tickPlaying(),
            .gameover => self.tickGameOver(),
        }
    }
};

var game_data = GameData{};
var cur_stage: Stage = needleman;

fn uploadRoomTexture(texture: *Renderer.Texture, room: Room) void {
    texture.loadFromData(room.data, room.width, room.height);
}

fn clearText() void {
    @memset(text_buffer[0..], ' ');
}

fn setText(text: []const u8, x: usize, y: usize) void {
    std.debug.assert(x < 32 and y < 30);
    @memcpy(text_buffer[text_w * y + x ..][0..text.len], text);
}

fn updatePlayer(player: *Player) void {
    player.tick();

    const room = cur_stage.rooms[game_data.cur_room_index];
    const player_old_x = player.box.x;

    player.handleInput(room, cur_stage.attribs, game_data.input, game_data.prev_input);
    player.move(room, cur_stage.attribs);

    // scrolling
    if (player.box.x != player_old_x) {
        const diff_x = player.box.x - player_old_x;
        const target_x = player.box.x + 8 - screen_width / 2;
        if (game_data.scrollr.x < target_x and diff_x > 0) game_data.scrollr.x += diff_x;
        if (game_data.scrollr.x > target_x and diff_x < 0) game_data.scrollr.x += diff_x;
    }
    if (game_data.scrollr.x < room.bounds.x) game_data.scrollr.x = room.bounds.x;
    if (game_data.scrollr.x > room.bounds.x + room.bounds.w - screen_width) game_data.scrollr.x = room.bounds.x + room.bounds.w - screen_width;
}

// Find a room which overlaps box
fn findNextRoom(rooms: []const Room, skip_room_index: u8, box: Box) ?u8 {
    var room_index: u8 = 0;
    while (room_index < rooms.len) : (room_index += 1) {
        if (room_index == skip_room_index) continue;
        if (rooms[room_index].bounds.overlaps(box)) {
            return room_index;
        }
    }
    return null;
}

fn setNextRoom(next_room_index: u8) void {
    game_data.prev_room_index = game_data.cur_room_index;
    game_data.cur_room_index = next_room_index;
    std.mem.swap(Renderer.Texture, &cur_room_tex, &prev_room_tex);
    uploadRoomTexture(&cur_room_tex, cur_stage.rooms[game_data.cur_room_index]);
}

fn drawTitle() void {
    Sprite.drawFrame(title_tex, Rect.init(0, 0, 160, 48), 0, 32);
}

fn drawHealthbar() void {
    Sprite.drawFrame(healthbar_tex, Rect.init(0, 0, 12, 68), 22, 14);
    const h = 4 + (31 - @as(i32, game_data.player.health)) * 2;
    Sprite.drawFrame(healthbar_tex, Rect.init(12, 0, 12, h), 22, 14);
}

var death_frame_counter: u32 = 0;
fn draw() void {
    Renderer.clear();

    if (game_data.state == .title) {
        drawTitle();
    } else {
        Renderer.scroll.x = game_data.scrollr.x;
        Renderer.scroll.y = game_data.scrollr.y;

        // prev room is visible during transition
        if (room_transition != .none) {
            drawRoom(cur_stage.rooms[game_data.prev_room_index], prev_room_tex, game_data.door2_h, game_data.door1_h);
        }

        drawRoom(cur_stage.rooms[game_data.cur_room_index], cur_room_tex, game_data.door1_h, game_data.door2_h);

        for (game_data.enemies) |enemy| {
            if (enemy.active) enemy.draw();
        }

        if (game_data.state == .start) {
            const player_x = game_data.player.box.x + @divTrunc(game_data.player.box.w, 2);
            const player_y = game_data.player.box.y + game_data.player.box.h;
            effects.drawTeleportEffect(player_x, player_y, game_data.counter);
        } else if (game_data.state == .gameover) {
            if (death_frame_counter < 40 and death_frame_counter % 8 < 4) {
                game_data.player.draw();
            }
            effects.drawDeathEffect(game_data.player.box.x - 4, game_data.player.box.y, death_frame_counter);
            death_frame_counter += 1;
        } else {
            game_data.player.draw();
        }
    }

    // ui
    Renderer.scroll.x = 0;
    Renderer.scroll.y = 0;
    if (game_data.state != .title) drawHealthbar();

    // text layer
    text_tex.updateData(text_buffer[0..]);
    const text_rect = Rect.init(0, 0, screen_width, screen_height);
    Renderer.Tilemap.draw(text_tex, font_tex, text_rect, 8);
}

fn drawRoom(room: Room, room_tex: Renderer.Texture, door1_h: u8, door2_h: u8) void {
    Renderer.Tilemap.draw(room_tex, tiles_tex, room.bounds.toRect(), 16);

    if (room.door1_y != Room.no_door) {
        var i: u8 = 0;
        while (i < door1_h) : (i += 1) {
            Renderer.Sprite.draw(door_sprite, room.bounds.x, room.bounds.y + @as(i32, room.door1_y + i) * Tile.size);
        }
    }
    if (room.door2_y != Room.no_door) {
        var i: u8 = 0;
        while (i < door2_h) : (i += 1) {
            Renderer.Sprite.draw(door_sprite, room.bounds.x + room.bounds.w - Tile.size, room.bounds.y + @as(i32, room.door2_y + i) * Tile.size);
        }
    }

    for (room.entities) |entity| {
        switch (entity.class) {
            .spike => Sprite.draw(spike_sprite, entity.box.x, entity.box.y),
            else => {},
        }
    }
}

pub export fn start() void {
    game_data.reset();
}

pub export fn update() void {
    game_data.tick();
    draw();

    // blitSpriteOpaque(gfx.needleman, 0, 0);
    // blitSpriteOpaque(gfx.title, 0, 40);
    // blitSprite(gfx.font, 16, 0);
    // blitSpriteOpaque(gfx.door, 0, 0);
    // blitSprite(gfx.healthbar, 0, 0);
    // blitSprite(gfx.hurt, 92, 104);
    // blitSprite(gfx.spike, 0, 104);
    // blitSprite(gfx.teleport, 68 - 24, 96);
    // blitSprite(gfx.effects, 0, 72);
    // blitZero();
    // blitGopher();
    // blitSprite(gfx.shot, 100, 112);
}

fn blitZero() void {
    var y: usize = 0;
    while (y < 32) : (y += 1) {
        var x: usize = 0;
        while (x < 24) : (x += 1) {
            const index = gfx.zero.indices.get(y * gfx.zero.w + x);
            if (index == 0) continue;
            cart.framebuffer[(y + 96) * cart.screen_width + x + 80 - 12] = gfx.zero.colors[index];
        }
    }
}

fn blitGopher() void {
    var y: usize = 0;
    while (y < 24) : (y += 1) {
        var x: usize = 0;
        while (x < 24) : (x += 1) {
            const index = gfx.gopher.indices.get(y * gfx.gopher.w + x);
            if (index == 0) continue;
            cart.framebuffer[(y + 104) * cart.screen_width + x + 92] = gfx.gopher.colors[index];
        }
    }
}

pub fn blitSpriteOpaque(sheet: anytype, dx: u32, dy: u32) void {
    var y: usize = 0;
    while (y < sheet.h) : (y += 1) {
        var x: usize = 0;
        while (x < sheet.w) : (x += 1) {
            const index = sheet.indices.get(y * sheet.w + x);
            cart.framebuffer[(y + dy) * cart.screen_width + x + dx] = sheet.colors[index];
        }
    }
}

pub fn blitSprite(sheet: anytype, dx: u32, dy: u32) void {
    var y: usize = 0;
    while (y < sheet.h) : (y += 1) {
        var x: usize = 0;
        while (x < sheet.w) : (x += 1) {
            const index = sheet.indices.get(y * sheet.w + x);
            if (index == 0) continue;
            cart.framebuffer[(y + dy) * cart.screen_width + x + dx] = sheet.colors[index];
        }
    }
}
