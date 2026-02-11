/// SYCL Badge OS Kernel
/// USB CDC and UART communication with interactive console
const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;

const usb = @import("drivers/usb.zig");
const uart = @import("drivers/uart.zig");
const timer = @import("drivers/timer.zig");
const lcd = @import("drivers/lcd.zig");
const gpio = @import("drivers/gpio.zig");
const console = @import("system/console.zig");
const init = @import("system/init.zig");
const storage = @import("loader/storage.zig");
const loader = @import("loader/loader.zig");
const multicore = @import("system/multicore.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

// Simple button poller (similar to badge-v1)
const ButtonPoller = struct {
    pub const Buttons = packed struct(u2) {
        up: u1, // GPIO 10
        down: u1, // GPIO 11
    };

    pub fn init() ButtonPoller {
        gpio.initButtons();
        return ButtonPoller{};
    }

    pub fn read(self: ButtonPoller) Buttons {
        _ = self;
        return .{
            .up = if (gpio.isButtonPressed(board.button_up)) 1 else 0,
            .down = if (gpio.isButtonPressed(board.button_down)) 1 else 0,
        };
    }
};

// Y position for cart list display
var cart_y_pos: u16 = 50;

// Cart display state
var last_cart_hash: u32 = 0;
var cart_hash_accumulator: u32 = 0;
var display_active: bool = true; // Track if we're showing the cart display

// Cart display check interval (in microseconds) - check every 500ms
const CART_CHECK_INTERVAL: u64 = 500_000;
var last_cart_check: u64 = 0;

// Button state tracking
var button_up_was_pressed: bool = false;
var button_down_was_pressed: bool = false;

// Cursor tracking for cart selection
var cursor_index: usize = 0; // Which cart is currently selected
var cart_count: usize = 0; // Total number of carts
var draw_index: usize = 0; // Current cart being drawn

// Cart name storage for running selected cart
const MAX_CARTS: usize = 16;
const MAX_CART_NAME_LEN: usize = 64;
var cart_names: [MAX_CARTS][MAX_CART_NAME_LEN]u8 = undefined;
var cart_name_lengths: [MAX_CARTS]usize = undefined;
var collect_index: usize = 0;

pub fn main() !void {
    // Initialize all drivers and kernel systems
    try init.init(.{
        .lcd_pins = lcd.createDT018BTFTPins(),
        .lcd_config = lcd.createDT018BTFTConfig(),
        .init_core1 = true,
    });

    // Initialize button poller
    const button_poller = ButtonPoller.init();
    const initial = button_poller.read();
    button_up_was_pressed = (initial.up == 1);
    button_down_was_pressed = (initial.down == 1);

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

        // Poll buttons (non-toggle behavior like badge-v1)
        const buttons = button_poller.read();

        // Detect button_up press (GPIO 10) - move cursor down through cart list
        if (buttons.up == 1 and !button_up_was_pressed) {
            button_up_was_pressed = true;
            // Move cursor to next cart (wrap around to top)
            if (cart_count > 0) {
                cursor_index = (cursor_index + 1) % cart_count;
                refreshCartDisplay();
            }
        } else if (buttons.up == 0 and button_up_was_pressed) {
            button_up_was_pressed = false;
        }

        // Detect button_down press (GPIO 11) - run selected cart
        if (buttons.down == 1 and !button_down_was_pressed) {
            button_down_was_pressed = true;
            // Run the selected cart
            if (cart_count > 0 and cursor_index < cart_count) {
                runSelectedCart();
            }
        } else if (buttons.down == 0 and button_down_was_pressed) {
            button_down_was_pressed = false;
        }

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
    draw_index = 0;
    cart_count = 0;
    storage.listCarts(countCart);

    // Reset cursor if cart list changed
    if (cursor_index >= cart_count) {
        cursor_index = 0;
    }

    // Collect cart names
    draw_index = 0;
    collect_index = 0;
    storage.listCarts(collectCartName);

    // Display carts
    draw_index = 0;
    storage.listCarts(displayCart);

    // If no carts were displayed, show a message
    if (cart_count == 0) {
        lcd.drawString(10, 50, "(No Carts)", lcd.YELLOW, lcd.BLACK, 1);
    }
}

/// Callback to count carts
fn countCart(name: []const u8, size: u32) void {
    _ = name;
    _ = size;
    cart_count += 1;
}

/// Callback to collect cart names
fn collectCartName(name: []const u8, size: u32) void {
    _ = size;
    if (collect_index >= MAX_CARTS) return;

    const copy_len = @min(name.len, MAX_CART_NAME_LEN - 1);
    @memcpy(cart_names[collect_index][0..copy_len], name[0..copy_len]);
    cart_name_lengths[collect_index] = copy_len;
    collect_index += 1;
}

/// Run the currently selected cart
fn runSelectedCart() void {
    if (cursor_index >= cart_count) return;

    const name = cart_names[cursor_index][0..cart_name_lengths[cursor_index]];

    // Stop any running cart first
    if (loader.isRunning()) {
        multicore.resetCore1();
        timer.sleep_ms(100);
    }

    // Load the cart
    const entry_point = loader.loadUF2Cart(name) catch |err| {
        // Show error on LCD
        lcd.fillRect(0, 50, lcd.width, 70, lcd.BLACK);
        const error_msg = switch (err) {
            loader.LoadError.FileNotFound => "Cart not found",
            loader.LoadError.FileTooLarge => "UF2 too large",
            loader.LoadError.InvalidUF2 => "Invalid UF2",
            loader.LoadError.UnsupportedFamily => "Wrong chip",
            loader.LoadError.AddressMismatch => "Wrong address",
            loader.LoadError.FlashWriteError => "Flash error",
            loader.LoadError.ReadError => "Read error",
        };
        lcd.drawString(10, 50, error_msg, lcd.RED, lcd.BLACK, 1);
        timer.sleep_ms(2000);
        refreshCartDisplay();
        return;
    };

    // Execute the cart
    if (multicore.executeCart(entry_point)) {
        // Cart execution started successfully
        display_active = false;
    } else {
        // Execution failed
        lcd.fillRect(0, 50, lcd.width, 70, lcd.BLACK);
        lcd.drawString(10, 50, "Failed to run", lcd.RED, lcd.BLACK, 1);
        timer.sleep_ms(2000);
        refreshCartDisplay();
    }
}

/// Callback to display a cart entry on the LCD
fn displayCart(name: []const u8, size: u32) void {
    // Convert size from bytes to kB
    const size_kb = (size + 512) / 1024; // Round to nearest kB

    // Format the display string with cursor indicator
    var buf: [64]u8 = undefined;
    const cursor = if (draw_index == cursor_index) ">" else " ";
    const text = std.fmt.bufPrint(&buf, "{s}{s} {d}kB", .{ cursor, name, size_kb }) catch return;

    // Draw on LCD if within screen bounds (height is 128)
    if (cart_y_pos < 120) {
        lcd.drawString(10, cart_y_pos, text, lcd.WHITE, lcd.BLACK, 1);
        cart_y_pos += 10;
    }

    draw_index += 1;
}
