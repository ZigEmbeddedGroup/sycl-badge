const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const mclk = hal.clocks.mclk;
const gclk = hal.clocks.gclk;
const sercom = hal.sercom;
const port = hal.port;
const timer = hal.timer;
const clocks = hal.clocks;

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

    clocks.gclk.enable_generator(.GCLK0, .OSCULP32K, .{});
    clocks.gclk.enable_generator(.GCLK2, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    clocks.enable_dpll(0, .GCLK2, .{
        .factor = 1,
        .input_freq_hz = 1_000_000,
        .output_freq_hz = 120_000_000,
    });

    clocks.gclk.enable_generator(.GCLK0, .DPLL0, .{});

    gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK0);
    gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK2);

    // TODO: pin and clock configuration
    mclk.set_apb_mask(.{
        .SERCOM4 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
    });
    mclk.set_ahb_mask(.{
        .DMAC = .enabled,
    });

    timer.init();
    var lcd = Lcd.init(.{
        .spi = sercom.spi.Master.init(.SERCOM4, .{
            .cpha = .LEADING_EDGE,
            .cpol = .IDLE_LOW,
            .dord = .MSB,
            .dopo = .PAD2,
            .ref_freq_hz = 48_000_000,
            .baud_freq_hz = 12_000_000,
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

    while (true) {
        lcd.clear_screen(.{
            .r = 31,
            .g = 0,
            .b = 0,
        });
        lcd.clear_screen(.{
            .r = 0,
            .g = 63,
            .b = 0,
        });
    }
}
