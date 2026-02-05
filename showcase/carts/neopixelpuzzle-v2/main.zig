/// Neopixel Puzzle Cart for Badge V2 (RP2354B)
///
/// This is a port of the neopixelpuzzle cart to badge_v2.
/// Currently runs in demo mode (auto-playing) since button input is not yet
/// implemented in the badge_v2 OS.
///
/// Hardware: 5 WS2812B neopixels on GPIO 15

const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const time = hal.time;

// ============================================================================
// Pin Configuration
// ============================================================================

const NEOPIXEL_PIN = 15; // GPIO 15 for neopixel data (from board_v2.zig)
const LED_PIN = 14; // GPIO 14 for status LED

// ============================================================================
// Neopixel Driver for WS2812B
// ============================================================================

const NeopixelColor = extern struct {
    g: u8,
    r: u8,
    b: u8,
};

const Neopixels = struct {
    /// Write colors to all 5 neopixels
    pub fn write(colors: *const [5]NeopixelColor) void {
        var buf: [15]u8 = undefined; // 5 pixels * 3 bytes (GRB)
        
        for (colors, 0..) |color, i| {
            buf[i * 3 + 0] = color.g;
            buf[i * 3 + 1] = color.r;
            buf[i * 3 + 2] = color.b;
        }
        
        write_buf(&buf);
    }
    
    /// Clear all neopixels (set to black)
    pub fn clear() void {
        const colors = [5]NeopixelColor{
            .{ .r = 0, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 0 },
            .{ .r = 0, .g = 0, .b = 0 },
        };
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
// Game State (from original neopixelpuzzle cart)
// ============================================================================

const StartMenu = struct {
    seed: u32,
};

const Play = struct {
    pos: u3,
    grid: [5][2]bool,
};

const Win = struct {
    frame: u32,
};

const Mode = union(enum) {
    start_menu: StartMenu,
    play: Play,
    win: Win,
};

var global = struct {
    mode: Mode = Mode{ .start_menu = .{ .seed = 0 } },
    bright: u8 = 32,
    frame_count: u32 = 0,
}{};

// ============================================================================
// Color Helpers
// ============================================================================

fn on() NeopixelColor {
    return .{ .r = 0, .g = global.bright, .b = 0 };
}

fn off() NeopixelColor {
    return .{ .r = 0, .g = 0, .b = 0 };
}

fn on_select() NeopixelColor {
    return .{ .r = 0, .g = global.bright, .b = global.bright / 2 };
}

fn off_select() NeopixelColor {
    return .{ .r = 0, .g = 0, .b = global.bright / 2 };
}

// ============================================================================
// Game Logic
// ============================================================================

fn rotate(grid: *[5][2]bool, pos: u3) void {
    const t = grid[pos][0];
    const pos2 = (pos + 1) % 5;
    grid[pos][0] = grid[pos][1];
    grid[pos][1] = grid[pos2][1];
    grid[pos2][1] = grid[pos2][0];
    grid[pos2][0] = t;
}

fn newGame(seed: u32) void {
    Neopixels.clear();
    global.mode = Mode{
        .play = .{
            .pos = 2,
            .grid = [5][2]bool{
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
                [2]bool{ false, true },
            },
        },
    };
    
    // Shuffle the grid
    var rand = std.Random.DefaultPrng.init(seed);
    for (0..100) |_| {
        var buf: [1]u8 = undefined;
        rand.fill(&buf);
        rotate(&global.mode.play.grid, @intCast(buf[0] % 5));
    }
}

fn updateStartMenu(start_menu: *StartMenu) void {
    start_menu.seed +%= 1;
    
    // Auto-start after showing animation for a bit
    if (global.frame_count % 300 == 299) {
        const seed = start_menu.seed;
        newGame(seed);
        return;
    }
    
    var colors = [5]NeopixelColor{
        off(), off(), off(), off(), off(),
    };
    colors[(start_menu.seed +% 4) % 5] = off();
    colors[start_menu.seed % 5] = on();
    Neopixels.write(&colors);
}

fn updatePlayMode(play: *Play) void {
    // Demo mode: auto-play every 60 frames
    if (global.frame_count % 60 == 0) {
        // Randomly choose an action
        const action = (global.frame_count / 60) % 10;
        if (action < 5) {
            rotate(&play.grid, play.pos);
        } else if (action < 8) {
            play.pos = (play.pos + 1) % 5;
        } else {
            play.pos = @intCast((@as(usize, play.pos) + 4) % 5);
        }
    }
    
    // Check for win condition
    var win = true;
    for (0..5) |i| {
        if (!play.grid[i][1]) {
            win = false;
            break;
        }
    }
    
    if (win) {
        Neopixels.clear();
        global.mode = Mode{ .win = .{ .frame = 0 } };
        return;
    }
    
    // Display current state
    var colors: [5]NeopixelColor = undefined;
    for (0..5) |i| {
        if (play.pos == i or i == ((play.pos + 1) % 5)) {
            colors[i] = if (play.grid[i][1]) on_select() else off_select();
        } else {
            colors[i] = if (play.grid[i][1]) on() else off();
        }
    }
    Neopixels.write(&colors);
}

fn updateWinMode(win: *Win) void {
    // Auto-restart after celebrating
    if (win.frame > 100) {
        const seed = win.frame;
        newGame(seed);
        return;
    }
    
    win.frame +%= 1;
    var colors = [5]NeopixelColor{
        off(), off(), off(), off(), off(),
    };
    colors[(win.frame +% 4) % 5] = off();
    colors[win.frame % 5] = on_select();
    Neopixels.write(&colors);
}

// ============================================================================
// Main Entry Point
// ============================================================================

pub fn main() !void {
    // Initialize neopixel pin
    const neopixel_pin = gpio.num(NEOPIXEL_PIN);
    neopixel_pin.set_function(.sio);
    neopixel_pin.set_direction(.out);
    neopixel_pin.put(0); // Start low
    
    // Initialize LED pin
    const led_pin = gpio.num(LED_PIN);
    led_pin.set_function(.sio);
    led_pin.set_direction(.out);
    led_pin.put(1); // Turn on to show cart is running
    
    // Clear neopixels
    Neopixels.clear();
    time.sleep_ms(100);
    
    // Main game loop
    while (true) {
        global.frame_count +%= 1;
        
        // Brightness control (cycle through brightness levels automatically)
        if (global.frame_count % 600 == 0) {
            if (global.bright == 0) {
                global.bright = 1;
            } else if (global.bright < 64) {
                global.bright *= 2;
            } else {
                global.bright = 8;
            }
        }
        
        // Update current mode
        switch (global.mode) {
            .start_menu => |*start_menu| updateStartMenu(start_menu),
            .play => |*play| updatePlayMode(play),
            .win => |*win| updateWinMode(win),
        }
        
        // Frame rate: ~30 FPS
        time.sleep_ms(33);
    }
}
