const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "SYCL";
pub const cart_title = "LCD Text Viewer";
pub const description = "Text viewer with font scaling and color cycling";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "lcd-text",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    }) orelse return;

    cart.install(b);
}
