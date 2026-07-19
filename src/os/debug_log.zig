/// Simple debug log ring buffer for early-boot and loader/storage diagnostics
const std = @import("std");
const microzig = @import("microzig");
const rtt = microzig.cpu.rtt;

const rtt_instance = rtt.RTT(.{
    .up_channels = &.{
        .{ .name = "log", .mode = .NoBlockSkip, .buffer_size = 1024 },
    },
    .linker_section = ".bss.rtt_cb",
});

pub fn init() void {
    rtt_instance.init();
}

/// Log to RTT, note that if the 1KB buffer fills, logs are discarded
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    var buf: [1024]u8 = undefined;
    var writer = rtt_instance.writer(0, &buf);

    writer.interface.print("[{s}] ({t}): " ++ format ++ "\r\n", .{ level.asText(), scope } ++ args) catch {};
    writer.interface.flush() catch {};
}
