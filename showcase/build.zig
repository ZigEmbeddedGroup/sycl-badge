const std = @import("std");
//const zine = @import("zine");

const root = @import("root");
// cart imports
const carts = .{
    .{ "zeroman", @import("zeroman") },
    .{ "dvd", @import("dvd") },
    .{ "blobs", @import("blobs") },
    .{ "plasma", @import("plasma") },
    .{ "metalgear-timer", @import("metalgear-timer") },
    .{ "raytracer", @import("raytracer") },
    .{ "neopixelpuzzle", @import("neopixelpuzzle") },
    .{ "space-shooter", @import("space-shooter") },
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    inline for (carts) |cart| {
        const cart_name, const cart_import = cart;
        _ = cart_import.author_name;
        if (@hasDecl(cart_import, "author_handle"))
            _ = cart_import.author_handle;
        _ = cart_import.cart_title;
        _ = cart_import.description;
        const dep = b.dependency(cart_name, .{ .optimize = optimize });
        for (dep.builder.install_tls.step.dependencies.items) |dep_step| {
            if (dep_step.cast(std.Build.Step.InstallArtifact)) |install_artifact| {
                b.installArtifact(install_artifact.artifact);
            } else if (dep_step.cast(std.Build.Step.InstallFile)) |install_file| {
                b.getInstallStep().dependOn(&b.addInstallFileWithDir(
                    install_file.source,
                    install_file.dir,
                    install_file.dest_rel_path,
                ).step);
            } else unreachable;
        }
    }
}
