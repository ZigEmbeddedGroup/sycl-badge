const std = @import("std");
const Build = std.Build;

const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .samd51 = true,
    .rp2xxx = true,
});

pub fn build(builder: *Build) void {
    const optimize = builder.standardOptimizeOption(.{});

    const mz_dep = builder.dependency("microzig", .{});
    const mb = MicroBuild.init(builder, mz_dep) orelse return;

    _ = builder.addModule("cart-api", .{ .root_source_file = builder.path("src/badge-v1/cart/api.zig") });

    // Badge V2 (RP2354B) target setup
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, builder);

    var dep: std.Build.Dependency = .{ .builder = builder };
    const feature_test_cart = add_cart(&dep, builder, .{
        .name = "feature_test",
        .optimize = optimize,
        .root_source_file = builder.path("src/badge-v1/badge/feature_test.zig"),
    }) orelse return;
    feature_test_cart.install(builder);

    // Badge V2 (RP2354B) demo builds (only blinky works for now)
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
            .root_source_file = builder.path(std.fmt.comptimePrint("src/badge-v1/badge/demos/{s}.zig", .{name})),
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
            .root_source_file = builder.path(std.fmt.comptimePrint("src/badge-v1/badge/demos/{s}.zig", .{name})),
        }) orelse return;
        cart.install(builder);
    }

    // build the OS Kernel (always use ReleaseSmall for minimal size)
    const sycl_os = add_os(&dep, builder, mz_dep, .{
        .name = "sycl-os-kernel",
        .optimize = .ReleaseSmall,
    }) orelse return;
    sycl_os.install(builder);

    // Build test XIP cart (runs on Core 1 with cart_runtime - no microzig)
    add_microzig_cart(builder, &dep, .{
        .name = "lcd-test",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/lcd-test/src/main.zig"),
    });

    // Build test MicroZig cart (runs on Core 1 with full MicroZig HAL)
    add_microzig_cart(builder, &dep, .{
        .name = "test-microzig-cart",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/test-microzig-cart/src/main.zig"),
    });

    // Build test letters cart (cycles through alphabet on LCD)
    add_microzig_cart(builder, &dep, .{
        .name = "test-letters-cart",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/test-letters-cart/main.zig"),
    });

    // Build neopixel-joystick demo cart
    add_microzig_cart(builder, &dep, .{
        .name = "neopixel-joystick",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/neopixel-joystick/main.zig"),
    });

    // Build neopixel puzzle v2 cart
    add_microzig_cart(builder, &dep, .{
        .name = "neopixelpuzzle-v2",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/neopixelpuzzle-v2/main.zig"),
    });

    // Build LCD text viewer cart
    add_microzig_cart(builder, &dep, .{
        .name = "neopixel-joystick",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/neopixel-joystick/main.zig"),
    });

    // OS cart builds - compiled against the new OS cart API (src/os/cart/api.zig)
    add_os_cart(builder, &dep, .{
        .name = "lcd-text",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/lcd-text/src/main.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "space-shooter",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/space-shooter/src/main.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "space-shooter-v2",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/space-shooter-v2/src/main.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "blobs",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/blobs/src/blobs.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "blobs-v2",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/blobs-v2/src/main.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "plasma",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/plasma/src/plasma.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "metalgear-timer",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/metalgear-timer/src/metalgear-timer.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "neopixelpuzzle",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/neopixelpuzzle/src/main.zig"),
    });
    add_os_cart(builder, &dep, .{
        .name = "raytracer",
        .optimize = .ReleaseSmall,
        .root_source_file = builder.path("showcase/carts/raytracer/src/main.zig"),
    });

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
    return mb.ports.samd51.chips.atsamd51j19.derive(.{
        .preferred_binary_format = .elf,
        .board = .{
            .name = "SYCL Badge V2",
            .root_source_file = mb.builder.path("src/badge-v1/board.zig"),
        },
        .linker_script = .{
            .file = mb.builder.path("src/badge-v1/badge/samd51j19a_self.ld"),
            .generate = .none,
        },
        .hal = .{
            .root_source_file = mb.builder.path("src/badge-v1/hal.zig"),
        },
    });
}

fn sycl_badge_v2_microzig_target(mb: *MicroBuild, builder: *Build) *microzig.Target {
    // We use the Raspberry Pi Pico 2 board as base, then customize with our board config
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
    // Install both ELF and UF2 formats
    mb.install_firmware(fw, .{ .format = .elf });
    mb.install_firmware(fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });

    const os: *OS = b.allocator.create(OS) catch @panic("OOM");
    os.* = .{ .exe = fw.exe, .uf2_output = fw.exe.getEmittedBin() };
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
            // Always use ReleaseSmall for WASM to minimize file size
            .optimize = .ReleaseSmall,
            .strip = true,
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
    cart_lib.linker_script = d.builder.path("src/badge-v1/cart.ld");

    const fw = mb.add_firmware(.{
        .name = options.name,
        .target = sycl_badge_target,
        .optimize = options.optimize,
        .root_source_file = d.builder.path("src/badge-v1/badge.zig"),
        .linker_script = .{
            .file = d.builder.path("src/badge-v1/cart.ld"),
            .assert_microzig_main = false,
        },
    });
    fw.exe.root_module.linkLibrary(cart_lib);

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

/// XIP Cart - runs from cart_xip flash region on Core 1
/// Options for XIP cart builds (carts that run on Core 1)
pub const XIPCartBuildOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
};

/// Add an XIP cart that runs from cart_xip flash region on Core 1
/// Carts built this way:
/// - Use cart_runtime.zig for safe startup (no peripheral reinitialization)
/// - Can use cart_hal.zig for GPIO, timers, etc. (works on all RP235X family)
/// - Run on Core 1 while OS runs on Core 0
/// - Do NOT use microzig's startup code (which would crash Core 0)
pub fn add_xip_cart(b: *Build, dep: *Build.Dependency, options: XIPCartBuildOptions) void {
    // ARM Cortex-M33 target (RP235X, same as RP2354B)
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m33 },
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    // Create cart_hal module (standalone HAL for RP235X family)
    const cart_hal_module = b.createModule(.{
        .root_source_file = dep.builder.path("src/cart/cart_hal.zig"),
        .target = target,
    });

    // Create cart_runtime module that imports cart_hal
    const cart_runtime_module = b.createModule(.{
        .root_source_file = dep.builder.path("src/cart/cart_runtime.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "cart_hal.zig", .module = cart_hal_module },
        },
    });

    // Build the cart executable
    const exe = b.addExecutable(.{
        .name = options.name,
        .root_module = b.createModule(.{
            .root_source_file = options.root_source_file,
            .target = target,
            .optimize = options.optimize,
            .imports = &.{
                .{ .name = "cart_runtime", .module = cart_runtime_module },
                .{ .name = "cart_hal", .module = cart_hal_module },
            },
        }),
    });

    // Use cart_xip linker script (places code at 0x101C0000)
    exe.setLinkerScript(dep.builder.path("src/cart/cart_xip.ld"));

    // Install ELF to firmware directory
    const install_elf = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .{ .custom = "firmware" } },
    });
    b.getInstallStep().dependOn(&install_elf.step);

    // Generate binary
    const bin = exe.addObjCopy(.{ .format = .bin });
    const bin_install = b.addInstallBinFile(bin.getOutput(), b.fmt("firmware/{s}.bin", .{options.name}));
    b.getInstallStep().dependOn(&bin_install.step);

    // Generate UF2 from binary
    const uf2_step = Uf2Step.create(b, bin.getOutput(), options.name, 0x101C0000); // cart_xip base
    b.getInstallStep().dependOn(&uf2_step.step);
}

/// MicroZig Cart - runs from cart_xip flash region on Core 1
/// Uses MicroZig's HAL but with automatic init override to prevent Core 0 crash
pub const MicroZigCartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
};

/// Add a MicroZig cart that runs from cart_xip flash region on Core 1
/// Carts built this way:
/// - Use cart_entry.zig as wrapper (auto-provides init override)
/// - User's code is injected as "user_main" module
/// - Full access to MicroZig HAL (GPIO, SPI, I2C, timers, etc.)
/// - Run on Core 1 while OS runs on Core 0
pub fn add_microzig_cart(b: *Build, dep: *Build.Dependency, options: MicroZigCartOptions) void {
    const mz_dep = dep.builder.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    // Get the badge v2 target (RP2354B)
    const badge_v2_target = sycl_badge_v2_microzig_target(mb, dep.builder);

    // Create module for user's main.zig with microzig access
    const user_main_module = b.createModule(.{
        .root_source_file = options.root_source_file,
    });

    // Give user_main access to microzig (will be available after firmware is created)
    // We'll add the import after fw is created since we need the core_mod

    // Create firmware with cart_entry.zig as root (provides init override)
    // Pass linker_script in add_firmware options (like the OS does)
    const fw = mb.add_firmware(.{
        .name = options.name,
        .target = badge_v2_target,
        .optimize = options.optimize,
        .root_source_file = dep.builder.path("src/cart/cart_entry.zig"),
        .linker_script = .{
            .file = dep.builder.path("src/cart/cart_xip.ld"),
            .generate = .none, // Don't generate microzig's default linker script
            .assert_microzig_main = false,
        },
    });

    // Inject user's main.zig as "user_main" module into the app module
    // (app_mod is cart_entry.zig, which imports user_main)
    fw.exe.root_module.addImport("user_main", user_main_module);

    // Give user_main access to microzig so they can use the HAL
    user_main_module.addImport("microzig", fw.core_mod);

    // Install ELF to firmware directory
    mb.install_firmware(fw, .{ .format = .elf });

    // Install UF2 for RP235X
    mb.install_firmware(fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });
}

/// OS Cart - runs on the new RP2354B OS (Core 1), using the new cart API.
/// Cart source must export `fn start()` and `fn update()`.
pub const OsCartOptions = struct {
    name: []const u8,
    optimize: std.builtin.OptimizeMode,
    root_source_file: Build.LazyPath,
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
        .root_source_file = dep.builder.path("src/os/cart/cart_entry.zig"),
        .linker_script = .{
            .file = dep.builder.path("src/cart/cart_xip.ld"),
            .generate = .none,
            .assert_microzig_main = false,
        },
    });

    // Inject cart and api modules into the entry wrapper
    fw.exe.root_module.addImport("user_cart", user_cart_module);
    fw.exe.root_module.addImport("cart-api", cart_api_module);
    user_cart_module.addImport("microzig", fw.core_mod);

    // Share the board module with cart-api so that font.zig belongs to exactly
    // one module (board). Without this, both board_v2.zig and api.zig would
    // directly import font.zig, which Zig prohibits.
    const board_mod = fw.core_mod.import_table.get("board").?;
    cart_api_module.addImport("board", board_mod);

    mb.install_firmware(fw, .{ .format = .elf });
    mb.install_firmware(fw, .{ .format = .{ .uf2 = .{ .family_id = .RP2350_ARM_S } } });

    // WASM build for the web simulator.
    // api.zig detects is_wasm at comptime and switches to WASM extern imports,
    // so no board/microzig dependency is needed here.
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm_cart_api_module = b.createModule(.{
        .root_source_file = dep.builder.path("src/os/cart/api.zig"),
    });

    const wasm = b.addExecutable(.{
        .name = options.name,
        .root_module = b.createModule(.{
            .root_source_file = options.root_source_file,
            .target = wasm_target,
            .optimize = .ReleaseSmall,
            .strip = true,
            .imports = &.{
                .{ .name = "cart-api", .module = wasm_cart_api_module },
            },
        }),
    });
    wasm.entry = .disabled;
    wasm.import_memory = true;
    wasm.initial_memory = 64 * 65536;
    wasm.max_memory = 64 * 65536;
    wasm.stack_size = 14752;
    wasm.global_base = 160 * 128 * 2 + 0x1e;
    wasm.rdynamic = true;
    b.installArtifact(wasm);
}

/// UF2 generation step
const Uf2Step = struct {
    step: Build.Step,
    input_bin: Build.LazyPath,
    name: []const u8,
    base_address: u32,
    output_file: Build.GeneratedFile,

    pub fn create(b: *Build, input_bin: Build.LazyPath, name: []const u8, base_address: u32) *Uf2Step {
        const self = b.allocator.create(Uf2Step) catch @panic("OOM");
        self.* = .{
            .step = Build.Step.init(.{
                .id = .custom,
                .name = b.fmt("Generate UF2 for {s}", .{name}),
                .owner = b,
                .makeFn = make,
            }),
            .input_bin = input_bin,
            .name = name,
            .base_address = base_address,
            .output_file = .{ .step = &self.step },
        };
        input_bin.addStepDependencies(&self.step);

        // Install the output using lazy path
        const output_lazy: Build.LazyPath = .{ .generated = .{ .file = &self.output_file } };
        const install = b.addInstallFile(output_lazy, b.fmt("firmware/{s}.uf2", .{name}));
        install.step.dependOn(&self.step);
        b.getInstallStep().dependOn(&install.step);

        return self;
    }

    fn make(step: *Build.Step, _: Build.Step.MakeOptions) !void {
        const self: *Uf2Step = @fieldParentPtr("step", step);
        const b = step.owner;

        const input_path = self.input_bin.getPath2(b, step);
        const input_data = try std.fs.cwd().readFileAlloc(b.allocator, input_path, 256 * 1024);

        // UF2 constants
        const MAGIC_START0: u32 = 0x0A324655; // "UF2\n"
        const MAGIC_START1: u32 = 0x9E5D5157;
        const MAGIC_END: u32 = 0x0AB16F30;
        const FLAG_FAMILY_PRESENT: u32 = 0x00002000;
        const RP2350_FAMILY: u32 = 0xe48bff59; // RP2354B is the same as RP2350 ARM-S

        const payload_size: u32 = 256;
        const block_count = @as(u32, @intCast((input_data.len + payload_size - 1) / payload_size));

        var uf2_data = std.ArrayListUnmanaged(u8){};

        var block_no: u32 = 0;
        var offset: u32 = 0;
        while (offset < input_data.len) : ({
            block_no += 1;
            offset += payload_size;
        }) {
            const chunk_size = @min(payload_size, @as(u32, @intCast(input_data.len)) - offset);

            // Block header (32 bytes)
            try uf2_data.writer(b.allocator).writeInt(u32, MAGIC_START0, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, MAGIC_START1, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, FLAG_FAMILY_PRESENT, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, self.base_address + offset, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, chunk_size, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, block_no, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, block_count, .little);
            try uf2_data.writer(b.allocator).writeInt(u32, RP2350_FAMILY, .little);

            // Payload (476 bytes, padded)
            try uf2_data.appendSlice(b.allocator, input_data[offset..][0..chunk_size]);
            try uf2_data.appendNTimes(b.allocator, 0, 476 - chunk_size);

            // Magic end
            try uf2_data.writer(b.allocator).writeInt(u32, MAGIC_END, .little);
        }

        // Write output
        const cache_dir = b.cache_root.handle;
        try cache_dir.makePath("uf2");
        const output_path = try std.fmt.allocPrint(b.allocator, "uf2/{s}.uf2", .{self.name});
        try cache_dir.writeFile(.{ .sub_path = output_path, .data = uf2_data.items });

        self.output_file.path = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{
            b.cache_root.path orelse "zig-cache",
            output_path,
        });
    }
};
