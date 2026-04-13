const std = @import("std");

pub fn build(b: *std.Build) void {
    const cmd = b.addSystemCommand(&.{ "zig", "build" });
    cmd.setCwd(b.path(".."));

    const passthrough_args = b.args orelse &.{};
    cmd.addArgs(passthrough_args);

    b.default_step.dependOn(&cmd.step);
}
