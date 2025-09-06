//! This demo validates the finalized PCBs.
//!
//! The bootloader demonstrates correct behavior of:
//!
//! - LCD
//! - USB
//! - Neopixels
//!
//! This program will demonstrate correct behavior of:
//!
//! - Buttons
//! - Light Sensor
//! - Speaker
//! - QSPI Flash
//!
//! The program will copy a function into RAM, then call into it from there.
//! This function will take the user through steps to test the different
//! subsystem. The last step will load an image from QSPI flash and display it
//! on the LCD. Once that is done, the function will erase both the QSPI flash
//! and program flash, effectively resetting the device. It will then reboot,
//! and the user should be greeted by the bootloader.
//!
//! In addition to this test, the bootloader should be given an image which
//! attempts to write over it's own address space, and it should be denied.
const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;

const Buttons = board.Buttons;
const led_pin = microzig.board.D13;

pub fn main() void {
    @call(.never_inline, main_impl, .{});
}

pub fn main_impl() linksection(".qspi") callconv(.c) void {
    Buttons.configure();
    led_pin.set_dir(.out);

    const period = 20000;
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
