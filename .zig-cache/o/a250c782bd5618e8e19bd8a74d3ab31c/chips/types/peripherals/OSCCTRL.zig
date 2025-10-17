const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const OSCCTRL_DPLLCTRLB__DCOFILTER = enum(u3) {
    /// Capacitor(pF) = 0.5 and Bandwidth Fn (MHz) = 3.21
    FILTER1 = 0x0,
    /// Capacitor(pF) = 1 and Bandwidth Fn (MHz) = 1.6
    FILTER2 = 0x1,
    /// Capacitor(pF) = 1.5 and Bandwidth Fn (MHz) = 1.1
    FILTER3 = 0x2,
    /// Capacitor(pF) = 2 and Bandwidth Fn (MHz) = 0.8
    FILTER4 = 0x3,
    /// Capacitor(pF) = 2.5 and Bandwidth Fn (MHz) = 0.64
    FILTER5 = 0x4,
    /// Capacitor(pF) = 3 and Bandwidth Fn (MHz) = 0.55
    FILTER6 = 0x5,
    /// Capacitor(pF) = 3.5 and Bandwidth Fn (MHz) = 0.45
    FILTER7 = 0x6,
    /// Capacitor(pF) = 4 and Bandwidth Fn (MHz) = 0.4
    FILTER8 = 0x7,
};

pub const OSCCTRL_DPLLCTRLB__FILTER = enum(u4) {
    /// Bandwidth = 92.7Khz and Damping Factor = 0.76
    FILTER1 = 0x0,
    /// Bandwidth = 131Khz and Damping Factor = 1.08
    FILTER2 = 0x1,
    /// Bandwidth = 46.4Khz and Damping Factor = 0.38
    FILTER3 = 0x2,
    /// Bandwidth = 65.6Khz and Damping Factor = 0.54
    FILTER4 = 0x3,
    /// Bandwidth = 131Khz and Damping Factor = 0.56
    FILTER5 = 0x4,
    /// Bandwidth = 185Khz and Damping Factor = 0.79
    FILTER6 = 0x5,
    /// Bandwidth = 65.6Khz and Damping Factor = 0.28
    FILTER7 = 0x6,
    /// Bandwidth = 92.7Khz and Damping Factor = 0.39
    FILTER8 = 0x7,
    /// Bandwidth = 46.4Khz and Damping Factor = 1.49
    FILTER9 = 0x8,
    /// Bandwidth = 65.6Khz and Damping Factor = 2.11
    FILTER10 = 0x9,
    /// Bandwidth = 23.2Khz and Damping Factor = 0.75
    FILTER11 = 0xa,
    /// Bandwidth = 32.8Khz and Damping Factor = 1.06
    FILTER12 = 0xb,
    /// Bandwidth = 65.6Khz and Damping Factor = 1.07
    FILTER13 = 0xc,
    /// Bandwidth = 92.7Khz and Damping Factor = 1.51
    FILTER14 = 0xd,
    /// Bandwidth = 32.8Khz and Damping Factor = 0.53
    FILTER15 = 0xe,
    /// Bandwidth = 46.4Khz and Damping Factor = 0.75
    FILTER16 = 0xf,
};

pub const OSCCTRL_DPLLCTRLB__LTIME = enum(u3) {
    /// No time-out. Automatic lock
    DEFAULT = 0x0,
    /// Time-out if no lock within 800us
    @"800US" = 0x4,
    /// Time-out if no lock within 900us
    @"900US" = 0x5,
    /// Time-out if no lock within 1ms
    @"1MS" = 0x6,
    /// Time-out if no lock within 1.1ms
    @"1P1MS" = 0x7,
    _,
};

pub const OSCCTRL_DPLLCTRLB__REFCLK = enum(u3) {
    /// Dedicated GCLK clock reference
    GCLK = 0x0,
    /// XOSC32K clock reference
    XOSC32 = 0x1,
    /// XOSC0 clock reference
    XOSC0 = 0x2,
    /// XOSC1 clock reference
    XOSC1 = 0x3,
    _,
};

pub const OSCCTRL_XOSCCTRL__CFDPRESC = enum(u3) {
    /// 48 MHz
    DIV1 = 0x0,
    /// 24 MHz
    DIV2 = 0x1,
    /// 12 MHz
    DIV4 = 0x2,
    /// 6 MHz
    DIV8 = 0x3,
    /// 3 MHz
    DIV16 = 0x4,
    /// 1.5 MHz
    DIV32 = 0x5,
    /// 0.75 MHz
    DIV64 = 0x6,
    /// 0.3125 MHz
    DIV128 = 0x7,
};

pub const OSCCTRL_XOSCCTRL__STARTUP = enum(u4) {
    /// 31 us
    CYCLE1 = 0x0,
    /// 61 us
    CYCLE2 = 0x1,
    /// 122 us
    CYCLE4 = 0x2,
    /// 244 us
    CYCLE8 = 0x3,
    /// 488 us
    CYCLE16 = 0x4,
    /// 977 us
    CYCLE32 = 0x5,
    /// 1953 us
    CYCLE64 = 0x6,
    /// 3906 us
    CYCLE128 = 0x7,
    /// 7813 us
    CYCLE256 = 0x8,
    /// 15625 us
    CYCLE512 = 0x9,
    /// 31250 us
    CYCLE1024 = 0xa,
    /// 62500 us
    CYCLE2048 = 0xb,
    /// 125000 us
    CYCLE4096 = 0xc,
    /// 250000 us
    CYCLE8192 = 0xd,
    /// 500000 us
    CYCLE16384 = 0xe,
    /// 1000000 us
    CYCLE32768 = 0xf,
};

pub const DPLL = extern struct {
    /// DPLL Control A
    /// offset: 0x00
    DPLLCTRLA: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// DPLL Enable
        ENABLE: u1,
        reserved6: u4 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        /// On Demand Control
        ONDEMAND: u1,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// DPLL Ratio Control
    /// offset: 0x04
    DPLLRATIO: mmio.Mmio(packed struct(u32) {
        /// Loop Divider Ratio
        LDR: u13,
        reserved16: u3 = 0,
        /// Loop Divider Ratio Fractional Part
        LDRFRAC: u5,
        padding: u11 = 0,
    }),
    /// DPLL Control B
    /// offset: 0x08
    DPLLCTRLB: mmio.Mmio(packed struct(u32) {
        /// Proportional Integral Filter Selection
        FILTER: OSCCTRL_DPLLCTRLB__FILTER,
        /// Wake Up Fast
        WUF: u1,
        /// Reference Clock Selection
        REFCLK: OSCCTRL_DPLLCTRLB__REFCLK,
        /// Lock Time
        LTIME: OSCCTRL_DPLLCTRLB__LTIME,
        /// Lock Bypass
        LBYPASS: u1,
        /// Sigma-Delta DCO Filter Selection
        DCOFILTER: OSCCTRL_DPLLCTRLB__DCOFILTER,
        /// DCO Filter Enable
        DCOEN: u1,
        /// Clock Divider
        DIV: u11,
        padding: u5 = 0,
    }),
    /// DPLL Synchronization Busy
    /// offset: 0x0c
    DPLLSYNCBUSY: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// DPLL Enable Synchronization Status
        ENABLE: u1,
        /// DPLL Loop Divider Ratio Synchronization Status
        DPLLRATIO: u1,
        padding: u29 = 0,
    }),
    /// DPLL Status
    /// offset: 0x10
    DPLLSTATUS: mmio.Mmio(packed struct(u32) {
        /// DPLL Lock Status
        LOCK: u1,
        /// DPLL Clock Ready
        CLKRDY: u1,
        padding: u30 = 0,
    }),
};

/// Oscillators Control
pub const OSCCTRL = extern struct {
    /// Event Control
    /// offset: 0x00
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Clock 0 Failure Detector Event Output Enable
        CFDEO0: u1,
        /// Clock 1 Failure Detector Event Output Enable
        CFDEO1: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// Interrupt Enable Clear
    /// offset: 0x04
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// XOSC 0 Ready Interrupt Enable
        XOSCRDY0: u1,
        /// XOSC 1 Ready Interrupt Enable
        XOSCRDY1: u1,
        /// XOSC 0 Clock Failure Detector Interrupt Enable
        XOSCFAIL0: u1,
        /// XOSC 1 Clock Failure Detector Interrupt Enable
        XOSCFAIL1: u1,
        reserved8: u4 = 0,
        /// DFLL Ready Interrupt Enable
        DFLLRDY: u1,
        /// DFLL Out Of Bounds Interrupt Enable
        DFLLOOB: u1,
        /// DFLL Lock Fine Interrupt Enable
        DFLLLCKF: u1,
        /// DFLL Lock Coarse Interrupt Enable
        DFLLLCKC: u1,
        /// DFLL Reference Clock Stopped Interrupt Enable
        DFLLRCS: u1,
        reserved16: u3 = 0,
        /// DPLL0 Lock Rise Interrupt Enable
        DPLL0LCKR: u1,
        /// DPLL0 Lock Fall Interrupt Enable
        DPLL0LCKF: u1,
        /// DPLL0 Lock Timeout Interrupt Enable
        DPLL0LTO: u1,
        /// DPLL0 Loop Divider Ratio Update Complete Interrupt Enable
        DPLL0LDRTO: u1,
        reserved24: u4 = 0,
        /// DPLL1 Lock Rise Interrupt Enable
        DPLL1LCKR: u1,
        /// DPLL1 Lock Fall Interrupt Enable
        DPLL1LCKF: u1,
        /// DPLL1 Lock Timeout Interrupt Enable
        DPLL1LTO: u1,
        /// DPLL1 Loop Divider Ratio Update Complete Interrupt Enable
        DPLL1LDRTO: u1,
        padding: u4 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x08
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// XOSC 0 Ready Interrupt Enable
        XOSCRDY0: u1,
        /// XOSC 1 Ready Interrupt Enable
        XOSCRDY1: u1,
        /// XOSC 0 Clock Failure Detector Interrupt Enable
        XOSCFAIL0: u1,
        /// XOSC 1 Clock Failure Detector Interrupt Enable
        XOSCFAIL1: u1,
        reserved8: u4 = 0,
        /// DFLL Ready Interrupt Enable
        DFLLRDY: u1,
        /// DFLL Out Of Bounds Interrupt Enable
        DFLLOOB: u1,
        /// DFLL Lock Fine Interrupt Enable
        DFLLLCKF: u1,
        /// DFLL Lock Coarse Interrupt Enable
        DFLLLCKC: u1,
        /// DFLL Reference Clock Stopped Interrupt Enable
        DFLLRCS: u1,
        reserved16: u3 = 0,
        /// DPLL0 Lock Rise Interrupt Enable
        DPLL0LCKR: u1,
        /// DPLL0 Lock Fall Interrupt Enable
        DPLL0LCKF: u1,
        /// DPLL0 Lock Timeout Interrupt Enable
        DPLL0LTO: u1,
        /// DPLL0 Loop Divider Ratio Update Complete Interrupt Enable
        DPLL0LDRTO: u1,
        reserved24: u4 = 0,
        /// DPLL1 Lock Rise Interrupt Enable
        DPLL1LCKR: u1,
        /// DPLL1 Lock Fall Interrupt Enable
        DPLL1LCKF: u1,
        /// DPLL1 Lock Timeout Interrupt Enable
        DPLL1LTO: u1,
        /// DPLL1 Loop Divider Ratio Update Complete Interrupt Enable
        DPLL1LDRTO: u1,
        padding: u4 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x0c
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// XOSC 0 Ready
        XOSCRDY0: u1,
        /// XOSC 1 Ready
        XOSCRDY1: u1,
        /// XOSC 0 Clock Failure Detector
        XOSCFAIL0: u1,
        /// XOSC 1 Clock Failure Detector
        XOSCFAIL1: u1,
        reserved8: u4 = 0,
        /// DFLL Ready
        DFLLRDY: u1,
        /// DFLL Out Of Bounds
        DFLLOOB: u1,
        /// DFLL Lock Fine
        DFLLLCKF: u1,
        /// DFLL Lock Coarse
        DFLLLCKC: u1,
        /// DFLL Reference Clock Stopped
        DFLLRCS: u1,
        reserved16: u3 = 0,
        /// DPLL0 Lock Rise
        DPLL0LCKR: u1,
        /// DPLL0 Lock Fall
        DPLL0LCKF: u1,
        /// DPLL0 Lock Timeout
        DPLL0LTO: u1,
        /// DPLL0 Loop Divider Ratio Update Complete
        DPLL0LDRTO: u1,
        reserved24: u4 = 0,
        /// DPLL1 Lock Rise
        DPLL1LCKR: u1,
        /// DPLL1 Lock Fall
        DPLL1LCKF: u1,
        /// DPLL1 Lock Timeout
        DPLL1LTO: u1,
        /// DPLL1 Loop Divider Ratio Update Complete
        DPLL1LDRTO: u1,
        padding: u4 = 0,
    }),
    /// Status
    /// offset: 0x10
    STATUS: mmio.Mmio(packed struct(u32) {
        /// XOSC 0 Ready
        XOSCRDY0: u1,
        /// XOSC 1 Ready
        XOSCRDY1: u1,
        /// XOSC 0 Clock Failure Detector
        XOSCFAIL0: u1,
        /// XOSC 1 Clock Failure Detector
        XOSCFAIL1: u1,
        /// XOSC 0 Clock Switch
        XOSCCKSW0: u1,
        /// XOSC 1 Clock Switch
        XOSCCKSW1: u1,
        reserved8: u2 = 0,
        /// DFLL Ready
        DFLLRDY: u1,
        /// DFLL Out Of Bounds
        DFLLOOB: u1,
        /// DFLL Lock Fine
        DFLLLCKF: u1,
        /// DFLL Lock Coarse
        DFLLLCKC: u1,
        /// DFLL Reference Clock Stopped
        DFLLRCS: u1,
        reserved16: u3 = 0,
        /// DPLL0 Lock Rise
        DPLL0LCKR: u1,
        /// DPLL0 Lock Fall
        DPLL0LCKF: u1,
        /// DPLL0 Timeout
        DPLL0TO: u1,
        /// DPLL0 Loop Divider Ratio Update Complete
        DPLL0LDRTO: u1,
        reserved24: u4 = 0,
        /// DPLL1 Lock Rise
        DPLL1LCKR: u1,
        /// DPLL1 Lock Fall
        DPLL1LCKF: u1,
        /// DPLL1 Timeout
        DPLL1TO: u1,
        /// DPLL1 Loop Divider Ratio Update Complete
        DPLL1LDRTO: u1,
        padding: u4 = 0,
    }),
    /// External Multipurpose Crystal Oscillator Control
    /// offset: 0x14
    XOSCCTRL: [2]mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Oscillator Enable
        ENABLE: u1,
        /// Crystal Oscillator Enable
        XTALEN: u1,
        reserved6: u3 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        /// On Demand Control
        ONDEMAND: u1,
        /// Low Buffer Gain Enable
        LOWBUFGAIN: u1,
        /// Oscillator Current Reference
        IPTAT: u2,
        /// Oscillator Current Multiplier
        IMULT: u4,
        /// Automatic Loop Control Enable
        ENALC: u1,
        /// Clock Failure Detector Enable
        CFDEN: u1,
        /// Xosc Clock Switch Enable
        SWBEN: u1,
        reserved20: u2 = 0,
        /// Start-Up Time
        STARTUP: OSCCTRL_XOSCCTRL__STARTUP,
        /// Clock Failure Detector Prescaler
        CFDPRESC: u4,
        padding: u4 = 0,
    }),
    /// DFLL48M Control A
    /// offset: 0x1c
    DFLLCTRLA: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// DFLL Enable
        ENABLE: u1,
        reserved6: u4 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        /// On Demand Control
        ONDEMAND: u1,
    }),
    /// offset: 0x1d
    reserved29: [3]u8,
    /// DFLL48M Control B
    /// offset: 0x20
    DFLLCTRLB: mmio.Mmio(packed struct(u8) {
        /// Operating Mode Selection
        MODE: u1,
        /// Stable DFLL Frequency
        STABLE: u1,
        /// Lose Lock After Wake
        LLAW: u1,
        /// USB Clock Recovery Mode
        USBCRM: u1,
        /// Chill Cycle Disable
        CCDIS: u1,
        /// Quick Lock Disable
        QLDIS: u1,
        /// Bypass Coarse Lock
        BPLCKC: u1,
        /// Wait Lock
        WAITLOCK: u1,
    }),
    /// offset: 0x21
    reserved33: [3]u8,
    /// DFLL48M Value
    /// offset: 0x24
    DFLLVAL: mmio.Mmio(packed struct(u32) {
        /// Fine Value
        FINE: u8,
        reserved10: u2 = 0,
        /// Coarse Value
        COARSE: u6,
        /// Multiplication Ratio Difference
        DIFF: u16,
    }),
    /// DFLL48M Multiplier
    /// offset: 0x28
    DFLLMUL: mmio.Mmio(packed struct(u32) {
        /// DFLL Multiply Factor
        MUL: u16,
        /// Fine Maximum Step
        FSTEP: u8,
        reserved26: u2 = 0,
        /// Coarse Maximum Step
        CSTEP: u6,
    }),
    /// DFLL48M Synchronization
    /// offset: 0x2c
    DFLLSYNC: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// ENABLE Synchronization Busy
        ENABLE: u1,
        /// DFLLCTRLB Synchronization Busy
        DFLLCTRLB: u1,
        /// DFLLVAL Synchronization Busy
        DFLLVAL: u1,
        /// DFLLMUL Synchronization Busy
        DFLLMUL: u1,
        padding: u3 = 0,
    }),
    /// offset: 0x2d
    reserved45: [3]u8,
    /// offset: 0x30
    DPLL: [2]DPLL,
};
