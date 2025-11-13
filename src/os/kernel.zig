/// SYCL Badge OS Kernel
/// USB CDC and UART communication
const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const time = rp2xxx.time;
const gpio = rp2xxx.gpio;

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");

const led = gpio.num(25);

pub fn main() !void {
    led.set_function(.sio);
    led.set_direction(.out);
    led.put(1);

    // Initialize UART for debug output
    uart.init();
    uart.println("SYCL Badge OS starting...");

    // Initialize USB
    try usb.init();
    uart.println("USB initialized");

    var old: u64 = time.get_time_since_boot().to_us();
    var new: u64 = 0;
    var i: u32 = 0;

    uart.println("Entering main loop");

    // Main loop - call usb.poll() as often as possible!
    while (true) {
        // CRITICAL: Poll USB frequently
        usb.poll();

        new = time.get_time_since_boot().to_us();
        if (new - old > 1_000_000) { // Every 1 second
            old = new;
            led.toggle();
            i += 1;

            // Send to both USB and UART
            _ = usb.printf("USB message {}\r\n", .{i});

            var uart_buffer: [64]u8 = undefined;
            const uart_msg = std.fmt.bufPrint(&uart_buffer, "UART message {}", .{i}) catch "Error";
            uart.println(uart_msg);

            // Check for incoming USB data
            var rx_buffer: [256]u8 = undefined;
            const bytes_read = usb.receive(&rx_buffer, 0); // Non-blocking read
            if (bytes_read > 0) {
                _ = usb.printf("USB received: {s}\r\n", .{rx_buffer[0..bytes_read]});
                uart.puts("USB received: ");
                uart.println(rx_buffer[0..bytes_read]);
            }
        }
    }
}

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    _ = message;
    while (true) {
        led.put(1);
        time.sleep_ms(100);
        led.put(0);
        time.sleep_ms(100);
    }
}
