const std = @import("std");
const Build = std.Build;
const sycl_badge = @import("sycl_badge");

pub const author_name = "Stevie Hryciw";
pub const author_handle = "hryx";
pub const cart_title = "dvd";
pub const description = "Bouncing DVD logo screensaver";

pub fn build(b: *Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "dvd",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    }) orelse return;
    add_dvd_assets_step(b, sycl_badge_dep, cart);
    cart.install(b);
}

// Thank you to Fabio for the code generation step.
fn add_dvd_assets_step(
    b: *Build,
    sycl_badge_dep: *Build.Dependency,
    cart: *sycl_badge.Cart,
) void {
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
    gen_gfx.addArg("-i");
    gen_gfx.addFileArg(b.path("assets/dvd.png"));
    gen_gfx.addArg(std.fmt.comptimePrint("{}", .{8}));
    gen_gfx.addArg(std.fmt.comptimePrint("{}", .{false}));
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
