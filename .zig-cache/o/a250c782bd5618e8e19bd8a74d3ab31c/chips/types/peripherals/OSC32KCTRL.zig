const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const OSC32KCTRL = extern struct {
    pub const OSC32KCTRL_RTCCTRL__RTCSEL = enum(u3) {
        /// 1.024kHz from 32kHz internal ULP oscillator
        ULP1K = 0x0,
        /// 32.768kHz from 32kHz internal ULP oscillator
        ULP32K = 0x1,
        /// 1.024kHz from 32.768kHz internal oscillator
        XOSC1K = 0x4,
        /// 32.768kHz from 32.768kHz external crystal oscillator
        XOSC32K = 0x5,
        _,
    };

    pub const OSC32KCTRL_XOSC32K__CGM = enum(u2) {
        /// Standard mode
        XT = 0x1,
        /// High Speed mode
        HS = 0x2,
        _,
    };

    pub const OSC32KCTRL_XOSC32K__STARTUP = enum(u3) {
        /// 62.6 ms
        CYCLE2048 = 0x0,
        /// 125 ms
        CYCLE4096 = 0x1,
        /// 500 ms
        CYCLE16384 = 0x2,
        /// 1000 ms
        CYCLE32768 = 0x3,
        /// 2000 ms
        CYCLE65536 = 0x4,
        /// 4000 ms
        CYCLE131072 = 0x5,
        /// 8000 ms
        CYCLE262144 = 0x6,
        _,
    };

    /// Interrupt Enable Clear
    /// offset: 0x00
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// XOSC32K Ready Interrupt Enable
        XOSC32KRDY: u1,
        reserved2: u1 = 0,
        /// XOSC32K Clock Failure Detector Interrupt Enable
        XOSC32KFAIL: u1,
        padding: u29 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x04
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// XOSC32K Ready Interrupt Enable
        XOSC32KRDY: u1,
        reserved2: u1 = 0,
        /// XOSC32K Clock Failure Detector Interrupt Enable
        XOSC32KFAIL: u1,
        padding: u29 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x08
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// XOSC32K Ready
        XOSC32KRDY: u1,
        reserved2: u1 = 0,
        /// XOSC32K Clock Failure Detector
        XOSC32KFAIL: u1,
        padding: u29 = 0,
    }),
    /// Power and Clocks Status
    /// offset: 0x0c
    STATUS: mmio.Mmio(packed struct(u32) {
        /// XOSC32K Ready
        XOSC32KRDY: u1,
        reserved2: u1 = 0,
        /// XOSC32K Clock Failure Detector
        XOSC32KFAIL: u1,
        /// XOSC32K Clock switch
        XOSC32KSW: u1,
        padding: u28 = 0,
    }),
    /// RTC Clock Selection
    /// offset: 0x10
    RTCCTRL: mmio.Mmio(packed struct(u8) {
        /// RTC Clock Selection
        RTCSEL: OSC32KCTRL_RTCCTRL__RTCSEL,
        padding: u5 = 0,
    }),
    /// offset: 0x11
    reserved17: [3]u8,
    /// 32kHz External Crystal Oscillator (XOSC32K) Control
    /// offset: 0x14
    XOSC32K: mmio.Mmio(packed struct(u16) {
        reserved1: u1 = 0,
        /// Oscillator Enable
        ENABLE: u1,
        /// Crystal Oscillator Enable
        XTALEN: u1,
        /// 32kHz Output Enable
        EN32K: u1,
        /// 1kHz Output Enable
        EN1K: u1,
        reserved6: u1 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        /// On Demand Control
        ONDEMAND: u1,
        /// Oscillator Start-Up Time
        STARTUP: OSC32KCTRL_XOSC32K__STARTUP,
        reserved12: u1 = 0,
        /// Write Lock
        WRTLOCK: u1,
        /// Control Gain Mode
        CGM: OSC32KCTRL_XOSC32K__CGM,
        padding: u1 = 0,
    }),
    /// Clock Failure Detector Control
    /// offset: 0x16
    CFDCTRL: mmio.Mmio(packed struct(u8) {
        /// Clock Failure Detector Enable
        CFDEN: u1,
        /// Clock Switch Back
        SWBACK: u1,
        /// Clock Failure Detector Prescaler
        CFDPRESC: u1,
        padding: u5 = 0,
    }),
    /// Event Control
    /// offset: 0x17
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Clock Failure Detector Event Output Enable
        CFDEO: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x18
    reserved24: [4]u8,
    /// 32kHz Ultra Low Power Internal Oscillator (OSCULP32K) Control
    /// offset: 0x1c
    OSCULP32K: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Enable Out 32k
        EN32K: u1,
        /// Enable Out 1k
        EN1K: u1,
        reserved8: u5 = 0,
        /// Oscillator Calibration
        CALIB: u6,
        reserved15: u1 = 0,
        /// Write Lock
        WRTLOCK: u1,
        padding: u16 = 0,
    }),
};
