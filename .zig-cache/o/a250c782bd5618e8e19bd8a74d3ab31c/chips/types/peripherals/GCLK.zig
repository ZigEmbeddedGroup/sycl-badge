const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const GCLK = extern struct {
    pub const GCLK_GENCTRL__DIVSEL = enum(u1) {
        /// Divide input directly by divider factor
        DIV1 = 0x0,
        /// Divide input by 2^(divider factor+ 1)
        DIV2 = 0x1,
    };

    pub const GCLK_GENCTRL__SRC = enum(u4) {
        /// XOSC0 oscillator output
        XOSC0 = 0x0,
        /// XOSC1 oscillator output
        XOSC1 = 0x1,
        /// Generator input pad
        GCLKIN = 0x2,
        /// Generic clock generator 1 output
        GCLKGEN1 = 0x3,
        /// OSCULP32K oscillator output
        OSCULP32K = 0x4,
        /// XOSC32K oscillator output
        XOSC32K = 0x5,
        /// DFLL output
        DFLL = 0x6,
        /// DPLL0 output
        DPLL0 = 0x7,
        /// DPLL1 output
        DPLL1 = 0x8,
        _,
    };

    pub const GCLK_PCHCTRL__GEN = enum(u4) {
        /// Generic clock generator 0
        GCLK0 = 0x0,
        /// Generic clock generator 1
        GCLK1 = 0x1,
        /// Generic clock generator 2
        GCLK2 = 0x2,
        /// Generic clock generator 3
        GCLK3 = 0x3,
        /// Generic clock generator 4
        GCLK4 = 0x4,
        /// Generic clock generator 5
        GCLK5 = 0x5,
        /// Generic clock generator 6
        GCLK6 = 0x6,
        /// Generic clock generator 7
        GCLK7 = 0x7,
        /// Generic clock generator 8
        GCLK8 = 0x8,
        /// Generic clock generator 9
        GCLK9 = 0x9,
        /// Generic clock generator 10
        GCLK10 = 0xa,
        /// Generic clock generator 11
        GCLK11 = 0xb,
        _,
    };

    pub const GCLK_SYNCBUSY__GENCTRL = enum(u12) {
        /// Generic clock generator 0
        GCLK0 = 0x1,
        /// Generic clock generator 1
        GCLK1 = 0x2,
        /// Generic clock generator 2
        GCLK2 = 0x4,
        /// Generic clock generator 3
        GCLK3 = 0x8,
        /// Generic clock generator 4
        GCLK4 = 0x10,
        /// Generic clock generator 5
        GCLK5 = 0x20,
        /// Generic clock generator 6
        GCLK6 = 0x40,
        /// Generic clock generator 7
        GCLK7 = 0x80,
        /// Generic clock generator 8
        GCLK8 = 0x100,
        /// Generic clock generator 9
        GCLK9 = 0x200,
        /// Generic clock generator 10
        GCLK10 = 0x400,
        /// Generic clock generator 11
        GCLK11 = 0x800,
        _,
    };

    /// Control
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// Synchronization Busy
    /// offset: 0x04
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// Software Reset Synchroniation Busy bit
        SWRST: u1,
        reserved2: u1 = 0,
        /// Generic Clock Generator Control n Synchronization Busy bits
        GENCTRL: GCLK_SYNCBUSY__GENCTRL,
        padding: u18 = 0,
    }),
    /// offset: 0x08
    reserved8: [24]u8,
    /// Generic Clock Generator Control
    /// offset: 0x20
    GENCTRL: [12]mmio.Mmio(packed struct(u32) {
        /// Source Select
        SRC: GCLK_GENCTRL__SRC,
        reserved8: u4 = 0,
        /// Generic Clock Generator Enable
        GENEN: u1,
        /// Improve Duty Cycle
        IDC: u1,
        /// Output Off Value
        OOV: u1,
        /// Output Enable
        OE: u1,
        /// Divide Selection
        DIVSEL: GCLK_GENCTRL__DIVSEL,
        /// Run in Standby
        RUNSTDBY: u1,
        reserved16: u2 = 0,
        /// Division Factor
        DIV: u16,
    }),
    /// offset: 0x50
    reserved80: [48]u8,
    /// Peripheral Clock Control
    /// offset: 0x80
    PCHCTRL: [48]mmio.Mmio(packed struct(u32) {
        /// Generic Clock Generator
        GEN: GCLK_PCHCTRL__GEN,
        reserved6: u2 = 0,
        /// Channel Enable
        CHEN: u1,
        /// Write Lock
        WRTLOCK: u1,
        padding: u24 = 0,
    }),
};
