const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const RAMECC = extern struct {
    /// Interrupt Enable Clear
    /// offset: 0x00
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Single Bit ECC Error Interrupt Enable Clear
        SINGLEE: u1,
        /// Dual Bit ECC Error Interrupt Enable Clear
        DUALE: u1,
        padding: u6 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x01
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Single Bit ECC Error Interrupt Enable Set
        SINGLEE: u1,
        /// Dual Bit ECC Error Interrupt Enable Set
        DUALE: u1,
        padding: u6 = 0,
    }),
    /// Interrupt Flag
    /// offset: 0x02
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Single Bit ECC Error Interrupt
        SINGLEE: u1,
        /// Dual Bit ECC Error Interrupt
        DUALE: u1,
        padding: u6 = 0,
    }),
    /// Status
    /// offset: 0x03
    STATUS: mmio.Mmio(packed struct(u8) {
        /// ECC Disable
        ECCDIS: u1,
        padding: u7 = 0,
    }),
    /// Error Address
    /// offset: 0x04
    ERRADDR: mmio.Mmio(packed struct(u32) {
        /// Error Address
        ERRADDR: u17,
        padding: u15 = 0,
    }),
    /// offset: 0x08
    reserved8: [7]u8,
    /// Debug Control
    /// offset: 0x0f
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// ECC Disable
        ECCDIS: u1,
        /// ECC Error Log
        ECCELOG: u1,
        padding: u6 = 0,
    }),
};
