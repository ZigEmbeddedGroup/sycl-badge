const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const ETM = extern struct {
    /// ETM Main Control Register
    /// offset: 0x00
    CR: mmio.Mmio(packed struct(u32) {
        /// ETM Power Down
        ETMPD: u1,
        reserved4: u3 = 0,
        /// Port Size bits 2:0
        PORTSIZE: u3,
        /// Stall Processor
        STALL: u1,
        /// Branch Output
        BROUT: u1,
        /// Debug Request Control
        DBGRQ: u1,
        /// ETM Programming
        PROG: u1,
        /// ETM Port Select
        PORTSEL: u1,
        reserved13: u1 = 0,
        /// Port Mode bit 2
        PORTMODE2: u1,
        reserved16: u2 = 0,
        /// Port Mode bits 1:0
        PORTMODE: u2,
        reserved21: u3 = 0,
        /// Port Size bit 3
        PORTSIZE3: u1,
        reserved28: u6 = 0,
        /// TimeStamp Enable
        TSEN: u1,
        padding: u3 = 0,
    }),
    /// ETM Configuration Code Register
    /// offset: 0x04
    CCR: u32,
    /// ETM Trigger Event Register
    /// offset: 0x08
    TRIGGER: u32,
    /// offset: 0x0c
    reserved12: [4]u8,
    /// ETM Status Register
    /// offset: 0x10
    SR: u32,
    /// ETM System Configuration Register
    /// offset: 0x14
    SCR: u32,
    /// offset: 0x18
    reserved24: [8]u8,
    /// ETM TraceEnable Event Register
    /// offset: 0x20
    TEEVR: u32,
    /// ETM TraceEnable Control 1 Register
    /// offset: 0x24
    TECR1: u32,
    /// ETM FIFO Full Level Register
    /// offset: 0x28
    FFLR: u32,
    /// offset: 0x2c
    reserved44: [276]u8,
    /// ETM Free-running Counter Reload Value
    /// offset: 0x140
    CNTRLDVR1: u32,
    /// offset: 0x144
    reserved324: [156]u8,
    /// ETM Synchronization Frequency Register
    /// offset: 0x1e0
    SYNCFR: u32,
    /// ETM ID Register
    /// offset: 0x1e4
    IDR: u32,
    /// ETM Configuration Code Extension Register
    /// offset: 0x1e8
    CCER: u32,
    /// offset: 0x1ec
    reserved492: [4]u8,
    /// ETM TraceEnable Start/Stop EmbeddedICE Control Register
    /// offset: 0x1f0
    TESSEICR: u32,
    /// offset: 0x1f4
    reserved500: [4]u8,
    /// ETM TimeStamp Event Register
    /// offset: 0x1f8
    TSEVT: u32,
    /// offset: 0x1fc
    reserved508: [4]u8,
    /// ETM CoreSight Trace ID Register
    /// offset: 0x200
    TRACEIDR: u32,
    /// offset: 0x204
    reserved516: [4]u8,
    /// ETM ID Register 2
    /// offset: 0x208
    IDR2: u32,
    /// offset: 0x20c
    reserved524: [264]u8,
    /// ETM Device Power-Down Status Register
    /// offset: 0x314
    PDSR: u32,
    /// offset: 0x318
    reserved792: [3016]u8,
    /// ETM Integration Test Miscellaneous Inputs
    /// offset: 0xee0
    ITMISCIN: u32,
    /// offset: 0xee4
    reserved3812: [4]u8,
    /// ETM Integration Test Trigger Out
    /// offset: 0xee8
    ITTRIGOUT: u32,
    /// offset: 0xeec
    reserved3820: [4]u8,
    /// ETM Integration Test ATB Control 2
    /// offset: 0xef0
    ITATBCTR2: u32,
    /// offset: 0xef4
    reserved3828: [4]u8,
    /// ETM Integration Test ATB Control 0
    /// offset: 0xef8
    ITATBCTR0: u32,
    /// offset: 0xefc
    reserved3836: [4]u8,
    /// ETM Integration Mode Control Register
    /// offset: 0xf00
    ITCTRL: mmio.Mmio(packed struct(u32) {
        INTEGRATION: u1,
        padding: u31 = 0,
    }),
    /// offset: 0xf04
    reserved3844: [156]u8,
    /// ETM Claim Tag Set Register
    /// offset: 0xfa0
    CLAIMSET: u32,
    /// ETM Claim Tag Clear Register
    /// offset: 0xfa4
    CLAIMCLR: u32,
    /// offset: 0xfa8
    reserved4008: [8]u8,
    /// ETM Lock Access Register
    /// offset: 0xfb0
    LAR: u32,
    /// ETM Lock Status Register
    /// offset: 0xfb4
    LSR: mmio.Mmio(packed struct(u32) {
        Present: u1,
        Access: u1,
        ByteAcc: u1,
        padding: u29 = 0,
    }),
    /// ETM Authentication Status Register
    /// offset: 0xfb8
    AUTHSTATUS: u32,
    /// offset: 0xfbc
    reserved4028: [16]u8,
    /// ETM CoreSight Device Type Register
    /// offset: 0xfcc
    DEVTYPE: u32,
    /// ETM Peripheral Identification Register #4
    /// offset: 0xfd0
    PIDR4: u32,
    /// ETM Peripheral Identification Register #5
    /// offset: 0xfd4
    PIDR5: u32,
    /// ETM Peripheral Identification Register #6
    /// offset: 0xfd8
    PIDR6: u32,
    /// ETM Peripheral Identification Register #7
    /// offset: 0xfdc
    PIDR7: u32,
    /// ETM Peripheral Identification Register #0
    /// offset: 0xfe0
    PIDR0: u32,
    /// ETM Peripheral Identification Register #1
    /// offset: 0xfe4
    PIDR1: u32,
    /// ETM Peripheral Identification Register #2
    /// offset: 0xfe8
    PIDR2: u32,
    /// ETM Peripheral Identification Register #3
    /// offset: 0xfec
    PIDR3: u32,
    /// ETM Component Identification Register #0
    /// offset: 0xff0
    CIDR0: u32,
    /// ETM Component Identification Register #1
    /// offset: 0xff4
    CIDR1: u32,
    /// ETM Component Identification Register #2
    /// offset: 0xff8
    CIDR2: u32,
    /// ETM Component Identification Register #3
    /// offset: 0xffc
    CIDR3: u32,
};
