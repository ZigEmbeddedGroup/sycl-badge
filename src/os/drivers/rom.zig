/// ROM driver for RP2354B
/// Provides access to bootrom functions and system reset capabilities
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const rom_api = hal.rom;

// -----------------------------------------------------------------------------
// System Control
// -----------------------------------------------------------------------------

/// Reset to USB bootloader (BOOTSEL mode)
pub fn reset_to_usb_boot() void {
    rom_api.reset_to_usb_boot();
}

// -----------------------------------------------------------------------------
// Bit Manipulation Functions
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Flash Operations
// -----------------------------------------------------------------------------

/// Restore all QSPI pad controls to their default state
pub inline fn connect_internal_flash() void {
    rom_api.connect_internal_flash();
}

/// Configure the SSI to generate a standard 03h serial read command
pub inline fn flash_enter_cmd_xip() void {
    rom_api.flash_enter_cmd_xip();
}

/// Set up SSI for serial-mode operations and issue XIP exit sequence
pub inline fn flash_exit_xip() void {
    rom_api.flash_exit_xip();
}

/// Flush the flash cache
pub inline fn flash_flush_cache() void {
    rom_api.flash_flush_cache();
}

/// Erase a range of flash
pub inline fn flash_range_erase(addr: u32, count: usize, block_size: u32, block_cmd: u8) void {
    rom_api.flash_range_erase(addr, count, block_size, block_cmd);
}

/// Program data to a range of flash addresses
pub inline fn flash_range_program(addr: u32, data: []const u8) void {
    rom_api.flash_range_program(addr, data);
}
