const std = @import("std");
const microzig = @import("microzig");
const assert = microzig.assert;
const EndianInt = microzig.core.mem.EndianInt;

const usb = @import("../usb.zig");
const log = std.log.scoped(.usb_cdc);

const endpoint = @import("endpoint.zig");

pub const Interface = enum {
    control,
    data,
};

pub const Descriptors = struct {
    const desc = microzig.core.usb.descriptor;

    itf_assoc: desc.InterfaceAssociation,
    itf_notifi: desc.Interface,
    cdc_header: desc.cdc.Header,
    cdc_call_mgmt: desc.cdc.CallManagement,
    cdc_acm: desc.cdc.AbstractControlModel,
    cdc_union: desc.cdc.Union,
    ep_notifi: desc.Endpoint,
    itf_data: desc.Interface,
    ep_out: desc.Endpoint,
    ep_in: desc.Endpoint,

    pub const Options = struct {
        itf_notifi: u8,
        itf_data: u8,
        function_name: u8,
        itf_notifi_name: u8,
        itf_data_name: u8,
        max_packet_size: u8,

        ep_notifi: microzig.core.usb.types.Endpoint,
        ep_bulk_out: microzig.core.usb.types.Endpoint,
        ep_bulk_in: microzig.core.usb.types.Endpoint,
    };

    pub fn init(opts: Options) Descriptors {
        return .{
            .itf_assoc = .{
                .first_interface = opts.itf_notifi,
                .interface_count = 2,
                .function_class = 2,
                .function_subclass = 2,
                .function_protocol = 0,
                .function = opts.function_name,
            },
            .itf_notifi = .{
                .interface_number = opts.itf_notifi,
                .alternate_setting = 0,
                .num_endpoints = 1,
                .interface_triple = .from(.CDC, .Abstract, .NoneRequired),
                .interface_s = opts.itf_notifi_name,
            },
            .cdc_header = .{
                .bcd_cdc = .from(1, 20),
            },
            .cdc_call_mgmt = .{
                .capabilities = .none,
                .data_interface = opts.itf_data,
            },
            .cdc_acm = .{
                .capabilities = .{
                    .comm_feature = false,
                    .send_break = false,
                    .line_coding = true,
                    .network_connection = false,
                },
            },
            .cdc_union = .{
                .master_interface = opts.itf_notifi,
                .slave_interface_0 = opts.itf_data,
            },
            // High-speed interrupt intervals are encoded as
            // 2^(bInterval - 1) microframes, while full-speed intervals
            // are expressed directly in milliseconds. Keep the intended
            // polling period at 16 ms for both speeds.
            .ep_notifi = .interrupt(opts.ep_notifi, 8, 8), // assert notifi is IN
            .itf_data = .{
                .interface_number = opts.itf_data,
                .alternate_setting = 0,
                .num_endpoints = 2,
                .interface_triple = .from(.CDC_Data, .Unused, .NoneRequired),
                .interface_s = opts.itf_data_name,
            },
            .ep_out = .bulk(opts.ep_bulk_out, opts.max_packet_size),
            .ep_in = .bulk(opts.ep_bulk_in, opts.max_packet_size),
        };
    }

    pub fn to_bytes(d: *const Descriptors) []const u8 {
        var ret: []const u8 = &.{};

        for (@typeInfo(Descriptors).@"struct".field_names) |field_name| {
            ret = ret ++ std.mem.asBytes(&@field(d, field_name));
        }

        return ret;
    }
};

pub const ClassRequest = enum(u8) {
    set_line_coding = 0x20,
    get_line_coding = 0x21,
    set_control_line_state = 0x22,
    _,
};

pub const ControlLineState = packed struct(u16) {
    dte_present: bool,
    carrier: bool,
    _reserved: u14,
};

pub const LineCoding = extern struct {
    dte_rate: EndianInt(u32, .little) align(1),
    char_format: CharFormat,
    parity_type: ParityType,
    data_bits: u8,

    pub const CharFormat = enum(u8) {
        @"1 stop bit" = 0,
        @"1.5 stop bits" = 1,
        @"2 stop bits" = 2,
        _,
    };

    pub const ParityType = enum(u8) {
        none = 0,
        odd = 1,
        even = 2,
        mark = 3,
        space = 4,
        _,
    };
};

comptime {
    assert(@sizeOf(LineCoding) == 7, .{});
}

pub const DriverOptions = struct {
    max_packet_size: u8,
    callbacks: struct {
        queue_receive: *const fn (pid: endpoint.PacketIdentifier) void,
        get_buffer: *const fn (dir: microzig.core.usb.types.Dir) []const u8,
    },
};

pub fn Driver(comptime SetupProcessor: type, comptime opts: DriverOptions) type {
    return struct {
        line_coding: LineCoding = .{
            .dte_rate = .from(9600),
            .char_format = .@"1 stop bit",
            .parity_type = .none,
            .data_bits = 8,
        },
        ready: struct {
            in: bool,
            out: bool,
        },
        bufs: struct {
            in: [512]u8,
            out: [512]u8,
        },
        pids: struct {
            in: endpoint.PacketIdentifier,
            out: endpoint.PacketIdentifier,
        },

        const SetupState = union(enum) {
            none,
            waiting_for_line_coding: usize,
        };

        pub fn init(d: *@This()) void {
            d.* = .{
                .ready = .{
                    .in = true,
                    .out = false,
                },
                .bufs = undefined,
                .pids = .{
                    .in = .DATA1,
                    .out = .DATA1,
                },
            };
        }

        pub fn in_ready(self: *@This()) void {
            log.info("IN READY", .{});
            self.ready.in = true;
        }

        pub fn out_ready(self: *@This()) void {
            log.info("OUT READY", .{});
            self.ready.out = true;

            _ = opts.callbacks.get_buffer(.out);

            // just keep them coming
            self.pids.out.toggle();
            opts.callbacks.queue_receive(self.pids.out);
        }

        pub fn poll(d: *@This()) void {
            _ = d;
        }

        pub fn setup_handler(
            setup_processor: *SetupProcessor,
            ctx: ?*anyopaque,
            pkt: *const microzig.core.usb.types.SetupPacket,
            payload: ?[]const u8,
        ) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            log.info("got setup packet: {f}", .{pkt});
            const dir = pkt.request_type.direction;
            const class_request: ClassRequest = @fromBackingInt(pkt.request);
            switch (class_request) {
                .set_line_coding => {
                    const p = payload orelse {
                        setup_processor.stall(dir);
                        return;
                    };

                    if (p.len < @sizeOf(LineCoding)) {
                        setup_processor.stall(dir);
                        return;
                    }

                    const lc: *const LineCoding = @ptrCast(p.ptr);
                    log.info("SET LINE CODING", .{});
                    self.line_coding = lc.*;

                    setup_processor.queue_in_xfer("", pkt.length.native());
                },
                .get_line_coding => {
                    setup_processor.queue_in_xfer(std.mem.asBytes(&self.line_coding), pkt.length.native());
                },
                .set_control_line_state => {
                    const cls: ControlLineState = @fromBackingInt(pkt.value.native());
                    _ = cls;

                    setup_processor.queue_in_xfer("", pkt.length.native());
                },
                _ => {
                    log.err("Unhandled setup packet request: 0x{X}", .{pkt.request});
                    setup_processor.stall(dir);
                },
            }
        }
    };
}
