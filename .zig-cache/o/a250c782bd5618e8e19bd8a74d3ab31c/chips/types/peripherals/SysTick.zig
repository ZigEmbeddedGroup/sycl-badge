const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const SysTick = extern struct {
    pub const SysTick_CALIB__NOREF = enum(u1) {
        /// The reference clock is provided
        VALUE_0 = 0x0,
        /// The reference clock is not provided
        VALUE_1 = 0x1,
    };

    pub const SysTick_CALIB__SKEW = enum(u1) {
        /// 10ms calibration value is exact
        VALUE_0 = 0x0,
        /// 10ms calibration value is inexact, because of the clock frequency
        VALUE_1 = 0x1,
    };

    pub const SysTick_CSR__CLKSOURCE = enum(u1) {
        /// External clock
        VALUE_0 = 0x0,
        /// Processor clock
        VALUE_1 = 0x1,
    };

    pub const SysTick_CSR__ENABLE = enum(u1) {
        /// Counter disabled
        VALUE_0 = 0x0,
        /// Counter enabled
        VALUE_1 = 0x1,
    };

    pub const SysTick_CSR__TICKINT = enum(u1) {
        /// Counting down to 0 does not assert the SysTick exception request
        VALUE_0 = 0x0,
        /// Counting down to 0 asserts the SysTick exception request
        VALUE_1 = 0x1,
    };

    /// SysTick Control and Status Register
    /// offset: 0x00
    CSR: mmio.Mmio(packed struct(u32) {
        /// SysTick Counter Enable
        ENABLE: SysTick_CSR__ENABLE,
        /// SysTick Exception Request Enable
        TICKINT: SysTick_CSR__TICKINT,
        /// Clock Source 0=external, 1=processor
        CLKSOURCE: SysTick_CSR__CLKSOURCE,
        reserved16: u13 = 0,
        /// Timer counted to 0 since last read of register
        COUNTFLAG: u1,
        padding: u15 = 0,
    }),
    /// SysTick Reload Value Register
    /// offset: 0x04
    RVR: mmio.Mmio(packed struct(u32) {
        /// Value to load into the SysTick Current Value Register when the counter reaches 0
        RELOAD: u24,
        padding: u8 = 0,
    }),
    /// SysTick Current Value Register
    /// offset: 0x08
    CVR: mmio.Mmio(packed struct(u32) {
        /// Current value at the time the register is accessed
        CURRENT: u24,
        padding: u8 = 0,
    }),
    /// SysTick Calibration Value Register
    /// offset: 0x0c
    CALIB: mmio.Mmio(packed struct(u32) {
        /// Reload value to use for 10ms timing
        TENMS: u24,
        reserved30: u6 = 0,
        /// TENMS is rounded from non-integer ratio
        SKEW: SysTick_CALIB__SKEW,
        /// No Separate Reference Clock
        NOREF: SysTick_CALIB__NOREF,
    }),
};
