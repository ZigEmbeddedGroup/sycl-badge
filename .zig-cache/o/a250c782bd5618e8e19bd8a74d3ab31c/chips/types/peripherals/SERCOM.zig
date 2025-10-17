const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const SERCOM = extern union {
    pub const Mode = enum {
        I2CM,
        I2CS,
        SPIS,
        SPIM,
        USART_EXT,
        USART_INT,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.I2CM_CTRLA.read().MODE;
            switch (value) {
                5,
                => return .I2CM,
                else => {},
            }
        }
        {
            const value = self.I2CS_CTRLA.read().MODE;
            switch (value) {
                4,
                => return .I2CS,
                else => {},
            }
        }
        {
            const value = self.SPIS_CTRLA.read().MODE;
            switch (value) {
                2,
                => return .SPIS,
                else => {},
            }
        }
        {
            const value = self.SPIM_CTRLA.read().MODE;
            switch (value) {
                3,
                => return .SPIM,
                else => {},
            }
        }
        {
            const value = self.USART_CTRLA.read().MODE;
            switch (value) {
                0,
                => return .USART_EXT,
                else => {},
            }
        }
        {
            const value = self.USART_CTRLA.read().MODE;
            switch (value) {
                1,
                => return .USART_INT,
                else => {},
            }
        }

        unreachable;
    }

    pub const SERCOM_I2CM_CTRLA__INACTOUT = enum(u2) {
        /// Disabled
        DISABLE = 0x0,
        /// 5-6 SCL Time-Out(50-60us)
        @"55US" = 0x1,
        /// 10-11 SCL Time-Out(100-110us)
        @"105US" = 0x2,
        /// 20-21 SCL Time-Out(200-210us)
        @"205US" = 0x3,
    };

    pub const SERCOM_I2CM_CTRLA__MODE = enum(u3) {
        /// USART with external clock
        USART_EXT_CLK = 0x0,
        /// USART with internal clock
        USART_INT_CLK = 0x1,
        /// SPI in slave operation
        SPI_SLAVE = 0x2,
        /// SPI in master operation
        SPI_MASTER = 0x3,
        /// I2C slave operation
        I2C_SLAVE = 0x4,
        /// I2C master operation
        I2C_MASTER = 0x5,
        _,
    };

    pub const SERCOM_I2CM_CTRLA__SDAHOLD = enum(u2) {
        /// Disabled
        DISABLE = 0x0,
        /// 50-100ns hold time
        @"75NS" = 0x1,
        /// 300-600ns hold time
        @"450NS" = 0x2,
        /// 400-800ns hold time
        @"600NS" = 0x3,
    };

    pub const SERCOM_I2CM_CTRLA__SPEED = enum(u2) {
        /// Standard Mode(Sm) Upto 100kHz and Fast Mode(Fm) Upto 400kHz
        STANDARD_AND_FAST_MODE = 0x0,
        /// Fast-mode Plus Upto 1MHz
        FASTPLUS_MODE = 0x1,
        /// High-speed mode Upto 3.4MHz
        HIGH_SPEED_MODE = 0x2,
        _,
    };

    pub const SERCOM_I2CM_CTRLC__DATA32B = enum(u1) {
        /// Data transaction from/to DATA register are 8-bit
        DATA_TRANS_8BIT = 0x0,
        /// Data transaction from/to DATA register are 32-bit
        DATA_TRANS_32BIT = 0x1,
    };

    pub const SERCOM_SPIM_CTRLA__CPHA = enum(u1) {
        /// The data is sampled on a leading SCK edge and changed on a trailing SCK edge
        LEADING_EDGE = 0x0,
        /// The data is sampled on a trailing SCK edge and changed on a leading SCK edge
        TRAILING_EDGE = 0x1,
    };

    pub const SERCOM_SPIM_CTRLA__CPOL = enum(u1) {
        /// SCK is low when idle
        IDLE_LOW = 0x0,
        /// SCK is high when idle
        IDLE_HIGH = 0x1,
    };

    pub const SERCOM_SPIM_CTRLA__DIPO = enum(u2) {
        /// SERCOM PAD[0] is used as data input
        PAD0 = 0x0,
        /// SERCOM PAD[1] is used as data input
        PAD1 = 0x1,
        /// SERCOM PAD[2] is used as data input
        PAD2 = 0x2,
        /// SERCOM PAD[3] is used as data input
        PAD3 = 0x3,
    };

    pub const SERCOM_SPIM_CTRLA__DOPO = enum(u2) {
        /// DO on PAD[0], SCK on PAD[1] and SS on PAD[2]
        PAD0 = 0x0,
        /// DO on PAD[3], SCK on PAD[1] and SS on PAD[2]
        PAD2 = 0x2,
        _,
    };

    pub const SERCOM_SPIM_CTRLA__DORD = enum(u1) {
        /// MSB is transferred first
        MSB = 0x0,
        /// LSB is transferred first
        LSB = 0x1,
    };

    pub const SERCOM_SPIM_CTRLA__FORM = enum(u4) {
        /// SPI Frame
        SPI_FRAME = 0x0,
        /// SPI Frame with Addr
        SPI_FRAME_WITH_ADDR = 0x2,
        _,
    };

    pub const SERCOM_SPIM_CTRLA__MODE = enum(u3) {
        /// USART with external clock
        USART_EXT_CLK = 0x0,
        /// USART with internal clock
        USART_INT_CLK = 0x1,
        /// SPI in slave operation
        SPI_SLAVE = 0x2,
        /// SPI in master operation
        SPI_MASTER = 0x3,
        /// I2C slave operation
        I2C_SLAVE = 0x4,
        /// I2C master operation
        I2C_MASTER = 0x5,
        _,
    };

    pub const SERCOM_SPIM_CTRLB__AMODE = enum(u2) {
        /// SPI Address mask
        MASK = 0x0,
        /// Two unique Addressess
        @"2_ADDRESSES" = 0x1,
        /// Address Range
        RANGE = 0x2,
        _,
    };

    pub const SERCOM_SPIM_CTRLB__CHSIZE = enum(u3) {
        /// 8 bits
        @"8_BIT" = 0x0,
        /// 9 bits
        @"9_BIT" = 0x1,
        _,
    };

    pub const SERCOM_SPIM_CTRLC__DATA32B = enum(u1) {
        /// Transaction from and to DATA register are 8-bit
        DATA_TRANS_8BIT = 0x0,
        /// Transaction from and to DATA register are 32-bit
        DATA_TRANS_32BIT = 0x1,
    };

    pub const SERCOM_USART_CTRLA__CMODE = enum(u1) {
        /// Asynchronous Communication
        ASYNC = 0x0,
        /// Synchronous Communication
        SYNC = 0x1,
    };

    pub const SERCOM_USART_CTRLA__CPOL = enum(u1) {
        /// TxD Change:- Rising XCK edge, RxD Sample:- Falling XCK edge
        IDLE_LOW = 0x0,
        /// TxD Change:- Falling XCK edge, RxD Sample:- Rising XCK edge
        IDLE_HIGH = 0x1,
    };

    pub const SERCOM_USART_CTRLA__DORD = enum(u1) {
        /// MSB is transmitted first
        MSB = 0x0,
        /// LSB is transmitted first
        LSB = 0x1,
    };

    pub const SERCOM_USART_CTRLA__FORM = enum(u4) {
        /// USART frame
        USART_FRAME_NO_PARITY = 0x0,
        /// USART frame with parity
        USART_FRAME_WITH_PARITY = 0x1,
        /// LIN Master - Break and sync generation
        USART_FRAME_LIN_MASTER_MODE = 0x2,
        /// Auto-baud - break detection and auto-baud
        USART_FRAME_AUTO_BAUD_NO_PARITY = 0x4,
        /// Auto-baud - break detection and auto-baud with parity
        USART_FRAME_AUTO_BAUD_WITH_PARITY = 0x5,
        /// ISO 7816
        USART_FRAME_ISO_7816 = 0x7,
        _,
    };

    pub const SERCOM_USART_CTRLA__MODE = enum(u3) {
        /// USART with external clock
        USART_EXT_CLK = 0x0,
        /// USART with internal clock
        USART_INT_CLK = 0x1,
        /// SPI in slave operation
        SPI_SLAVE = 0x2,
        /// SPI in master operation
        SPI_MASTER = 0x3,
        /// I2C slave operation
        I2C_SLAVE = 0x4,
        /// I2C master operation
        I2C_MASTER = 0x5,
        _,
    };

    pub const SERCOM_USART_CTRLA__RXPO = enum(u2) {
        /// SERCOM PAD[0] is used for data reception
        PAD0 = 0x0,
        /// SERCOM PAD[1] is used for data reception
        PAD1 = 0x1,
        /// SERCOM PAD[2] is used for data reception
        PAD2 = 0x2,
        /// SERCOM PAD[3] is used for data reception
        PAD3 = 0x3,
    };

    pub const SERCOM_USART_CTRLA__SAMPR = enum(u3) {
        /// 16x over-sampling using arithmetic baudrate generation
        @"16X_ARITHMETIC" = 0x0,
        /// 16x over-sampling using fractional baudrate generation
        @"16X_FRACTIONAL" = 0x1,
        /// 8x over-sampling using arithmetic baudrate generation
        @"8X_ARITHMETIC" = 0x2,
        /// 8x over-sampling using fractional baudrate generation
        @"8X_FRACTIONAL" = 0x3,
        /// 3x over-sampling using arithmetic baudrate generation
        @"3X_ARITHMETIC" = 0x4,
        _,
    };

    pub const SERCOM_USART_CTRLA__TXPO = enum(u2) {
        /// SERCOM PAD[0] is used for data transmission
        PAD0 = 0x0,
        /// SERCOM_PAD[0] is used for data transmission
        PAD3 = 0x3,
        _,
    };

    pub const SERCOM_USART_CTRLB__CHSIZE = enum(u3) {
        /// 8 Bits
        @"8_BIT" = 0x0,
        /// 9 Bits
        @"9_BIT" = 0x1,
        /// 5 Bits
        @"5_BIT" = 0x5,
        /// 6 Bits
        @"6_BIT" = 0x6,
        /// 7 Bits
        @"7_BIT" = 0x7,
        _,
    };

    pub const SERCOM_USART_CTRLB__PMODE = enum(u1) {
        /// Even Parity
        EVEN = 0x0,
        /// Odd Parity
        ODD = 0x1,
    };

    pub const SERCOM_USART_CTRLB__SBMODE = enum(u1) {
        /// One Stop Bit
        @"1_BIT" = 0x0,
        /// Two Stop Bits
        @"2_BIT" = 0x1,
    };

    pub const SERCOM_USART_CTRLC__DATA32B = enum(u2) {
        /// Data reads and writes according CTRLB.CHSIZE
        DATA_READ_WRITE_CHSIZE = 0x0,
        /// Data reads according CTRLB.CHSIZE and writes according 32-bit extension
        DATA_READ_CHSIZE_WRITE_32BIT = 0x1,
        /// Data reads according 32-bit extension and writes according CTRLB.CHSIZE
        DATA_READ_32BIT_WRITE_CHSIZE = 0x2,
        /// Data reads and writes according 32-bit extension
        DATA_READ_WRITE_32BIT = 0x3,
    };

    I2CM: extern struct {
        /// I2CM Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_I2CM_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run in Standby
            RUNSTDBY: u1,
            reserved16: u8 = 0,
            /// Pin Usage
            PINOUT: u1,
            reserved20: u3 = 0,
            /// SDA Hold Time
            SDAHOLD: SERCOM_I2CM_CTRLA__SDAHOLD,
            /// Master SCL Low Extend Timeout
            MEXTTOEN: u1,
            /// Slave SCL Low Extend Timeout
            SEXTTOEN: u1,
            /// Transfer Speed
            SPEED: SERCOM_I2CM_CTRLA__SPEED,
            reserved27: u1 = 0,
            /// SCL Clock Stretch Mode
            SCLSM: u1,
            /// Inactive Time-Out
            INACTOUT: SERCOM_I2CM_CTRLA__INACTOUT,
            /// SCL Low Timeout Enable
            LOWTOUTEN: u1,
            padding: u1 = 0,
        }),
        /// I2CM Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            reserved8: u8 = 0,
            /// Smart Mode Enable
            SMEN: u1,
            /// Quick Command Enable
            QCEN: u1,
            reserved16: u6 = 0,
            /// Command
            CMD: u2,
            /// Acknowledge Action
            ACKACT: u1,
            padding: u13 = 0,
        }),
        /// I2CM Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            reserved24: u24 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_I2CM_CTRLC__DATA32B,
            padding: u7 = 0,
        }),
        /// I2CM Baud Rate
        /// offset: 0x0c
        BAUD: mmio.Mmio(packed struct(u32) {
            /// Baud Rate Value
            BAUD: u8,
            /// Baud Rate Value Low
            BAUDLOW: u8,
            /// High Speed Baud Rate Value
            HSBAUD: u8,
            /// High Speed Baud Rate Value Low
            HSBAUDLOW: u8,
        }),
        /// offset: 0x10
        reserved16: [4]u8,
        /// I2CM Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Master On Bus Interrupt Disable
            MB: u1,
            /// Slave On Bus Interrupt Disable
            SB: u1,
            reserved7: u5 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// I2CM Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Master On Bus Interrupt Enable
            MB: u1,
            /// Slave On Bus Interrupt Enable
            SB: u1,
            reserved7: u5 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// I2CM Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Master On Bus Interrupt
            MB: u1,
            /// Slave On Bus Interrupt
            SB: u1,
            reserved7: u5 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// I2CM Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            /// Bus Error
            BUSERR: u1,
            /// Arbitration Lost
            ARBLOST: u1,
            /// Received Not Acknowledge
            RXNACK: u1,
            reserved4: u1 = 0,
            /// Bus State
            BUSSTATE: u2,
            /// SCL Low Timeout
            LOWTOUT: u1,
            /// Clock Hold
            CLKHOLD: u1,
            /// Master SCL Low Extend Timeout
            MEXTTOUT: u1,
            /// Slave SCL Low Extend Timeout
            SEXTTOUT: u1,
            /// Length Error
            LENERR: u1,
            padding: u5 = 0,
        }),
        /// I2CM Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            /// System Operation Synchronization Busy
            SYSOP: u1,
            reserved4: u1 = 0,
            /// Length Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// offset: 0x20
        reserved32: [4]u8,
        /// I2CM Address
        /// offset: 0x24
        ADDR: mmio.Mmio(packed struct(u32) {
            /// Address Value
            ADDR: u11,
            reserved13: u2 = 0,
            /// Length Enable
            LENEN: u1,
            /// High Speed Mode
            HS: u1,
            /// Ten Bit Addressing Enable
            TENBITEN: u1,
            /// Length
            LEN: u8,
            padding: u8 = 0,
        }),
        /// I2CM Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u8) {
            /// Data Value
            DATA: u8,
        }),
        /// offset: 0x29
        reserved41: [7]u8,
        /// I2CM Debug Control
        /// offset: 0x30
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Debug Mode
            DBGSTOP: u1,
            padding: u7 = 0,
        }),
    },
    I2CS: extern struct {
        /// I2CS Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_I2CM_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run during Standby
            RUNSTDBY: u1,
            reserved16: u8 = 0,
            /// Pin Usage
            PINOUT: u1,
            reserved20: u3 = 0,
            /// SDA Hold Time
            SDAHOLD: SERCOM_I2CM_CTRLA__SDAHOLD,
            reserved23: u1 = 0,
            /// Slave SCL Low Extend Timeout
            SEXTTOEN: u1,
            /// Transfer Speed
            SPEED: SERCOM_I2CM_CTRLA__SPEED,
            reserved27: u1 = 0,
            /// SCL Clock Stretch Mode
            SCLSM: u1,
            reserved30: u2 = 0,
            /// SCL Low Timeout Enable
            LOWTOUTEN: u1,
            padding: u1 = 0,
        }),
        /// I2CS Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            reserved8: u8 = 0,
            /// Smart Mode Enable
            SMEN: u1,
            /// PMBus Group Command
            GCMD: u1,
            /// Automatic Address Acknowledge
            AACKEN: u1,
            reserved14: u3 = 0,
            /// Address Mode
            AMODE: u2,
            /// Command
            CMD: u2,
            /// Acknowledge Action
            ACKACT: u1,
            padding: u13 = 0,
        }),
        /// I2CS Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            /// SDA Setup Time
            SDASETUP: u4,
            reserved24: u20 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_I2CM_CTRLC__DATA32B,
            padding: u7 = 0,
        }),
        /// offset: 0x0c
        reserved12: [8]u8,
        /// I2CS Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Stop Received Interrupt Disable
            PREC: u1,
            /// Address Match Interrupt Disable
            AMATCH: u1,
            /// Data Interrupt Disable
            DRDY: u1,
            reserved7: u4 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// I2CS Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Stop Received Interrupt Enable
            PREC: u1,
            /// Address Match Interrupt Enable
            AMATCH: u1,
            /// Data Interrupt Enable
            DRDY: u1,
            reserved7: u4 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// I2CS Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Stop Received Interrupt
            PREC: u1,
            /// Address Match Interrupt
            AMATCH: u1,
            /// Data Interrupt
            DRDY: u1,
            reserved7: u4 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// I2CS Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            /// Bus Error
            BUSERR: u1,
            /// Transmit Collision
            COLL: u1,
            /// Received Not Acknowledge
            RXNACK: u1,
            /// Read/Write Direction
            DIR: u1,
            /// Repeated Start
            SR: u1,
            reserved6: u1 = 0,
            /// SCL Low Timeout
            LOWTOUT: u1,
            /// Clock Hold
            CLKHOLD: u1,
            reserved9: u1 = 0,
            /// Slave SCL Low Extend Timeout
            SEXTTOUT: u1,
            /// High Speed
            HS: u1,
            /// Transaction Length Error
            LENERR: u1,
            padding: u4 = 0,
        }),
        /// I2CS Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            reserved4: u2 = 0,
            /// Length Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// offset: 0x20
        reserved32: [2]u8,
        /// I2CS Length
        /// offset: 0x22
        LENGTH: mmio.Mmio(packed struct(u16) {
            /// Data Length
            LEN: u8,
            /// Data Length Enable
            LENEN: u1,
            padding: u7 = 0,
        }),
        /// I2CS Address
        /// offset: 0x24
        ADDR: mmio.Mmio(packed struct(u32) {
            /// General Call Address Enable
            GENCEN: u1,
            /// Address Value
            ADDR: u10,
            reserved15: u4 = 0,
            /// Ten Bit Addressing Enable
            TENBITEN: u1,
            reserved17: u1 = 0,
            /// Address Mask
            ADDRMASK: u10,
            padding: u5 = 0,
        }),
        /// I2CS Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u32) {
            /// Data Value
            DATA: u32,
        }),
    },
    SPIS: extern struct {
        /// SPIS Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_SPIM_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run during Standby
            RUNSTDBY: u1,
            /// Immediate Buffer Overflow Notification
            IBON: u1,
            reserved16: u7 = 0,
            /// Data Out Pinout
            DOPO: SERCOM_SPIM_CTRLA__DOPO,
            reserved20: u2 = 0,
            /// Data In Pinout
            DIPO: SERCOM_SPIM_CTRLA__DIPO,
            reserved24: u2 = 0,
            /// Frame Format
            FORM: SERCOM_SPIM_CTRLA__FORM,
            /// Clock Phase
            CPHA: SERCOM_SPIM_CTRLA__CPHA,
            /// Clock Polarity
            CPOL: SERCOM_SPIM_CTRLA__CPOL,
            /// Data Order
            DORD: SERCOM_SPIM_CTRLA__DORD,
            padding: u1 = 0,
        }),
        /// SPIS Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            /// Character Size
            CHSIZE: SERCOM_SPIM_CTRLB__CHSIZE,
            reserved6: u3 = 0,
            /// Data Preload Enable
            PLOADEN: u1,
            reserved9: u2 = 0,
            /// Slave Select Low Detect Enable
            SSDE: u1,
            reserved13: u3 = 0,
            /// Master Slave Select Enable
            MSSEN: u1,
            /// Address Mode
            AMODE: SERCOM_SPIM_CTRLB__AMODE,
            reserved17: u1 = 0,
            /// Receiver Enable
            RXEN: u1,
            padding: u14 = 0,
        }),
        /// SPIS Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            /// Inter-Character Spacing
            ICSPACE: u6,
            reserved24: u18 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_SPIM_CTRLC__DATA32B,
            padding: u7 = 0,
        }),
        /// SPIS Baud Rate
        /// offset: 0x0c
        BAUD: mmio.Mmio(packed struct(u8) {
            /// Baud Rate Value
            BAUD: u8,
        }),
        /// offset: 0x0d
        reserved13: [7]u8,
        /// SPIS Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Disable
            DRE: u1,
            /// Transmit Complete Interrupt Disable
            TXC: u1,
            /// Receive Complete Interrupt Disable
            RXC: u1,
            /// Slave Select Low Interrupt Disable
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// SPIS Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Enable
            DRE: u1,
            /// Transmit Complete Interrupt Enable
            TXC: u1,
            /// Receive Complete Interrupt Enable
            RXC: u1,
            /// Slave Select Low Interrupt Enable
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// SPIS Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt
            DRE: u1,
            /// Transmit Complete Interrupt
            TXC: u1,
            /// Receive Complete Interrupt
            RXC: u1,
            /// Slave Select Low Interrupt Flag
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// SPIS Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            reserved2: u2 = 0,
            /// Buffer Overflow
            BUFOVF: u1,
            reserved11: u8 = 0,
            /// Transaction Length Error
            LENERR: u1,
            padding: u4 = 0,
        }),
        /// SPIS Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            /// CTRLB Synchronization Busy
            CTRLB: u1,
            reserved4: u1 = 0,
            /// LENGTH Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// offset: 0x20
        reserved32: [2]u8,
        /// SPIS Length
        /// offset: 0x22
        LENGTH: mmio.Mmio(packed struct(u16) {
            /// Data Length
            LEN: u8,
            /// Data Length Enable
            LENEN: u1,
            padding: u7 = 0,
        }),
        /// SPIS Address
        /// offset: 0x24
        ADDR: mmio.Mmio(packed struct(u32) {
            /// Address Value
            ADDR: u8,
            reserved16: u8 = 0,
            /// Address Mask
            ADDRMASK: u8,
            padding: u8 = 0,
        }),
        /// SPIS Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u32) {
            /// Data Value
            DATA: u32,
        }),
        /// offset: 0x2c
        reserved44: [4]u8,
        /// SPIS Debug Control
        /// offset: 0x30
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Debug Mode
            DBGSTOP: u1,
            padding: u7 = 0,
        }),
    },
    SPIM: extern struct {
        /// SPIM Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_SPIM_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run during Standby
            RUNSTDBY: u1,
            /// Immediate Buffer Overflow Notification
            IBON: u1,
            reserved16: u7 = 0,
            /// Data Out Pinout
            DOPO: SERCOM_SPIM_CTRLA__DOPO,
            reserved20: u2 = 0,
            /// Data In Pinout
            DIPO: SERCOM_SPIM_CTRLA__DIPO,
            reserved24: u2 = 0,
            /// Frame Format
            FORM: SERCOM_SPIM_CTRLA__FORM,
            /// Clock Phase
            CPHA: SERCOM_SPIM_CTRLA__CPHA,
            /// Clock Polarity
            CPOL: SERCOM_SPIM_CTRLA__CPOL,
            /// Data Order
            DORD: SERCOM_SPIM_CTRLA__DORD,
            padding: u1 = 0,
        }),
        /// SPIM Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            /// Character Size
            CHSIZE: SERCOM_SPIM_CTRLB__CHSIZE,
            reserved6: u3 = 0,
            /// Data Preload Enable
            PLOADEN: u1,
            reserved9: u2 = 0,
            /// Slave Select Low Detect Enable
            SSDE: u1,
            reserved13: u3 = 0,
            /// Master Slave Select Enable
            MSSEN: u1,
            /// Address Mode
            AMODE: SERCOM_SPIM_CTRLB__AMODE,
            reserved17: u1 = 0,
            /// Receiver Enable
            RXEN: u1,
            padding: u14 = 0,
        }),
        /// SPIM Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            /// Inter-Character Spacing
            ICSPACE: u6,
            reserved24: u18 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_SPIM_CTRLC__DATA32B,
            padding: u7 = 0,
        }),
        /// SPIM Baud Rate
        /// offset: 0x0c
        BAUD: mmio.Mmio(packed struct(u8) {
            /// Baud Rate Value
            BAUD: u8,
        }),
        /// offset: 0x0d
        reserved13: [7]u8,
        /// SPIM Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Disable
            DRE: u1,
            /// Transmit Complete Interrupt Disable
            TXC: u1,
            /// Receive Complete Interrupt Disable
            RXC: u1,
            /// Slave Select Low Interrupt Disable
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// SPIM Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Enable
            DRE: u1,
            /// Transmit Complete Interrupt Enable
            TXC: u1,
            /// Receive Complete Interrupt Enable
            RXC: u1,
            /// Slave Select Low Interrupt Enable
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// SPIM Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt
            DRE: u1,
            /// Transmit Complete Interrupt
            TXC: u1,
            /// Receive Complete Interrupt
            RXC: u1,
            /// Slave Select Low Interrupt Flag
            SSL: u1,
            reserved7: u3 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// SPIM Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            reserved2: u2 = 0,
            /// Buffer Overflow
            BUFOVF: u1,
            reserved11: u8 = 0,
            /// Transaction Length Error
            LENERR: u1,
            padding: u4 = 0,
        }),
        /// SPIM Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            /// CTRLB Synchronization Busy
            CTRLB: u1,
            reserved4: u1 = 0,
            /// LENGTH Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// offset: 0x20
        reserved32: [2]u8,
        /// SPIM Length
        /// offset: 0x22
        LENGTH: mmio.Mmio(packed struct(u16) {
            /// Data Length
            LEN: u8,
            /// Data Length Enable
            LENEN: u1,
            padding: u7 = 0,
        }),
        /// SPIM Address
        /// offset: 0x24
        ADDR: mmio.Mmio(packed struct(u32) {
            /// Address Value
            ADDR: u8,
            reserved16: u8 = 0,
            /// Address Mask
            ADDRMASK: u8,
            padding: u8 = 0,
        }),
        /// SPIM Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u32) {
            /// Data Value
            DATA: u32,
        }),
        /// offset: 0x2c
        reserved44: [4]u8,
        /// SPIM Debug Control
        /// offset: 0x30
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Debug Mode
            DBGSTOP: u1,
            padding: u7 = 0,
        }),
    },
    USART_EXT: extern struct {
        /// USART_EXT Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_USART_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run during Standby
            RUNSTDBY: u1,
            /// Immediate Buffer Overflow Notification
            IBON: u1,
            /// Transmit Data Invert
            TXINV: u1,
            /// Receive Data Invert
            RXINV: u1,
            reserved13: u2 = 0,
            /// Sample
            SAMPR: SERCOM_USART_CTRLA__SAMPR,
            /// Transmit Data Pinout
            TXPO: SERCOM_USART_CTRLA__TXPO,
            reserved20: u2 = 0,
            /// Receive Data Pinout
            RXPO: SERCOM_USART_CTRLA__RXPO,
            /// Sample Adjustment
            SAMPA: u2,
            /// Frame Format
            FORM: SERCOM_USART_CTRLA__FORM,
            /// Communication Mode
            CMODE: SERCOM_USART_CTRLA__CMODE,
            /// Clock Polarity
            CPOL: SERCOM_USART_CTRLA__CPOL,
            /// Data Order
            DORD: SERCOM_USART_CTRLA__DORD,
            padding: u1 = 0,
        }),
        /// USART_EXT Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            /// Character Size
            CHSIZE: SERCOM_USART_CTRLB__CHSIZE,
            reserved6: u3 = 0,
            /// Stop Bit Mode
            SBMODE: SERCOM_USART_CTRLB__SBMODE,
            reserved8: u1 = 0,
            /// Collision Detection Enable
            COLDEN: u1,
            /// Start of Frame Detection Enable
            SFDE: u1,
            /// Encoding Format
            ENC: u1,
            reserved13: u2 = 0,
            /// Parity Mode
            PMODE: SERCOM_USART_CTRLB__PMODE,
            reserved16: u2 = 0,
            /// Transmitter Enable
            TXEN: u1,
            /// Receiver Enable
            RXEN: u1,
            reserved24: u6 = 0,
            /// LIN Command
            LINCMD: u2,
            padding: u6 = 0,
        }),
        /// USART_EXT Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            /// Guard Time
            GTIME: u3,
            reserved8: u5 = 0,
            /// LIN Master Break Length
            BRKLEN: u2,
            /// LIN Master Header Delay
            HDRDLY: u2,
            reserved16: u4 = 0,
            /// Inhibit Not Acknowledge
            INACK: u1,
            /// Disable Successive NACK
            DSNACK: u1,
            reserved20: u2 = 0,
            /// Maximum Iterations
            MAXITER: u3,
            reserved24: u1 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_USART_CTRLC__DATA32B,
            padding: u6 = 0,
        }),
        /// USART_EXT Baud Rate
        /// offset: 0x0c
        BAUD: mmio.Mmio(packed struct(u16) {
            /// Baud Rate Value
            BAUD: u13,
            /// Fractional Part
            FP: u3,
        }),
        /// USART_EXT Receive Pulse Length
        /// offset: 0x0e
        RXPL: mmio.Mmio(packed struct(u8) {
            /// Receive Pulse Length
            RXPL: u8,
        }),
        /// offset: 0x0f
        reserved15: [5]u8,
        /// USART_EXT Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Disable
            DRE: u1,
            /// Transmit Complete Interrupt Disable
            TXC: u1,
            /// Receive Complete Interrupt Disable
            RXC: u1,
            /// Receive Start Interrupt Disable
            RXS: u1,
            /// Clear To Send Input Change Interrupt Disable
            CTSIC: u1,
            /// Break Received Interrupt Disable
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// USART_EXT Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Enable
            DRE: u1,
            /// Transmit Complete Interrupt Enable
            TXC: u1,
            /// Receive Complete Interrupt Enable
            RXC: u1,
            /// Receive Start Interrupt Enable
            RXS: u1,
            /// Clear To Send Input Change Interrupt Enable
            CTSIC: u1,
            /// Break Received Interrupt Enable
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// USART_EXT Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt
            DRE: u1,
            /// Transmit Complete Interrupt
            TXC: u1,
            /// Receive Complete Interrupt
            RXC: u1,
            /// Receive Start Interrupt
            RXS: u1,
            /// Clear To Send Input Change Interrupt
            CTSIC: u1,
            /// Break Received Interrupt
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// USART_EXT Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            /// Parity Error
            PERR: u1,
            /// Frame Error
            FERR: u1,
            /// Buffer Overflow
            BUFOVF: u1,
            /// Clear To Send
            CTS: u1,
            /// Inconsistent Sync Field
            ISF: u1,
            /// Collision Detected
            COLL: u1,
            /// Transmitter Empty
            TXE: u1,
            /// Maximum Number of Repetitions Reached
            ITER: u1,
            padding: u8 = 0,
        }),
        /// USART_EXT Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            /// CTRLB Synchronization Busy
            CTRLB: u1,
            /// RXERRCNT Synchronization Busy
            RXERRCNT: u1,
            /// LENGTH Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// USART_EXT Receive Error Count
        /// offset: 0x20
        RXERRCNT: u8,
        /// offset: 0x21
        reserved33: [1]u8,
        /// USART_EXT Length
        /// offset: 0x22
        LENGTH: mmio.Mmio(packed struct(u16) {
            /// Data Length
            LEN: u8,
            /// Data Length Enable
            LENEN: u2,
            padding: u6 = 0,
        }),
        /// offset: 0x24
        reserved36: [4]u8,
        /// USART_EXT Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u32) {
            /// Data Value
            DATA: u32,
        }),
        /// offset: 0x2c
        reserved44: [4]u8,
        /// USART_EXT Debug Control
        /// offset: 0x30
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Debug Mode
            DBGSTOP: u1,
            padding: u7 = 0,
        }),
    },
    USART_INT: extern struct {
        /// USART_INT Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u32) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: SERCOM_USART_CTRLA__MODE,
            reserved7: u2 = 0,
            /// Run during Standby
            RUNSTDBY: u1,
            /// Immediate Buffer Overflow Notification
            IBON: u1,
            /// Transmit Data Invert
            TXINV: u1,
            /// Receive Data Invert
            RXINV: u1,
            reserved13: u2 = 0,
            /// Sample
            SAMPR: SERCOM_USART_CTRLA__SAMPR,
            /// Transmit Data Pinout
            TXPO: SERCOM_USART_CTRLA__TXPO,
            reserved20: u2 = 0,
            /// Receive Data Pinout
            RXPO: SERCOM_USART_CTRLA__RXPO,
            /// Sample Adjustment
            SAMPA: u2,
            /// Frame Format
            FORM: SERCOM_USART_CTRLA__FORM,
            /// Communication Mode
            CMODE: SERCOM_USART_CTRLA__CMODE,
            /// Clock Polarity
            CPOL: SERCOM_USART_CTRLA__CPOL,
            /// Data Order
            DORD: SERCOM_USART_CTRLA__DORD,
            padding: u1 = 0,
        }),
        /// USART_INT Control B
        /// offset: 0x04
        CTRLB: mmio.Mmio(packed struct(u32) {
            /// Character Size
            CHSIZE: SERCOM_USART_CTRLB__CHSIZE,
            reserved6: u3 = 0,
            /// Stop Bit Mode
            SBMODE: SERCOM_USART_CTRLB__SBMODE,
            reserved8: u1 = 0,
            /// Collision Detection Enable
            COLDEN: u1,
            /// Start of Frame Detection Enable
            SFDE: u1,
            /// Encoding Format
            ENC: u1,
            reserved13: u2 = 0,
            /// Parity Mode
            PMODE: SERCOM_USART_CTRLB__PMODE,
            reserved16: u2 = 0,
            /// Transmitter Enable
            TXEN: u1,
            /// Receiver Enable
            RXEN: u1,
            reserved24: u6 = 0,
            /// LIN Command
            LINCMD: u2,
            padding: u6 = 0,
        }),
        /// USART_INT Control C
        /// offset: 0x08
        CTRLC: mmio.Mmio(packed struct(u32) {
            /// Guard Time
            GTIME: u3,
            reserved8: u5 = 0,
            /// LIN Master Break Length
            BRKLEN: u2,
            /// LIN Master Header Delay
            HDRDLY: u2,
            reserved16: u4 = 0,
            /// Inhibit Not Acknowledge
            INACK: u1,
            /// Disable Successive NACK
            DSNACK: u1,
            reserved20: u2 = 0,
            /// Maximum Iterations
            MAXITER: u3,
            reserved24: u1 = 0,
            /// Data 32 Bit
            DATA32B: SERCOM_USART_CTRLC__DATA32B,
            padding: u6 = 0,
        }),
        /// USART_INT Baud Rate
        /// offset: 0x0c
        BAUD: mmio.Mmio(packed struct(u16) {
            /// Baud Rate Value
            BAUD: u13,
            /// Fractional Part
            FP: u3,
        }),
        /// USART_INT Receive Pulse Length
        /// offset: 0x0e
        RXPL: mmio.Mmio(packed struct(u8) {
            /// Receive Pulse Length
            RXPL: u8,
        }),
        /// offset: 0x0f
        reserved15: [5]u8,
        /// USART_INT Interrupt Enable Clear
        /// offset: 0x14
        INTENCLR: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Disable
            DRE: u1,
            /// Transmit Complete Interrupt Disable
            TXC: u1,
            /// Receive Complete Interrupt Disable
            RXC: u1,
            /// Receive Start Interrupt Disable
            RXS: u1,
            /// Clear To Send Input Change Interrupt Disable
            CTSIC: u1,
            /// Break Received Interrupt Disable
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt Disable
            ERROR: u1,
        }),
        /// offset: 0x15
        reserved21: [1]u8,
        /// USART_INT Interrupt Enable Set
        /// offset: 0x16
        INTENSET: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt Enable
            DRE: u1,
            /// Transmit Complete Interrupt Enable
            TXC: u1,
            /// Receive Complete Interrupt Enable
            RXC: u1,
            /// Receive Start Interrupt Enable
            RXS: u1,
            /// Clear To Send Input Change Interrupt Enable
            CTSIC: u1,
            /// Break Received Interrupt Enable
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt Enable
            ERROR: u1,
        }),
        /// offset: 0x17
        reserved23: [1]u8,
        /// USART_INT Interrupt Flag Status and Clear
        /// offset: 0x18
        INTFLAG: mmio.Mmio(packed struct(u8) {
            /// Data Register Empty Interrupt
            DRE: u1,
            /// Transmit Complete Interrupt
            TXC: u1,
            /// Receive Complete Interrupt
            RXC: u1,
            /// Receive Start Interrupt
            RXS: u1,
            /// Clear To Send Input Change Interrupt
            CTSIC: u1,
            /// Break Received Interrupt
            RXBRK: u1,
            reserved7: u1 = 0,
            /// Combined Error Interrupt
            ERROR: u1,
        }),
        /// offset: 0x19
        reserved25: [1]u8,
        /// USART_INT Status
        /// offset: 0x1a
        STATUS: mmio.Mmio(packed struct(u16) {
            /// Parity Error
            PERR: u1,
            /// Frame Error
            FERR: u1,
            /// Buffer Overflow
            BUFOVF: u1,
            /// Clear To Send
            CTS: u1,
            /// Inconsistent Sync Field
            ISF: u1,
            /// Collision Detected
            COLL: u1,
            /// Transmitter Empty
            TXE: u1,
            /// Maximum Number of Repetitions Reached
            ITER: u1,
            padding: u8 = 0,
        }),
        /// USART_INT Synchronization Busy
        /// offset: 0x1c
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Synchronization Busy
            SWRST: u1,
            /// SERCOM Enable Synchronization Busy
            ENABLE: u1,
            /// CTRLB Synchronization Busy
            CTRLB: u1,
            /// RXERRCNT Synchronization Busy
            RXERRCNT: u1,
            /// LENGTH Synchronization Busy
            LENGTH: u1,
            padding: u27 = 0,
        }),
        /// USART_INT Receive Error Count
        /// offset: 0x20
        RXERRCNT: u8,
        /// offset: 0x21
        reserved33: [1]u8,
        /// USART_INT Length
        /// offset: 0x22
        LENGTH: mmio.Mmio(packed struct(u16) {
            /// Data Length
            LEN: u8,
            /// Data Length Enable
            LENEN: u2,
            padding: u6 = 0,
        }),
        /// offset: 0x24
        reserved36: [4]u8,
        /// USART_INT Data
        /// offset: 0x28
        DATA: mmio.Mmio(packed struct(u32) {
            /// Data Value
            DATA: u32,
        }),
        /// offset: 0x2c
        reserved44: [4]u8,
        /// USART_INT Debug Control
        /// offset: 0x30
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Debug Mode
            DBGSTOP: u1,
            padding: u7 = 0,
        }),
    },
};
