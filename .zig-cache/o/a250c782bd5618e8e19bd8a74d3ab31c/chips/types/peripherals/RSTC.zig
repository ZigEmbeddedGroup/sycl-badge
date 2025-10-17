const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const RSTC = extern struct {
    /// Reset Cause
    /// offset: 0x00
    RCAUSE: mmio.Mmio(packed struct(u8) {
        /// Power On Reset
        POR: u1,
        /// Brown Out CORE Detector Reset
        BODCORE: u1,
        /// Brown Out VDD Detector Reset
        BODVDD: u1,
        /// NVM Reset
        NVM: u1,
        /// External Reset
        EXT: u1,
        /// Watchdog Reset
        WDT: u1,
        /// System Reset Request
        SYST: u1,
        /// Backup Reset
        BACKUP: u1,
    }),
    /// offset: 0x01
    reserved1: [1]u8,
    /// Backup Exit Source
    /// offset: 0x02
    BKUPEXIT: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// Real Timer Counter Interrupt
        RTC: u1,
        /// Battery Backup Power Switch
        BBPS: u1,
        reserved7: u4 = 0,
        /// Hibernate
        HIB: u1,
    }),
};
