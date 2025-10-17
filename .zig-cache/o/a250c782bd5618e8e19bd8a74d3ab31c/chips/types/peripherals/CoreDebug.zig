const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const CoreDebug = extern struct {
    /// Debug Halting Control and Status Register
    /// offset: 0x00
    DHCSR: mmio.Mmio(packed struct(u32) {
        C_DEBUGEN: u1,
        C_HALT: u1,
        C_STEP: u1,
        C_MASKINTS: u1,
        reserved5: u1 = 0,
        C_SNAPSTALL: u1,
        reserved16: u10 = 0,
        S_REGRDY: u1,
        S_HALT: u1,
        S_SLEEP: u1,
        S_LOCKUP: u1,
        reserved24: u4 = 0,
        S_RETIRE_ST: u1,
        S_RESET_ST: u1,
        padding: u6 = 0,
    }),
    /// Debug Core Register Selector Register
    /// offset: 0x04
    DCRSR: mmio.Mmio(packed struct(u32) {
        REGSEL: u5,
        reserved16: u11 = 0,
        REGWnR: u1,
        padding: u15 = 0,
    }),
    /// Debug Core Register Data Register
    /// offset: 0x08
    DCRDR: u32,
    /// Debug Exception and Monitor Control Register
    /// offset: 0x0c
    DEMCR: mmio.Mmio(packed struct(u32) {
        VC_CORERESET: u1,
        reserved4: u3 = 0,
        VC_MMERR: u1,
        VC_NOCPERR: u1,
        VC_CHKERR: u1,
        VC_STATERR: u1,
        VC_BUSERR: u1,
        VC_INTERR: u1,
        VC_HARDERR: u1,
        reserved16: u5 = 0,
        MON_EN: u1,
        MON_PEND: u1,
        MON_STEP: u1,
        MON_REQ: u1,
        reserved24: u4 = 0,
        TRCENA: u1,
        padding: u7 = 0,
    }),
};
