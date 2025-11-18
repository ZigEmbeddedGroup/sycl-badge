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
pub var device_configuration: usb.DeviceConfiguration = .{
    .device_descriptor = &.{
        .descriptor_type = usb.DescType.Device,
        .bcd_usb = 0x0200,
        .device_class = 0xEF,
        .device_subclass = 2,
        .device_protocol = 1,
        .max_packet_size0 = 64,
        .vendor = 0x2E8A,
        .product = 0x000a,
        .bcd_device = 0x0100,
        .manufacturer_s = 1,
        .product_s = 2,
        .serial_s = 0,
        .num_configurations = 1,
    },
    .config_descriptor = &usb_config_descriptor,
    .lang_descriptor = "\x04\x03\x09\x04", // length || string descriptor (0x03) || Engl (0x0409)
    .descriptor_strings = &.{
        &usb.utils.utf8_to_utf16_le("Raspberry Pi"),
        &usb.utils.utf8_to_utf16_le("Pico Test Device"),
        &usb.utils.utf8_to_utf16_le("someserial"),
        &usb.utils.utf8_to_utf16_le("Board CDC"),
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
/// Returns true if the host has opened the COM port (DTR is set)
pub fn isConnected() bool {
    // Check if DTR (Data Terminal Ready) is set by the host
    // Bit 0 of line_state is DTR
    // When a terminal program opens the COM port, it sets DTR=1
    return (driver_cdc.line_state & 0x01) != 0;
}

/// Send data over USB (non-blocking with retry limit)
/// Returns true if successful
pub fn send(data: []const u8) bool {
    // Write the data in chunks with limited attempts to prevent blocking
    var write_data: []const u8 = data;
    var attempts: u32 = 0;

    while (write_data.len > 0 and attempts < 100) : (attempts += 1) {
        write_data = driver_cdc.write(write_data);
        usb_dev.task(false) catch {};
    }

    // CRITICAL: Flush to actually send short messages!
    _ = driver_cdc.write_flush();

    return write_data.len == 0; // Return true if all data was written
}

/// Receive data from USB (non-blocking with timeout)
/// Returns number of bytes actually received
pub fn receive(buffer: []u8, timeout_ms: u32) usize {
    const start = time.get_time_since_boot().to_us();
    const timeout_us = timeout_ms * 1000;

    var total_read: usize = 0;
    var read_buffer = buffer;

    while (read_buffer.len > 0) {
        const len = driver_cdc.read(read_buffer);
        read_buffer = read_buffer[len..];
        total_read += len;

        if (len == 0) {
            // No more data available
            break;
        }

        // Check timeout
        const elapsed = time.get_time_since_boot().to_us() - start;
        if (elapsed >= timeout_us) break;

        // Process USB events while waiting
        usb_dev.task(false) catch {};
    }

    return total_read;
}

/// Check if data is available to read
/// Returns number of bytes in RX buffer
pub fn available() usize {
    return driver_cdc.available();
}

/// Process USB events (MUST be called frequently from main loop!)
/// This is critical for USB to work - call as often as possible
/// Handles enumeration, control requests, and data transfers
pub fn poll() void {
    usb_dev.task(false) catch {};
}

// Buffer for formatted printing
var print_buffer: [2048]u8 = undefined;

/// Send formatted string over USB (like printf)
/// Returns true if successful
pub fn printf(comptime fmt: []const u8, args: anytype) bool {
    const text = std.fmt.bufPrint(&print_buffer, fmt, args) catch return false;
    return send(text);
}

//TODO: line buffering (accumulate chars until enter is pressed)
//TODO: echo chars back to the terminal
//TODO: handle special chars and keys (backspace, ctrl + c)
//TODO: ANSI escape code handling for proper terminal interaction
