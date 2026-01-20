const std = @import("std");
const Build = std.Build;

const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .atsam = true,
    .rp2xxx = true,
});

pub fn build(builder: *Build) void {
    const optimize = builder.standardOptimizeOption(.{});

    const mz_dep = builder.dependency("microzig", .{});
    const mb = MicroBuild.init(builder, mz_dep) orelse return;

    _ = builder.addModule("cart-api", .{ .root_source_file = builder.path("src/cart/api.zig") });

    // Badge V2 (RP2350) target setup
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, builder);

    var dep: std.Build.Dependency = .{ .builder = builder };
    const feature_test_cart = add_cart(&dep, builder, .{
        .name = "feature_test",
        .optimize = optimize,
        .root_source_file = builder.path("src/badge/feature_test.zig"),
    }) orelse return;
    feature_test_cart.install(builder);

    // Badge V2 (RP2350) demo builds (only blinky works for now)
    inline for (.{
        "blinky",
        //"blinky_timer",
        //"usb_cdc",
        //"usb_storage",
        // "buttons",
        // "lcd",
        // "spi",
        // "audio",
        // "light_sensor",
        //"qspi",
        //"qa",
        //"clocks",
    }) |name| {
        const exe = mb.add_firmware(.{
            .name = std.fmt.comptimePrint("badge.v2.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = builder.path(std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name})),
            .target = badge_v2_target,
        });
        mb.install_firmware(exe, .{ .format = .elf });
        mb.install_firmware(exe, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });
    }

    inline for (.{
        "neopixels",
        "song",
    }) |name| {
        const cart = add_cart(&dep, builder, .{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = builder.path(std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name})),
        }) orelse return;
        cart.install(builder);
    }

    // build the OS Kernel (always use ReleaseSmall for minimal size)
    const sycl_os = add_os(&dep, builder, mz_dep, .{
        .name = "sycl-os-kernel",
        .optimize = .ReleaseSmall,
    }) orelse return;
    sycl_os.install(builder);

    const font_export_step = builder.step("generate-font.ts", "convert src/font.zig to simulator/src/font.ts");
    const font_export_exe = builder.addExecutable(.{
        .name = "font_export_exe",
        .root_module = builder.createModule(.{
            .target = builder.graph.host,
            .root_source_file = builder.path("src/generate_font_ts.zig"),
        }),
    });

    const font_export_run = builder.addRunArtifact(font_export_exe);
    font_export_run.has_side_effects = true;

    font_export_step.dependOn(&font_export_run.step);
}

pub const Cart = struct {
    fw: *MicroBuild.Firmware,
    wasm: *Build.Step.Compile,
    mb: *MicroBuild,
    cart_lib: *Build.Step.Compile,

    options: CartOptions,

    pub fn install(c: *const Cart, b: *Build) void {
        c.mb.install_firmware(c.fw, .{ .format = .elf });
        c.mb.install_firmware(c.fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_NS } } });
        b.installArtifact(c.wasm);
    }
};

pub const CartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
};

fn sycl_badge_microzig_target(mb: *MicroBuild) *microzig.Target {
    return mb.ports.atsam.chips.atsamd51j19.derive(.{
        .preferred_binary_format = .elf,
        .board = .{
            .name = "SYCL Badge V2",
            .root_source_file = mb.builder.path("src/board.zig"),
        },
        .linker_script = .{
            .file = mb.builder.path("src/badge/samd51j19a_self.ld"),
            .generate = .none,
        },
        .hal = .{
            .root_source_file = mb.builder.path("src/hal.zig"),
        },
    });
}

fn sycl_badge_v2_microzig_target(mb: *MicroBuild, builder: *Build) *microzig.Target {
    // Use the Raspberry Pi Pico 2 board as base, then customize with our board config
    const base_target = mb.ports.rp2xxx.boards.raspberrypi.pico2_arm;

    return base_target.derive(.{
        .board = .{
            .name = "SYCL Badge V2",
            .root_source_file = builder.path("src/board_v2.zig"),
        },
    });
}

pub const OS = struct {
    exe: *Build.Step.Compile, // the compiled ELF file
    uf2_output: Build.LazyPath, // the UF2 file made from the ELF file

    pub fn install(os: *const OS, b: *Build) void {
        const install_elf = b.addInstallArtifact(os.exe, .{
            .dest_dir = .{ .override = .{ .custom = "firmware" } },
        });
        b.getInstallStep().dependOn(&install_elf.step);

        const uf2_install_path = b.fmt("firmware/{s}.uf2", .{os.exe.name});
        const install_uf2 = b.addInstallFile(os.uf2_output, uf2_install_path);
        b.getInstallStep().dependOn(&install_uf2.step);
    }
};

pub const OSOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode, // this massively reduces UF2 file size
};

pub fn add_os(
    d: *Build.Dependency,
    b: *Build,
    mz_dep: *Build.Dependency,
    options: OSOptions,
) ?*OS {
    // Use microzig's firmware builder which provides startup code and HAL access
    const mb = MicroBuild.init(b, mz_dep) orelse return null;
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, d.builder);

    const fw = mb.add_firmware(.{
        .name = options.name,
        .target = badge_v2_target,
        .optimize = options.optimize,
        .root_source_file = d.builder.path("src/os/kernel.zig"),
        .linker_script = .{
            .file = d.builder.path("src/os/linker.ld"),
            .generate = .none, // Don't generate microzig's default linker script
        },
    });

    // WASM runtime (wasm3) integration
    fw.artifact.addIncludePath(b.path("src/os/loader"));
    fw.artifact.addIncludePath(mz_dep.path("modules/foundation-libc/include"));
    fw.artifact.addIncludePath(b.path("lib/wasm3/source"));
    const wasm3_flags = &.{
        "-Dd_m3LogParse=0",
        "-Dd_m3LogModule=0",
        "-Dd_m3LogCompile=0",
        "-Dd_m3LogRuntime=0",
    };
    const wasm3_files = [_][]const u8{
        "lib/wasm3/source/m3_bind.c",
        "lib/wasm3/source/m3_code.c",
        "lib/wasm3/source/m3_compile.c",
        "lib/wasm3/source/m3_core.c",
        "lib/wasm3/source/m3_env.c",
        "lib/wasm3/source/m3_exec.c",
        "lib/wasm3/source/m3_function.c",
        "lib/wasm3/source/m3_info.c",
        "lib/wasm3/source/m3_module.c",
        "lib/wasm3/source/m3_parse.c",
        "src/os/loader/wasm3_host.c",
        "src/os/loader/stdio_stub.c",
        "src/os/loader/stdlib_stub.c",
        "src/os/loader/string_stub.c",
    };
    for (wasm3_files) |file| {
        fw.artifact.addCSourceFile(.{ .file = b.path(file), .flags = wasm3_flags });
    }

    // Install both ELF and UF2 formats
    mb.install_firmware(fw, .{ .format = .elf });
    mb.install_firmware(fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });

    const os: *OS = b.allocator.create(OS) catch @panic("OOM");
    os.* = .{ .exe = fw.artifact, .uf2_output = fw.artifact.getEmittedBin() };
    return os;
}

pub fn add_cart(
    d: *Build.Dependency,
    b: *Build,
    options: CartOptions,
) ?*Cart {
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm = b.addExecutable(.{
        .name = options.name,
        .root_module = b.createModule(.{
            .root_source_file = options.root_source_file,
            .target = wasm_target,
            .optimize = options.optimize,
        }),
    });
    wasm.entry = .disabled;
    wasm.import_memory = true;
    wasm.initial_memory = 64 * 65536;
    wasm.max_memory = 64 * 65536;
    wasm.stack_size = 14752;
    wasm.global_base = 160 * 128 * 2 + 0x1e;
    wasm.rdynamic = true;
    wasm.root_module.addImport("cart-api", d.module("cart-api"));

    const microzig_dep = d.builder.dependency("microzig", .{});
    const mb = MicroBuild.init(d.builder, microzig_dep) orelse return null;
    const sycl_badge_target = sycl_badge_microzig_target(mb);
    const cart_lib = b.addLibrary(.{
        .name = "cart",
        .root_module = b.createModule(.{
            .root_source_file = options.root_source_file,
            .target = b.resolveTargetQuery(sycl_badge_target.zig_target),
            .optimize = options.optimize,
            .link_libc = false,
            .single_threaded = true,

            .strip = false,
        }),
        .use_llvm = true,
        .use_lld = true,
    });
    cart_lib.root_module.addImport("cart-api", d.module("cart-api"));
    cart_lib.linker_script = d.builder.path("src/cart.ld");

    const fw = mb.add_firmware(.{
        .name = options.name,
        .target = sycl_badge_target,
        .optimize = options.optimize,
        .root_source_file = d.builder.path("src/badge.zig"),
        .linker_script = .{
            .file = d.builder.path("src/cart.ld"),
        },
    });
    fw.artifact.linkLibrary(cart_lib);

    const cart: *Cart = b.allocator.create(Cart) catch @panic("OOM");
    cart.* = .{
        .mb = mb,
        .wasm = wasm,
        .fw = fw,
        .cart_lib = cart_lib,
        .options = options,
    };

    return cart;
}

pub fn install_cart(b: *Build, cart: *Cart) void {
    _ = b;
    cart.mz.install_firmware(cart.fw, .{ .format = .elf });
    cart.mz.install_firmware(cart.fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });
}
