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

/// Bit-bang a WS2812B all-black (zero) frame onto the neopixel data line.
///
/// Transmits 5 pixels × 3 bytes × 8 bits = 120 consecutive "0" code-words
/// using the WS2812B NRZ protocol, then holds the line low for ≥60 µs so
/// the strip latches and all LEDs turn off.
///
/// Protocol timing (WS2812B, ±150 ns tolerance):
///   T0H (zero-code high): ~400 ns → 45 NOPs at 125 MHz ≈ 360 ns
///   T0L (zero-code low):  ~850 ns → 105 NOPs + loop overhead ≈ 860 ns
///   Reset/latch:          >50 µs  → timer-based 80 µs pre-pulse + 60 µs post
///
/// The caller must have already reconfigured the neopixel pin as an SIO
/// output.  The line is left low (latched/off) after this function returns.
fn clearNeopixels() void {
    // SIO single-cycle GPIO registers (addresses from RP2350 TRM / cart_hal.zig).
    const GPIO_OUT_SET: *volatile u32 = @ptrFromInt(0xD0000018);
    const GPIO_OUT_CLR: *volatile u32 = @ptrFromInt(0xD0000020);
    // TIMER0_TIMERAWL: free-running 32-bit µs counter (1 MHz, always-on).
    const TIMER_RAWL: *volatile u32 = @ptrFromInt(0x400B0028);

    const neopixel_gpio: u5 = @intCast(@intFromEnum(board.neopixel_pin));
    const PIN: u32 = @as(u32, 1) << neopixel_gpio;

    // Pre-transmission reset: hold data line low for ≥80 µs so any prior
    // in-progress WS2812 frame is abandoned and the strip is ready to latch.
    GPIO_OUT_CLR.* = PIN;
    const t0 = TIMER_RAWL.*;
    while (TIMER_RAWL.* -% t0 < 80) {}

    // Transmit 120 zero bits (= 5 fully-black pixels).
    var i: u32 = 0;
    while (i < 120) : (i += 1) {
        // --- T0H: ~400 ns high ---
        GPIO_OUT_SET.* = PIN;
        asm volatile (
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop
        ); // 45 NOPs ≈ 360 ns

        // --- T0L: ~850 ns low ---
        GPIO_OUT_CLR.* = PIN;
        asm volatile (
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
            \\ nop; nop; nop; nop; nop
        ); // 105 NOPs ≈ 840 ns (loop overhead ≈ +24 ns → total ≈ 864 ns)
    }

    // Post-transmission latch: hold low ≥60 µs to commit the all-off frame.
    GPIO_OUT_CLR.* = PIN;
    const t1 = TIMER_RAWL.*;
    while (TIMER_RAWL.* -% t1 < 60) {}
}

/// Reset all hardware to a safe state after a cart stops.
///
/// This must be called (on Core 0) after Core 1 has been halted so that any
/// peripherals the cart left in an active state are silenced/disabled before
/// the OS resumes normal operation.  Specifically it:
///   • Silences the buzzer (disables the PWM tone and de-asserts SPKR_EN).
///   • Disables every PWM slice (carts may drive LEDs or servos via PWM).
///   • Disables all PIO state-machine groups (carts use PIO for neopixels,
///     custom protocols, etc.).
///   • Transmits an all-black WS2812B frame to clear all 5 neopixels.
///   • Drives the debug LED low.
///   • Reconfigures all button/joystick pins as pull-up inputs so they are
///     readable by the kernel again.
pub fn resetCartHardware() void {
    // 1. Stop buzzer – de-asserts SPKR_EN and disables the PWM slice.
    buzzer.stop();

    // 2. Disable all 12 PWM slices (RP2350).
    //    The LCD backlight (GPIO 16) is wired as a plain SIO output, not PWM,
    //    so disabling every slice is safe.
    var i: u32 = 0;
    while (i < 12) : (i += 1) {
        const sl: hal.pwm.Slice = @enumFromInt(i);
        sl.disable();
    }

    // 3. Disable all PIO state machines across PIO0, PIO1, PIO2.
    //    The SM_ENABLE field occupies bits [3:0] of each PIO CTRL register.
    //    The OS itself does not use PIO, so clearing these bits is safe.
    const PIO0_CTRL: *volatile u32 = @ptrFromInt(0x50200000);
    const PIO1_CTRL: *volatile u32 = @ptrFromInt(0x50300000);
    const PIO2_CTRL: *volatile u32 = @ptrFromInt(0x50400000);
    PIO0_CTRL.* = PIO0_CTRL.* & ~@as(u32, 0xF);
    PIO1_CTRL.* = PIO1_CTRL.* & ~@as(u32, 0xF);
    PIO2_CTRL.* = PIO2_CTRL.* & ~@as(u32, 0xF);

    // 4. Clear all 5 neopixels by bit-banging an all-black WS2812B frame.
    //    Reconfigure the pin first (cart may have left it in PIO/PWM mode).
    board.neopixel_pin.set_function(.sio);
    board.neopixel_pin.set_direction(.out);
    clearNeopixels(); // transmits 5×24 zero bits + latch; leaves line low

    // 5. Drive the debug LED off.
    board.led_pin.set_function(.sio);
    board.led_pin.set_direction(.out);
    board.led_pin.put(0);

    // 6. Restore button / joystick pins for kernel use.
    initButtons();
}
