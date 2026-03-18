/// Neopixel Puzzle Cart for Badge V2 (RP2354B)
///
/// Press any joystick direction to light LEDs one-by-one in different colors.
/// After all 5 LEDs are lit, the strip enters a color cycling animation.
///
/// Hardware: 5 WS2812B neopixels on GPIO 15
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const time = hal.time;
const board = microzig.board;

// ============================================================================
// Pin Configuration
// ============================================================================

const NEOPIXEL_PIN: u5 = @intCast(@intFromEnum(board.neopixel_pin));
const LED_PIN: u5 = @intCast(@intFromEnum(board.led_pin));
const BKLT_EN_PIN: u5 = @intCast(@intFromEnum(board.BKLT_PWM));
const NUM_LEDS = 5;
const BRIGHTNESS_PERCENT: u8 = 15;

// ============================================================================
// Neopixel Driver for WS2812B
// ============================================================================

const NeopixelColor = extern struct {
    g: u8,
    r: u8,
    b: u8,
};

const Neopixels = struct {
    /// Write colors to all neopixels
    pub fn write(colors: *const [NUM_LEDS]NeopixelColor) void {
        var buf: [NUM_LEDS * 3]u8 = [_]u8{0} ** (NUM_LEDS * 3);

        for (colors, 0..) |color, i| {
            buf[i * 3 + 0] = color.g;
            buf[i * 3 + 1] = color.r;
            buf[i * 3 + 2] = color.b;
        }

        write_buf(&buf);
    }

    /// Clear all neopixels (set to black)
    pub fn clear() void {
        const colors = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;
        write(&colors);
    }

    /// Low-level WS2812B protocol implementation
    /// Timing: T0H=300ns, T0L=900ns, T1H=600ns, T1L=600ns
    /// RP2350 at 150MHz = 6.67ns per cycle
    fn write_buf(buf: []const u8) void {
        // Disable interrupts for timing-critical section
        asm volatile ("cpsid i");
        defer asm volatile ("cpsie i");

        const pin_mask: u32 = @as(u32, 1) << NEOPIXEL_PIN;

        // Use cart_hal SIO registers directly
        const SIO_GPIO_OUT_SET: *volatile u32 = @ptrFromInt(0xD0000018);
        const SIO_GPIO_OUT_CLR: *volatile u32 = @ptrFromInt(0xD0000020);

        // Send reset pulse (>50us low)
        SIO_GPIO_OUT_CLR.* = pin_mask;

        // Wait 80us for reset
        time.sleep_us(80);

        // Send each byte
        for (buf) |byte| {
            var mask: u8 = 0x80; // Start with MSB

            while (mask != 0) : (mask >>= 1) {
                const bit_set = (byte & mask) != 0;

                if (bit_set) {
                    // Send bit 1: 600ns high, 600ns low
                    // At 150MHz: 90 cycles high, 90 cycles low
                    SIO_GPIO_OUT_SET.* = pin_mask;

                    // Delay ~600ns (90 cycles)
                    var i: u32 = 0;
                    while (i < 26) : (i += 1) {
                        asm volatile ("nop");
                    }

                    SIO_GPIO_OUT_CLR.* = pin_mask;

                    // Delay ~600ns
                    i = 0;
                    while (i < 26) : (i += 1) {
                        asm volatile ("nop");
                    }
                } else {
                    // Send bit 0: 300ns high, 900ns low
                    // At 150MHz: 45 cycles high, 135 cycles low
                    SIO_GPIO_OUT_SET.* = pin_mask;

                    // Delay ~300ns (45 cycles)
                    var i: u32 = 0;
                    while (i < 12) : (i += 1) {
                        asm volatile ("nop");
                    }

                    SIO_GPIO_OUT_CLR.* = pin_mask;

                    // Delay ~900ns (135 cycles)
                    i = 0;
                    while (i < 38) : (i += 1) {
                        asm volatile ("nop");
                    }
                }
            }
        }
    }
};

// ============================================================================
// Input Handling
// ============================================================================

const ButtonState = struct {
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,

    fn read() ButtonState {
        return .{
            .left = board.joystick_left.read() == 1,
            .right = board.joystick_right.read() == 1,
            .up = board.joystick_up.read() == 1,
            .down = board.joystick_down.read() == 1,
        };
    }

    fn anyPressed(self: ButtonState) bool {
        return self.left or self.right or self.up or self.down;
    }
};

// ============================================================================
// Animation State
// ============================================================================

const color_palette = [_]NeopixelColor{
    .{ .r = 32, .g = 20, .b = 26 }, // Pink
    .{ .r = 28, .g = 17, .b = 31 }, // Purple
    .{ .r = 19, .g = 26, .b = 30 }, // Blue
    .{ .r = 19, .g = 30, .b = 23 }, // Green
    .{ .r = 29, .g = 30, .b = 19 }, // Zig Yellow
};

var global = struct {
    lit_count: usize = 0,
    cycle_phase: usize = 0,
    frame_count: u32 = 0,
    complete: bool = false,
    last_buttons: ButtonState = .{},
}{};

fn applyBrightness(color: NeopixelColor) NeopixelColor {
    return .{
        .r = @intCast((@as(u16, color.r) * BRIGHTNESS_PERCENT) / 100),
        .g = @intCast((@as(u16, color.g) * BRIGHTNESS_PERCENT) / 100),
        .b = @intCast((@as(u16, color.b) * BRIGHTNESS_PERCENT) / 100),
    };
}

fn renderProgress() void {
    var leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;

    for (0..global.lit_count) |i| {
        const led_index = (NUM_LEDS - 1) - i;
        leds[led_index] = applyBrightness(color_palette[i % color_palette.len]);
    }

    Neopixels.write(&leds);
}

fn renderCycle() void {
    var leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;

    for (0..NUM_LEDS) |i| {
        leds[i] = applyBrightness(color_palette[(i + global.cycle_phase) % color_palette.len]);
    }

    Neopixels.write(&leds);
}

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    // Initialize neopixel output pin
    const neopixel_pin = gpio.num(NEOPIXEL_PIN);
    neopixel_pin.set_function(.sio);
    neopixel_pin.set_direction(.out);
    neopixel_pin.put(0);

    // Initialize status LED pin
    const led_pin = gpio.num(LED_PIN);
    led_pin.set_function(.sio);
    led_pin.set_direction(.out);
    led_pin.put(1);

    const backlight_enable_pin = gpio.num(BKLT_EN_PIN);
    backlight_enable_pin.set_function(.sio);
    backlight_enable_pin.set_direction(.out);
    backlight_enable_pin.put(0); // Disable backlight

    // Initialize joystick directions as inputs
    board.joystick_left.set_function(.sio);
    board.joystick_left.set_direction(.in);
    board.joystick_left.set_pull(.down);

    board.joystick_right.set_function(.sio);
    board.joystick_right.set_direction(.in);
    board.joystick_right.set_pull(.down);

    board.joystick_up.set_function(.sio);
    board.joystick_up.set_direction(.in);
    board.joystick_up.set_pull(.down);

    board.joystick_down.set_function(.sio);
    board.joystick_down.set_direction(.in);
    board.joystick_down.set_pull(.down);

    Neopixels.clear();
    time.sleep_ms(100);

    renderProgress();

    while (true) {
        global.frame_count +%= 1;

        const buttons = ButtonState.read();
        const just_pressed =
            (buttons.left and !global.last_buttons.left) or
            (buttons.right and !global.last_buttons.right) or
            (buttons.up and !global.last_buttons.up) or
            (buttons.down and !global.last_buttons.down);

        if (!global.complete) {
            if (just_pressed and global.lit_count < NUM_LEDS) {
                global.lit_count += 1;
                renderProgress();

                if (global.lit_count >= NUM_LEDS) {
                    global.complete = true;
                    global.cycle_phase = 0;
                    renderCycle();
                }
            }
        } else {
            if (global.frame_count % 6 == 0) {
                global.cycle_phase = (global.cycle_phase + 1) % color_palette.len;
                renderCycle();
            }

            if (just_pressed) {
                led_pin.toggle();
            }
        }

        global.last_buttons = buttons;
        time.sleep_ms(20);
    }
}
