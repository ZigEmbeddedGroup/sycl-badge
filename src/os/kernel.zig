/// SYCL Badge OS Kernel
/// USB CDC and UART communication with interactive console
const std = @import("std");
const microzig = @import("microzig");

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");
const timer = @import("drivers/timer.zig");
const lcd = @import("drivers/lcd.zig");
const console = @import("system/console.zig");
const init = @import("system/init.zig");
const storage = @import("loader/storage.zig");
const loader = @import("loader/loader.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

// Y position for cart list display
var cart_y_pos: u16 = 50;

// Cart display state
var last_cart_hash: u32 = 0;
var cart_hash_accumulator: u32 = 0;
var display_active: bool = true; // Track if we're showing the cart display

// Cart display check interval (in microseconds) - check every 500ms
const CART_CHECK_INTERVAL: u64 = 500_000;
var last_cart_check: u64 = 0;

pub fn main() !void {
    // Initialize all drivers and kernel systems
    try init.init(.{
        .lcd_pins = lcd.createDT018BTFTPins(),
        .lcd_config = lcd.createDT018BTFTConfig(),
        .init_core1 = true,
    });

    // Display startup message on LCD
    lcd.fillScreen(lcd.BLACK);
    lcd.drawString(10, 20, "SYCL Badge OS", lcd.WHITE, lcd.BLACK, 1);
    lcd.drawString(10, 40, "Available Carts:", lcd.CYAN, lcd.BLACK, 1);

    // Initial cart display
    refreshCartDisplay();
    last_cart_hash = computeCartHash();

    // Main loop
    while (true) {
        // Poll USB frequently
        // Avoid spamming UART; keep USB polling tight for CDC/MSC.
        usb.poll();

        // Process console input
        console.processInput();

        // Check if cart is running - stop display updates
        const cart_running = loader.getState() == .running;

        if (cart_running and display_active) {
            // Cart just started running - stop updating display
            display_active = false;
        } else if (!cart_running and !display_active) {
            // Cart stopped - restore display
            display_active = true;
            lcd.fillScreen(lcd.BLACK);
            lcd.drawString(10, 20, "SYCL Badge OS", lcd.WHITE, lcd.BLACK, 1);
            lcd.drawString(10, 40, "Available Carts:", lcd.CYAN, lcd.BLACK, 1);
            last_cart_hash = 0; // Force refresh
        }

        // Periodically check if cart list changed (only when display is active)
        if (display_active) {
            const now = timer.micros();
            if (now -% last_cart_check >= CART_CHECK_INTERVAL) {
                const current_hash = computeCartHash();
                if (current_hash != last_cart_hash) {
                    refreshCartDisplay();
                    last_cart_hash = current_hash;
                }
                last_cart_check = now;
            }
        }
    }
}

/// Compute a simple hash of cart list to detect changes
fn computeCartHash() u32 {
    cart_hash_accumulator = 0;
    storage.listCarts(hashCart);
    return cart_hash_accumulator;
}

/// Callback to hash a cart entry
fn hashCart(name: []const u8, size: u32) void {
    // Simple hash combining name and size
    var h: u32 = size;
    for (name) |c| {
        h = h *% 31 +% c;
    }
    cart_hash_accumulator = cart_hash_accumulator *% 17 +% h;
}

/// Refresh the cart list display on LCD
fn refreshCartDisplay() void {
    // Clear the cart list area (y: 50 to 120)
    lcd.fillRect(0, 50, lcd.width, 70, lcd.BLACK);

    // Reset Y position and display carts
    cart_y_pos = 50;
    storage.listCarts(displayCart);

    // If no carts were displayed, show a message
    if (cart_y_pos == 50) {
        lcd.drawString(10, 50, "(No Carts)", lcd.YELLOW, lcd.BLACK, 1);
    }
}

/// Callback to display a cart entry on the LCD
fn displayCart(name: []const u8, size: u32) void {
    // Convert size from bytes to kB
    const size_kb = (size + 512) / 1024; // Round to nearest kB

    // Format the display string
    var buf: [64]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{s} {d}kB", .{ name, size_kb }) catch return;

    // Draw on LCD if within screen bounds (height is 128)
    if (cart_y_pos < 120) {
        lcd.drawString(10, cart_y_pos, text, lcd.WHITE, lcd.BLACK, 1);
        cart_y_pos += 10;
    }
}
