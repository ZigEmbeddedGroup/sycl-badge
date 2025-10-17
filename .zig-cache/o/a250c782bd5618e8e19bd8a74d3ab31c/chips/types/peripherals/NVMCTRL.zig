const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const NVMCTRL = extern struct {
    pub const NVMCTRL_CTRLA__PRM = enum(u2) {
        /// NVM block enters low-power mode when entering standby mode. NVM block enters low-power mode when SPRM command is issued. NVM block exits low-power mode upon first access.
        SEMIAUTO = 0x0,
        /// NVM block enters low-power mode when entering standby mode. NVM block enters low-power mode when SPRM command is issued. NVM block exits low-power mode when system is not in standby mode.
        FULLAUTO = 0x1,
        /// NVM block does not enter low-power mode when entering standby mode. NVM block enters low-power mode when SPRM command is issued. NVM block exits low-power mode upon first access.
        MANUAL = 0x3,
        _,
    };

    pub const NVMCTRL_CTRLA__WMODE = enum(u2) {
        /// Manual Write
        MAN = 0x0,
        /// Automatic Double Word Write
        ADW = 0x1,
        /// Automatic Quad Word
        AQW = 0x2,
        /// Automatic Page Write
        AP = 0x3,
    };

    pub const NVMCTRL_CTRLB__CMD = enum(u7) {
        /// Erase Page - Only supported in the USER and AUX pages.
        EP = 0x0,
        /// Erase Block - Erases the block addressed by the ADDR register, not supported in the user page
        EB = 0x1,
        /// Write Page - Writes the contents of the page buffer to the page addressed by the ADDR register, not supported in the user page
        WP = 0x3,
        /// Write Quad Word - Writes a 128-bit word at the location addressed by the ADDR register.
        WQW = 0x4,
        /// Software Reset - Power-Cycle the NVM memory and replay the device automatic calibration procedure and resets the module configuration registers
        SWRST = 0x10,
        /// Lock Region - Locks the region containing the address location in the ADDR register.
        LR = 0x11,
        /// Unlock Region - Unlocks the region containing the address location in the ADDR register.
        UR = 0x12,
        /// Sets the power reduction mode.
        SPRM = 0x13,
        /// Clears the power reduction mode.
        CPRM = 0x14,
        /// Page Buffer Clear - Clears the page buffer.
        PBC = 0x15,
        /// Set Security Bit
        SSB = 0x16,
        /// Bank swap and system reset, if SMEE is used also reallocate SMEE data into the opposite BANK
        BKSWRST = 0x17,
        /// Chip Erase Lock - DSU.CE command is not available
        CELCK = 0x18,
        /// Chip Erase Unlock - DSU.CE command is available
        CEULCK = 0x19,
        /// Sets STATUS.BPDIS, Boot loader protection is discarded until CBPDIS is issued or next start-up sequence
        SBPDIS = 0x1a,
        /// Clears STATUS.BPDIS, Boot loader protection is not discarded
        CBPDIS = 0x1b,
        /// Activate SmartEEPROM Sector 0, deactivate Sector 1
        ASEES0 = 0x30,
        /// Activate SmartEEPROM Sector 1, deactivate Sector 0
        ASEES1 = 0x31,
        /// Starts SmartEEPROM sector reallocation algorithm
        SEERALOC = 0x32,
        /// Flush SMEE data when in buffered mode
        SEEFLUSH = 0x33,
        /// Lock access to SmartEEPROM data from any mean
        LSEE = 0x34,
        /// Unlock access to SmartEEPROM data
        USEE = 0x35,
        /// Lock access to the SmartEEPROM Register Address Space (above 64KB)
        LSEER = 0x36,
        /// Unlock access to the SmartEEPROM Register Address Space (above 64KB)
        USEER = 0x37,
        _,
    };

    pub const NVMCTRL_CTRLB__CMDEX = enum(u8) {
        /// Execution Key
        KEY = 0xa5,
        _,
    };

    pub const NVMCTRL_ECCERR__TYPEH = enum(u2) {
        /// No Error Detected Since Last Read
        None = 0x0,
        /// At Least One Single Error Detected Since last Read
        Single = 0x1,
        /// At Least One Dual Error Detected Since Last Read
        Dual = 0x2,
        _,
    };

    pub const NVMCTRL_ECCERR__TYPEL = enum(u2) {
        /// No Error Detected Since Last Read
        None = 0x0,
        /// At Least One Single Error Detected Since last Read
        Single = 0x1,
        /// At Least One Dual Error Detected Since Last Read
        Dual = 0x2,
        _,
    };

    pub const NVMCTRL_PARAM__PSZ = enum(u3) {
        /// 8 bytes
        @"8" = 0x0,
        /// 16 bytes
        @"16" = 0x1,
        /// 32 bytes
        @"32" = 0x2,
        /// 64 bytes
        @"64" = 0x3,
        /// 128 bytes
        @"128" = 0x4,
        /// 256 bytes
        @"256" = 0x5,
        /// 512 bytes
        @"512" = 0x6,
        /// 1024 bytes
        @"1024" = 0x7,
    };

    pub const NVMCTRL_PARAM__SEE = enum(u3) {
        /// 0 bytes
        @"0" = 0x0,
        /// 16384 bytes
        @"1" = 0x1,
        /// 32768 bytes
        @"2" = 0x2,
        /// 49152 bytes
        @"3" = 0x3,
        /// 65536 bytes
        @"4" = 0x4,
        /// 81920 bytes
        @"5" = 0x5,
        /// 98304 bytes
        @"6" = 0x6,
        /// 114688 bytes
        @"7" = 0x7,
        /// 131072 bytes
        @"8" = 0x8,
        /// 147456 bytes
        @"9" = 0x9,
        /// 163840 bytes
        A = 0xa,
    };

    pub const NVMCTRL_SEECFG__WMODE = enum(u1) {
        /// A NVM write command is issued after each write in the pagebuffer
        UNBUFFERED = 0x0,
        /// A NVM write command is issued when a write to a new page is requested
        BUFFERED = 0x1,
    };

    pub const NVMCTRL_STATUS__BOOTPROT = enum(u4) {
        /// 120 kbytes
        @"120" = 0x0,
        /// 112 kbytes
        @"112" = 0x1,
        /// 104 kbytes
        @"104" = 0x2,
        /// 96 kbytes
        @"96" = 0x3,
        /// 88 kbytes
        @"88" = 0x4,
        /// 80 kbytes
        @"80" = 0x5,
        /// 72 kbytes
        @"72" = 0x6,
        /// 64 kbytes
        @"64" = 0x7,
        /// 56 kbytes
        @"56" = 0x8,
        /// 48 kbytes
        @"48" = 0x9,
        /// 40 kbytes
        @"40" = 0xa,
        /// 32 kbytes
        @"32" = 0xb,
        /// 24 kbytes
        @"24" = 0xc,
        /// 16 kbytes
        @"16" = 0xd,
        /// 8 kbytes
        @"8" = 0xe,
        /// 0 kbytes
        @"0" = 0xf,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u16) {
        reserved2: u2 = 0,
        /// Auto Wait State Enable
        AUTOWS: u1,
        /// Suspend Enable
        SUSPEN: u1,
        /// Write Mode
        WMODE: NVMCTRL_CTRLA__WMODE,
        /// Power Reduction Mode during Sleep
        PRM: NVMCTRL_CTRLA__PRM,
        /// NVM Read Wait States
        RWS: u4,
        /// Force AHB0 access to NONSEQ, burst transfers are continuously rearbitrated
        AHBNS0: u1,
        /// Force AHB1 access to NONSEQ, burst transfers are continuously rearbitrated
        AHBNS1: u1,
        /// AHB0 Cache Disable
        CACHEDIS0: u1,
        /// AHB1 Cache Disable
        CACHEDIS1: u1,
    }),
    /// offset: 0x02
    reserved2: [2]u8,
    /// Control B
    /// offset: 0x04
    CTRLB: mmio.Mmio(packed struct(u16) {
        /// Command
        CMD: NVMCTRL_CTRLB__CMD,
        reserved8: u1 = 0,
        /// Command Execution
        CMDEX: NVMCTRL_CTRLB__CMDEX,
    }),
    /// offset: 0x06
    reserved6: [2]u8,
    /// NVM Parameter
    /// offset: 0x08
    PARAM: mmio.Mmio(packed struct(u32) {
        /// NVM Pages
        NVMP: u16,
        /// Page Size
        PSZ: NVMCTRL_PARAM__PSZ,
        reserved31: u12 = 0,
        /// SmartEEPROM Supported
        SEE: u1,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x0c
    INTENCLR: mmio.Mmio(packed struct(u16) {
        /// Command Done Interrupt Clear
        DONE: u1,
        /// Address Error
        ADDRE: u1,
        /// Programming Error Interrupt Clear
        PROGE: u1,
        /// Lock Error Interrupt Clear
        LOCKE: u1,
        /// ECC Single Error Interrupt Clear
        ECCSE: u1,
        /// ECC Dual Error Interrupt Clear
        ECCDE: u1,
        /// NVM Error Interrupt Clear
        NVME: u1,
        /// Suspended Write Or Erase Interrupt Clear
        SUSP: u1,
        /// Active SEES Full Interrupt Clear
        SEESFULL: u1,
        /// Active SEES Overflow Interrupt Clear
        SEESOVF: u1,
        /// SEE Write Completed Interrupt Clear
        SEEWRC: u1,
        padding: u5 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x0e
    INTENSET: mmio.Mmio(packed struct(u16) {
        /// Command Done Interrupt Enable
        DONE: u1,
        /// Address Error Interrupt Enable
        ADDRE: u1,
        /// Programming Error Interrupt Enable
        PROGE: u1,
        /// Lock Error Interrupt Enable
        LOCKE: u1,
        /// ECC Single Error Interrupt Enable
        ECCSE: u1,
        /// ECC Dual Error Interrupt Enable
        ECCDE: u1,
        /// NVM Error Interrupt Enable
        NVME: u1,
        /// Suspended Write Or Erase Interrupt Enable
        SUSP: u1,
        /// Active SEES Full Interrupt Enable
        SEESFULL: u1,
        /// Active SEES Overflow Interrupt Enable
        SEESOVF: u1,
        /// SEE Write Completed Interrupt Enable
        SEEWRC: u1,
        padding: u5 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x10
    INTFLAG: mmio.Mmio(packed struct(u16) {
        /// Command Done
        DONE: u1,
        /// Address Error
        ADDRE: u1,
        /// Programming Error
        PROGE: u1,
        /// Lock Error
        LOCKE: u1,
        /// ECC Single Error
        ECCSE: u1,
        /// ECC Dual Error
        ECCDE: u1,
        /// NVM Error
        NVME: u1,
        /// Suspended Write Or Erase Operation
        SUSP: u1,
        /// Active SEES Full
        SEESFULL: u1,
        /// Active SEES Overflow
        SEESOVF: u1,
        /// SEE Write Completed
        SEEWRC: u1,
        padding: u5 = 0,
    }),
    /// Status
    /// offset: 0x12
    STATUS: mmio.Mmio(packed struct(u16) {
        /// Ready to accept a command
        READY: u1,
        /// Power Reduction Mode
        PRM: u1,
        /// NVM Page Buffer Active Loading
        LOAD: u1,
        /// NVM Write Or Erase Operation Is Suspended
        SUSP: u1,
        /// BANKA First
        AFIRST: u1,
        /// Boot Loader Protection Disable
        BPDIS: u1,
        reserved8: u2 = 0,
        /// Boot Loader Protection Size
        BOOTPROT: NVMCTRL_STATUS__BOOTPROT,
        padding: u4 = 0,
    }),
    /// Address
    /// offset: 0x14
    ADDR: mmio.Mmio(packed struct(u32) {
        /// NVM Address
        ADDR: u24,
        padding: u8 = 0,
    }),
    /// Lock Section
    /// offset: 0x18
    RUNLOCK: mmio.Mmio(packed struct(u32) {
        /// Region Un-Lock Bits
        RUNLOCK: u32,
    }),
    /// Page Buffer Load Data x
    /// offset: 0x1c
    PBLDATA: [2]mmio.Mmio(packed struct(u32) {
        /// Page Buffer Data
        DATA: u32,
    }),
    /// ECC Error Status Register
    /// offset: 0x24
    ECCERR: mmio.Mmio(packed struct(u32) {
        /// Error Address
        ADDR: u24,
        reserved28: u4 = 0,
        /// Low Double-Word Error Type
        TYPEL: NVMCTRL_ECCERR__TYPEL,
        /// High Double-Word Error Type
        TYPEH: NVMCTRL_ECCERR__TYPEH,
    }),
    /// Debug Control
    /// offset: 0x28
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debugger ECC Read Disable
        ECCDIS: u1,
        /// Debugger ECC Error Tracking Mode
        ECCELOG: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x29
    reserved41: [1]u8,
    /// SmartEEPROM Configuration Register
    /// offset: 0x2a
    SEECFG: mmio.Mmio(packed struct(u8) {
        /// Write Mode
        WMODE: NVMCTRL_SEECFG__WMODE,
        /// Automatic Page Reallocation Disable
        APRDIS: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x2b
    reserved43: [1]u8,
    /// SmartEEPROM Status Register
    /// offset: 0x2c
    SEESTAT: mmio.Mmio(packed struct(u32) {
        /// Active SmartEEPROM Sector
        ASEES: u1,
        /// Page Buffer Loaded
        LOAD: u1,
        /// Busy
        BUSY: u1,
        /// SmartEEPROM Write Access Is Locked
        LOCK: u1,
        /// SmartEEPROM Write Access To Register Address Space Is Locked
        RLOCK: u1,
        reserved8: u3 = 0,
        /// Blocks Number In a Sector
        SBLK: u4,
        reserved16: u4 = 0,
        /// SmartEEPROM Page Size
        PSZ: u3,
        padding: u13 = 0,
    }),
};
