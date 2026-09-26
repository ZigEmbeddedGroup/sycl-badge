//! USB device driver
//!
//! The badge is a composite device: mass storage on interface 0 (EP1) for the
//! cart drive, and a CDC ACM serial port on interfaces 1 and 2 (EP2 data, EP3
//! notifications) for the kernel console.
const std = @import("std");
const microzig = @import("microzig");
const assert = microzig.assert;
const rp2xxx = microzig.hal;
const core = microzig.core;
const descriptor = core.usb.descriptor;
const types = core.usb.types;
const Endpoint = types.Endpoint;
const USB = microzig.chip.peripherals.USB;
const USB_DPRAM = microzig.chip.peripherals.USB_DPRAM;
const SIO = microzig.chip.peripherals.SIO;
const EndpointType = microzig.chip.types.peripherals.USB_DPRAM.EndpointType;
const BufferControl = @FieldType(microzig.chip.types.peripherals.USB_DPRAM, "EP0_IN_BUFFER_CONTROL");
const EndpointControl = @FieldType(microzig.chip.types.peripherals.USB_DPRAM, "EP1_IN_CONTROL");

const setup = @import("usb/setup.zig");
const cdc = @import("usb/cdc.zig");
const timer = @import("timer.zig");
const endpoint = @import("usb/endpoint.zig");

const log = std.log.scoped(.usb_device);

const max_packet_size = 64;
const dpram_addr = @intFromPtr(USB_DPRAM);
const dpram_size = 4096;
const ep_ctrls: *volatile [32]EndpointControl = @ptrFromInt(dpram_addr + 0x00);
const buff_ctrls: *volatile [32]BufferControl = @ptrFromInt(dpram_addr + 0x80);

// DPRAM data buffers. The hardware fixes the EP0 buffer at 0x100 and shares it
// between both directions. Every other buffer holds one packet.
const ep0_buffer = 0x100;
const msc_in_buffer = 0x180;
const msc_out_buffer = 0x1C0;
const cdc_in_buffer = 0x200;
const cdc_out_buffer = 0x240;
const cdc_notification_buffer = 0x280;

// Interface numbers, class requests carry them in wIndex
const msc_interface_num = 0;
const cdc_comm_interface_num = 1;
const cdc_data_interface_num = 2;

fn ep_idx(ep: Endpoint) usize {
    return (2 * @backingInt(ep.num)) + @as(usize, switch (ep.dir) {
        .in => 0,
        .out => 1,
    });
}

fn endpoint_control(ep: Endpoint) *volatile EndpointControl {
    assert(ep.num != .ep0, .{});
    // TODO: this is not how it works.
    return &ep_ctrls[ep_idx(ep)];
}

fn buffer_control(ep: Endpoint) *volatile BufferControl {
    return &buff_ctrls[ep_idx(ep)];
}

fn clear_dpram() void {
    const dpram: *[dpram_size]u8 = @ptrFromInt(dpram_addr);
    @memset(dpram, 0);
}

const descriptors: setup.Descriptors = blk: {
    var builder: setup.StringDescriptorBuilder(&.{.english}) = .init();

    const manufacturer = builder.add_single("Zig Embedded Group");
    const product = builder.add_single("SYCL Badge V2");
    const serial = builder.add_single("serial number");
    const config_name = builder.add_single("default");
    const msc_name = builder.add_single("SYCL Badge Cart Storage");
    const cdc_name = builder.add_single("SYCL Badge Console");

    const device = descriptor.Device{
        .bcd_usb = .v2_00,
        // Composite device with an interface association descriptor
        .device_triple = .{ .class = .Miscellaneous, .subclass = 0x02, .protocol = 0x01 },
        .max_packet_size0 = max_packet_size,
        .vendor = .from(1234),
        .product = .from(1234),
        // Badge V2
        .bcd_device = .from(2, 0),
        .manufacturer_s = manufacturer,
        .product_s = product,
        .serial_s = serial,
        // rarely ever more than one
        .num_configurations = 1,
    };

    const const_builder = builder.finish();

    // Interface 0: mass storage for carts
    const msc_interface = descriptor.Interface{
        .interface_number = msc_interface_num,
        .alternate_setting = 0,
        .num_endpoints = 2,
        .interface_triple = .from(.MassStorage, .SCSI, .BulkOnly),
        .interface_s = msc_name,
    };
    const msc_in_ep: descriptor.Endpoint = .bulk(.{ .dir = .in, .num = .ep1 }, max_packet_size);
    const msc_out_ep: descriptor.Endpoint = .bulk(.{ .dir = .out, .num = .ep1 }, max_packet_size);

    // Interfaces 1 and 2: CDC ACM serial console
    const cdc_association = descriptor.InterfaceAssociation{
        .first_interface = cdc_comm_interface_num,
        .interface_count = 2,
        .function_class = @backingInt(types.ClassSubclassProtocol.ClassCode.CDC),
        .function_subclass = @backingInt(types.ClassSubclassProtocol.Subclass.CDC.Abstract),
        .function_protocol = @backingInt(types.ClassSubclassProtocol.Protocol.CDC.NoneRequired),
        .function = cdc_name,
    };
    const cdc_comm_interface = descriptor.Interface{
        .interface_number = cdc_comm_interface_num,
        .alternate_setting = 0,
        .num_endpoints = 1,
        .interface_triple = .from(.CDC, .Abstract, .NoneRequired),
        .interface_s = cdc_name,
    };
    const cdc_header = descriptor.cdc.Header{};
    const cdc_call_management = descriptor.cdc.CallManagement{
        .capabilities = .none,
        .data_interface = cdc_data_interface_num,
    };
    const cdc_acm = descriptor.cdc.AbstractControlModel{
        .capabilities = .{
            .comm_feature = false,
            .line_coding = true,
            .send_break = false,
            .network_connection = false,
        },
    };
    const cdc_union = descriptor.cdc.Union{
        .master_interface = cdc_comm_interface_num,
        .slave_interface_0 = cdc_data_interface_num,
    };
    const cdc_notification_ep: descriptor.Endpoint = .interrupt(.{ .dir = .in, .num = .ep3 }, 8, 16);
    const cdc_data_interface = descriptor.Interface{
        .interface_number = cdc_data_interface_num,
        .alternate_setting = 0,
        .num_endpoints = 2,
        .interface_triple = .{ .class = .CDC_Data, .subclass = 0x00, .protocol = 0x00 },
        .interface_s = cdc_name,
    };
    const cdc_in_ep: descriptor.Endpoint = .bulk(.{ .dir = .in, .num = .ep2 }, max_packet_size);
    const cdc_out_ep: descriptor.Endpoint = .bulk(.{ .dir = .out, .num = .ep2 }, max_packet_size);

    const function_descriptors = std.mem.asBytes(&msc_interface) ++
        std.mem.asBytes(&msc_in_ep) ++
        std.mem.asBytes(&msc_out_ep) ++
        std.mem.asBytes(&cdc_association) ++
        std.mem.asBytes(&cdc_comm_interface) ++
        std.mem.asBytes(&cdc_header) ++
        std.mem.asBytes(&cdc_call_management) ++
        std.mem.asBytes(&cdc_acm) ++
        std.mem.asBytes(&cdc_union) ++
        std.mem.asBytes(&cdc_notification_ep) ++
        std.mem.asBytes(&cdc_data_interface) ++
        std.mem.asBytes(&cdc_in_ep) ++
        std.mem.asBytes(&cdc_out_ep);

    const config = descriptor.Configuration{
        .total_length = .from(@sizeOf(descriptor.Configuration) + function_descriptors.len),
        .num_interfaces = 3,
        .configuration_value = 1,
        .configuration_s = config_name,
        .attributes = .{ .self_powered = false },
        .max_current = .from_ma(350),
    };

    const config_payload = std.mem.asBytes(&config) ++ function_descriptors;
    break :blk setup.Descriptors{
        .device = &device,
        .string = const_builder.to_descriptor(),
        .configurations = &.{config_payload},
    };
};

const SetupProcessor = setup.RequestPacketProcessor(.{
    .max_packet_size = max_packet_size,
    .max_transfer_size = max_packet_size,
    .callbacks = .{
        .queue_packet = queue_packet,
        .queue_receive = queue_receive,
        .set_address = set_address,
        .get_buffer = get_buffer,
        .clear_endpoint_halt = clear_endpoint_halt,
        .stall = stall,
    },
});

fn get_max_lun(_: ?*anyopaque) u4 {
    return 0;
}

fn bulk_only_mass_storage_reset(_: ?*anyopaque) void {}

const MSC_Driver = @import("usb/msc.zig").MSC_Driver(SetupProcessor, .{
    .max_packet_size = max_packet_size,
    .max_transfer_size = 512,
    .callbacks = .{
        .get_max_lun = get_max_lun,
        .bulk_only_mass_storage_reset = bulk_only_mass_storage_reset,
        .queue_packet = msc_queue_packet,
        .queue_receive = msc_queue_receive,
        .get_buffer = msc_get_buffer,
        .disarm_endpoints = msc_disarm_endpoints,
    },
});

const CDC_Driver = cdc.CDC_Driver(SetupProcessor, .{
    .max_packet_size = max_packet_size,
    .callbacks = .{
        .queue_packet = cdc_queue_packet,
        .queue_receive = cdc_queue_receive,
        .get_buffer = cdc_get_buffer,
        .disarm_endpoints = cdc_disarm_endpoints,
    },
});

var setup_processor: SetupProcessor = undefined;
var msc_driver: MSC_Driver = undefined;
var cdc_driver: CDC_Driver = undefined;

/// True while `poll` runs, `send` and `receive` must not re-enter it
var in_poll = false;

/// Initialize the USB device
/// Sets up the USB in device mode with mass storage and a CDC serial console
/// Returns error if initialization fails
pub fn init() !void {
    log.info("Resetting USBCTRL", .{});
    rp2xxx.resets.reset(.only(.usbctrl));

    log.info("Clearing DPRAM", .{});
    clear_dpram();

    // Mux the controller to the onboard usb phy
    USB.USB_MUXING.write(.{
        .TO_PHY = 1,
        .SOFTCON = 1,
    });

    // Force VBUS detect so the device thinks its plugged to a host
    USB.USB_PWR.write(.{
        .VBUS_DETECT = 1,
        .VBUS_DETECT_OVERRIDE_EN = 1,
    });

    // Enable  the usb control in device mode
    USB.MAIN_CTRL.write(.{
        .PHY_ISO = 0,
        .CONTROLLER_EN = 1,
        .HOST_NDEVICE = 0,
    });

    USB.SIE_CTRL.write(.{
        .EP0_INT_1BUF = 1,
        .PULLDOWN_EN = 0,
    });

    USB.INTE.write(.{
        .BUS_RESET = 1,
        .SETUP_REQ = 1,
        .BUFF_STATUS = 1,
        .TRANS_COMPLETE = 1,
    });

    msc_driver.init(null);
    cdc_driver.init();
    setup_processor = .init(.{
        .descriptors = descriptors,
        .handlers = .{
            .interface = &.{
                .{ .num = msc_interface_num, .ctx = &msc_driver, .handler = MSC_Driver.setup_handler },
                .{ .num = cdc_comm_interface_num, .ctx = &cdc_driver, .handler = CDC_Driver.setup_handler },
            },
        },
    });

    setup_endpoints();
    cdc_driver.reset();

    connect();
    msc_driver.in_ready();

    log.info("Finished init", .{});
    log_state();
}

fn set_address(addr: u7) void {
    log.info("set_address: {}", .{addr});
    USB.ADDR_ENDP.write(.{ .ADDRESS = addr });
}

fn stall(ep: types.Endpoint) void {
    log.info("stall: {}", .{ep});
    const buf_ctrl = buffer_control(ep);

    if (ep.num == .ep0) {
        buf_ctrl.write(.{
            .STALL = 1,
            .LAST_0 = 1,
        });

        buffer_control_delay();

        buf_ctrl.modify(.{ .AVAILABLE_0 = 1 });
        return;
    }

    disarm_endpoint(ep);
    buf_ctrl.modify(.{ .STALL = 1 });
}

fn clear_endpoint_halt(ep: types.Endpoint) void {
    switch (ep.num) {
        .ep1 => msc_driver.reset(),
        .ep2 => cdc_driver.reset(),
        else => {},
    }
}

/// Aborts the transfer armed on `ep` so its buffer can be written again
fn abort_endpoint(ep: Endpoint) void {
    switch (ep.num) {
        inline .ep1, .ep2, .ep3 => |num| switch (ep.dir) {
            inline .in, .out => |dir| {
                const field = comptime std.fmt.comptimePrint("EP{d}_{s}", .{
                    @backingInt(num),
                    switch (dir) {
                        .in => "IN",
                        .out => "OUT",
                    },
                });

                var abort: @TypeOf(USB.EP_ABORT.read()) = .{};
                @field(abort, field) = 1;
                USB.EP_ABORT.write(abort);
                while (@field(USB.EP_ABORT_DONE.read(), field) == 0) {}

                var done: @TypeOf(USB.EP_ABORT_DONE.read()) = .{};
                @field(done, field) = 1;
                rp2xxx.hw.clear_alias(&USB.EP_ABORT_DONE).write(done);
                USB.EP_ABORT.write(.{});
            },
        },
        else => @panic("abort_endpoint: unsupported endpoint"),
    }
}

fn disarm_endpoint(ep: Endpoint) void {
    assert(ep.num != .ep0, .{});
    const buf_ctrl = buffer_control(ep);

    if (buf_ctrl.read().AVAILABLE_0 == 1) {
        abort_endpoint(ep);
    }

    buf_ctrl.write(.{ .STALL = 0 });
}

fn msc_disarm_endpoints() void {
    const in_ctrl = buffer_control(.{ .dir = .in, .num = .ep1 });
    const out_ctrl = buffer_control(.{ .dir = .out, .num = .ep1 });
    log.debug("disarm_msc_endpoints: in.available={} out.available={}", .{
        in_ctrl.read().AVAILABLE_0,
        out_ctrl.read().AVAILABLE_0,
    });

    disarm_endpoint(.{ .dir = .in, .num = .ep1 });
    disarm_endpoint(.{ .dir = .out, .num = .ep1 });

    // drop abandoned buffers
    rp2xxx.hw.clear_alias(&USB.BUFF_STATUS).write(.{ .EP1_IN = 1, .EP1_OUT = 1 });
}

fn cdc_disarm_endpoints() void {
    disarm_endpoint(.{ .dir = .in, .num = .ep2 });
    disarm_endpoint(.{ .dir = .out, .num = .ep2 });

    // drop abandoned buffers
    rp2xxx.hw.clear_alias(&USB.BUFF_STATUS).write(.{ .EP2_IN = 1, .EP2_OUT = 1 });
}

/// The buffer control register needs a few cycles between writing the packet
/// fields and setting AVAILABLE
inline fn buffer_control_delay() void {
    asm volatile (
        \\ nop
        \\ nop
        \\ nop
    );
}

/// Queues one IN packet on a non-control endpoint
fn queue_in_packet(ep_num: Endpoint.Num, buffer_offset: u16, data: []const u8, pid: endpoint.PacketIdentifier) void {
    const buf_ctrl = buffer_control(.{ .dir = .in, .num = ep_num });
    assert(buf_ctrl.read().AVAILABLE_0 == 0, .{});
    assert(data.len <= max_packet_size, .{});

    const dest: [*]u8 = @ptrFromInt(dpram_addr + buffer_offset);
    @memcpy(dest[0..data.len], data);

    buf_ctrl.write(.{
        .LENGTH_0 = @intCast(data.len),
        .PID_0 = @backingInt(pid),
        .FULL_0 = 1,
        .LAST_0 = 1,
    });

    buffer_control_delay();

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

/// Arms a non-control OUT endpoint to receive one packet
fn queue_out_packet(ep_num: Endpoint.Num, pid: endpoint.PacketIdentifier) void {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = ep_num });

    buf_ctrl.write(.{
        .LENGTH_0 = max_packet_size,
        .PID_0 = @backingInt(pid),
        .FULL_0 = 0,
        .LAST_0 = 1,
    });

    buffer_control_delay();

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

/// Payload of the packet that a non-control OUT endpoint last received
fn received_packet(ep_num: Endpoint.Num, buffer_offset: u16) []const u8 {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = ep_num });
    const ptr: [*]const u8 = @ptrFromInt(dpram_addr + buffer_offset);
    return ptr[0..buf_ctrl.read().LENGTH_0];
}

fn queue_packet(data: []const u8, pid: setup.PID) void {
    const buf_ctrl = buffer_control(.{ .dir = .in, .num = .ep0 });
    //assert(buf_ctrl.read().AVAILABLE_0 == 0, .{});
    assert(data.len <= 64, .{});

    log.debug("queue_packet: len={} pid={}", .{ data.len, pid });
    const dest: [*]u8 = @ptrFromInt(dpram_addr + ep0_buffer);
    @memcpy(dest[0..data.len], data);

    buf_ctrl.write(.{
        .LENGTH_0 = @intCast(data.len),
        .PID_0 = @backingInt(pid),
        .FULL_0 = 1,
        .LAST_0 = 1,
    });

    buffer_control_delay();

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn get_buffer() []const u8 {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = .ep0 });
    const ptr: [*]const u8 = @ptrFromInt(dpram_addr + ep0_buffer);
    return ptr[0..buf_ctrl.read().LENGTH_0];
}

fn queue_receive() void {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = .ep0 });

    log.debug("queue_receive", .{});

    // Accept a full packet: either the zero length status stage of a control
    // IN transfer, or the single packet data stage of a control OUT request.
    // Both are DATA1.
    buf_ctrl.write(.{
        .LENGTH_0 = max_packet_size,
        .PID_0 = 1,
        .FULL_0 = 0,
        .LAST_0 = 1,
    });

    buffer_control_delay();

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn msc_queue_packet(data: []const u8, pid: endpoint.PacketIdentifier) void {
    log.debug("queue_msc_packet: len={} pid={}", .{ data.len, pid });
    queue_in_packet(.ep1, msc_in_buffer, data, pid);
}

fn msc_get_buffer() []const u8 {
    return received_packet(.ep1, msc_out_buffer);
}

fn msc_queue_receive(pid: endpoint.PacketIdentifier) void {
    log.debug("queue_msc_receive: pid={}", .{pid});
    queue_out_packet(.ep1, pid);
}

fn cdc_queue_packet(data: []const u8, pid: endpoint.PacketIdentifier) void {
    log.debug("queue_cdc_packet: len={} pid={}", .{ data.len, pid });
    queue_in_packet(.ep2, cdc_in_buffer, data, pid);
}

fn cdc_get_buffer() []const u8 {
    return received_packet(.ep2, cdc_out_buffer);
}

fn cdc_queue_receive(pid: endpoint.PacketIdentifier) void {
    log.debug("queue_cdc_receive: pid={}", .{pid});
    queue_out_packet(.ep2, pid);
}

fn configure_endpoint(ep: Endpoint, ep_type: EndpointType, buffer_offset: u16) void {
    endpoint_control(ep).write(.{
        .BUFFER_ADDRESS = buffer_offset,
        .ENDPOINT_TYPE = ep_type,
        .INTERRUPT_PER_BUFF = 1,
        .DOUBLE_BUFFERED = 0,
        .ENABLE = 1,
    });
}

fn setup_endpoints() void {
    // EP1 IN and OUT: mass storage
    configure_endpoint(.{ .num = .ep1, .dir = .in }, .bulk, msc_in_buffer);
    configure_endpoint(.{ .num = .ep1, .dir = .out }, .bulk, msc_out_buffer);
    msc_queue_receive(.DATA0);

    // EP2 IN and OUT: CDC data, the CDC driver arms the OUT side in reset
    configure_endpoint(.{ .num = .ep2, .dir = .in }, .bulk, cdc_in_buffer);
    configure_endpoint(.{ .num = .ep2, .dir = .out }, .bulk, cdc_out_buffer);

    // EP3 IN: CDC notifications. Enabled so the controller answers the host's
    // polls with NAK, but never armed: the console has nothing to notify.
    configure_endpoint(.{ .num = .ep3, .dir = .in }, .interrupt, cdc_notification_buffer);
}

pub fn poll() void {
    if (in_poll) return;
    in_poll = true;
    defer in_poll = false;

    const interrupts = USB.INTS.read();

    if (interrupts.BUS_RESET == 1) {
        log.debug("BUS_RESET", .{});
        USB.ADDR_ENDP.write(.{ .ADDRESS = 0 });

        msc_driver.reset();
        cdc_driver.reset();

        // TODO: use clear alias?
        USB.SIE_STATUS.write(.{ .BUS_RESET = 1 });
    }

    if (interrupts.BUFF_STATUS == 1) {
        const buff_status = USB.BUFF_STATUS.read();

        inline for (@typeInfo(@TypeOf(buff_status)).@"struct".field_names) |field_name| {
            if (@field(buff_status, field_name) == 1)
                log.debug("BUFF_STATUS: {s}", .{field_name});
        }

        const clear = rp2xxx.hw.clear_alias(&USB.BUFF_STATUS);
        if (buff_status.EP0_IN == 1) {
            setup_processor.ep0_in_ready();
            clear.write(.{ .EP0_IN = 1 });
        }

        if (buff_status.EP0_OUT == 1) {
            setup_processor.ep0_out_ready();
            clear.write(.{ .EP0_OUT = 1 });
        }

        if (buff_status.EP1_IN == 1) {
            msc_driver.in_ready();
            clear.write(.{ .EP1_IN = 1 });
        }

        if (buff_status.EP1_OUT == 1) {
            msc_driver.out_ready();
            clear.write(.{ .EP1_OUT = 1 });
        }

        if (buff_status.EP2_IN == 1) {
            cdc_driver.in_ready();
            clear.write(.{ .EP2_IN = 1 });
        }

        if (buff_status.EP2_OUT == 1) {
            cdc_driver.out_ready();
            clear.write(.{ .EP2_OUT = 1 });
        }
    }

    if (interrupts.SETUP_REQ == 1) {
        log.debug("SETUP_REQ", .{});
        USB.SIE_STATUS.write(.{ .SETUP_REC = 1 });

        const pkt: *volatile types.SetupPacket = @ptrCast(@alignCast(&USB_DPRAM.SETUP_PACKET_LOW));
        setup_processor.submit_setup_request(pkt.*);
    }

    setup_processor.poll();
    msc_driver.poll();
    cdc_driver.poll();
}

/// Sends console output to the host. Output waits in a buffer until a terminal
/// opens the port. While a terminal is connected this waits up to 100 ms for
/// room, then drops the rest. Returns true if every byte was queued.
pub fn send(data: []const u8) bool {
    // The USB peripheral belongs to core 0
    if (SIO.CPUID.raw != 0) return false;

    var rest = data[cdc_driver.write(data)..];
    const deadline = timer.millis() + 100;
    while (rest.len > 0) {
        if (!cdc_driver.connected() or in_poll or timer.millis() > deadline) return false;
        poll();
        rest = rest[cdc_driver.write(rest)..];
    }
    return true;
}

/// Receives console input from the host. Waits up to `timeout_ms` for the
/// first byte. Returns the number of bytes written to `buffer`.
pub fn receive(buffer: []u8, timeout_ms: u32) usize {
    const deadline = timer.millis() + timeout_ms;
    while (true) {
        const n = cdc_driver.read(buffer);
        if (n > 0 or in_poll or timer.millis() >= deadline) return n;
        poll();
    }
}

fn log_state() void {
    log.debug("SIE_CTRL: {}", .{USB.SIE_CTRL.read()});
    log.debug("SIE_STATUS: {}", .{USB.SIE_STATUS.read()});
}

fn connect() void {
    log.info("Connect", .{});
    USB.SIE_CTRL.modify(.{
        .PULLUP_EN = 1,
    });
}

/// Disconnect the USB device from the host
/// This disables the pull-up resistor to signal disconnection
/// Call this before system reset to properly close the USB connection
pub fn disconnect() void {
    // Disable the pull-up resistor to disconnect from host
    // On RP235X, this is done via SIE_CTRL.PULLUP_EN
    USB.SIE_CTRL.modify(.{ .PULLUP_EN = 0 });
}

test {
    _ = @import("usb/endpoint.zig");
    _ = @import("usb/cdc.zig");
}
