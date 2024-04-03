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

pub const pin_config = hal.pins.create_config(.{
    .{ .name = "tft_rst", .port = "PA0", .mode = .output },
    .{ .name = "tft_lite", .port = "PA1", .mode = .output },
    .{ .name = "audio", .port = "PA2", .mode = .dac },
    .{ .name = "battery_level", .port = "PA2", .mode = .adc },
    .{ .name = "led", .port = "PA5" },
    .{ .name = "light_sensor", .port = "PA6" },
    .{ .name = "neopixels", .port = "PA15" },
    .{ .name = "spkr_en", .port = "PA23" },
    .{ .name = "D-", .port = "PA24" },
    .{ .name = "D+", .port = "PA25" },
    // TODO: rest
});

pub const TFT_RST = port.pin(.a, 0);
pub const TFT_LITE = port.pin(.a, 1);
pub const A0 = port.pin(.a, 2);
pub const A6_VMEAS = port.pin(.a, 2);
pub const D13 = port.pin(.a, 5);
pub const A7_LIGHT = port.pin(.a, 6);

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

pub const Buttons = packed struct(u9) {
    select: u1,
    start: u1,
    a: u1,
    b: u1,
    up: u1,
    down: u1,
    press: u1,
    right: u1,
    left: u1,

    pub const mask = port.mask(.b, 0x1FF);

    pub fn configure() void {
        mask.set_dir(.in);
    }

    pub fn read_from_port() Buttons {
        return @bitCast(@as(u9, @truncate(mask.read())));
    }
};
