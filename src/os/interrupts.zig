/// This file contains all top-level interrupt handlers,
/// which may then dispatch to subsystems.

const microzig = @import("microzig");
const int = microzig.cpu.interrupt;
const DMA = microzig.chip.peripherals.DMA;

const audio = @import("drivers/audio.zig");
const lcd = @import("drivers/lcd.zig");

pub const interrupts: microzig.InterruptOptions = .{
    .DMA_IRQ_0 = .{ .c = lcd.interrupt_DMA_0 },
    .DMA_IRQ_1 = .{ .c = audio.interrupt_DMA_1 },
};

pub fn init() void {
    int.enable(.DMA_IRQ_0);
    int.enable(.DMA_IRQ_1);
}
