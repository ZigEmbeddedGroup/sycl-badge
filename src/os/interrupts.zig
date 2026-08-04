/// This file contains all top-level interrupt handlers,
/// which may then dispatch to subsystems.

const microzig = @import("microzig");
const int = microzig.cpu.interrupt;
const DMA = microzig.chip.peripherals.DMA;

const audio = @import("drivers/audio.zig");

pub const interrupts: microzig.InterruptOptions = .{
    .DMA_IRQ_0 = .{ .c = interrupt_DMA_0 },
};

pub fn init() void {
    int.enable(.DMA_IRQ_0);
    microzig.board.led_pin.put(1);
}

fn interrupt_DMA_0() callconv(.c) void {
    // DMA IRQ 0 is only used by the audio system, so we dispatch straight there
    const irq_bits = DMA.INTS0.raw;
    var handled_bits: u32 = 0;

    handled_bits |= audio.interrupt_DMA_0(irq_bits);

    DMA.INTS0.write_raw(handled_bits);
}
