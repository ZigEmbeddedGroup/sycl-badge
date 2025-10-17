const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const TPI = extern struct {
    /// Supported Parallel Port Size Register
    /// offset: 0x00
    SSPSR: u32,
    /// Current Parallel Port Size Register
    /// offset: 0x04
    CSPSR: u32,
    /// offset: 0x08
    reserved8: [8]u8,
    /// Asynchronous Clock Prescaler Register
    /// offset: 0x10
    ACPR: mmio.Mmio(packed struct(u32) {
        PRESCALER: u13,
        padding: u19 = 0,
    }),
    /// offset: 0x14
    reserved20: [220]u8,
    /// Selected Pin Protocol Register
    /// offset: 0xf0
    SPPR: mmio.Mmio(packed struct(u32) {
        TXMODE: u2,
        padding: u30 = 0,
    }),
    /// offset: 0xf4
    reserved244: [524]u8,
    /// Formatter and Flush Status Register
    /// offset: 0x300
    FFSR: mmio.Mmio(packed struct(u32) {
        FlInProg: u1,
        FtStopped: u1,
        TCPresent: u1,
        FtNonStop: u1,
        padding: u28 = 0,
    }),
    /// Formatter and Flush Control Register
    /// offset: 0x304
    FFCR: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        EnFCont: u1,
        reserved8: u6 = 0,
        TrigIn: u1,
        padding: u23 = 0,
    }),
    /// Formatter Synchronization Counter Register
    /// offset: 0x308
    FSCR: u32,
    /// offset: 0x30c
    reserved780: [3036]u8,
    /// TRIGGER
    /// offset: 0xee8
    TRIGGER: mmio.Mmio(packed struct(u32) {
        TRIGGER: u1,
        padding: u31 = 0,
    }),
    /// Integration ETM Data
    /// offset: 0xeec
    FIFO0: mmio.Mmio(packed struct(u32) {
        ETM0: u8,
        ETM1: u8,
        ETM2: u8,
        ETM_bytecount: u2,
        ETM_ATVALID: u1,
        ITM_bytecount: u2,
        ITM_ATVALID: u1,
        padding: u2 = 0,
    }),
    /// ITATBCTR2
    /// offset: 0xef0
    ITATBCTR2: mmio.Mmio(packed struct(u32) {
        ATREADY: u1,
        padding: u31 = 0,
    }),
    /// offset: 0xef4
    reserved3828: [4]u8,
    /// ITATBCTR0
    /// offset: 0xef8
    ITATBCTR0: mmio.Mmio(packed struct(u32) {
        ATREADY: u1,
        padding: u31 = 0,
    }),
    /// Integration ITM Data
    /// offset: 0xefc
    FIFO1: mmio.Mmio(packed struct(u32) {
        ITM0: u8,
        ITM1: u8,
        ITM2: u8,
        ETM_bytecount: u2,
        ETM_ATVALID: u1,
        ITM_bytecount: u2,
        ITM_ATVALID: u1,
        padding: u2 = 0,
    }),
    /// Integration Mode Control
    /// offset: 0xf00
    ITCTRL: mmio.Mmio(packed struct(u32) {
        Mode: u1,
        padding: u31 = 0,
    }),
    /// offset: 0xf04
    reserved3844: [156]u8,
    /// Claim tag set
    /// offset: 0xfa0
    CLAIMSET: u32,
    /// Claim tag clear
    /// offset: 0xfa4
    CLAIMCLR: u32,
    /// offset: 0xfa8
    reserved4008: [32]u8,
    /// TPIU_DEVID
    /// offset: 0xfc8
    DEVID: mmio.Mmio(packed struct(u32) {
        NrTraceInput: u1,
        reserved5: u4 = 0,
        AsynClkIn: u1,
        MinBufSz: u3,
        PTINVALID: u1,
        MANCVALID: u1,
        NRZVALID: u1,
        padding: u20 = 0,
    }),
    /// TPIU_DEVTYPE
    /// offset: 0xfcc
    DEVTYPE: mmio.Mmio(packed struct(u32) {
        SubType: u4,
        MajorType: u4,
        padding: u24 = 0,
    }),
};
