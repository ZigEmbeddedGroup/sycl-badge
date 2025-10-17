const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const PDEC = extern struct {
    pub const PDEC_CTRLA__CONF = enum(u3) {
        /// Quadrature decoder direction
        X4 = 0x0,
        /// Secure Quadrature decoder direction
        X4S = 0x1,
        /// Decoder direction
        X2 = 0x2,
        /// Secure decoder direction
        X2S = 0x3,
        /// Auto correction mode
        AUTOC = 0x4,
        _,
    };

    pub const PDEC_CTRLA__MODE = enum(u2) {
        /// QDEC operating mode
        QDEC = 0x0,
        /// HALL operating mode
        HALL = 0x1,
        /// COUNTER operating mode
        COUNTER = 0x2,
        _,
    };

    pub const PDEC_CTRLBCLR__CMD = enum(u3) {
        /// No action
        NONE = 0x0,
        /// Force a counter restart or retrigger
        RETRIGGER = 0x1,
        /// Force update of double buffered registers
        UPDATE = 0x2,
        /// Force a read synchronization of COUNT
        READSYNC = 0x3,
        /// Start QDEC/HALL
        START = 0x4,
        /// Stop QDEC/HALL
        STOP = 0x5,
        _,
    };

    pub const PDEC_CTRLBSET__CMD = enum(u3) {
        /// No action
        NONE = 0x0,
        /// Force a counter restart or retrigger
        RETRIGGER = 0x1,
        /// Force update of double buffered registers
        UPDATE = 0x2,
        /// Force a read synchronization of COUNT
        READSYNC = 0x3,
        /// Start QDEC/HALL
        START = 0x4,
        /// Stop QDEC/HALL
        STOP = 0x5,
        _,
    };

    pub const PDEC_EVCTRL__EVACT = enum(u2) {
        /// Event action disabled
        OFF = 0x0,
        /// Start, restart or retrigger on event
        RETRIGGER = 0x1,
        /// Count on event
        COUNT = 0x2,
        _,
    };

    pub const PDEC_PRESCBUF__PRESCBUF = enum(u4) {
        /// No division
        DIV1 = 0x0,
        /// Divide by 2
        DIV2 = 0x1,
        /// Divide by 4
        DIV4 = 0x2,
        /// Divide by 8
        DIV8 = 0x3,
        /// Divide by 16
        DIV16 = 0x4,
        /// Divide by 32
        DIV32 = 0x5,
        /// Divide by 64
        DIV64 = 0x6,
        /// Divide by 128
        DIV128 = 0x7,
        /// Divide by 256
        DIV256 = 0x8,
        /// Divide by 512
        DIV512 = 0x9,
        /// Divide by 1024
        DIV1024 = 0xa,
        _,
    };

    pub const PDEC_PRESC__PRESC = enum(u4) {
        /// No division
        DIV1 = 0x0,
        /// Divide by 2
        DIV2 = 0x1,
        /// Divide by 4
        DIV4 = 0x2,
        /// Divide by 8
        DIV8 = 0x3,
        /// Divide by 16
        DIV16 = 0x4,
        /// Divide by 32
        DIV32 = 0x5,
        /// Divide by 64
        DIV64 = 0x6,
        /// Divide by 128
        DIV128 = 0x7,
        /// Divide by 256
        DIV256 = 0x8,
        /// Divide by 512
        DIV512 = 0x9,
        /// Divide by 1024
        DIV1024 = 0xa,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u32) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        /// Operation Mode
        MODE: PDEC_CTRLA__MODE,
        reserved6: u2 = 0,
        /// Run in Standby
        RUNSTDBY: u1,
        reserved8: u1 = 0,
        /// PDEC Configuration
        CONF: PDEC_CTRLA__CONF,
        /// Auto Lock
        ALOCK: u1,
        reserved14: u2 = 0,
        /// PDEC Phase A and B Swap
        SWAP: u1,
        /// Period Enable
        PEREN: u1,
        /// PDEC Input From Pin 0 Enable
        PINEN0: u1,
        /// PDEC Input From Pin 1 Enable
        PINEN1: u1,
        /// PDEC Input From Pin 2 Enable
        PINEN2: u1,
        reserved20: u1 = 0,
        /// IO Pin 0 Invert Enable
        PINVEN0: u1,
        /// IO Pin 1 Invert Enable
        PINVEN1: u1,
        /// IO Pin 2 Invert Enable
        PINVEN2: u1,
        reserved24: u1 = 0,
        /// Angular Counter Length
        ANGULAR: u3,
        reserved28: u1 = 0,
        /// Maximum Consecutive Missing Pulses
        MAXCMP: u4,
    }),
    /// Control B Clear
    /// offset: 0x04
    CTRLBCLR: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// Lock Update
        LUPD: u1,
        reserved5: u3 = 0,
        /// Command
        CMD: PDEC_CTRLBCLR__CMD,
    }),
    /// Control B Set
    /// offset: 0x05
    CTRLBSET: mmio.Mmio(packed struct(u8) {
        reserved1: u1 = 0,
        /// Lock Update
        LUPD: u1,
        reserved5: u3 = 0,
        /// Command
        CMD: PDEC_CTRLBSET__CMD,
    }),
    /// Event Control
    /// offset: 0x06
    EVCTRL: mmio.Mmio(packed struct(u16) {
        /// Event Action
        EVACT: PDEC_EVCTRL__EVACT,
        /// Inverted Event Input Enable
        EVINV: u3,
        /// Event Input Enable
        EVEI: u3,
        /// Overflow/Underflow Output Event Enable
        OVFEO: u1,
        /// Error Output Event Enable
        ERREO: u1,
        /// Direction Output Event Enable
        DIREO: u1,
        /// Velocity Output Event Enable
        VLCEO: u1,
        /// Match Channel 0 Event Output Enable
        MCEO0: u1,
        /// Match Channel 1 Event Output Enable
        MCEO1: u1,
        padding: u2 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x08
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Overflow/Underflow Interrupt Disable
        OVF: u1,
        /// Error Interrupt Disable
        ERR: u1,
        /// Direction Interrupt Disable
        DIR: u1,
        /// Velocity Interrupt Disable
        VLC: u1,
        /// Channel 0 Compare Match Disable
        MC0: u1,
        /// Channel 1 Compare Match Disable
        MC1: u1,
        padding: u2 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x09
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Overflow/Underflow Interrupt Enable
        OVF: u1,
        /// Error Interrupt Enable
        ERR: u1,
        /// Direction Interrupt Enable
        DIR: u1,
        /// Velocity Interrupt Enable
        VLC: u1,
        /// Channel 0 Compare Match Enable
        MC0: u1,
        /// Channel 1 Compare Match Enable
        MC1: u1,
        padding: u2 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x0a
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Overflow/Underflow
        OVF: u1,
        /// Error
        ERR: u1,
        /// Direction Change
        DIR: u1,
        /// Velocity
        VLC: u1,
        /// Channel 0 Compare Match
        MC0: u1,
        /// Channel 1 Compare Match
        MC1: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x0b
    reserved11: [1]u8,
    /// Status
    /// offset: 0x0c
    STATUS: mmio.Mmio(packed struct(u16) {
        /// Quadrature Error Flag
        QERR: u1,
        /// Index Error Flag
        IDXERR: u1,
        /// Missing Pulse Error flag
        MPERR: u1,
        reserved4: u1 = 0,
        /// Window Error Flag
        WINERR: u1,
        /// Hall Error Flag
        HERR: u1,
        /// Stop
        STOP: u1,
        /// Direction Status Flag
        DIR: u1,
        /// Prescaler Buffer Valid
        PRESCBUFV: u1,
        /// Filter Buffer Valid
        FILTERBUFV: u1,
        reserved12: u2 = 0,
        /// Compare Channel 0 Buffer Valid
        CCBUFV0: u1,
        /// Compare Channel 1 Buffer Valid
        CCBUFV1: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x0e
    reserved14: [1]u8,
    /// Debug Control
    /// offset: 0x0f
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Run Mode
        DBGRUN: u1,
        padding: u7 = 0,
    }),
    /// Synchronization Status
    /// offset: 0x10
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// Software Reset Synchronization Busy
        SWRST: u1,
        /// Enable Synchronization Busy
        ENABLE: u1,
        /// Control B Synchronization Busy
        CTRLB: u1,
        /// Status Synchronization Busy
        STATUS: u1,
        /// Prescaler Synchronization Busy
        PRESC: u1,
        /// Filter Synchronization Busy
        FILTER: u1,
        /// Count Synchronization Busy
        COUNT: u1,
        /// Compare Channel 0 Synchronization Busy
        CC0: u1,
        /// Compare Channel 1 Synchronization Busy
        CC1: u1,
        padding: u23 = 0,
    }),
    /// Prescaler Value
    /// offset: 0x14
    PRESC: mmio.Mmio(packed struct(u8) {
        /// Prescaler Value
        PRESC: PDEC_PRESC__PRESC,
        padding: u4 = 0,
    }),
    /// Filter Value
    /// offset: 0x15
    FILTER: mmio.Mmio(packed struct(u8) {
        /// Filter Value
        FILTER: u8,
    }),
    /// offset: 0x16
    reserved22: [2]u8,
    /// Prescaler Buffer Value
    /// offset: 0x18
    PRESCBUF: mmio.Mmio(packed struct(u8) {
        /// Prescaler Buffer Value
        PRESCBUF: PDEC_PRESCBUF__PRESCBUF,
        padding: u4 = 0,
    }),
    /// Filter Buffer Value
    /// offset: 0x19
    FILTERBUF: mmio.Mmio(packed struct(u8) {
        /// Filter Buffer Value
        FILTERBUF: u8,
    }),
    /// offset: 0x1a
    reserved26: [2]u8,
    /// Counter Value
    /// offset: 0x1c
    COUNT: mmio.Mmio(packed struct(u32) {
        /// Counter Value
        COUNT: u16,
        padding: u16 = 0,
    }),
    /// Channel n Compare Value
    /// offset: 0x20
    CC: [2]mmio.Mmio(packed struct(u32) {
        /// Channel Compare Value
        CC: u16,
        padding: u16 = 0,
    }),
    /// offset: 0x28
    reserved40: [8]u8,
    /// Channel Compare Buffer Value
    /// offset: 0x30
    CCBUF: [2]mmio.Mmio(packed struct(u32) {
        /// Channel Compare Buffer Value
        CCBUF: u16,
        padding: u16 = 0,
    }),
};
