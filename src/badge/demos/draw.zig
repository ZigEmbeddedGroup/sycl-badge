const cart = @import("cart-api");

pub export fn start() void {}

var tick: u32 = 0;

pub export fn update() void {
    @memset(cart.framebuffer, @bitCast(@as(u16, @bitCast(switch (@as(u1, @truncate(tick))) {
        0 => cart.DisplayColor{ .r = 0x1f, .g = 0x00, .b = 0x00 },
        1 => cart.DisplayColor{ .r = 0x00, .g = 0x3f, .b = 0x00 },
    }))));
    tick +%= 1;
}
