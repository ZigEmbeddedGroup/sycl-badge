/// Interrupt handling
const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;

pub const IRQ = hal.irq.IRQ; // HAL provides IRQ enum

// Handler storage for custom interrupt handlers
// Use dynamic count based on IRQ enum if possible
const IRQ_COUNT = if (@typeInfo(IRQ) == .Enum) @typeInfo(IRQ).Enum.fields.len else 52;
var handlers: [IRQ_COUNT]?*const fn () void = [_]?*const fn () void{null} ** IRQ_COUNT;

pub fn enable(irq: IRQ) void {
    microzig.cpu.interrupt.enable(irq);
}

pub fn disable(irq: IRQ) void {
    microzig.cpu.interrupt.disable(irq);
}

pub fn registerHandler(irq: IRQ, handler: *const fn () void) void {
    const irq_num = @intFromEnum(irq);
    if (irq_num < handlers.len) {
        handlers[irq_num] = handler;
    }
}

pub fn unregisterHandler(irq: IRQ) void {
    const irq_num = @intFromEnum(irq);
    if (irq_num < handlers.len) {
        handlers[irq_num] = null;
    }
}

pub fn enableInterrupts() void {
    microzig.cpu.interrupt.enable_interrupts();
}

pub fn disableInterrupts() void {
    microzig.cpu.interrupt.disable_interrupts();
}

pub fn areEnabled() bool {
    return microzig.cpu.interrupt.globally_enabled();
}

/// Critical section helper - executes function with interrupts disabled
/// Automatically restores interrupt state after execution
pub fn withInterruptsDisabled(comptime func: anytype) @TypeOf(func()) {
    const was_enabled = microzig.cpu.interrupt.globally_enabled();
    disableInterrupts();
    defer if (was_enabled) enableInterrupts();
    return func();
}

/// Interrupt dispatcher
/// TODO: check if can use microzig.cpu.interrupt.enable(irq) instead of firing up dispatch
/// This gets called by the HAL for each interrupt
/// NOTE: MicroZig may handle this differently - check if needed
pub fn dispatch(irq_num: u32) void {
    if (irq_num < handlers.len) {
        if (handlers[irq_num]) |handler| {
            handler();
        }
    }
}
