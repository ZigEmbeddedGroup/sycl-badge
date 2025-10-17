const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const DAC = extern struct {
    pub const DAC_CTRLB__REFSEL = enum(u2) {
        /// External reference unbuffered
        VREFPU = 0x0,
        /// Analog supply
        VDDANA = 0x1,
        /// External reference buffered
        VREFPB = 0x2,
        /// Internal bandgap reference
        INTREF = 0x3,
    };

    pub const DAC_DACCTRL__CCTRL = enum(u2) {
        /// 100kSPS
        CC100K = 0x0,
        /// 500kSPS
        CC1M = 0x1,
        /// 1MSPS
        CC12M = 0x2,
        _,
    };

    pub const DAC_DACCTRL__OSR = enum(u3) {
        /// No Over Sampling
        OSR_1 = 0x0,
        /// 2x Over Sampling Ratio
        OSR_2 = 0x1,
        /// 4x Over Sampling Ratio
        OSR_4 = 0x2,
        /// 8x Over Sampling Ratio
        OSR_8 = 0x3,
        /// 16x Over Sampling Ratio
        OSR_16 = 0x4,
        /// 32x Over Sampling Ratio
        OSR_32 = 0x5,
        _,
    };

    pub const DAC_DACCTRL__REFRESH = enum(u4) {
        /// Do not Refresh
        REFRESH_0 = 0x0,
        /// Refresh every 30 us
        REFRESH_1 = 0x1,
        /// Refresh every 60 us
        REFRESH_2 = 0x2,
        /// Refresh every 90 us
        REFRESH_3 = 0x3,
        /// Refresh every 120 us
        REFRESH_4 = 0x4,
        /// Refresh every 150 us
        REFRESH_5 = 0x5,
        /// Refresh every 180 us
        REFRESH_6 = 0x6,
        /// Refresh every 210 us
        REFRESH_7 = 0x7,
        /// Refresh every 240 us
        REFRESH_8 = 0x8,
        /// Refresh every 270 us
        REFRESH_9 = 0x9,
        /// Refresh every 300 us
        REFRESH_10 = 0xa,
        /// Refresh every 330 us
        REFRESH_11 = 0xb,
        /// Refresh every 360 us
        REFRESH_12 = 0xc,
        /// Refresh every 390 us
        REFRESH_13 = 0xd,
        /// Refresh every 420 us
        REFRESH_14 = 0xe,
        /// Refresh every 450 us
        REFRESH_15 = 0xf,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        /// Enable DAC Controller
        ENABLE: u1,
        padding: u6 = 0,
    }),
    /// Control B
    /// offset: 0x01
    CTRLB: mmio.Mmio(packed struct(u8) {
        /// Differential mode enable
        DIFF: u1,
        /// Reference Selection for DAC0/1
        REFSEL: DAC_CTRLB__REFSEL,
        padding: u5 = 0,
    }),
    /// Event Control
    /// offset: 0x02
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Start Conversion Event Input DAC 0
        STARTEI0: u1,
        /// Start Conversion Event Input DAC 1
        STARTEI1: u1,
        /// Data Buffer Empty Event Output DAC 0
        EMPTYEO0: u1,
        /// Data Buffer Empty Event Output DAC 1
        EMPTYEO1: u1,
        /// Enable Invertion of DAC 0 input event
        INVEI0: u1,
        /// Enable Invertion of DAC 1 input event
        INVEI1: u1,
        /// Result Ready Event Output 0
        RESRDYEO0: u1,
        /// Result Ready Event Output 1
        RESRDYEO1: u1,
    }),
    /// offset: 0x03
    reserved3: [1]u8,
    /// Interrupt Enable Clear
    /// offset: 0x04
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Underrun 0 Interrupt Enable
        UNDERRUN0: u1,
        /// Underrun 1 Interrupt Enable
        UNDERRUN1: u1,
        /// Data Buffer 0 Empty Interrupt Enable
        EMPTY0: u1,
        /// Data Buffer 1 Empty Interrupt Enable
        EMPTY1: u1,
        /// Result 0 Ready Interrupt Enable
        RESRDY0: u1,
        /// Result 1 Ready Interrupt Enable
        RESRDY1: u1,
        /// Overrun 0 Interrupt Enable
        OVERRUN0: u1,
        /// Overrun 1 Interrupt Enable
        OVERRUN1: u1,
    }),
    /// Interrupt Enable Set
    /// offset: 0x05
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Underrun 0 Interrupt Enable
        UNDERRUN0: u1,
        /// Underrun 1 Interrupt Enable
        UNDERRUN1: u1,
        /// Data Buffer 0 Empty Interrupt Enable
        EMPTY0: u1,
        /// Data Buffer 1 Empty Interrupt Enable
        EMPTY1: u1,
        /// Result 0 Ready Interrupt Enable
        RESRDY0: u1,
        /// Result 1 Ready Interrupt Enable
        RESRDY1: u1,
        /// Overrun 0 Interrupt Enable
        OVERRUN0: u1,
        /// Overrun 1 Interrupt Enable
        OVERRUN1: u1,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x06
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Result 0 Underrun
        UNDERRUN0: u1,
        /// Result 1 Underrun
        UNDERRUN1: u1,
        /// Data Buffer 0 Empty
        EMPTY0: u1,
        /// Data Buffer 1 Empty
        EMPTY1: u1,
        /// Result 0 Ready
        RESRDY0: u1,
        /// Result 1 Ready
        RESRDY1: u1,
        /// Result 0 Overrun
        OVERRUN0: u1,
        /// Result 1 Overrun
        OVERRUN1: u1,
    }),
    /// Status
    /// offset: 0x07
    STATUS: mmio.Mmio(packed struct(u8) {
        /// DAC 0 Startup Ready
        READY0: u1,
        /// DAC 1 Startup Ready
        READY1: u1,
        /// DAC 0 End of Conversion
        EOC0: u1,
        /// DAC 1 End of Conversion
        EOC1: u1,
        padding: u4 = 0,
    }),
    /// Synchronization Busy
    /// offset: 0x08
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// Software Reset
        SWRST: u1,
        /// DAC Enable Status
        ENABLE: u1,
        /// Data DAC 0
        DATA0: u1,
        /// Data DAC 1
        DATA1: u1,
        /// Data Buffer DAC 0
        DATABUF0: u1,
        /// Data Buffer DAC 1
        DATABUF1: u1,
        padding: u26 = 0,
    }),
    /// DAC n Control
    /// offset: 0x0c
    DACCTRL: [2]mmio.Mmio(packed struct(u16) {
        /// Left Adjusted Data
        LEFTADJ: u1,
        /// Enable DAC0
        ENABLE: u1,
        /// Current Control
        CCTRL: DAC_DACCTRL__CCTRL,
        reserved5: u1 = 0,
        /// Standalone Filter
        FEXT: u1,
        /// Run in Standby
        RUNSTDBY: u1,
        /// Dithering Mode
        DITHER: u1,
        /// Refresh period
        REFRESH: DAC_DACCTRL__REFRESH,
        reserved13: u1 = 0,
        /// Sampling Rate
        OSR: DAC_DACCTRL__OSR,
    }),
    /// DAC n Data
    /// offset: 0x10
    DATA: [2]mmio.Mmio(packed struct(u16) {
        /// DAC0 Data
        DATA: u16,
    }),
    /// DAC n Data Buffer
    /// offset: 0x14
    DATABUF: [2]mmio.Mmio(packed struct(u16) {
        /// DAC0 Data Buffer
        DATABUF: u16,
    }),
    /// Debug Control
    /// offset: 0x18
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Run
        DBGRUN: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x19
    reserved25: [3]u8,
    /// Filter Result
    /// offset: 0x1c
    RESULT: [2]mmio.Mmio(packed struct(u16) {
        /// Filter Result
        RESULT: u16,
    }),
};
