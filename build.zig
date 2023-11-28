const atsam = @import("atsam");
const MicroZig = @import("microzig");
const std = @import("std");

pub const py_badge: MicroZig.Target = .{
    .preferred_format = .elf,
    .chip = atsam.chips.atsamd51j19,
    .hal = null,
};

pub fn build(b: *std.Build) void {
    const mz = MicroZig.init(b, "microzig");
    const optimize = b.standardOptimizeOption(.{});

    const fw_options = b.addOptions();
    fw_options.addOption(bool, "have_cart", false);

    const modified_memory_regions = b.allocator.dupe(MicroZig.MemoryRegion, py_badge.chip.memory_regions) catch @panic("out of memory");
    for (modified_memory_regions) |*memory_region| {
        if (memory_region.kind != .ram) continue;
        memory_region.offset += 0x19A0;
        memory_region.length -= 0x19A0;
        break;
    }
    var modified_py_badge = py_badge;
    modified_py_badge.chip.memory_regions = modified_memory_regions;

    const fw = mz.addFirmware(b, .{
        .name = "pybadge-io",
        .target = modified_py_badge,
        .optimize = optimize,
        .source_file = .{ .path = "src/main.zig" },
    });
    fw.artifact.step.dependOn(&fw_options.step);
    fw.modules.app.dependencies.put("options", fw_options.createModule()) catch @panic("out of memory");
    mz.installFirmware(b, fw, .{});
    mz.installFirmware(b, fw, .{ .format = .{ .uf2 = .SAMD51 } });
}

pub const Cart = struct {
    mz: *MicroZig,
    fw: *MicroZig.Firmware,
};

pub const CartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    source_file: std.Build.LazyPath,
};

pub fn addCart(
    d: *std.Build.Dependency,
    b: *std.Build,
    options: CartOptions,
) *Cart {
    const cart_lib = b.addStaticLibrary(.{
        .name = "cart",
        .root_source_file = options.source_file,
        .target = py_badge.chip.cpu.getDescriptor().target,
        .optimize = options.optimize,
        .link_libc = false,
        .single_threaded = true,
        .use_llvm = true,
        .use_lld = true,
    });
    cart_lib.addModule("wasm4", d.builder.createModule(.{ .source_file = .{ .path = "src/wasm4.zig" } }));

    const fw_options = b.addOptions();
    fw_options.addOption(bool, "have_cart", true);

    const mz = MicroZig.init(d.builder, "microzig");
    const fw = mz.addFirmware(d.builder, .{
        .name = options.name,
        .target = py_badge,
        .optimize = .Debug, // TODO
        .source_file = .{ .path = "src/main.zig" },
        .linker_script = .{ .source_file = .{ .path = "src/cart.ld" } },
    });
    fw.artifact.linkLibrary(cart_lib);
    fw.artifact.step.dependOn(&fw_options.step);
    fw.modules.app.dependencies.put("options", fw_options.createModule()) catch @panic("out of memory");

    const cart: *Cart = b.allocator.create(Cart) catch @panic("out of memory");
    cart.* = .{ .mz = mz, .fw = fw };
    return cart;
}

pub fn installCart(b: *std.Build, cart: *Cart) void {
    cart.mz.installFirmware(b, cart.fw, .{});
    cart.mz.installFirmware(b, cart.fw, .{ .format = .{ .uf2 = .SAMD51 } });
}
