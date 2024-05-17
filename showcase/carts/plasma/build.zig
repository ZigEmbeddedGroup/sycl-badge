const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Fabio Arnold";
pub const author_handle = "fabioarnold";
pub const cart_title = "plasma";
pub const description = "Plasma effect - computes plasma blobs and cycles their hue";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "plasma",
        .optimize = optimize,
        .root_source_file = b.path("src/plasma.zig"),
    });
    cart.install(b);
}
