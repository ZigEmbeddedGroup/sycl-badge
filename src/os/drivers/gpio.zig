/// GPIO driver for RP2350
/// Thin wrapper around the rp2xxx HAL gpio module
const std = @import("std");
const hal = @import("microzig");

// Re-export HAL types and funcs
pub const Pin = hal.gpio.Pin;
pub const Function = hal.gpio.Function;
pub const Direction = hal.gpio.Direction;
pub const IrqLevel = hal.gpio.IrqLevel;
pub const IrqCallback = hal.gpio.IrqCallback;
pub const Override = hal.gpio.Override;
pub const SlewRate = hal.gpio.SlewRate;
pub const DriveStrength = hal.gpio.DriveStrength;
pub const Pull = hal.gpio.Pull;
pub const Mask = hal.gpio.Mask;

/// Create a Pin from a GPIO num
pub fn num(n: u9) Pin {
    return hal.gpio.num(n);
}

/// Create a Mask from a bitmask val
pub fn mask(m: anytype) Mask {
    return hal.gpio.mask(m);
}

///pin defs: can be expanded as needed
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
