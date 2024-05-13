//! This is firmware for the SYCL badge.
//!
//! The badge image
//! For normal operation, the default app will run. Pressing select will go to
//! the main menu. The default app will display the SYCL logo, users will be
//! able to change the default app.
//!
//! Apps will have the option to to save state to non-volatile memory. This
//! will prompt the user. The user will either exit without saving, save and
//! exit, or cancel.
//!
//! TODO:
//! - USB mass drive
//! - USB CDC logging
const std = @import("std");

const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;

const led_pin = board.D13;

const Lcd = board.Lcd;
const Buttons = board.Buttons;

const peripherals = microzig.chip.peripherals;
const MCLK = peripherals.MCLK;

pub fn main() !void {
    // Initialize clocks
    MCLK.AHBMASK.modify(.{ .USB_ = 1 });
    MCLK.APBBMASK.modify(.{ .USB_ = 1 });

    // Initialize pins
    led_pin.set_dir(.out);

    const period = 200000;
    while (true) {
        delay_count(period);
        led_pin.write(.high);
        delay_count(period);
        led_pin.write(.low);
    }
}

fn delay_count(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {}
}
