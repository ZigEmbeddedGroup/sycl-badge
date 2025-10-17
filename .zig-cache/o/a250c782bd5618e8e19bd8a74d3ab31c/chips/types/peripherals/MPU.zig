const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const MPU = extern struct {
    /// MPU Type Register
    /// offset: 0x00
    TYPE: mmio.Mmio(packed struct(u32) {
        /// Separate instruction and Data Memory MapsRegions
        SEPARATE: u1,
        reserved8: u7 = 0,
        /// Number of Data Regions
        DREGION: u8,
        /// Number of Instruction Regions
        IREGION: u8,
        padding: u8 = 0,
    }),
    /// MPU Control Register
    /// offset: 0x04
    CTRL: mmio.Mmio(packed struct(u32) {
        /// MPU Enable
        ENABLE: u1,
        /// Enable Hard Fault and NMI handlers
        HFNMIENA: u1,
        /// Enables privileged software access to default memory map
        PRIVDEFENA: u1,
        padding: u29 = 0,
    }),
    /// MPU Region Number Register
    /// offset: 0x08
    RNR: mmio.Mmio(packed struct(u32) {
        /// Region referenced by RBAR and RASR
        REGION: u8,
        padding: u24 = 0,
    }),
    /// MPU Region Base Address Register
    /// offset: 0x0c
    RBAR: mmio.Mmio(packed struct(u32) {
        /// Region number
        REGION: u4,
        /// Region number valid
        VALID: u1,
        /// Region base address
        ADDR: u27,
    }),
    /// MPU Region Attribute and Size Register
    /// offset: 0x10
    RASR: mmio.Mmio(packed struct(u32) {
        /// Region Enable
        ENABLE: u1,
        /// Region Size
        SIZE: u1,
        reserved8: u6 = 0,
        /// Sub-region disable
        SRD: u8,
        /// Bufferable bit
        B: u1,
        /// Cacheable bit
        C: u1,
        /// Shareable bit
        S: u1,
        /// TEX bit
        TEX: u3,
        reserved24: u2 = 0,
        /// Access Permission
        AP: u3,
        reserved28: u1 = 0,
        /// Execute Never Attribute
        XN: u1,
        padding: u3 = 0,
    }),
    /// MPU Alias 1 Region Base Address Register
    /// offset: 0x14
    RBAR_A1: mmio.Mmio(packed struct(u32) {
        /// Region number
        REGION: u4,
        /// Region number valid
        VALID: u1,
        /// Region base address
        ADDR: u27,
    }),
    /// MPU Alias 1 Region Attribute and Size Register
    /// offset: 0x18
    RASR_A1: mmio.Mmio(packed struct(u32) {
        /// Region Enable
        ENABLE: u1,
        /// Region Size
        SIZE: u1,
        reserved8: u6 = 0,
        /// Sub-region disable
        SRD: u8,
        /// Bufferable bit
        B: u1,
        /// Cacheable bit
        C: u1,
        /// Shareable bit
        S: u1,
        /// TEX bit
        TEX: u3,
        reserved24: u2 = 0,
        /// Access Permission
        AP: u3,
        reserved28: u1 = 0,
        /// Execute Never Attribute
        XN: u1,
        padding: u3 = 0,
    }),
    /// MPU Alias 2 Region Base Address Register
    /// offset: 0x1c
    RBAR_A2: mmio.Mmio(packed struct(u32) {
        /// Region number
        REGION: u4,
        /// Region number valid
        VALID: u1,
        /// Region base address
        ADDR: u27,
    }),
    /// MPU Alias 2 Region Attribute and Size Register
    /// offset: 0x20
    RASR_A2: mmio.Mmio(packed struct(u32) {
        /// Region Enable
        ENABLE: u1,
        /// Region Size
        SIZE: u1,
        reserved8: u6 = 0,
        /// Sub-region disable
        SRD: u8,
        /// Bufferable bit
        B: u1,
        /// Cacheable bit
        C: u1,
        /// Shareable bit
        S: u1,
        /// TEX bit
        TEX: u3,
        reserved24: u2 = 0,
        /// Access Permission
        AP: u3,
        reserved28: u1 = 0,
        /// Execute Never Attribute
        XN: u1,
        padding: u3 = 0,
    }),
    /// MPU Alias 3 Region Base Address Register
    /// offset: 0x24
    RBAR_A3: mmio.Mmio(packed struct(u32) {
        /// Region number
        REGION: u4,
        /// Region number valid
        VALID: u1,
        /// Region base address
        ADDR: u27,
    }),
    /// MPU Alias 3 Region Attribute and Size Register
    /// offset: 0x28
    RASR_A3: mmio.Mmio(packed struct(u32) {
        /// Region Enable
        ENABLE: u1,
        /// Region Size
        SIZE: u1,
        reserved8: u6 = 0,
        /// Sub-region disable
        SRD: u8,
        /// Bufferable bit
        B: u1,
        /// Cacheable bit
        C: u1,
        /// Shareable bit
        S: u1,
        /// TEX bit
        TEX: u3,
        reserved24: u2 = 0,
        /// Access Permission
        AP: u3,
        reserved28: u1 = 0,
        /// Execute Never Attribute
        XN: u1,
        padding: u3 = 0,
    }),
};
