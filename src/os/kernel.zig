/// SYCL Badge OS Kernel
/// USB CDC communication with interactive console
const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const rp2xxx = microzig.hal;

const usb = @import("drivers/usb.zig");
const timer = @import("drivers/timer.zig");
const lcd = @import("drivers/lcd.zig");
const gpio = @import("drivers/gpio.zig");
const audio = @import("drivers/audio.zig");
const dma = @import("drivers/dma.zig");
const rev = @import("drivers/rev.zig");
const rtt = @import("drivers/rtt.zig");
const console = @import("system/console.zig");
const init = @import("system/init.zig");
const fps_overlay = @import("system/fps_overlay.zig");
const storage = @import("loader/storage.zig");
const loader = @import("loader/loader.zig");
const multicore = @import("system/multicore.zig");
const terry = @import("system/terry.zig");
const mailbox = @import("ipc/mailbox.zig");
const cart_api = @import("cart/api.zig");
const Controls = cart_api.Controls;
const i2c = @import("drivers/i2c.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;
pub const std_options = microzig.std_options(.{
    .logFn = rtt.log,
});

comptime {
    _ = microzig.export_startup();
}

pub const microzig_options: microzig.Options = .{
    .interrupts = @import("interrupts.zig").interrupts,
};

pub fn read_buttons() Controls {
    return .{
        .start = gpio.isButtonPressed(board.button_start),
        .select = gpio.isButtonPressed(board.button_select),
        .a = gpio.isButtonPressed(board.button_a),
        .b = gpio.isButtonPressed(board.button_b),
        .click = gpio.isButtonPressed(board.joystick_click), // joystick press-in button
        .up = gpio.isButtonPressed(board.joystick_up),
        .down = gpio.isButtonPressed(board.joystick_down),
        .left = gpio.isButtonPressed(board.joystick_left),
        .right = gpio.isButtonPressed(board.joystick_right),
    };
}

// Y position for cart list display
var cart_y_pos: u16 = 2;

// Cart display state
var last_cart_hash: u32 = 0;
var cart_hash_accumulator: u32 = 0;
var display_active: bool = true; // Track if we're showing the cart display

// Cart display check interval (in microseconds) - check every 500ms
const CART_CHECK_INTERVAL: u64 = 500_000;
var last_cart_check: u64 = 0;

// Stop combo: require both START+SELECT held for 500ms before triggering
const STOP_COMBO_HOLD_US: u64 = 500_000;
var stop_combo_deadline: u64 = 0; // 0 = not currently held

// Button diagnostic logging: print raw button state every BTN_DIAG_US microseconds
// while a cart is running.  Uses timer.micros() so it fires at a wall-clock rate
// regardless of main-loop iteration speed.
const BTN_DIAG_US: u64 = 2_000_000; // 2 seconds
var btn_diag_last_us: u64 = 0;
var btn_diag_cart_was_running: bool = false; // tracks first-run edge

const overlay_refresh_period_us: u64 = 30_000;
var overlay_refresh_deadline: u64 = 0;

const EARLY_TRACY_WAIT_TIME_US = 0;
const LATE_TRACY_WAIT_TIME_US = 0; // 60_000_000 * 10; // 10 minutes

// Button state tracking
var last_buttons: Controls = @bitCast(@as(u16, 0));

// Cursor tracking for cart selection
var cursor_index: usize = 0; // Which cart is currently selected
var cart_count: usize = 0; // Total number of carts
var draw_index: usize = 0; // Current cart being drawn
var list_top_index: usize = 0; // First visible cart index in menu list

const CART_LIST_Y_START: u16 = 14;
const CART_LIST_ROW_HEIGHT: u16 = 10;
const CART_LIST_VISIBLE_ROWS: usize = 11;

// Cart name storage for running selected cart
const MAX_CARTS: usize = 64;
const MAX_CART_NAME_LEN: usize = 64;
var cart_names: [MAX_CARTS][MAX_CART_NAME_LEN]u8 = undefined;
var cart_name_lengths: [MAX_CARTS]usize = undefined;
var collect_index: usize = 0;
var cart_list_truncated: bool = false;
var brightness: u10 = 512;

var ready_fb_state: terry.core0.TrackedStateMachine(enum {
    not_ready,
    ready_rect,
    ready_whole,
    transferring,
    draw_debug,
}) = undefined;

var ready_framebuffer: []const u16 = undefined;
var ready_fb_dirty_rect: [4]u16 = undefined;

pub fn main() !void {
    // Initialize all drivers and kernel systems
    try init.init(.{
        .lcd_pins = lcd.createDT018BTFTPins(),
        .lcd_config = lcd.createDT018BTFTConfig(),
        .init_core1 = true,
        .early_wait_for_tracy_time = EARLY_TRACY_WAIT_TIME_US,
        .late_wait_for_tracy_time = LATE_TRACY_WAIT_TIME_US,
    });

    ready_fb_state.register("kernel.ready_fb_state", .not_ready, @src());

    last_buttons = read_buttons();

    // Initial cart display
    refreshCartDisplay();
    last_cart_hash = computeCartHash();

    // Auto-start cart if only one is present in storage
    // _ = loader.autoStartSingleCart();

    const z = terry.core0.zone("Kernel Main Loop", @src());
    defer z.end();

    // Main loop
    while (true) {
        // Poll USB frequently for console
        usb.poll();

        audio.poll();

        terry.client.poll();

        fps_overlay.poll();

        i2c.poll();

        // Process console input
        console.processInput();

        // Check if cart is running - controls both button handling and display updates
        // Check for both .ready and .running states (cart is active from load until stop)
        const cart_state = loader.getState();
        var cart_running = (cart_state == .running) or (cart_state == .ready);

        // Poll buttons
        const buttons = read_buttons();
        const changed: Controls = @bitCast(@as(u16, @bitCast(buttons)) ^ @as(u16, @bitCast(last_buttons)));
        const pressed: Controls = @bitCast(@as(u16, @bitCast(buttons)) & @as(u16, @bitCast(changed)));
        const released: Controls = @bitCast(~@as(u16, @bitCast(buttons)) & @as(u16, @bitCast(changed)));
        _ = released; // not currently used
        defer last_buttons = buttons;

        // Start + Select combo stops running cart (prevents accidental exit in carts
        // that use the Start button for their own purposes).
        // Require both held for 250ms to avoid accidental trigger when pressing START alone.
        const stop_combo = (buttons.start and buttons.select);
        if (cart_running and stop_combo) {
            if (stop_combo_deadline == 0) {
                stop_combo_deadline = timer.micros() + STOP_COMBO_HOLD_US;
            }
            if (timer.micros() > stop_combo_deadline) {
                console.printf("[BTN] START+SELECT (STOP) pressed (cart_running={})\r\n", .{cart_running});
                console.println("[STOP] 1: halting Core 1");
                multicore.haltCore1();
                console.println("[STOP] 2: stopDMA");
                lcd.stopDMA();
                console.println("[STOP] 3a: resetCartBuzzer");
                audio.reset();
                console.println("[STOP] 3b: resetCartPWM");
                gpio.resetCartPWM();
                console.println("[STOP] 3c: resetCartPIO");
                gpio.resetCartPIO();
                console.println("[STOP] 3d: resetCartNeopixels");
                gpio.resetCartNeopixels();
                console.println("[STOP] 3e: resetCartLED");
                gpio.resetCartLED();
                console.println("[STOP] 3f: initButtons");
                gpio.initButtons();
                console.println("[STOP] 4: abortCartChannels");
                dma.abortCartChannels();
                console.println("[STOP] 5: loader.stop");
                loader.stop();
                console.println("[STOP] 6: resetCore1");
                multicore.resetCore1();
                // Mark cart as stopped and restore state before reinit
                cart_running = false;
                display_active = true;
                btn_diag_cart_was_running = false; // reset so next cart launch emits "cart started"
                ready_fb_state.set_state(.not_ready, @src());
                console.println("[STOP] 7: reinitDisplay");
                lcd.reinitDisplay();
                console.println("[STOP] 8: refreshCartDisplay");
                refreshCartDisplay();
                last_cart_hash = computeCartHash();
                console.println("[STOP] 9: done");
            }
        } else {
            stop_combo_deadline = 0;
        }

        // Joystick click toggles FPS overlay at any time (cart running or not)
        if (pressed.click) {
            const new_state = !fps_overlay.isEnabled();
            fps_overlay.setEnabled(new_state);
            console.printf("[BTN] CLICK: FPS overlay {s}\r\n", .{if (new_state) "on" else "off"});
        }

        // Only process navigation buttons when cart is NOT running
        if (!cart_running) {
            // Joystick up - move cursor up through cart list
            if (pressed.up) {
                console.printf("[BTN] UP pressed (cursor={d}, cart_count={d})\r\n", .{ cursor_index, cart_count });
                if (cart_count > 0) {
                    cursor_index = if (cursor_index == 0) cart_count - 1 else cursor_index - 1;
                    refreshCartDisplay();
                }
            }

            // Joystick down - move cursor down through cart list
            if (pressed.down) {
                console.printf("[BTN] DOWN pressed (cursor={d}, cart_count={d})\r\n", .{ cursor_index, cart_count });
                if (cart_count > 0) {
                    cursor_index = (cursor_index + 1) % cart_count;
                    refreshCartDisplay();
                }
            }

            // Button A - run the selected cart
            if (pressed.a) {
                console.printf("[BTN] A pressed (cursor={d}, cart_count={d})\r\n", .{ cursor_index, cart_count });
                if (cart_count > 0 and cursor_index < cart_count) {
                    runSelectedCart();
                    continue;
                } else {
                    console.printf("[BTN] A: no cart to run (cart_count={d})\r\n", .{cart_count});
                }
            }

            const now = timer.micros();
            if (now > overlay_refresh_deadline) {
                overlay_refresh_deadline = now + overlay_refresh_period_us;
                fps_overlay.tick_os();
            }

            if (fps_overlay.is_drawing() and !lcd.isBusy()) {
                fps_overlay.submit_lcd_work();
            }
        } else {
            // Keep ipc_controls updated every iteration so carts always read fresh
            // button state (fixes start/select recognition in spaceshooter, metalgear-timer).
            mailbox.shared_data.controls = buttons;

            // Periodic diagnostic: print raw GPIO reads + processed button state over USB CDC.
            // Fires on first cart-running entry and then every BTN_DIAG_US microseconds.
            const now_us = timer.micros();
            if (!btn_diag_cart_was_running) {
                btn_diag_cart_was_running = true;
                btn_diag_last_us = now_us;
                console.println("[BTN-DIAG] cart started - will log button state every 2s");
            }
            if (now_us -% btn_diag_last_us >= BTN_DIAG_US) {
                btn_diag_last_us = now_us;
                console.printf("[BTN-DIAG] raw_ipc=0x{x:0>3} | gpio(0=pressed): START={} SEL={} A={} B={} UP={} DN={} \r\n", .{
                    @as(u16, @bitCast(buttons)),
                    buttons.start,
                    buttons.select,
                    buttons.a,
                    buttons.b,
                    buttons.up,
                    buttons.down,
                });
            }

            // Mailbox: process all pending messages (trace, framebuffer sync).
            // New-API carts send FRAMEBUFFER_READY when they finish a frame.
            // CART_TRACE: cart debug/panic output via cart.trace().
            while (mailbox.tryReceive()) |msg| {
                if (mailbox.MessageType.getType(msg) == mailbox.MessageType.CART_TRACE) {
                    const len: usize = @min(mailbox.MessageType.getPayload(msg), mailbox.shared_data.trace_buf.len - 1);
                    const buf: [*]const u8 = @volatileCast(&mailbox.shared_data.trace_buf);
                    console.printf("[CART] {s}\r\n", .{buf[0..len]});
                } else if (mailbox.MessageType.getType(msg) == mailbox.MessageType.CART_TONE) {
                    const freq: f32 = mailbox.shared_data.tone_freq;
                    const duration_sec: f32 = mailbox.shared_data.tone_duration;
                    const volume = mailbox.shared_data.tone_volume;
                    const flags = mailbox.shared_data.tone_flags;
                    audio.tone(freq, duration_sec, volume, flags);
                } else if (mailbox.MessageType.getType(msg) == mailbox.MessageType.CART_VOLUME) {
                    const volume = mailbox.shared_data.global_volume;
                    audio.set_global_volume(volume);
                } else if (msg == mailbox.MessageType.FRAMEBUFFER_READY or
                    mailbox.MessageType.getType(msg) == mailbox.MessageType.FRAMEBUFFER_READY_V2)
                {
                    const fb_index: usize = if (mailbox.MessageType.getType(msg) == mailbox.MessageType.FRAMEBUFFER_READY_V2)
                        @intCast(mailbox.MessageType.getPayload(msg) & 0x1)
                    else
                        0;
                    const is_v2: bool = mailbox.MessageType.getType(msg) == mailbox.MessageType.FRAMEBUFFER_READY_V2;
                    const has_dirty_rect: bool = is_v2 and
                        (mailbox.MessageType.getPayload(msg) & 0x2) != 0;

                    // Flush selected shared-RAM framebuffer.
                    fps_overlay.tick_cart();
                    ready_framebuffer = @ptrCast(@volatileCast(&mailbox.shared_data.framebuffers[fb_index]));
                    if (has_dirty_rect) {
                        const rx: u16 = mailbox.shared_data.dirty_rect_x;
                        const ry: u16 = mailbox.shared_data.dirty_rect_y;
                        const rw: u16 = mailbox.shared_data.dirty_rect_w;
                        const rh: u16 = mailbox.shared_data.dirty_rect_h;

                        // Fallback to full-frame if rect metadata is invalid.
                        if (!(rw == 0 or rh == 0 or rx >= 160 or ry >= 128)) {
                            ready_fb_dirty_rect = .{ rx, ry, rw, rh };
                            ready_fb_state.set_state(.ready_rect, @src());
                        } else {
                            ready_fb_state.set_state(.ready_whole, @src());
                        }
                    } else if (!is_v2) {
                        // Legacy carts always imply full-frame updates.
                        ready_fb_state.set_state(.ready_whole, @src());
                    } else {
                        // No visual change this frame: skip LCD transfer.
                        ready_fb_state.set_state(.transferring, @src());
                    }
                }
                // Other messages (e.g. CART_FINISHED) handled by loader state machine.
            }

            // Dispatch async LCD work
            if (!lcd.isBusy()) {
                find_lcd_work: switch (ready_fb_state.state) {
                    .not_ready => {},
                    .ready_rect => {
                        const rect = ready_fb_dirty_rect;
                        lcd.writeCartBufferRect(ready_framebuffer, rect[0], rect[1], rect[2], rect[3]);
                        ready_fb_state.set_state(.transferring, @src());
                    },
                    .ready_whole => {
                        lcd.writeCartBuffer(ready_framebuffer);
                        ready_fb_state.set_state(.transferring, @src());
                    },
                    .transferring => {
                        // Transfer finished, the frame buffer is safe for the app to write
                        //mailbox.send(mailbox.MessageType.FRAMEBUFFER_DONE);
                        ready_fb_state.set_state(.draw_debug, @src());
                        continue :find_lcd_work .draw_debug;
                    },
                    .draw_debug => {
                        if (fps_overlay.is_drawing()) {
                            fps_overlay.submit_lcd_work();
                        } else {
                            mailbox.send(mailbox.MessageType.FRAMEBUFFER_DONE);
                            ready_fb_state.set_state(.not_ready, @src());
                        }
                    },
                }
            }
        }

        if (cart_running and display_active) {
            // Cart just started running - stop updating display
            display_active = false;
        } else if (!cart_running and !display_active) {
            // Cart stopped naturally (not via stop button) - reset hardware and restore display.
            btn_diag_cart_was_running = false; // reset so next cart launch emits "cart started"
            console.printf("[CART] natural stop: state={}, restoring display\r\n", .{loader.getState()});
            lcd.stopDMA();
            fps_overlay.reset_for_cart();
            ready_fb_state.set_state(.not_ready, @src());
            // Reset buzzer, PWM, PIO, neopixel/LED outputs, and button pins.
            gpio.resetCartHardware();
            // Abort any DMA transfers the cart may have left running.
            dma.abortCartChannels();
            display_active = true;
            // Re-sync all button states so any buttons still held when the cart
            // exited are consumed and won't immediately re-trigger menu actions.
            lcd.reinitDisplay();
            refreshCartDisplay();
            last_cart_hash = computeCartHash(); // Update hash to prevent duplicate refresh
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
    const z = terry.core0.fn_zone(@src());
    defer z.end();

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
    const z = terry.core0.fn_zone(@src());
    defer z.end();

    lcd.set_backlight(brightness);
    lcd.fillScreen(lcd.BLACK);
    //lcd.setBacklight(true);

    // Header
    lcd.drawString(0, 2, "Available Carts:", lcd.CYAN, lcd.BLACK, 1);
    cart_y_pos = CART_LIST_Y_START; // below header (8px char + 4px gap)

    draw_index = 0;
    cart_count = 0;
    cart_list_truncated = false;
    storage.listCarts(countCart);

    if (cursor_index >= cart_count) {
        cursor_index = 0;
    }

    if (cart_count <= CART_LIST_VISIBLE_ROWS) {
        list_top_index = 0;
    } else {
        if (cursor_index < list_top_index) {
            list_top_index = cursor_index;
        } else if (cursor_index >= list_top_index + CART_LIST_VISIBLE_ROWS) {
            list_top_index = cursor_index - CART_LIST_VISIBLE_ROWS + 1;
        }

        const max_top = cart_count - CART_LIST_VISIBLE_ROWS;
        if (list_top_index > max_top) {
            list_top_index = max_top;
        }
    }

    draw_index = 0;
    collect_index = 0;
    storage.listCarts(collectCartName);

    draw_index = 0;
    storage.listCarts(displayCart);

    if (list_top_index > 0) {
        lcd.drawString(146, CART_LIST_Y_START, "^", lcd.CYAN, lcd.BLACK, 1);
    }
    if (cart_count > list_top_index + CART_LIST_VISIBLE_ROWS) {
        const bottom_y = CART_LIST_Y_START + @as(u16, @intCast((CART_LIST_VISIBLE_ROWS - 1) * CART_LIST_ROW_HEIGHT));
        lcd.drawString(146, bottom_y, "v", lcd.CYAN, lcd.BLACK, 1);
    }

    if (cart_list_truncated) {
        lcd.drawString(0, 118, "(showing first 64)", lcd.RED, lcd.BLACK, 1);
    }

    if (cart_count == 0) {
        lcd.drawString(0, 50, "(No Carts)", lcd.YELLOW, lcd.BLACK, 1);
    }

    // Always show the hardware revision in the bottom right corner
    var rev_buf: [16]u8 = undefined;
    const rev_str = std.fmt.bufPrint(&rev_buf, "SYCL 2026 rev{s}", .{rev.revision.str()}) catch "rev error";
    const gray: lcd.Color16 = .rgb(0x10, 0x10, 0x10);
    lcd.drawString(@intCast(lcd.width - 8 * rev_str.len), lcd.height - 8, rev_str, gray, lcd.BLACK, 1);

    if (rev.debug or rev.revision == .unknown) {
        const adc_str = std.fmt.bufPrint(&rev_buf, "ADC:{d}", .{rev.raw_reading}) catch "rev error";
        lcd.drawString(@intCast(lcd.width - 8 * adc_str.len), lcd.height - 16, adc_str, gray, lcd.BLACK, 1);
    }

    fps_overlay.redraw();
}

/// Callback to count carts
fn countCart(name: []const u8, size: u32) void {
    _ = name;
    _ = size;
    if (cart_count < MAX_CARTS) {
        cart_count += 1;
    } else {
        cart_list_truncated = true;
    }
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

    const z = terry.core0.fn_zone(@src());
    defer z.end();

    const name = cart_names[cursor_index][0..cart_name_lengths[cursor_index]];
    console.printf("[BTN] runSelectedCart: loading '{s}'\r\n", .{name});

    // Stop any running cart first
    if (loader.isRunning()) {
        console.println("[BTN] stopping running cart before reload");
        multicore.haltCore1();
        loader.stop();
        multicore.resetCore1();
        timer.sleep_ms(100);
    }

    fps_overlay.reset_for_cart();

    // Show loading screen while the UF2 is read from storage and flashed.
    lcd.fillScreen(lcd.BLACK);
    lcd.drawString(0, 20, "Loading Cart", lcd.CYAN, lcd.BLACK, 1);
    lcd.drawString(0, 40, name[0..@min(name.len, 18)], lcd.WHITE, lcd.BLACK, 1);
    lcd.drawString(0, 60, "Please wait...", lcd.YELLOW, lcd.BLACK, 1);

    // Load the cart
    console.println("[BTN] calling loadUF2Cart...");
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

    // Prepare LCD for cart: ensure normal mode (not inverted) and clear screen
    console.printf("[BTN] cart loaded, entry_point=0x{x}\r\n", .{entry_point});
    // NOTE: do NOT touch the LCD here - prepareForCart/fillScreen before executeCart
    // interferes with the cart's own LCD init (forces MADCTL, may leave DMA running).
    // The console 'cart run' command works precisely because it skips these LCD calls.

    // Drain any stale messages from previous cart so they don't overwrite
    // ipc_controls before the new cart's first update().
    while (mailbox.tryReceive()) |_| {}

    // Write current button state before cart's first frame.
    // Carts read at start of update(); this ensures frame 0 sees real buttons
    // rather than all-zero (which broke metalgear-timer and spaceshooter).
    mailbox.shared_data.controls = read_buttons();

    // Execute the cart
    console.println("[BTN] calling executeCart...");
    if (multicore.executeCart(entry_point)) {
        // Cart execution started successfully
        // Mark as running immediately to prevent race conditions
        loader.markRunning();
        // NOTE: do NOT set display_active = false here. cart_running is still false
        // in this loop iteration (it was captured before runSelectedCart was called),
        // so setting display_active = false here causes the !cart_running && !display_active
        // branch to fire immediately, redrawing the menu on top of the cart.
        // The main loop's (cart_running && display_active) check handles this correctly
        // on the next iteration once cart_running reflects the new state.
        console.println("[BTN] executeCart succeeded, cart running");
        // Small delay to let Core 1 start and take control of hardware
        timer.sleep_ms(5);
    } else {
        // Execution failed
        console.println("[BTN] executeCart FAILED");
        lcd.fillRect(0, 50, lcd.width, 70, lcd.BLACK);
        lcd.drawString(0, 50, "Failed to run", lcd.RED, lcd.BLACK, 1);
        timer.sleep_ms(2000);
        refreshCartDisplay();
    }
}

/// Callback to display a cart entry on the LCD
fn displayCart(name: []const u8, size: u32) void {
    _ = size;

    // Strip .uf2 / .UF2 extension for cleaner display
    const display_name = if (name.len >= 4 and
        (std.mem.eql(u8, name[name.len - 4 ..], ".uf2") or
            std.mem.eql(u8, name[name.len - 4 ..], ".UF2")))
        name[0 .. name.len - 4]
    else
        name;

    var buf: [64]u8 = undefined;
    const cursor = if (draw_index == cursor_index) ">" else " ";
    const text = std.fmt.bufPrint(&buf, "{s}{s}", .{ cursor, display_name }) catch return;

    if (draw_index >= list_top_index and draw_index < list_top_index + CART_LIST_VISIBLE_ROWS) {
        const row = draw_index - list_top_index;
        const y = CART_LIST_Y_START + @as(u16, @intCast(row)) * CART_LIST_ROW_HEIGHT;
        const color = if (draw_index == cursor_index) lcd.YELLOW else lcd.WHITE;
        lcd.drawString(0, y, text, color, lcd.BLACK, 1);
    }

    draw_index += 1;
}
