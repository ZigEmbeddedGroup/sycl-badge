const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const EVSYS_CHANNEL__EDGSEL = enum(u2) {
    /// No event output when using the resynchronized or synchronous path
    NO_EVT_OUTPUT = 0x0,
    /// Event detection only on the rising edge of the signal from the event generator when using the resynchronized or synchronous path
    RISING_EDGE = 0x1,
    /// Event detection only on the falling edge of the signal from the event generator when using the resynchronized or synchronous path
    FALLING_EDGE = 0x2,
    /// Event detection on rising and falling edges of the signal from the event generator when using the resynchronized or synchronous path
    BOTH_EDGES = 0x3,
};

pub const EVSYS_CHANNEL__PATH = enum(u2) {
    /// Synchronous path
    SYNCHRONOUS = 0x0,
    /// Resynchronized path
    RESYNCHRONIZED = 0x1,
    /// Asynchronous path
    ASYNCHRONOUS = 0x2,
    _,
};

pub const CHANNEL = extern struct {
    /// Channel n Control
    /// offset: 0x00
    CHANNEL: mmio.Mmio(packed struct(u32) {
        /// Event Generator Selection
        EVGEN: u7,
        reserved8: u1 = 0,
        /// Path Selection
        PATH: EVSYS_CHANNEL__PATH,
        /// Edge Detection Selection
        EDGSEL: EVSYS_CHANNEL__EDGSEL,
        reserved14: u2 = 0,
        /// Run in standby
        RUNSTDBY: u1,
        /// Generic Clock On Demand
        ONDEMAND: u1,
        padding: u16 = 0,
    }),
    /// Channel n Interrupt Enable Clear
    /// offset: 0x04
    CHINTENCLR: mmio.Mmio(packed struct(u8) {
        /// Channel Overrun Interrupt Disable
        OVR: u1,
        /// Channel Event Detected Interrupt Disable
        EVD: u1,
        padding: u6 = 0,
    }),
    /// Channel n Interrupt Enable Set
    /// offset: 0x05
    CHINTENSET: mmio.Mmio(packed struct(u8) {
        /// Channel Overrun Interrupt Enable
        OVR: u1,
        /// Channel Event Detected Interrupt Enable
        EVD: u1,
        padding: u6 = 0,
    }),
    /// Channel n Interrupt Flag Status and Clear
    /// offset: 0x06
    CHINTFLAG: mmio.Mmio(packed struct(u8) {
        /// Channel Overrun
        OVR: u1,
        /// Channel Event Detected
        EVD: u1,
        padding: u6 = 0,
    }),
    /// Channel n Status
    /// offset: 0x07
    CHSTATUS: mmio.Mmio(packed struct(u8) {
        /// Ready User
        RDYUSR: u1,
        /// Busy Channel
        BUSYCH: u1,
        padding: u6 = 0,
    }),
};

/// Event System Interface
pub const EVSYS = extern struct {
    /// Control
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// Software Event
    /// offset: 0x04
    SWEVT: mmio.Mmio(packed struct(u32) {
        /// Channel 0 Software Selection
        CHANNEL0: u1,
        /// Channel 1 Software Selection
        CHANNEL1: u1,
        /// Channel 2 Software Selection
        CHANNEL2: u1,
        /// Channel 3 Software Selection
        CHANNEL3: u1,
        /// Channel 4 Software Selection
        CHANNEL4: u1,
        /// Channel 5 Software Selection
        CHANNEL5: u1,
        /// Channel 6 Software Selection
        CHANNEL6: u1,
        /// Channel 7 Software Selection
        CHANNEL7: u1,
        /// Channel 8 Software Selection
        CHANNEL8: u1,
        /// Channel 9 Software Selection
        CHANNEL9: u1,
        /// Channel 10 Software Selection
        CHANNEL10: u1,
        /// Channel 11 Software Selection
        CHANNEL11: u1,
        /// Channel 12 Software Selection
        CHANNEL12: u1,
        /// Channel 13 Software Selection
        CHANNEL13: u1,
        /// Channel 14 Software Selection
        CHANNEL14: u1,
        /// Channel 15 Software Selection
        CHANNEL15: u1,
        /// Channel 16 Software Selection
        CHANNEL16: u1,
        /// Channel 17 Software Selection
        CHANNEL17: u1,
        /// Channel 18 Software Selection
        CHANNEL18: u1,
        /// Channel 19 Software Selection
        CHANNEL19: u1,
        /// Channel 20 Software Selection
        CHANNEL20: u1,
        /// Channel 21 Software Selection
        CHANNEL21: u1,
        /// Channel 22 Software Selection
        CHANNEL22: u1,
        /// Channel 23 Software Selection
        CHANNEL23: u1,
        /// Channel 24 Software Selection
        CHANNEL24: u1,
        /// Channel 25 Software Selection
        CHANNEL25: u1,
        /// Channel 26 Software Selection
        CHANNEL26: u1,
        /// Channel 27 Software Selection
        CHANNEL27: u1,
        /// Channel 28 Software Selection
        CHANNEL28: u1,
        /// Channel 29 Software Selection
        CHANNEL29: u1,
        /// Channel 30 Software Selection
        CHANNEL30: u1,
        /// Channel 31 Software Selection
        CHANNEL31: u1,
    }),
    /// Priority Control
    /// offset: 0x08
    PRICTRL: mmio.Mmio(packed struct(u8) {
        /// Channel Priority Number
        PRI: u4,
        reserved7: u3 = 0,
        /// Round-Robin Scheduling Enable
        RREN: u1,
    }),
    /// offset: 0x09
    reserved9: [7]u8,
    /// Channel Pending Interrupt
    /// offset: 0x10
    INTPEND: mmio.Mmio(packed struct(u16) {
        /// Channel ID
        ID: u4,
        reserved8: u4 = 0,
        /// Channel Overrun
        OVR: u1,
        /// Channel Event Detected
        EVD: u1,
        reserved14: u4 = 0,
        /// Ready
        READY: u1,
        /// Busy
        BUSY: u1,
    }),
    /// offset: 0x12
    reserved18: [2]u8,
    /// Interrupt Status
    /// offset: 0x14
    INTSTATUS: mmio.Mmio(packed struct(u32) {
        /// Channel 0 Pending Interrupt
        CHINT0: u1,
        /// Channel 1 Pending Interrupt
        CHINT1: u1,
        /// Channel 2 Pending Interrupt
        CHINT2: u1,
        /// Channel 3 Pending Interrupt
        CHINT3: u1,
        /// Channel 4 Pending Interrupt
        CHINT4: u1,
        /// Channel 5 Pending Interrupt
        CHINT5: u1,
        /// Channel 6 Pending Interrupt
        CHINT6: u1,
        /// Channel 7 Pending Interrupt
        CHINT7: u1,
        /// Channel 8 Pending Interrupt
        CHINT8: u1,
        /// Channel 9 Pending Interrupt
        CHINT9: u1,
        /// Channel 10 Pending Interrupt
        CHINT10: u1,
        /// Channel 11 Pending Interrupt
        CHINT11: u1,
        padding: u20 = 0,
    }),
    /// Busy Channels
    /// offset: 0x18
    BUSYCH: mmio.Mmio(packed struct(u32) {
        /// Busy Channel 0
        BUSYCH0: u1,
        /// Busy Channel 1
        BUSYCH1: u1,
        /// Busy Channel 2
        BUSYCH2: u1,
        /// Busy Channel 3
        BUSYCH3: u1,
        /// Busy Channel 4
        BUSYCH4: u1,
        /// Busy Channel 5
        BUSYCH5: u1,
        /// Busy Channel 6
        BUSYCH6: u1,
        /// Busy Channel 7
        BUSYCH7: u1,
        /// Busy Channel 8
        BUSYCH8: u1,
        /// Busy Channel 9
        BUSYCH9: u1,
        /// Busy Channel 10
        BUSYCH10: u1,
        /// Busy Channel 11
        BUSYCH11: u1,
        padding: u20 = 0,
    }),
    /// Ready Users
    /// offset: 0x1c
    READYUSR: mmio.Mmio(packed struct(u32) {
        /// Ready User for Channel 0
        READYUSR0: u1,
        /// Ready User for Channel 1
        READYUSR1: u1,
        /// Ready User for Channel 2
        READYUSR2: u1,
        /// Ready User for Channel 3
        READYUSR3: u1,
        /// Ready User for Channel 4
        READYUSR4: u1,
        /// Ready User for Channel 5
        READYUSR5: u1,
        /// Ready User for Channel 6
        READYUSR6: u1,
        /// Ready User for Channel 7
        READYUSR7: u1,
        /// Ready User for Channel 8
        READYUSR8: u1,
        /// Ready User for Channel 9
        READYUSR9: u1,
        /// Ready User for Channel 10
        READYUSR10: u1,
        /// Ready User for Channel 11
        READYUSR11: u1,
        padding: u20 = 0,
    }),
    /// offset: 0x20
    CHANNEL: [32]CHANNEL,
    /// offset: 0x28
    reserved40: [248]u8,
    /// User Multiplexer n
    /// offset: 0x120
    USER: [67]mmio.Mmio(packed struct(u32) {
        /// Channel Event Selection
        CHANNEL: u6,
        padding: u26 = 0,
    }),
};
