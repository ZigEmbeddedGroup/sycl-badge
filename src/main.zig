const builtin = @import("builtin");
const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const microzig = @import("microzig");
const Port = @import("Port.zig");
const sleep = microzig.core.experimental.debug.busy_sleep;
const std = @import("std");

pub const std_options = struct {
    pub const log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
    };
    pub const logFn = log;
};

pub const microzig_options = struct {
    const interrupts = .{
        .EIC_EIC_EXTINT_0 = .{ .C = &buttonInterruptTest },
    };
};

const GCLK = struct {
    const PCH = struct {
        const OSCCTRL_DFLL48 = 0;
        const OSCCTRL_FDPLL0 = 1;
        const OSCCTRL_FDPLL1 = 2;
        const OSCCTRL_FDPLL0_32K = 3;
        const OSCCTRL_FDPLL1_32K = 3;
        const SDHC0_SLOW = 3;
        const SDHC1_SLOW = 3;
        const SERCOM0_SLOW = 3;
        const SERCOM1_SLOW = 3;
        const SERCOM2_SLOW = 3;
        const SERCOM3_SLOW = 3;
        const SERCOM4_SLOW = 3;
        const SERCOM5_SLOW = 3;
        const SERCOM6_SLOW = 3;
        const SERCOM7_SLOW = 3;
        const EIC = 4;
        const FREQM_MSR = 5;
        const FREQM_REF = 6;
        const SERCOM0_CORE = 7;
        const SERCOM1_CORE = 8;
        const TC0 = 9;
        const TC1 = 9;
        const USB = 10;
        const EVSYS0 = 11;
        const EVSYS1 = 12;
        const EVSYS2 = 13;
        const EVSYS3 = 14;
        const EVSYS4 = 15;
        const EVSYS5 = 16;
        const EVSYS6 = 17;
        const EVSYS7 = 18;
        const EVSYS8 = 19;
        const EVSYS9 = 20;
        const EVSYS10 = 21;
        const EVSYS11 = 22;
        const SERCOM2_CORE = 23;
        const SERCOM3_CORE = 24;
        const TCC0_CORE = 25;
        const TCC1_CORE = 25;
        const TC2 = 26;
        const TC3 = 26;
        const CAN0 = 27;
        const CAN1 = 28;
        const TCC2 = 29;
        const TCC3 = 29;
        const TC4 = 30;
        const TC5 = 30;
        const PDEC = 31;
        const AC = 32;
        const CCL = 33;
        const SERCOM4_CORE = 34;
        const SERCOM5_CORE = 35;
        const SERCOM6_CORE = 36;
        const SERCOM7_CORE = 37;
        const TCC4 = 38;
        const TC6 = 39;
        const TC7 = 39;
        const ADC0 = 40;
        const ADC1 = 41;
        const DAC = 42;
        const I2C = .{ 43, 44 };
        const SDHC0 = 45;
        const SDHC1 = 46;
        const CM4_TRACE = 47;
    };
};

fn buttonInterruptTest() callconv(.C) void {
    std.log.scoped(.interrupt).info("buttonInterruptTest();", .{});
}

const InOutError = error{NoConnection};
pub const in: std.io.Reader(void, InOutError, struct {
    fn read(_: void, buffer: []u8) InOutError!usize {
        if (usb.cdc.current_connection == 0) return error.NoConnection;
        return usb.read(2, buffer).len;
    }
}.read) = .{ .context = {} };
pub const out: std.io.Writer(void, InOutError, struct {
    fn write(_: void, data: []const u8) InOutError!usize {
        if (usb.cdc.current_connection == 0) return error.NoConnection;
        if (data.len == 0) return data.len;
        var line_it = std.mem.splitScalar(u8, data, '\n');
        var first = true;
        while (line_it.next()) |line| {
            if (!first) usb.write(2, "\r\n");
            var chunk_it = std.mem.window(u8, line, 64, 64);
            while (chunk_it.next()) |chunk| usb.write(2, chunk);
            first = false;
        }
        return data.len;
    }
}.write) = .{ .context = {} };

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    out.print("[" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ "): " ++ format ++ "\n", args) catch return;
}

//:lib/samd51/include/samd51j19a.h
const HSRAM = struct {
    const ADDR: *align(4) [SIZE]u8 = @ptrFromInt(0x20000000);
    const SIZE = 0x00030000;
};

const NVMCTRL = struct {
    const SW0: *volatile [4]u32 = @ptrFromInt(0x00800080); // (NVMCTRL) SW0 Base Address
    const SW1: *volatile [4]u32 = @ptrFromInt(0x00800090); // (NVMCTRL) SW1 Base Address
    const SW2: *volatile [4]u32 = @ptrFromInt(0x008000A0); // (NVMCTRL) SW2 Base Address
    const SW3: *volatile [4]u32 = @ptrFromInt(0x008000B0); // (NVMCTRL) SW3 Base Address
    const SW4: *volatile [4]u32 = @ptrFromInt(0x008000C0); // (NVMCTRL) SW4 Base Address
    const SW5: *volatile [4]u32 = @ptrFromInt(0x008000D0); // (NVMCTRL) SW5 Base Address
    const SW6: *volatile [4]u32 = @ptrFromInt(0x008000E0); // (NVMCTRL) SW6 Base Address
    const SW7: *volatile [4]u32 = @ptrFromInt(0x008000F0); // (NVMCTRL) SW7 Base Address
};

const USB = struct {
    //:lib/samd51/include/component/nvmctrl.h
    const FUSES: *volatile microzig.mmio.Mmio(packed struct(u32) {
        TRANSN: u5,
        TRANSP: u5,
        TRIM: u3,
        reserved: u19,
    }) = @ptrCast(&NVMCTRL.SW0[1]);
};

//:src/init_samd51.c
fn system_init() void {
    // Automatic wait states.
    io.NVMCTRL.CTRLA.modify(.{ .AUTOWS = 1 });

    // Software reset the module to ensure it is re-initialized correctly
    io.GCLK.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    // wait for reset to complete
    while (io.GCLK.SYNCBUSY.read().SWRST != 0) {}

    // Temporarily switch the CPU to the internal 32k oscillator while we
    // reconfigure the DFLL.
    io.GCLK.GENCTRL[0].write(.{
        .SRC = .{ .value = .OSCULP32K },
        .reserved8 = 0,
        .GENEN = 1,
        .IDC = 0,
        .OOV = 0,
        .OE = 1,
        .DIVSEL = .{ .value = .DIV1 },
        .RUNSTDBY = 0,
        .reserved16 = 0,
        .DIV = 0,
    });
    // Wait for synchronization
    while ((io.GCLK.SYNCBUSY.read().GENCTRL.raw & @intFromEnum(io_types.GCLK.GCLK_SYNCBUSY__GENCTRL.GCLK0)) != 0) {}

    // Configure the DFLL for USB clock recovery.
    io.OSCCTRL.DFLLCTRLA.write(.{
        .reserved1 = 0,
        .ENABLE = 0,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
    });
    io.OSCCTRL.DFLLMUL.write(.{
        .MUL = 0xBB80,
        .FSTEP = 1,
        .reserved26 = 0,
        .CSTEP = 1,
    });
    // Wait for synchronization
    while (io.OSCCTRL.DFLLSYNC.read().DFLLMUL != 0) {}

    io.OSCCTRL.DFLLCTRLB.write(.{
        .MODE = 0,
        .STABLE = 0,
        .LLAW = 0,
        .USBCRM = 0,
        .CCDIS = 0,
        .QLDIS = 0,
        .BPLCKC = 0,
        .WAITLOCK = 0,
    });
    // Wait for synchronization
    while (io.OSCCTRL.DFLLSYNC.read().DFLLCTRLB != 0) {}

    io.OSCCTRL.DFLLCTRLA.write(.{
        .reserved1 = 0,
        .ENABLE = 1,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
    });
    // Wait for synchronization
    while (io.OSCCTRL.DFLLSYNC.read().ENABLE != 0) {}

    io.OSCCTRL.DFLLVAL.modify(.{});
    // Wait for synchronization
    while (io.OSCCTRL.DFLLSYNC.read().DFLLVAL != 0) {}

    io.OSCCTRL.DFLLCTRLB.write(.{
        .MODE = 0,
        .STABLE = 0,
        .LLAW = 0,
        .USBCRM = 1,
        .CCDIS = 1,
        .QLDIS = 0,
        .BPLCKC = 0,
        .WAITLOCK = 1,
    });
    // Wait for synchronization
    while (io.OSCCTRL.STATUS.read().DFLLRDY == 0) {}

    // 5) Switch Generic Clock Generator 0 to DFLL48M. CPU will run at 48MHz.
    io.GCLK.GENCTRL[0].write(.{
        .SRC = .{ .value = .DFLL },
        .reserved8 = 0,
        .GENEN = 1,
        .IDC = 1,
        .OOV = 0,
        .OE = 1,
        .DIVSEL = .{ .value = .DIV1 },
        .RUNSTDBY = 0,
        .reserved16 = 0,
        .DIV = 0,
    });
    // Wait for synchronization
    while ((io.GCLK.SYNCBUSY.read().GENCTRL.raw & @intFromEnum(io_types.GCLK.GCLK_SYNCBUSY__GENCTRL.GCLK0)) != 0) {}

    // Now that all system clocks are configured, we can set CLKDIV.
    // These values are normally the ones present after Reset.
    io.MCLK.CPUDIV.write(.{ .DIV = .{ .value = .DIV1 } });

    //SysTick_Config(1000);
}

//:src/main.c
pub fn main() !void {
    system_init();
    microzig.cpu.dmb();
    usb.init();

    // ID detection
    const id_port = Port.D13;
    id_port.setDir(.out);
    id_port.write(true);
    id_port.configPtr().write(.{
        .PMUXEN = 0,
        .INEN = 1,
        .PULLEN = 1,
        .reserved6 = 0,
        .DRVSTR = 0,
        .padding = 0,
    });

    // button testing
    Port.BUTTON_OUT.setDir(.in);
    Port.BUTTON_OUT.configPtr().write(.{
        .PMUXEN = 0,
        .INEN = 1,
        .PULLEN = 0,
        .reserved6 = 0,
        .DRVSTR = 0,
        .padding = 0,
    });
    Port.BUTTON_CLK.setDir(.out);
    Port.BUTTON_CLK.write(true);
    Port.BUTTON_LATCH.setDir(.out);
    Port.BUTTON_LATCH.write(false);
    io.MCLK.APBAMASK.modify(.{ .EIC_ = 1 });

    var was_ready = false;
    while (true) {
        usb.tick();

        input: {
            var input_buffer: [64]u8 = undefined;
            const data = input_buffer[0 .. in.read(&input_buffer) catch |err| {
                switch (err) {
                    error.NoConnection => was_ready = false,
                }
                break :input;
            }];
            if (!was_ready) {
                std.log.info("Hello, {s}!", .{"world"});
                was_ready = true;
            }
            if (data.len > 0) for (data) |c| switch (c) {
                else => out.writeByte(c) catch break :input,
                'B' - '@' => utils.resetIntoBootloader(),
                'C' - '@' => {
                    // Use generator 11 as reference
                    io.GCLK.GENCTRL[11].write(.{
                        .SRC = .{ .value = .OSCULP32K },
                        .reserved8 = 0,
                        .GENEN = 1,
                        .IDC = 0,
                        .OOV = 0,
                        .OE = 0,
                        .DIVSEL = .{ .value = .DIV2 },
                        .RUNSTDBY = 0,
                        .reserved16 = 0,
                        .DIV = 8,
                    });
                    io.GCLK.PCHCTRL[GCLK.PCH.FREQM_REF].write(.{
                        .GEN = .{ .value = .GCLK11 },
                        .reserved6 = 0,
                        .CHEN = 1,
                        .WRTLOCK = 0,
                        .padding = 0,
                    });

                    // Measure generator 10
                    io.GCLK.GENCTRL[10].write(.{
                        .SRC = .{ .value = .XOSC32K },
                        .reserved8 = 0,
                        .GENEN = 1,
                        .IDC = 0,
                        .OOV = 0,
                        .OE = 0,
                        .DIVSEL = .{ .value = .DIV1 },
                        .RUNSTDBY = 0,
                        .reserved16 = 0,
                        .DIV = 0,
                    });
                    io.GCLK.PCHCTRL[GCLK.PCH.FREQM_MSR].write(.{
                        .GEN = .{ .value = .GCLK10 },
                        .reserved6 = 0,
                        .CHEN = 1,
                        .WRTLOCK = 0,
                        .padding = 0,
                    });

                    // Reset Frequency Meter
                    io.MCLK.APBAMASK.modify(.{ .FREQM_ = 1 });
                    io.FREQM.CTRLA.write(.{
                        .SWRST = 1,
                        .ENABLE = 0,
                        .padding = 0,
                    });
                    while (io.FREQM.SYNCBUSY.read().SWRST != 0) {}

                    // Run Frequency Meter
                    io.FREQM.CFGA.write(.{
                        .REFNUM = 8,
                        .padding = 0,
                    });
                    io.FREQM.CTRLA.write(.{
                        .SWRST = 0,
                        .ENABLE = 1,
                        .padding = 0,
                    });
                    while (io.FREQM.SYNCBUSY.read().ENABLE != 0) {}
                    io.FREQM.CTRLB.write(.{
                        .START = 1,
                        .padding = 0,
                    });
                    while (io.FREQM.STATUS.read().BUSY != 0) {}
                    if (io.FREQM.STATUS.read().OVF == 0) {
                        std.log.info("{}Hz", .{(io.FREQM.VALUE.read().VALUE + 1) * 8});
                    }
                },
                '\r' => out.writeByte('\n') catch break :input,
                'P' - '@' => @panic("user"),
                'R' - '@' => utils.resetIntoApp(),
                'S' - '@' => for (0.., &io.PORT.GROUP) |group_i, *group|
                    std.log.info("IN{d} = 0x{X:0>8}", .{ group_i, group.IN.read().IN }),
                0x7f => out.writeAll("\x1B[D\x1B[K") catch break :input,
            };
        }
    }
}

const usb = struct {
    var endpoint_buffer: [8][2][64]u8 align(4) = .{.{.{0} ** 64} ** 2} ** 8;
    const setup = std.mem.bytesAsValue(Setup, endpoint_buffer[0][0][0..8]);

    var endpoint_table: [8]io_types.USB.USB_DESCRIPTOR align(4) = .{.{ .DEVICE = .{
        .DEVICE_DESC_BANK = .{.{ .DEVICE = .{
            .ADDR = .{ .raw = 0 },
            .PCKSIZE = .{ .raw = 0 },
            .EXTREG = .{ .raw = 0 },
            .STATUS_BK = .{ .raw = 0 },
            .padding = .{0} ** 5,
        } }} ** 2,
    } }} ** 8;
    const endpoint_table_addr: *align(4) volatile [8]io_types.USB.USB_DESCRIPTOR = &endpoint_table;

    var current_configuration: u8 = 0;

    const cdc = struct {
        var current_connection: u8 = 0;
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

    //:src/cdc_enumerate.c
    fn AT91F_InitUSB() void {
        Port.@"D-".setMux(.H);
        Port.@"D+".setMux(.H);

        io.GCLK.PCHCTRL[GCLK.PCH.USB].write(.{
            .GEN = .{ .value = .GCLK0 },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.MCLK.AHBMASK.modify(.{ .USB_ = 1 });
        io.MCLK.APBBMASK.modify(.{ .USB_ = 1 });
        while ((io.GCLK.SYNCBUSY.read().GENCTRL.raw & @intFromEnum(io_types.GCLK.GCLK_SYNCBUSY__GENCTRL.GCLK0)) != 0) {}

        // Reset
        io.USB.DEVICE.CTRLA.modify(.{ .SWRST = 1 });
        // Sync wait
        while (io.USB.DEVICE.SYNCBUSY.read().SWRST != 0) {}

        // Load Pad Calibration
        const pads = USB.FUSES.read();
        io.USB.DEVICE.PADCAL.write(.{
            .TRANSP = switch (pads.TRANSP) {
                0...std.math.maxInt(u5) - 1 => |transn| transn,
                std.math.maxInt(u5) => 29,
            },
            .reserved6 = 0,
            .TRANSN = switch (pads.TRANSN) {
                0...std.math.maxInt(u5) - 1 => |transn| transn,
                std.math.maxInt(u5) => 5,
            },
            .reserved12 = 0,
            .TRIM = switch (pads.TRIM) {
                0...std.math.maxInt(u3) - 1 => |transn| transn,
                std.math.maxInt(u3) => 3,
            },
            .padding = 0,
        });

        // Set the configuration
        // Set mode to Device mode
        // Enable Run in Standby
        io.USB.DEVICE.CTRLA.modify(.{
            .MODE = .{ .value = .DEVICE },
            .RUNSTDBY = 1,
        });
        // Set the descriptor address
        io.USB.DEVICE.DESCADD.write(.{
            .DESCADD = @intFromPtr(&endpoint_table),
        });
        // Set speed configuration to Full speed
        // Attach to the USB host
        io.USB.DEVICE.CTRLB.modify(.{
            .SPDCONF = .{ .value = .FS },
            .DETACH = 0,
        });
    }

    pub fn init() void {
        // Initialize USB
        AT91F_InitUSB();
        io.USB.HOST.CTRLA.modify(.{ .ENABLE = 1 });
    }

    fn tick() void {
        // Check for End Of Reset flag
        if (io.USB.DEVICE.INTFLAG.read().EORST != 0) {
            // Clear the flag
            io.USB.DEVICE.INTFLAG.write(.{
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
            io.USB.DEVICE.DADD.write(.{ .DADD = 0, .ADDEN = 1 });
            // Configure endpoint 0
            // Configure Endpoint 0 for Control IN and Control OUT
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPCFG.write(.{
                .EPTYPE0 = @intFromEnum(EpType.control),
                .reserved4 = 0,
                .EPTYPE1 = @intFromEnum(EpType.control),
                .padding = 0,
            });
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
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
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
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
        if (io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.read().RXSTP != 0) setup: {
            // Clear the Received Setup flag
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.write(.{
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
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });

            switch (setup.bmRequestType.kind) {
                .standard => switch (setup.bmRequestType.recipient) {
                    .device => switch (setup.bmRequestType.dir) {
                        .out => switch (@as(Setup.standard.Request, @enumFromInt(setup.bRequest))) {
                            .SET_ADDRESS => if (setup.wIndex == 0 and setup.wLength == 0) {
                                if (std.math.cast(u7, setup.wValue)) |addr| {
                                    writeControl(&[0]u8{});
                                    io.USB.DEVICE.DADD.write(.{ .DADD = addr, .ADDEN = 1 });
                                    break :setup;
                                }
                            },
                            .SET_CONFIGURATION => {
                                if (std.math.cast(u8, setup.wValue)) |config| {
                                    writeControl(&[0]u8{});
                                    current_configuration = config;
                                    cdc.current_connection = 0;
                                    switch (config) {
                                        0 => {},
                                        1 => {
                                            io.USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPCFG.write(.{
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
                                            io.USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPSTATUSCLR.write(.{
                                                .DTGLOUT = 0,
                                                .DTGLIN = 0,
                                                .CURBK = 0,
                                                .reserved4 = 0,
                                                .STALLRQ0 = 0,
                                                .STALLRQ1 = 0,
                                                .BK0RDY = 0,
                                                .BK1RDY = 1,
                                            });

                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPCFG.write(.{
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
                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSSET.write(.{
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
                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSCLR.write(.{
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
                                        writeControl(&[0x12]u8{
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
                                                writeControl(&[0x003e]u8{
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
                                                writeControl(&[4]u8{
                                                    4, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    0x09, 0x04, // English (United States)
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        },
                                        1 => switch (setup.wIndex) {
                                            0x0409 => { // English (United States)
                                                writeControl(&[38]u8{
                                                    38, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    'Z', 0x00, //
                                                    'i', 0x00, //
                                                    'g', 0x00, //
                                                    ' ', 0x00, //
                                                    'E', 0x00, //
                                                    'm', 0x00, //
                                                    'b', 0x00, //
                                                    'e', 0x00, //
                                                    'd', 0x00, //
                                                    'd', 0x00, //
                                                    'e', 0x00, //
                                                    'd', 0x00, //
                                                    ' ', 0x00, //
                                                    'G', 0x00, //
                                                    'r', 0x00, //
                                                    'o', 0x00, //
                                                    'u', 0x00, //
                                                    'p', 0x00, //
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        },
                                        2 => switch (setup.wIndex) {
                                            0x0409 => { // English (United States)
                                                writeControl(&[16]u8{
                                                    16, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    'B', 0x00, //
                                                    'a', 0x00, //
                                                    'd', 0x00, //
                                                    'g', 0x00, //
                                                    'e', 0x00, //
                                                    'L', 0x00, //
                                                    'C', 0x00, //
                                                });
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
                                    writeControl(&[0]u8{});
                                    break :setup;
                                },
                                .SET_CONTROL_LINE_STATE => if (setup.wLength == 0) {
                                    if (std.math.cast(u8, setup.wValue)) |conn| {
                                        cdc.current_connection = conn;
                                        writeControl(&[0]u8{});
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
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
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

    fn read(ep: u3, data: []u8) []u8 {
        const ep_buffer = &endpoint_buffer[ep][0];
        const ep_descs: *volatile [8]io_types.USB.USB_DESCRIPTOR = @ptrFromInt(io.USB.DEVICE.DESCADD.read().DESCADD);
        const ep_desc = &ep_descs[ep].DEVICE.DEVICE_DESC_BANK[0].DEVICE;
        const ep_ctrl = &io.USB.DEVICE.DEVICE_ENDPOINT[ep].DEVICE;

        if (ep_ctrl.EPSTATUS.read().BK0RDY != 0) {
            const len = ep_desc.PCKSIZE.read().BYTE_COUNT;
            @memcpy(data[0..len], ep_buffer[0..len]);
            ep_ctrl.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });
            return data[0..len];
        }
        return data[0..0];
    }

    fn writeControl(data: []const u8) void {
        write(0, data[0..@min(data.len, setup.wLength)]);
    }

    fn write(ep: u3, data: []const u8) void {
        const ep_buffer = &endpoint_buffer[ep][1];
        @memcpy(ep_buffer[0..data.len], data);

        const ep_descs: *volatile [8]io_types.USB.USB_DESCRIPTOR = @ptrFromInt(io.USB.DEVICE.DESCADD.read().DESCADD);
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
        const ep_ctrl = &io.USB.DEVICE.DEVICE_ENDPOINT[ep].DEVICE;
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
};

//:src/utils.c
const utils = struct {
    const DBL_TAP_PTR: *volatile u32 = std.mem.bytesAsValue(u32, HSRAM.ADDR[HSRAM.ADDR.len - 4 ..]);
    const DBL_TAP_MAGIC = 0xf01669ef;
    const DBL_TAP_MAGIC_QUICK_BOOT = 0xf02669ef;

    pub fn resetIntoApp() noreturn {
        DBL_TAP_PTR.* = DBL_TAP_MAGIC_QUICK_BOOT;
        NVIC_SystemReset();
    }

    pub fn resetIntoBootloader() noreturn {
        DBL_TAP_PTR.* = DBL_TAP_MAGIC;
        NVIC_SystemReset();
    }

    fn NVIC_SystemReset() noreturn {
        microzig.cpu.dsb();
        microzig.cpu.peripherals.SCB.AIRCR.write(.{
            .reserved1 = 0,
            .VECTCLRACTIVE = 0,
            .SYSRESETREQ = 1,
            .reserved15 = 0,
            .ENDIANESS = 0,
            .VECTKEY = 0x5FA,
        });
        microzig.cpu.dsb();
        microzig.hang();
    }
};
