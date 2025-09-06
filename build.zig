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

    _ = b.addModule("cart-api", .{ .root_source_file = b.path("src/cart/api.zig") });

    var dep: std.Build.Dependency = .{ .builder = b };
    const feature_test_cart = add_cart(&dep, b, .{
        .name = "feature_test",
        .optimize = optimize,
        .root_source_file = b.path("src/badge/feature_test.zig"),
    }) orelse return;
    feature_test_cart.install(b);

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
        .root_module = b.createModule(.{
            .target = b.graph.host,
            .root_source_file = b.path("src/generate_font_ts.zig"),
        }),
    });

    const font_export_run = b.addRunArtifact(font_export_exe);
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
        c.mb.install_firmware(c.fw, .{ .format = .{ .uf2 = .SAMD51 } });
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
    cart.mz.install_firmware(cart.fw, .{ .format = .{ .uf2 = .SAMD51 } });
}
