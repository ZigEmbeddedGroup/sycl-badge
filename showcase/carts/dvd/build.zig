const std = @import("std");
const Build = std.Build;
const sycl_badge = @import("sycl_badge");

pub const author_name = "Stevie Hryciw";
pub const author_handle = "hryx";
pub const cart_title = "dvd";
pub const description = "Bouncing DVD logo screensaver";

// Thank you to Fabio for the code generation step.
pub fn build_cart(b: *Build, cart: *Build.Module, cart_api: *Build.Module, step: *Build.Step) void {
    const convert = b.addExecutable(.{
        .name = "convert_gfx",
        .root_module = b.createModule(.{
            .root_source_file = b.path("showcase/carts/dvd/build/convert_gfx.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
            .link_libc = true,
        }),
    });
    convert.root_module.addImport("zigimg", b.dependency("zigimg", .{}).module("zigimg"));

    const gen_gfx = b.addRunArtifact(convert);
    gen_gfx.addArg("-i");
    gen_gfx.addFileArg(b.path("showcase/carts/dvd/assets/dvd.png"));
    gen_gfx.addArg(std.fmt.comptimePrint("{}", .{8}));
    gen_gfx.addArg(std.fmt.comptimePrint("{}", .{false}));
    gen_gfx.addArg("-o");
    const gfx_zig = gen_gfx.addOutputFileArg("gfx.zig");

    const gfx_mod = b.createModule(.{
        .root_source_file = gfx_zig,
        .imports = &.{
            .{
                .name = "packed_int_array",
                .module = b.createModule(.{
                    .root_source_file = b.path("showcase/carts/dvd/src/packed_int_array.zig"),
                }),
            },
        },
    });
    gfx_mod.addImport("cart-api", cart_api);
    step.dependOn(&gen_gfx.step);
    cart.addImport("gfx", gfx_mod);
}
