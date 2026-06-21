const microzig = @import("microzig");
const assert = microzig.assert;

const std = @import("std");

pub const PacketIdentifier = enum(u1) {
    /// Even packet in a data transfer
    DATA0 = 0,
    /// Odd packet in a data transfer
    DATA1 = 1,

    pub fn toggle(pid: *PacketIdentifier) void {
        pid.* = @fromBackingInt(@as(u1, @backingInt(pid.*)) ^ 1);
    }
};

// TODO: For a transfer, I need to keep track of the transfer_len. ZLP does not
// need to be sent if exactly the transfer_len has been sent.
pub const In = struct {
    num: u4,
    pid: PacketIdentifier = .DATA0,
    max_packet_size: u16,
    transfer: Transfer = .{
        .state = .done,
        .len = undefined,
        .data = undefined,
        .progress = undefined,
    },

    const log = std.log.scoped(.ep_in);

    pub const QueueCommand = struct {
        payload: []const u8,
        pid: PacketIdentifier,
    };

    /// The output of this state machine, you BETTER follow them.
    pub const Command = union(enum) {
        queue: QueueCommand,
        stall,
        nak,
        done,
    };

    pub const Transfer = struct {
        data: []const u8,
        progress: usize,
        len: usize,
        state: State,

        const State = enum {
            sending,
            done,
        };

        /// The creation function for an IN transfer. Transfers are one-shot items,
        /// so you need to regulary reset/recreate this object.
        ///
        /// It is the caller's responsibility to manage the lifetime of `payload`.
        pub fn start(data: []const u8, transfer_len: u32) Transfer {
            //assert(max_payload_size > 0);
            //assert(max_payload_size <= 1024);
            log.debug("start: data.len={}", .{data.len});

            return .{
                .state = .sending,
                .len = transfer_len,
                .progress = 0,
                .data = data,
            };
        }
    };

    pub fn reset(self: *In) void {
        self.transfer.state = .done;
        self.pid = .DATA0;
    }

    /// The transition event. It needs to be called when another packet can be
    /// sent.
    pub fn ready(self: *In) Command {
        return switch (self.transfer.state) {
            .sending => blk: {
                const packet_size = @min(self.max_packet_size, self.transfer.data.len - self.transfer.progress);
                defer self.transfer.state = if (packet_size < self.max_packet_size or self.transfer.progress == self.transfer.len) .done else .sending;
                log.debug("queue: size={}", .{packet_size});
                break :blk .{ .queue = self.queue_packet(packet_size) };
            },
            .done => .done,
        };
    }

    fn queue_packet(self: *In, size: usize) QueueCommand {
        //assert(self.size <= self.max_packet_size);
        const begin = self.transfer.progress;
        const end = self.transfer.progress + size;
        defer {
            self.transfer.progress = end;
            self.pid.toggle();
        }

        return .{
            .pid = self.pid,
            .payload = self.transfer.data[begin..end],
        };
    }
};

pub const Out = struct {
    num: u4,
    /// This state machine assumes that the hardware is initialized before it to
    /// accept DATA0, so this is initialized to DATA1.
    pid: PacketIdentifier = .DATA0,
    max_packet_size: u16,
    progress: usize = 0,
    /// Pass in a reusable buf. This will determine the maximum size for
    /// transfers.
    buf: []u8,

    const log = std.log.scoped(.ep_out);

    const Command = union(enum) {
        done: struct {
            next_pid: PacketIdentifier,
            payload: []u8,
        },
        // Returns the next expected packet identifier
        none: PacketIdentifier,
        stall,
    };

    pub fn reset(out: *Out) void {
        out.pid = .DATA0;
        out.progress = 0;
    }

    pub fn receive(self: *Out, packet: []const u8) Command {
        assert(packet.len <= self.max_packet_size, .{});
        self.pid.toggle();
        if (self.progress + packet.len > self.buf.len) {
            log.err("going to stall: progress={} packet.len={} self.buf.len={}", .{ self.progress, packet.len, self.buf.len });
            self.progress = 0;
            // TODO: Probably need to reset this? Check the spec to confirm
            self.pid = .DATA0;
            return .stall;
        }

        @memcpy(self.buf[self.progress .. self.progress + packet.len], packet);
        self.progress += packet.len;

        if (packet.len == self.max_packet_size)
            return .{ .none = self.pid };

        defer self.progress = 0;
        return .{
            .done = .{
                .next_pid = self.pid,
                .payload = self.buf[0..self.progress],
            },
        };
    }
};

const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "IN: empty data" {
    var xfer: In = .start(64, &.{});

    const cmd = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd.queue.pid);
    try expectEqual(0, cmd.queue.payload.len);

    try expectEqual(.done, xfer.endpoint_ready());
}

test "IN: short packet" {
    const data = "arst";
    var xfer: In = .start(64, data);

    const cmd = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd.queue.pid);
    try expectEqualStrings(data, cmd.queue.payload);

    try expectEqual(.done, xfer.endpoint_ready());
}

test "IN: exactly max packet size" {
    const max_packet_size = 64;
    const data = std.mem.zeroes([max_packet_size]u8);
    var xfer: In = .start(max_packet_size, &data);

    const cmd1 = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd1.queue.pid);
    try expectEqualStrings(&data, cmd1.queue.payload);

    const cmd2 = xfer.endpoint_ready();
    try expectEqual(.DATA1, cmd2.queue.pid);
    try expectEqual(0, cmd2.queue.payload.len);

    try expectEqual(.done, xfer.endpoint_ready());
}

test "IN: just above max_packet size" {
    const max_packet_size = 64;
    const data = std.mem.zeroes([max_packet_size + 1]u8);
    var xfer: In = .start(max_packet_size, &data);

    const cmd1 = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd1.queue.pid);
    try expectEqualStrings(data[0..max_packet_size], cmd1.queue.payload);

    const cmd2 = xfer.endpoint_ready();
    try expectEqual(.DATA1, cmd2.queue.pid);
    try expectEqualStrings(data[max_packet_size..], cmd2.queue.payload);

    try expectEqual(.done, xfer.endpoint_ready());
}

test "IN: two max packets" {
    const max_packet_size = 64;
    const data = std.mem.zeroes([max_packet_size * 2]u8);
    var xfer: In = .start(max_packet_size, &data);

    const cmd1 = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd1.queue.pid);
    try expectEqualStrings(data[0..max_packet_size], cmd1.queue.payload);

    const cmd2 = xfer.endpoint_ready();
    try expectEqual(.DATA1, cmd2.queue.pid);
    try expectEqualStrings(data[max_packet_size..], cmd2.queue.payload);

    const cmd3 = xfer.endpoint_ready();
    try expectEqual(.DATA0, cmd3.queue.pid);
    try expectEqual(0, cmd3.queue.payload.len);

    try expectEqual(.done, xfer.endpoint_ready());
}
