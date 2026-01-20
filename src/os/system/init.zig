/// System initialization for Core 0 (kernel)
/// Centralizes all driver and kernel system initialization
const std = @import("std");
const microzig = @import("microzig");

// Driver imports
const gpio = @import("../drivers/gpio.zig");
const uart = @import("../drivers/uart.zig");
const usb = @import("../drivers/usb.zig");
const timer = @import("../drivers/timer.zig");
const lcd = @import("../drivers/lcd.zig");

// System imports
const console = @import("console.zig");
const interrupts = @import("interrupts.zig");
const multicore = @import("multicore.zig");
const shared_mem = @import("../ipc/shared_mem.zig");
const storage = @import("../loader/storage.zig");

// Linker symbols for RAM-resident text (.ram_text)
extern const __ram_text_load__: u8;
extern var __ram_text_start__: u8;
extern var __ram_text_end__: u8;

fn copyRamTextSection() void {
    const text_flash_start = @intFromPtr(&__ram_text_load__);
    const text_ram_start = @intFromPtr(&__ram_text_start__);
    const text_ram_end = @intFromPtr(&__ram_text_end__);
    const text_size = text_ram_end - text_ram_start;
    if (text_size > 0) {
        const src = @as([*]const u8, @ptrFromInt(text_flash_start));
        const dst = @as([*]u8, @ptrFromInt(text_ram_start));
        @memcpy(dst[0..text_size], src[0..text_size]);
    }
}

/// Configuration for system initialization
pub const InitConfig = struct {
    /// LCD pin configuration (optional, includes both control and SPI pins)
    /// Use lcd.createDT018BTFTPins() to create this
    lcd_pins: ?lcd.LCDPins = null,

    /// LCD driver configuration (optional, required if lcd_pins is set)
    /// Use lcd.createDT018BTFTConfig() to create this
    lcd_config: ?lcd.Config = null,

    /// Whether to initialize Core 1
    init_core1: bool = false,

    /// Custom entrypoint for Core 1 (if null, uses default cart.main)
    core1_entrypoint: ?*const fn () void = null,
};

/// Initialize all drivers and kernel systems
/// This function should be called once at kernel startup
/// Returns error if USB or LCD initialization fails
pub fn init(config: InitConfig) !void {
    // Disable interrupts early to avoid unhandled IRQ panics during init.
    interrupts.disableInterrupts();
    // Copy RAM-resident flash helpers before any flash writes.
    copyRamTextSection();
    // 1. Initialize GPIO subsystem
    gpio.init();

    // 2. Initialize LED
    gpio.initLED();

    // 3. Initialize UART for debug output (must be before any uart.println calls)
    uart.init();
    uart.println("SYCL Badge OS starting...");
    uart.println("GPIO initialized");
    uart.println("LED initialized");
    uart.println("UART initialized");

    // 4. Initialize cart storage (FAT16 in romfs) before USB starts
    // This avoids USB timeouts while formatting flash on first boot.
    storage.init();
    uart.println("Cart storage initialized");
    {
        var buf: [96]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "ROMFS sectors: {d}\r\n", .{storage.totalSectors()}) catch "";
        uart.puts(text);
    }

    // 5. Initialize USB
    try usb.init();
    uart.println("USB initialized");

    // 6. Wait for USB enumeration
    timer.sleep_ms(500);

    // 7. Initialize shared memory (for IPC)
    shared_mem.init();
    uart.println("Shared memory initialized");

    // 8. Initialize console (shows welcome message and prompt)
    console.init();

    // 9. Leave interrupts disabled for now (polling-based drivers)
    uart.println("Interrupts disabled");

    // 10. Initialize LCD if configured
    if (config.lcd_pins) |lcd_pins| {
        if (config.lcd_config) |lcd_cfg| {
            // Initialize LCD with all pins (handles SPI and TE pin configuration)
            lcd.initWithAllPins(lcd_pins, lcd_cfg) catch |err| {
                uart.println("LCD initialization failed");
                return err;
            };
            uart.println("LCD initialized");
        } else {
            uart.println("LCD pins provided but no config - skipping LCD init");
        }
    }

    // 11. Optional: Initialize Core 1 if chosen (this is for the user program loader)
    if (config.init_core1) {
        if (config.core1_entrypoint) |entrypoint| {
            multicore.initCore1WithEntrypoint(entrypoint);
        } else {
            multicore.initCore1();
        }
        uart.println("Core 1 initialized");
    }

    uart.println("System initialization complete");
}
