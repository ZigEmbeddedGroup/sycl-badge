/// USB device driver
/// Barebones CDC implementation wrapping microzig USB HAL
/// For loading programs via USB CDC (virtual serial port)
const std = @import("std");
const microzig = @import("microzig");
const core = microzig.core;
const rp2xxx = microzig.hal;
const usb = core.usb;
const time = rp2xxx.time;
const msc = @import("usb_msc.zig");

const USB_Device = rp2xxx.usb.Polled(.{});
const USB_Serial = usb.drivers.CDC;
const USB_MSC = @import("usb_msc.zig");

var usb_device: USB_Device = undefined;

// TODO: ensure device config matches
var usb_controller: usb.DeviceController(.{
    .bcd_usb = USB_Device.max_supported_bcd_usb,
    .device_triple = .unspecified,
    .vendor = USB_Device.default_vendor_id,
    .product = USB_Device.default_product_id,
    .bcd_device = .v1_00,
    .serial = "someserial",
    .max_supported_packet_size = USB_Device.max_supported_packet_size,
    .configurations = &.{
        .{
            .attributes = .{ .self_powered = false },
            .max_current_ma = 200,
            .Drivers = struct {
                serial: USB_Serial,
                msc: USB_MSC,
                reset: rp2xxx.usb.ResetDriver(null, 0),
            },
        },
    },
}, .{
    // TODO: what is this?
    .{
        .serial = .{
            .itf_notifi = "Board CDC",
            .itf_data = "Board CDC Data",
        },
        .msc = .{
            // TODO: what goes in here?
        },
        .reset = "",
    },
}) = .init;

// Device configuration
//const device_configuration: usb.DeviceConfiguration = .{
//    .device_descriptor = &.{
//        .descriptor_type = usb.DescType.Device,
//        .bcd_usb = 0x0200,
//        .device_class = 0x00,
//        .device_subclass = 0,
//        .device_protocol = 0,
//        .max_packet_size0 = 64,
//        .vendor = 0x2E8A,
//        .product = 0x000a,
//        .bcd_device = 0x0100,
//        .manufacturer_s = 1,
//        .product_s = 2,
//        .serial_s = 3,
//        .num_configurations = 1,
//    },
//    .config_descriptor = &usb_config_descriptor,
//    .lang_descriptor = "\x04\x03\x09\x04", // length || string descriptor (0x03) || Engl (0x0409)
//    .descriptor_strings = &.{
//        &usb.utils.utf8_to_utf16_le("Raspberry Pi"),
//        &usb.utils.utf8_to_utf16_le("SYCL Badge"),
//        &usb.utils.utf8_to_utf16_le("SYCLBADGE0001"),
//        &usb.utils.utf8_to_utf16_le("CDC Console"),
//    },
//    .drivers = &drivers,
//};

// Create USB device instance
//const usb_dev = usb.Usb(.{});
//
//// CDC descriptor constants
//const msc_descriptor_len = 9 + 7 + 7;
//const msc_descriptor: [msc_descriptor_len]u8 = blk: {
//    var desc: [msc_descriptor_len]u8 = undefined;
//    const itf_desc = usb.types.InterfaceDescriptor{
//        .interface_number = 2,
//        .alternate_setting = 0,
//        .num_endpoints = 2,
//        .interface_class = 0x08,
//        .interface_subclass = 0x06,
//        .interface_protocol = 0x50,
//        .interface_s = 0,
//    };
//    const itf = itf_desc.serialize();
//    const ep_out_desc = usb.types.EndpointDescriptor{
//        .endpoint_address = usb.Endpoint.to_address(3, .Out),
//        .attributes = @intFromEnum(usb.types.TransferType.Bulk),
//        .max_packet_size = 64,
//        .interval = 0,
//    };
//    const ep_out = ep_out_desc.serialize();
//    const ep_in_desc = usb.types.EndpointDescriptor{
//        .endpoint_address = usb.Endpoint.to_address(3, .In),
//        .attributes = @intFromEnum(usb.types.TransferType.Bulk),
//        .max_packet_size = 64,
//        .interval = 0,
//    };
//    const ep_in = ep_in_desc.serialize();
//    @memcpy(desc[0..itf.len], &itf);
//    @memcpy(desc[itf.len .. itf.len + ep_out.len], &ep_out);
//    @memcpy(desc[itf.len + ep_out.len ..], &ep_in);
//    break :blk desc;
//};
//
//const usb_config_len = usb.templates.config_descriptor_len + usb.templates.cdc_descriptor_len + msc_descriptor_len;
//const usb_config_descriptor =
//    usb.templates.config_descriptor(1, 3, 0, usb_config_len, 0xc0, 100) ++
//    usb.templates.cdc_descriptor(0, 4, usb.Endpoint.to_address(1, .In), 8, usb.Endpoint.to_address(2, .Out), usb.Endpoint.to_address(2, .In), 64) ++
//    msc_descriptor;
//
//// CDC class driver instance
//var driver_cdc: usb.cdc.CdcClassDriver(usb_dev) = .{};
//var driver_msc: msc.MscClassDriver = .{};
//var drivers = [_]usb.types.UsbClassDriver{ driver_cdc.driver(), driver_msc.driver() };

/// Initialize the USB device
/// Sets up the USB in device mode for CDC (virtual serial port)
/// Returns error if initialization fails
pub fn init() !void {
    usb_device = .init();
}

/// Send data over USB (non-blocking with retry limit)
/// Returns true if successful
pub fn send(data: []const u8) bool {
    const drivers = usb_controller.drivers() orelse return false;

    var tx: []const u8 = data;
    while (tx.len > 0) {
        tx = tx[drivers.serial.write(tx)..];
        usb_device.poll(&usb_controller);
    }
    // Short messages are not sent right away; instead, they accumulate in a buffer, so we have to force a flush to send them
    while (!drivers.serial.flush())
        usb_device.poll(&usb_controller);

    return true;
}

/// Receive data from USB (non-blocking with timeout)
/// Returns number of bytes actually received
pub fn receive(buffer: []u8, timeout_ms: u32) usize {
    const drivers = usb_controller.drivers() orelse return 0;

    const start = time.get_time_since_boot().to_us();
    const timeout_us = timeout_ms * 1000;

    var rx_len: usize = 0;
    while (true) {
        const len = drivers.serial.read(buffer[rx_len..]);
        rx_len += len;
        if (len == 0)
            break;

        // Check timeout
        const elapsed = time.get_time_since_boot().to_us() - start;
        if (elapsed >= timeout_us)
            break;

        usb_device.poll(&usb_controller);
    }

    return rx_len;
}

/// Check if data is available to read
/// Returns number of bytes in RX buffer
pub fn available() usize {
    const drivers = usb_controller.drivers() orelse return 0;
    return drivers.serial.available();
}

/// Process USB events (MUST be called frequently from main loop!)
/// This is critical for USB to work - call as often as possible
/// Handles enumeration, control requests, and data transfers
pub fn poll() void {
    usb_device.poll(&usb_controller);
    const drivers = usb_controller.drivers() orelse return;
    _ = drivers;
    // Very Big TODO: handle stuff for drivers
}

/// Disconnect the USB device from the host
/// This disables the pull-up resistor to signal disconnection
/// Call this before system reset to properly close the USB connection
pub fn disconnect() void {
    const USB = microzig.chip.peripherals.USB;

    // Disable the pull-up resistor to disconnect from host
    // On RP235X, this is done via SIE_CTRL.PULLUP_EN
    USB.SIE_CTRL.modify(.{ .PULLUP_EN = 0 });
}

// Buffer for formatted printing (max 2KB)
var print_buffer: [2048]u8 = undefined;

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
    const text = std.fmt.bufPrint(&print_buffer, fmt, args) catch return false;
    return send(text);
}
