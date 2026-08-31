/// System initialization for Core 0 (kernel)
/// Centralizes all driver and kernel system initialization
const std = @import("std");
const microzig = @import("microzig");
const interrupt = microzig.interrupt;
const interrupts = @import("../interrupts.zig");

// Driver imports
const gpio = @import("../drivers/gpio.zig");
const audio = @import("../drivers/audio.zig");
const usb = @import("../drivers/usb.zig");
const timer = @import("../drivers/timer.zig");
const lcd = @import("../drivers/lcd.zig");
const rom = @import("../drivers/rom.zig");
const loader = @import("../loader/loader.zig");
const rev = @import("../drivers/rev.zig");
const rtt = @import("../drivers/rtt.zig");
const terry = @import("../system/terry.zig");
const uart = @import("../drivers/uart.zig");
const i2c = @import("../drivers/i2c.zig");

// System imports
const console = @import("console.zig");
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
extern const __stack_limit__: u8;

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
    // Set the stack limit
    asm volatile (
        \\  msr msplim, %[splim]
        :
        : [splim] "r" (&__stack_limit__),
    );

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
    /// LCD pin configuration (includes both control and SPI pins)
    /// Use lcd.createDT018BTFTPins() to create this
    lcd_pins: lcd.LCDPins,

    /// LCD driver configuration (required if lcd_pins is set)
    /// Use lcd.createDT018BTFTConfig() to create this
    lcd_config: lcd.Config,

    /// Whether to initialize Core 1
    init_core1: bool = false,

    /// Custom entrypoint for Core 1 (if null, uses default cart.main)
    core1_entrypoint: ?*const fn () void = null,

    /// Amount of time to wait for a Tracy server to connect before running
    /// any initialization. This will look like a stall if you don't know
    /// it's coming.
    early_wait_for_tracy_time: u64 = 0,

    /// Amount of time to wait for a tracy server to connect after initialization
    /// but before the main loop starts. This will display a nice message on
    /// the screen telling the user that it's waiting.
    late_wait_for_tracy_time: u64 = 0,
};

/// Initialize all drivers and kernel systems
/// This function should be called once at kernel startup
/// Returns error if USB or LCD initialization fails
pub fn init(config: InitConfig) !void {
    const boot_start = timer.micros();

    // Disable interrupts early to avoid unhandled IRQ panics during init.
    interrupt.disable_interrupts();

    // Scrub RAM regions that are not guaranteed to reset on warm boots.
    clearOnBoot();
    // Copy RAM-resident flash helpers before any flash writes.
    copyRamTextSection();

    // -1. Set up RTT and terry for monitoring initialization
    rtt.init();
    if (config.early_wait_for_tracy_time != 0) {
        const deadline = timer.micros() + config.early_wait_for_tracy_time;
        _ = terry.client.wait_for_connection(deadline) catch {};
    }

    const z = terry.core0.zone("Initialize", @src());
    defer z.end();

    // 0. Detect board revision
    rev.init();

    std.log.info("=================================================", .{});
    std.log.info("INITIALIZING KERNEL", .{});
    std.log.info("=================================================", .{});

    // 1. Initialize GPIO subsystem
    gpio.init();

    // 2. Initialize LED
    gpio.initLED();

    // 3. Initialize Buttons (joystick and face buttons)
    gpio.initButtons();

    // 4. Initialize buzzer (GPIO 8/9 for CMT-7525-80 magnetic buzzer)
    audio.init();

    i2c.init();

    // 5. Initialize cart storage (FAT16 in romfs) before USB starts
    // This avoids USB timeouts while formatting flash on first boot.
    // Ensure internal flash is connected before any ROM access (improves persistence across power cycles)
    rom.connect_internal_flash();
    storage.init();

    // 5. Initialize USB
    try usb.init();

    // 6. Wait for USB enumeration
    const usb_enum_timeout_ms: u32 = 100;
    const start_time = timer.millis();
    while (timer.millis() - start_time < usb_enum_timeout_ms) {
        usb.poll();
    }

    // 7. Initialize shared memory (for IPC)
    shared_mem.init();

    // 8. Initialize console (shows welcome message and prompt)
    console.init();

    // 9. Enable interrupts now that all drivers are initialized.
    // Flash operations disable interrupts locally around the XIP-off window and restore
    // the previous state on exit, so they are safe to call with interrupts enabled.
    interrupts.init();
    interrupt.enable_interrupts();

    // 10. Initialize LCD if configured
    // Initialize LCD with all pins (handles SPI and TE pin configuration)
    lcd.initWithAllPins(config.lcd_pins, config.lcd_config) catch |err| {
        return err;
    };

    // 11. Wait for late tracy connection after initialization, with friendly screen message
    if (config.late_wait_for_tracy_time != 0 and terry.client.is_waiting_for_connection()) {
        const deadline = timer.micros() + config.late_wait_for_tracy_time;
        lcd.clearScreen(lcd.BLACK);
        while (lcd.isBusy() and terry.client.is_waiting_for_connection()) {
            terry.client.poll();
        }
        while (lcd.isBusy()) {}
        const msg = "Waiting for Tracy";
        lcd.drawString(@intCast(lcd.width / 2 - (msg.len * 4)), lcd.height / 2 - 4, msg, lcd.CYAN, lcd.BLACK, 1);
        if (terry.client.is_waiting_for_connection()) {
            while (true) {
                terry.client.poll();
                if (!terry.client.is_waiting_for_connection()) break;
                if (timer.millis() > deadline) break;
            }
        }
    }

    // 12. Initialize Core 1 if chosen (should always be chosen in practice)
    if (config.init_core1) {
        if (config.core1_entrypoint) |entrypoint| {
            multicore.initCore1WithEntrypoint(entrypoint);
        } else {
            multicore.initCore1();
        }
    }

    loader.init();

    _ = boot_start;
}
