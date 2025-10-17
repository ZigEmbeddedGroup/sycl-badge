const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const FPU = extern struct {
    pub const FPU_FPDSCR__RMODE = enum(u2) {
        /// Round to Nearest
        RN = 0x0,
        /// Round towards Positive Infinity
        RP = 0x1,
        /// Round towards Negative Infinity
        RM = 0x2,
        /// Round towards Zero
        RZ = 0x3,
    };

    /// offset: 0x00
    reserved0: [4]u8,
    /// Floating-Point Context Control Register
    /// offset: 0x04
    FPCCR: mmio.Mmio(packed struct(u32) {
        LSPACT: u1,
        USER: u1,
        reserved3: u1 = 0,
        THREAD: u1,
        HFRDY: u1,
        MMRDY: u1,
        BFRDY: u1,
        reserved8: u1 = 0,
        MONRDY: u1,
        reserved30: u21 = 0,
        LSPEN: u1,
        ASPEN: u1,
    }),
    /// Floating-Point Context Address Register
    /// offset: 0x08
    FPCAR: mmio.Mmio(packed struct(u32) {
        reserved3: u3 = 0,
        /// Address for FP registers in exception stack frame
        ADDRESS: u29,
    }),
    /// Floating-Point Default Status Control Register
    /// offset: 0x0c
    FPDSCR: mmio.Mmio(packed struct(u32) {
        reserved22: u22 = 0,
        /// Default value for FPSCR.RMODE
        RMODE: FPU_FPDSCR__RMODE,
        /// Default value for FPSCR.FZ
        FZ: u1,
        /// Default value for FPSCR.DN
        DN: u1,
        /// Default value for FPSCR.AHP
        AHP: u1,
        padding: u5 = 0,
    }),
    /// Media and FP Feature Register 0
    /// offset: 0x10
    MVFR0: mmio.Mmio(packed struct(u32) {
        A_SIMD_registers: u4,
        Single_precision: u4,
        Double_precision: u4,
        FP_excep_trapping: u4,
        Divide: u4,
        Square_root: u4,
        Short_vectors: u4,
        FP_rounding_modes: u4,
    }),
    /// Media and FP Feature Register 1
    /// offset: 0x14
    MVFR1: mmio.Mmio(packed struct(u32) {
        FtZ_mode: u4,
        D_NaN_mode: u4,
        reserved24: u16 = 0,
        FP_HPFP: u4,
        FP_fused_MAC: u4,
    }),
};
