const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const DSU = extern struct {
    pub const DSU_CFG__DCCDMALEVEL = enum(u2) {
        /// Trigger rises when DCC is empty
        EMPTY = 0x0,
        /// Trigger rises when DCC is full
        FULL = 0x1,
        _,
    };

    pub const DSU_DID__FAMILY = enum(u5) {
        /// General purpose microcontroller
        @"0" = 0x0,
        /// PicoPower
        @"1" = 0x1,
        _,
    };

    pub const DSU_DID__PROCESSOR = enum(u4) {
        /// Cortex-M0+
        CM0P = 0x1,
        /// Cortex-M23
        CM23 = 0x2,
        /// Cortex-M3
        CM3 = 0x3,
        /// Cortex-M4
        CM4 = 0x5,
        /// Cortex-M4 with FPU
        CM4F = 0x6,
        /// Cortex-M33
        CM33 = 0x7,
        _,
    };

    pub const DSU_DID__SERIES = enum(u6) {
        /// Cortex-M0+ processor, basic feature set
        @"0" = 0x0,
        /// Cortex-M0+ processor, USB
        @"1" = 0x1,
        _,
    };

    /// Control
    /// offset: 0x00
    CTRL: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        reserved2: u1 = 0,
        /// 32-bit Cyclic Redundancy Code
        CRC: u1,
        /// Memory built-in self-test
        MBIST: u1,
        /// Chip-Erase
        CE: u1,
        reserved6: u1 = 0,
        /// Auxiliary Row Read
        ARR: u1,
        /// Start Memory Stream Access
        SMSA: u1,
    }),
    /// Status A
    /// offset: 0x01
    STATUSA: mmio.Mmio(packed struct(u8) {
        /// Done
        DONE: u1,
        /// CPU Reset Phase Extension
        CRSTEXT: u1,
        /// Bus Error
        BERR: u1,
        /// Failure
        FAIL: u1,
        /// Protection Error
        PERR: u1,
        padding: u3 = 0,
    }),
    /// Status B
    /// offset: 0x02
    STATUSB: mmio.Mmio(packed struct(u8) {
        /// Protected
        PROT: u1,
        /// Debugger Present
        DBGPRES: u1,
        /// Debug Communication Channel 0 Dirty
        DCCD0: u1,
        /// Debug Communication Channel 1 Dirty
        DCCD1: u1,
        /// Hot-Plugging Enable
        HPE: u1,
        /// Chip Erase Locked
        CELCK: u1,
        /// Test Debug Communication Channel 0 Dirty
        TDCCD0: u1,
        /// Test Debug Communication Channel 1 Dirty
        TDCCD1: u1,
    }),
    /// offset: 0x03
    reserved3: [1]u8,
    /// Address
    /// offset: 0x04
    ADDR: mmio.Mmio(packed struct(u32) {
        /// Access Mode
        AMOD: u2,
        /// Address
        ADDR: u30,
    }),
    /// Length
    /// offset: 0x08
    LENGTH: mmio.Mmio(packed struct(u32) {
        reserved2: u2 = 0,
        /// Length
        LENGTH: u30,
    }),
    /// Data
    /// offset: 0x0c
    DATA: mmio.Mmio(packed struct(u32) {
        /// Data
        DATA: u32,
    }),
    /// Debug Communication Channel n
    /// offset: 0x10
    DCC: [2]mmio.Mmio(packed struct(u32) {
        /// Data
        DATA: u32,
    }),
    /// Device Identification
    /// offset: 0x18
    DID: mmio.Mmio(packed struct(u32) {
        /// Device Select
        DEVSEL: u8,
        /// Revision Number
        REVISION: u4,
        /// Die Number
        DIE: u4,
        /// Series
        SERIES: DSU_DID__SERIES,
        reserved23: u1 = 0,
        /// Family
        FAMILY: DSU_DID__FAMILY,
        /// Processor
        PROCESSOR: DSU_DID__PROCESSOR,
    }),
    /// Configuration
    /// offset: 0x1c
    CFG: mmio.Mmio(packed struct(u32) {
        /// Latency Quality Of Service
        LQOS: u2,
        /// DMA Trigger Level
        DCCDMALEVEL: DSU_CFG__DCCDMALEVEL,
        /// Trace Control
        ETBRAMEN: u1,
        padding: u27 = 0,
    }),
    /// offset: 0x20
    reserved32: [208]u8,
    /// Device Configuration
    /// offset: 0xf0
    DCFG: [2]mmio.Mmio(packed struct(u32) {
        /// Device Configuration
        DCFG: u32,
    }),
    /// offset: 0xf8
    reserved248: [3848]u8,
    /// CoreSight ROM Table Entry 0
    /// offset: 0x1000
    ENTRY0: mmio.Mmio(packed struct(u32) {
        /// Entry Present
        EPRES: u1,
        /// Format
        FMT: u1,
        reserved12: u10 = 0,
        /// Address Offset
        ADDOFF: u20,
    }),
    /// CoreSight ROM Table Entry 1
    /// offset: 0x1004
    ENTRY1: u32,
    /// CoreSight ROM Table End
    /// offset: 0x1008
    END: mmio.Mmio(packed struct(u32) {
        /// End Marker
        END: u32,
    }),
    /// offset: 0x100c
    reserved4108: [4032]u8,
    /// CoreSight ROM Table Memory Type
    /// offset: 0x1fcc
    MEMTYPE: mmio.Mmio(packed struct(u32) {
        /// System Memory Present
        SMEMP: u1,
        padding: u31 = 0,
    }),
    /// Peripheral Identification 4
    /// offset: 0x1fd0
    PID4: mmio.Mmio(packed struct(u32) {
        /// JEP-106 Continuation Code
        JEPCC: u4,
        /// 4KB count
        FKBC: u4,
        padding: u24 = 0,
    }),
    /// Peripheral Identification 5
    /// offset: 0x1fd4
    PID5: u32,
    /// Peripheral Identification 6
    /// offset: 0x1fd8
    PID6: u32,
    /// Peripheral Identification 7
    /// offset: 0x1fdc
    PID7: u32,
    /// Peripheral Identification 0
    /// offset: 0x1fe0
    PID0: mmio.Mmio(packed struct(u32) {
        /// Part Number Low
        PARTNBL: u8,
        padding: u24 = 0,
    }),
    /// Peripheral Identification 1
    /// offset: 0x1fe4
    PID1: mmio.Mmio(packed struct(u32) {
        /// Part Number High
        PARTNBH: u4,
        /// Low part of the JEP-106 Identity Code
        JEPIDCL: u4,
        padding: u24 = 0,
    }),
    /// Peripheral Identification 2
    /// offset: 0x1fe8
    PID2: mmio.Mmio(packed struct(u32) {
        /// JEP-106 Identity Code High
        JEPIDCH: u3,
        /// JEP-106 Identity Code is used
        JEPU: u1,
        /// Revision Number
        REVISION: u4,
        padding: u24 = 0,
    }),
    /// Peripheral Identification 3
    /// offset: 0x1fec
    PID3: mmio.Mmio(packed struct(u32) {
        /// ARM CUSMOD
        CUSMOD: u4,
        /// Revision Number
        REVAND: u4,
        padding: u24 = 0,
    }),
    /// Component Identification 0
    /// offset: 0x1ff0
    CID0: mmio.Mmio(packed struct(u32) {
        /// Preamble Byte 0
        PREAMBLEB0: u8,
        padding: u24 = 0,
    }),
    /// Component Identification 1
    /// offset: 0x1ff4
    CID1: mmio.Mmio(packed struct(u32) {
        /// Preamble
        PREAMBLE: u4,
        /// Component Class
        CCLASS: u4,
        padding: u24 = 0,
    }),
    /// Component Identification 2
    /// offset: 0x1ff8
    CID2: mmio.Mmio(packed struct(u32) {
        /// Preamble Byte 2
        PREAMBLEB2: u8,
        padding: u24 = 0,
    }),
    /// Component Identification 3
    /// offset: 0x1ffc
    CID3: mmio.Mmio(packed struct(u32) {
        /// Preamble Byte 3
        PREAMBLEB3: u8,
        padding: u24 = 0,
    }),
};
