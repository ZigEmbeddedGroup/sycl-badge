const std = @import("std");
const cart = @import("cart-api");

const black = cart.DisplayColor{
    .r = 0,
    .g = 0,
    .b = 0,
};

const green = cart.DisplayColor{
    .r = 0,
    .g = 63,
    .b = 0,
};

const size = cart.screen_width * cart.screen_height;

var currentbuffer: [size]bool = undefined;
const sw = cart.screen_width;

export fn start() void {
    const mid = cart.screen_width / 2;
    @memset(currentbuffer[mid .. mid + 1], true);
    for (currentbuffer, 0..) |_, i| {
        if (i <= sw) {
            continue;
        } else {
            const l = currentbuffer[i - sw - 1];
            const u = currentbuffer[i - sw];
            const r = currentbuffer[i - sw + 1];

            if (l and u and r) {
                currentbuffer[i] = false;
            } else if (l and u and !r) {
                currentbuffer[i] = false;
            } else if (l and !u and r) {
                currentbuffer[i] = false;
            } else if (l and !u and !r) {
                currentbuffer[i] = true;
            } else if (!l and u and r) {
                currentbuffer[i] = true;
            } else if (!l and u and !r) {
                currentbuffer[i] = true;
            } else if (!l and !u and r) {
                currentbuffer[i] = true;
            } else if (!l and !u and !r) {
                currentbuffer[i] = false;
            }
        }
    }

    for (cart.framebuffer, 0..) |_, i| {
        if (currentbuffer[i]) {
            @memset(cart.framebuffer[i .. i + 1], green);
        } else {
            @memset(cart.framebuffer[i .. i + 1], black);
        }
    }
}

export fn update() void {}
