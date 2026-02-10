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

// Linker symbols for RAM clearing
extern const __bss_end__: u8;
extern const __kernel_ram_end__: u8;
extern const __process_ram_start__: u8;
extern const __process_ram_end__: u8;
extern const __scratch_x_region_start__: u8;
extern const __scratch_x_region_end__: u8;
extern const __scratch_y_region_start__: u8;
extern const __scratch_y_region_end__: u8;

fn clearRange(start: usize, end: usize) void {
    if (end > start) {
        const dest: [*]u8 = @ptrFromInt(start);
        @memset(dest[0..(end - start)], 0);
    }
}

fn readMsp() usize {
    var sp: usize = 0;
    asm volatile ("mrs %[out], msp"
        : [out] "=r" (sp),
    );
    return sp;
}

fn clearOnBoot() void {
    // Clear kernel RAM after .bss (heap/shared_mem/unused).
    clearRange(@intFromPtr(&__bss_end__), @intFromPtr(&__kernel_ram_end__));

    // Clear all process RAM before Core 1 starts.
    clearRange(@intFromPtr(&__process_ram_start__), @intFromPtr(&__process_ram_end__));

    // Clear scratch X entirely (IRQ stack is not in use with interrupts disabled).
    clearRange(@intFromPtr(&__scratch_x_region_start__), @intFromPtr(&__scratch_x_region_end__));

    // Clear scratch Y below the current MSP to avoid clobbering the active stack.
    const scratch_y_start = @intFromPtr(&__scratch_y_region_start__);
    const scratch_y_end = @intFromPtr(&__scratch_y_region_end__);
    const sp = readMsp();
    const clear_end = if (sp < scratch_y_end) sp else scratch_y_end;
    if (clear_end > scratch_y_start) {
        clearRange(scratch_y_start, clear_end);
    }

    microzig.cpu.dmb();
}

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
    const boot_start = timer.micros();

    // Disable interrupts early to avoid unhandled IRQ panics during init.
    interrupts.disableInterrupts();
    // Scrub RAM regions that are not guaranteed to reset on warm boots.
    clearOnBoot();
    // Copy RAM-resident flash helpers before any flash writes.
    copyRamTextSection();
    // 1. Initialize GPIO subsystem
    gpio.init();

    // 2. Initialize LED
    gpio.initLED();

    // 3. Initialize Buttons (joystick and face buttons)
    gpio.initButtons();

    // 4. Initialize UART for debug output (must be before any uart.println calls)
    uart.init();
    uart.println("SYCL Badge OS starting...");
    uart.println("GPIO initialized");
    uart.println("LED initialized");
    uart.println("Buttons initialized");
    uart.println("UART initialized");

    // 5. Initialize cart storage (FAT16 in romfs) before USB starts
    // This avoids USB timeouts while formatting flash on first boot.
    storage.init();
    uart.println("Cart storage initialized");
    {
        var buf: [96]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "ROMFS sectors: {d}\r\n", .{storage.totalSectors()}) catch "";
        uart.puts(text);
    }

    // 6. Initialize USB
    const usb_start = timer.micros();
    try usb.init();
    uart.println("USB initialized");

    // 7. Wait for USB enumeration
    const usb_enum_timeout_ms: u32 = 100;
    const start_time = timer.millis();
    while (timer.millis() - start_time < usb_enum_timeout_ms) {
        usb.poll();
    }
    const usb_time = timer.micros() - usb_start;

    // 8. Initialize shared memory (for IPC)
    shared_mem.init();
    uart.println("Shared memory initialized");

    // 9. Initialize console (shows welcome message and prompt)
    console.init();

    // 10. Leave interrupts disabled for now (polling-based drivers)
    uart.println("Interrupts disabled");

    // 11. Initialize LCD if configured
    if (config.lcd_pins) |lcd_pins| {
        if (config.lcd_config) |lcd_cfg| {
            const lcd_start = timer.micros();
            // Initialize LCD with all pins (handles SPI and TE pin configuration)
            lcd.initWithAllPins(lcd_pins, lcd_cfg) catch |err| {
                uart.println("LCD initialization failed");
                return err;
            };
            const lcd_time = timer.micros() - lcd_start;
            {
                var buf: [64]u8 = undefined;
                const text = std.fmt.bufPrint(&buf, "LCD initialized ({d}ms)\r\n", .{lcd_time / 1000}) catch "";
                uart.puts(text);
            }
        } else {
            uart.println("LCD pins provided but no config - skipping LCD init");
        }
    }

    // 12. Initialize Core 1 if chosen (should always be chosen in practice)
    if (config.init_core1) {
        const core1_start = timer.micros();
        if (config.core1_entrypoint) |entrypoint| {
            multicore.initCore1WithEntrypoint(entrypoint);
        } else {
            multicore.initCore1();
        }
        const core1_time = timer.micros() - core1_start;
        {
            var buf: [64]u8 = undefined;
            const text = std.fmt.bufPrint(&buf, "Core 1 initialized ({d}ms)\r\n", .{core1_time / 1000}) catch "";
            uart.puts(text);
        }
    }

    const boot_time = timer.micros() - boot_start;
    {
        var buf: [96]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "System initialization complete (total: {d}ms, USB: {d}ms)\r\n", .{ boot_time / 1000, usb_time / 1000 }) catch "";
        uart.puts(text);
    }
}
