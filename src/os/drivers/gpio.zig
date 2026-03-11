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

// Button pin definitions - single source of truth
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
        numbers[i] = @intFromEnum(p);
    }
    break :blk numbers;
};

// Button initialization
pub fn initButtons() void {
    // Configure all button and joystick pins as inputs with pull-ups
    // Buttons are active-low (connect to GND when pressed)
    for (button_pins) |pin| {
        pin.set_function(.sio);
        pin.set_direction(.in);
        pin.set_pull(.up); // Pull-up: not pressed = 1 (high), pressed = 0 (low)
    }
}

/// Check if a pin number corresponds to a button/joystick pin
fn isButtonPin(pin: Pin) bool {
    const pin_num = @intFromEnum(pin);
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

    // Enable pull-up for button pins (not pressed = 1, pressed = 0)
    if (isButtonPin(pin)) {
        pin.set_pull(.up);
    }
}

// Button reading convenience functions (returns true when pressed)
pub fn isButtonPressed(pin: Pin) bool {
    return read(pin) == 0; // Active-high with pull-up: pressed = 0
}

pub fn isButtonReleased(pin: Pin) bool {
    return read(pin) == 1; // Active-high with pull-up: released = 1
}

// ============================================================================
// Buzzer controller for CMT-7525-80-SMT-TR
//
// GPIO8 = SPKR_EN  - speaker enable (active-high)
// GPIO9 = SPKR_A0  - PWM audio output → PWM slice 4, channel B
//
// The CMT-7525-80-SMT-TR is a magnetic buzzer with a resonant frequency of
// ~2500 Hz. It is driven by toggling the A0 line at the desired frequency
// (50 % duty cycle for maximum volume) while SPKR_EN is held high.
// ============================================================================

/// System clock in Hz (125 MHz for RP2354B)
const buzzer_sys_clk_hz: u32 = 125_000_000;

/// Integer pre-divider applied to the system clock before the PWM counter.
/// 125 MHz / 4 = 31.25 MHz PWM tick rate.
const buzzer_pwm_clk_div: u8 = 4;

/// PWM slice number for GPIO9 (slice = pin / 2 = 9 / 2 = 4).
const buzzer_pwm_slice: u32 = 4;

pub const buzzer = struct {
    /// Initialise buzzer hardware.
    /// SPKR_EN is driven low (muted), the PWM pin is muxed to PWM function.
    pub fn init() void {
        // Enable pin: SIO output, start disabled
        board.buzzer_enable.set_function(.sio);
        board.buzzer_enable.set_direction(.out);
        board.buzzer_enable.put(0);

        // Audio pin: hand control to the PWM peripheral
        board.buzzer_pwm.set_function(.pwm);
    }

    /// Enable or disable the speaker amplifier without changing the PWM output.
    pub fn setEnable(enabled: bool) void {
        board.buzzer_enable.put(@intFromBool(enabled));
    }

    /// Start a continuous tone at `freq_hz`.
    /// Passing 0 is equivalent to calling `stop()`.
    /// The speaker enable pin is asserted automatically.
    pub fn tone(freq_hz: u32) void {
        if (freq_hz == 0) {
            stop();
            return;
        }

        const pwm = hal.pwm;
        const sl: pwm.Slice = @enumFromInt(buzzer_pwm_slice);
        const ch = pwm.Pwm{ .slice_number = buzzer_pwm_slice, .channel = .b };

        // wrap = tick_rate / freq  (clamped to u16)
        const tick_hz: u32 = buzzer_sys_clk_hz / @as(u32, buzzer_pwm_clk_div);
        const wrap: u16 = @intCast(@min(tick_hz / freq_hz, 0xFFFF));

        sl.set_clk_div(buzzer_pwm_clk_div, 0); // integer div, no fraction
        sl.set_wrap(wrap);
        ch.set_level(wrap / 2); // 50 % duty cycle → loudest output
        sl.enable();

        setEnable(true);
    }

    /// Stop PWM output and deassert SPKR_EN.
    pub fn stop() void {
        const sl: hal.pwm.Slice = @enumFromInt(buzzer_pwm_slice);
        sl.disable();
        setEnable(false);
    }

    /// Blocking beep: play `freq_hz` for `duration_ms` milliseconds, then stop.
    pub fn beep(freq_hz: u32, duration_ms: u32) void {
        tone(freq_hz);
        hal.time.sleep_ms(duration_ms);
        stop();
    }

    /// Play a sequence of (frequency, duration_ms) pairs.
    /// A frequency of 0 inserts a silent pause for the given duration.
    pub fn melody(notes: []const struct { freq: u32, ms: u32 }) void {
        for (notes) |note| {
            if (note.freq == 0) {
                stop();
                hal.time.sleep_ms(note.ms);
            } else {
                beep(note.freq, note.ms);
            }
        }
    }
};
