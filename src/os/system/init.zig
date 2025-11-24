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

    // 4. Initialize USB
    try usb.init();
    uart.println("USB initialized");

    // 5. Wait for USB enumeration
    timer.sleep_ms(500);

    // 6. Initialize shared memory (for IPC)
    shared_mem.init();
    uart.println("Shared memory initialized");

    // 7. Initialize console (shows welcome message and prompt)
    console.init();

    // 8. Enable interrupts
    interrupts.enableInterrupts();
    uart.println("Interrupts enabled");

    // 9. Initialize LCD if configured
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

    // 10. Optional: Initialize Core 1 if chosen (this is for the user program loader)
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
