const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const TRNG = extern struct {
    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// Enable
        ENABLE: u1,
        reserved6: u4 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        padding: u1 = 0,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// Event Control
    /// offset: 0x04
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Data Ready Event Output
        DATARDYEO: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x05
    reserved5: [3]u8,
    /// Interrupt Enable Clear
    /// offset: 0x08
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Data Ready Interrupt Enable
        DATARDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x09
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Data Ready Interrupt Enable
        DATARDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x0a
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Data Ready Interrupt Flag
        DATARDY: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x0b
    reserved11: [21]u8,
    /// Output Data
    /// offset: 0x20
    DATA: mmio.Mmio(packed struct(u32) {
        /// Output Data
        DATA: u32,
    }),
};
