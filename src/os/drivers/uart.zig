/// UART driver for RP2354B
/// Thin wrapper around the rp2xxx HAL uart module for having clean kernel
///
/// Note: UART0 TX/RX are routed to the TC2030-CTX-NL 6-pin debug connector.
/// This connector provides both SWD (Serial Wire Debug) and UART functionality:
///   - Pin 1: VCC (target voltage reference)
///   - Pin 2: SWDIO (Serial Wire Debug I/O)
///   - Pin 3: GND
///   - Pin 4: SWCLK (Serial Wire Debug Clock)
///   - Pin 5: UART0 TX (GPIO0)
///   - Pin 6: UART0 RX (GPIO1)
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const board = microzig.board;

// Re-export HAL types
pub const Config = hal.uart.Config;
pub const WordBits = hal.uart.WordBits;
pub const StopBits = hal.uart.StopBits;
pub const Parity = hal.uart.Parity;
pub const TransmitError = hal.uart.TransmitError;
pub const ReceiveError = hal.uart.ReceiveError;

// Use UART0
const uart_instance = hal.uart.instance.num(0);

/// UART0 default settings init (115200 baud, 8N1)
pub fn init() void {
    // Get the clock config
    const clock_config = hal.clock_config;

    // GPIO pins config for UART0
    const tx_pin = board.UART0_TX;
    const rx_pin = board.UART0_RX;

    tx_pin.set_function(.uart);
    rx_pin.set_function(.uart);

    // UART config
    uart_instance.apply(.{
        .clock_config = clock_config,
        .baud_rate = 115200,
        .word_bits = .eight,
        .stop_bits = .one,
        .parity = .none,
    });
}

/// UART init with config
pub fn initWithConfig(config: Config) void {
    // Configure GPIO pins for UART0
    const tx_pin = board.UART0_TX;
    const rx_pin = board.UART0_RX;

    tx_pin.set_function(.uart);
    rx_pin.set_function(.uart);

    // Apply config
    uart_instance.apply(config);
}

/// Write single char to UART
pub fn putc(c: u8) void {
    uart_instance.write_blocking(&.{c}, null) catch {};
}

/// Read single char from UART (blocking)
pub fn getc() u8 {
    var byte: u8 = 0;
    _ = uart_instance.read_blocking(&.{&byte}) catch 0;
    return byte;
}

/// Write string to UART
pub fn puts(str: []const u8) void {
    uart_instance.write_blocking(str, null) catch {};
}

/// Write str with newline
pub fn println(str: []const u8) void {
    puts(str);
    putc('\r');
    putc('\n');
}

/// Get a writer with std.fmt
pub fn writer() hal.uart.UART.Writer {
    return uart_instance.writer();
}

/// Format and print with std.fmt
pub fn printf(comptime fmt: []const u8, args: anytype) !void {
    try std.fmt.format(writer(), fmt, args);
}
