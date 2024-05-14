const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;

// pins
const ButtonPoller = board.ButtonPoller;
const led_pin = board.D13;

const Symbol = enum {
    dot,
    dash,

    fn blink(symbol: Symbol, pin: microzig.hal.port.Pin) void {
        pin.write(.high);
        delay_count(switch (symbol) {
            .dot => unit_period_count,
            .dash => 3 * unit_period_count,
        });
        pin.write(.low);
        delay_count(unit_period_count);
    }
};

const unit_period_count = 200000;

const Mapping = struct {
    character: u8,
    symbols: []const Symbol,
};

const alphabet = [_]Mapping{
    .{ .character = 'a', .symbols = &.{ .dot, .dash } }, // A: .-
    .{ .character = 'b', .symbols = &.{ .dash, .dot, .dot, .dot } }, // B: -...
    .{ .character = 'c', .symbols = &.{ .dash, .dot, .dash, .dot } }, // C: -.-.
    .{ .character = 'd', .symbols = &.{ .dash, .dot, .dot } }, // D: -..
    .{ .character = 'e', .symbols = &.{.dot} }, // E: .
    .{ .character = 'f', .symbols = &.{ .dot, .dot, .dash, .dot } }, // F: ..-.
    .{ .character = 'g', .symbols = &.{ .dash, .dash, .dot } }, // G: --.
    .{ .character = 'h', .symbols = &.{ .dot, .dot, .dot, .dot } }, // H: ....
    .{ .character = 'i', .symbols = &.{ .dot, .dot } }, // I: ..
    .{ .character = 'j', .symbols = &.{ .dot, .dash, .dash, .dash } }, // J: .---
    .{ .character = 'k', .symbols = &.{ .dash, .dot, .dash } }, // K: -.-
    .{ .character = 'l', .symbols = &.{ .dot, .dash, .dot, .dot } }, // L: .-..
    .{ .character = 'm', .symbols = &.{ .dash, .dash } }, // M: --
    .{ .character = 'n', .symbols = &.{ .dash, .dot } }, // N: -.
    .{ .character = 'o', .symbols = &.{ .dash, .dash, .dash } }, // O: ---
    .{ .character = 'p', .symbols = &.{ .dot, .dash, .dash, .dot } }, // P: .--.
    .{ .character = 'q', .symbols = &.{ .dash, .dash, .dot, .dash } }, // Q: --.-
    .{ .character = 'r', .symbols = &.{ .dot, .dash, .dot } }, // R: .-.
    .{ .character = 's', .symbols = &.{ .dot, .dot, .dot } }, // S: ...
    .{ .character = 't', .symbols = &.{.dash} }, // T: -
    .{ .character = 'u', .symbols = &.{ .dot, .dot, .dash } }, // U: ..-
    .{ .character = 'v', .symbols = &.{ .dot, .dot, .dot, .dash } }, // V: ...-
    .{ .character = 'w', .symbols = &.{ .dot, .dash, .dash } }, // W: .--
    .{ .character = 'x', .symbols = &.{ .dash, .dot, .dot, .dash } }, // X: -..-
    .{ .character = 'y', .symbols = &.{ .dash, .dot, .dash, .dash } }, // Y: -.--
    .{ .character = 'z', .symbols = &.{ .dash, .dash, .dot, .dot } }, // Z: --..
};

fn get_symbols(character: u8) []const Symbol {
    return for (alphabet) |entry| {
        if (entry.character == character)
            break entry.symbols;
    } else unreachable;
}

pub fn main() !void {
    const poller = ButtonPoller.init();
    // Use morse code to convey which button is currently pressed
    led_pin.set_dir(.out);

    while (true) {
        const message: []const u8 = blk: {
            const buttons = poller.read_from_port();
            inline for (@typeInfo(ButtonPoller.Buttons).Struct.fields) |field| {
                if (@field(buttons, field.name) == 1)
                    break :blk field.name;
            }

            continue;
        };

        for (message) |character| {
            const symbols = get_symbols(character);
            for (symbols) |symbol| symbol.blink(led_pin);

            // there's supposed to be 3, but we already wait one period after every symbol
            delay_count(2 * unit_period_count);
        }

        delay_count(5 * unit_period_count);
    }
}

fn delay_count(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {}
}
