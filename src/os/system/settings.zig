const std = @import("std");

const kernel = @import("../kernel.zig");
const audio = @import("../drivers/audio.zig");
const abi = @import("../cart/os_abi.zig");
const adc = @import("../drivers/adc.zig");
const lcd = @import("../drivers/lcd.zig");
const Controls = abi.Controls;
const Rect8 = abi.Rect8;

var active: bool = false;
var selected: enum {
    exit_cart,
    brightness,
    volume,
} = .exit_cart;

var auto_bright: bool = true;
var brightness: f32 = 0.5;
var mute: bool = false;
var global_volume: f32 = audio.initial_global_volume;

pub fn effectiveLightLevel() u12 {
    if (auto_bright) {
        return adc.light_level;
    } else {
        return @round(brightness * std.math.maxInt(u12));
    }
}

pub fn appendClipRects(buf: *std.ArrayList(Rect8)) void {
    if (active) buf.appendAssumeCapacity(.{
        .min_x = 8,
        .min_y = 16,
        .max_x = lcd.width - 8,
        .max_y = lcd.height - 16,
    });
}

pub fn init() void {
    audio.set_global_volume(if (mute) 0.0 else global_volume);
}

pub fn setGlobalVolume(volume: f32) void {
    global_volume = volume;
    if (!mute) audio.set_global_volume(volume);
}

pub fn activate(in_cart: bool) void {
    active = true;
    selected = if (in_cart) .exit_cart else .brightness;
}

pub fn isActive() bool {
    return active;
}

pub fn update(pressed: Controls, in_cart: bool, force_refresh: bool) void {
    const num_settings = @typeInfo(@TypeOf(selected)).@"enum".field_names.len;

    var redraw = force_refresh;

    if (pressed.start or pressed.select or pressed.b) {
        active = false;
        return;
    }

    if (pressed.up) {
        switch (@backingInt(selected)) {
            0 => selected = @fromBackingInt(num_settings - 1),
            else => |i| selected = @fromBackingInt(i - 1),
        }
        if (selected == .exit_cart and !in_cart) {
            // "Exit Cart" is not a valid setting while not in a cart, so go one further.
            switch (@backingInt(selected)) {
                0 => selected = @fromBackingInt(num_settings - 1),
                else => |i| selected = @fromBackingInt(i - 1),
            }
        }
        redraw = true;
    }

    if (pressed.down) {
        switch (@backingInt(selected)) {
            num_settings - 1 => selected = @fromBackingInt(0),
            else => |i| selected = @fromBackingInt(i + 1),
        }
        if (selected == .exit_cart and !in_cart) {
            // "Exit Cart" is not a valid setting while not in a cart, so go one further.
            switch (@backingInt(selected)) {
                num_settings - 1 => selected = @fromBackingInt(0),
                else => |i| selected = @fromBackingInt(i + 1),
            }
        }
        redraw = true;
    }

    if (pressed.a) switch (selected) {
        .exit_cart => {
            active = false;
            kernel.stop_active_cart();
            return;
        },
        .brightness => {
            auto_bright = !auto_bright;
            //if (in_cart) kernel.updateNeopixels(); // MLUGG??
            redraw = true;
        },
        .volume => {
            mute = !mute;
            audio.set_global_volume(if (mute) 0.0 else global_volume);
            redraw = true;
        },
    };

    if (pressed.left) switch (selected) {
        .exit_cart => {},
        .brightness => {
            auto_bright = false;
            brightness = @min(@max(brightness - 0.1, 0.0), 1.0);
            redraw = true;
        },
        .volume => {
            mute = false;
            global_volume = @min(@max(global_volume - 0.1, 0.0), 1.0);
            audio.set_global_volume(global_volume);
            redraw = true;
        },
    };

    if (pressed.right) switch (selected) {
        .exit_cart => {},
        .brightness => {
            auto_bright = false;
            brightness = @min(@max(brightness + 0.1, 0.0), 1.0);
            redraw = true;
        },
        .volume => {
            mute = false;
            global_volume = @min(@max(global_volume + 0.1, 0.0), 1.0);
            audio.set_global_volume(global_volume);
            redraw = true;
        },
    };

    if (redraw) draw(in_cart);
}

fn draw(in_cart: bool) void {
    lcd.fillRect(8, 16, lcd.width - 16, lcd.height - 32, .black);
    lcd.drawRect(8, 16, lcd.width - 16, lcd.height - 32, .yellow);
    lcd.drawString(
        12,
        18,
        "Exit Cart",
        if (!in_cart)
            .{ .r = 0b01111, .g = 0b011110, .b = 0b01111 }
        else if (selected == .exit_cart)
            .yellow
        else
            .white,
        .black,
        1,
    );
    lcd.drawString(12, 28, "Brightness", if (selected == .brightness) .yellow else .white, .black, 1);
    lcd.drawString(12, 38, "Volume", if (selected == .volume) .yellow else .white, .black, 1);

    var buf: [32]u8 = undefined;

    const brightness_str: []const u8 = if (auto_bright) "[auto]" else std.mem.print(
        &buf,
        "{d: >3.0}%",
        .{brightness * 100},
    ) catch unreachable;
    lcd.drawString(@intCast(
        lcd.width - 12 - brightness_str.len * 8,
    ), 28, brightness_str, .white, .black, 1);

    const volume_str: []const u8 = if (mute) "[mute]" else std.mem.print(
        &buf,
        "{d: >3.0}%",
        .{global_volume * 100},
    ) catch unreachable;
    lcd.drawString(@intCast(
        lcd.width - 12 - volume_str.len * 8,
    ), 38, volume_str, .white, .black, 1);
}
