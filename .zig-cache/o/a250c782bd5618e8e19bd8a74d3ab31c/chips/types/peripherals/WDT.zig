const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const WDT = extern struct {
    pub const WDT_CLEAR__CLEAR = enum(u8) {
        /// Clear Key
        KEY = 0xa5,
        _,
    };

    pub const WDT_CONFIG__PER = enum(u4) {
        /// 8 clock cycles
        CYC8 = 0x0,
        /// 16 clock cycles
        CYC16 = 0x1,
        /// 32 clock cycles
        CYC32 = 0x2,
        /// 64 clock cycles
        CYC64 = 0x3,
        /// 128 clock cycles
        CYC128 = 0x4,
        /// 256 clock cycles
        CYC256 = 0x5,
        /// 512 clock cycles
        CYC512 = 0x6,
        /// 1024 clock cycles
        CYC1024 = 0x7,
        /// 2048 clock cycles
        CYC2048 = 0x8,
        /// 4096 clock cycles
        CYC4096 = 0x9,
        /// 8192 clock cycles
        CYC8192 = 0xa,
        /// 16384 clock cycles
        CYC16384 = 0xb,
        _,
    };

    pub const WDT_CONFIG__WINDOW = enum(u4) {
        /// 8 clock cycles
        CYC8 = 0x0,
        /// 16 clock cycles
        CYC16 = 0x1,
        /// 32 clock cycles
        CYC32 = 0x2,
        /// 64 clock cycles
        CYC64 = 0x3,
        /// 128 clock cycles
        CYC128 = 0x4,
        /// 256 clock cycles
        CYC256 = 0x5,
        /// 512 clock cycles
        CYC512 = 0x6,
        /// 1024 clock cycles
        CYC1024 = 0x7,
        /// 2048 clock cycles
        CYC2048 = 0x8,
        /// 4096 clock cycles
        CYC4096 = 0x9,
        /// 8192 clock cycles
        CYC8192 = 0xa,
        /// 16384 clock cycles
        CYC16384 = 0xb,
        _,
    };

    pub const WDT_EWCTRL__EWOFFSET = enum(u4) {
        /// 8 clock cycles
        CYC8 = 0x0,
        /// 16 clock cycles
        CYC16 = 0x1,
        /// 32 clock cycles
        CYC32 = 0x2,
        /// 64 clock cycles
        CYC64 = 0x3,
        /// 128 clock cycles
        CYC128 = 0x4,
        /// 256 clock cycles
        CYC256 = 0x5,
        /// 512 clock cycles
        CYC512 = 0x6,
        /// 1024 clock cycles
        CYC1024 = 0x7,
        /// 2048 clock cycles
        CYC2048 = 0x8,
        /// 4096 clock cycles
        CYC4096 = 0x9,
        /// 8192 clock cycles
        CYC8192 = 0xa,
        /// 16384 clock cycles
        CYC16384 = 0xb,
        _,
    };

    /// Control
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// Enable
        ENABLE: u1,
        /// Watchdog Timer Window Mode Enable
        WEN: u1,
        reserved7: u4 = 0,
        /// Always-On
        ALWAYSON: u1,
    }),
    /// Configuration
    /// offset: 0x01
    CONFIG: mmio.Mmio(packed struct(u8) {
        /// Time-Out Period
        PER: WDT_CONFIG__PER,
        /// Window Mode Time-Out Period
        WINDOW: WDT_CONFIG__WINDOW,
    }),
    /// Early Warning Interrupt Control
    /// offset: 0x02
    EWCTRL: mmio.Mmio(packed struct(u8) {
        /// Early Warning Interrupt Time Offset
        EWOFFSET: WDT_EWCTRL__EWOFFSET,
        padding: u4 = 0,
    }),
    /// offset: 0x03
    reserved3: [1]u8,
    /// Interrupt Enable Clear
    /// offset: 0x04
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Early Warning Interrupt Enable
        EW: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x05
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Early Warning Interrupt Enable
        EW: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x06
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Early Warning
        EW: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x07
    reserved7: [1]u8,
    /// Synchronization Busy
    /// offset: 0x08
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Enable Synchronization Busy
        ENABLE: u1,
        /// Window Enable Synchronization Busy
        WEN: u1,
        /// Always-On Synchronization Busy
        ALWAYSON: u1,
        /// Clear Synchronization Busy
        CLEAR: u1,
        padding: u27 = 0,
    }),
    /// Clear
    /// offset: 0x0c
    CLEAR: mmio.Mmio(packed struct(u8) {
        /// Watchdog Clear
        CLEAR: WDT_CLEAR__CLEAR,
    }),
};
