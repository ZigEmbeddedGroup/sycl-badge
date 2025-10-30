// kernel.zig
// Main OS kernel entry point
// This is where the OS starts after boot initialization

const std = @import("std");

// Main kernel entry point  (called by boot.zig after hardware init)
export fn kernelMain() noreturn {
    // Initialize kernel subsystems
    initConsole();
    initMemoryAllocator();
    initScheduler();
    initFilesystem();

    // Print boot message
    consolePrint("RP2350 OS Booting...\n");
    consolePrint("Kernel RAM: 128KB\n");
    consolePrint("Process RAM: 384KB\n");
    consolePrint("Flash: 2MB (512KB kernel, 1.5MB user)\n");

    // Load and start initial processes from romfs
    startInitProcess();

    // Enter scheduler loop
    schedulerRun();
}

fn initConsole() void {
    // TODO: Initialize UART or USB CDC for console output (we probably want to use USB right?)
}

fn initMemoryAllocator() void {
    // TODO: Set up kernel heap allocator
    // Use __end__ symbol as heap start
    // Use __heap_limit__ as heap end
}

fn initScheduler() void {
    // TODO: Initialize task scheduler
    // Set up SysTick timer
}

fn initFilesystem() void {
    // TODO: Mount romfs at __romfs_start__
}

fn startInitProcess() void {
    // TODO: Load first user program from romfs
    // Allocate process_ram for it
    // Create initial task
}

fn schedulerRun() noreturn {
    // TODO: Main scheduler loop
    while (true) {
        // Switch to next ready task
        // Handle syscalls
        // Update timers
    }
}

fn consolePrint(msg: []const u8) void {
    _ = msg;
    // TODO: Write to UART/USB
}
