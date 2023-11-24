pub const GCLK = struct {
    pub const GEN = struct {
        fn Gen(comptime id: u4) type {
            const tag = std.fmt.comptimePrint("GCLK{d}", .{id});
            return struct {
                pub const ID = id;
                pub const SYNCBUSY_GENCTRL = @intFromEnum(@field(io_types.GCLK.GCLK_SYNCBUSY__GENCTRL, tag));
                pub const PCHCTRL_GEN = @field(io_types.GCLK.GCLK_PCHCTRL__GEN, tag);
            };
        }
        pub const @"120MHz" = Gen(0);
        pub const @"48MHz" = Gen(2);
        pub const @"1MHz" = Gen(3);
        pub const @"64KHz" = Gen(11);
    };
    pub const PCH = struct {
        pub const OSCCTRL_DFLL48 = 0;
        pub const OSCCTRL_FDPLL0 = 1;
        pub const OSCCTRL_FDPLL1 = 2;
        pub const OSCCTRL_FDPLL0_32K = 3;
        pub const OSCCTRL_FDPLL1_32K = 3;
        pub const SDHC0_SLOW = 3;
        pub const SDHC1_SLOW = 3;
        pub const SERCOM0_SLOW = 3;
        pub const SERCOM1_SLOW = 3;
        pub const SERCOM2_SLOW = 3;
        pub const SERCOM3_SLOW = 3;
        pub const SERCOM4_SLOW = 3;
        pub const SERCOM5_SLOW = 3;
        pub const SERCOM6_SLOW = 3;
        pub const SERCOM7_SLOW = 3;
        pub const EIC = 4;
        pub const FREQM_MSR = 5;
        pub const FREQM_REF = 6;
        pub const SERCOM0_CORE = 7;
        pub const SERCOM1_CORE = 8;
        pub const TC0 = 9;
        pub const TC1 = 9;
        pub const USB = 10;
        pub const EVSYS0 = 11;
        pub const EVSYS1 = 12;
        pub const EVSYS2 = 13;
        pub const EVSYS3 = 14;
        pub const EVSYS4 = 15;
        pub const EVSYS5 = 16;
        pub const EVSYS6 = 17;
        pub const EVSYS7 = 18;
        pub const EVSYS8 = 19;
        pub const EVSYS9 = 20;
        pub const EVSYS10 = 21;
        pub const EVSYS11 = 22;
        pub const SERCOM2_CORE = 23;
        pub const SERCOM3_CORE = 24;
        pub const TCC0_CORE = 25;
        pub const TCC1_CORE = 25;
        pub const TC2 = 26;
        pub const TC3 = 26;
        pub const CAN0 = 27;
        pub const CAN1 = 28;
        pub const TCC2 = 29;
        pub const TCC3 = 29;
        pub const TC4 = 30;
        pub const TC5 = 30;
        pub const PDEC = 31;
        pub const AC = 32;
        pub const CCL = 33;
        pub const SERCOM4_CORE = 34;
        pub const SERCOM5_CORE = 35;
        pub const SERCOM6_CORE = 36;
        pub const SERCOM7_CORE = 37;
        pub const TCC4 = 38;
        pub const TC6 = 39;
        pub const TC7 = 39;
        pub const ADC0 = 40;
        pub const ADC1 = 41;
        pub const DAC = 42;
        pub const I2C = .{ 43, 44 };
        pub const SDHC0 = 45;
        pub const SDHC1 = 46;
        pub const CM4_TRACE = 47;
    };
};

pub const NVMCTRL = struct {
    pub const SW0: *volatile io_types.FUSES.SW0_FUSES = @ptrFromInt(0x00800080);
};

const io_types = microzig.chip.types.peripherals;
const microzig = @import("microzig");
const std = @import("std");
