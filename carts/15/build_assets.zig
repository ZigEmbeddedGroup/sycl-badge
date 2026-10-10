const std = @import("std");
const Build = std.Build;

pub const author_name = "Jeff Pele";
pub const author_handle = "jeffective";
pub const cart_title = "15";
pub const description = "15 Puzzle";

// Thank you to Fabio for the code generation step.
// This function is connected manually in build.zig
pub fn build_cart(b: *Build, cart: *Build.Module, cart_api: *Build.Module, step: *Build.Step) void {
    const convert = b.addExecutable(.{
        .name = "convert_gfx",
        .root_module = b.createModule(.{
            .root_source_file = b.path("carts/15/build/convert_gfx.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
            .link_libc = true,
        }),
    });
    convert.root_module.addImport("zigimg", b.dependency("zigimg", .{}).module("zigimg"));
    convert.root_module.addImport("cart-api", cart_api);

    const gen_gfx = b.addRunArtifact(convert);
    gen_gfx.addArg("-i");
    gen_gfx.addFileArg(b.path("carts/15/assets/joshwolfe.png"));
    gen_gfx.addArg("-o");
    const zon_path = gen_gfx.addOutputFileArg("josh.zon");
    step.dependOn(&gen_gfx.step);
    cart.addAnonymousImport("josh.zon", .{ .root_source_file = zon_path });
}
