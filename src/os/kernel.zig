/// SYCL Badge OS Kernel
/// USB CDC communication with interactive console
const std = @import("std");
const microzig = @import("microzig");

const usb = @import("drivers/usb.zig");
const timer = @import("drivers/timer.zig");
const lcd = @import("drivers/lcd.zig");
const console = @import("system/console.zig");
const init = @import("system/init.zig");
const loader = @import("loader/loader.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

pub fn main() !void {
    // Initialize all drivers and kernel systems
    try init.init(.{
        .lcd_pins = lcd.createDT018BTFTPins(),
        .lcd_config = lcd.createDT018BTFTConfig(),
        .init_core1 = true,
    });

    // Display startup message on LCD
    lcd.fillScreen(lcd.BLACK);
    lcd.drawString(10, 20, "SYCL Badge OS", lcd.WHITE, lcd.BLACK, 1);
    lcd.drawString(10, 40, "Team VIKES!", lcd.GREEN, lcd.BLACK, 1);
    lcd.drawString(10, 60, "Ready!", lcd.CYAN, lcd.BLACK, 1);

    // Auto-start cart if only one is present in storage
    // _ = loader.autoStartSingleCart();

    // Main loop
    while (true) {
        // Poll USB frequently for console
        usb.poll();

        // Process console input
        console.processInput();
    }
}

// TODO: add error handling (here or in usb)
// - Check USB init errors
// - Handle buffer overflow in line input
// - Validate command arguments
// - Send error messages back to user
