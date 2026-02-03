/// Cart HAL - Hardware Abstraction Layer for RP2350 Family
///
/// Provides direct register access for carts running on Core 1.
/// Works on all RP2350 family chips (RP2350A, RP2354B, etc.)
/// without depending on microzig's build system.
///
/// Register addresses are identical across the RP2350 family.

// ============================================================================
// Base Addresses (same across all RP2350 variants)
// ============================================================================

pub const SIO_BASE: u32 = 0xD0000000;
pub const IO_BANK0_BASE: u32 = 0x40028000;
pub const PADS_BANK0_BASE: u32 = 0x40038000;
pub const TIMER0_BASE: u32 = 0x400B0000;
pub const TIMER1_BASE: u32 = 0x400B8000;
pub const RESETS_BASE: u32 = 0x40020000;
pub const CLOCKS_BASE: u32 = 0x40010000;

// ============================================================================
// SIO (Single-cycle I/O) Registers
// Each core has its own view of SIO at the same address
// ============================================================================

pub const SIO = struct {
    pub const CPUID = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x000));

    // GPIO output
    pub const GPIO_OUT = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x010));
    pub const GPIO_OUT_SET = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x018));
    pub const GPIO_OUT_CLR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x020));
    pub const GPIO_OUT_XOR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x028));

    // GPIO output enable
    pub const GPIO_OE = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x030));
    pub const GPIO_OE_SET = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x038));
    pub const GPIO_OE_CLR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x040));
    pub const GPIO_OE_XOR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x048));

    // GPIO input
    pub const GPIO_IN = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x008));

    // FIFO for inter-core communication
    pub const FIFO_ST = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x050));
    pub const FIFO_WR = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x054));
    pub const FIFO_RD = @as(*volatile u32, @ptrFromInt(SIO_BASE + 0x058));

    // Spinlocks (32 available)
    pub const SPINLOCK_BASE = SIO_BASE + 0x100;

    pub fn spinlock(n: u5) *volatile u32 {
        return @ptrFromInt(SPINLOCK_BASE + @as(u32, n) * 4);
    }
};

// ============================================================================
// IO_BANK0 - GPIO function selection
// ============================================================================

pub const IO_BANK0 = struct {
    /// Get the status register for a GPIO pin
    pub fn gpioStatus(pin: u5) *volatile u32 {
        return @ptrFromInt(IO_BANK0_BASE + @as(u32, pin) * 8);
    }

    /// Get the control register for a GPIO pin
    pub fn gpioCtrl(pin: u5) *volatile u32 {
        return @ptrFromInt(IO_BANK0_BASE + 0x04 + @as(u32, pin) * 8);
    }

    // GPIO function select values
    pub const FUNC_XIP = 0;
    pub const FUNC_SPI = 1;
    pub const FUNC_UART = 2;
    pub const FUNC_I2C = 3;
    pub const FUNC_PWM = 4;
    pub const FUNC_SIO = 5; // Software controlled GPIO
    pub const FUNC_PIO0 = 6;
    pub const FUNC_PIO1 = 7;
    pub const FUNC_PIO2 = 8;
    pub const FUNC_CLOCK = 9;
    pub const FUNC_USB = 10;
    pub const FUNC_NULL = 31;
};

// ============================================================================
// PADS_BANK0 - GPIO pad control
// ============================================================================

pub const PADS_BANK0 = struct {
    pub const VOLTAGE_SELECT = @as(*volatile u32, @ptrFromInt(PADS_BANK0_BASE + 0x00));

    /// Get the pad control register for a GPIO pin
    pub fn gpioPad(pin: u5) *volatile u32 {
        return @ptrFromInt(PADS_BANK0_BASE + 0x04 + @as(u32, pin) * 4);
    }

    // Pad control bits
    pub const OD: u32 = 1 << 7; // Output disable
    pub const IE: u32 = 1 << 6; // Input enable
    pub const DRIVE_2MA: u32 = 0 << 4;
    pub const DRIVE_4MA: u32 = 1 << 4;
    pub const DRIVE_8MA: u32 = 2 << 4;
    pub const DRIVE_12MA: u32 = 3 << 4;
    pub const PUE: u32 = 1 << 3; // Pull-up enable
    pub const PDE: u32 = 1 << 2; // Pull-down enable
    pub const SCHMITT: u32 = 1 << 1; // Schmitt trigger enable
    pub const SLEWFAST: u32 = 1 << 0; // Slew rate control
};

// ============================================================================
// TIMER - 64-bit microsecond timer
// ============================================================================

pub const TIMER0 = struct {
    pub const TIMEHW = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x00));
    pub const TIMELW = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x04));
    pub const TIMEHR = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x08));
    pub const TIMELR = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x0C));

    // Alarms
    pub const ALARM0 = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x10));
    pub const ALARM1 = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x14));
    pub const ALARM2 = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x18));
    pub const ALARM3 = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x1C));

    pub const ARMED = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x20));
    pub const TIMERAWH = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x24));
    pub const TIMERAWL = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x28));

    pub const INTR = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x34));
    pub const INTE = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x38));
    pub const INTF = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x3C));
    pub const INTS = @as(*volatile u32, @ptrFromInt(TIMER0_BASE + 0x40));
};

// ============================================================================
// GPIO Helper Functions
// ============================================================================

pub const gpio = struct {
    /// Initialize a GPIO pin as output with SIO function
    pub fn initOutput(pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;

        // Configure pad: clear output disable, set drive strength
        // Default pad config: OD=0, IE=1, DRIVE=4mA, PUE=0, PDE=1, SCHMITT=1, SLEWFAST=0
        const pad = PADS_BANK0.gpioPad(pin);
        pad.* = PADS_BANK0.DRIVE_4MA | PADS_BANK0.SCHMITT; // OD=0 (output enabled), IE=0, no pulls

        // Set function to SIO (software controlled GPIO)
        IO_BANK0.gpioCtrl(pin).* = IO_BANK0.FUNC_SIO;

        // Enable output in SIO
        SIO.GPIO_OE_SET.* = pin_mask;
    }

    /// Initialize a GPIO pin as input with SIO function
    pub fn initInput(pin: u5) void {
        const pin_mask: u32 = @as(u32, 1) << pin;

        // Set function to SIO
        IO_BANK0.gpioCtrl(pin).* = IO_BANK0.FUNC_SIO;

        // Disable output (make it input)
        SIO.GPIO_OE_CLR.* = pin_mask;

        // Enable input in pad control
        const pad = PADS_BANK0.gpioPad(pin);
        pad.* = (pad.* & ~PADS_BANK0.OD) | PADS_BANK0.IE;
    }

    /// Set a GPIO pin high
    pub fn setHigh(pin: u5) void {
        SIO.GPIO_OUT_SET.* = @as(u32, 1) << pin;
    }

    /// Set a GPIO pin low
    pub fn setLow(pin: u5) void {
        SIO.GPIO_OUT_CLR.* = @as(u32, 1) << pin;
    }

    /// Toggle a GPIO pin
    pub fn toggle(pin: u5) void {
        SIO.GPIO_OUT_XOR.* = @as(u32, 1) << pin;
    }

    /// Set GPIO pin state
    pub fn set(pin: u5, value: bool) void {
        if (value) {
            setHigh(pin);
        } else {
            setLow(pin);
        }
    }

    /// Read GPIO pin state
    pub fn read(pin: u5) bool {
        return (SIO.GPIO_IN.* & (@as(u32, 1) << pin)) != 0;
    }

    /// Enable pull-up resistor
    pub fn enablePullUp(pin: u5) void {
        const pad = PADS_BANK0.gpioPad(pin);
        pad.* = (pad.* & ~PADS_BANK0.PDE) | PADS_BANK0.PUE;
    }

    /// Enable pull-down resistor
    pub fn enablePullDown(pin: u5) void {
        const pad = PADS_BANK0.gpioPad(pin);
        pad.* = (pad.* & ~PADS_BANK0.PUE) | PADS_BANK0.PDE;
    }

    /// Disable pull-up and pull-down resistors
    pub fn disablePulls(pin: u5) void {
        const pad = PADS_BANK0.gpioPad(pin);
        pad.* = pad.* & ~(PADS_BANK0.PUE | PADS_BANK0.PDE);
    }
};

// ============================================================================
// Timer Helper Functions
// ============================================================================

pub const timer = struct {
    /// Get current time in microseconds (64-bit)
    pub fn micros() u64 {
        // Read low first, then high to get atomic read
        const lo = TIMER0.TIMELR.*;
        const hi = TIMER0.TIMEHR.*;
        return (@as(u64, hi) << 32) | lo;
    }

    /// Busy-wait for specified microseconds
    pub fn delayUs(us: u32) void {
        const target = micros() + us;
        while (micros() < target) {
            asm volatile ("nop");
        }
    }

    /// Busy-wait for specified milliseconds
    pub fn delayMs(ms: u32) void {
        delayUs(ms * 1000);
    }
};

// ============================================================================
// Utility Functions
// ============================================================================

/// Simple busy-loop delay (cycles, not time-based)
pub fn delayCycles(cycles: u32) void {
    var i: u32 = 0;
    while (i < cycles) : (i += 1) {
        asm volatile ("nop");
    }
}

/// Get current core ID (0 or 1)
pub fn getCoreId() u32 {
    return SIO.CPUID.*;
}

/// Memory barrier - ensure all memory operations complete
pub fn memoryBarrier() void {
    asm volatile ("dmb sy");
}

/// Data synchronization barrier
pub fn dsb() void {
    asm volatile ("dsb sy");
}

/// Instruction synchronization barrier
pub fn isb() void {
    asm volatile ("isb sy");
}
