const std = @import("std");
const microzig = @import("microzig");

// Re-export microzig types and funcs
pub const Pin = microzig.gpio.Pin;
pub const Function = microzig.gpio.Function;
pub const Direction = microzig.gpio.Direction;
pub const IrqLevel = microzig.gpio.IrqLevel;
pub const IrqCallback = microzig.gpio.IrqCallback;
pub const Override = microzig.gpio.Override;
pub const SlewRate = microzig.gpio.SlewRate;
pub const DriveStrength = microzig.gpio.DriveStrength;
pub const Pull = microzig.gpio.Pull;
pub const Mask = microzig.gpio.Mask;

// Basic pin operations
pub fn num(n: u9) Pin {
    return microzig.gpio.num(n);
}

pub fn mask(m: anytype) Mask {
    return microzig.gpio.mask(m);
}

// Read and write operations with proper types
pub fn read(pin: Pin) u1 {
    return @intFromBool(microzig.gpio.read(pin));
}

pub fn put(pin: Pin, value: u1) void {
    microzig.gpio.put(pin, value != 0);
}

// Convenience functions using the corrected read
pub fn isHigh(pin: Pin) bool {
    return read(pin) == 1;
}

pub fn isLow(pin: Pin) bool {
    return read(pin) == 0;
}

pub fn toggle(pin: Pin) void {
    put(pin, ~read(pin) & 1);
}

// Rest of your pin definitions...
pub const Pins = struct {
    pub const UART0_TX = num(0);
    pub const UART0_RX = num(1);
    pub const LED = num(25);
    pub const I2C0_SDA = num(4);
    pub const I2C0_SCL = num(5);
    pub const SPI0_RX = num(16);
    pub const SPI0_CSn = num(17);
    pub const SPI0_SCK = num(18);
    pub const SPI0_TX = num(19);
};
