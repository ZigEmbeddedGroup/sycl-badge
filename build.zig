const std = @import("std");

pub const atsamd51j19 = .{
    .name = "ATSAMD51J19A",
    .url = "https://www.microchip.com/en-us/product/ATSAMD51J19A",
    .cpu = .cortex_m4,
    .register_definition = .{
        .atdf = .{ .path = "./board/ATSAMD51J19A.atdf" },
    },
    .memory_regions = &.{
        .{ .kind = .flash, .offset = 0x00000000, .length = 512 * 1024 }, // Embedded Flash
        .{ .kind = .ram, .offset = 0x20000000, .length = 192 * 1024 }, // Embedded SRAM
        .{ .kind = .ram, .offset = 0x47000000, .length = 8 * 1024 }, // Backup SRAM
        .{ .kind = .flash, .offset = 0x00804000, .length = 512 }, // NVM User Row
    },
};

pub const py_badge = .{
    .preferred_format = .elf,
    .chip = atsamd51j19,
    .hal = null,
    // .linker_script = linker_script,
    // .board = .{
    //     .name = "RaspberryPi Pico",
    //     .source_file = .{ .cwd_relative = build_root ++ "/src/boards/raspberry_pi_pico.zig" },
    //     .url = "https://learn.adafruit.com/adafruit-pybadge/downloads",
    // },
    // .configure = rp2040_configure(.w25q080),
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
    microzig.installFirmware(b, firmware, .{ .format = .elf });
}
