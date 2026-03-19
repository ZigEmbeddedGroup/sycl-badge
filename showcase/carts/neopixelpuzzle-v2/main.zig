/// Neopixel Puzzle Cart for Badge V2 (RP2354B)
///
/// Staged animation: blank, then LEDs fill one-by-one each second.
/// After all 5 LEDs are lit, the strip enters faster color cycling.
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
const TICK_MS: u32 = 20;
const FILL_STAGE_INTERVAL_TICKS: u32 = 1000 / TICK_MS;
const FINAL_CYCLE_INTERVAL_TICKS: u32 = 120 / TICK_MS;

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
// Animation State
// ============================================================================

// Pink, Purple, Blue, Green, Yellow
const color_palette = [_]NeopixelColor{
    .{ .r = 32, .g = 0, .b = 16 }, // Magenta
    .{ .r = 16, .g = 0, .b = 32 }, // Purple
    .{ .r = 0, .g = 0, .b = 32 }, // Blue
    .{ .r = 0, .g = 32, .b = 0 }, // Green
    .{ .r = 32, .g = 32, .b = 0 }, // Yellow
};

var global = struct {
    lit_count: usize = 0,
    cycle_phase: usize = 0,
    stage_ticks: u32 = 0,
    complete: bool = false,
    cycle_started: bool = false,
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
    if (global.lit_count > 0 and global.lit_count <= NUM_LEDS) {
        const stage_color_index = (global.lit_count - 1) % color_palette.len;
        const stage_color = applyBrightness(color_palette[stage_color_index]);
        const led_index = NUM_LEDS - global.lit_count;
        leds[led_index] = stage_color;
    }

    Neopixels.write(&leds);
}

fn renderCycle() void {
    var leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;
    const cycle_color = applyBrightness(color_palette[global.cycle_phase % color_palette.len]);

    for (0..NUM_LEDS) |i| {
        leds[i] = cycle_color;
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

    Neopixels.clear();
    time.sleep_ms(100);

    renderProgress();

    while (true) {
        global.stage_ticks += 1;

        if (!global.complete) {
            if (global.stage_ticks >= FILL_STAGE_INTERVAL_TICKS) {
                global.stage_ticks = 0;
                global.lit_count += 1;
                renderProgress();

                if (global.lit_count >= NUM_LEDS) {
                    global.complete = true;
                    global.cycle_phase = 0;
                    global.stage_ticks = 0;
                    global.cycle_started = false;
                }
            }
        } else {
            if (!global.cycle_started) {
                // Hold the 5th LED for one full second before fast cycling starts.
                if (global.stage_ticks >= FILL_STAGE_INTERVAL_TICKS) {
                    global.stage_ticks = 0;
                    global.cycle_started = true;
                    renderCycle();
                }
            } else {
                if (global.stage_ticks >= FINAL_CYCLE_INTERVAL_TICKS) {
                    global.stage_ticks = 0;
                    global.cycle_phase = (global.cycle_phase + 1) % color_palette.len;
                    renderCycle();
                }
            }
        }

        time.sleep_ms(TICK_MS);
    }
}
