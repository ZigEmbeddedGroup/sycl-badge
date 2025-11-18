/// SYCL Badge OS Kernel
/// USB CDC and UART communication
const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");
const timer = @import("drivers/timer.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

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

    var old: u64 = timer.micros();
    var new: u64 = 0;
    var i: u32 = 0;

    uart.println("Entering main loop");

    // Main loop - call usb.poll() as often as possible!
    while (true) {
        // CRITICAL: Poll USB frequently
        usb.poll();

        new = timer.micros();
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


// TODO: - Kernel printf implementation
//       - Number formatting (hex, decimal, binary)
//       - String formatting
//       - Maybe a simple allocator for dynamic strings (or fixed buffers)

// TODO: implement line buffering
// - Character accumulation buffer (e.g., 256 bytes)
// - Echo characters back to terminal
// - Detect Enter/newline to complete a line
// - Handle backspace/delete
// - Pass complete lines to command processor
// Echo each character back so you see what you type
// Accumulate characters into a buffer until Enter is pressed
// Handle backspace to delete characters
// Process the complete line as a command

// TODO: registry of commands:
//       - list of commands
//       - help - list of available cmds
//       - uptime - time since boot
//       - mem - show memory usage
//       - ps - list of processes/tasks
//       - led - control led
//       - gpio - gpio manipulations
//       - reboot - reboot the system?? - not so necessary rn

// TODO: build cmd parser
// - Function to split input line into command + arguments
// - Command lookup table/registry
// - Command handler functions
// - Output formatting back to USB/UART
// Parse "led on" into command="led", arg="on"
// Look up command in a table
// Call the appropriate handler function
// Send response back to USB

// TODO: 
// - Move USB polling into a proper input handler
// - Call command processor when a line is complete
// - Send command output back through USB
// - Keep the timing loop for periodic tasks


// TODO: add error handling (here or in usb)
// - Check USB init errors
// - Handle buffer overflow in line input
// - Validate command arguments
// - Send error messages back to user 

// TODO: create printf
// - A kernel_printf() or console_print() function
// - Handles formatting internally
// - Sends to both USB and UART automatically
// - Returns errors gracefully


// [x] 1. Build system compiles OS kernel to .uf2
// [x] 2. Flash to RP2350 chip and it boots (LED blinks)
// [x] 3. USB CDC device appears on PC
// [x] 4. Can open serial port in PuTTY
// [x] 5. Typing shows characters echoed back
// [ ] 6. Pressing Enter triggers command processing
// [ ] 7. "help" command shows available commands
// [ ] 8. "led on" turns LED on
// [ ] 9. "led off" turns LED off
// [ ] 10. "uptime" shows seconds since boot
// [ ] 11. Backspace deletes characters correctly
// [ ] 12. UART shows same output as USB (parallel debug)