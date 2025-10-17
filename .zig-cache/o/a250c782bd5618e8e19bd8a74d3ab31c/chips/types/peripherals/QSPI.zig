const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const QSPI = extern struct {
    pub const QSPI_CTRLB__CSMODE = enum(u2) {
        /// The chip select is deasserted if TD has not been reloaded before the end of the current transfer.
        NORELOAD = 0x0,
        /// The chip select is deasserted when the bit LASTXFER is written at 1 and the character written in TD has been transferred.
        LASTXFER = 0x1,
        /// The chip select is deasserted systematically after each transfer.
        SYSTEMATICALLY = 0x2,
        _,
    };

    pub const QSPI_CTRLB__DATALEN = enum(u4) {
        /// 8-bits transfer
        @"8BITS" = 0x0,
        /// 9 bits transfer
        @"9BITS" = 0x1,
        /// 10-bits transfer
        @"10BITS" = 0x2,
        /// 11-bits transfer
        @"11BITS" = 0x3,
        /// 12-bits transfer
        @"12BITS" = 0x4,
        /// 13-bits transfer
        @"13BITS" = 0x5,
        /// 14-bits transfer
        @"14BITS" = 0x6,
        /// 15-bits transfer
        @"15BITS" = 0x7,
        /// 16-bits transfer
        @"16BITS" = 0x8,
        _,
    };

    pub const QSPI_CTRLB__MODE = enum(u1) {
        /// SPI operating mode
        SPI = 0x0,
        /// Serial Memory operating mode
        MEMORY = 0x1,
    };

    pub const QSPI_INSTRFRAME__ADDRLEN = enum(u1) {
        /// 24-bits address length
        @"24BITS" = 0x0,
        /// 32-bits address length
        @"32BITS" = 0x1,
    };

    pub const QSPI_INSTRFRAME__OPTCODELEN = enum(u2) {
        /// 1-bit length option code
        @"1BIT" = 0x0,
        /// 2-bits length option code
        @"2BITS" = 0x1,
        /// 4-bits length option code
        @"4BITS" = 0x2,
        /// 8-bits length option code
        @"8BITS" = 0x3,
    };

    pub const QSPI_INSTRFRAME__TFRTYPE = enum(u2) {
        /// Read transfer from the serial memory.Scrambling is not performed.Read at random location (fetch) in the serial flash memory is not possible.
        READ = 0x0,
        /// Read data transfer from the serial memory.If enabled, scrambling is performed.Read at random location (fetch) in the serial flash memory is possible.
        READMEMORY = 0x1,
        /// Write transfer into the serial memory.Scrambling is not performed.
        WRITE = 0x2,
        /// Write data transfer into the serial memory.If enabled, scrambling is performed.
        WRITEMEMORY = 0x3,
    };

    pub const QSPI_INSTRFRAME__WIDTH = enum(u3) {
        /// Instruction: Single-bit SPI / Address-Option: Single-bit SPI / Data: Single-bit SPI
        SINGLE_BIT_SPI = 0x0,
        /// Instruction: Single-bit SPI / Address-Option: Single-bit SPI / Data: Dual SPI
        DUAL_OUTPUT = 0x1,
        /// Instruction: Single-bit SPI / Address-Option: Single-bit SPI / Data: Quad SPI
        QUAD_OUTPUT = 0x2,
        /// Instruction: Single-bit SPI / Address-Option: Dual SPI / Data: Dual SPI
        DUAL_IO = 0x3,
        /// Instruction: Single-bit SPI / Address-Option: Quad SPI / Data: Quad SPI
        QUAD_IO = 0x4,
        /// Instruction: Dual SPI / Address-Option: Dual SPI / Data: Dual SPI
        DUAL_CMD = 0x5,
        /// Instruction: Quad SPI / Address-Option: Quad SPI / Data: Quad SPI
        QUAD_CMD = 0x6,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u32) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        reserved24: u22 = 0,
        /// Last Transfer
        LASTXFER: u1,
        padding: u7 = 0,
    }),
    /// Control B
    /// offset: 0x04
    CTRLB: mmio.Mmio(packed struct(u32) {
        /// Serial Memory Mode
        MODE: QSPI_CTRLB__MODE,
        /// Local Loopback Enable
        LOOPEN: u1,
        /// Wait Data Read Before Transfer
        WDRBT: u1,
        /// Serial Memory reg
        SMEMREG: u1,
        /// Chip Select Mode
        CSMODE: QSPI_CTRLB__CSMODE,
        reserved8: u2 = 0,
        /// Data Length
        DATALEN: QSPI_CTRLB__DATALEN,
        reserved16: u4 = 0,
        /// Delay Between Consecutive Transfers
        DLYBCT: u8,
        /// Minimum Inactive CS Delay
        DLYCS: u8,
    }),
    /// Baud Rate
    /// offset: 0x08
    BAUD: mmio.Mmio(packed struct(u32) {
        /// Clock Polarity
        CPOL: u1,
        /// Clock Phase
        CPHA: u1,
        reserved8: u6 = 0,
        /// Serial Clock Baud Rate
        BAUD: u8,
        /// Delay Before SCK
        DLYBS: u8,
        padding: u8 = 0,
    }),
    /// Receive Data
    /// offset: 0x0c
    RXDATA: mmio.Mmio(packed struct(u32) {
        /// Receive Data
        DATA: u16,
        padding: u16 = 0,
    }),
    /// Transmit Data
    /// offset: 0x10
    TXDATA: mmio.Mmio(packed struct(u32) {
        /// Transmit Data
        DATA: u16,
        padding: u16 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x14
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// Receive Data Register Full Interrupt Disable
        RXC: u1,
        /// Transmit Data Register Empty Interrupt Disable
        DRE: u1,
        /// Transmission Complete Interrupt Disable
        TXC: u1,
        /// Overrun Error Interrupt Disable
        ERROR: u1,
        reserved8: u4 = 0,
        /// Chip Select Rise Interrupt Disable
        CSRISE: u1,
        reserved10: u1 = 0,
        /// Instruction End Interrupt Disable
        INSTREND: u1,
        padding: u21 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x18
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// Receive Data Register Full Interrupt Enable
        RXC: u1,
        /// Transmit Data Register Empty Interrupt Enable
        DRE: u1,
        /// Transmission Complete Interrupt Enable
        TXC: u1,
        /// Overrun Error Interrupt Enable
        ERROR: u1,
        reserved8: u4 = 0,
        /// Chip Select Rise Interrupt Enable
        CSRISE: u1,
        reserved10: u1 = 0,
        /// Instruction End Interrupt Enable
        INSTREND: u1,
        padding: u21 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x1c
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// Receive Data Register Full
        RXC: u1,
        /// Transmit Data Register Empty
        DRE: u1,
        /// Transmission Complete
        TXC: u1,
        /// Overrun Error
        ERROR: u1,
        reserved8: u4 = 0,
        /// Chip Select Rise
        CSRISE: u1,
        reserved10: u1 = 0,
        /// Instruction End
        INSTREND: u1,
        padding: u21 = 0,
    }),
    /// Status Register
    /// offset: 0x20
    STATUS: mmio.Mmio(packed struct(u32) {
        reserved1: u1 = 0,
        /// Enable
        ENABLE: u1,
        reserved9: u7 = 0,
        /// Chip Select
        CSSTATUS: u1,
        padding: u22 = 0,
    }),
    /// offset: 0x24
    reserved36: [12]u8,
    /// Instruction Address
    /// offset: 0x30
    INSTRADDR: mmio.Mmio(packed struct(u32) {
        /// Instruction Address
        ADDR: u32,
    }),
    /// Instruction Code
    /// offset: 0x34
    INSTRCTRL: mmio.Mmio(packed struct(u32) {
        /// Instruction Code
        INSTR: u8,
        reserved16: u8 = 0,
        /// Option Code
        OPTCODE: u8,
        padding: u8 = 0,
    }),
    /// Instruction Frame
    /// offset: 0x38
    INSTRFRAME: mmio.Mmio(packed struct(u32) {
        /// Instruction Code, Address, Option Code and Data Width
        WIDTH: QSPI_INSTRFRAME__WIDTH,
        reserved4: u1 = 0,
        /// Instruction Enable
        INSTREN: u1,
        /// Address Enable
        ADDREN: u1,
        /// Option Enable
        OPTCODEEN: u1,
        /// Data Enable
        DATAEN: u1,
        /// Option Code Length
        OPTCODELEN: QSPI_INSTRFRAME__OPTCODELEN,
        /// Address Length
        ADDRLEN: QSPI_INSTRFRAME__ADDRLEN,
        reserved12: u1 = 0,
        /// Data Transfer Type
        TFRTYPE: QSPI_INSTRFRAME__TFRTYPE,
        /// Continuous Read Mode
        CRMODE: u1,
        /// Double Data Rate Enable
        DDREN: u1,
        /// Dummy Cycles Length
        DUMMYLEN: u5,
        padding: u11 = 0,
    }),
    /// offset: 0x3c
    reserved60: [4]u8,
    /// Scrambling Mode
    /// offset: 0x40
    SCRAMBCTRL: mmio.Mmio(packed struct(u32) {
        /// Scrambling/Unscrambling Enable
        ENABLE: u1,
        /// Scrambling/Unscrambling Random Value Disable
        RANDOMDIS: u1,
        padding: u30 = 0,
    }),
    /// Scrambling Key
    /// offset: 0x44
    SCRAMBKEY: mmio.Mmio(packed struct(u32) {
        /// Scrambling User Key
        KEY: u32,
    }),
};
