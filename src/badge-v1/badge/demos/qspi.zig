const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const gclk = hal.clocks.gclk;
const mclk = hal.clocks.mclk;
const qspi = hal.qspi;
const nvm = hal.nvm;

const ext_flash: *u8 = @ptrFromInt(0x0400_0000);

pub fn main() !void {
    mclk.set_apb_mask(.{
        .QSPI = .enabled,
    });
    mclk.set_ahb_mask(.{
        .QSPI = .enabled,
        // only needed for DDR (TODO: what is that?)
        .QSPI_2X = .stopped,
    });

    qspi.init();

    while (true) {}
}
