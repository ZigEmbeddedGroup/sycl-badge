const microzig = @import("microzig");
const assert = microzig.assert;
const descriptor = microzig.core.usb.descriptor;
const types = microzig.core.usb.types;

const usb = @import("../usb.zig");
const timer = @import("../timer.zig");

const std = @import("std");

pub const PID = enum(u1) {
    data0 = 0,
    data1 = 1,
};

pub const Config = struct {
    max_packet_size: usize,
    max_transfer_size: usize,
    callbacks: Callbacks,

    pub const Callbacks = struct {
        queue_packet: *const fn (data: []const u8, pid: PID) void,
        queue_receive: *const fn () void,
        set_address: *const fn (address: u7) void,
        // This is for the out buffer
        get_buffer: *const fn () []const u8,
    };
};

/// Portable state machine for handling setup requests
pub fn RequestPacketProcessor(comptime config: Config) type {
    return struct {
        desc: Descriptors,
        ready: struct {
            in: bool,
            out: bool,
        },
        sm: union(enum) {
            awaiting_request,
            pending_address: u7,
            receiving_data: OutTransfer,
            sending_data: InTransfer,
        },
        handlers: Handlers,

        const log = std.log.scoped(.usb_setup);
        const InTransfer = InTransferProcessor(.{
            .max_packet_size = config.max_packet_size,
            .callbacks = .{
                .queue_packet = config.callbacks.queue_packet,
            },
        });

        const OutTransfer = OutTransferProcessor(.{
            .max_packet_size = config.max_packet_size,
            .max_transfer_size = config.max_transfer_size,
            .callbacks = .{
                .get_buffer = config.callbacks.get_buffer,
            },
        });

        const out_callbacks: OutTransfer.Callbacks = .{};

        pub const Handlers = struct {
            endpoint: []const EndpointHandler = &.{},
            interface: []const InterfaceHandler = &.{},
        };

        pub const SetupPacketHandler = fn (self: *@This(), ctx: ?*anyopaque, pkt: *const types.SetupPacket) void;

        pub const InterfaceHandler = struct {
            num: u8,
            ctx: ?*anyopaque,
            handler: *const SetupPacketHandler,
        };

        pub const EndpointHandler = struct {
            ep: types.Endpoint,
            ctx: ?*anyopaque,
            handler: *const SetupPacketHandler,
        };

        pub const Options = struct {
            descriptors: Descriptors,
            handlers: Handlers,
        };

        pub fn init(opts: Options) @This() {
            return .{
                .desc = opts.descriptors,
                .handlers = opts.handlers,
                .sm = .awaiting_request,
                .ready = .{
                    .in = true,
                    .out = true,
                },
            };
        }

        fn submit_setup_request_standard(self: *@This(), pkt: *const types.SetupPacket) void {
            assert(pkt.request_type.type == .standard, .{});
            switch (pkt.to_standard_request().*) {
                .set_address => {
                    const addr: u7 = @intCast(pkt.value.native());
                    queue_zlp(.data1);
                    self.sm = .{ .pending_address = addr };
                },
                .get_descriptor => {
                    log.debug("GET_DESCRIPTOR: value={} index={} length={}", .{ pkt.value.native(), pkt.index.native(), pkt.length.native() });
                    const desc_type: descriptor.Type = @fromBackingInt(@truncate(pkt.value.native() >> 8));
                    const desc_idx: u8 = @truncate(pkt.value.native());
                    const lang: Language = @fromBackingInt(pkt.index.native());
                    log.debug("type: {}", .{desc_type});
                    const payload: []const u8 = switch (desc_type) {
                        .device => std.mem.asBytes(self.desc.device),
                        .string => blk: {
                            const desc = self.desc.string.lookup(lang, desc_idx) orelse break :blk "";
                            assert(desc.valid(), .{});
                            log.debug("str='{f}'", .{desc});
                            break :blk desc.payload;
                        },
                        .configuration => self.desc.configurations[desc_idx],
                        else => @panic("unhandled desc type"),
                    };

                    // TODO: break value into descriptor type and index
                    self.queue_in_xfer(payload, pkt.length.native());
                },
                .set_configuration => {
                    self.queue_in_xfer("", pkt.length.native());

                    // TODO: keep the configuration data around so we can
                    // see what values we have.
                    if (pkt.value.native() != 1) {
                        @panic("TODO: handle incorrect configuration value");
                    }
                },
                .clear_feature_device => {
                    const feature_selector = pkt.value.native();
                    const zero_interface_endpoint = pkt.index.native();
                    log.info("CLEAR_FEATURE DEVICE feature_selector={} zero_interface_endpoint={}", .{
                        feature_selector,
                        zero_interface_endpoint,
                    });
                    @panic("TODO");
                },
                .clear_feature_interface => {
                    const feature_selector = pkt.value.native();
                    const zero_interface_endpoint = pkt.index.native();
                    log.info("CLEAR_FEATURE INTERFACE feature_selector={} zero_interface_endpoint={}", .{
                        feature_selector,
                        zero_interface_endpoint,
                    });
                    @panic("TODO");
                },
                .clear_feature_endpoint => {
                    const feature_selector = pkt.value.native();
                    const zero_interface_endpoint = pkt.index.native();
                    log.info("CLEAR_FEATURE ENDPOINT feature_selector={} zero_interface_endpoint={}", .{
                        feature_selector,
                        zero_interface_endpoint,
                    });

                    // TODO: handle this
                    self.queue_in_xfer("", pkt.length.native());
                },
                .get_status_device => {
                    const zero_interface_endpoint = pkt.index.native();
                    const length_two = pkt.length.native();
                    log.info("GET_STATUS DEVICE zero_interface_endpoint={} length_two={}", .{
                        zero_interface_endpoint,
                        length_two,
                    });
                    @panic("TODO");
                },
                .get_status_interface => {
                    const zero_interface_endpoint = pkt.index.native();
                    const length_two = pkt.length.native();
                    log.info("GET_STATUS INTERFACE zero_interface_endpoint={} length_two={}", .{
                        zero_interface_endpoint,
                        length_two,
                    });

                    @panic("TODO");
                },
                .get_status_endpoint => {
                    const zero_interface_endpoint = pkt.index.native();
                    const length_two = pkt.length.native();
                    log.info("GET_STATUS ENDPOINT zero_interface_endpoint={} length_two={}", .{
                        zero_interface_endpoint,
                        length_two,
                    });

                    // TODO: handle this correctly

                    self.queue_in_xfer(std.mem.asBytes(&endpoint_status_resp), pkt.length.native());
                },
                // set_configuration
                // set_descriptor
                // If it's marked as a standard request, but doesn't match
                // the above, then it is not good.
                else => |value| {
                    log.info("unhandled standard setup request packet: {}", .{value});
                    timer.sleep_ms(100);
                    @panic("unhandled");
                },
            }
        }

        const EndpointStatusResponse = packed struct(u16) {
            /// The halt feature is required to be implemented for
            /// all interrupt and bulk endpoint types
            halt: u1,
            _reserved: u15 = 0,
        };

        const endpoint_status_resp: EndpointStatusResponse = .{ .halt = 0 };

        fn submit_setup_request_class(self: *@This(), pkt: *const types.SetupPacket) void {
            assert(pkt.request_type.type == .class, .{});
            log.info("got class SETUP REQUEST: {f}", .{pkt});
            switch (pkt.request_type.recipient) {
                .interface => {
                    const num = pkt.index.native();
                    for (self.handlers.interface) |entry| {
                        if (entry.num == num) {
                            entry.handler(self, entry.ctx, pkt);
                            return;
                        }
                    }
                },
                .endpoint => {
                    const ep: types.Endpoint = @bitCast(@as(u8, @truncate(pkt.index.native() >> 8)));
                    for (self.handlers.endpoint) |entry| {
                        if (entry.ep == ep) {
                            entry.handler(self, entry.ctx, pkt);
                            return;
                        }
                    }
                },
                else => {},
            }
            log.warn("Unahndled setup request", .{});
        }

        pub fn submit_setup_request(self: *@This(), pkt: types.SetupPacket) void {
            // Setting this to one because the example docs do it here
            switch (pkt.request_type.type) {
                .standard => self.submit_setup_request_standard(&pkt),
                .class => self.submit_setup_request_class(&pkt),
                else => @panic("TODO"),
            }
        }

        pub fn queue_in_xfer(self: *@This(), data: []const u8, host_len: usize) void {
            self.sm = .{
                .sending_data = .start(data, host_len),
            };
        }

        pub fn ep0_in_ready(self: *@This()) void {
            self.ready.in = true;
            switch (self.sm) {
                .pending_address => |addr| {
                    config.callbacks.set_address(addr);
                    self.sm = .awaiting_request;
                },
                else => {},
            }
        }

        pub fn ep0_out_ready(self: *@This()) void {
            self.ready.out = true;
            switch (self.sm) {
                else => {},
            }
        }

        pub fn poll(self: *@This()) void {
            switch (self.sm) {
                .awaiting_request, .pending_address => {},
                .sending_data => |*xfer| if (self.ready.in) {
                    defer self.ready.in = false;

                    xfer.ep_ready();
                    if (xfer.state == .done) {
                        self.sm = .awaiting_request;
                        config.callbacks.queue_receive();
                    }
                },
                .receiving_data => |*xfer| if (self.ready.out) {
                    defer self.ready.out = false;

                    xfer.ep_ready();
                    if (xfer.state == .done) {
                        self.sm = .awaiting_request;
                        config.callbacks.queue_receive();
                    }
                },
            }
        }

        fn queue_zlp(pid: PID) void {
            config.callbacks.queue_packet(&.{}, pid);
        }
    };
}

pub const InTransferConfig = struct {
    max_packet_size: usize,
    callbacks: Callbacks,

    pub const Callbacks = struct {
        queue_packet: *const fn (data: []const u8, pid: PID) void,
    };
};

pub fn InTransferProcessor(comptime config: InTransferConfig) type {
    return struct {
        data: []const u8,
        host_len: usize,
        progress: usize,
        pid: PID = .data1,
        state: enum {
            send_data,
            send_zlp,
            done,
        },

        const log = std.log.scoped(.in_xfer);

        /// data is the payload you want to send, host_len is the length the
        /// host sent, this concept exists in different protocols. wLength for
        /// control transfers.
        pub fn start(data: []const u8, host_len: usize) @This() {
            log.debug("start: data={X} host_len={}", .{ data, host_len });
            return .{
                .data = data,
                .host_len = host_len,
                .progress = 0,
                .state = .send_data,
            };
        }

        pub fn ep_ready(self: *@This()) void {
            state: switch (self.state) {
                .done => {},
                .send_zlp => {
                    self.state = .done;
                    // TODO: not sure about the pid
                    self.queue_packet(&.{});
                },
                .send_data => {
                    const limit = @min(self.data.len, self.host_len);
                    const pkt_len = @min(config.max_packet_size, limit - self.progress);
                    if (pkt_len < config.max_packet_size) {
                        // Termination
                        if (pkt_len == 0) {
                            self.state = .send_zlp;
                            continue :state .send_zlp;
                        }
                    }

                    const begin = self.progress;
                    const end = self.progress + pkt_len;
                    self.queue_packet(self.data[begin..end]);
                    self.progress += pkt_len;

                    if (self.progress == limit) {
                        self.state = .done;
                    }
                },
            }
        }

        fn queue_packet(self: *@This(), data: []const u8) void {
            config.callbacks.queue_packet(data, self.pid);
            self.pid = @fromBackingInt(@backingInt(self.pid) ^ 1);
        }
    };
}

test InTransferProcessor {
    const Transfer = InTransferProcessor(.{ .max_packet_size = 64 });
    var pkt_buf: [64]u8 = @splat(0xBB);

    // Transfer more than what the host requested. n < max_packet_size
    var transfer: Transfer = try .start("arstarst", 5);
    var n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(5, n);
    try testing.expectEqual(5, transfer.host_len);
    try testing.expectEqual(5, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer more than what the host requested. n == max_packet_size
    transfer = try .start(&@as([65]u8, @splat(0xBB)), 64);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(64, n);
    try testing.expectEqual(64, transfer.host_len);
    try testing.expectEqual(64, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer more than what the host requested. n > max_packet_size
    transfer = try .start(&@as([96]u8, @splat(0xBB)), 64);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(64, n);
    try testing.expectEqual(64, transfer.host_len);
    try testing.expectEqual(64, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer exactly what the host requested. n < max_packet_size
    transfer = try .start("arstarst", 8);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(8, n);
    try testing.expectEqual(8, transfer.host_len);
    try testing.expectEqual(8, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer exactly what the host requested. n == max_packet_size
    transfer = try .start(&@as([64]u8, @splat(0xBB)), 64);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(64, n);
    try testing.expectEqual(64, transfer.host_len);
    try testing.expectEqual(64, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer exactly what the host requested. n > max_packet_size
    transfer = try .start(&@as([96]u8, @splat(0xBB)), 96);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(64, n);
    try testing.expectEqual(96, transfer.host_len);
    try testing.expectEqual(64, transfer.progress);
    try testing.expectEqual(.send_data, transfer.state);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(32, n);
    try testing.expectEqual(96, transfer.host_len);
    try testing.expectEqual(96, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer less than what the host requested. n < max_packet_size
    transfer = try .start("arstarst", 16);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(8, n);
    try testing.expectEqual(16, transfer.host_len);
    try testing.expectEqual(8, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer less than what the host requested. n == max_packet_size
    transfer = try .start(&@as([63]u8, @splat(0xBB)), 64);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(63, n);
    try testing.expectEqual(64, transfer.host_len);
    try testing.expectEqual(63, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // Transfer less than what the host requested. n > max_packet_size
    transfer = try .start(&@as([70]u8, @splat(0xBB)), 96);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(64, n);
    try testing.expectEqual(96, transfer.host_len);
    try testing.expectEqual(64, transfer.progress);
    try testing.expectEqual(.send_data, transfer.state);
    n = transfer.process(&pkt_buf).?;
    try testing.expectEqual(6, n);
    try testing.expectEqual(96, transfer.host_len);
    try testing.expectEqual(70, transfer.progress);
    try testing.expectEqual(.done, transfer.state);
}

pub const OutTransferConfig = struct {
    max_packet_size: usize,
    max_transfer_size: usize,
    callbacks: struct {
        get_buffer: *const fn () []const u8,
    },
};

pub fn OutTransferProcessor(comptime config: OutTransferConfig) type {
    return struct {
        buf: [config.max_transfer_size]u8,
        host_len: usize,
        progress: usize,
        state: enum {
            receiving_data,
            err,
            done,
        },

        const log = std.log.scoped(.out_xfer);

        pub fn start(host_len: usize) !@This() {
            if (host_len == 0) {
                return error.ProtocolViolation;
            }

            return .{
                .buf = undefined,
                .host_len = host_len,
                .progress = 0,
                .state = .receiving_data,
            };
        }

        pub fn ep_ready(self: *@This()) void {
            self.ep_ready_inner() catch {
                self.state = .err;
            };
        }

        pub fn get_payload(self: @This()) []const u8 {
            assert(self.state == .done);
            return self.buf[0..self.progress];
        }

        fn ep_ready_inner(self: *@This()) !void {
            const pkt = config.callbacks.get_buffer();
            return state: switch (self.state) {
                .done => {},
                .err => error.ProtocolViolation,
                .receiving_data => {
                    if (pkt.len > config.max_packet_size)
                        return error.ProtocolViolation;

                    if (self.host_len % config.max_packet_size == 0) {
                        // Termniated with a zlp
                        if (pkt.len == 0) {
                            if (self.progress == self.host_len) {
                                self.state = .done;
                                continue :state .done;
                            }

                            return error.ProtocolViolation;
                        }

                        if (pkt.len != config.max_packet_size) {
                            return error.ProtocolViolation;
                        }
                    } else {
                        // Terminated with a short packet
                        if (pkt.len < config.max_packet_size and (pkt.len + self.progress) != self.host_len)
                            return error.ProtocolViolation;

                        if (pkt.len == config.max_packet_size and (pkt.len + self.progress) > self.host_len)
                            return error.ProtocolViolation;
                    }

                    const begin = self.progress;
                    const end = self.progress + pkt.len;
                    if (end > self.host_len)
                        return error.ProtocolViolation;

                    @memcpy(self.buf[begin..end], pkt[0..pkt.len]);
                    self.progress += pkt.len;

                    if (self.progress == self.host_len and pkt.len < config.max_packet_size) {
                        self.state = .done;
                        continue :state .done;
                    }
                },
            };
        }
    };
}

const testing = std.testing;

test OutTransferProcessor {
    const Transfer = OutTransferProcessor(.{ .max_packet_size = 64, .max_transfer_size = 512 });
    var pkt_buf: [64]u8 = @splat(0xBB);

    // zero length packet at start
    var result = Transfer.start(0);
    try testing.expectError(error.ProtocolViolation, result);

    // zero length packet with nonzero host length
    var transfer = try Transfer.start(16);
    try testing.expectError(error.ProtocolViolation, transfer.process(&pkt_buf, 0));

    // nonzero length packet greater than the reported length
    result = Transfer.start(8);
    try testing.expectError(error.ProtocolViolation, transfer.process(&pkt_buf, 10));

    // nonzero length packet less than the reported length, and less than the
    // max packet size
    transfer = try Transfer.start(32);
    try testing.expectError(error.ProtocolViolation, transfer.process(&pkt_buf, 16));

    // nonzero length packet equal to the reported length
    transfer = try Transfer.start(16);
    try testing.expectEqualStrings(&@as([16]u8, @splat(0xBB)), (try transfer.process(&pkt_buf, 16)).?);
    try testing.expectEqual(16, transfer.host_len);
    try testing.expectEqual(16, transfer.progress);
    try testing.expectEqual(.done, transfer.state);

    // multi packet transfer, length is not multiple of max_packet_size
    transfer = try Transfer.start(96);
    try testing.expectEqual(null, try transfer.process(&pkt_buf, 64));
    try testing.expectEqualStrings(&@as([96]u8, @splat(0xBB)), (try transfer.process(&pkt_buf, 32)).?);
    try testing.expectEqual(96, transfer.host_len);
    try testing.expectEqual(96, transfer.progress);
    try testing.expectEqual(.done, transfer.state);
}

pub const Descriptors = struct {
    device: *const descriptor.Device,
    string: StringDescriptors,
    configurations: []const []const u8,
    //interfaces: []const descriptor.Interface,
    //endpoints: []const descriptor.Endpoint,

};

pub const Language = enum(u16) {
    english = 0x0409,
    _,
};

pub const StringDescriptors = struct {
    langs: []const Language,
    offsets: []const []const usize,
    data: []const u8,

    pub const Wrapper = struct {
        payload: []const u8,

        pub fn valid(w: *const Wrapper) bool {
            return w.payload.len >= 2 and
                w.payload.len % 2 == 0 and
                w.payload[1] == 0x03 and
                w.payload[0] == w.payload.len;
        }

        pub fn format(w: *const Wrapper, writer: *std.Io.Writer) !void {
            var buf: [256]u8 = undefined;

            const n = std.unicode.utf16LeToUtf8(&buf, @alignCast(std.mem.bytesAsSlice(u16, w.payload[2..]))) catch return error.WriteFailed;
            try writer.print("{s}", .{buf[0..n]});
        }
    };

    pub fn lookup(s: *const StringDescriptors, lang: Language, index: usize) ?Wrapper {
        const lang_idx = for (s.langs, 0..) |entry_lang, i| {
            if (entry_lang == lang)
                break i;
        } else return null;

        const offset = s.offsets[lang_idx][index];
        // First byte of the descriptor is the length;
        const len = s.data[offset];
        return .{ .payload = s.data[offset .. offset + len] };
    }
};

fn make_desc(str: []const u8) []const u8 {
    var buf: [2 + (2 * str.len)]u8 = undefined;

    buf[0] = @intCast(buf.len);
    buf[1] = 0x03;

    var utf16: [str.len]u16 = undefined;

    const n = std.unicode.utf8ToUtf16Le(&utf16, str) catch unreachable;
    assert(n == str.len, .{});

    @memcpy(buf[2..], std.mem.sliceAsBytes(&utf16));

    const ret = buf;
    return &ret;
}

fn make_languages_desc(langs: []const Language) []const u8 {
    var buf: [2 + (2 * langs.len)]u8 = undefined;

    buf[0] = @intCast(buf.len);
    buf[1] = 0x03;
    @memcpy(buf[2..], std.mem.sliceAsBytes(langs));

    const ret = buf;
    return &ret;
}

pub fn StringDescriptorBuilder(comptime lang_config: []const Language) type {
    const Attributes = std.builtin.Type.Struct.FieldAttributes;

    var field_names: [lang_config.len][]const u8 = undefined;
    for (lang_config, 0..) |lang, i| {
        _ = lang;
        field_names[i] = "";
    }

    const field_types: [lang_config.len]type = @splat([]const u8);
    const field_attrs: [lang_config.len]Attributes = @splat(Attributes{});
    // Has the benefit of making sure every language in the config is unique
    const Translations = @Struct(.auto, null, &field_names, field_types[0..], field_attrs[0..]);

    return struct {
        langs: []const Language,
        offsets: [lang_config.len][]const usize,
        data: []const u8,

        pub fn init() @This() {
            const offsets_init: [lang_config.len][]const usize = @splat(&.{0});
            var data_init: []const u8 = &.{};

            data_init = data_init ++ make_languages_desc(lang_config);
            return .{
                .langs = lang_config,
                .offsets = offsets_init,
                .data = data_init,
            };
        }

        pub fn add(comptime self: *@This(), comptime translations: Translations) usize {
            const ret_idx = self.offsets[0].len;
            inline for (@typeInfo(Translations).@"struct".fields, 0..) |field, i| {
                self.offsets[i] = self.offsets[i] ++ self.data.len;
                self.data = self.data ++ make_desc(@field(translations, field.name));
            }

            return ret_idx;
        }

        pub fn add_single(self: *@This(), comptime str: []const u8) usize {
            const ret_idx = self.offsets[0].len;
            inline for (@typeInfo(Translations).@"struct".field_names, 0..) |_, i| {
                self.offsets[i] = self.offsets[i] ++ .{self.data.len};
            }

            self.data = self.data ++ make_desc(str);
            return ret_idx;
        }

        pub fn to_descriptor(self: *const @This()) StringDescriptors {
            const ret: StringDescriptors = .{
                .langs = self.langs,
                .offsets = &self.offsets,
                .data = self.data,
            };

            // No more mutating this once you've converted it to a descriptor
            return ret;
        }

        /// Use this function in the comptime block to make the const copy, it
        /// has the benefit of making itself undefined, which will cause compile
        /// errors if you mutate it after this point.
        pub fn finish(self: *@This()) @This() {
            defer self.* = undefined;
            return self.*;
        }
    };
}
