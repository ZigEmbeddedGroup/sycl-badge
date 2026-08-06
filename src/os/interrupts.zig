/// This file contains all top-level interrupt handlers,
/// which may then dispatch to subsystems.
const microzig = @import("microzig");
const cpu = microzig.cpu;
const int = cpu.interrupt;
const DMA = microzig.chip.peripherals.DMA;

const audio = @import("drivers/audio.zig");
const lcd = @import("drivers/lcd.zig");

const std = @import("std");

pub const interrupts: microzig.InterruptOptions = .{
    .DMA_IRQ_0 = .{ .c = lcd.interrupt_DMA_0 },
    .HardFault = fault("HardFault"),
    .MemManageFault = fault("MemManageFault"),
    .BusFault = fault("BusFault"),
    .UsageFault = fault("UsageFault"),
    .SecureFault = fault("SecureFault"),
};

pub fn init() void {
    int.enable(.DMA_IRQ_0);
}

fn fault(comptime name: []const u8) microzig.interrupt.Handler {
    return .{ .c = struct {
        fn func() callconv(.c) void {
            std.log.err("fault interrupt: {s}", .{name});
            print_fault_data();
            @breakpoint();
            @panic("unhandled");
        }
    }.func };
}

fn print_fault_data() void {
    std.log.err("The following fault flags are set:", .{});
    const cfsr = cpu.peripherals.scb.CFSR.read();
    const mmfsr = cfsr.MMFSR;
    if (mmfsr.IACCVIOL == 1)
        std.log.err("- Instruction Access Violation", .{});
    if (mmfsr.DACCVIOL == 1)
        std.log.err("- Data Access Violation", .{});
    if (mmfsr.MUNSTKERR == 1)
        std.log.err("- MemManage fault on unstacking for a return from exception", .{});
    if (mmfsr.MSTKERR == 1)
        std.log.err("- MemManage fault on stacking for exception entry", .{});
    if (mmfsr.MLSPERR == 1)
        std.log.err("- A MemManage fault occurred during floating-point lazy state preservation", .{});
    if (mmfsr.MMARVALID == 1)
        std.log.err("- MMAR holds a valid fault address", .{});

    const bfsr = cfsr.BFSR;
    if (bfsr.instruction_bus_error)
        std.log.err("- Instruction Bus Error", .{});
    if (bfsr.precise_data_bus_error)
        std.log.err("- Precise Data Bus Error", .{});
    if (bfsr.imprecise_data_bus_error)
        std.log.err("- Imprecise Data Bus Error", .{});
    if (bfsr.unstacking_exception_error)
        std.log.err("- Unstacking Exception Error", .{});
    if (bfsr.exception_stacking_error)
        std.log.err("- Exception Stacking Error", .{});
    if (bfsr.fpu_lazy_state_preservation_fault)
        std.log.err("- FPU Lazy State Preservation Fault", .{});
    if (bfsr.busfault_address_register_valid)
        std.log.err("- BusFault Address Register Valid: 0x{X}", .{cpu.peripherals.scb.BFAR});

    const ufsr = cfsr.UFSR;
    if (ufsr.undefined_instruction)
        std.log.err("- Undefined Instruction", .{});
    if (ufsr.invalid_state)
        std.log.err("- Invalid State", .{});
    if (ufsr.invalid_pc_load)
        std.log.err("- Invalid PC Load", .{});
    if (ufsr.missing_coprocessor_usage)
        std.log.err("- Missing Coprocessor Usage", .{});
    if (ufsr.unaligned_memory_access)
        std.log.err("- Unaligned Memory Access", .{});
    if (ufsr.divide_by_zero)
        std.log.err("- Divide By Zero", .{});
}
