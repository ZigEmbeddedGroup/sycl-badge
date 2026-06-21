/// USB device driver
/// Barebones CDC implementation wrapping microzig USB HAL
/// For loading programs via USB CDC (virtual serial port)
const std = @import("std");
const microzig = @import("microzig");
const assert = microzig.assert;
const rp2xxx = microzig.hal;
const mmio = microzig.mmio;
const core = microzig.core;
const descriptor = core.usb.descriptor;
const types = core.usb.types;
const TransferType = types.TransferType;
const SetupPacket = types.SetupPacket;
const Endpoint = types.Endpoint;
const USB = microzig.chip.peripherals.USB;
const USB_DPRAM = microzig.chip.peripherals.USB_DPRAM;
const EndpointType = microzig.chip.types.peripherals.USB_DPRAM.EndpointType;
const BufferControl = @FieldType(microzig.chip.types.peripherals.USB_DPRAM, "EP0_IN_BUFFER_CONTROL");
const EndpointControl = @FieldType(microzig.chip.types.peripherals.USB_DPRAM, "EP1_IN_CONTROL");

const setup = @import("usb/setup.zig");
const timer = @import("timer.zig");
const storage = @import("../loader/storage.zig");
const endpoint = @import("usb/endpoint.zig");

const log = std.log.scoped(.usb_device);

const AssumeOptions = struct {};

fn endpoint_type_from_transfer_type(xfer: TransferType) EndpointType {
    return switch (xfer) {
        .control => .control,
        .isochronous => .isochronous,
        .bulk => .bulk,
        .interrupt => .interrupt,
    };
}

const max_packet_size = 64;
const dpram_addr = @intFromPtr(USB_DPRAM);
const dpram_size = 4096;
const dpram_buffer_start_offset = 0x180;
const ep_ctrls: *volatile [32]EndpointControl = @ptrFromInt(dpram_addr + 0x00);
const buff_ctrls: *volatile [32]BufferControl = @ptrFromInt(dpram_addr + 0x80);

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
    const interface_name = builder.add_single("SYCL Badge Cart Storage");

    const device = descriptor.Device{
        .bcd_usb = .v2_00,
        // Let the OS figure things out by looking at the interfaces
        .device_triple = .unspecified,
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

    const msc_interface = descriptor.Interface{
        .interface_number = 0,
        .alternate_setting = 0,
        .num_endpoints = 2,
        .interface_triple = .from(.MassStorage, .SCSI, .BulkOnly),
        .interface_s = interface_name,
    };

    const bulk_in_ep: descriptor.Endpoint = .bulk(.{ .dir = .in, .num = .ep1 }, max_packet_size);
    const bulk_out_ep: descriptor.Endpoint = .bulk(.{ .dir = .out, .num = .ep1 }, max_packet_size);

    const config = descriptor.Configuration{
        .total_length = .from(@sizeOf(descriptor.Configuration) + @sizeOf(descriptor.Interface) + (2 * @sizeOf(descriptor.Endpoint))),
        .num_interfaces = 1,
        .configuration_value = 1,
        .configuration_s = config_name,
        .attributes = .{ .self_powered = false },
        .max_current = .from_ma(350),
    };

    const config_payload = std.mem.asBytes(&config) ++ std.mem.asBytes(&msc_interface) ++ std.mem.asBytes(&bulk_in_ep) ++ std.mem.asBytes(&bulk_out_ep);
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
        .queue_packet = queue_msc_packet,
        .queue_receive = queue_msc_receive,
        .get_buffer = get_msc_buffer,
    },
});

var setup_processor: SetupProcessor = undefined;
var msc_driver: MSC_Driver = undefined;

fn in_buf_ready() bool {
    const buf_ctrl = buffer_control(.{ .dir = .in, .num = .ep0 });
    return buf_ctrl.read().AVAILABLE_0 == 0;
}

/// Initialize the USB device
/// Sets up the USB in device mode for CDC (virtual serial port)
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
    setup_processor = .init(.{
        .descriptors = descriptors,
        .handlers = .{
            .interface = &.{
                .{ .num = 0, .ctx = &msc_driver, .handler = MSC_Driver.setup_handler },
            },
        },
    });

    setup_endpoints();

    connect();
    msc_driver.in_ready();

    log.info("Finished init", .{});
    log_state();
}

fn set_address(addr: u7) void {
    log.info("set_address: {}", .{addr});
    USB.ADDR_ENDP.write(.{ .ADDRESS = addr });
}

fn queue_packet(data: []const u8, pid: setup.PID) void {
    const buf_ctrl = buffer_control(.{ .dir = .in, .num = .ep0 });
    assert(buf_ctrl.read().AVAILABLE_0 == 0, .{});
    assert(data.len <= 64, .{});

    log.debug("queue_packet: len={} pid={}", .{ data.len, pid });
    const dest: [*]u8 = @ptrFromInt(dpram_addr + 0x100);
    @memcpy(dest[0..data.len], data);

    buf_ctrl.write(.{
        .LENGTH_0 = @intCast(data.len),
        .PID_0 = @backingInt(pid),
        .FULL_0 = 1,
        .LAST_0 = 1,
    });

    asm volatile (
        \\ nop
        \\ nop
        \\ nop
    );

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn queue_msc_packet(data: []const u8, pid: endpoint.PacketIdentifier) void {
    const buf_ctrl = buffer_control(.{ .dir = .in, .num = .ep1 });
    assert(buf_ctrl.read().AVAILABLE_0 == 0, .{});
    assert(data.len <= 64, .{});

    log.debug("queue_msc_packet: len={} pid={}", .{ data.len, pid });
    const dest: [*]u8 = @ptrFromInt(dpram_addr + 0x180);
    @memcpy(dest[0..data.len], data);

    buf_ctrl.write(.{
        .LENGTH_0 = @intCast(data.len),
        .PID_0 = @backingInt(pid),
        .FULL_0 = 1,
        .LAST_0 = 1,
    });

    asm volatile (
        \\ nop
        \\ nop
        \\ nop
    );

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn get_buffer() []const u8 {
    return "";
}

fn get_msc_buffer() []const u8 {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = .ep1 });
    const ptr: [*]const u8 = @ptrFromInt(dpram_addr + 0x180 + 64);
    return ptr[0..buf_ctrl.read().LENGTH_0];
}

fn queue_receive() void {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = .ep0 });

    log.debug("queue_receive", .{});

    buf_ctrl.write(.{
        .LENGTH_0 = 0,
        .PID_0 = 0,
        .FULL_0 = 0,
        .LAST_0 = 1,
    });

    asm volatile (
        \\ nop
        \\ nop
        \\ nop
    );

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn queue_msc_receive(pid: endpoint.PacketIdentifier) void {
    const buf_ctrl = buffer_control(.{ .dir = .out, .num = .ep1 });

    log.debug("queue_msc_receive: pid={}", .{pid});

    buf_ctrl.write(.{
        .LENGTH_0 = max_packet_size,
        .PID_0 = @backingInt(pid),
        .FULL_0 = 0,
        .LAST_0 = 1,
    });

    asm volatile (
        \\ nop
        \\ nop
        \\ nop
    );

    buf_ctrl.modify(.{
        .AVAILABLE_0 = 1,
    });
}

fn allocate_buffer(offset: *u16) u16 {
    defer offset.* += max_packet_size;
    return offset.*;
}

fn setup_endpoints() void {
    var buffer_offset_current: u16 = dpram_buffer_start_offset;

    // EP1 IN and OUT: MSC
    const ep1_in = endpoint_control(.{ .num = .ep1, .dir = .in });
    const ep1_out = endpoint_control(.{ .num = .ep1, .dir = .out });

    ep1_in.write(.{
        .BUFFER_ADDRESS = allocate_buffer(&buffer_offset_current),
        .ENDPOINT_TYPE = .bulk,
        .INTERRUPT_PER_BUFF = 1,
        .DOUBLE_BUFFERED = 0,
        .ENABLE = 1,
    });

    ep1_out.write(.{
        .BUFFER_ADDRESS = allocate_buffer(&buffer_offset_current),
        .ENDPOINT_TYPE = .bulk,
        .INTERRUPT_PER_BUFF = 1,
        .DOUBLE_BUFFERED = 0,
        .ENABLE = 1,
    });

    queue_msc_receive(.DATA0);

    // EP2 IN AND OUT: CDC

}

pub fn poll() void {
    const interrupts = USB.INTS.read();

    if (interrupts.BUS_RESET == 1) {
        log.debug("BUS_RESET", .{});
        USB.ADDR_ENDP.write(.{ .ADDRESS = 0 });

        // TODO: use clear alias?
        USB.SIE_STATUS.write(.{ .BUS_RESET = 1 });
    }

    if (interrupts.SETUP_REQ == 1) {
        log.debug("SETUP_REQ", .{});
        USB.SIE_STATUS.write(.{ .SETUP_REC = 1 });

        const pkt: *volatile types.SetupPacket = @ptrCast(@alignCast(&USB_DPRAM.SETUP_PACKET_LOW));
        setup_processor.submit_setup_request(pkt.*);
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
    }

    setup_processor.poll();
    msc_driver.poll();
}

/// Send data over USB (non-blocking with retry limit)
/// Returns true if successful
pub fn send(data: []const u8) bool {
    _ = data;
    //const drivers = usb_controller.drivers() orelse return false;

    //var tx: []const u8 = data;
    //while (tx.len > 0) {
    //    tx = tx[drivers.serial.write(tx)..];
    //    usb_device.poll(&usb_controller);
    //}
    //// Short messages are not sent right away; instead, they accumulate in a buffer, so we have to force a flush to send them
    //while (!drivers.serial.flush())
    //    usb_device.poll(&usb_controller);

    return true;
}

/// Receive data from USB (non-blocking with timeout)
/// Returns number of bytes actually received
pub fn receive(buffer: []u8, timeout_ms: u32) usize {
    _ = buffer;
    _ = timeout_ms;
    return 0;
    //const drivers = usb_controller.drivers() orelse return 0;

    //const start = time.get_time_since_boot().to_us();
    //const timeout_us = timeout_ms * 1000;

    //var rx_len: usize = 0;
    //while (true) {
    //    const len = drivers.serial.read(buffer[rx_len..]);
    //    rx_len += len;
    //    if (len == 0)
    //        break;

    //    // Check timeout
    //    const elapsed = time.get_time_since_boot().to_us() - start;
    //    if (elapsed >= timeout_us)
    //        break;

    //    usb_device.poll(&usb_controller);
    //}

    //return rx_len;
}

/// Check if data is available to read
/// Returns number of bytes in RX buffer
pub fn available() usize {
    //const drivers = usb_controller.drivers() orelse return 0;
    //return drivers.serial.available();
    return 0;
}

/// Process USB events (MUST be called frequently from main loop!)
/// This is critical for USB to work - call as often as possible
/// Handles enumeration, control requests, and data transfers
//pub fn poll() void {
//usb_device.poll(&usb_controller);
//const drivers = usb_controller.drivers() orelse return;
//_ = drivers;
// Very Big TODO: handle stuff for drivers
//}

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

// Buffer for formatted printing (max 2KB)
//var print_buffer: [2048]u8 = undefined;

/// Send formatted string over USB with full printf-style formatting
///
/// Supports all Zig format specifiers:
/// - {} or {any}     - Default formatting for any type
/// - {d}            - Decimal integer
/// - {x}            - Lowercase hexadecimal
/// - {X}            - Uppercase hexadecimal
/// - {o}            - Octal
/// - {b}            - Binary
/// - {c}            - Character
/// - {s}            - String/slice
/// - {e}            - Lowercase scientific notation
/// - {E}            - Uppercase scientific notation
/// - {[precision]}  - Decimal precision (e.g., {d:4} for width 4)
///
/// Examples:
///   printf("Number: {d}\r\n", .{42})           -> "Number: 42"
///   printf("Hex: 0x{x:0>4}\r\n", .{255})       -> "Hex: 0x00ff"
///   printf("String: {s}\r\n", .{"hello"})      -> "String: hello"
///   printf("Mixed: {} and {d}\r\n", .{1, 2})   -> "Mixed: 1 and 2"
///
/// Returns true if successful, false if buffer overflow or send failed
pub fn printf(comptime fmt: []const u8, args: anytype) bool {
    _ = fmt;
    _ = args;
    //const text = std.fmt.bufPrint(&print_buffer, fmt, args) catch return false;
    //return send(text);
}

test {
    //_ = @import("usb/setup.zig");
    _ = @import("usb/endpoint.zig");
}
