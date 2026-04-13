/// Neopixel Joystick Demo Cart for Badge V2 (RP2354B)
///
/// Control a single lit neopixel LED using the joystick:
/// - Left/Right: Move the lit LED
/// - Up/Down: Change the LED color
///
/// Hardware: 5 WS2812B neopixels on GPIO defined by board.neopixel_pin
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const time = hal.time;
const board = microzig.board;

// ============================================================================
// Pin Configuration
// ============================================================================

/// Derived at compile time from the board definition, so board pin changes propagate here automatically.
const NEOPIXEL_PIN: u5 = @intCast(@intFromEnum(board.neopixel_pin));
const NUM_LEDS = 5;

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
    pub fn write(leds: *const [NUM_LEDS]NeopixelColor) void {
        // Initialize buffer to zero to prevent garbage data
        var buf: [NUM_LEDS * 3]u8 = [_]u8{0} ** (NUM_LEDS * 3);

        for (leds, 0..) |color, i| {
            buf[i * 3 + 0] = color.g;
            buf[i * 3 + 1] = color.r;
            buf[i * 3 + 2] = color.b;
        }

        write_buf(&buf);
    }

    /// Low-level WS2812B protocol implementation
    /// Timing: T0H=300ns, T0L=900ns, T1H=600ns, T1L=600ns
    /// RP2350 at 150MHz = 6.67ns per cycle
    ///
    /// NOTE: linksection(".data") places this function in the .data section so
    /// MicroZig copies it to RAM at boot.  This is critical: the bit-bang
    /// timing loop is so short (~300-900 ns per pulse) that an XIP flash cache
    /// miss caused by Core 0's kernel activity would corrupt the WS2812B
    /// bit stream and produce garbage colors.
    fn write_buf(buf: []const u8) linksection(".data") void {
        const pin_mask: u32 = @as(u32, 1) << NEOPIXEL_PIN;

        // Use SIO registers directly for timing-critical operations
        const SIO_GPIO_OUT_SET: *volatile u32 = @ptrFromInt(0xD0000018);
        const SIO_GPIO_OUT_CLR: *volatile u32 = @ptrFromInt(0xD0000020);

        // Send reset pulse (>50us required, using 100us for safety).
        // Interrupts are still enabled here; timing does not matter for the reset.
        SIO_GPIO_OUT_CLR.* = pin_mask;
        time.sleep_us(100);

        // Disable interrupts only for the timing-critical bit transmission.
        // Core 1 has no interrupt handlers so this is safe, but keeping the
        // disabled window as short as possible is good practice.
        asm volatile ("cpsid i");

        // Send each byte
        for (buf) |byte| {
            var mask: u8 = 0x80; // Start with MSB

            while (mask != 0) : (mask >>= 1) {
                const bit_set = (byte & mask) != 0;

                if (bit_set) {
                    // Send bit 1: 600ns high, 600ns low
                    SIO_GPIO_OUT_SET.* = pin_mask;
                    var i: u32 = 0;
                    while (i < 26) : (i += 1) {
                        asm volatile ("nop");
                    }
                    SIO_GPIO_OUT_CLR.* = pin_mask;
                    i = 0;
                    while (i < 26) : (i += 1) {
                        asm volatile ("nop");
                    }
                } else {
                    // Send bit 0: 300ns high, 900ns low
                    SIO_GPIO_OUT_SET.* = pin_mask;
                    var i: u32 = 0;
                    while (i < 12) : (i += 1) {
                        asm volatile ("nop");
                    }
                    SIO_GPIO_OUT_CLR.* = pin_mask;
                    i = 0;
                    while (i < 38) : (i += 1) {
                        asm volatile ("nop");
                    }
                }
            }
        }

        // Re-enable interrupts now that timing-critical transmission is done.
        asm volatile ("cpsie i");

        // Ensure pin ends LOW and send final reset pulse to latch data
        SIO_GPIO_OUT_CLR.* = pin_mask;
        time.sleep_us(100);
    }
};

// ============================================================================
// Color Palette
// ============================================================================

const color_palette = [_]NeopixelColor{
    .{ .r = 32, .g = 0, .b = 0 }, // Red
    .{ .r = 32, .g = 16, .b = 0 }, // Orange
    .{ .r = 32, .g = 32, .b = 0 }, // Yellow
    .{ .r = 0, .g = 32, .b = 0 }, // Green
    .{ .r = 0, .g = 32, .b = 32 }, // Cyan
    .{ .r = 0, .g = 0, .b = 32 }, // Blue
    .{ .r = 16, .g = 0, .b = 32 }, // Purple
    .{ .r = 32, .g = 0, .b = 16 }, // Magenta
};

// ============================================================================
// Game State
// ============================================================================

var global = struct {
    position: u3 = 2, // Current lit LED (0-4)
    color_index: u3 = 0, // Current color (0-7)
    frame_count: u32 = 0,
}{};

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
};

var last_buttons = ButtonState{};

// ============================================================================
// Main Loop
// ============================================================================

pub fn main() void {
    // Initialize neopixel pin as output and ensure it starts LOW
    board.neopixel_pin.set_function(.sio);
    board.neopixel_pin.set_direction(.out);
    board.neopixel_pin.put(0); // Ensure pin starts LOW

    // Initialize joystick pins as inputs with pull-downs
    board.joystick_up.set_function(.sio);
    board.joystick_up.set_direction(.in);
    board.joystick_up.set_pull(.down);

    board.joystick_down.set_function(.sio);
    board.joystick_down.set_direction(.in);
    board.joystick_down.set_pull(.down);

    board.joystick_left.set_function(.sio);
    board.joystick_left.set_direction(.in);
    board.joystick_left.set_pull(.down);

    board.joystick_right.set_function(.sio);
    board.joystick_right.set_direction(.in);
    board.joystick_right.set_pull(.down);

    // Clear all neopixels first
    const clear_leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;
    Neopixels.write(&clear_leds);

    // Initial display
    var leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;
    leds[global.position] = color_palette[global.color_index];
    Neopixels.write(&leds);

    var last_update_frame: u32 = 0;
    const DEBOUNCE_FRAMES = 15; // ~150ms at 100fps

    while (true) {
        global.frame_count += 1;
        const buttons = ButtonState.read();

        // Debounce: only process input every DEBOUNCE_FRAMES
        if (global.frame_count - last_update_frame > DEBOUNCE_FRAMES) {
            var updated = false;

            // Detect button press (wasn't pressed before, is pressed now)
            if (buttons.right and !last_buttons.right and global.position > 0) {
                global.position -= 1;
                updated = true;
                last_update_frame = global.frame_count;
            }

            if (buttons.left and !last_buttons.left and global.position < NUM_LEDS - 1) {
                global.position += 1;
                updated = true;
                last_update_frame = global.frame_count;
            }

            if (buttons.up and !last_buttons.up) {
                global.color_index = @intCast((global.color_index + 1) % color_palette.len);
                updated = true;
                last_update_frame = global.frame_count;
            }

            if (buttons.down and !last_buttons.down) {
                if (global.color_index == 0) {
                    global.color_index = @intCast(color_palette.len - 1);
                } else {
                    global.color_index -= 1;
                }
                updated = true;
                last_update_frame = global.frame_count;
            }

            // Update display if state changed
            if (updated) {
                leds = [_]NeopixelColor{.{ .r = 0, .g = 0, .b = 0 }} ** NUM_LEDS;
                leds[global.position] = color_palette[global.color_index];
                Neopixels.write(&leds);
            }
        }

        last_buttons = buttons;

        // Frame rate control (~100fps = 10ms per frame)
        time.sleep_ms(10);
    }
}
