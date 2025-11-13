const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

// HAL + time imports
const time = microzig.drivers.time;
const system_timer = hal.system_timer;

// Fixed pin list
pub const LED = hal.gpio.num(25);
pub const UART0 = hal.uart.instance(0);
pub const UART_TX = hal.gpio.num(0);
pub const TIMER0 = system_timer.num(0);

// Use HAL-defined interrupt
const TIMER_IRQ = hal.interrupt.Timer0;

//
// -----------------------------------------------------------------------------
// Time utilities
// -----------------------------------------------------------------------------
pub fn get_time_since_boot() time.Absolute {
    return @enumFromInt(TIMER0.read());
}

pub fn sleep_ms(time_ms: u32) void {
    sleep_us(time_ms * 1000);
}

pub fn sleep_us(time_us: u64) void {
    const end_time = time.make_timeout_us(get_time_since_boot(), time_us);
    while (!end_time.is_reached_by(get_time_since_boot())) {}
}

//
// -----------------------------------------------------------------------------
// MicroZig options
// -----------------------------------------------------------------------------
pub const microzig_options: microzig.Options = hal.make_options(.{
    .log_level = .debug,
    .logFn = hal.uart.log,
}, .{ .Timer0 = timer_interrupt });

//
// -----------------------------------------------------------------------------
// Interrupt handler
// -----------------------------------------------------------------------------
fn timer_interrupt() callconv(.c) void {
    const cs = microzig.interrupt.enter_critical_section();
    defer cs.leave();

    std.log.info("toggle LED!", .{});
    LED.toggle();

    TIMER0.clear_interrupt(.alarm0);
    TIMER0.schedule_alarm(.alarm0, TIMER0.read_low() +% 1_000_000);
}

//
// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------
pub fn main() !void {
    // Initialize UART logging
    UART_TX.set_function(.uart);
    UART0.apply(.{ .clock_config = hal.clock_config });
    hal.uart.init_logger(UART0);

    // Configure LED
    LED.set_function(.sio);
    LED.set_direction(.out);

    // Enable timer interrupt
    microzig.cpu.interrupt.enable(TIMER_IRQ);
    TIMER0.set_interrupt_enabled(.alarm0, true);
    TIMER0.schedule_alarm(.alarm0, TIMER0.read_low() +% 1_000_000);

    // Enable machine external interrupts for RISC-V (HAL provides arch info)
    if (hal.compatibility.arch == .riscv) {
        microzig.cpu.interrupt.core.enable(.MachineExternal);
    }

    microzig.cpu.interrupt.enable_interrupts();

    // Wait-for-interrupt loop
    while (true) {
        asm volatile ("wfi");
    }
}
