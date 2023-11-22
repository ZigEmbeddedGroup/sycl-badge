const std = @import("std");
const atsam = @import("atsam");

pub const py_badge = .{
    .preferred_format = .elf,
    .chip = atsam.chips.atsamd51j19,
    .hal = null,
};

pub fn build(b: *std.Build) void {
    const microzig = @import("microzig").init(b, "microzig");
    const optimize = b.standardOptimizeOption(.{});

    const firmware = microzig.addFirmware(b, .{
        .name = "pybadge-io",
        .target = py_badge,
        .optimize = optimize,
        .source_file = .{ .path = "src/main.zig" },
    });
    microzig.installFirmware(b, firmware, .{});
    microzig.installFirmware(b, firmware, .{ .format = .{ .uf2 = .SAMD51 } });
}
