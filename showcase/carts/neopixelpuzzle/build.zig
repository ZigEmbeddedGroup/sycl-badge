const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Jonathan Marler";
pub const author_handle = "marler8997";
pub const cart_title = "neopixelpuzzle";
pub const description = "Light up all the neo pixels in this simple puzzle game!";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "neopixelpuzzle",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    cart.install(b);
}
