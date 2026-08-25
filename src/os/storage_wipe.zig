/// Storage wipe firmware for SYCL Badge V2 (RP2354B)
/// Erases the romfs and cart_xip flash regions so a subsequent sycl-os
/// flash boots with no carts loaded, then reboots into BOOTSEL.
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const time = hal.time;
const flash = hal.flash;
const rom = hal.rom;

// Flash layout from src/os/linker.ld: kernel (512K), then romfs at
// 0x10080000 (1280K) and cart_xip at 0x101C0000 (256K). Wipe everything
// from the start of romfs to the end of the 2MB flash.
const XIP_BASE: u32 = 0x10000000;
const ROMFS_START: u32 = 0x10080000;
const FLASH_END: u32 = 0x10200000;
const WIPE_OFFSET: u32 = ROMFS_START - XIP_BASE;
const WIPE_LEN: u32 = FLASH_END - ROMFS_START;

const led_pin = gpio.num(14);

pub fn main() !void {
    led_pin.set_function(.sio);
    led_pin.set_direction(.out);
    led_pin.put(1);

    flash.range_erase(WIPE_OFFSET, WIPE_LEN);

    // Blink to signal the wipe is done.
    for (0..10) |_| {
        led_pin.put(0);
        time.sleep_ms(100);
        led_pin.put(1);
        time.sleep_ms(100);
    }

    // Blocks until the badge reboots into BOOTSEL; never returns.
    rom.reset_to_usb_boot();
}
