const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const DWT = extern struct {
    /// Control Register
    /// offset: 0x00
    CTRL: mmio.Mmio(packed struct(u32) {
        CYCCNTENA: u1,
        POSTPRESET: u4,
        POSTINIT: u4,
        CYCTAP: u1,
        SYNCTAP: u2,
        PCSAMPLENA: u1,
        reserved16: u3 = 0,
        EXCTRCENA: u1,
        CPIEVTENA: u1,
        EXCEVTENA: u1,
        SLEEPEVTENA: u1,
        LSUEVTENA: u1,
        FOLDEVTENA: u1,
        CYCEVTENA: u1,
        reserved24: u1 = 0,
        NOPRFCNT: u1,
        NOCYCCNT: u1,
        NOEXTTRIG: u1,
        NOTRCPKT: u1,
        NUMCOMP: u4,
    }),
    /// Cycle Count Register
    /// offset: 0x04
    CYCCNT: u32,
    /// CPI Count Register
    /// offset: 0x08
    CPICNT: mmio.Mmio(packed struct(u32) {
        CPICNT: u8,
        padding: u24 = 0,
    }),
    /// Exception Overhead Count Register
    /// offset: 0x0c
    EXCCNT: mmio.Mmio(packed struct(u32) {
        EXCCNT: u8,
        padding: u24 = 0,
    }),
    /// Sleep Count Register
    /// offset: 0x10
    SLEEPCNT: mmio.Mmio(packed struct(u32) {
        SLEEPCNT: u8,
        padding: u24 = 0,
    }),
    /// LSU Count Register
    /// offset: 0x14
    LSUCNT: mmio.Mmio(packed struct(u32) {
        LSUCNT: u8,
        padding: u24 = 0,
    }),
    /// Folded-instruction Count Register
    /// offset: 0x18
    FOLDCNT: mmio.Mmio(packed struct(u32) {
        FOLDCNT: u8,
        padding: u24 = 0,
    }),
    /// Program Counter Sample Register
    /// offset: 0x1c
    PCSR: u32,
    /// Comparator Register 0
    /// offset: 0x20
    COMP0: u32,
    /// Mask Register 0
    /// offset: 0x24
    MASK0: mmio.Mmio(packed struct(u32) {
        MASK: u5,
        padding: u27 = 0,
    }),
    /// Function Register 0
    /// offset: 0x28
    FUNCTION0: mmio.Mmio(packed struct(u32) {
        FUNCTION: u4,
        reserved5: u1 = 0,
        EMITRANGE: u1,
        reserved7: u1 = 0,
        CYCMATCH: u1,
        DATAVMATCH: u1,
        LNK1ENA: u1,
        DATAVSIZE: u2,
        DATAVADDR0: u4,
        DATAVADDR1: u4,
        reserved24: u4 = 0,
        MATCHED: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x2c
    reserved44: [4]u8,
    /// Comparator Register 1
    /// offset: 0x30
    COMP1: u32,
    /// Mask Register 1
    /// offset: 0x34
    MASK1: mmio.Mmio(packed struct(u32) {
        MASK: u5,
        padding: u27 = 0,
    }),
    /// Function Register 1
    /// offset: 0x38
    FUNCTION1: mmio.Mmio(packed struct(u32) {
        FUNCTION: u4,
        reserved5: u1 = 0,
        EMITRANGE: u1,
        reserved7: u1 = 0,
        CYCMATCH: u1,
        DATAVMATCH: u1,
        LNK1ENA: u1,
        DATAVSIZE: u2,
        DATAVADDR0: u4,
        DATAVADDR1: u4,
        reserved24: u4 = 0,
        MATCHED: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x3c
    reserved60: [4]u8,
    /// Comparator Register 2
    /// offset: 0x40
    COMP2: u32,
    /// Mask Register 2
    /// offset: 0x44
    MASK2: mmio.Mmio(packed struct(u32) {
        MASK: u5,
        padding: u27 = 0,
    }),
    /// Function Register 2
    /// offset: 0x48
    FUNCTION2: mmio.Mmio(packed struct(u32) {
        FUNCTION: u4,
        reserved5: u1 = 0,
        EMITRANGE: u1,
        reserved7: u1 = 0,
        CYCMATCH: u1,
        DATAVMATCH: u1,
        LNK1ENA: u1,
        DATAVSIZE: u2,
        DATAVADDR0: u4,
        DATAVADDR1: u4,
        reserved24: u4 = 0,
        MATCHED: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x4c
    reserved76: [4]u8,
    /// Comparator Register 3
    /// offset: 0x50
    COMP3: u32,
    /// Mask Register 3
    /// offset: 0x54
    MASK3: mmio.Mmio(packed struct(u32) {
        MASK: u5,
        padding: u27 = 0,
    }),
    /// Function Register 3
    /// offset: 0x58
    FUNCTION3: mmio.Mmio(packed struct(u32) {
        FUNCTION: u4,
        reserved5: u1 = 0,
        EMITRANGE: u1,
        reserved7: u1 = 0,
        CYCMATCH: u1,
        DATAVMATCH: u1,
        LNK1ENA: u1,
        DATAVSIZE: u2,
        DATAVADDR0: u4,
        DATAVADDR1: u4,
        reserved24: u4 = 0,
        MATCHED: u1,
        padding: u7 = 0,
    }),
};
