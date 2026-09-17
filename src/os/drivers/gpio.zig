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

// GPIO subsystem init (handled by microzig startup)
pub fn init() void {}

// Red LED control functions
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

// Button pin definitions
const button_pins = [_]Pin{
    board.joystick_up,
    board.joystick_down,
    board.joystick_left,
    board.joystick_right,
    board.joystick_click,
    board.button_a,
    board.button_b,
    board.button_start,
    board.button_select,
};

/// Button pin numbers extracted from board definitions at compile time
const button_pin_numbers = blk: {
    var numbers: [button_pins.len]u8 = undefined;
    for (button_pins, 0..) |p, i| {
        numbers[i] = @backingInt(p);
    }
    break :blk numbers;
};

// Button initialization
pub fn initButtons() void {
    // Configure all button and joystick pins as inputs with pull-downs.
    // Buttons are active-high: not pressed = 0 (low), pressed = 1 (high).
    for (button_pins) |pin| {
        pin.set_function(.sio);
        pin.set_direction(.in);
        pin.set_pull(.down); // Pull-down: not pressed = 0 (low), pressed = 1 (high)
    }
}

/// Check if a pin number corresponds to a button/joystick pin
fn isButtonPin(pin: Pin) bool {
    const pin_num = @backingInt(pin);
    for (button_pin_numbers) |bp_num| {
        if (pin_num == bp_num) return true;
    }
    return false;
}

/// Configure a pin as an input (useful for reading GPIO state)
/// If the pin is a button, also enables pull-down
pub fn configureAsInput(pin_num: u9) void {
    const pin = num(pin_num);
    pin.set_function(.sio);
    pin.set_direction(.in);

    // Enable pull-down for button pins (active-high: not pressed = 0, pressed = 1)
    if (isButtonPin(pin)) {
        pin.set_pull(.down);
    }
}

// Button reading convenience functions (returns true when pressed)
pub fn isButtonPressed(pin: Pin) bool {
    return read(pin) == 1; // Active-high: pressed = 1 (high)
}

pub fn isButtonReleased(pin: Pin) bool {
    return read(pin) == 0; // Active-high: released = 0 (low)
}

/// Step 2: Disable all 12 PWM slices (RP2350)
///
/// Uses raw register access instead of hal.pwm.Slice because the HAL's Slice
/// enum may only have 8 variants (RP2040). @enumFromInt(8..11) would be
/// invalid and can panic. Direct CSR writes work for all 12 slices.
pub fn resetCartPWM() void {
    // TODO: The OS is using these PWMs, we need special allocations if cart can use them.

    // const PWM_BASE: u32 = 0x400a8000;
    // const CH_SIZE: u32 = 0x14; // 20 bytes per channel (CSR, DIV, CTR, CC, TOP)
    // const CSR_EN: u32 = 1;

    // var i: u32 = 0;
    // while (i < 12) : (i += 1) {
    //     const csr_addr = PWM_BASE + i * CH_SIZE;
    //     const csr: *volatile u32 = @ptrFromInt(csr_addr);
    //     csr.* = csr.* & ~CSR_EN; // Clear EN bit to disable
    // }
}

/// Step 3: Disable all PIO state machines
pub fn resetCartPIO() void {
    // TODO: The OS is using these PIOs, we need special allocations if cart can use them.

    // const PIO0_CTRL: *volatile u32 = @ptrFromInt(0x50200000);
    // const PIO1_CTRL: *volatile u32 = @ptrFromInt(0x50300000);
    // const PIO2_CTRL: *volatile u32 = @ptrFromInt(0x50400000);
    // PIO0_CTRL.* = PIO0_CTRL.* & ~@as(u32, 0xF);
    // PIO1_CTRL.* = PIO1_CTRL.* & ~@as(u32, 0xF);
    // PIO2_CTRL.* = PIO2_CTRL.* & ~@as(u32, 0xF);
}

/// Step 5: Drive debug LED off
pub fn resetCartLED() void {
    board.led_pin.set_function(.sio);
    board.led_pin.set_direction(.out);
    board.led_pin.put(0);
}
