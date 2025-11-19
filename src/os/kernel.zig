/// SYCL Badge OS Kernel
/// USB CDC and UART communication with interactive console
const std = @import("std");
const microzig = @import("microzig");

const rp2xxx = microzig.hal;
const gpio = rp2xxx.gpio;

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");
const timer = @import("drivers/timer.zig");
const console = @import("system/console.zig");

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

    // Wait a moment for USB to enumerate
    timer.sleep_ms(500);

    // Initialize console (shows welcome message and prompt)
    console.init();

    var old: u64 = timer.micros();

    uart.println("Entering main loop");

    // Main loop - console-based interaction
    while (true) {
        // CRITICAL: Poll USB frequently
        usb.poll();

        // Process console input (handles echo, line buffering, commands)
        console.processInput();

        const new = timer.micros();
        if (new - old > 1_000_000) { // Every 1 second - heartbeat
            old = new;

            // Debug heartbeat to UART only (not USB to avoid breaking console)
            var uart_buffer: [64]u8 = undefined;
            const uart_msg = std.fmt.bufPrint(&uart_buffer, "Heartbeat: {d}s", .{new / 1_000_000}) catch "Error";
            uart.println(uart_msg);
        }
    }
}

// TODO: DONE
// Accumulate characters into a buffer until Enter is pressed
// Handle backspace to delete characters
// Process the complete line as a command

// TODO: DONE
// registry of commands:
//       - list of commands
//       - help - list of available cmds
//       - uptime - time since boot
//       - mem - show memory usage
//       - ps - list of processes/tasks
//       - led - control led
//       - gpio - gpio manipulations
//       - reboot - reboot the system?? - not so necessary rn

// TODO: DONE
// build cmd parser
// - Function to split input line into command + arguments
// - Command lookup table/registry
// - Command handler functions
// - Output formatting back to USB/UART
// Parse "led on" into command="led", arg="on"
// Look up command in a table
// Call the appropriate handler function
// Send response back to USB

// TODO: DONE
// - Move USB polling into a proper input handler
// - Call command processor when a line is complete
// - Send command output back through USB
// - Keep the timing loop for periodic tasks

// TODO: add error handling (here or in usb)
// - Check USB init errors
// - Handle buffer overflow in line input
// - Validate command arguments
// - Send error messages back to user

// [x] 1. Build system compiles OS kernel to .uf2
// [x] 2. Flash to RP2350 chip and it boots (LED blinks)
// [x] 3. USB CDC device appears on PC
// [x] 4. Can open serial port in PuTTY
// [x] 5. Typing shows characters echoed back
// [x] 6. Pressing Enter triggers command processing
// [x] 7. "help" command shows available commands
// [x] 8. "led on" turns LED on
// [x] 9. "led off" turns LED off
// [x] 10. "uptime" shows seconds since boot
// [x] 11. Backspace deletes characters correctly
// [ ] 12. UART shows same output as USB (parallel debug)
