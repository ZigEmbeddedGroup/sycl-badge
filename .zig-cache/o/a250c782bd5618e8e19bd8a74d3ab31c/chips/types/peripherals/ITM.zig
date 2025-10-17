const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const ITM = extern struct {
    /// ITM Stimulus Port Registers
    /// offset: 0x00
    PORT: [32]mmio.Mmio(packed struct(u32) {
        PORT: u8,
        padding: u24 = 0,
    }),
    /// offset: 0x80
    reserved128: [3456]u8,
    /// ITM Trace Enable Register
    /// offset: 0xe00
    TER: u32,
    /// offset: 0xe04
    reserved3588: [60]u8,
    /// ITM Trace Privilege Register
    /// offset: 0xe40
    TPR: mmio.Mmio(packed struct(u32) {
        PRIVMASK: u4,
        padding: u28 = 0,
    }),
    /// offset: 0xe44
    reserved3652: [60]u8,
    /// ITM Trace Control Register
    /// offset: 0xe80
    TCR: mmio.Mmio(packed struct(u32) {
        ITMENA: u1,
        TSENA: u1,
        SYNCENA: u1,
        DWTENA: u1,
        SWOENA: u1,
        STALLENA: u1,
        reserved8: u2 = 0,
        TSPrescale: u2,
        GTSFREQ: u2,
        reserved16: u4 = 0,
        TraceBusID: u7,
        BUSY: u1,
        padding: u8 = 0,
    }),
    /// offset: 0xe84
    reserved3716: [116]u8,
    /// ITM Integration Write Register
    /// offset: 0xef8
    IWR: mmio.Mmio(packed struct(u32) {
        ATVALIDM: u1,
        padding: u31 = 0,
    }),
    /// ITM Integration Read Register
    /// offset: 0xefc
    IRR: mmio.Mmio(packed struct(u32) {
        ATREADYM: u1,
        padding: u31 = 0,
    }),
};
