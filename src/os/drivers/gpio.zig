const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const board = microzig.board;

// Re-export microzig types and funcs
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

// Basic pin operations
pub fn num(n: u9) Pin {
    return hal.gpio.num(n);
}

pub fn mask(m: anytype) Mask {
    return hal.gpio.mask(m);
}

// Read and write operations with proper types
pub fn read(pin: Pin) u1 {
    return pin.read();
}

pub fn put(pin: Pin, value: u1) void {
    pin.put(value);
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

// GPIO subsystem init (if needed)
pub fn init() void {
    // GPIO is initialized by microzig startup
    // This function exists for consistency with other drivers
}

// LED control functions
pub fn initLED() void {
    const pin = board.led_pin;
    pin.set_function(.sio);
    pin.set_direction(.out);
    pin.put(0);
}

pub fn setLED(state: bool) void {
    board.led_pin.put(@intFromBool(state));
}

pub fn toggleLED() void {
    toggle(board.led_pin);
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
// Button pin definitions - single source of truth

// Button pin definitions - single source of truth
const button_pins = [_]Pin{ board.button_down, board.button_up };

/// Button pin numbers extracted from board definitions at compile time
const button_pin_numbers = blk: {
    var numbers: [button_pins.len]u8 = undefined;
    for (button_pins, 0..) |p, i| {
        numbers[i] = @intFromEnum(p);
    }
    break :blk numbers;
};

/// Check if a pin number corresponds to a button/joystick pin
fn isButtonPin(pin: Pin) bool {
    const pin_num = @intFromEnum(pin);
    for (button_pin_numbers) |bp_num| {
        if (pin_num == bp_num) return true;
    }
    return false;
}

/// Configure a pin as an input
/// Automatically applies pull-down for buttons
pub fn configureAsInput(pin_num: u9) void {
    const pin = num(pin_num);
    pin.set_function(.sio);
    pin.set_direction(.in);

    if (isButtonPin(pin)) {
        pin.set_pull(.down); // Pull-down for active-high buttons
    }
}

/// Initialize all buttons
/// Simply loops through button pins and configures them as input
pub fn initButtons() void {
    for (button_pins) |pin| {
        configureAsInput(@intFromEnum(pin));
        // Small delay to allow pull-down resistor to stabilize the pin state
        // This prevents reading floating values on RP2354B
        microzig.hal.time.sleep_us(10);
    }
}

/// Button reading convenience functions
pub fn isButtonPressed(pin: Pin) bool {
    return read(pin) == 1; // Active-high: pressed = 1
}

pub fn isButtonReleased(pin: Pin) bool {
    return read(pin) == 0; // Released = 0
}
