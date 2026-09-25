const std = @import("std");
const Build = std.Build;

const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .samd51 = true,
    .rp2xxx = true,
});

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    // Badge V2 (RP2354B) target setup
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, b);

    var dep: std.Build.Dependency = .{ .builder = b };

    const kernel = mb.add_firmware(.{
        .name = "sycl-os-kernel",
        .target = badge_v2_target,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/os/kernel.zig"),
        .linker_script = .{
            .file = b.path("src/os/linker.ld"),
            .generate = .none, // Don't generate microzig's default linker script
        },
        .stack = .{ .symbol_name = "__stack" }, // Exported by linker script
        .asserts = true,
    });

    // Install both ELF and UF2 formats
    mb.install_firmware(kernel, .{ .format = .elf });
    mb.install_firmware(kernel, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });

    // OS cart builds - compiled against the new OS cart API (src/os/cart/api.zig)
    add_os_cart(b, &dep, .{
        .name = "lcd-text",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/lcd-text/src/main.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "space-shooter",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/space-shooter/src/main.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "blobs",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/blobs/src/blobs.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "plasma",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/plasma/src/plasma.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "metalgear-timer",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/metalgear-timer/src/metalgear-timer.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "neopixelpuzzle",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/neopixelpuzzle/src/main.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "raytracer",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/raytracer/src/main.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "audio",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/audio/src/main.zig"),
    });
    add_os_cart(b, &dep, .{
        .name = "dvd",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/dvd/src/main.zig"),
        .custom_builder = &@import("showcase/carts/dvd/build.zig").build_cart,
    });
    add_os_cart(b, &dep, .{
        .name = "zeroman",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/zeroman/src/main.zig"),
        .custom_builder = @import("showcase/carts/zeroman/build.zig").build_cart,
    });
    add_os_cart(b, &dep, .{
        .name = "vsync",
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("showcase/carts/vsync/src/main.zig"),
    });

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

    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/os/test.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&kernel.exe.step);

    const calc_version = b.addExecutable(.{
        .name = "calc_version",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tools/calc_version.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });

    const run_calc_version = b.addRunArtifact(calc_version);
    const calc_version_step = b.step("calc-version", "");
    calc_version_step.dependOn(&run_calc_version.step);

    b.installArtifact(calc_version);
}

fn sycl_badge_v2_microzig_target(mb: *MicroBuild, b: *Build) *microzig.Target {
    // We use the Raspberry Pi Pico 2 board as base, then customize with our board config
    const base_target = mb.ports.rp2xxx.boards.raspberrypi.pico2_arm;

    return base_target.derive(.{
        .board = .{
            .name = "SYCL Badge V2",
            .root_source_file = b.path("src/board_v2.zig"),
        },
    });
}

/// OS Cart - runs on the new RP2354B OS (Core 1), using the new cart API.
/// Cart source must export `fn start()` and `fn update()`.
pub const OsCartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
    custom_builder: ?*const fn (b: *Build, cart: *Build.Module, cart_api: *Build.Module, step: *Build.Step) void = null,
};

pub fn add_os_cart(b: *Build, dep: *Build.Dependency, options: OsCartOptions) void {
    const mz_dep = dep.builder.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, dep.builder);

    // The cart-api module for OS (ARM build)
    const cart_api_module = b.createModule(.{
        .root_source_file = dep.builder.path("src/os/cart/api.zig"),
    });

    // The user's cart source (must export start() and update())
    const user_cart_module = b.createModule(.{
        .root_source_file = options.root_source_file,
        .imports = &.{
            .{ .name = "cart-api", .module = cart_api_module },
        },
    });

    // Firmware root is OS cart entry wrapper
    const fw = mb.add_firmware(.{
        .name = options.name,
        .target = badge_v2_target,
        .optimize = options.optimize,
        .root_source_file = options.root_source_file,
        .linker_script = .{
            .file = dep.builder.path("src/cart/cart_ram.ld"),
            .generate = .none,
            .assert_microzig_main = false,
        },
    });

    // Inject cart and api modules into the entry wrapper
    fw.exe.root_module.addImport("user_cart", user_cart_module);
    fw.exe.root_module.addImport("cart-api", cart_api_module);

    const asset_step: ?*Build.Step = if (options.custom_builder) |builder| blk: {
        // Zig build no longer allows custom/anonymous steps, so we'll mark it as "top-level"
        // even though it's intermediate.
        const shared_step = b.allocator.create(Build.Step.TopLevel) catch @panic("oom");
        shared_step.* = .{
            .step = .init(.{
                .name = b.fmt("{s} assets", .{options.name}),
                .tag = .top_level,
                .owner = b,
            }),
            .description = "Reusable build node for cart assets",
        };

        builder(b, fw.exe.root_module, cart_api_module, &shared_step.step);

        break :blk &shared_step.step;
    } else null;

    // Share the board module with cart-api so that font.zig belongs to exactly
    // one module (board). Without this, both board_v2.zig and api.zig would
    // directly import font.zig, which Zig prohibits.
    const board_mod = fw.core_mod.import_table.get("board").?;
    cart_api_module.addImport("board", board_mod);
    cart_api_module.addImport("tracy_protocol", b.createModule(.{
        .root_source_file = b.path("src/os/system/tracy_protocol.zig"),
    }));

    mb.install_firmware(fw, .{ .format = .elf });
    mb.install_firmware(fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });

    // WASM build for the web simulator.
    // api.zig detects is_wasm at comptime and switches to WASM extern imports,
    // so no board/microzig dependency is needed here.
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    // This is hacky as hell, but necessary since the root module specifies the build target.
    const wasm_module = b.allocator.create(Build.Module) catch @panic("oom");
    wasm_module.* = fw.exe.root_module.*;
    wasm_module.resolved_target = wasm_target;

    const wasm = b.addExecutable(.{
        .name = options.name,
        .root_module = wasm_module,
    });
    wasm.entry = .disabled;
    wasm.import_memory = true;
    wasm.initial_memory = 64 * 65536;
    wasm.max_memory = 64 * 65536;
    wasm.stack_size = 14752;
    wasm.global_base = 160 * 128 * 2 + 0x1e;
    wasm.rdynamic = true;
    b.installArtifact(wasm);

    if (asset_step) |step| {
        wasm.step.dependOn(step);
        fw.exe.step.dependOn(step);
    }
}
