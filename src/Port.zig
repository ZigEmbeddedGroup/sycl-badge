pub const TFT_RST: Port = .{ .group = .A, .pin = 0 };
pub const TFT_LITE: Port = .{ .group = .A, .pin = 1 };
pub const A0: Port = .{ .group = .A, .pin = 2 };
pub const AVCC: Port = .{ .group = .A, .pin = 3 };
pub const A4: Port = .{ .group = .A, .pin = 4 };
pub const A1: Port = .{ .group = .A, .pin = 5 };
pub const A5: Port = .{ .group = .A, .pin = 6 };
pub const @"+3V3": Port = .{ .Group = .A, .pin = 7 };
pub const QSPI_DATA: [4]Port = .{
    .{ .group = .A, .pin = 8 },
    .{ .group = .A, .pin = 9 },
    .{ .group = .A, .pin = 10 },
    .{ .group = .A, .pin = 11 },
};
pub const SDA_3V: Port = .{ .group = .A, .pin = 12 };
pub const SCL_3V: Port = .{ .group = .A, .pin = 13 };
pub const D4: Port = .{ .group = .A, .pin = 14 };
pub const D8_NEOPIX: Port = .{ .group = .A, .pin = 15 };
pub const D5: Port = .{ .group = .A, .pin = 16 };
pub const SCK: Port = .{ .group = .A, .pin = 17 };
pub const D6: Port = .{ .group = .A, .pin = 18 };
pub const D9: Port = .{ .group = .A, .pin = 19 };
pub const D10: Port = .{ .group = .A, .pin = 20 };
pub const D11: Port = .{ .group = .A, .pin = 21 };
pub const D12: Port = .{ .group = .A, .pin = 22 };
pub const D13: Port = .{ .group = .A, .pin = 23 };
pub const @"D-": Port = .{ .group = .A, .pin = 24 };
pub const @"D+": Port = .{ .group = .A, .pin = 25 };
// PA26 not present
pub const SPKR_EN: Port = .{ .group = .A, .pin = 27 };
// PA28-PA29 not present
pub const SWCLK: Port = .{ .group = .A, .pin = 30 };
pub const SWDIO: Port = .{ .group = .A, .pin = 31 };

pub const BUTTON_LATCH: Port = .{ .group = .B, .pin = 0 };
pub const A6_VMEAS: Port = .{ .group = .B, .pin = 1 };
pub const D3_A9: Port = .{ .group = .B, .pin = 2 };
pub const D2_A8: Port = .{ .group = .B, .pin = 3 };
pub const A7_LIGHT: Port = .{ .group = .B, .pin = 4 };
pub const TFT_DC: Port = .{ .group = .B, .pin = 5 };
// PB06 not connected
pub const TFT_CS: Port = .{ .group = .B, .pin = 7 };
pub const A2: Port = .{ .group = .B, .pin = 8 };
pub const A3: Port = .{ .group = .B, .pin = 9 };
pub const QSPI_SCK: Port = .{ .group = .B, .pin = 10 };
pub const QSPI_CS: Port = .{ .group = .B, .pin = 11 };
// PB12 not connected
pub const TFT_SCK: Port = .{ .group = .B, .pin = 13 };
pub const D7_LISIRQ: Port = .{ .group = .B, .pin = 14 };
pub const TFT_MOSI: Port = .{ .group = .B, .pin = 15 };
pub const TX: Port = .{ .group = .B, .pin = 16 };
pub const RX: Port = .{ .group = .B, .pin = 17 };
// PB18-PB21 not present
pub const MISO: Port = .{ .group = .B, .pin = 22 };
pub const MOSI: Port = .{ .group = .B, .pin = 23 };
// PB24-PB29 not present
pub const BUTTON_OUT: Port = .{ .group = .B, .pin = 30 };
pub const BUTTON_CLK: Port = .{ .group = .B, .pin = 31 };

group: Group,
pin: u5,

pub const Group = enum { A, B };

pub inline fn setDir(port: Port, dir: enum { in, out }) void {
    switch (dir) {
        .in => port.groupPtr().DIRCLR.write(.{ .DIRCLR = @as(u32, 1) << port.pin }),
        .out => port.groupPtr().DIRSET.write(.{ .DIRSET = @as(u32, 1) << port.pin }),
    }
}

pub inline fn write(port: Port, value: bool) void {
    switch (value) {
        false => port.groupPtr().OUTCLR.write(.{ .OUTCLR = @as(u32, 1) << port.pin }),
        true => port.groupPtr().OUTSET.write(.{ .OUTSET = @as(u32, 1) << port.pin }),
    }
}

pub inline fn read(port: Port) bool {
    return port.groupPtr().IN.read() & @as(u32, 1) << port.pin != 0;
}

pub const Mux = enum(u4) { A, B, C, D, E, F, G, H, I, J, K, L, M, N };
pub inline fn setMux(port: Port, mux: Mux) void {
    const pmux = &port.groupPtr().PMUX[port.pin / 2];
    switch (@as(u1, @truncate(port.pin))) {
        0 => pmux.modify(.{ .PMUXE = .{
            .value = @as(io_types.PORT.PORT_PMUX__PMUXE, @enumFromInt(@intFromEnum(mux))),
        } }),
        1 => pmux.modify(.{ .PMUXO = .{
            .value = @as(io_types.PORT.PORT_PMUX__PMUXO, @enumFromInt(@intFromEnum(mux))),
        } }),
    }
    port.configPtr().modify(.{ .PMUXEN = 1 });
}

const PinCfg = @typeInfo(std.meta.FieldType(io_types.PORT.GROUP, .PINCFG)).Array.child;
pub inline fn configPtr(port: Port) *volatile PinCfg {
    return &port.groupPtr().PINCFG[port.pin];
}

fn groupPtr(port: Port) *volatile io_types.PORT.GROUP {
    return &io.PORT.GROUP[@intFromEnum(port.group)];
}

const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const microzig = @import("microzig");
const Port = @This();
const std = @import("std");
