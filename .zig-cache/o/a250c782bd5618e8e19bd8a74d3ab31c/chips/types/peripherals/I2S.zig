const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const I2S = extern struct {
    pub const I2S_CLKCTRL__BITDELAY = enum(u1) {
        /// Left Justified (0 Bit Delay)
        LJ = 0x0,
        /// I2S (1 Bit Delay)
        I2S = 0x1,
    };

    pub const I2S_CLKCTRL__FSSEL = enum(u1) {
        /// Divided Serial Clock n is used as Frame Sync n source
        SCKDIV = 0x0,
        /// FSn input pin is used as Frame Sync n source
        FSPIN = 0x1,
    };

    pub const I2S_CLKCTRL__FSWIDTH = enum(u2) {
        /// Frame Sync Pulse is 1 Slot wide (default for I2S protocol)
        SLOT = 0x0,
        /// Frame Sync Pulse is half a Frame wide
        HALF = 0x1,
        /// Frame Sync Pulse is 1 Bit wide
        BIT = 0x2,
        /// Clock Unit n operates in Burst mode, with a 1-bit wide Frame Sync pulse per Data sample, only when Data transfer is requested
        BURST = 0x3,
    };

    pub const I2S_CLKCTRL__MCKSEL = enum(u1) {
        /// GCLK_I2S_n is used as Master Clock n source
        GCLK = 0x0,
        /// MCKn input pin is used as Master Clock n source
        MCKPIN = 0x1,
    };

    pub const I2S_CLKCTRL__SCKSEL = enum(u1) {
        /// Divided Master Clock n is used as Serial Clock n source
        MCKDIV = 0x0,
        /// SCKn input pin is used as Serial Clock n source
        SCKPIN = 0x1,
    };

    pub const I2S_CLKCTRL__SLOTSIZE = enum(u2) {
        /// 8-bit Slot for Clock Unit n
        @"8" = 0x0,
        /// 16-bit Slot for Clock Unit n
        @"16" = 0x1,
        /// 24-bit Slot for Clock Unit n
        @"24" = 0x2,
        /// 32-bit Slot for Clock Unit n
        @"32" = 0x3,
    };

    pub const I2S_RXCTRL__BITREV = enum(u1) {
        /// Transfer Data Most Significant Bit (MSB) first (default for I2S protocol)
        MSBIT = 0x0,
        /// Transfer Data Least Significant Bit (LSB) first
        LSBIT = 0x1,
    };

    pub const I2S_RXCTRL__CLKSEL = enum(u1) {
        /// Use Clock Unit 0
        CLK0 = 0x0,
        /// Use Clock Unit 1
        CLK1 = 0x1,
    };

    pub const I2S_RXCTRL__DATASIZE = enum(u3) {
        /// 32 bits
        @"32" = 0x0,
        /// 24 bits
        @"24" = 0x1,
        /// 20 bits
        @"20" = 0x2,
        /// 18 bits
        @"18" = 0x3,
        /// 16 bits
        @"16" = 0x4,
        /// 16 bits compact stereo
        @"16C" = 0x5,
        /// 8 bits
        @"8" = 0x6,
        /// 8 bits compact stereo
        @"8C" = 0x7,
    };

    pub const I2S_RXCTRL__DMA = enum(u1) {
        /// Single DMA channel
        SINGLE = 0x0,
        /// One DMA channel per data channel
        MULTIPLE = 0x1,
    };

    pub const I2S_RXCTRL__EXTEND = enum(u2) {
        /// Extend with zeroes
        ZERO = 0x0,
        /// Extend with ones
        ONE = 0x1,
        /// Extend with Most Significant Bit
        MSBIT = 0x2,
        /// Extend with Least Significant Bit
        LSBIT = 0x3,
    };

    pub const I2S_RXCTRL__MONO = enum(u1) {
        /// Normal mode
        STEREO = 0x0,
        /// Left channel data is duplicated to right channel
        MONO = 0x1,
    };

    pub const I2S_RXCTRL__SERMODE = enum(u2) {
        /// Receive
        RX = 0x0,
        /// Receive one PDM data on each serial clock edge
        PDM2 = 0x2,
        _,
    };

    pub const I2S_RXCTRL__SLOTADJ = enum(u1) {
        /// Data is right adjusted in slot
        RIGHT = 0x0,
        /// Data is left adjusted in slot
        LEFT = 0x1,
    };

    pub const I2S_RXCTRL__WORDADJ = enum(u1) {
        /// Data is right adjusted in word
        RIGHT = 0x0,
        /// Data is left adjusted in word
        LEFT = 0x1,
    };

    pub const I2S_TXCTRL__BITREV = enum(u1) {
        /// Transfer Data Most Significant Bit (MSB) first (default for I2S protocol)
        MSBIT = 0x0,
        /// Transfer Data Least Significant Bit (LSB) first
        LSBIT = 0x1,
    };

    pub const I2S_TXCTRL__CLKSEL = enum(u1) {
        /// Use Clock Unit 0
        CLK0 = 0x0,
        /// Use Clock Unit 1
        CLK1 = 0x1,
    };

    pub const I2S_TXCTRL__DATASIZE = enum(u3) {
        /// 32 bits
        @"32" = 0x0,
        /// 24 bits
        @"24" = 0x1,
        /// 20 bits
        @"20" = 0x2,
        /// 18 bits
        @"18" = 0x3,
        /// 16 bits
        @"16" = 0x4,
        /// 16 bits compact stereo
        @"16C" = 0x5,
        /// 8 bits
        @"8" = 0x6,
        /// 8 bits compact stereo
        @"8C" = 0x7,
    };

    pub const I2S_TXCTRL__DMA = enum(u1) {
        /// Single DMA channel
        SINGLE = 0x0,
        /// One DMA channel per data channel
        MULTIPLE = 0x1,
    };

    pub const I2S_TXCTRL__EXTEND = enum(u2) {
        /// Extend with zeroes
        ZERO = 0x0,
        /// Extend with ones
        ONE = 0x1,
        /// Extend with Most Significant Bit
        MSBIT = 0x2,
        /// Extend with Least Significant Bit
        LSBIT = 0x3,
    };

    pub const I2S_TXCTRL__MONO = enum(u1) {
        /// Normal mode
        STEREO = 0x0,
        /// Left channel data is duplicated to right channel
        MONO = 0x1,
    };

    pub const I2S_TXCTRL__SERMODE = enum(u2) {
        /// Receive
        RX = 0x0,
        /// Transmit
        TX = 0x1,
        /// Receive one PDM data on each serial clock edge
        PDM2 = 0x2,
        _,
    };

    pub const I2S_TXCTRL__SLOTADJ = enum(u1) {
        /// Data is right adjusted in slot
        RIGHT = 0x0,
        /// Data is left adjusted in slot
        LEFT = 0x1,
    };

    pub const I2S_TXCTRL__TXDEFAULT = enum(u2) {
        /// Output Default Value is 0
        ZERO = 0x0,
        /// Output Default Value is 1
        ONE = 0x1,
        /// Output Default Value is high impedance
        HIZ = 0x3,
        _,
    };

    pub const I2S_TXCTRL__TXSAME = enum(u1) {
        /// Zero data transmitted in case of underrun
        ZERO = 0x0,
        /// Last data transmitted in case of underrun
        SAME = 0x1,
    };

    pub const I2S_TXCTRL__WORDADJ = enum(u1) {
        /// Data is right adjusted in word
        RIGHT = 0x0,
        /// Data is left adjusted in word
        LEFT = 0x1,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        /// Clock Unit 0 Enable
        CKEN0: u1,
        /// Clock Unit 1 Enable
        CKEN1: u1,
        /// Tx Serializer Enable
        TXEN: u1,
        /// Rx Serializer Enable
        RXEN: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x01
    reserved1: [3]u8,
    /// Clock Unit n Control
    /// offset: 0x04
    CLKCTRL: [2]mmio.Mmio(packed struct(u32) {
        /// Slot Size
        SLOTSIZE: I2S_CLKCTRL__SLOTSIZE,
        /// Number of Slots in Frame
        NBSLOTS: u3,
        /// Frame Sync Width
        FSWIDTH: I2S_CLKCTRL__FSWIDTH,
        /// Data Delay from Frame Sync
        BITDELAY: I2S_CLKCTRL__BITDELAY,
        /// Frame Sync Select
        FSSEL: I2S_CLKCTRL__FSSEL,
        /// Frame Sync Invert
        FSINV: u1,
        /// Frame Sync Output Invert
        FSOUTINV: u1,
        /// Serial Clock Select
        SCKSEL: I2S_CLKCTRL__SCKSEL,
        /// Serial Clock Output Invert
        SCKOUTINV: u1,
        /// Master Clock Select
        MCKSEL: I2S_CLKCTRL__MCKSEL,
        /// Master Clock Enable
        MCKEN: u1,
        /// Master Clock Output Invert
        MCKOUTINV: u1,
        /// Master Clock Division Factor
        MCKDIV: u6,
        reserved24: u2 = 0,
        /// Master Clock Output Division Factor
        MCKOUTDIV: u6,
        padding: u2 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x0c
    INTENCLR: mmio.Mmio(packed struct(u16) {
        /// Receive Ready 0 Interrupt Enable
        RXRDY0: u1,
        /// Receive Ready 1 Interrupt Enable
        RXRDY1: u1,
        reserved4: u2 = 0,
        /// Receive Overrun 0 Interrupt Enable
        RXOR0: u1,
        /// Receive Overrun 1 Interrupt Enable
        RXOR1: u1,
        reserved8: u2 = 0,
        /// Transmit Ready 0 Interrupt Enable
        TXRDY0: u1,
        /// Transmit Ready 1 Interrupt Enable
        TXRDY1: u1,
        reserved12: u2 = 0,
        /// Transmit Underrun 0 Interrupt Enable
        TXUR0: u1,
        /// Transmit Underrun 1 Interrupt Enable
        TXUR1: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x0e
    reserved14: [2]u8,
    /// Interrupt Enable Set
    /// offset: 0x10
    INTENSET: mmio.Mmio(packed struct(u16) {
        /// Receive Ready 0 Interrupt Enable
        RXRDY0: u1,
        /// Receive Ready 1 Interrupt Enable
        RXRDY1: u1,
        reserved4: u2 = 0,
        /// Receive Overrun 0 Interrupt Enable
        RXOR0: u1,
        /// Receive Overrun 1 Interrupt Enable
        RXOR1: u1,
        reserved8: u2 = 0,
        /// Transmit Ready 0 Interrupt Enable
        TXRDY0: u1,
        /// Transmit Ready 1 Interrupt Enable
        TXRDY1: u1,
        reserved12: u2 = 0,
        /// Transmit Underrun 0 Interrupt Enable
        TXUR0: u1,
        /// Transmit Underrun 1 Interrupt Enable
        TXUR1: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x12
    reserved18: [2]u8,
    /// Interrupt Flag Status and Clear
    /// offset: 0x14
    INTFLAG: mmio.Mmio(packed struct(u16) {
        /// Receive Ready 0
        RXRDY0: u1,
        /// Receive Ready 1
        RXRDY1: u1,
        reserved4: u2 = 0,
        /// Receive Overrun 0
        RXOR0: u1,
        /// Receive Overrun 1
        RXOR1: u1,
        reserved8: u2 = 0,
        /// Transmit Ready 0
        TXRDY0: u1,
        /// Transmit Ready 1
        TXRDY1: u1,
        reserved12: u2 = 0,
        /// Transmit Underrun 0
        TXUR0: u1,
        /// Transmit Underrun 1
        TXUR1: u1,
        padding: u2 = 0,
    }),
    /// offset: 0x16
    reserved22: [2]u8,
    /// Synchronization Status
    /// offset: 0x18
    SYNCBUSY: mmio.Mmio(packed struct(u16) {
        /// Software Reset Synchronization Status
        SWRST: u1,
        /// Enable Synchronization Status
        ENABLE: u1,
        /// Clock Unit 0 Enable Synchronization Status
        CKEN0: u1,
        /// Clock Unit 1 Enable Synchronization Status
        CKEN1: u1,
        /// Tx Serializer Enable Synchronization Status
        TXEN: u1,
        /// Rx Serializer Enable Synchronization Status
        RXEN: u1,
        reserved8: u2 = 0,
        /// Tx Data Synchronization Status
        TXDATA: u1,
        /// Rx Data Synchronization Status
        RXDATA: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x1a
    reserved26: [6]u8,
    /// Tx Serializer Control
    /// offset: 0x20
    TXCTRL: mmio.Mmio(packed struct(u32) {
        /// Serializer Mode
        SERMODE: I2S_TXCTRL__SERMODE,
        /// Line Default Line when Slot Disabled
        TXDEFAULT: I2S_TXCTRL__TXDEFAULT,
        /// Transmit Data when Underrun
        TXSAME: I2S_TXCTRL__TXSAME,
        /// Clock Unit Selection
        CLKSEL: I2S_TXCTRL__CLKSEL,
        reserved7: u1 = 0,
        /// Data Slot Formatting Adjust
        SLOTADJ: I2S_TXCTRL__SLOTADJ,
        /// Data Word Size
        DATASIZE: I2S_TXCTRL__DATASIZE,
        reserved12: u1 = 0,
        /// Data Word Formatting Adjust
        WORDADJ: I2S_TXCTRL__WORDADJ,
        /// Data Formatting Bit Extension
        EXTEND: I2S_TXCTRL__EXTEND,
        /// Data Formatting Bit Reverse
        BITREV: I2S_TXCTRL__BITREV,
        /// Slot 0 Disabled for this Serializer
        SLOTDIS0: u1,
        /// Slot 1 Disabled for this Serializer
        SLOTDIS1: u1,
        /// Slot 2 Disabled for this Serializer
        SLOTDIS2: u1,
        /// Slot 3 Disabled for this Serializer
        SLOTDIS3: u1,
        /// Slot 4 Disabled for this Serializer
        SLOTDIS4: u1,
        /// Slot 5 Disabled for this Serializer
        SLOTDIS5: u1,
        /// Slot 6 Disabled for this Serializer
        SLOTDIS6: u1,
        /// Slot 7 Disabled for this Serializer
        SLOTDIS7: u1,
        /// Mono Mode
        MONO: I2S_TXCTRL__MONO,
        /// Single or Multiple DMA Channels
        DMA: I2S_TXCTRL__DMA,
        padding: u6 = 0,
    }),
    /// Rx Serializer Control
    /// offset: 0x24
    RXCTRL: mmio.Mmio(packed struct(u32) {
        /// Serializer Mode
        SERMODE: I2S_RXCTRL__SERMODE,
        reserved5: u3 = 0,
        /// Clock Unit Selection
        CLKSEL: I2S_RXCTRL__CLKSEL,
        reserved7: u1 = 0,
        /// Data Slot Formatting Adjust
        SLOTADJ: I2S_RXCTRL__SLOTADJ,
        /// Data Word Size
        DATASIZE: I2S_RXCTRL__DATASIZE,
        reserved12: u1 = 0,
        /// Data Word Formatting Adjust
        WORDADJ: I2S_RXCTRL__WORDADJ,
        /// Data Formatting Bit Extension
        EXTEND: I2S_RXCTRL__EXTEND,
        /// Data Formatting Bit Reverse
        BITREV: I2S_RXCTRL__BITREV,
        /// Slot 0 Disabled for this Serializer
        SLOTDIS0: u1,
        /// Slot 1 Disabled for this Serializer
        SLOTDIS1: u1,
        /// Slot 2 Disabled for this Serializer
        SLOTDIS2: u1,
        /// Slot 3 Disabled for this Serializer
        SLOTDIS3: u1,
        /// Slot 4 Disabled for this Serializer
        SLOTDIS4: u1,
        /// Slot 5 Disabled for this Serializer
        SLOTDIS5: u1,
        /// Slot 6 Disabled for this Serializer
        SLOTDIS6: u1,
        /// Slot 7 Disabled for this Serializer
        SLOTDIS7: u1,
        /// Mono Mode
        MONO: I2S_RXCTRL__MONO,
        /// Single or Multiple DMA Channels
        DMA: I2S_RXCTRL__DMA,
        /// Loop-back Test Mode
        RXLOOP: u1,
        padding: u5 = 0,
    }),
    /// offset: 0x28
    reserved40: [8]u8,
    /// Tx Data
    /// offset: 0x30
    TXDATA: mmio.Mmio(packed struct(u32) {
        /// Sample Data
        DATA: u32,
    }),
    /// Rx Data
    /// offset: 0x34
    RXDATA: mmio.Mmio(packed struct(u32) {
        /// Sample Data
        DATA: u32,
    }),
};
