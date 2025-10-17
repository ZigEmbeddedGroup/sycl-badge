const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const DMAC_BTCTRL__BEATSIZE = enum(u2) {
    /// 8-bit bus transfer
    BYTE = 0x0,
    /// 16-bit bus transfer
    HWORD = 0x1,
    /// 32-bit bus transfer
    WORD = 0x2,
    _,
};

pub const DMAC_BTCTRL__BLOCKACT = enum(u2) {
    /// Channel will be disabled if it is the last block transfer in the transaction
    NOACT = 0x0,
    /// Channel will be disabled if it is the last block transfer in the transaction and block interrupt
    INT = 0x1,
    /// Channel suspend operation is completed
    SUSPEND = 0x2,
    /// Both channel suspend operation and block interrupt
    BOTH = 0x3,
};

pub const DMAC_BTCTRL__EVOSEL = enum(u2) {
    /// Event generation disabled
    DISABLE = 0x0,
    /// Block event strobe
    BLOCK = 0x1,
    /// Burst event strobe
    BURST = 0x3,
    _,
};

pub const DMAC_BTCTRL__STEPSEL = enum(u1) {
    /// Step size settings apply to the destination address
    DST = 0x0,
    /// Step size settings apply to the source address
    SRC = 0x1,
};

pub const DMAC_BTCTRL__STEPSIZE = enum(u3) {
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 1
    X1 = 0x0,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 2
    X2 = 0x1,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 4
    X4 = 0x2,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 8
    X8 = 0x3,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 16
    X16 = 0x4,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 32
    X32 = 0x5,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 64
    X64 = 0x6,
    /// Next ADDR = ADDR + (1<<BEATSIZE) * 128
    X128 = 0x7,
};

pub const DMAC_CHCTRLA__BURSTLEN = enum(u4) {
    /// Single-beat burst length
    SINGLE = 0x0,
    /// 2-beats burst length
    @"2BEAT" = 0x1,
    /// 3-beats burst length
    @"3BEAT" = 0x2,
    /// 4-beats burst length
    @"4BEAT" = 0x3,
    /// 5-beats burst length
    @"5BEAT" = 0x4,
    /// 6-beats burst length
    @"6BEAT" = 0x5,
    /// 7-beats burst length
    @"7BEAT" = 0x6,
    /// 8-beats burst length
    @"8BEAT" = 0x7,
    /// 9-beats burst length
    @"9BEAT" = 0x8,
    /// 10-beats burst length
    @"10BEAT" = 0x9,
    /// 11-beats burst length
    @"11BEAT" = 0xa,
    /// 12-beats burst length
    @"12BEAT" = 0xb,
    /// 13-beats burst length
    @"13BEAT" = 0xc,
    /// 14-beats burst length
    @"14BEAT" = 0xd,
    /// 15-beats burst length
    @"15BEAT" = 0xe,
    /// 16-beats burst length
    @"16BEAT" = 0xf,
};

pub const DMAC_CHCTRLA__THRESHOLD = enum(u2) {
    /// Destination write starts after each beat source address read
    @"1BEAT" = 0x0,
    /// Destination write starts after 2-beats source address read
    @"2BEATS" = 0x1,
    /// Destination write starts after 4-beats source address read
    @"4BEATS" = 0x2,
    /// Destination write starts after 8-beats source address read
    @"8BEATS" = 0x3,
};

pub const DMAC_CHCTRLA__TRIGACT = enum(u2) {
    /// One trigger required for each block transfer
    BLOCK = 0x0,
    /// One trigger required for each burst transfer
    BURST = 0x2,
    /// One trigger required for each transaction
    TRANSACTION = 0x3,
    _,
};

pub const DMAC_CHCTRLA__TRIGSRC = enum(u7) {
    /// Only software/event triggers
    DISABLE = 0x0,
    _,
};

pub const DMAC_CHCTRLB__CMD = enum(u2) {
    /// No action
    NOACT = 0x0,
    /// Channel suspend operation
    SUSPEND = 0x1,
    /// Channel resume operation
    RESUME = 0x2,
    _,
};

pub const DMAC_CHEVCTRL__EVACT = enum(u3) {
    /// No action
    NOACT = 0x0,
    /// Transfer and periodic transfer trigger
    TRIG = 0x1,
    /// Conditional transfer trigger
    CTRIG = 0x2,
    /// Conditional block transfer
    CBLOCK = 0x3,
    /// Channel suspend operation
    SUSPEND = 0x4,
    /// Channel resume operation
    RESUME = 0x5,
    /// Skip next block suspend action
    SSKIP = 0x6,
    /// Increase priority
    INCPRI = 0x7,
};

pub const DMAC_CHEVCTRL__EVOMODE = enum(u2) {
    /// Block event output selection. Refer to BTCTRL.EVOSEL for available selections.
    DEFAULT = 0x0,
    /// Ongoing trigger action
    TRIGACT = 0x1,
    _,
};

pub const DMAC_CHPRILVL__PRILVL = enum(u2) {
    /// Channel Priority Level 0 (Lowest Level)
    LVL0 = 0x0,
    /// Channel Priority Level 1
    LVL1 = 0x1,
    /// Channel Priority Level 2
    LVL2 = 0x2,
    /// Channel Priority Level 3 (Highest Level)
    LVL3 = 0x3,
};

pub const DMAC_CRCCTRL__CRCBEATSIZE = enum(u2) {
    /// 8-bit bus transfer
    BYTE = 0x0,
    /// 16-bit bus transfer
    HWORD = 0x1,
    /// 32-bit bus transfer
    WORD = 0x2,
    _,
};

pub const DMAC_CRCCTRL__CRCMODE = enum(u2) {
    /// Default operating mode
    DEFAULT = 0x0,
    /// Memory CRC monitor operating mode
    CRCMON = 0x2,
    /// Memory CRC generation operating mode
    CRCGEN = 0x3,
    _,
};

pub const DMAC_CRCCTRL__CRCPOLY = enum(u1) {
    /// CRC-16 (CRC-CCITT)
    CRC16 = 0x0,
    /// CRC32 (IEEE 802.3)
    CRC32 = 0x1,
};

pub const DMAC_CRCCTRL__CRCSRC = enum(u1) {
    /// CRC Disabled
    DISABLE = 0x0,
    /// I/O interface
    IO = 0x1,
};

pub const DMAC_PRICTRL0__QOS0 = enum(u2) {
    /// Regular delivery
    REGULAR = 0x0,
    /// Bandwidth shortage
    SHORTAGE = 0x1,
    /// Latency sensitive
    SENSITIVE = 0x2,
    /// Latency critical
    CRITICAL = 0x3,
};

pub const DMAC_PRICTRL0__QOS1 = enum(u2) {
    /// Regular delivery
    REGULAR = 0x0,
    /// Bandwidth shortage
    SHORTAGE = 0x1,
    /// Latency sensitive
    SENSITIVE = 0x2,
    /// Latency critical
    CRITICAL = 0x3,
};

pub const DMAC_PRICTRL0__QOS2 = enum(u2) {
    /// Regular delivery
    REGULAR = 0x0,
    /// Bandwidth shortage
    SHORTAGE = 0x1,
    /// Latency sensitive
    SENSITIVE = 0x2,
    /// Latency critical
    CRITICAL = 0x3,
};

pub const DMAC_PRICTRL0__QOS3 = enum(u2) {
    /// Regular delivery
    REGULAR = 0x0,
    /// Bandwidth shortage
    SHORTAGE = 0x1,
    /// Latency sensitive
    SENSITIVE = 0x2,
    /// Latency critical
    CRITICAL = 0x3,
};

pub const CHANNEL = extern struct {
    /// Channel n Control A
    /// offset: 0x00
    CHCTRLA: mmio.Mmio(packed struct(u32) {
        /// Channel Software Reset
        SWRST: u1,
        /// Channel Enable
        ENABLE: u1,
        reserved6: u4 = 0,
        /// Channel Run in Standby
        RUNSTDBY: u1,
        reserved8: u1 = 0,
        /// Trigger Source
        TRIGSRC: DMAC_CHCTRLA__TRIGSRC,
        reserved20: u5 = 0,
        /// Trigger Action
        TRIGACT: DMAC_CHCTRLA__TRIGACT,
        reserved24: u2 = 0,
        /// Burst Length
        BURSTLEN: DMAC_CHCTRLA__BURSTLEN,
        /// FIFO Threshold
        THRESHOLD: DMAC_CHCTRLA__THRESHOLD,
        padding: u2 = 0,
    }),
    /// Channel n Control B
    /// offset: 0x04
    CHCTRLB: mmio.Mmio(packed struct(u8) {
        /// Software Command
        CMD: DMAC_CHCTRLB__CMD,
        padding: u6 = 0,
    }),
    /// Channel n Priority Level
    /// offset: 0x05
    CHPRILVL: mmio.Mmio(packed struct(u8) {
        /// Channel Priority Level
        PRILVL: DMAC_CHPRILVL__PRILVL,
        padding: u6 = 0,
    }),
    /// Channel n Event Control
    /// offset: 0x06
    CHEVCTRL: mmio.Mmio(packed struct(u8) {
        /// Channel Event Input Action
        EVACT: DMAC_CHEVCTRL__EVACT,
        reserved4: u1 = 0,
        /// Channel Event Output Mode
        EVOMODE: DMAC_CHEVCTRL__EVOMODE,
        /// Channel Event Input Enable
        EVIE: u1,
        /// Channel Event Output Enable
        EVOE: u1,
    }),
    /// offset: 0x07
    reserved7: [5]u8,
    /// Channel n Interrupt Enable Clear
    /// offset: 0x0c
    CHINTENCLR: mmio.Mmio(packed struct(u8) {
        /// Channel Transfer Error Interrupt Enable
        TERR: u1,
        /// Channel Transfer Complete Interrupt Enable
        TCMPL: u1,
        /// Channel Suspend Interrupt Enable
        SUSP: u1,
        padding: u5 = 0,
    }),
    /// Channel n Interrupt Enable Set
    /// offset: 0x0d
    CHINTENSET: mmio.Mmio(packed struct(u8) {
        /// Channel Transfer Error Interrupt Enable
        TERR: u1,
        /// Channel Transfer Complete Interrupt Enable
        TCMPL: u1,
        /// Channel Suspend Interrupt Enable
        SUSP: u1,
        padding: u5 = 0,
    }),
    /// Channel n Interrupt Flag Status and Clear
    /// offset: 0x0e
    CHINTFLAG: mmio.Mmio(packed struct(u8) {
        /// Channel Transfer Error
        TERR: u1,
        /// Channel Transfer Complete
        TCMPL: u1,
        /// Channel Suspend
        SUSP: u1,
        padding: u5 = 0,
    }),
    /// Channel n Status
    /// offset: 0x0f
    CHSTATUS: mmio.Mmio(packed struct(u8) {
        /// Channel Pending
        PEND: u1,
        /// Channel Busy
        BUSY: u1,
        /// Channel Fetch Error
        FERR: u1,
        /// Channel CRC Error
        CRCERR: u1,
        padding: u4 = 0,
    }),
};

/// Direct Memory Access Controller
pub const DMAC = extern struct {
    /// Control
    /// offset: 0x00
    CTRL: mmio.Mmio(packed struct(u16) {
        /// Software Reset
        SWRST: u1,
        /// DMA Enable
        DMAENABLE: u1,
        reserved8: u6 = 0,
        /// Priority Level 0 Enable
        LVLEN0: u1,
        /// Priority Level 1 Enable
        LVLEN1: u1,
        /// Priority Level 2 Enable
        LVLEN2: u1,
        /// Priority Level 3 Enable
        LVLEN3: u1,
        padding: u4 = 0,
    }),
    /// CRC Control
    /// offset: 0x02
    CRCCTRL: mmio.Mmio(packed struct(u16) {
        /// CRC Beat Size
        CRCBEATSIZE: DMAC_CRCCTRL__CRCBEATSIZE,
        /// CRC Polynomial Type
        CRCPOLY: u2,
        reserved8: u4 = 0,
        /// CRC Input Source
        CRCSRC: u6,
        /// CRC Operating Mode
        CRCMODE: DMAC_CRCCTRL__CRCMODE,
    }),
    /// CRC Data Input
    /// offset: 0x04
    CRCDATAIN: mmio.Mmio(packed struct(u32) {
        /// CRC Data Input
        CRCDATAIN: u32,
    }),
    /// CRC Checksum
    /// offset: 0x08
    CRCCHKSUM: mmio.Mmio(packed struct(u32) {
        /// CRC Checksum
        CRCCHKSUM: u32,
    }),
    /// CRC Status
    /// offset: 0x0c
    CRCSTATUS: mmio.Mmio(packed struct(u8) {
        /// CRC Module Busy
        CRCBUSY: u1,
        /// CRC Zero
        CRCZERO: u1,
        /// CRC Error
        CRCERR: u1,
        padding: u5 = 0,
    }),
    /// Debug Control
    /// offset: 0x0d
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Run
        DBGRUN: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x0e
    reserved14: [2]u8,
    /// Software Trigger Control
    /// offset: 0x10
    SWTRIGCTRL: mmio.Mmio(packed struct(u32) {
        /// Channel 0 Software Trigger
        SWTRIG0: u1,
        /// Channel 1 Software Trigger
        SWTRIG1: u1,
        /// Channel 2 Software Trigger
        SWTRIG2: u1,
        /// Channel 3 Software Trigger
        SWTRIG3: u1,
        /// Channel 4 Software Trigger
        SWTRIG4: u1,
        /// Channel 5 Software Trigger
        SWTRIG5: u1,
        /// Channel 6 Software Trigger
        SWTRIG6: u1,
        /// Channel 7 Software Trigger
        SWTRIG7: u1,
        /// Channel 8 Software Trigger
        SWTRIG8: u1,
        /// Channel 9 Software Trigger
        SWTRIG9: u1,
        /// Channel 10 Software Trigger
        SWTRIG10: u1,
        /// Channel 11 Software Trigger
        SWTRIG11: u1,
        /// Channel 12 Software Trigger
        SWTRIG12: u1,
        /// Channel 13 Software Trigger
        SWTRIG13: u1,
        /// Channel 14 Software Trigger
        SWTRIG14: u1,
        /// Channel 15 Software Trigger
        SWTRIG15: u1,
        /// Channel 16 Software Trigger
        SWTRIG16: u1,
        /// Channel 17 Software Trigger
        SWTRIG17: u1,
        /// Channel 18 Software Trigger
        SWTRIG18: u1,
        /// Channel 19 Software Trigger
        SWTRIG19: u1,
        /// Channel 20 Software Trigger
        SWTRIG20: u1,
        /// Channel 21 Software Trigger
        SWTRIG21: u1,
        /// Channel 22 Software Trigger
        SWTRIG22: u1,
        /// Channel 23 Software Trigger
        SWTRIG23: u1,
        /// Channel 24 Software Trigger
        SWTRIG24: u1,
        /// Channel 25 Software Trigger
        SWTRIG25: u1,
        /// Channel 26 Software Trigger
        SWTRIG26: u1,
        /// Channel 27 Software Trigger
        SWTRIG27: u1,
        /// Channel 28 Software Trigger
        SWTRIG28: u1,
        /// Channel 29 Software Trigger
        SWTRIG29: u1,
        /// Channel 30 Software Trigger
        SWTRIG30: u1,
        /// Channel 31 Software Trigger
        SWTRIG31: u1,
    }),
    /// Priority Control 0
    /// offset: 0x14
    PRICTRL0: mmio.Mmio(packed struct(u32) {
        /// Level 0 Channel Priority Number
        LVLPRI0: u5,
        /// Level 0 Quality of Service
        QOS0: DMAC_PRICTRL0__QOS0,
        /// Level 0 Round-Robin Scheduling Enable
        RRLVLEN0: u1,
        /// Level 1 Channel Priority Number
        LVLPRI1: u5,
        /// Level 1 Quality of Service
        QOS1: DMAC_PRICTRL0__QOS1,
        /// Level 1 Round-Robin Scheduling Enable
        RRLVLEN1: u1,
        /// Level 2 Channel Priority Number
        LVLPRI2: u5,
        /// Level 2 Quality of Service
        QOS2: DMAC_PRICTRL0__QOS2,
        /// Level 2 Round-Robin Scheduling Enable
        RRLVLEN2: u1,
        /// Level 3 Channel Priority Number
        LVLPRI3: u5,
        /// Level 3 Quality of Service
        QOS3: DMAC_PRICTRL0__QOS3,
        /// Level 3 Round-Robin Scheduling Enable
        RRLVLEN3: u1,
    }),
    /// offset: 0x18
    reserved24: [8]u8,
    /// Interrupt Pending
    /// offset: 0x20
    INTPEND: mmio.Mmio(packed struct(u16) {
        /// Channel ID
        ID: u5,
        reserved8: u3 = 0,
        /// Transfer Error
        TERR: u1,
        /// Transfer Complete
        TCMPL: u1,
        /// Channel Suspend
        SUSP: u1,
        reserved12: u1 = 0,
        /// CRC Error
        CRCERR: u1,
        /// Fetch Error
        FERR: u1,
        /// Busy
        BUSY: u1,
        /// Pending
        PEND: u1,
    }),
    /// offset: 0x22
    reserved34: [2]u8,
    /// Interrupt Status
    /// offset: 0x24
    INTSTATUS: mmio.Mmio(packed struct(u32) {
        /// Channel 0 Pending Interrupt
        CHINT0: u1,
        /// Channel 1 Pending Interrupt
        CHINT1: u1,
        /// Channel 2 Pending Interrupt
        CHINT2: u1,
        /// Channel 3 Pending Interrupt
        CHINT3: u1,
        /// Channel 4 Pending Interrupt
        CHINT4: u1,
        /// Channel 5 Pending Interrupt
        CHINT5: u1,
        /// Channel 6 Pending Interrupt
        CHINT6: u1,
        /// Channel 7 Pending Interrupt
        CHINT7: u1,
        /// Channel 8 Pending Interrupt
        CHINT8: u1,
        /// Channel 9 Pending Interrupt
        CHINT9: u1,
        /// Channel 10 Pending Interrupt
        CHINT10: u1,
        /// Channel 11 Pending Interrupt
        CHINT11: u1,
        /// Channel 12 Pending Interrupt
        CHINT12: u1,
        /// Channel 13 Pending Interrupt
        CHINT13: u1,
        /// Channel 14 Pending Interrupt
        CHINT14: u1,
        /// Channel 15 Pending Interrupt
        CHINT15: u1,
        /// Channel 16 Pending Interrupt
        CHINT16: u1,
        /// Channel 17 Pending Interrupt
        CHINT17: u1,
        /// Channel 18 Pending Interrupt
        CHINT18: u1,
        /// Channel 19 Pending Interrupt
        CHINT19: u1,
        /// Channel 20 Pending Interrupt
        CHINT20: u1,
        /// Channel 21 Pending Interrupt
        CHINT21: u1,
        /// Channel 22 Pending Interrupt
        CHINT22: u1,
        /// Channel 23 Pending Interrupt
        CHINT23: u1,
        /// Channel 24 Pending Interrupt
        CHINT24: u1,
        /// Channel 25 Pending Interrupt
        CHINT25: u1,
        /// Channel 26 Pending Interrupt
        CHINT26: u1,
        /// Channel 27 Pending Interrupt
        CHINT27: u1,
        /// Channel 28 Pending Interrupt
        CHINT28: u1,
        /// Channel 29 Pending Interrupt
        CHINT29: u1,
        /// Channel 30 Pending Interrupt
        CHINT30: u1,
        /// Channel 31 Pending Interrupt
        CHINT31: u1,
    }),
    /// Busy Channels
    /// offset: 0x28
    BUSYCH: mmio.Mmio(packed struct(u32) {
        /// Busy Channel 0
        BUSYCH0: u1,
        /// Busy Channel 1
        BUSYCH1: u1,
        /// Busy Channel 2
        BUSYCH2: u1,
        /// Busy Channel 3
        BUSYCH3: u1,
        /// Busy Channel 4
        BUSYCH4: u1,
        /// Busy Channel 5
        BUSYCH5: u1,
        /// Busy Channel 6
        BUSYCH6: u1,
        /// Busy Channel 7
        BUSYCH7: u1,
        /// Busy Channel 8
        BUSYCH8: u1,
        /// Busy Channel 9
        BUSYCH9: u1,
        /// Busy Channel 10
        BUSYCH10: u1,
        /// Busy Channel 11
        BUSYCH11: u1,
        /// Busy Channel 12
        BUSYCH12: u1,
        /// Busy Channel 13
        BUSYCH13: u1,
        /// Busy Channel 14
        BUSYCH14: u1,
        /// Busy Channel 15
        BUSYCH15: u1,
        /// Busy Channel 16
        BUSYCH16: u1,
        /// Busy Channel 17
        BUSYCH17: u1,
        /// Busy Channel 18
        BUSYCH18: u1,
        /// Busy Channel 19
        BUSYCH19: u1,
        /// Busy Channel 20
        BUSYCH20: u1,
        /// Busy Channel 21
        BUSYCH21: u1,
        /// Busy Channel 22
        BUSYCH22: u1,
        /// Busy Channel 23
        BUSYCH23: u1,
        /// Busy Channel 24
        BUSYCH24: u1,
        /// Busy Channel 25
        BUSYCH25: u1,
        /// Busy Channel 26
        BUSYCH26: u1,
        /// Busy Channel 27
        BUSYCH27: u1,
        /// Busy Channel 28
        BUSYCH28: u1,
        /// Busy Channel 29
        BUSYCH29: u1,
        /// Busy Channel 30
        BUSYCH30: u1,
        /// Busy Channel 31
        BUSYCH31: u1,
    }),
    /// Pending Channels
    /// offset: 0x2c
    PENDCH: mmio.Mmio(packed struct(u32) {
        /// Pending Channel 0
        PENDCH0: u1,
        /// Pending Channel 1
        PENDCH1: u1,
        /// Pending Channel 2
        PENDCH2: u1,
        /// Pending Channel 3
        PENDCH3: u1,
        /// Pending Channel 4
        PENDCH4: u1,
        /// Pending Channel 5
        PENDCH5: u1,
        /// Pending Channel 6
        PENDCH6: u1,
        /// Pending Channel 7
        PENDCH7: u1,
        /// Pending Channel 8
        PENDCH8: u1,
        /// Pending Channel 9
        PENDCH9: u1,
        /// Pending Channel 10
        PENDCH10: u1,
        /// Pending Channel 11
        PENDCH11: u1,
        /// Pending Channel 12
        PENDCH12: u1,
        /// Pending Channel 13
        PENDCH13: u1,
        /// Pending Channel 14
        PENDCH14: u1,
        /// Pending Channel 15
        PENDCH15: u1,
        /// Pending Channel 16
        PENDCH16: u1,
        /// Pending Channel 17
        PENDCH17: u1,
        /// Pending Channel 18
        PENDCH18: u1,
        /// Pending Channel 19
        PENDCH19: u1,
        /// Pending Channel 20
        PENDCH20: u1,
        /// Pending Channel 21
        PENDCH21: u1,
        /// Pending Channel 22
        PENDCH22: u1,
        /// Pending Channel 23
        PENDCH23: u1,
        /// Pending Channel 24
        PENDCH24: u1,
        /// Pending Channel 25
        PENDCH25: u1,
        /// Pending Channel 26
        PENDCH26: u1,
        /// Pending Channel 27
        PENDCH27: u1,
        /// Pending Channel 28
        PENDCH28: u1,
        /// Pending Channel 29
        PENDCH29: u1,
        /// Pending Channel 30
        PENDCH30: u1,
        /// Pending Channel 31
        PENDCH31: u1,
    }),
    /// Active Channel and Levels
    /// offset: 0x30
    ACTIVE: mmio.Mmio(packed struct(u32) {
        /// Level 0 Channel Trigger Request Executing
        LVLEX0: u1,
        /// Level 1 Channel Trigger Request Executing
        LVLEX1: u1,
        /// Level 2 Channel Trigger Request Executing
        LVLEX2: u1,
        /// Level 3 Channel Trigger Request Executing
        LVLEX3: u1,
        reserved8: u4 = 0,
        /// Active Channel ID
        ID: u5,
        reserved15: u2 = 0,
        /// Active Channel Busy
        ABUSY: u1,
        /// Active Channel Block Transfer Count
        BTCNT: u16,
    }),
    /// Descriptor Memory Section Base Address
    /// offset: 0x34
    BASEADDR: mmio.Mmio(packed struct(u32) {
        /// Descriptor Memory Base Address
        BASEADDR: u32,
    }),
    /// Write-Back Memory Section Base Address
    /// offset: 0x38
    WRBADDR: mmio.Mmio(packed struct(u32) {
        /// Write-Back Memory Base Address
        WRBADDR: u32,
    }),
    /// offset: 0x3c
    reserved60: [4]u8,
    /// offset: 0x40
    CHANNEL: [32]CHANNEL,
};

/// Direct Memory Access Controller
pub const DMAC_DESCRIPTOR = extern struct {
    /// Block Transfer Control
    /// offset: 0x00
    BTCTRL: mmio.Mmio(packed struct(u16) {
        /// Descriptor Valid
        VALID: u1,
        /// Block Event Output Selection
        EVOSEL: DMAC_BTCTRL__EVOSEL,
        /// Block Action
        BLOCKACT: DMAC_BTCTRL__BLOCKACT,
        reserved8: u3 = 0,
        /// Beat Size
        BEATSIZE: DMAC_BTCTRL__BEATSIZE,
        /// Source Address Increment Enable
        SRCINC: u1,
        /// Destination Address Increment Enable
        DSTINC: u1,
        /// Step Selection
        STEPSEL: DMAC_BTCTRL__STEPSEL,
        /// Address Increment Step Size
        STEPSIZE: DMAC_BTCTRL__STEPSIZE,
    }),
    /// Block Transfer Count
    /// offset: 0x02
    BTCNT: mmio.Mmio(packed struct(u16) {
        /// Block Transfer Count
        BTCNT: u16,
    }),
    /// Block Transfer Source Address
    /// offset: 0x04
    SRCADDR: mmio.Mmio(packed struct(u32) {
        /// Transfer Source Address
        SRCADDR: u32,
    }),
    /// Block Transfer Destination Address
    /// offset: 0x08
    DSTADDR: mmio.Mmio(packed struct(u32) {
        /// CRC Checksum Initial Value
        CHKINIT: u32,
    }),
    /// Next Descriptor Address
    /// offset: 0x0c
    DESCADDR: mmio.Mmio(packed struct(u32) {
        /// Next Descriptor Address
        DESCADDR: u32,
    }),
};
