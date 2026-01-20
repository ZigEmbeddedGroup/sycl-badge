/// SYCL Badge OS Kernel
/// USB CDC and UART communication with interactive console
const std = @import("std");
const microzig = @import("microzig");

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");
const timer = @import("drivers/timer.zig");
const lcd = @import("drivers/lcd.zig");
const console = @import("system/console.zig");
const init = @import("system/init.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

pub fn main() !void {
    // Initialize all drivers and kernel systems (including LCD)
    try init.init(.{
        .lcd_pins = lcd.createDT018BTFTPins(),
        .lcd_config = lcd.createDT018BTFTConfig(),
        .init_core1 = true,
    });

    // Display startup message on LCD
    lcd.fillScreen(lcd.BLACK);
    lcd.drawString(10, 20, "SYCL Badge OS", lcd.WHITE, lcd.BLACK, 1);
    lcd.drawString(10, 40, "VIKES is the best", lcd.GREEN, lcd.BLACK, 1);
    lcd.drawString(10, 60, "Ready!", lcd.CYAN, lcd.BLACK, 1);

    // var old: u64 = timer.micros();

    uart.println("Entering main loop");

    // Main loop
    while (true) {
        // CRITICAL: Poll USB frequently
        // Avoid spamming UART; keep USB polling tight for CDC/MSC.
        usb.poll();

        // Process console input (handles echo, line buffering, commands)
        console.processInput();
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
