const std = @import("std");
const Build = std.Build;

const MicroZig = @import("microzig/build");
const atsam = @import("microzig/bsp/microchip/atsam");

pub const py_badge: MicroZig.Target = .{
    .preferred_format = .elf,
    .chip = atsam.chips.atsamd51j19,
    .hal = null,
};

pub const sycl_badge_2024 = MicroZig.Target{
    .preferred_format = .elf,
    .chip = atsam.chips.atsamd51j19.chip,
    .hal = .{
        .root_source_file = .{ .cwd_relative = "src/hal.zig" },
    },
    .board = .{
        .name = "SYCL Badge 2024",
        .root_source_file = .{ .cwd_relative = "src/board.zig" },
    },
};

pub fn build(b: *Build) void {
    const mz = MicroZig.init(b, .{});

    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("wasm4", .{ .root_source_file = .{ .path = "src/wasm4.zig" } });

    var dep: std.Build.Dependency = .{ .builder = b };
    const cart = add_cart(&dep, b, .{
        .name = "sample",
        .optimize = optimize,
        .root_source_file = .{ .path = "samples/feature_test.zig" },
    });

    const watch_step = b.step("watch", "");
    watch_step.dependOn(&cart.watch_run_cmd.step);

    //const modified_memory_regions = b.allocator.dupe(MicroZig.MemoryRegion, py_badge.chip.memory_regions) catch @panic("out of memory");
    //for (modified_memory_regions) |*memory_region| {
    //    if (memory_region.kind != .ram) continue;
    //    memory_region.offset += 0x19A0;
    //    memory_region.length -= 0x19A0;
    //    break;
    //}
    //var modified_py_badge = py_badge;
    //modified_py_badge.chip.memory_regions = modified_memory_regions;

    //const fw = mz.add_firmware(b, .{
    //    .name = "pybadge-io",
    //    .target = modified_py_badge,
    //    .optimize = optimize,
    //    .source_file = .{ .path = "src/main.zig" },
    //});
    //fw.artifact.step.dependOn(&fw_options.step);
    //fw.modules.app.addImport("options", fw_options.createModule());x
    //mz.install_firmware(b, fw, .{});
    //mz.install_firmware(b, fw, .{ .format = .{ .uf2 = .SAMD51 } });

    const badge = mz.add_firmware(b, .{
        .name = "badge",
        .target = sycl_badge_2024,
        .optimize = optimize,
        .root_source_file = .{ .path = "src/badge.zig" },
    });
    mz.install_firmware(b, badge, .{});

    inline for (.{
        "blinky",
        "blinky_timer",
        "usb_cdc",
        "usb_storage",
        "buttons",
        "lcd",
        "audio",
        "light_sensor",
        "neopixels",
        "qspi",
    }) |name| {
        const mvp = mz.add_firmware(b, .{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .target = sycl_badge_2024,
            .optimize = optimize,
            .root_source_file = .{ .path = std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name}) },
        });
        mz.install_firmware(b, mvp, .{});
    }

    const font_export_step = b.step("generate-font.ts", "convert src/font.zig to simulator/src/font.ts");
    font_export_step.makeFn = struct {
        fn make(_: *std.Build.Step, _: *std.Progress.Node) anyerror!void {
            const font = @import("src/font.zig").font;
            var file = try std.fs.cwd().createFile("simulator/src/font.ts", .{});
            try file.writer().writeAll("export const FONT = Uint8Array.of(\n");
            for (font) |char| {
                try file.writer().writeAll("   ");
                for (char) |byte| {
                    try file.writer().print(" 0x{X:0>2},", .{byte});
                }
                try file.writer().writeByte('\n');
            }
            try file.writer().writeAll(");\n");
            file.close();
        }
    }.make;
}

pub const Cart = struct {
    // mz: *MicroZig,
    // fw: *MicroZig.Firmware,

    watch_run_cmd: *std.Build.Step.Run,
};

pub const CartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
};

pub fn add_cart(
    d: *Build.Dependency,
    b: *Build,
    options: CartOptions,
) *Cart {
    const lib = b.addExecutable(.{
        .name = "cart",
        .root_source_file = options.root_source_file,
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
        }),
        .optimize = options.optimize,
    });
    b.installArtifact(lib);

    lib.entry = .disabled;
    lib.import_memory = true;
    lib.initial_memory = 65536;
    lib.max_memory = 65536;
    lib.stack_size = 14752;
    lib.global_base = 160 * 128 * 2 + 0x1e;

    lib.rdynamic = true;

    lib.root_module.addImport("wasm4", d.module("wasm4"));

    const host_target = b.resolveTargetQuery(.{});
    const watch = d.builder.addExecutable(.{
        .name = "watch",
        .root_source_file = .{ .path = "src/watch/main.zig" },
        .target = host_target,
        .optimize = options.optimize,
    });
    watch.root_module.addImport("ws", d.builder.dependency("ws", .{}).module("websocket"));
    watch.root_module.addImport("mime", d.builder.dependency("mime", .{}).module("mime"));

    if (host_target.result.os.tag == .macos) {
        watch.linkFramework("CoreFoundation");
        watch.linkFramework("CoreServices");
    }

    const watch_run_cmd = b.addRunArtifact(watch);
    watch_run_cmd.step.dependOn(b.getInstallStep());

    watch_run_cmd.addArgs(&.{
        "serve",
        b.graph.zig_exe,
        "--zig-out-bin-dir",
        b.pathJoin(&.{ b.install_path, "bin" }),
        "--input-dir",
        options.root_source_file.dirname().getPath(b),
    });

    const cart: *Cart = b.allocator.create(Cart) catch @panic("out of memory");
    cart.* = .{
        .watch_run_cmd = watch_run_cmd,
    };
    return cart;

    // const cart_lib = b.addStaticLibrary(.{
    //     .name = "cart",
    //     .root_source_file = options.source_file,
    //     .target = py_badge.chip.cpu.getDescriptor().target,
    //     .optimize = options.optimize,
    //     .link_libc = false,
    //     .single_threaded = true,
    //     .use_llvm = true,
    //     .use_lld = true,
    // });
    // cart_lib.addModule("wasm4", d.module("wasm4"));

    // const fw_options = b.addOptions();
    // fw_options.addOption(bool, "have_cart", true);

    // const mz = MicroZig.init(d.builder, "microzig");

    // const fw = mz.addFirmware(d.builder, .{
    //     .name = options.name,
    //     .target = py_badge,
    //     .optimize = .Debug, // TODO
    //     .source_file = .{ .path = "src/main.zig" },
    //     .linker_script = .{ .source_file = .{ .path = "src/cart.ld" } },
    // });
    // fw.artifact.linkLibrary(cart_lib);
    // fw.artifact.step.dependOn(&fw_options.step);
    // fw.modules.app.dependencies.put("options", fw_options.createModule()) catch @panic("out of memory");

    // const cart: *Cart = b.allocator.create(Cart) catch @panic("out of memory");
    // cart.* = .{ .mz = mz, .fw = fw };
    // return cart;
}

pub fn install_cart(b: *Build, cart: *Cart) void {
    cart.mz.install_firmware(b, cart.fw, .{});
    cart.mz.install_firmware(b, cart.fw, .{ .format = .{ .uf2 = .SAMD51 } });
}
