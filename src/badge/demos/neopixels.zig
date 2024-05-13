const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;

const white: u24 = 0xFFA;
const red: u24 = 0x0F0;

pub fn main() !void {
    const neopixels = board.Neopixels.init(board.D8_NEOPIX);
    neopixels.write_all(.{
        .r = 0xFF,
        .g = 0x00,
        .b = 0x00,
    });

    while (true) {}
}
