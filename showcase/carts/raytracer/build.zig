const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Nathan Bourgeois";
pub const author_handle = "iridescentrose";
pub const cart_title = "Raytracer";
pub const description = "Raytracing in One Weekend raytracer on badge!";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "raytracer",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    cart.install(b);
}
