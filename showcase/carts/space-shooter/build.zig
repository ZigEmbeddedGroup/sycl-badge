const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Kristoffer Gronlund";
pub const author_handle = "krig";
pub const cart_title = "space-shooter";
pub const description = "A basic bullet hell side scrolling arcade game";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "space-shooter",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    }) orelse return;
    cart.install(b);
}
