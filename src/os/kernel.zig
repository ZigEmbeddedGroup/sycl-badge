// kernel.zig - Minimal OS kernel for RP2350

// RP2350 GPIO registers for LED
const SIO_BASE = 0xD0000000;
const GPIO_OUT_SET = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x014));
const GPIO_OUT_CLR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x018));
const GPIO_OE_SET = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x024));

const PADS_BANK0_BASE = 0x40038000;
const IO_BANK0_BASE = 0x40028000;
const LED_PIN: u32 = 25;

/// Main kernel entry point - called by boot.S
export fn kernel_main() noreturn {
    // Configure GPIO 25 for LED
    const pad_ctrl = @as(*volatile u32, @ptrFromInt(PADS_BANK0_BASE + 0x04 + (LED_PIN * 4)));
    pad_ctrl.* = (1 << 6) | (1 << 5);

    const gpio_ctrl = @as(*volatile u32, @ptrFromInt(IO_BANK0_BASE + 0x04 + (LED_PIN * 8)));
    gpio_ctrl.* = 5; // SIO function

    GPIO_OE_SET.* = (1 << LED_PIN);

    // Blink LED forever
    while (true) {
        GPIO_OUT_SET.* = (1 << LED_PIN);
        delay(500000);
        GPIO_OUT_CLR.* = (1 << LED_PIN);
        delay(500000);
    }
}

fn delay(cycles: u32) void {
    var i: u32 = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("nop");
    }
}

// Panic handler (required by Zig for freestanding)
pub fn panic(msg: []const u8, error_return_trace: ?*anyopaque, ret_addr: ?usize) noreturn {
    _ = msg;
    _ = error_return_trace;
    _ = ret_addr;
    while (true) {}
}
