//adafruit/uf2-samdx1:lib/cmsis/CMSIS/Include/core_cm7.h
fn NVIC_SystemReset() noreturn {
    microzig.cpu.dsb();
    microzig.cpu.peripherals.SCB.AIRCR.write(.{
        .reserved1 = 0,
        .VECTCLRACTIVE = 0,
        .SYSRESETREQ = 1,
        .reserved15 = 0,
        .ENDIANESS = 0,
        .VECTKEY = 0x5FA,
    });
    microzig.cpu.dsb();
    microzig.hang();
}

//adafruit/uf2-samdx1:lib/samd51/include/samd51j19a.h
pub const HSRAM = struct {
    pub const SIZE: usize = 0x00030000; // 192 kB
    pub const ADDR: *align(@divExact(SIZE, 3)) volatile [SIZE]u8 = @ptrFromInt(0x20000000);
};
pub const FLASH = struct {
    pub const SIZE: usize = 0x00080000; // 512 kB
    pub const PAGE_SIZE = 512;
    pub const NB_OF_PAGES = 1024;
    pub const USER_PAGE_SIZE = 512;
    pub const ADDR: *allowzero align(PAGE_SIZE) volatile [SIZE]u8 = @ptrFromInt(0x00000000);
};

//adafruit/uf2-samdx1:inc/uf2.h
const DBL_TAP_PTR: *volatile u32 = std.mem.bytesAsValue(u32, HSRAM.ADDR[HSRAM.ADDR.len - 4 ..]);
const DBL_TAP_MAGIC = 0xf01669ef;
const DBL_TAP_MAGIC_QUICK_BOOT = 0xf02669ef;

//adafruit/uf2-samdx1:src/utils.c
pub fn reset_into_app() noreturn {
    DBL_TAP_PTR.* = DBL_TAP_MAGIC_QUICK_BOOT;
    NVIC_SystemReset();
}

pub fn reset_into_bootloader() noreturn {
    DBL_TAP_PTR.* = DBL_TAP_MAGIC;
    NVIC_SystemReset();
}

const microzig = @import("microzig");
const std = @import("std");
