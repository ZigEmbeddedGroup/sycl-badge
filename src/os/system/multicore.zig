/// Multicore management
const std = @import("std");
const microzig = @import("microzig");
const cart = @import("../cart.zig");
const hal = microzig.hal;
const interrupt = microzig.interrupts;
const peripherals = microzig.chip.peripherals;

const CriticalSection = interrupt.CriticalSection;
const SIO = peripherals.SIO;
const PSM = peripherals.PSM;
const PPB = peripherals.PPB;
var core1_stack: [128]u32 = undefined;
extern const _external_interrupt_table: usize; // For riscv only

pub const fifo = hal.multicore.fifo;

pub fn launch_core1(entrypoint: *const fn () void) void {
    hal.multicore.launch_with_stack(entrypoint, &core1_stack);
}

pub fn launch_core1_with_stack(entrypoint: *const fn () void, stack: []u32) void {
    hal.multicore.launch_with_stack(entrypoint, stack);
}
