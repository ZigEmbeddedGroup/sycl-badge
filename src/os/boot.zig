// boot.zig - RP235X OS Bootloader
// Handles startup, memory initialization, and jumps to kernel main

const std = @import("std");

// Import linker script symbols
extern const __data_start_flash__: u8;
extern var __data_start__: u8;
extern var __data_end__: u8;
extern var __bss_start__: u8;
extern var __bss_end__: u8;
extern const __stack_top__: u32;
extern const __bootmeta_start__: u8;
extern const __bootmeta_end__: u8;
extern const __romfs_start__: u8;
extern const __romfs_end__: u8;

// RP235X Cortex-M33 Vector Table
// ARM requires this at address 0x10000000 (the start of the flash section)
export const vector_table linksection(".vectors") = VectorTable{
    .initial_stack_pointer = &__stack_top__,
    .reset = resetHandler,
    .nmi = nmiHandler,
    .hard_fault = hardFaultHandler,
    .mem_manage = memManageHandler,
    .bus_fault = busFaultHandler,
    .usage_fault = usageFaultHandler,
    .reserved1 = [4]u32{ 0, 0, 0, 0 },
    .svcall = svcallHandler,
    .debug_monitor = debugMonitorHandler,
    .reserved2 = 0,
    .pendsv = pendsvHandler,
    .systick = systickHandler,
    // RP235X has 52 external interrupts (NVIC_TIMER0 to NVIC_SWI5)
    .irq = [52]InterruptHandler{defaultHandler} ** 52,
};

const VectorTable = extern struct {
    initial_stack_pointer: *const u32,
    reset: InterruptHandler,
    nmi: InterruptHandler,
    hard_fault: InterruptHandler,
    mem_manage: InterruptHandler,
    bus_fault: InterruptHandler,
    usage_fault: InterruptHandler,
    reserved1: [4]u32,
    svcall: InterruptHandler,
    debug_monitor: InterruptHandler,
    reserved2: u32,
    pendsv: InterruptHandler,
    systick: InterruptHandler,
    irq: [52]InterruptHandler,
};

const InterruptHandler = *const fn () callconv(.C) void;

// UF2 Boot Metadata Block (for Pico bootloader, unclear if this will need to change later)
const BootMetadata = extern struct {
    magic: u32 = 0x4d474250, // this is used to identify that this is a valid Pico file and is required by the bootloader
    // It evaluates to "PBGM" in ASCII which stands for "Pico Boot Good Magic"
    flash_start: u32 = 0x10000000, // very start of flash
    flash_end: u32 = 0x10200000, // 2MB
    flags: u32 = 0, // TODO: change this if we need to see any flags in the future
    checksum: u32 = calculateChecksum(), // TODO: implement a calculateChecksum() function to set this properly
};

export const boot_metadata linksection(".bootmeta") = BootMetadata{};

// Reset Handler - First code that runs after power-on/reset
export fn resetHandler() callconv(.C) noreturn {
    // 1. Copy .data section from flash to RAM
    copyDataSection();

    // 2. Zero out .bss section (these are the uninitialized variables)
    zeroBssSection();

    // 3. Initialize hardware
    initHardware();

    // 4. Jump to kernel main
    kernelMain();
}

// Copy initialized data from flash to RAM
fn copyDataSection() void {
    const data_flash_start = @intFromPtr(&__data_start_flash__);
    const data_ram_start = @intFromPtr(&__data_start__);
    const data_ram_end = @intFromPtr(&__data_end__);
    const data_size = data_ram_end - data_ram_start;

    if (data_size > 0) {
        const src = @as([*]const u8, @ptrFromInt(data_flash_start));
        const dst = @as([*]u8, @ptrFromInt(data_ram_start));
        @memcpy(dst[0..data_size], src[0..data_size]);
    }
}

// Zero out BSS section (uninitialized variables)
fn zeroBssSection() void {
    const bss_start = @intFromPtr(&__bss_start__);
    const bss_end = @intFromPtr(&__bss_end__);
    const bss_size = bss_end - bss_start;

    if (bss_size > 0) {
        const bss = @as([*]u8, @ptrFromInt(bss_start));
        @memset(bss[0..bss_size], 0);
    }
}

// Initialize basic hardware (clocks, flash, etc.)
fn initHardware() void {
    // RP235X System Control Block (SCB) base
    const SCB_BASE = 0xE000ED00;
    const VTOR = @as(*volatile u32, @ptrFromInt(SCB_BASE + 0x08));

    // Set Vector Table Offset Register to flash start
    VTOR.* = 0x10000000;

    // TODO: Initialize clocks (XOSC, PLLs)
    // TODO: Configure flash wait states for proper speed
    // TODO: Enable instruction cache
    // TODO: Setup MPU for memory protection
}

/// Kernel main entry point (implement this in the OS)
extern fn kernelMain() noreturn;

// Exception Handlers
fn nmiHandler() callconv(.C) void {
    // Non-Maskable Interrupt
    while (true) {}
}

fn hardFaultHandler() callconv(.C) void {
    // Hard Fault - serious error
    // TODO: Print fault registers, stack trace
    while (true) {}
}

fn memManageHandler() callconv(.C) void {
    // Memory Management Fault (MPU violation)
    while (true) {}
}

fn busFaultHandler() callconv(.C) void {
    // Bus Fault (bad memory access)
    while (true) {}
}

fn usageFaultHandler() callconv(.C) void {
    // Usage Fault (undefined instruction, etc.)
    while (true) {}
}

fn svcallHandler() callconv(.C) void {
    // Supervisor Call (system calls)
    // TODO: Implement syscall dispatcher
}

fn debugMonitorHandler() callconv(.C) void {
    // Debug Monitor
    while (true) {}
}

fn pendsvHandler() callconv(.C) void {
    // PendSV (context switching)
    // TODO: Implement task context switch
}

fn systickHandler() callconv(.C) void {
    // SysTick Timer (OS tick)
    // TODO: Implement scheduler tick
}

fn defaultHandler() callconv(.C) void {
    // Default IRQ handler for unhandled interrupts
    // TODO: Implement logging or safe recovery
    while (true) {}
}

fn calculateChecksum() u32 {
    // TODO: verify this is the correct implementation
    return BootMetadata.magic + BootMetadata.flash_start + BootMetadata.flash_end + BootMetadata.flags;
}

// Panic handler for Zig runtime errors
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;

    // TODO: Print panic message via UART/USB
    while (true) {}
}
