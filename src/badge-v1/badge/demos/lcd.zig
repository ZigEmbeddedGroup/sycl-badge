const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const mclk = hal.clocks.mclk;
const gclk = hal.clocks.gclk;
const sercom = hal.sercom;
const port = hal.port;
const timer = hal.timer;

const board = microzig.board;
const tft_rst_pin = board.TFT_RST;
const tft_lite_pin = board.TFT_LITE;
const tft_dc_pin = board.TFT_DC;
const tft_cs_pin = board.TFT_CS;
const tft_sck_pin = board.TFT_SCK;
const tft_mosi_pin = board.TFT_MOSI;
const lcd = board.lcd;

var fb: [lcd.width][lcd.height]lcd.Color16 = undefined;

pub fn main() !void {
    tft_rst_pin.set_dir(.out);
    tft_lite_pin.set_dir(.out);
    tft_dc_pin.set_dir(.out);
    tft_cs_pin.set_dir(.out);
    tft_sck_pin.set_dir(.out);
    tft_mosi_pin.set_dir(.out);

    tft_sck_pin.set_mux(.C);
    tft_mosi_pin.set_mux(.C);

    gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK1);
    gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK1);

    // TODO: pin and clock configuration
    mclk.set_apb_mask(.{
        .SERCOM4 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
    });

    timer.init();
    lcd.init(.bpp16, @ptrCast(&fb));

    timer.delay_us(5 * std.time.us_per_s);
    lcd.invert();
    while (true) {}
}
