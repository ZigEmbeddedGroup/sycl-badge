const std = @import("std");
const Build = std.Build;

const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .atsam = true,
});

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const ws_dep = b.dependency("ws", .{});
    const mime_dep = b.dependency("mime", .{});

    _ = b.addModule("cart-api", .{ .root_source_file = b.path("src/cart/api.zig") });

    const watch = b.addExecutable(.{
        .name = "watch",
        .root_source_file = b.path("src/watch/main.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    });
    watch.root_module.addImport("ws", ws_dep.module("websocket"));
    watch.root_module.addImport("mime", mime_dep.module("mime"));

    if (b.graph.host.result.os.tag == .macos) {
        watch.linkFramework("CoreFoundation");
        watch.linkFramework("CoreServices");
    }

    b.getInstallStep().dependOn(&b.addInstallArtifact(watch, .{
        .dest_dir = .disabled,
    }).step);

    var dep: std.Build.Dependency = .{ .builder = b };
    const feature_test_cart = add_cart(&dep, b, .{
        .name = "feature_test",
        .optimize = optimize,
        .root_source_file = b.path("src/badge/feature_test.zig"),
    }) orelse return;
    feature_test_cart.install(b);
    const watch_run_step = feature_test_cart.install_with_watcher(&dep, b, .{});

    const watch_step = b.step("feature-test", "");
    watch_step.dependOn(&watch_run_step.step);

    inline for (.{
        "blinky",
        //"blinky_timer",
        //"usb_cdc",
        //"usb_storage",
        "buttons",
        "lcd",
        "spi",
        "audio",
        "light_sensor",
        //"qspi",
        //"qa",
        //"clocks",
    }) |name| {
        const mvp = mb.add_firmware(.{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = b.path(std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name})),
            .target = sycl_badge_microzig_target(mb),
        });
        mb.install_firmware(mvp, .{ .format = .elf });
        mb.install_firmware(mvp, .{ .format = .{ .uf2 = .SAMD51 } });
    }

    inline for (.{
        "neopixels",
        "song",
    }) |name| {
        const mvp = add_cart(&dep, b, .{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = b.path(std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name})),
        }) orelse return;
        mvp.install(b);
    }

    const font_export_step = b.step("generate-font.ts", "convert src/font.zig to simulator/src/font.ts");
    const font_export_exe = b.addExecutable(.{
        .name = "font_export_exe",
        .target = b.graph.host,
        .root_source_file = b.path("src/generate_font_ts.zig"),
    });

    const font_export_run = b.addRunArtifact(font_export_exe);
    font_export_run.has_side_effects = true;

    font_export_step.dependOn(&font_export_run.step);
}

pub const CartWatcherOptions = struct {
    /// Directories for the Watcher to watch.
    /// If null, defaults to the root source file directory.
    watch_dirs: ?[]const []const u8 = null,
    build_firmware: bool = true,
};

pub const Cart = struct {
    fw: *MicroBuild.Firmware,
    wasm: *Build.Step.Compile,
    mb: *MicroBuild,
    cart_lib: *Build.Step.Compile,

    options: CartOptions,

    pub fn install(c: *const Cart, b: *Build) void {
        c.mb.install_firmware(c.fw, .{ .format = .elf });
        c.mb.install_firmware(c.fw, .{ .format = .{ .uf2 = .SAMD51 } });
        b.installArtifact(c.wasm);
    }

    pub fn install_with_watcher(c: *const Cart, d: *Build.Dependency, b: *Build, opt: CartWatcherOptions) *Build.Step.Run {
        if (opt.build_firmware) {
            c.mb.install_firmware(c.fw, .{ .format = .{ .uf2 = .SAMD51 } });
        }
        const install_artifact_step = b.addInstallArtifact(c.wasm, .{});
        b.getInstallStep().dependOn(&install_artifact_step.step);

        const watch_run = b.addRunArtifact(d.artifact("watch"));
        watch_run.step.dependOn(&install_artifact_step.step);
        // watch_run.addArgs(&.{ "serve", b.graph.zig_exe, "--input-dir", b.pathFromRoot(std.fs.path.dirname(options.root_source_file) orelse ""), "--cart", b.pathFromRoot("zig-out/bin/feature_test.wasm") });
        watch_run.addArgs(&.{ "serve", b.graph.zig_exe });
        if (opt.watch_dirs) |dirs| {
            if (dirs.len == 0) @panic("watch input directories should either be empty or null");
            for (dirs) |dir| {
                watch_run.addArgs(&.{ "--input-dir", dir });
            }
        } else {
            watch_run.addArgs(&.{"--input-dir"});
            watch_run.addFileArg(c.options.root_source_file.dirname());
        }
        watch_run.addArgs(&.{ "--cart", b.getInstallPath(install_artifact_step.dest_dir.?, install_artifact_step.dest_sub_path) });

        return watch_run;
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
            .name = "SYCL Badge Rev A",
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
        .root_source_file = options.root_source_file,
        .target = wasm_target,
        .optimize = options.optimize,
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

    const cart_lib = b.addStaticLibrary(.{
        .name = "cart",
        .root_source_file = options.root_source_file,
        .target = b.resolveTargetQuery(sycl_badge_target.zig_target),
        .optimize = options.optimize,
        .link_libc = false,
        .single_threaded = true,
        .use_llvm = true,
        .use_lld = true,
        .strip = false,
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
    cart.mz.install_firmware(cart.fw, .{ .format = .{ .uf2 = .SAMD51 } });
}
