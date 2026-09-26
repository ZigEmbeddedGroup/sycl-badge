//! USB CDC ACM class driver: the virtual serial port that carries the kernel console
const std = @import("std");
const microzig = @import("microzig");
const types = microzig.core.usb.types;

const endpoint = @import("endpoint.zig");
const PacketIdentifier = endpoint.PacketIdentifier;

const log = std.log.scoped(.cdc);

/// Class requests sent to the communications interface
pub const Request = enum(u8) {
    set_line_coding = 0x20,
    get_line_coding = 0x21,
    set_control_line_state = 0x22,
    _,
};

/// Bit rate, stop bits, parity and data bits. A virtual port ignores the
/// values, but the host expects them to round trip.
pub const LineCoding = [7]u8;
const default_line_coding: LineCoding = .{ 0x00, 0xC2, 0x01, 0x00, 0, 0, 8 }; // 115200 8N1

pub const Callbacks = struct {
    queue_packet: *const fn (data: []const u8, pid: PacketIdentifier) void,
    queue_receive: *const fn (pid: PacketIdentifier) void,
    get_buffer: *const fn () []const u8,
    disarm_endpoints: *const fn () void,
};

pub const Config = struct {
    max_packet_size: u8,
    callbacks: Callbacks,
};

/// Fixed capacity byte FIFO
pub fn Ring(comptime capacity: usize) type {
    return struct {
        buf: [capacity]u8 = undefined,
        head: usize = 0,
        len: usize = 0,

        pub fn free(self: *const @This()) usize {
            return capacity - self.len;
        }

        /// Copies as much of `data` as fits, returns how many bytes were copied
        pub fn push(self: *@This(), data: []const u8) usize {
            const n = @min(data.len, self.free());
            for (data[0..n]) |byte| {
                self.buf[(self.head + self.len) % capacity] = byte;
                self.len += 1;
            }
            return n;
        }

        /// Moves up to `out.len` bytes into `out`, returns how many bytes were moved
        pub fn pop(self: *@This(), out: []u8) usize {
            const n = @min(out.len, self.len);
            for (out[0..n]) |*byte| {
                byte.* = self.buf[self.head];
                self.head = (self.head + 1) % capacity;
                self.len -= 1;
            }
            return n;
        }
    };
}

pub fn CDC_Driver(comptime SetupProcessor: type, comptime config: Config) type {
    return struct {
        line_coding: LineCoding,
        /// Data Terminal Ready: the host has the port open
        dtr: bool,
        tx: Ring(1024),
        rx: Ring(256),
        in_pid: PacketIdentifier,
        out_pid: PacketIdentifier,
        /// No packet waits in the IN endpoint buffer
        in_idle: bool,
        /// The last IN packet was full, so a zero length packet must end the transfer
        in_needs_zlp: bool,
        /// The OUT endpoint is armed for a packet
        out_armed: bool,

        pub fn init(self: *@This()) void {
            self.* = .{
                .line_coding = default_line_coding,
                .dtr = false,
                .tx = .{},
                .rx = .{},
                .in_pid = .DATA0,
                .out_pid = .DATA0,
                .in_idle = true,
                .in_needs_zlp = false,
                .out_armed = false,
            };
        }

        /// Call once the endpoints are configured, and on every bus reset
        pub fn reset(self: *@This()) void {
            config.callbacks.disarm_endpoints();
            self.init();
            self.poll();
        }

        pub fn connected(self: *const @This()) bool {
            return self.dtr;
        }

        /// Queues bytes for the host, returns how many bytes fit
        pub fn write(self: *@This(), data: []const u8) usize {
            return self.tx.push(data);
        }

        /// Takes bytes received from the host, returns how many bytes were copied
        pub fn read(self: *@This(), out: []u8) usize {
            return self.rx.pop(out);
        }

        pub fn in_ready(self: *@This()) void {
            self.in_idle = true;
        }

        pub fn out_ready(self: *@This()) void {
            // The endpoint is only armed while the ring has room for a full packet
            _ = self.rx.push(config.callbacks.get_buffer());
            self.out_pid.toggle();
            self.out_armed = false;
        }

        pub fn poll(self: *@This()) void {
            if (!self.out_armed and self.rx.free() >= config.max_packet_size) {
                config.callbacks.queue_receive(self.out_pid);
                self.out_armed = true;
            }

            // Only send while a terminal reads, otherwise the packet would sit
            // in the endpoint buffer and block later output
            if (!self.in_idle or !self.dtr) return;

            var pkt: [config.max_packet_size]u8 = undefined;
            const n = self.tx.pop(&pkt);
            if (n == 0 and !self.in_needs_zlp) return;

            config.callbacks.queue_packet(pkt[0..n], self.in_pid);
            self.in_pid.toggle();
            self.in_idle = false;
            self.in_needs_zlp = n == config.max_packet_size;
        }

        pub fn setup_handler(setup_processor: *SetupProcessor, ctx: ?*anyopaque, pkt: *const types.SetupPacket) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            const request: Request = @fromBackingInt(pkt.request);
            switch (request) {
                .set_line_coding => setup_processor.queue_out_xfer(pkt.length.native(), .{
                    .ctx = self,
                    .handler = set_line_coding,
                }),
                .get_line_coding => setup_processor.queue_in_xfer(&self.line_coding, pkt.length.native()),
                .set_control_line_state => {
                    self.dtr = (pkt.value.native() & 0x01) != 0;
                    log.info("SET_CONTROL_LINE_STATE dtr={}", .{self.dtr});
                    // The host closed the port, drop output it will never read
                    if (!self.dtr) self.tx = .{};
                    setup_processor.queue_in_xfer("", 0);
                },
                _ => {
                    log.warn("unsupported CDC request 0x{X}", .{pkt.request});
                    setup_processor.stall_ep0();
                },
            }
        }

        fn set_line_coding(ctx: ?*anyopaque, payload: []const u8) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            if (payload.len >= self.line_coding.len)
                @memcpy(&self.line_coding, payload[0..self.line_coding.len]);
        }
    };
}

test Ring {
    var ring: Ring(4) = .{};
    var out: [4]u8 = undefined;

    try std.testing.expectEqual(0, ring.pop(&out));
    try std.testing.expectEqual(3, ring.push("abc"));
    // Only one byte of room is left
    try std.testing.expectEqual(1, ring.push("de"));
    try std.testing.expectEqual(0, ring.free());

    try std.testing.expectEqual(2, ring.pop(out[0..2]));
    try std.testing.expectEqualStrings("ab", out[0..2]);

    // Wraps around the end of the buffer
    try std.testing.expectEqual(2, ring.push("fg"));
    try std.testing.expectEqual(4, ring.pop(&out));
    try std.testing.expectEqualStrings("cdfg", &out);
}
