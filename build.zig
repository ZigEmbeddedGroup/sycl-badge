const std = @import("std");
const Build = std.Build;

const MicroZig = @import("microzig/build");
const atsam = @import("microzig/bsp/microchip/atsam");

pub const py_badge: MicroZig.Target = .{
    .preferred_format = .elf,
    .chip = atsam.chips.atsamd51j19,
    .hal = null,
};

fn sycl_badge_microzig_target(d: *Build.Dependency) MicroZig.Target {
    return .{
        .preferred_format = .elf,
        .chip = atsam.chips.atsamd51j19.chip,
        .hal = .{
            .root_source_file = d.builder.path("src/hal.zig"),
        },
        .board = .{
            .name = "SYCL Badge Rev A",
            .root_source_file = d.builder.path("src/board.zig"),
        },
        .linker_script = d.builder.path("src/badge/samd51j19a_self.ld"),
    };
}

pub fn build(b: *Build) void {
    const mz = MicroZig.init(b, .{});
    const optimize = b.standardOptimizeOption(.{});

    const ws_dep = b.dependency("ws", .{});
    const mime_dep = b.dependency("mime", .{});

    _ = b.addModule("cart-api", .{ .root_source_file = .{ .path = "src/cart/api.zig" } });

    const watch = b.addExecutable(.{
        .name = "watch",
        .root_source_file = .{ .path = "src/watch/main.zig" },
        .target = b.host,
        .optimize = optimize,
    });
    watch.root_module.addImport("ws", ws_dep.module("websocket"));
    watch.root_module.addImport("mime", mime_dep.module("mime"));

    if (b.host.result.os.tag == .macos) {
        watch.linkFramework("CoreFoundation");
        watch.linkFramework("CoreServices");
    }

    b.getInstallStep().dependOn(&b.addInstallArtifact(watch, .{
        .dest_dir = .disabled,
    }).step);

    var dep: std.Build.Dependency = .{ .builder = b };
    const feature_test_cart = add_cart(&dep, b, .{
        .name = "feature_test",
        .optimize = .Debug,
        .root_source_file = .{ .path = "samples/feature_test.zig" },
    });
    feature_test_cart.install(b);
    const watch_run_step = feature_test_cart.install_with_watcher(&dep, b, .{});

    const zeroman_cart = add_cart(&dep, b, .{
        .name = "zeroman",
        .optimize = optimize,
        .root_source_file = .{ .path = "samples/zeroman/main.zig" },
    });
    add_zeroman_assets_step(b, zeroman_cart);
    zeroman_cart.install(b);

    {
        const cart = add_cart(&dep, b, .{
            .name = "blobs",
            .optimize = .ReleaseSmall,
            .root_source_file = .{ .path = "samples/blobs/blobs.zig" },
        });
        cart.install(b);
        b.step("watch-blobs", "Watch/run blobs in the simulator").dependOn(
            &cart.install_with_watcher(&dep, b, .{}).step,
        );
    }

    const watch_step = b.step("watch", "");
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
        const mvp = mz.add_firmware(b, .{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = .{ .path = std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name}) },
            .target = sycl_badge_microzig_target(&dep),
        });
        mz.install_firmware(b, mvp, .{ .format = .elf });
        mz.install_firmware(b, mvp, .{ .format = .{ .uf2 = .SAMD51 } });
    }

    inline for (.{
        "neopixels",
        "song",
    }) |name| {
        const mvp = add_cart(&dep, b, .{
            .name = std.fmt.comptimePrint("badge.demo.{s}", .{name}),
            .optimize = optimize,
            .root_source_file = .{ .path = std.fmt.comptimePrint("src/badge/demos/{s}.zig", .{name}) },
        });
        mvp.install(b);
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

pub const CartWatcherOptions = struct {
    /// Directories for the Watcher to watch.
    /// If null, defaults to the root source file directory.
    watch_dirs: ?[]const []const u8 = null,
    build_firmware: bool = true,
};

pub const Cart = struct {
    fw: *MicroZig.Firmware,
    wasm: *Build.Step.Compile,
    mz: *MicroZig,
    cart_lib: *Build.Step.Compile,

    options: CartOptions,

    pub fn install(c: *const Cart, b: *Build) void {
        c.mz.install_firmware(b, c.fw, .{ .format = .elf });
        c.mz.install_firmware(b, c.fw, .{ .format = .{ .uf2 = .SAMD51 } });
        b.installArtifact(c.wasm);
    }

    pub fn install_with_watcher(c: *const Cart, d: *Build.Dependency, b: *Build, opt: CartWatcherOptions) *Build.Step.Run {
        if (opt.build_firmware) {
            c.mz.install_firmware(b, c.fw, .{ .format = .{ .uf2 = .SAMD51 } });
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

pub fn add_cart(
    d: *Build.Dependency,
    b: *Build,
    options: CartOptions,
) *Cart {
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

    const sycl_badge_target =
        b.resolveTargetQuery(sycl_badge_microzig_target(d).chip.cpu.target);

    const cart_lib = b.addStaticLibrary(.{
        .name = "cart",
        .root_source_file = options.root_source_file,
        .target = sycl_badge_target,
        .optimize = options.optimize,
        .link_libc = false,
        .single_threaded = true,
        .use_llvm = true,
        .use_lld = true,
        .strip = false,
    });
    cart_lib.root_module.addImport("cart-api", d.module("cart-api"));
    cart_lib.linker_script = d.builder.path("src/cart.ld");

    const mz = MicroZig.init(d.builder, .{});
    const fw = mz.add_firmware(d.builder, .{
        .name = options.name,
        .target = sycl_badge_microzig_target(d),
        .optimize = options.optimize,
        .root_source_file = d.builder.path("src/badge.zig"),
        .linker_script = d.builder.path("src/cart.ld"),
    });
    fw.artifact.linkLibrary(cart_lib);

    const cart: *Cart = b.allocator.create(Cart) catch @panic("OOM");
    cart.* = .{
        .mz = mz,
        .wasm = wasm,
        .fw = fw,
        .cart_lib = cart_lib,
        .options = options,
    };
    return cart;
}

pub fn install_cart(b: *Build, cart: *Cart) void {
    cart.mz.install_firmware(b, cart.fw, .{ .format = .elf });
    cart.mz.install_firmware(b, cart.fw, .{ .format = .{ .uf2 = .SAMD51 } });
}

fn add_zeroman_assets_step(b: *Build, cart: *Cart) void {
    const convert = b.addExecutable(.{
        .name = "convert_gfx",
        .root_source_file = b.path("samples/zeroman/build/convert_gfx.zig"),
        .target = b.host,
        .optimize = cart.options.optimize,
        .link_libc = true,
    });
    convert.root_module.addImport("zigimg", b.dependency("zigimg", .{}).module("zigimg"));

    const base_path = "samples/zeroman/assets/";
    const gen_gfx = b.addRunArtifact(convert);
    inline for (zeroman_assets) |file| {
        gen_gfx.addArg("-i");
        gen_gfx.addFileArg(b.path(base_path ++ file.path));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.bits}));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.transparency}));
    }
    gen_gfx.addArg("-o");
    const gfx_zig = gen_gfx.addOutputFileArg("gfx.zig");

    const gfx_mod = b.addModule("gfx", .{
        .root_source_file = gfx_zig,
        .optimize = cart.options.optimize,
    });
    var dep: std.Build.Dependency = .{ .builder = b };
    gfx_mod.addImport("cart-api", dep.module("cart-api"));

    cart.wasm.step.dependOn(&gen_gfx.step);
    cart.wasm.root_module.addImport("gfx", gfx_mod);
    cart.cart_lib.root_module.addImport("gfx", gfx_mod);
}

const GfxAsset = struct { path: []const u8, bits: u4, transparency: bool };

const zeroman_assets = [_]GfxAsset{
    .{ .path = "door.png", .bits = 2, .transparency = false },
    .{ .path = "effects.png", .bits = 2, .transparency = true },
    .{ .path = "font.png", .bits = 2, .transparency = true },
    .{ .path = "gopher.png", .bits = 4, .transparency = true },
    .{ .path = "healthbar.png", .bits = 4, .transparency = true },
    .{ .path = "hurt.png", .bits = 1, .transparency = true },
    .{ .path = "needleman.png", .bits = 4, .transparency = false },
    .{ .path = "shot.png", .bits = 2, .transparency = true },
    .{ .path = "spike.png", .bits = 2, .transparency = true },
    .{ .path = "teleport.png", .bits = 2, .transparency = true },
    .{ .path = "title.png", .bits = 4, .transparency = false },
    .{ .path = "zero.png", .bits = 4, .transparency = true },
};
