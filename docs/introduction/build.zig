const std = @import("std");
const badge = @import("sycl-badge");

pub fn build(b: *std.Build) void {
    const dep = b.dependency("sycl-badge", .{});
    const feature_test_cart = badge.add_cart(dep, b, .{
        .name = "hello",
        .optimize = b.standardOptimizeOption(.{}),
        .root_source_file = .{ .path = "src/rule30.zig" },
    });
    const watch_run_step = feature_test_cart.install_with_watcher(dep, b, .{});

    const watch_step = b.step("watch", "");
    watch_step.dependOn(&watch_run_step.step);
}
