const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const mclk = hal.mclk;
const gclk = hal.gclk;
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
const Lcd = board.Lcd;

var fb: [Lcd.width][Lcd.height]Lcd.Color16 = undefined;

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
    const lcd = Lcd.init(.{
        .spi = sercom.spi.Master.init(.SERCOM4, .{
            .cpha = .LEADING_EDGE,
            .cpol = .IDLE_LOW,
            .dord = .MSB,
            .dopo = .PAD2,
            .ref_freq_hz = 48_000_000,
            .baud_freq_hz = 4_000_000,
        }),
        .pins = .{
            .rst = tft_rst_pin,
            .lite = tft_lite_pin,
            .dc = tft_dc_pin,
            .cs = tft_cs_pin,
            .sck = tft_sck_pin,
            .mosi = tft_mosi_pin,
        },
        .fb = .{
            .bpp16 = &fb,
        },
    });

    lcd.clear_screen(.{
        .r = 31,
        .g = 0,
        .b = 0,
    });
    lcd.set_window(0, 0, 10, 10);

    //Lcd.fill16(red16);
    timer.delay_us(5 * std.time.us_per_s);
    lcd.invert();
    while (true) {}
}
