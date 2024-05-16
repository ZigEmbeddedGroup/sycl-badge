const cart = @import("cart-api");

const fb_width = 256;
const fb_height = 240;

pub var scroll = Point.init(0, 0);

pub const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{ .x = x, .y = y };
    }
};

pub const Rect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn init(x: i32, y: i32, w: i32, h: i32) Rect {
        return Rect{ .x = x, .y = y, .w = w, .h = h };
    }
};

pub const Texture = struct {
    width: u32,
    height: u32,
    data: []const u8,

    pub fn loadFromData(self: *Texture, data: []const u8, width: u32, height: u32) void {
        self.data = data;
        self.width = width;
        self.height = height;
    }

    pub fn updateData(self: *Texture, data: []const u8) void {
        self.data = data;
    }
};

pub const Sprite = struct {
    pub fn draw(sprite: anytype, x: i32, y: i32) void {
        const src_rect = Rect.init(0, 0, @intCast(sprite.width), @intCast(sprite.height));
        const dst_rect = Rect.init(x, y, src_rect.w, src_rect.h);
        drawFromTo(sprite, src_rect, dst_rect);
    }

    pub fn drawFrame(sprite: anytype, src_rect: Rect, x: i32, y: i32) void {
        const dst_rect = Rect.init(x, y, src_rect.w, src_rect.h);
        drawFromTo(sprite, src_rect, dst_rect);
    }

    pub fn drawFromTo(sprite: anytype, src_rect: Rect, dst_rect: Rect) void {
        if (@TypeOf(sprite) == Texture) return;
        var src_x0: usize = @intCast(src_rect.x);
        const src_y0: usize = @intCast(src_rect.y);
        const flip_x = src_rect.w < 0;
        if (flip_x) src_x0 -= @intCast(@abs(src_rect.w));
        var y: usize = 0;
        while (y < src_rect.h) : (y += 1) {
            var x: usize = 0;
            while (x < @abs(src_rect.w)) : (x += 1) {
                const dst_x = dst_rect.x + @as(i32, @intCast(x)) - scroll.x;
                const dst_y = dst_rect.y + @as(i32, @intCast(y)) - scroll.y;
                if (dst_x < 0 or dst_x >= cart.screen_width or dst_y < 0 or dst_y >= cart.screen_height) continue;
                const index = (y + src_y0) * sprite.width + (if (flip_x) @abs(src_rect.w) - 1 - x else x) + src_x0;
                const color = sprite.colors[sprite.indices.get(index)];
                if (color.r == 31 and color.g == 0 and color.b == 31) continue;
                cart.framebuffer[@as(usize, @intCast(dst_y * cart.screen_width + dst_x))] = color;
            }
        }
    }
};

pub const Tilemap = struct {
    pub fn draw(map: Texture, tiles: anytype, rect: Rect, tile_size: usize) void {
        const dst_x0 = rect.x - scroll.x;
        const dst_y0 = rect.y - scroll.y;
        var y: usize = 0;
        while (y < rect.h) : (y += 1) {
            const dst_y = dst_y0 + @as(i32, @intCast(y));
            if (dst_y < 0 or dst_y >= cart.screen_height) continue;
            const tile_y = y / tile_size;
            var x: usize = 0;
            while (x < rect.w) : (x += 1) {
                const dst_x = dst_x0 + @as(i32, @intCast(x));
                if (dst_x < 0 or dst_x >= cart.screen_width) continue;
                const tile_x = x / tile_size;
                const tile_index = map.data[tile_y * map.width + tile_x];
                if (tile_index == 0) continue;
                const src_x = (tile_index % 16) * tile_size + (x % tile_size);
                const src_y = (tile_index / 16) * tile_size + (y % tile_size);
                const color = tiles.colors[tiles.indices.get(src_y * tiles.width + src_x)];
                if (color.r == 31 and color.g == 0 and color.b == 31) continue;
                cart.framebuffer[@as(usize, @intCast((dst_y) * cart.screen_width + dst_x))] = color;
            }
        }
    }
};

pub fn init() void {}

pub fn clear() void {
    @memset(cart.framebuffer, .{ .r = 0, .g = 0, .b = 0 });
}
