const std = @import("std");
const Build = std.Build;

const sycl_badge = @import("sycl_badge");

pub const author_name = "Fabio Arnold";
pub const author_handle = "CaptainHorst";
pub const cart_title = "Zeroman";
pub const description = "<TODO>: get Fabio to give a description";

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "zeroman",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    }) orelse return;
    add_zeroman_assets_step(sycl_badge_dep, b, cart);
    cart.install(b);
}

fn add_zeroman_assets_step(
    sycl_badge_dep: *Build.Dependency,
    b: *Build,
    cart: *sycl_badge.Cart,
) void {
    @setEvalBranchQuota(5000);
    const convert = b.addExecutable(.{
        .name = "convert_gfx",
        .root_module = b.createModule(.{
            .root_source_file = b.path("build/convert_gfx.zig"),
            .target = b.graph.host,
            .optimize = cart.options.optimize,
            .link_libc = true,
        }),
    });
    convert.root_module.addImport("zigimg", b.dependency("zigimg", .{}).module("zigimg"));

    const gen_gfx = b.addRunArtifact(convert);
    inline for (zeroman_assets) |file| {
        gen_gfx.addArg("-i");
        gen_gfx.addFileArg(b.path(file.path));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.bits}));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.transparency}));
    }
    gen_gfx.addArg("-o");
    const gfx_zig = gen_gfx.addOutputFileArg("gfx.zig");

    const gfx_mod = b.addModule("gfx", .{
        .root_source_file = gfx_zig,
        .optimize = cart.options.optimize,
        .imports = &.{
            .{
                .name = "packed_int_array",
                .module = b.createModule(.{
                    .root_source_file = b.path("src/packed_int_array.zig"),
                }),
            },
        },
    });
    gfx_mod.addImport("cart-api", sycl_badge_dep.module("cart-api"));

    cart.wasm.step.dependOn(&gen_gfx.step);
    cart.wasm.root_module.addImport("gfx", gfx_mod);
    cart.cart_lib.root_module.addImport("gfx", gfx_mod);
}

const GfxAsset = struct { path: []const u8, bits: u4, transparency: bool };

const zeroman_assets = [_]GfxAsset{
    .{ .path = "assets/door.png", .bits = 2, .transparency = false },
    .{ .path = "assets/effects.png", .bits = 2, .transparency = true },
    .{ .path = "assets/font.png", .bits = 2, .transparency = true },
    .{ .path = "assets/gopher.png", .bits = 4, .transparency = true },
    .{ .path = "assets/healthbar.png", .bits = 4, .transparency = true },
    .{ .path = "assets/hurt.png", .bits = 1, .transparency = true },
    .{ .path = "assets/needleman.png", .bits = 4, .transparency = false },
    .{ .path = "assets/shot.png", .bits = 2, .transparency = true },
    .{ .path = "assets/spike.png", .bits = 2, .transparency = true },
    .{ .path = "assets/teleport.png", .bits = 2, .transparency = true },
    .{ .path = "assets/title.png", .bits = 4, .transparency = false },
    .{ .path = "assets/zero.png", .bits = 4, .transparency = true },
};
