/// DMA Driver for RP2350 family

const std = @import("std");
const microzig = @import("microzig");
const chip = microzig.chip;
const peripherals = chip.peripherals;

// base addresses (SPI0=0x40080000, SPI1=0x40088000, DMA=0x50000000)
const DMA = peripherals.DMA;
const SPI0 = peripherals.SPI0;
const SPI1 = peripherals.SPI1;

// Ch0 is used for LCD DMA transfers
const LCD_CHANNEL: u4 = 0;

// Stored LCD DMA config for resetting between transfers
var lcd_framebuffer_addr: u32 = 0;
var lcd_framebuffer_len: u28 = 0;
var lcd_spi_dr_addr: u32 = 0;

/// Init DMA ctrl (already init by boot ROM)
pub fn init() void {
}

/// Config DMA ch0 for LCD SPI transfer
pub fn initLCD(
    spi_instance_num: u1,
    framebuffer: []const u8,
) void {
    // (SPI0 base = 0x40080000, SSPDR offset = 0x08 → 0x40080008)
    const spi_dr_addr: u32 = switch (spi_instance_num) {
        0 => @intFromPtr(&SPI0.SSPDR),
        1 => @intFromPtr(&SPI1.SSPDR),
    };

    // Enable TX DMA on SPI peripheral via SSPDMACR reg
    switch (spi_instance_num) {
        0 => SPI0.SSPDMACR.modify(.{ .TXDMAE = 1 }),
        1 => SPI1.SSPDMACR.modify(.{ .TXDMAE = 1 }),
    }

    // Store config for resetting between transfers
    lcd_framebuffer_addr = @intFromPtr(framebuffer.ptr);
    lcd_framebuffer_len = @intCast(framebuffer.len);
    lcd_spi_dr_addr = spi_dr_addr;

    // spi0_tx = 0x18 (24), spi1_tx = 0x1a (26)
    const treq: @TypeOf(DMA.CH0_CTRL_TRIG.read().TREQ_SEL) = switch (spi_instance_num) {
        0 => .spi0_tx,
        1 => .spi1_tx,
    };

    // Disable ch first
    DMA.CH0_CTRL_TRIG.modify(.{ .EN = 0 });

    // Wait to become idle
    while (DMA.CH0_CTRL_TRIG.read().BUSY != 0) {}

    // Set source addr
    DMA.CH0_READ_ADDR.write(.{ .CH0_READ_ADDR = lcd_framebuffer_addr });

    // Set dest addr
    DMA.CH0_WRITE_ADDR.write(.{ .CH0_WRITE_ADDR = spi_dr_addr });

    // Set transfer count
    DMA.CH0_TRANS_COUNT.write(.{ .COUNT = lcd_framebuffer_len, .MODE = .NORMAL });

    // Config ctrl reg
    // INCR_READ_REV (bit 5) and INCR_WRITE_REV (bit 7)
    DMA.CH0_CTRL_TRIG.write(.{
        .EN = 0, // Don't start yet
        .HIGH_PRIORITY = 1,
        .DATA_SIZE = .size_8, // Byte transfers (SPI is in 8-bit mode)
        .INCR_READ = 1, // Increment read addr
        .INCR_READ_REV = 0, // Normal fwd increment
        .INCR_WRITE = 0,
        .INCR_WRITE_REV = 0,
        .RING_SIZE = .RING_NONE,
        .RING_SEL = 0,
        .CHAIN_TO = LCD_CHANNEL, // No chaining
        .TREQ_SEL = treq, // SPI TX DREQ
        .IRQ_QUIET = 1, // No interrupts
        .BSWAP = 0,
        .SNIFF_EN = 0,
        .BUSY = 0,
        .WRITE_ERROR = 0,
        .READ_ERROR = 0,
        .AHB_ERROR = 0,
    });
}

/// Start DMA transfer
pub fn startLCD() void {
    // Reset read addr for this transfer
    DMA.CH0_READ_ADDR.write(.{ .CH0_READ_ADDR = lcd_framebuffer_addr });

    // Reset transfer count
    DMA.CH0_TRANS_COUNT.write(.{ .COUNT = lcd_framebuffer_len, .MODE = .NORMAL });

    // Start transfer
    DMA.CH0_CTRL_TRIG.modify(.{ .EN = 1 });
}

/// Stop DMA transfer
pub fn stopLCD() void {
    DMA.CH0_CTRL_TRIG.modify(.{ .EN = 0 });

    // Wait for ch to become idle
    while (DMA.CH0_CTRL_TRIG.read().BUSY != 0) {}
}

/// Check if DMA transfer is in progress
pub fn isLCDbusy() bool {
    return DMA.CH0_CTRL_TRIG.read().BUSY != 0;
}

/// Wait for DMA transfer to complete
pub fn waitLCD() void {
    while (DMA.CH0_CTRL_TRIG.read().BUSY != 0) {}
}

/// Reconfig DMA with new framebuffer pointer and len
pub fn updateLCD(framebuffer: []const u8) void {
    const was_busy = DMA.CH0_CTRL_TRIG.read().BUSY != 0;

    // Stop if running
    if (was_busy) {
        stopLCD();
    }

    // Update source addr and count
    lcd_framebuffer_addr = @intFromPtr(framebuffer.ptr);
    lcd_framebuffer_len = @intCast(framebuffer.len);
    DMA.CH0_READ_ADDR.write(.{ .CH0_READ_ADDR = lcd_framebuffer_addr });
    DMA.CH0_TRANS_COUNT.write(.{ .COUNT = lcd_framebuffer_len, .MODE = .NORMAL });

    // Restart if it was running
    if (was_busy) {
        startLCD();
    }
}
