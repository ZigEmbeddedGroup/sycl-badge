const std = @import("std");
const microzig = @import("microzig");
const io_types = microzig.chip.types;
const PORT = microzig.chip.peripherals.PORT;

pub const PinCfg = @typeInfo(std.meta.FieldType(io_types.peripherals.PORT.GROUP, .PINCFG)).Array.child;
pub const Mux = enum(u4) { A, B, C, D, E, F, G, H, I, J, K, L, M, N };
pub const Pin = packed struct(u6) {
    num: u5,
    group: Group,

    pub fn config_ptr(p: Pin) *volatile PinCfg {
        return &p.group.ptr().PINCFG[p.num];
    }

    pub inline fn set_mux(p: Pin, mux: Mux) void {
        const pmux = &p.group.ptr().PMUX[p.num / 2];
        switch (@as(u1, @truncate(p.num))) {
            0 => pmux.modify(.{ .PMUXE = .{
                .value = @as(io_types.peripherals.PORT.PORT_PMUX__PMUXE, @enumFromInt(@intFromEnum(mux))),
            } }),
            1 => pmux.modify(.{ .PMUXO = .{
                .value = @as(io_types.peripherals.PORT.PORT_PMUX__PMUXO, @enumFromInt(@intFromEnum(mux))),
            } }),
        }

        p.config_ptr().modify(.{ .PMUXEN = 1 });
    }

    pub inline fn set_dir(p: Pin, dir: Direction) void {
        switch (dir) {
            .in => {
                p.group.ptr().DIRCLR.write(.{ .DIRCLR = @as(u32, 1) << p.num });
                p.group.ptr().PINCFG[p.num].modify(.{ .INEN = 1 });
            },
            .out => p.group.ptr().DIRSET.write(.{ .DIRSET = @as(u32, 1) << p.num }),
        }
    }

    pub inline fn read(p: Pin) Level {
        return @enumFromInt(p.group.ptr().IN.read().IN >> p.num & 1);
    }

    pub inline fn write(p: Pin, level: Level) void {
        switch (level) {
            .low => p.group.ptr().OUTCLR.write(.{ .OUTCLR = @as(u32, 1) << p.num }),
            .high => p.group.ptr().OUTSET.write(.{ .OUTSET = @as(u32, 1) << p.num }),
        }
    }

    pub fn toggle(p: Pin) void {
        p.group.ptr().OUTTGL.write(.{ .OUTTGL = @as(u32, 1) << p.num });
    }
};

pub const Mask = packed struct(u33) {
    pins: u32,
    group: Group,

    pub inline fn read(m: Mask) u32 {
        return m.group.ptr().IN.read().IN & m.pins;
    }

    /// Sets direction for entire mask
    pub fn set_dir(m: Mask, dir: Direction) void {
        switch (dir) {
            .in => {
                m.group.ptr().DIRCLR.write(.{ .DIRCLR = m.pins });
                for (0..32) |i| {
                    if (m.pins & (@as(u32, 1) << @intCast(i)) != 0)
                        m.group.ptr().PINCFG[i].modify(.{ .INEN = 1 });
                }
            },
            .out => m.group.ptr().DIRSET.write(.{ .DIRSET = m.pins }),
        }
    }
};

pub fn pin(group: Group, num: u5) Pin {
    return Pin{
        .num = num,
        .group = group,
    };
}

pub fn mask(group: Group, pins: u32) Mask {
    return Mask{
        .pins = pins,
        .group = group,
    };
}

pub const Group = enum(u1) {
    a,
    b,

    pub fn ptr(group: Group) *volatile io_types.peripherals.PORT.GROUP {
        return &PORT.GROUP[@intFromEnum(group)];
    }
};
pub const Direction = enum(u1) { in, out };
pub const Level = enum(u1) { low, high };
