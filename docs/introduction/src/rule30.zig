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

fn gen(l: bool, u: bool, r: bool) bool {
    if (l and u and r) {
        return false;
    } else if (l and u and !r) {
        return false;
    } else if (l and !u and r) {
        return false;
    } else if (l and !u and !r) {
        return true;
    } else if (!l and u and r) {
        return true;
    } else if (!l and u and !r) {
        return true;
    } else if (!l and !u and r) {
        return true;
    } else if (!l and !u and !r) {
        return false;
    }
    return true;
}

export fn start() void {
    const mid = (cart.screen_width * cart.screen_height) - (cart.screen_width / 2);
    @memset(currentbuffer[mid .. mid + 1], true);
}

var linebuffer: [size / cart.screen_height]bool = undefined;

export fn update() void {
    for (linebuffer, 0..) |_, i| {
        var l = currentbuffer[currentbuffer.len - sw + i - 1];
        const u = currentbuffer[currentbuffer.len - sw + i];
        var r = currentbuffer[currentbuffer.len - sw + i + 1];

        if (i == 0) {
            l = currentbuffer[currentbuffer.len - 1];
        }

        if (i == linebuffer.len - 1) {
            r = currentbuffer[currentbuffer.len - sw];
        }

        linebuffer[i] = gen(l, u, r);
    }

    for (currentbuffer[0 .. currentbuffer.len - sw], 0..) |_, i| {
        currentbuffer[i] = currentbuffer[i + sw];
    }

    for (linebuffer, 0..) |_, i| {
        currentbuffer[currentbuffer.len - sw + i] = linebuffer[i];
    }

    for (cart.framebuffer, 0..) |_, i| {
        if (currentbuffer[i]) {
            @memset(cart.framebuffer[i .. i + 1], green);
        } else {
            @memset(cart.framebuffer[i .. i + 1], black);
        }
    }
}
