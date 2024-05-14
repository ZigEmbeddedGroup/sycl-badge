pub const TFT_RST: Port = .{ .group = .A, .pin = 0 };
pub const TFT_LITE: Port = .{ .group = .A, .pin = 1 };
pub const A0: Port = .{ .group = .A, .pin = 2 };
pub const AVCC: Port = .{ .group = .A, .pin = 3 };
pub const @"+3V3": Port = .{ .Group = .A, .pin = 7 };
pub const QSPI_DATA: [4]Port = .{
    .{ .group = .A, .pin = 8 },
    .{ .group = .A, .pin = 9 },
    .{ .group = .A, .pin = 10 },
    .{ .group = .A, .pin = 11 },
};
pub const D8_NEOPIX: Port = .{ .group = .A, .pin = 15 };
pub const D13: Port = .{ .group = .A, .pin = 5 };
pub const @"D-": Port = .{ .group = .A, .pin = 24 };
pub const @"D+": Port = .{ .group = .A, .pin = 25 };
pub const SPKR_EN: Port = .{ .group = .A, .pin = 23 };
pub const SWCLK: Port = .{ .group = .A, .pin = 30 };
pub const SWDIO: Port = .{ .group = .A, .pin = 31 };

pub const A6_VMEAS: Port = .{ .group = .A, .pin = 4 };
pub const A7_LIGHT: Port = .{ .group = .A, .pin = 6 };
pub const TFT_DC: Port = .{ .group = .B, .pin = 12 };
pub const TFT_CS: Port = .{ .group = .B, .pin = 14 };
pub const QSPI_SCK: Port = .{ .group = .B, .pin = 10 };
pub const QSPI_CS: Port = .{ .group = .B, .pin = 11 };
pub const TFT_SCK: Port = .{ .group = .B, .pin = 13 };
pub const TFT_MOSI: Port = .{ .group = .B, .pin = 15 };

pub const BUTTON_SELECT: Port = .{ .group = .B, .pin = 0 };
pub const BUTTON_START: Port = .{ .group = .B, .pin = 1 };
pub const BUTTON_A: Port = .{ .group = .B, .pin = 2 };
pub const BUTTON_B: Port = .{ .group = .B, .pin = 3 };
pub const BUTTON_UP: Port = .{ .group = .B, .pin = 4 };
pub const BUTTON_DOWN: Port = .{ .group = .B, .pin = 5 };
pub const BUTTON_PRESS: Port = .{ .group = .B, .pin = 6 };
pub const BUTTON_RIGHT: Port = .{ .group = .B, .pin = 7 };
pub const BUTTON_LEFT: Port = .{ .group = .B, .pin = 8 };

group: Group,
pin: u5,

pub const Group = enum { A, B };
pub const Direction = enum { in, out };
pub const Level = enum(u1) { low, high };

pub inline fn set_dir(port: Port, dir: Direction) void {
    switch (dir) {
        .in => port.group_ptr().DIRCLR.write(.{ .DIRCLR = @as(u32, 1) << port.pin }),
        .out => port.group_ptr().DIRSET.write(.{ .DIRSET = @as(u32, 1) << port.pin }),
    }
}

pub inline fn write(port: Port, level: Level) void {
    switch (level) {
        .low => port.group_ptr().OUTCLR.write(.{ .OUTCLR = @as(u32, 1) << port.pin }),
        .high => port.group_ptr().OUTSET.write(.{ .OUTSET = @as(u32, 1) << port.pin }),
    }
}

pub inline fn read(port: Port) Level {
    return @enumFromInt(port.group_ptr().IN.read().IN >> port.pin & 1);
}

pub const Mux = enum(u4) { A, B, C, D, E, F, G, H, I, J, K, L, M, N };
pub inline fn set_mux(port: Port, mux: Mux) void {
    const pmux = &port.group_ptr().PMUX[port.pin / 2];
    switch (@as(u1, @truncate(port.pin))) {
        0 => pmux.modify(.{ .PMUXE = .{
            .value = @as(io_types.PORT.PORT_PMUX__PMUXE, @enumFromInt(@intFromEnum(mux))),
        } }),
        1 => pmux.modify(.{ .PMUXO = .{
            .value = @as(io_types.PORT.PORT_PMUX__PMUXO, @enumFromInt(@intFromEnum(mux))),
        } }),
    }
    port.config_ptr().modify(.{ .PMUXEN = 1 });
}

const PinCfg = @typeInfo(std.meta.FieldType(io_types.PORT.GROUP, .PINCFG)).Array.child;
pub inline fn config_ptr(port: Port) *volatile PinCfg {
    return &port.group_ptr().PINCFG[port.pin];
}

fn group_ptr(port: Port) *volatile io_types.PORT.GROUP {
    return &io.PORT.GROUP[@intFromEnum(port.group)];
}

const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const microzig = @import("microzig");
const Port = @This();
const std = @import("std");
