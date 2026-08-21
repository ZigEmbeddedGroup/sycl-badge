const std = @import("std");
const microzig = @import("microzig");
const rtt = @import("microzig_rtt.zig");

const rtt_instance = rtt.RTT(.{
    .up_channels = &.{
        .{ .name = "TracySend", .buffer_size = tracy_send_size, .mode = .BlockIfFull },
        .{ .name = "Logger", .buffer_size = 2048, .mode = .NoBlockSkip },
    },
    .down_channels = &.{
        .{ .name = "TracyRecv", .buffer_size = 256, .mode = .BlockIfFull },
    },
    .linker_section = ".bss",
});

pub const tracy_send_size = 2048 * 4;
pub const tracy_send = rtt_instance.up_channel(0);
pub const tracy_recv = rtt_instance.down_channel(0);

const log_send = rtt_instance.up_channel(1);

pub fn init() void {
    rtt_instance.init();
    rtt_initialized();
    log_core0("\n\n======================== Rebooted ==========================\n\n");
}

pub fn log_core0(string: []const u8) void {
    const cs = microzig.interrupt.enter_critical_section();
    defer cs.leave();

    _ = log_send.write_if_available(string);
}

pub fn logf_core0(comptime fmt: []const u8, args: anytype) void {
    const cs = microzig.interrupt.enter_critical_section();
    defer cs.leave();

    var writer = log_send.writer(&.{});
    writer.interface.print(fmt, args) catch {};
    writer.interface.flush() catch {};
}

// Debugger can set a breakpoint here to pick up
// as soon as rtt is initialized.
noinline fn rtt_initialized() void {
    asm volatile ("");
}

