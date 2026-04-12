//! Hardware to interact with:
//!
//! - LCD Screen
//! - Speaker
//! - 5x Neopixels
//! - Light Sensor
//! - 4x Buttons
//! - Navstick
//! - Red LED
//! - Flash Memory
//!
const hal = @import("microzig").hal;
const port = hal.port;

pub const NeopixelColor = @import("board/neopixel.zig").Color;
pub const Neopixels = @import("board/neopixel.zig").Group(5);
pub const lcd = @import("board/lcd.zig");
pub const audio = @import("board/audio.zig");

pub const TFT_RST = port.pin(.a, 0);
pub const TFT_LITE = port.pin(.a, 1);
pub const A0_SPKR = port.pin(.a, 2);
pub const A1_VCC = port.pin(.a, 3);
pub const A4_VMEAS = port.pin(.a, 4);
pub const A5_D13 = port.pin(.a, 5);
pub const A6_LIGHT = port.pin(.a, 6);
pub const A7_VCC = port.pin(.a, 7);

pub const qspi = [_]port.Pin{
    port.pin(.a, 8),
    port.pin(.a, 9),
    port.pin(.a, 10),
    port.pin(.a, 11),
    port.pin(.b, 10),
    port.pin(.b, 11),
};

pub const D8_NEOPIX = port.pin(.a, 15);
pub const SPKR_EN = port.pin(.a, 23);
pub const @"D-" = port.pin(.a, 24);
pub const @"D+" = port.pin(.a, 25);
pub const SWO = port.pin(.a, 27);
pub const SWCLK = port.pin(.a, 30);
pub const SWDIO = port.pin(.a, 31);
pub const TFT_DC = port.pin(.b, 12);
pub const TFT_SCK = port.pin(.b, 13);
pub const TFT_CS = port.pin(.b, 14);
pub const TFT_MOSI = port.pin(.b, 15);

pub const ButtonPoller = struct {
    pub const mask = port.mask(.b, 0x1FF);

    pub fn init() ButtonPoller {
        mask.set_dir(.in);
        return ButtonPoller{};
    }

    pub fn read_from_port(poller: ButtonPoller) Buttons {
        _ = poller;
        const value = mask.read();
        return @bitCast(@as(u9, @truncate(value)));
    }

    pub const Buttons = packed struct(u9) {
        select: u1,
        start: u1,
        a: u1,
        b: u1,
        up: u1,
        down: u1,
        click: u1,
        right: u1,
        left: u1,
    };
};
