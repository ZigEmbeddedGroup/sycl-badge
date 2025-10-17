const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const PORT_EVCTRL__EVACT0 = enum(u2) {
    /// Event output to pin
    OUT = 0x0,
    /// Set output register of pin on event
    SET = 0x1,
    /// Clear output register of pin on event
    CLR = 0x2,
    /// Toggle output register of pin on event
    TGL = 0x3,
};

pub const GROUP = extern struct {
    /// Data Direction
    /// offset: 0x00
    DIR: mmio.Mmio(packed struct(u32) {
        /// Port Data Direction
        DIR: u32,
    }),
    /// Data Direction Clear
    /// offset: 0x04
    DIRCLR: mmio.Mmio(packed struct(u32) {
        /// Port Data Direction Clear
        DIRCLR: u32,
    }),
    /// Data Direction Set
    /// offset: 0x08
    DIRSET: mmio.Mmio(packed struct(u32) {
        /// Port Data Direction Set
        DIRSET: u32,
    }),
    /// Data Direction Toggle
    /// offset: 0x0c
    DIRTGL: mmio.Mmio(packed struct(u32) {
        /// Port Data Direction Toggle
        DIRTGL: u32,
    }),
    /// Data Output Value
    /// offset: 0x10
    OUT: mmio.Mmio(packed struct(u32) {
        /// PORT Data Output Value
        OUT: u32,
    }),
    /// Data Output Value Clear
    /// offset: 0x14
    OUTCLR: mmio.Mmio(packed struct(u32) {
        /// PORT Data Output Value Clear
        OUTCLR: u32,
    }),
    /// Data Output Value Set
    /// offset: 0x18
    OUTSET: mmio.Mmio(packed struct(u32) {
        /// PORT Data Output Value Set
        OUTSET: u32,
    }),
    /// Data Output Value Toggle
    /// offset: 0x1c
    OUTTGL: mmio.Mmio(packed struct(u32) {
        /// PORT Data Output Value Toggle
        OUTTGL: u32,
    }),
    /// Data Input Value
    /// offset: 0x20
    IN: mmio.Mmio(packed struct(u32) {
        /// PORT Data Input Value
        IN: u32,
    }),
    /// Control
    /// offset: 0x24
    CTRL: mmio.Mmio(packed struct(u32) {
        /// Input Sampling Mode
        SAMPLING: u32,
    }),
    /// Write Configuration
    /// offset: 0x28
    WRCONFIG: mmio.Mmio(packed struct(u32) {
        /// Pin Mask for Multiple Pin Configuration
        PINMASK: u16,
        /// Peripheral Multiplexer Enable
        PMUXEN: u1,
        /// Input Enable
        INEN: u1,
        /// Pull Enable
        PULLEN: u1,
        reserved22: u3 = 0,
        /// Output Driver Strength Selection
        DRVSTR: u1,
        reserved24: u1 = 0,
        /// Peripheral Multiplexing
        PMUX: u4,
        /// Write PMUX
        WRPMUX: u1,
        reserved30: u1 = 0,
        /// Write PINCFG
        WRPINCFG: u1,
        /// Half-Word Select
        HWSEL: u1,
    }),
    /// Event Input Control
    /// offset: 0x2c
    EVCTRL: mmio.Mmio(packed struct(u32) {
        /// PORT Event Pin Identifier 0
        PID0: u5,
        /// PORT Event Action 0
        EVACT0: PORT_EVCTRL__EVACT0,
        /// PORT Event Input Enable 0
        PORTEI0: u1,
        /// PORT Event Pin Identifier 1
        PID1: u5,
        /// PORT Event Action 1
        EVACT1: u2,
        /// PORT Event Input Enable 1
        PORTEI1: u1,
        /// PORT Event Pin Identifier 2
        PID2: u5,
        /// PORT Event Action 2
        EVACT2: u2,
        /// PORT Event Input Enable 2
        PORTEI2: u1,
        /// PORT Event Pin Identifier 3
        PID3: u5,
        /// PORT Event Action 3
        EVACT3: u2,
        /// PORT Event Input Enable 3
        PORTEI3: u1,
    }),
    /// Peripheral Multiplexing
    /// offset: 0x30
    PMUX: [16]mmio.Mmio(packed struct(u8) {
        /// Peripheral Multiplexing for Even-Numbered Pin
        PMUXE: u4,
        /// Peripheral Multiplexing for Odd-Numbered Pin
        PMUXO: u4,
    }),
    /// Pin Configuration
    /// offset: 0x40
    PINCFG: [32]mmio.Mmio(packed struct(u8) {
        /// Peripheral Multiplexer Enable
        PMUXEN: u1,
        /// Input Enable
        INEN: u1,
        /// Pull Enable
        PULLEN: u1,
        reserved6: u3 = 0,
        /// Output Driver Strength Selection
        DRVSTR: u1,
        padding: u1 = 0,
    }),
    padding: [32]u8,
};

/// Port Module
pub const PORT = extern struct {
    /// offset: 0x00
    GROUP: [2]GROUP,
};
