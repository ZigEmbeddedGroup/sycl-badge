//! MSC USB Driver for the badge
//!
//! Later we'll work on making it hardware agnostic.

const microzig = @import("microzig");
const usb = microzig.core.usb;

const std = @import("std");
const log = std.log.scoped(.usb_msc);

const MSC = @This();

pub const Descriptor = extern struct {
    const desc = usb.descriptor;

    itf: desc.Interface,
    ep_out: desc.Endpoint,
    ep_in: desc.Endpoint,

    pub fn create(
        alloc: *usb.DescriptorAllocator,
        max_supported_packet_size: usb.types.Len,
        itf_string: []const u8,
    ) usb.DescriptorCreateResult(Descriptor) {
        return .{
            .descriptor = .{
                .itf = .{
                    .interface_number = alloc.next_itf(),
                    .alternate_setting = 0,
                    .num_endpoints = 2,
                    .interface_triple = .from(.MassStorage, .SCSI, .BulkOnly),
                    .interface_s = alloc.string(itf_string),
                },
                .ep_out = .bulk(alloc.next_ep(.Out), max_supported_packet_size),
                .ep_in = .bulk(alloc.next_ep(.In), max_supported_packet_size),
            },
            // Buffers whose length is only known after creating the
            // descriptor can be allocated at this stage.
            .alloc_bytes = max_supported_packet_size,
        };
    }
};

pub fn init(self: *MSC, desc: *const Descriptor, device: *usb.DeviceInterface, data: []u8) void {
    _ = self;
    std.debug.assert(data.len == desc.ep_in.max_packet_size.into());
    //self.* = .{
    //    .device = device,
    //    .descriptor = desc,
    //    .packet_buffer = data,
    //    .tx_ready = .init(false),
    //};
    // TODO: what does this give me?
    device.ep_listen(
        desc.ep_out.endpoint.num,
        @intCast(desc.ep_out.max_packet_size.into()),
    );
}

pub const handlers: usb.DriverHandlers(MSC) = .{
    .ep_in = on_tx_ready,
    .ep_out = on_rx,
};

pub fn on_tx_ready(self: *MSC, ep_tx: usb.types.Endpoint.Num) void {
    _ = self;
    _ = ep_tx;
}

pub fn on_rx(self: *MSC, ep_rx: usb.types.Endpoint.Num) void {
    _ = self;
    _ = ep_rx;
}

pub fn class_request(self: *@This(), setup: *const usb.types.SetupPacket) ?[]const u8 {
    _ = self;
    log.debug("setup: {x}, {}, {}", .{ setup.request, setup.length.into(), setup.value.into() });
    return usb.ack;
}
