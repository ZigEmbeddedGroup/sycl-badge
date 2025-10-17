const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const ICM_CFG__UALGO = enum(u3) {
    /// SHA1 Algorithm
    SHA1 = 0x0,
    /// SHA256 Algorithm
    SHA256 = 0x1,
    /// SHA224 Algorithm
    SHA224 = 0x4,
    _,
};

pub const ICM_RCFG__BEIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__CDWBN = enum(u1) {
    WRBA = 0x0,
    COMP = 0x1,
};

pub const ICM_RCFG__DMIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__ECIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__EOM = enum(u1) {
    NO = 0x0,
    YES = 0x1,
};

pub const ICM_RCFG__PROCDLY = enum(u1) {
    SHORT = 0x0,
    LONG = 0x1,
};

pub const ICM_RCFG__RHIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__SUIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__WCIEN = enum(u1) {
    EN = 0x0,
    DIS = 0x1,
};

pub const ICM_RCFG__WRAP = enum(u1) {
    NO = 0x0,
    YES = 0x1,
};

pub const ICM_UASR__URAT = enum(u3) {
    /// Unspecified structure member set to one detected when the descriptor is loaded
    UNSPEC_STRUCT_MEMBER = 0x0,
    /// CFG modified during active monitoring
    CFG_MODIFIED = 0x1,
    /// DSCR modified during active monitoring
    DSCR_MODIFIED = 0x2,
    /// HASH modified during active monitoring
    HASH_MODIFIED = 0x3,
    /// Write-only register read access
    READ_ACCESS = 0x4,
    _,
};

/// Integrity Check Monitor
pub const ICM = extern struct {
    /// Configuration
    /// offset: 0x00
    CFG: mmio.Mmio(packed struct(u32) {
        /// Write Back Disable
        WBDIS: u1,
        /// End of Monitoring Disable
        EOMDIS: u1,
        /// Secondary List Branching Disable
        SLBDIS: u1,
        reserved4: u1 = 0,
        /// Bus Burden Control
        BBC: u4,
        /// Automatic Switch To Compare Digest
        ASCD: u1,
        /// Dual Input Buffer
        DUALBUFF: u1,
        reserved12: u2 = 0,
        /// User Initial Hash Value
        UIHASH: u1,
        /// User SHA Algorithm
        UALGO: ICM_CFG__UALGO,
        /// Region Hash Area Protection
        HAPROT: u6,
        reserved24: u2 = 0,
        /// Region Descriptor Area Protection
        DAPROT: u6,
        padding: u2 = 0,
    }),
    /// Control
    /// offset: 0x04
    CTRL: mmio.Mmio(packed struct(u32) {
        /// ICM Enable
        ENABLE: u1,
        /// ICM Disable Register
        DISABLE: u1,
        /// Software Reset
        SWRST: u1,
        reserved4: u1 = 0,
        /// Recompute Internal Hash
        REHASH: u4,
        /// Region Monitoring Disable
        RMDIS: u4,
        /// Region Monitoring Enable
        RMEN: u4,
        padding: u16 = 0,
    }),
    /// Status
    /// offset: 0x08
    SR: mmio.Mmio(packed struct(u32) {
        /// ICM Controller Enable Register
        ENABLE: u1,
        reserved8: u7 = 0,
        /// RAW Region Monitoring Disabled Status
        RAWRMDIS: u4,
        /// Region Monitoring Disabled Status
        RMDIS: u4,
        padding: u16 = 0,
    }),
    /// offset: 0x0c
    reserved12: [4]u8,
    /// Interrupt Enable
    /// offset: 0x10
    IER: mmio.Mmio(packed struct(u32) {
        /// Region Hash Completed Interrupt Enable
        RHC: u4,
        /// Region Digest Mismatch Interrupt Enable
        RDM: u4,
        /// Region Bus Error Interrupt Enable
        RBE: u4,
        /// Region Wrap Condition detected Interrupt Enable
        RWC: u4,
        /// Region End bit Condition Detected Interrupt Enable
        REC: u4,
        /// Region Status Updated Interrupt Disable
        RSU: u4,
        /// Undefined Register Access Detection Interrupt Enable
        URAD: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Disable
    /// offset: 0x14
    IDR: mmio.Mmio(packed struct(u32) {
        /// Region Hash Completed Interrupt Disable
        RHC: u4,
        /// Region Digest Mismatch Interrupt Disable
        RDM: u4,
        /// Region Bus Error Interrupt Disable
        RBE: u4,
        /// Region Wrap Condition Detected Interrupt Disable
        RWC: u4,
        /// Region End bit Condition detected Interrupt Disable
        REC: u4,
        /// Region Status Updated Interrupt Disable
        RSU: u4,
        /// Undefined Register Access Detection Interrupt Disable
        URAD: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Mask
    /// offset: 0x18
    IMR: mmio.Mmio(packed struct(u32) {
        /// Region Hash Completed Interrupt Mask
        RHC: u4,
        /// Region Digest Mismatch Interrupt Mask
        RDM: u4,
        /// Region Bus Error Interrupt Mask
        RBE: u4,
        /// Region Wrap Condition Detected Interrupt Mask
        RWC: u4,
        /// Region End bit Condition Detected Interrupt Mask
        REC: u4,
        /// Region Status Updated Interrupt Mask
        RSU: u4,
        /// Undefined Register Access Detection Interrupt Mask
        URAD: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Status
    /// offset: 0x1c
    ISR: mmio.Mmio(packed struct(u32) {
        /// Region Hash Completed
        RHC: u4,
        /// Region Digest Mismatch
        RDM: u4,
        /// Region Bus Error
        RBE: u4,
        /// Region Wrap Condition Detected
        RWC: u4,
        /// Region End bit Condition Detected
        REC: u4,
        /// Region Status Updated Detected
        RSU: u4,
        /// Undefined Register Access Detection Status
        URAD: u1,
        padding: u7 = 0,
    }),
    /// Undefined Access Status
    /// offset: 0x20
    UASR: mmio.Mmio(packed struct(u32) {
        /// Undefined Register Access Trace
        URAT: ICM_UASR__URAT,
        padding: u29 = 0,
    }),
    /// offset: 0x24
    reserved36: [12]u8,
    /// Region Descriptor Area Start Address
    /// offset: 0x30
    DSCR: mmio.Mmio(packed struct(u32) {
        reserved6: u6 = 0,
        /// Descriptor Area Start Address
        DASA: u26,
    }),
    /// Region Hash Area Start Address
    /// offset: 0x34
    HASH: mmio.Mmio(packed struct(u32) {
        reserved7: u7 = 0,
        /// Hash Area Start Address
        HASA: u25,
    }),
    /// User Initial Hash Value n
    /// offset: 0x38
    UIHVAL: [8]mmio.Mmio(packed struct(u32) {
        /// Initial Hash Value
        VAL: u32,
    }),
};

/// Integrity Check Monitor
pub const ICM_DESCRIPTOR = extern struct {
    /// Region Start Address
    /// offset: 0x00
    RADDR: u32,
    /// Region Configuration
    /// offset: 0x04
    RCFG: mmio.Mmio(packed struct(u32) {
        /// Compare Digest Write Back
        CDWBN: ICM_RCFG__CDWBN,
        /// Region Wrap
        WRAP: ICM_RCFG__WRAP,
        /// End of Monitoring
        EOM: ICM_RCFG__EOM,
        reserved4: u1 = 0,
        /// Region Hash Interrupt Enable
        RHIEN: ICM_RCFG__RHIEN,
        /// Region Digest Mismatch Interrupt Enable
        DMIEN: ICM_RCFG__DMIEN,
        /// Region Bus Error Interrupt Enable
        BEIEN: ICM_RCFG__BEIEN,
        /// Region Wrap Condition Detected Interrupt Enable
        WCIEN: ICM_RCFG__WCIEN,
        /// Region End bit Condition detected Interrupt Enable
        ECIEN: ICM_RCFG__ECIEN,
        /// Region Status Updated Interrupt Enable
        SUIEN: ICM_RCFG__SUIEN,
        /// SHA Processing Delay
        PROCDLY: ICM_RCFG__PROCDLY,
        reserved12: u1 = 0,
        /// SHA Algorithm
        ALGO: u3,
        reserved24: u9 = 0,
        /// Memory Region AHB Protection
        MRPROT: u6,
        padding: u2 = 0,
    }),
    /// Region Control
    /// offset: 0x08
    RCTRL: mmio.Mmio(packed struct(u32) {
        /// Transfer Size
        TRSIZE: u16,
        padding: u16 = 0,
    }),
    /// Region Next Address
    /// offset: 0x0c
    RNEXT: u32,
};
