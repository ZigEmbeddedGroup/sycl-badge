const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const CMCC = extern struct {
    pub const CMCC_CFG__CSIZESW = enum(u3) {
        /// The Cache Size is configured to 1KB
        CONF_CSIZE_1KB = 0x0,
        /// The Cache Size is configured to 2KB
        CONF_CSIZE_2KB = 0x1,
        /// The Cache Size is configured to 4KB
        CONF_CSIZE_4KB = 0x2,
        /// The Cache Size is configured to 8KB
        CONF_CSIZE_8KB = 0x3,
        /// The Cache Size is configured to 16KB
        CONF_CSIZE_16KB = 0x4,
        /// The Cache Size is configured to 32KB
        CONF_CSIZE_32KB = 0x5,
        /// The Cache Size is configured to 64KB
        CONF_CSIZE_64KB = 0x6,
        _,
    };

    pub const CMCC_MAINT1__WAY = enum(u4) {
        /// Way 0 is selection for index invalidation
        WAY0 = 0x0,
        /// Way 1 is selection for index invalidation
        WAY1 = 0x1,
        /// Way 2 is selection for index invalidation
        WAY2 = 0x2,
        /// Way 3 is selection for index invalidation
        WAY3 = 0x3,
        _,
    };

    pub const CMCC_MCFG__MODE = enum(u2) {
        /// Cycle counter
        CYCLE_COUNT = 0x0,
        /// Instruction hit counter
        IHIT_COUNT = 0x1,
        /// Data hit counter
        DHIT_COUNT = 0x2,
        _,
    };

    pub const CMCC_TYPE__CLSIZE = enum(u3) {
        /// Cache Line Size is 4 bytes
        CLSIZE_4B = 0x0,
        /// Cache Line Size is 8 bytes
        CLSIZE_8B = 0x1,
        /// Cache Line Size is 16 bytes
        CLSIZE_16B = 0x2,
        /// Cache Line Size is 32 bytes
        CLSIZE_32B = 0x3,
        /// Cache Line Size is 64 bytes
        CLSIZE_64B = 0x4,
        /// Cache Line Size is 128 bytes
        CLSIZE_128B = 0x5,
        _,
    };

    pub const CMCC_TYPE__CSIZE = enum(u3) {
        /// Cache Size is 1 KB
        CSIZE_1KB = 0x0,
        /// Cache Size is 2 KB
        CSIZE_2KB = 0x1,
        /// Cache Size is 4 KB
        CSIZE_4KB = 0x2,
        /// Cache Size is 8 KB
        CSIZE_8KB = 0x3,
        /// Cache Size is 16 KB
        CSIZE_16KB = 0x4,
        /// Cache Size is 32 KB
        CSIZE_32KB = 0x5,
        /// Cache Size is 64 KB
        CSIZE_64KB = 0x6,
        _,
    };

    pub const CMCC_TYPE__WAYNUM = enum(u2) {
        /// Direct Mapped Cache
        DMAPPED = 0x0,
        /// 2-WAY set associative
        ARCH2WAY = 0x1,
        /// 4-WAY set associative
        ARCH4WAY = 0x2,
        _,
    };

    /// Cache Type Register
    /// offset: 0x00
    TYPE: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// dynamic Clock Gating supported
        GCLK: u1,
        reserved4: u2 = 0,
        /// Round Robin Policy supported
        RRP: u1,
        /// Number of Way
        WAYNUM: CMCC_TYPE__WAYNUM,
        /// Lock Down supported
        LCKDOWN: u1,
        /// Cache Size
        CSIZE: CMCC_TYPE__CSIZE,
        /// Cache Line Size
        CLSIZE: CMCC_TYPE__CLSIZE,
        padding: u18 = 0,
    }),
    /// Cache Configuration Register
    /// offset: 0x04
    CFG: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Instruction Cache Disable
        ICDIS: u1,
        /// Data Cache Disable
        DCDIS: u1,
        reserved4: u1 = 0,
        /// Cache size configured by software
        CSIZESW: CMCC_CFG__CSIZESW,
        padding: u25 = 0,
    }),
    /// Cache Control Register
    /// offset: 0x08
    CTRL: mmio.Mmio(packed struct(u32) {
        /// Cache Controller Enable
        CEN: u1,
        padding: u31 = 0,
    }),
    /// Cache Status Register
    /// offset: 0x0c
    SR: mmio.Mmio(packed struct(u32) {
        /// Cache Controller Status
        CSTS: u1,
        padding: u31 = 0,
    }),
    /// Cache Lock per Way Register
    /// offset: 0x10
    LCKWAY: mmio.Mmio(packed struct(u32) {
        /// Lockdown way Register
        LCKWAY: u4,
        padding: u28 = 0,
    }),
    /// offset: 0x14
    reserved20: [12]u8,
    /// Cache Maintenance Register 0
    /// offset: 0x20
    MAINT0: mmio.Mmio(packed struct(u32) {
        /// Cache Controller invalidate All
        INVALL: u1,
        padding: u31 = 0,
    }),
    /// Cache Maintenance Register 1
    /// offset: 0x24
    MAINT1: mmio.Mmio(packed struct(u32) {
        reserved4: u4 = 0,
        /// Invalidate Index
        INDEX: u8,
        reserved28: u16 = 0,
        /// Invalidate Way
        WAY: CMCC_MAINT1__WAY,
    }),
    /// Cache Monitor Configuration Register
    /// offset: 0x28
    MCFG: mmio.Mmio(packed struct(u32) {
        /// Cache Controller Monitor Counter Mode
        MODE: CMCC_MCFG__MODE,
        padding: u30 = 0,
    }),
    /// Cache Monitor Enable Register
    /// offset: 0x2c
    MEN: mmio.Mmio(packed struct(u32) {
        /// Cache Controller Monitor Enable
        MENABLE: u1,
        padding: u31 = 0,
    }),
    /// Cache Monitor Control Register
    /// offset: 0x30
    MCTRL: mmio.Mmio(packed struct(u32) {
        /// Cache Controller Software Reset
        SWRST: u1,
        padding: u31 = 0,
    }),
    /// Cache Monitor Status Register
    /// offset: 0x34
    MSR: mmio.Mmio(packed struct(u32) {
        /// Monitor Event Counter
        EVENT_CNT: u32,
    }),
};
