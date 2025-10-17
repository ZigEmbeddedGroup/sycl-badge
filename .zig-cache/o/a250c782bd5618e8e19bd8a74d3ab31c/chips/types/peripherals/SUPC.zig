const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const SUPC = extern struct {
    pub const SUPC_BBPS__CONF = enum(u1) {
        /// The power switch is handled by the BOD33
        BOD33 = 0x0,
        /// In Backup Domain, the backup domain is always supplied by battery backup power
        FORCED = 0x1,
    };

    pub const SUPC_BOD33__ACTION = enum(u2) {
        /// No action
        NONE = 0x0,
        /// The BOD33 generates a reset
        RESET = 0x1,
        /// The BOD33 generates an interrupt
        INT = 0x2,
        /// The BOD33 puts the device in backup sleep mode
        BKUP = 0x3,
    };

    pub const SUPC_BOD33__PSEL = enum(u3) {
        /// Not divided
        NODIV = 0x0,
        /// Divide clock by 4
        DIV4 = 0x1,
        /// Divide clock by 8
        DIV8 = 0x2,
        /// Divide clock by 16
        DIV16 = 0x3,
        /// Divide clock by 32
        DIV32 = 0x4,
        /// Divide clock by 64
        DIV64 = 0x5,
        /// Divide clock by 128
        DIV128 = 0x6,
        /// Divide clock by 256
        DIV256 = 0x7,
    };

    pub const SUPC_VREF__SEL = enum(u4) {
        /// 1.0V voltage reference typical value
        @"1V0" = 0x0,
        /// 1.1V voltage reference typical value
        @"1V1" = 0x1,
        /// 1.2V voltage reference typical value
        @"1V2" = 0x2,
        /// 1.25V voltage reference typical value
        @"1V25" = 0x3,
        /// 2.0V voltage reference typical value
        @"2V0" = 0x4,
        /// 2.2V voltage reference typical value
        @"2V2" = 0x5,
        /// 2.4V voltage reference typical value
        @"2V4" = 0x6,
        /// 2.5V voltage reference typical value
        @"2V5" = 0x7,
        _,
    };

    pub const SUPC_VREG__SEL = enum(u1) {
        /// LDO selection
        LDO = 0x0,
        /// Buck selection
        BUCK = 0x1,
    };

    /// Interrupt Enable Clear
    /// offset: 0x00
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// BOD33 Ready
        BOD33RDY: u1,
        /// BOD33 Detection
        BOD33DET: u1,
        /// BOD33 Synchronization Ready
        B33SRDY: u1,
        reserved8: u5 = 0,
        /// Voltage Regulator Ready
        VREGRDY: u1,
        reserved10: u1 = 0,
        /// VDDCORE Ready
        VCORERDY: u1,
        padding: u21 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x04
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// BOD33 Ready
        BOD33RDY: u1,
        /// BOD33 Detection
        BOD33DET: u1,
        /// BOD33 Synchronization Ready
        B33SRDY: u1,
        reserved8: u5 = 0,
        /// Voltage Regulator Ready
        VREGRDY: u1,
        reserved10: u1 = 0,
        /// VDDCORE Ready
        VCORERDY: u1,
        padding: u21 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x08
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// BOD33 Ready
        BOD33RDY: u1,
        /// BOD33 Detection
        BOD33DET: u1,
        /// BOD33 Synchronization Ready
        B33SRDY: u1,
        reserved8: u5 = 0,
        /// Voltage Regulator Ready
        VREGRDY: u1,
        reserved10: u1 = 0,
        /// VDDCORE Ready
        VCORERDY: u1,
        padding: u21 = 0,
    }),
    /// Power and Clocks Status
    /// offset: 0x0c
    STATUS: mmio.Mmio(packed struct(u32) {
        /// BOD33 Ready
        BOD33RDY: u1,
        /// BOD33 Detection
        BOD33DET: u1,
        /// BOD33 Synchronization Ready
        B33SRDY: u1,
        reserved8: u5 = 0,
        /// Voltage Regulator Ready
        VREGRDY: u1,
        reserved10: u1 = 0,
        /// VDDCORE Ready
        VCORERDY: u1,
        padding: u21 = 0,
    }),
    /// BOD33 Control
    /// offset: 0x10
    BOD33: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Enable
        ENABLE: u1,
        /// Action when Threshold Crossed
        ACTION: SUPC_BOD33__ACTION,
        /// Configuration in Standby mode
        STDBYCFG: u1,
        /// Run in Standby mode
        RUNSTDBY: u1,
        /// Run in Hibernate mode
        RUNHIB: u1,
        /// Run in Backup mode
        RUNBKUP: u1,
        /// Hysteresis value
        HYST: u4,
        /// Prescaler Select
        PSEL: SUPC_BOD33__PSEL,
        reserved16: u1 = 0,
        /// Threshold Level for VDD
        LEVEL: u8,
        /// Threshold Level in battery backup sleep mode for VBAT
        VBATLEVEL: u8,
    }),
    /// offset: 0x14
    reserved20: [4]u8,
    /// VREG Control
    /// offset: 0x18
    VREG: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Enable
        ENABLE: u1,
        /// Voltage Regulator Selection
        SEL: SUPC_VREG__SEL,
        reserved7: u4 = 0,
        /// Run in Backup mode
        RUNBKUP: u1,
        reserved16: u8 = 0,
        /// Voltage Scaling Enable
        VSEN: u1,
        reserved24: u7 = 0,
        /// Voltage Scaling Period
        VSPER: u3,
        padding: u5 = 0,
    }),
    /// VREF Control
    /// offset: 0x1c
    VREF: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Temperature Sensor Output Enable
        TSEN: u1,
        /// Voltage Reference Output Enable
        VREFOE: u1,
        /// Temperature Sensor Selection
        TSSEL: u1,
        reserved6: u2 = 0,
        /// Run during Standby
        RUNSTDBY: u1,
        /// On Demand Contrl
        ONDEMAND: u1,
        reserved16: u8 = 0,
        /// Voltage Reference Selection
        SEL: SUPC_VREF__SEL,
        padding: u12 = 0,
    }),
    /// Battery Backup Power Switch
    /// offset: 0x20
    BBPS: mmio.Mmio(packed struct(u32) {
        /// Battery Backup Configuration
        CONF: SUPC_BBPS__CONF,
        reserved2: u1 = 0,
        /// Wake Enable
        WAKEEN: u1,
        padding: u29 = 0,
    }),
    /// Backup Output Control
    /// offset: 0x24
    BKOUT: mmio.Mmio(packed struct(u32) {
        /// Enable OUT0
        ENOUT0: u1,
        /// Enable OUT1
        ENOUT1: u1,
        reserved8: u6 = 0,
        /// Clear OUT0
        CLROUT0: u1,
        /// Clear OUT1
        CLROUT1: u1,
        reserved16: u6 = 0,
        /// Set OUT0
        SETOUT0: u1,
        /// Set OUT1
        SETOUT1: u1,
        reserved24: u6 = 0,
        /// RTC Toggle OUT0
        RTCTGLOUT0: u1,
        /// RTC Toggle OUT1
        RTCTGLOUT1: u1,
        padding: u6 = 0,
    }),
    /// Backup Input Control
    /// offset: 0x28
    BKIN: mmio.Mmio(packed struct(u32) {
        /// Backup Input 0
        BKIN0: u1,
        /// Backup Input 1
        BKIN1: u1,
        padding: u30 = 0,
    }),
};
