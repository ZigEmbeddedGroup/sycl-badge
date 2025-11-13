/// UART driver for RP2350
/// Thin wrapper around the rp2xxx microzig uart module for having clean kernel
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

// Re-export microzig types
pub const Config = microzig.uart.Config;
pub const WordBits = microzig.uart.WordBits;
pub const StopBits = microzig.uart.StopBits;
pub const Parity = microzig.uart.Parity;
pub const TransmitError = microzig.uart.TransmitError;
pub const ReceiveError = microzig.uart.ReceiveError;

// Use UART0
const uart_instance = hal.uart.instance.num(0);

/// UART0 default settings init (115200 baud, 8N1)
pub fn init() void {
    // Get the clock config
    const clock_config = microzig.clock_config;

    // GPIO pins config for UART0 (GPIO 0 = TX, GPIO 1 = RX)
    const tx_pin = gpio.num(0);
    const rx_pin = gpio.num(1);

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
    const tx_pin = gpio.num(0);
    const rx_pin = gpio.num(1);

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
pub fn writer() microzig.uart.UART.Writer {
    return uart_instance.writer();
}

/// Format and print with std.fmt
pub fn printf(comptime fmt: []const u8, args: anytype) !void {
    try std.fmt.format(writer(), fmt, args);
}
