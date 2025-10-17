const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const PCC = extern struct {
    /// Mode Register
    /// offset: 0x00
    MR: mmio.Mmio(packed struct(u32) {
        /// Parallel Capture Enable
        PCEN: u1,
        reserved4: u3 = 0,
        /// Data size
        DSIZE: u2,
        reserved8: u2 = 0,
        /// Scale data
        SCALE: u1,
        /// Always Sampling
        ALWYS: u1,
        /// Half Sampling
        HALFS: u1,
        /// First sample
        FRSTS: u1,
        reserved16: u4 = 0,
        /// Input Data Size
        ISIZE: u3,
        reserved30: u11 = 0,
        /// Clear If Disabled
        CID: u2,
    }),
    /// Interrupt Enable Register
    /// offset: 0x04
    IER: mmio.Mmio(packed struct(u32) {
        /// Data Ready Interrupt Enable
        DRDY: u1,
        /// Overrun Error Interrupt Enable
        OVRE: u1,
        padding: u30 = 0,
    }),
    /// Interrupt Disable Register
    /// offset: 0x08
    IDR: mmio.Mmio(packed struct(u32) {
        /// Data Ready Interrupt Disable
        DRDY: u1,
        /// Overrun Error Interrupt Disable
        OVRE: u1,
        padding: u30 = 0,
    }),
    /// Interrupt Mask Register
    /// offset: 0x0c
    IMR: mmio.Mmio(packed struct(u32) {
        /// Data Ready Interrupt Mask
        DRDY: u1,
        /// Overrun Error Interrupt Mask
        OVRE: u1,
        padding: u30 = 0,
    }),
    /// Interrupt Status Register
    /// offset: 0x10
    ISR: mmio.Mmio(packed struct(u32) {
        /// Data Ready Interrupt Status
        DRDY: u1,
        /// Overrun Error Interrupt Status
        OVRE: u1,
        padding: u30 = 0,
    }),
    /// Reception Holding Register
    /// offset: 0x14
    RHR: mmio.Mmio(packed struct(u32) {
        /// Reception Data
        RDATA: u32,
    }),
    /// offset: 0x18
    reserved24: [200]u8,
    /// Write Protection Mode Register
    /// offset: 0xe0
    WPMR: mmio.Mmio(packed struct(u32) {
        /// Write Protection Enable
        WPEN: u1,
        reserved8: u7 = 0,
        /// Write Protection Key
        WPKEY: u24,
    }),
    /// Write Protection Status Register
    /// offset: 0xe4
    WPSR: mmio.Mmio(packed struct(u32) {
        /// Write Protection Violation Source
        WPVS: u1,
        reserved8: u7 = 0,
        /// Write Protection Violation Status
        WPVSRC: u16,
        padding: u8 = 0,
    }),
};
