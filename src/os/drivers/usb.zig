/// USB device driver
/// Barebones CDC implementation wrapping microzig USB HAL
/// For loading programs via USB CDC (virtual serial port)
const std = @import("std");
const microzig = @import("microzig");
const usb = microzig.hal.usb;
const time = microzig.hal.time;

// Create USB device instance
const usb_dev = usb.Usb(.{});

// CDC descriptor constants
const usb_config_len = usb.templates.config_descriptor_len + usb.templates.cdc_descriptor_len;
const usb_config_descriptor =
    usb.templates.config_descriptor(1, 2, 0, usb_config_len, 0xc0, 100) ++
    usb.templates.cdc_descriptor(0, 4, usb.Endpoint.to_address(1, .In), 8, usb.Endpoint.to_address(2, .Out), usb.Endpoint.to_address(2, .In), 64);

// CDC class driver instance
var driver_cdc: usb.cdc.CdcClassDriver(usb_dev) = .{};
var drivers = [_]usb.types.UsbClassDriver{driver_cdc.driver()};

// Device configuration
var device_configuration: usb.DeviceConfiguration = .{
    .device_descriptor = &.{
        .descriptor_type = usb.DescType.Device,
        .bcd_usb = 0x0200,
        .device_class = 0xEF, // Miscellaneous Device Class
        .device_subclass = 2, // Common Class
        .device_protocol = 1, // Interface Association Descriptor
        .max_packet_size0 = 64,
        .vendor = 0x2E8A, // Raspberry Pi
        .product = 0x000a, // Pico SDK CDC
        .bcd_device = 0x0100,
        .manufacturer_s = 1,
        .product_s = 2,
        .serial_s = 0,
        .num_configurations = 1,
    },
    .config_descriptor = &usb_config_descriptor,
    .lang_descriptor = "\x04\x03\x09\x04", // English (US)
    .descriptor_strings = &.{
        &usb.utils.utf8_to_utf16_le("SYCL Badge"),
        &usb.utils.utf8_to_utf16_le("Program Loader"),
    },
    .drivers = &drivers,
};

/// Initialize the USB device
/// Sets up the USB in device mode for CDC (virtual serial port)
/// Returns error if initialization fails
pub fn init() !void {
    usb_dev.init_clk();
    try usb_dev.init_device(&device_configuration);
}

/// Check if USB is connected to a host
pub fn isConnected() bool {
    return driver_cdc.is_connected();
}

/// Send data over USB (blocking)
/// Returns true if successful
pub fn send(data: []const u8) bool {
    if (!isConnected()) return false;

    const written = driver_cdc.write(data) catch return false;
    return written == data.len;
}

/// Receive data from USB (blocking with timeout)
/// Returns number of bytes actually received
pub fn receive(buffer: []u8, timeout_ms: u32) usize {
    if (!isConnected()) return 0;

    const start = time.get_time_since_boot().to_us();
    const timeout_us = timeout_ms * 1000;

    while (true) {
        const available_count = driver_cdc.available();
        if (available_count > 0) {
            const to_read = @min(available_count, buffer.len);
            return driver_cdc.read(buffer[0..to_read]) catch 0;
        }

        const elapsed = time.get_time_since_boot().to_us() - start;
        if (elapsed >= timeout_us) break;

        // Process USB events while waiting
        usb_dev.task(false) catch {};
    }

    return 0;
}

/// Check if data is available to read
/// Returns number of bytes in RX buffer
pub fn available() usize {
    if (!isConnected()) return 0;
    return driver_cdc.available();
}

/// Process USB events (we need to call regularly from main loop)
/// Handles enumeration, control requests, etc.
pub fn poll() void {
    usb_dev.task(false) catch {};
}
