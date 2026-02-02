const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    // Create a custom target for cart XIP execution
    // Carts run at 0x101C0000 in the cart_xip flash region
    const cart_target = mb.ports.rp2xxx.boards.raspberrypi.pico2_arm.derive(.{
        .board = null, // No board-specific config needed for carts
    });

    const cart = mb.add_firmware(.{
        .name = "test-xip-cart",
        .target = cart_target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .linker_script = .{
            // Use the cart_xip linker script from the main project
            .file = b.path("../../../src/cart_xip.ld"),
            .generate = .none,
        },
    });

    // Install both ELF and UF2 formats
    mb.install_firmware(cart, .{ .format = .elf });
    mb.install_firmware(cart, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });
}
