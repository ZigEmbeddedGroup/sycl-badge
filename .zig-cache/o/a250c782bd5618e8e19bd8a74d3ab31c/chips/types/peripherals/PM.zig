const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const PM = extern struct {
    pub const PM_BKUPCFG__BRAMCFG = enum(u2) {
        /// All the backup RAM is retained
        RET = 0x0,
        /// Only the first 4Kbytes of the backup RAM is retained
        PARTIAL = 0x1,
        /// All the backup RAM is turned OFF
        OFF = 0x2,
        _,
    };

    pub const PM_HIBCFG__BRAMCFG = enum(u2) {
        /// All the backup RAM is retained
        RET = 0x0,
        /// Only the first 4Kbytes of the backup RAM is retained
        PARTIAL = 0x1,
        /// All the backup RAM is turned OFF
        OFF = 0x2,
        _,
    };

    pub const PM_HIBCFG__RAMCFG = enum(u2) {
        /// All the system RAM is retained
        RET = 0x0,
        /// Only the first 32Kbytes of the system RAM is retained
        PARTIAL = 0x1,
        /// All the system RAM is turned OFF
        OFF = 0x2,
        _,
    };

    pub const PM_SLEEPCFG__SLEEPMODE = enum(u3) {
        /// CPU, AHBx, and APBx clocks are OFF
        IDLE = 0x2,
        /// All Clocks are OFF
        STANDBY = 0x4,
        /// Backup domain is ON as well as some PDRAMs
        HIBERNATE = 0x5,
        /// Only Backup domain is powered ON
        BACKUP = 0x6,
        /// All power domains are powered OFF
        OFF = 0x7,
        _,
    };

    pub const PM_STDBYCFG__FASTWKUP = enum(u2) {
        /// Fast Wakeup is disabled
        NO = 0x0,
        /// Fast Wakeup is enabled on NVM
        NVM = 0x1,
        /// Fast Wakeup is enabled on the main voltage regulator (MAINVREG)
        MAINVREG = 0x2,
        /// Fast Wakeup is enabled on both NVM and MAINVREG
        BOTH = 0x3,
    };

    pub const PM_STDBYCFG__RAMCFG = enum(u2) {
        /// All the system RAM is retained
        RET = 0x0,
        /// Only the first 32Kbytes of the system RAM is retained
        PARTIAL = 0x1,
        /// All the system RAM is turned OFF
        OFF = 0x2,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        reserved2: u2 = 0,
        /// I/O Retention
        IORET: u1,
        padding: u5 = 0,
    }),
    /// Sleep Configuration
    /// offset: 0x01
    SLEEPCFG: mmio.Mmio(packed struct(u8) {
        /// Sleep Mode
        SLEEPMODE: PM_SLEEPCFG__SLEEPMODE,
        padding: u5 = 0,
    }),
    /// offset: 0x02
    reserved2: [2]u8,
    /// Interrupt Enable Clear
    /// offset: 0x04
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Sleep Mode Entry Ready Enable
        SLEEPRDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x05
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Sleep Mode Entry Ready Enable
        SLEEPRDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x06
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Sleep Mode Entry Ready
        SLEEPRDY: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x07
    reserved7: [1]u8,
    /// Standby Configuration
    /// offset: 0x08
    STDBYCFG: mmio.Mmio(packed struct(u8) {
        /// Ram Configuration
        RAMCFG: PM_STDBYCFG__RAMCFG,
        reserved4: u2 = 0,
        /// Fast Wakeup
        FASTWKUP: PM_STDBYCFG__FASTWKUP,
        padding: u2 = 0,
    }),
    /// Hibernate Configuration
    /// offset: 0x09
    HIBCFG: mmio.Mmio(packed struct(u8) {
        /// Ram Configuration
        RAMCFG: PM_HIBCFG__RAMCFG,
        /// Backup Ram Configuration
        BRAMCFG: PM_HIBCFG__BRAMCFG,
        padding: u4 = 0,
    }),
    /// Backup Configuration
    /// offset: 0x0a
    BKUPCFG: mmio.Mmio(packed struct(u8) {
        /// Ram Configuration
        BRAMCFG: PM_BKUPCFG__BRAMCFG,
        padding: u6 = 0,
    }),
    /// offset: 0x0b
    reserved11: [7]u8,
    /// Power Switch Acknowledge Delay
    /// offset: 0x12
    PWSAKDLY: mmio.Mmio(packed struct(u8) {
        /// Delay Value
        DLYVAL: u7,
        /// Ignore Acknowledge
        IGNACK: u1,
    }),
};
