const std = @import("std");
const microzig = @import("microzig");
const board = microzig.board;
const hal = microzig.hal;
const usb = hal.usb;
const mclk = hal.clocks.mclk;
const gclk = hal.clocks.gclk;

const io_types = microzig.chip.types.peripherals;

const peripherals = microzig.chip.peripherals;
const MCLK = peripherals.MCLK;
const GCLK = peripherals.GCLK;
const USB = peripherals.USB;
const NVMCTRL = struct {
    pub const SW0: *volatile io_types.FUSES.SW0_FUSES = @ptrFromInt(0x00800080);
};

// pins
const @"D+" = board.@"D+";
const @"D-" = board.@"D-";

// USB state
var endpoint_buffer_storage: [8][2][64]u8 align(4) = .{.{.{0} ** 64} ** 2} ** 8;
const endpoint_buffer: *align(4) volatile [8][2][64]u8 = &endpoint_buffer_storage;
const setup = std.mem.bytesAsValue(Setup, endpoint_buffer[0][0][0..8]);

var endpoint_table_storage: [8]io_types.USB.USB_DESCRIPTOR align(4) = undefined;
const endpoint_table: *align(4) volatile [8]io_types.USB.USB_DESCRIPTOR = &endpoint_table_storage;

var current_configuration: u8 = 0;

const cdc = struct {
    var current_connection: u8 = 0;
};

const Setup = extern struct {
    bmRequestType: packed struct(u8) {
        recipient: enum(u5) {
            device,
            interface,
            endpoint,
            other,
            _,
        },
        kind: enum(u2) {
            standard,
            class,
            vendor,
            _,
        },
        dir: enum(u1) {
            out,
            in,
        },
    },
    bRequest: u8,
    wValue: u16,
    wIndex: u16,
    wLength: u16,

    const standard = struct {
        const Request = enum(u8) {
            GET_STATUS = 0,
            CLEAR_FEATURE = 1,
            SET_FEATURE = 3,
            SET_ADDRESS = 5,
            GET_DESCRIPTOR = 6,
            SET_DESCRIPTOR = 7,
            GET_CONFIGURATION = 8,
            SET_CONFIGURATION = 9,
            GET_INTERFACE = 10,
            SET_INTERFACE = 11,
            SYNC_FRAME = 12,
            _,
        };
        const DescriptorType = enum(u8) {
            DEVICE = 1,
            CONFIGURATION = 2,
            STRING = 3,
            INTERFACE = 4,
            ENDPOINT = 5,
            DEVICE_QUALIFIER = 6,
            OTHER_SPEED_CONFIGURATION = 7,
            INTERFACE_POWER = 8,
            _,
        };
    };

    const cdc = struct {
        const Request = enum(u8) {
            SEND_ENCAPSULATED_COMMAND = 0x00,
            GET_ENCAPSULATED_RESPONSE = 0x01,
            SET_COMM_FEATURE = 0x02,
            GET_COMM_FEATURE = 0x03,
            CLEAR_COMM_FEATURE = 0x04,

            SET_AUX_LINE_STATE = 0x10,
            SET_HOOK_STATE = 0x11,
            PULSE_SETUP = 0x12,
            SEND_PULSE = 0x13,
            SET_PULSE_TIME = 0x14,
            RING_AUX_JACK = 0x15,

            SET_LINE_CODING = 0x20,
            GET_LINE_CODING = 0x21,
            SET_CONTROL_LINE_STATE = 0x22,
            SEND_BREAK = 0x23,

            SET_RINGER_PARMS = 0x30,
            GET_RINGER_PARMS = 0x31,
            SET_OPERATION_PARMS = 0x32,
            GET_OPERATION_PARMS = 0x33,
            SET_LINE_PARMS = 0x34,
            GET_LINE_PARMS = 0x35,
            DIAL_DIGITS = 0x36,
            SET_UNIT_PARAMETER = 0x37,
            GET_UNIT_PARAMETER = 0x38,
            CLEAR_UNIT_PARAMETER = 0x39,
            GET_PROFILE = 0x3A,

            SET_ETHERNET_MULTICAST_FILTERS = 0x40,
            SET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER = 0x41,
            GET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER = 0x42,
            SET_ETHERNET_PACKET_FILTER = 0x43,
            GET_ETHERNET_STATISTIC = 0x44,

            SET_ATM_DATA_FORMAT = 0x50,
            GET_ATM_DEVICE_STATISTICS = 0x51,
            SET_ATM_DEFAULT_VC = 0x52,
            GET_ATM_VC_STATISTICS = 0x53,

            GET_NTB_PARAMETERS = 0x80,
            GET_NET_ADDRESS = 0x81,
            SET_NET_ADDRESS = 0x82,
            GET_NTB_FORMAT = 0x83,
            SET_NTB_FORMAT = 0x84,
            GET_NTB_INPUT_SIZE = 0x85,
            SET_NTB_INPUT_SIZE = 0x86,
            GET_MAX_DATAGRAM_SIZE = 0x87,
            SET_MAX_DATAGRAM_SIZE = 0x88,
            GET_CRC_MODE = 0x89,
            SET_CRC_MODE = 0x8A,

            _,
        };
        const DescriptorType = enum(u8) {
            CS_INTERFACE = 0x24,
            CS_ENDPOINT = 0x25,
            _,
        };
    };
};

const EpType = enum(u3) {
    disabled,
    control,
    isochronous,
    bulk,
    interrupt,
    dual,
};

const pcksize = struct {
    const Size = enum(u3) {
        @"8",
        @"16",
        @"32",
        @"64",
        @"128",
        @"256",
        @"512",
        @"1023",
    };
};

//pub const microzig_options = .{
//    .logFn = log,
//};

pub fn main() !void {
    // Initialize pins
    @"D+".set_mux(.H);
    @"D-".set_mux(.H);

    // Load Pad Calibration
    const pads = NVMCTRL.SW0.SW0_WORD_1.read();
    USB.DEVICE.PADCAL.write(.{
        .TRANSP = switch (pads.USB_TRANSP) {
            0...std.math.maxInt(u5) - 1 => |transp| transp,
            std.math.maxInt(u5) => 29,
        },
        .reserved6 = 0,
        .TRANSN = switch (pads.USB_TRANSN) {
            0...std.math.maxInt(u5) - 1 => |transn| transn,
            std.math.maxInt(u5) => 5,
        },
        .reserved12 = 0,
        .TRIM = switch (pads.USB_TRIM) {
            0...std.math.maxInt(u3) - 1 => |trim| trim,
            std.math.maxInt(u3) => 3,
        },
        .padding = 0,
    });

    // Initialize clocks
    mclk.set_apb_mask(.{ .USB = .enabled });
    mclk.set_ahb_mask(.{ .USB = .enabled });
    gclk.set_peripheral_clk_gen(.GCLK_USB, .GCLK0);

    // enable USB
    @memset(std.mem.sliceAsBytes(endpoint_table), 0x00);
    microzig.cpu.dmb();
    USB.DEVICE.DESCADD.write(.{ .DESCADD = @intFromPtr(endpoint_table) });
    USB.DEVICE.CTRLA.modify(.{ .ENABLE = 0 });
    USB.DEVICE.CTRLB.modify(.{
        .SPDCONF = .{ .value = .FS },
        .DETACH = 0,
    });
    USB.DEVICE.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .RUNSTDBY = 0,
        .reserved7 = 0,
        .MODE = .{ .value = .DEVICE },
    });

    while (USB.DEVICE.SYNCBUSY.read().ENABLE != 0) {}

    while (true) {
        //tick();
    }
}

fn tick() void {
    // Check for End Of Reset flag
    if (USB.DEVICE.INTFLAG.read().EORST != 0) {
        // Clear the flag
        USB.DEVICE.INTFLAG.write(.{
            .SUSPEND = 0,
            .reserved2 = 0,
            .SOF = 0,
            .EORST = 1,
            .WAKEUP = 0,
            .EORSM = 0,
            .UPRSM = 0,
            .RAMACER = 0,
            .LPMNYET = 0,
            .LPMSUSP = 0,
            .padding = 0,
        });
        // Set Device address as 0
        USB.DEVICE.DADD.write(.{ .DADD = 0, .ADDEN = 1 });
        // Configure endpoint 0
        // Configure Endpoint 0 for Control IN and Control OUT
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPCFG.write(.{
            .EPTYPE0 = @intFromEnum(EpType.control),
            .reserved4 = 0,
            .EPTYPE1 = @intFromEnum(EpType.control),
            .padding = 0,
        });
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 0,
            .BK0RDY = 1,
            .BK1RDY = 0,
        });
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 0,
            .BK0RDY = 0,
            .BK1RDY = 1,
        });
        // Configure control OUT Packet size to 64 bytes
        // Set Multipacket size to 8 for control OUT and byte count to 0
        endpoint_table[0].DEVICE.DEVICE_DESC_BANK[0].DEVICE.PCKSIZE.write(.{
            .BYTE_COUNT = 0,
            .MULTI_PACKET_SIZE = 8,
            .SIZE = @intFromEnum(pcksize.Size.@"64"),
            .AUTO_ZLP = 0,
        });
        // Configure control IN Packet size to 64 bytes
        endpoint_table[0].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
            .BYTE_COUNT = 0,
            .MULTI_PACKET_SIZE = 0,
            .SIZE = @intFromEnum(pcksize.Size.@"64"),
            .AUTO_ZLP = 1,
        });
        // Configure the data buffer address for control OUT
        endpoint_table[0].DEVICE.DEVICE_DESC_BANK[0].DEVICE.ADDR.write(.{
            .ADDR = @intFromPtr(&endpoint_buffer[0][0]),
        });
        // Configure the data buffer address for control IN
        endpoint_table[0].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
            .ADDR = @intFromPtr(&endpoint_buffer[0][1]),
        });
        microzig.cpu.dmb();
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 0,
            .BK0RDY = 1,
            .BK1RDY = 0,
        });

        // Reset current configuration value to 0
        current_configuration = 0;
        cdc.current_connection = 0;
    }

    // Check for End Of SETUP flag
    if (USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.read().RXSTP != 0) setup: {
        // Clear the Received Setup flag
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.write(.{
            .TRCPT0 = 0,
            .TRCPT1 = 0,
            .TRFAIL0 = 0,
            .TRFAIL1 = 0,
            .RXSTP = 1,
            .STALL0 = 0,
            .STALL1 = 0,
            .padding = 0,
        });

        // Clear the Bank 0 ready flag on Control OUT
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 0,
            .BK0RDY = 1,
            .BK1RDY = 0,
        });

        microzig.cpu.dmb();
        switch (setup.bmRequestType.kind) {
            .standard => switch (setup.bmRequestType.recipient) {
                .device => switch (setup.bmRequestType.dir) {
                    .out => switch (@as(Setup.standard.Request, @enumFromInt(setup.bRequest))) {
                        .SET_ADDRESS => if (setup.wIndex == 0 and setup.wLength == 0) {
                            if (std.math.cast(u7, setup.wValue)) |addr| {
                                write_control(&[0]u8{});
                                USB.DEVICE.DADD.write(.{ .DADD = addr, .ADDEN = 1 });
                                break :setup;
                            }
                        },
                        .SET_CONFIGURATION => {
                            if (std.math.cast(u8, setup.wValue)) |config| {
                                write_control(&[0]u8{});
                                current_configuration = config;
                                cdc.current_connection = 0;
                                switch (config) {
                                    0 => {},
                                    1 => {
                                        USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPCFG.write(.{
                                            .EPTYPE0 = @intFromEnum(EpType.disabled),
                                            .reserved4 = 0,
                                            .EPTYPE1 = @intFromEnum(EpType.interrupt),
                                            .padding = 0,
                                        });
                                        endpoint_table[1].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
                                            .BYTE_COUNT = 0,
                                            .MULTI_PACKET_SIZE = 0,
                                            .SIZE = @intFromEnum(pcksize.Size.@"8"),
                                            .AUTO_ZLP = 1,
                                        });
                                        endpoint_table[1].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
                                            .ADDR = @intFromPtr(&endpoint_buffer[1][1]),
                                        });
                                        microzig.cpu.dmb();
                                        USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPSTATUSCLR.write(.{
                                            .DTGLOUT = 0,
                                            .DTGLIN = 0,
                                            .CURBK = 0,
                                            .reserved4 = 0,
                                            .STALLRQ0 = 0,
                                            .STALLRQ1 = 0,
                                            .BK0RDY = 0,
                                            .BK1RDY = 1,
                                        });

                                        USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPCFG.write(.{
                                            .EPTYPE0 = @intFromEnum(EpType.bulk),
                                            .reserved4 = 0,
                                            .EPTYPE1 = @intFromEnum(EpType.bulk),
                                            .padding = 0,
                                        });
                                        endpoint_table[2].DEVICE.DEVICE_DESC_BANK[0].DEVICE.PCKSIZE.write(.{
                                            .BYTE_COUNT = 0,
                                            .MULTI_PACKET_SIZE = 0,
                                            .SIZE = @intFromEnum(pcksize.Size.@"64"),
                                            .AUTO_ZLP = 0,
                                        });
                                        endpoint_table[2].DEVICE.DEVICE_DESC_BANK[0].DEVICE.ADDR.write(.{
                                            .ADDR = @intFromPtr(&endpoint_buffer[2][0]),
                                        });
                                        microzig.cpu.dmb();
                                        USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSSET.write(.{
                                            .DTGLOUT = 0,
                                            .DTGLIN = 0,
                                            .CURBK = 0,
                                            .reserved4 = 0,
                                            .STALLRQ0 = 0,
                                            .STALLRQ1 = 0,
                                            .BK0RDY = 1,
                                            .BK1RDY = 0,
                                        });
                                        endpoint_table[2].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
                                            .BYTE_COUNT = 0,
                                            .MULTI_PACKET_SIZE = 0,
                                            .SIZE = @intFromEnum(pcksize.Size.@"64"),
                                            .AUTO_ZLP = 1,
                                        });
                                        endpoint_table[2].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
                                            .ADDR = @intFromPtr(&endpoint_buffer[2][1]),
                                        });
                                        microzig.cpu.dmb();
                                        USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSCLR.write(.{
                                            .DTGLOUT = 0,
                                            .DTGLIN = 0,
                                            .CURBK = 0,
                                            .reserved4 = 0,
                                            .STALLRQ0 = 0,
                                            .STALLRQ1 = 0,
                                            .BK0RDY = 0,
                                            .BK1RDY = 1,
                                        });
                                    },
                                    else => {},
                                }
                                break :setup;
                            }
                        },
                        else => {},
                    },
                    .in => switch (@as(Setup.standard.Request, @enumFromInt(setup.bRequest))) {
                        .GET_DESCRIPTOR => {
                            switch (@as(Setup.standard.DescriptorType, @enumFromInt(setup.wValue >> 8))) {
                                .DEVICE => if (@as(u8, @truncate(setup.wValue)) == 0 and setup.wIndex == 0) {
                                    write_control(&[0x12]u8{
                                        0x12, @intFromEnum(Setup.standard.DescriptorType.DEVICE), //
                                        0x00, 0x02, //
                                        0xef, 0x02, 0x01, //
                                        64, //
                                        0x9a, 0x23, // Adafruit
                                        0x34, 0x00, //
                                        0x01, 0x42, // 42.01
                                        0x01, 0x02, 0x00, //
                                        0x01, //
                                    });
                                    break :setup;
                                },
                                .CONFIGURATION => if (setup.wIndex == 0) {
                                    switch (@as(u8, @truncate(setup.wValue))) {
                                        0 => {
                                            write_control(&[0x003e]u8{
                                                0x09, @intFromEnum(Setup.standard.DescriptorType.CONFIGURATION), //
                                                0x3e, 0x00, //
                                                0x02, 0x01, 0x00, //
                                                0x80, 500 / 2, //
                                                //
                                                0x09, @intFromEnum(Setup.standard.DescriptorType.INTERFACE), //
                                                0x00, 0x00, 0x01, //
                                                0x02, 0x02, 0x00, //
                                                0x00, //
                                                //
                                                0x05, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x00, //
                                                0x10, 0x01, //
                                                //
                                                0x04, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x02, //
                                                0x00, //
                                                //
                                                0x05, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x06, //
                                                0x00, 0x01, //
                                                //
                                                0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                0x81, 0x03, //
                                                8, 0, std.math.maxInt(u8), //
                                                //
                                                0x09, @intFromEnum(Setup.standard.DescriptorType.INTERFACE), //
                                                0x01, 0x00, 0x02, //
                                                0x0a, 0x02, 0x00, //
                                                0x00, //
                                                //
                                                0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                0x02, 0x02, //
                                                64, 0, 0, //
                                                //
                                                0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                0x82, 0x02, //
                                                64, 0, 0, //
                                            });
                                            break :setup;
                                        },
                                        else => {},
                                    }
                                },
                                .STRING => switch (@as(u8, @truncate(setup.wValue))) {
                                    0 => switch (setup.wIndex) {
                                        0 => {
                                            write_control(&[4]u8{
                                                4, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                0x09, 0x04, // English (United States)
                                            });
                                            break :setup;
                                        },
                                        else => {},
                                    },
                                    1 => switch (setup.wIndex) {
                                        0x0409 => { // English (United States)
                                            const manufacturer_name = comptime make_string_literal("Zig Embedded Group");
                                            write_control(manufacturer_name);
                                            break :setup;
                                        },
                                        else => {},
                                    },
                                    2 => switch (setup.wIndex) {
                                        0x0409 => { // English (United States)
                                            const name = comptime make_string_literal("SYCL Badge 2024");
                                            write_control(name);
                                            break :setup;
                                        },
                                        else => {},
                                    },
                                    else => {},
                                },
                                else => {},
                            }
                        },
                        else => {},
                    },
                },
                .interface => {},
                .endpoint => {},
                .other => {},
                _ => {},
            },
            .class => switch (setup.bmRequestType.recipient) {
                .device => {},
                .interface => switch (setup.wIndex) {
                    0 => switch (setup.bmRequestType.dir) {
                        .out => switch (@as(Setup.cdc.Request, @enumFromInt(setup.bRequest))) {
                            .SET_LINE_CODING => if (setup.wValue == 0) {
                                write_control(&[0]u8{});
                                break :setup;
                            },
                            .SET_CONTROL_LINE_STATE => if (setup.wLength == 0) {
                                if (std.math.cast(u8, setup.wValue)) |conn| {
                                    cdc.current_connection = conn;
                                    write_control(&[0]u8{});
                                    break :setup;
                                }
                            },
                            else => {},
                        },
                        .in => {},
                    },
                    else => {},
                },
                .endpoint => {},
                .other => {},
                _ => {},
            },
            .vendor => {},
            _ => {},
        }
        // Stall control endpoint
        USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 1,
            .BK0RDY = 0,
            .BK1RDY = 0,
        });

        if (setup.bmRequestType.kind == .standard and setup.bmRequestType.dir == .in and
            setup.bRequest == @intFromEnum(Setup.standard.Request.GET_DESCRIPTOR) and
            setup.wValue >> 8 == @intFromEnum(Setup.standard.DescriptorType.DEVICE_QUALIFIER))
        {} else {
            std.log.scoped(.usb).err("Unhandled request: 0x{X:0<2}", .{setup.bRequest});
        }
    }
}

fn write_control(data: []const u8) void {
    write(0, data[0..@min(data.len, setup.wLength)]);
}

fn write(ep: u3, data: []const u8) void {
    const ep_buffer = &endpoint_buffer[ep][1];
    @memcpy(ep_buffer[0..data.len], data);
    microzig.cpu.dmb();

    const ep_descs: *volatile [8]io_types.USB.USB_DESCRIPTOR = @ptrFromInt(USB.DEVICE.DESCADD.read().DESCADD);
    // Set the buffer address for ep data
    const ep_desc = &ep_descs[ep].DEVICE.DEVICE_DESC_BANK[1].DEVICE;
    ep_desc.ADDR.write(.{ .ADDR = @intFromPtr(ep_buffer) });
    // Set the byte count as zero
    // Set the multi packet size as zero for multi-packet transfers where length > ep size
    ep_desc.PCKSIZE.modify(.{
        .BYTE_COUNT = @as(u14, @intCast(data.len)),
        .MULTI_PACKET_SIZE = 0,
    });
    // Clear the transfer complete flag
    const ep_ctrl = &USB.DEVICE.DEVICE_ENDPOINT[ep].DEVICE;
    ep_ctrl.EPINTFLAG.write(.{
        .TRCPT0 = 0,
        .TRCPT1 = 1,
        .TRFAIL0 = 0,
        .TRFAIL1 = 0,
        .RXSTP = 0,
        .STALL0 = 0,
        .STALL1 = 0,
        .padding = 0,
    });
    // Set the bank as ready
    ep_ctrl.EPSTATUSSET.write(.{
        .DTGLOUT = 0,
        .DTGLIN = 0,
        .CURBK = 0,
        .reserved4 = 0,
        .STALLRQ0 = 0,
        .STALLRQ1 = 0,
        .BK0RDY = 0,
        .BK1RDY = 1,
    });
    // Wait for transfer to complete
    while (ep_ctrl.EPINTFLAG.read().TRCPT1 == 0) {}
}

fn make_string_literal(comptime str: []const u8) []const u8 {
    const len = str.len + 2;
    var buf: [len]u8 = undefined;
    buf[0] = len;
    buf[1] = @intFromEnum(Setup.standard.DescriptorType.STRING);
    for (buf[2..], 0..) |*b, i|
        b.* = if (i % 2 == 0) str[i >> 1] else 0x00;

    const buf_const = buf;
    return &buf_const;
}

//pub fn log(
//    comptime level: std.log.Level,
//    comptime scope: @Type(.EnumLiteral),
//    comptime format: []const u8,
//    args: anytype,
//) void {
//    out.print("[" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ "): " ++ format ++ "\n", args) catch return;
//}

//const InOutError = error{NoConnection};
//pub const out: std.io.Writer(void, InOutError, struct {
//    fn write(_: void, data: []const u8) InOutError!usize {
//        if (usb.cdc.current_connection == 0) return error.NoConnection;
//        if (data.len == 0) return data.len;
//        var line_it = std.mem.splitScalar(u8, data, '\n');
//        var first = true;
//        while (line_it.next()) |line| {
//            if (!first) usb.write(2, "\r\n");
//            var chunk_it = std.mem.window(u8, line, 64, 64);
//            while (chunk_it.next()) |chunk| usb.write(2, chunk);
//            first = false;
//        }
//        return data.len;
//    }
//}.write) = .{ .context = {} };
