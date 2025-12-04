/// Panic handler for kernel
const std = @import("std");
const microzig = @import("microzig");
const multicore = @import("multicore.zig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;
const uart = @import("../drivers/uart.zig");
const usb = @import("../drivers/usb.zig");
const timer = @import("../drivers/timer.zig");

const led = gpio.num(25);

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    // Disable interrupts to prevent further issues
    asm volatile ("cpsid i");

    // Output panic message to UART
    uart.puts("\r\n!!! KERNEL PANIC !!!\r\n");
    uart.puts("Message: ");
    uart.println(message);
    uart.puts("System halted.\r\n");

    // Try to output to USB as well (may not work if USB is the cause)
    _ = usb.printf("\r\n!!! KERNEL PANIC !!!\r\nMessage: {s}\r\nSystem halted.\r\n", .{message}); // Rapid LED blink pattern to indicate panic state
    while (true) {
        led.put(1);
        timer.sleep_ms(100);
        led.put(0);
        timer.sleep_ms(100);
    }
}
