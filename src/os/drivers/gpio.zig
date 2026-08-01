const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const board = microzig.board;
const timer = @import("timer.zig");

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
        numbers[i] = @intFromEnum(p);
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
/// TODO: This isn't quite right, the notes come out
/// somewhere around 400 cents higher than they should
const buzzer_sys_clk_hz: u32 = 120_000_000;

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
    pub fn tone(freq_hz: f32) void {
        if (freq_hz == 0) {
            stop();
            return;
        }

        const pwm = hal.pwm;
        const sl: pwm.Slice = @enumFromInt(buzzer_pwm_slice);
        const ch = pwm.Pwm{ .slice_number = buzzer_pwm_slice, .channel = .b };

        // A piano ranges from 27.5 Hz to 4186 Hz, so for the square wave generator
        // clock we need to support a pretty wide range with reasonable accuracy.
        // The possible source clocks are 8.4 fractional divs of the sys clock,
        // or 0 for a max div of 256
        //
        // Max Freq = Clk Rate * 16 / 65536 / N
        // N = ceil(Clk Rate * 16 / 65536 / Freq)
        // Ticks = round(Clk Rate * 16 / N / Freq)

        const clk_rate = @as(f32, @floatFromInt(buzzer_sys_clk_hz));
        var clk_div = @ceil(clk_rate * 16.0 / 65536.0 / freq_hz);

        // Can't divide by less than 1.0
        clk_div = @max(16.0, clk_div);

        if (clk_div > (1<<13)) {
            // This frequency is too slow for us to reproduce, and also probably
            // too slow to hear, so just stop audio.
            stop();
            return;
        }

        var wrap_ticks = clk_rate * 16.0 / clk_div / freq_hz;

        // Centered mode allows another 2x divider on the clock
        var use_centered_mode = false;
        if (clk_div > (1<<12)) {
            clk_div = @ceil(clk_div / 2.0);
            wrap_ticks = wrap_ticks / 2.0;
            use_centered_mode = true;
        }
        wrap_ticks = @max(1.0, @round(wrap_ticks));

        const clk_div_int: u32 = if (clk_div == 256) 0 else @intFromFloat(clk_div);
        const wrap_int: u32 = @intFromFloat(wrap_ticks - 1.0);

        // Then came. The Noise.
        sl.set_phase_correct(use_centered_mode);
        sl.set_clk_div(@intCast(clk_div_int >> 4), @intCast(clk_div_int & 0xF));
        sl.set_wrap(@intCast(wrap_int));
        ch.set_level(@intCast(wrap_int / 2)); // 50 % duty cycle → loudest output
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
/// using the WS2812B NRZ protocol, then holds the line low for ≥300 µs so
/// the strip latches and all LEDs turn off.
///
/// Core 0 owns the USB stack so we cannot disable interrupts for the full
/// bit-bang window without risking a USB ISR panic.  Instead we send three
/// redundant passes with generous latch gaps; at least one clean frame will
/// reach the strip even if a USB interrupt corrupts a single pass.
fn clearNeopixels() linksection(".data") void {
    const PIN_MASK: u32 = 1 << 15;

    const IO_BANK0_GPIO15_CTRL: *volatile u32 = @ptrFromInt(0x4002807C);
    const GPIO_OE_SET: *volatile u32 = @ptrFromInt(0xD0000038);
    const GPIO_OUT_SET: *volatile u32 = @ptrFromInt(0xD0000018);
    const GPIO_OUT_CLR: *volatile u32 = @ptrFromInt(0xD0000020);

    IO_BANK0_GPIO15_CTRL.* = 5; // FUNC_SIO
    GPIO_OE_SET.* = PIN_MASK;
    microzig.cpu.dsb();

    // Extended pre-transmission reset so the strip sees a clean latch
    // even if the data line was left in an arbitrary state by the cart.
    GPIO_OUT_CLR.* = PIN_MASK;
    timer.sleep_us(300);

    // Three passes with extended latch gaps for reliability.
    var pass: u32 = 0;
    while (pass < 3) : (pass += 1) {
        var bit: u32 = 0;
        while (bit < 120) : (bit += 1) {
            GPIO_OUT_SET.* = PIN_MASK;
            // T0H ~300-400ns (tuned for 150 MHz RP2350)
            var t: u32 = 0;
            while (t < 15) : (t += 1) {
                asm volatile ("nop");
            }
            GPIO_OUT_CLR.* = PIN_MASK;
            // T0L ~800-900ns
            t = 0;
            while (t < 42) : (t += 1) {
                asm volatile ("nop");
            }
        }
        GPIO_OUT_CLR.* = PIN_MASK;
        timer.sleep_us(300);
    }
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
    resetCartBuzzer();
    resetCartPWM();
    resetCartPIO();
    resetCartNeopixels();
    resetCartLED();
    initButtons();
}

/// Step 1: Stop buzzer
pub fn resetCartBuzzer() void {
    buzzer.stop();
}

/// Step 2: Disable all 12 PWM slices (RP2350)
///
/// Uses raw register access instead of hal.pwm.Slice because the HAL's Slice
/// enum may only have 8 variants (RP2040). @enumFromInt(8..11) would be
/// invalid and can panic. Direct CSR writes work for all 12 slices.
pub fn resetCartPWM() void {
    const PWM_BASE: u32 = 0x400a8000;
    const CH_SIZE: u32 = 0x14; // 20 bytes per channel (CSR, DIV, CTR, CC, TOP)
    const CSR_EN: u32 = 1;

    var i: u32 = 0;
    while (i < 12) : (i += 1) {
        const csr_addr = PWM_BASE + i * CH_SIZE;
        const csr: *volatile u32 = @ptrFromInt(csr_addr);
        csr.* = csr.* & ~CSR_EN; // Clear EN bit to disable
    }
}

/// Step 3: Disable all PIO state machines
pub fn resetCartPIO() void {
    const PIO0_CTRL: *volatile u32 = @ptrFromInt(0x50200000);
    const PIO1_CTRL: *volatile u32 = @ptrFromInt(0x50300000);
    const PIO2_CTRL: *volatile u32 = @ptrFromInt(0x50400000);
    PIO0_CTRL.* = PIO0_CTRL.* & ~@as(u32, 0xF);
    PIO1_CTRL.* = PIO1_CTRL.* & ~@as(u32, 0xF);
    PIO2_CTRL.* = PIO2_CTRL.* & ~@as(u32, 0xF);
}

/// Step 4: Clear neopixels via WS2812B protocol
pub fn resetCartNeopixels() void {
    clearNeopixels();
}

/// Step 5: Drive debug LED off
pub fn resetCartLED() void {
    board.led_pin.set_function(.sio);
    board.led_pin.set_direction(.out);
    board.led_pin.put(0);
}
