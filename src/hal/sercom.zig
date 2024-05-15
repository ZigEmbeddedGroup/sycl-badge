const std = @import("std");
const assert = std.debug.assert;

const microzig = @import("microzig");
const hal = microzig.hal;
const port = hal.port;
const clocks = hal.clocks;

const peripherals = microzig.chip.peripherals;
const SERCOM = microzig.chip.types.peripherals.SERCOM;

pub const Sercom = enum(u3) {
    SERCOM0,
    SERCOM1,
    SERCOM2,
    SERCOM3,
    SERCOM4,
    SERCOM5,
    SERCOM6,
    SERCOM7,

    fn get_regs(sercom: Sercom) *volatile SERCOM {
        return switch (sercom) {
            .SERCOM0 => if (@hasDecl(peripherals, "SERCOM0"))
                peripherals.SERCOM0
            else
                unreachable, // MCU does not have SERCOM0
            .SERCOM1 => if (@hasDecl(peripherals, "SERCOM1"))
                peripherals.SERCOM1
            else
                unreachable, // MCU does not have SERCOM1
            .SERCOM2 => if (@hasDecl(peripherals, "SERCOM2"))
                peripherals.SERCOM2
            else
                unreachable, // MCU does not have SERCOM2
            .SERCOM3 => if (@hasDecl(peripherals, "SERCOM3"))
                peripherals.SERCOM3
            else
                unreachable, // MCU does not have SERCOM3
            .SERCOM4 => if (@hasDecl(peripherals, "SERCOM4"))
                peripherals.SERCOM4
            else
                unreachable, // MCU does not have SERCOM4
            .SERCOM5 => if (@hasDecl(peripherals, "SERCOM5"))
                peripherals.SERCOM5
            else
                unreachable, // MCU does not have SERCOM5
            .SERCOM6 => if (@hasDecl(peripherals, "SERCOM6"))
                peripherals.SERCOM6
            else
                unreachable, // MCU does not have SERCOM6
            .SERCOM7 => if (@hasDecl(peripherals, "SERCOM7"))
                peripherals.SERCOM7
            else
                unreachable, // MCU does not have SERCOM7
        };
    }

    pub fn get_peripheral_index(sercom: Sercom) clocks.gclk.PeripheralIndex {
        return switch (sercom) {
            .SERCOM0 => .GCLK_SERCOM0_CORE,
            .SERCOM1 => .GCLK_SERCOM1_CORE,
            .SERCOM2 => .GCLK_SERCOM2_CORE,
            .SERCOM3 => .GCLK_SERCOM3_CORE,
            .SERCOM4 => .GCLK_SERCOM4_CORE,
            .SERCOM5 => .GCLK_SERCOM5_CORE,
            .SERCOM6 => .GCLK_SERCOM6_CORE,
            .SERCOM7 => .GCLK_SERCOM7_CORE,
        };
    }

    pub fn get_clock_frequency_hz(sercom: Sercom) u32 {
        const index = sercom.get_peripheral_index();
        return clocks.get_peripheral_clock_freq_hz(index);
    }
};

pub const spi = struct {
    pub const CPHA = SERCOM.SERCOM_SPIM_CTRLA__CPHA;
    pub const CPOL = SERCOM.SERCOM_SPIM_CTRLA__CPOL;
    pub const DORD = SERCOM.SERCOM_SPIM_CTRLA__DORD;

    pub const Master = struct {
        sercom: Sercom,

        pub const ConfigureOptions = struct {
            cpha: CPHA,
            cpol: CPOL,
            dord: DORD,
            dopo: SERCOM.SERCOM_SPIM_CTRLA__DOPO,
            ref_freq_hz: u32,
            baud_freq_hz: u32,
        };

        const SPIM = for (@typeInfo(SERCOM).Union.fields) |field| {
            if (std.mem.eql(u8, field.name, "SPIM"))
                break field.type;
        } else @compileError("no SPIM field");

        fn get_regs(m: Master) *volatile SPIM {
            return &m.sercom.get_regs().SPIM;
        }

        // TODO: pin and clock configuration
        pub fn init(sercom: Sercom, opts: ConfigureOptions) Master {
            const master = Master{ .sercom = sercom };
            master.reset();

            master.disable();
            defer master.enable();

            const regs = master.get_regs();
            regs.CTRLA.modify(.{
                .MODE = .{ .value = .SPI_MASTER },
                .FORM = .{ .value = .SPI_FRAME },
                .CPOL = .{ .value = opts.cpol },
                .CPHA = .{ .value = opts.cpha },
                // TODO: allow for reception
                .DIPO = .{ .value = .PAD0 },
                .DOPO = .{ .value = opts.dopo },
                .DORD = .{ .value = opts.dord },
            });

            // CTRLB only needs syncronization if the module is enabled.
            regs.CTRLB.modify(.{
                .CHSIZE = .{ .value = .@"8_BIT" },
                .MSSEN = 0,
                // TODO: configure RX
                .RXEN = 0,
            });

            regs.BAUD.write(.{
                .BAUD = @intCast((opts.ref_freq_hz / (2 * opts.baud_freq_hz)) - 1),
            });

            return master;
        }

        pub fn enable(m: Master) void {
            assert(clocks.gclk.peripheral_is_enabled(m.sercom.get_peripheral_index()));
            const regs = m.get_regs();
            regs.CTRLA.modify(.{
                .ENABLE = 1,
            });

            while (regs.SYNCBUSY.read().ENABLE == 1) {}
        }

        pub fn disable(m: Master) void {
            const regs = m.get_regs();
            regs.CTRLA.modify(.{
                .ENABLE = 0,
            });

            while (regs.SYNCBUSY.read().ENABLE == 1) {}
        }

        pub fn reset(m: Master) void {
            const regs = m.get_regs();
            regs.CTRLA.modify(.{
                .SWRST = 1,
            });

            while (regs.SYNCBUSY.read().SWRST == 1) {}
        }

        // Note: TXC is set when the data has been shifted and there's nothing
        // in DATA
        //
        // DRE is set when DATA is empty and ready for new data to transmit
        pub fn write_blocking(m: Master, byte: u8) void {
            const regs = m.get_regs();
            regs.DATA.write(.{ .DATA = byte });
            while (regs.INTFLAG.read().TXC == 0) {}
        }

        pub fn write_all_blocking(m: Master, bytes: []const u8) void {
            const regs = m.get_regs();
            for (bytes) |b| {
                while (regs.INTFLAG.read().DRE == 0) {}
                regs.DATA.write(.{ .DATA = b });
            }

            while (regs.INTFLAG.read().TXC == 0) {}
        }

        pub fn transfer_blocking(m: Master, byte: u8) u8 {
            const regs = m.get_regs();
            m.write_blocking(byte);
            return @truncate(regs.DATA.read().DATA);
        }
    };
};
