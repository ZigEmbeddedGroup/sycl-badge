const cart = @import("cart-api");
const gfx = @import("gfx");

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

pub export fn start() void {}

pub export fn update() void {
    blitSpriteOpaque(gfx.needleman, 0, 0);
    blitSpriteOpaque(gfx.title, 0, 40);
    blitSprite(gfx.font, 16, 0);
    blitSpriteOpaque(gfx.door, 0, 0);
    blitSprite(gfx.healthbar, 0, 0);
    blitSprite(gfx.hurt, 92, 104);
    blitSprite(gfx.spike, 0, 104);
    blitSprite(gfx.teleport, 68 - 24, 96);
    blitSprite(gfx.effects, 0, 72);
    blitZero();
    blitGopher();
    blitSprite(gfx.shot, 100, 112);
}
