const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

/// HSB Matrix
pub const HMATRIXB = extern struct {
    /// offset: 0x00
    reserved0: [128]u8,
    /// offset: 0x80
    PRS: [16]PRS,
};

pub const PRS = extern struct {
    /// Priority A for Slave
    /// offset: 0x00
    PRAS: u32,
    /// Priority B for Slave
    /// offset: 0x04
    PRBS: u32,
};
