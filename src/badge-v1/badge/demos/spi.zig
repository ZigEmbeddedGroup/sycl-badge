const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const clocks = hal.clocks;
const sercom = hal.sercom;

pub fn main() void {
    clocks.mclk.set_apb_mask(.{ .SERCOM4 = .enabled });
    clocks.gclk.enable_generator(.GCLK1, .DFLL, .{});

    clocks.gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK1);

    board.TFT_RST.set_dir(.out);
    board.TFT_LITE.set_dir(.out);
    board.TFT_DC.set_dir(.out);
    board.TFT_CS.set_dir(.out);

    board.TFT_SCK.set_mux(.C);
    board.TFT_MOSI.set_mux(.C);

    const spi = sercom.spi.Master.init(.SERCOM4, .{
        .cpha = .LEADING_EDGE,
        .cpol = .IDLE_LOW,
        .dord = .MSB,
        .dopo = .PAD2,
        .ref_freq_hz = 48_000_000,
        .baud_freq_hz = 4_000_000,
    });

    while (true) {
        spi.write_blocking(0xAA);
    }
}
