const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const SDHC = extern struct {
    pub const SDHC_ACESR__ACMD12NE = enum(u1) {
        /// Executed
        EXEC = 0x0,
        /// Not executed
        NOT_EXEC = 0x1,
    };

    pub const SDHC_ACESR__ACMDCRC = enum(u1) {
        /// No error
        NO = 0x0,
        /// CRC Error Generated
        YES = 0x1,
    };

    pub const SDHC_ACESR__ACMDEND = enum(u1) {
        /// No error
        NO = 0x0,
        /// End Bit Error Generated
        YES = 0x1,
    };

    pub const SDHC_ACESR__ACMDIDX = enum(u1) {
        /// No error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_ACESR__ACMDTEO = enum(u1) {
        /// No error
        NO = 0x0,
        /// Timeout
        YES = 0x1,
    };

    pub const SDHC_ACESR__CMDNI = enum(u1) {
        /// No error
        OK = 0x0,
        /// Not Issued
        NOT_ISSUED = 0x1,
    };

    pub const SDHC_ACR__BMAX = enum(u2) {
        INCR16 = 0x0,
        INCR8 = 0x1,
        INCR4 = 0x2,
        SINGLE = 0x3,
    };

    pub const SDHC_AESR__ERRST = enum(u2) {
        /// ST_STOP (Stop DMA)
        STOP = 0x0,
        /// ST_FDS (Fetch Descriptor)
        FDS = 0x1,
        /// ST_TFR (Transfer Data)
        TFR = 0x3,
        _,
    };

    pub const SDHC_AESR__LMIS = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_BGCR__CONTR = enum(u1) {
        /// Not affected
        GO_ON = 0x0,
        /// Restart
        RESTART = 0x1,
    };

    pub const SDHC_BGCR__INTBG = enum(u1) {
        /// Disabled
        DISABLED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_BGCR__RWCTRL = enum(u1) {
        /// Disable Read Wait Control
        DISABLE = 0x0,
        /// Enable Read Wait Control
        ENABLE = 0x1,
    };

    pub const SDHC_BGCR__STPBGR = enum(u1) {
        /// Transfer
        TRANSFER = 0x0,
        /// Stop
        STOP = 0x1,
    };

    pub const SDHC_BSR__BOUNDARY = enum(u3) {
        /// 4k bytes
        @"4K" = 0x0,
        /// 8k bytes
        @"8K" = 0x1,
        /// 16k bytes
        @"16K" = 0x2,
        /// 32k bytes
        @"32K" = 0x3,
        /// 64k bytes
        @"64K" = 0x4,
        /// 128k bytes
        @"128K" = 0x5,
        /// 256k bytes
        @"256K" = 0x6,
        /// 512k bytes
        @"512K" = 0x7,
    };

    pub const SDHC_CA0R__ADMA2SUP = enum(u1) {
        /// ADMA2 not Supported
        NO = 0x0,
        /// ADMA2 Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__ASINTSUP = enum(u1) {
        /// Asynchronous Interrupt not Supported
        NO = 0x0,
        /// Asynchronous Interrupt supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__BASECLKF = enum(u8) {
        /// Get information via another method
        OTHER = 0x0,
        _,
    };

    pub const SDHC_CA0R__ED8SUP = enum(u1) {
        /// 8-bit Bus Width not Supported
        NO = 0x0,
        /// 8-bit Bus Width Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__HSSUP = enum(u1) {
        /// High Speed not Supported
        NO = 0x0,
        /// High Speed Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__MAXBLKL = enum(u2) {
        /// 512 bytes
        @"512" = 0x0,
        /// 1024 bytes
        @"1024" = 0x1,
        /// 2048 bytes
        @"2048" = 0x2,
        _,
    };

    pub const SDHC_CA0R__SB64SUP = enum(u1) {
        /// 32-bit Address Descriptors and System Bus
        NO = 0x0,
        /// 64-bit Address Descriptors and System Bus
        YES = 0x1,
    };

    pub const SDHC_CA0R__SDMASUP = enum(u1) {
        /// SDMA not Supported
        NO = 0x0,
        /// SDMA Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__SLTYPE = enum(u2) {
        /// Removable Card Slot
        REMOVABLE = 0x0,
        /// Embedded Slot for One Device
        EMBEDDED = 0x1,
        _,
    };

    pub const SDHC_CA0R__SRSUP = enum(u1) {
        /// Suspend/Resume not Supported
        NO = 0x0,
        /// Suspend/Resume Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__TEOCLKF = enum(u6) {
        /// Get information via another method
        OTHER = 0x0,
        _,
    };

    pub const SDHC_CA0R__TEOCLKU = enum(u1) {
        /// KHz
        KHZ = 0x0,
        /// MHz
        MHZ = 0x1,
    };

    pub const SDHC_CA0R__V18VSUP = enum(u1) {
        /// 1.8V Not Supported
        NO = 0x0,
        /// 1.8V Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__V30VSUP = enum(u1) {
        /// 3.0V Not Supported
        NO = 0x0,
        /// 3.0V Supported
        YES = 0x1,
    };

    pub const SDHC_CA0R__V33VSUP = enum(u1) {
        /// 3.3V Not Supported
        NO = 0x0,
        /// 3.3V Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__CLKMULT = enum(u8) {
        /// Clock Multiplier is Not Supported
        NO = 0x0,
        _,
    };

    pub const SDHC_CA1R__DDR50SUP = enum(u1) {
        /// DDR50 is Not Supported
        NO = 0x0,
        /// DDR50 is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__DRVASUP = enum(u1) {
        /// Driver Type A is Not Supported
        NO = 0x0,
        /// Driver Type A is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__DRVCSUP = enum(u1) {
        /// Driver Type C is Not Supported
        NO = 0x0,
        /// Driver Type C is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__DRVDSUP = enum(u1) {
        /// Driver Type D is Not Supported
        NO = 0x0,
        /// Driver Type D is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__SDR104SUP = enum(u1) {
        /// SDR104 is Not Supported
        NO = 0x0,
        /// SDR104 is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__SDR50SUP = enum(u1) {
        /// SDR50 is Not Supported
        NO = 0x0,
        /// SDR50 is Supported
        YES = 0x1,
    };

    pub const SDHC_CA1R__TCNTRT = enum(u4) {
        /// Re-Tuning Timer disabled
        DISABLED = 0x0,
        /// 1 second
        @"1S" = 0x1,
        /// 2 seconds
        @"2S" = 0x2,
        /// 4 seconds
        @"4S" = 0x3,
        /// 8 seconds
        @"8S" = 0x4,
        /// 16 seconds
        @"16S" = 0x5,
        /// 32 seconds
        @"32S" = 0x6,
        /// 64 seconds
        @"64S" = 0x7,
        /// 128 seconds
        @"128S" = 0x8,
        /// 256 seconds
        @"256S" = 0x9,
        /// 512 seconds
        @"512S" = 0xa,
        /// 1024 seconds
        @"1024S" = 0xb,
        /// Get information from other source
        OTHER = 0xf,
        _,
    };

    pub const SDHC_CA1R__TSDR50 = enum(u1) {
        /// SDR50 does not require tuning
        NO = 0x0,
        /// SDR50 requires tuning
        YES = 0x1,
    };

    pub const SDHC_CC2R__FSDCLKD = enum(u1) {
        /// No effect
        NOEFFECT = 0x0,
        /// SDCLK can be stopped at any time after DATA transfer.SDCLK enable forcing for 8 SDCLK cycles is disabled
        DISABLE = 0x1,
    };

    pub const SDHC_CCR__CLKGSEL = enum(u1) {
        /// Divided Clock Mode
        DIV = 0x0,
        /// Programmable Clock Mode
        PROG = 0x1,
    };

    pub const SDHC_CCR__INTCLKEN = enum(u1) {
        /// Stop
        OFF = 0x0,
        /// Oscillate
        ON = 0x1,
    };

    pub const SDHC_CCR__INTCLKS = enum(u1) {
        /// Not Ready
        NOT_READY = 0x0,
        /// Ready
        READY = 0x1,
    };

    pub const SDHC_CCR__SDCLKEN = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_CR__CMDCCEN = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_CR__CMDICEN = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_CR__CMDTYP = enum(u2) {
        /// Other commands
        NORMAL = 0x0,
        /// CMD52 for writing Bus Suspend in CCCR
        SUSPEND = 0x1,
        /// CMD52 for writing Function Select in CCCR
        RESUME = 0x2,
        /// CMD12, CMD52 for writing I/O Abort in CCCR
        ABORT = 0x3,
    };

    pub const SDHC_CR__DPSEL = enum(u1) {
        /// No Data Present
        NO_DATA = 0x0,
        /// Data Present
        DATA = 0x1,
    };

    pub const SDHC_CR__RESPTYP = enum(u2) {
        /// No response
        NONE = 0x0,
        /// 136-bit response
        @"136_BIT" = 0x1,
        /// 48-bit response
        @"48_BIT" = 0x2,
        /// 48-bit response check busy after response
        @"48_BIT_BUSY" = 0x3,
    };

    pub const SDHC_DBGR__NIDBG = enum(u1) {
        /// Debugging is intrusive (reads of BDPR from debugger are considered and increment the internal buffer pointer)
        IDBG = 0x0,
        /// Debugging is not intrusive (reads of BDPR from debugger are discarded and do not increment the internal buffer pointer)
        NIDBG = 0x1,
    };

    pub const SDHC_EISIER__ACMD = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__ADMA = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__CMDCRC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__CMDEND = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__CMDIDX = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__CMDTEO = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__CURLIM = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__DATCRC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__DATEND = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISIER__DATTEO = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__ACMD = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__ADMA = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__CMDCRC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__CMDEND = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__CMDIDX = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__CMDTEO = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__CURLIM = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__DATCRC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__DATEND = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTER__DATTEO = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_EISTR__ACMD = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_EISTR__ADMA = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_EISTR__BOOTAE = enum(u1) {
        /// FIFO contains at least one byte
        @"0" = 0x0,
        /// FIFO is empty
        @"1" = 0x1,
    };

    pub const SDHC_EISTR__CMDCRC = enum(u1) {
        /// No Error
        NO = 0x0,
        /// CRC Error Generated
        YES = 0x1,
    };

    pub const SDHC_EISTR__CMDEND = enum(u1) {
        /// No error
        NO = 0x0,
        /// End Bit Error Generated
        YES = 0x1,
    };

    pub const SDHC_EISTR__CMDIDX = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_EISTR__CMDTEO = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Timeout
        YES = 0x1,
    };

    pub const SDHC_EISTR__CURLIM = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Power Fail
        YES = 0x1,
    };

    pub const SDHC_EISTR__DATCRC = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_EISTR__DATEND = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_EISTR__DATTEO = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Timeout
        YES = 0x1,
    };

    pub const SDHC_FERACES__ACMD12NE = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FERACES__ACMDCRC = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FERACES__ACMDEND = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FERACES__ACMDIDX = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FERACES__ACMDTEO = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FERACES__CMDNI = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__ACMD = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__ADMA = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__BOOTAE = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__CMDCRC = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__CMDEND = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__CMDIDX = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__CMDTEO = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__CURLIM = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__DATCRC = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__DATEND = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_FEREIS__DATTEO = enum(u1) {
        /// No Interrupt
        NO = 0x0,
        /// Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_HC1R__CARDDSEL = enum(u1) {
        /// SDCD# is selected (for normal use)
        NORMAL = 0x0,
        /// The Card Select Test Level is selected (for test purpose)
        TEST = 0x1,
    };

    pub const SDHC_HC1R__CARDDTL = enum(u1) {
        /// No Card
        NO = 0x0,
        /// Card Inserted
        YES = 0x1,
    };

    pub const SDHC_HC1R__DMASEL = enum(u2) {
        /// SDMA is selected
        SDMA = 0x0,
        /// 32-bit Address ADMA2 is selected
        @"32BIT" = 0x2,
        _,
    };

    pub const SDHC_HC1R__DW = enum(u1) {
        /// 1-bit mode
        @"1BIT" = 0x0,
        /// 4-bit mode
        @"4BIT" = 0x1,
    };

    pub const SDHC_HC1R__HSEN = enum(u1) {
        /// Normal Speed mode
        NORMAL = 0x0,
        /// High Speed mode
        HIGH = 0x1,
    };

    pub const SDHC_HC1R__LEDCTRL = enum(u1) {
        /// LED off
        OFF = 0x0,
        /// LED on
        ON = 0x1,
    };

    pub const SDHC_HC2R__ASINTEN = enum(u1) {
        /// Disabled
        DISABLED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_HC2R__DRVSEL = enum(u2) {
        /// Driver Type B is Selected (Default)
        B = 0x0,
        /// Driver Type A is Selected
        A = 0x1,
        /// Driver Type C is Selected
        C = 0x2,
        /// Driver Type D is Selected
        D = 0x3,
    };

    pub const SDHC_HC2R__EXTUN = enum(u1) {
        /// Not Tuned or Tuning Completed
        NO = 0x0,
        /// Execute Tuning
        REQUESTED = 0x1,
    };

    pub const SDHC_HC2R__HS200EN = enum(u4) {
        /// SDR12
        SDR12 = 0x0,
        /// SDR25
        SDR25 = 0x1,
        /// SDR50
        SDR50 = 0x2,
        /// SDR104
        SDR104 = 0x3,
        /// DDR50
        DDR50 = 0x4,
        _,
    };

    pub const SDHC_HC2R__PVALEN = enum(u1) {
        /// SDCLK and Driver Strength are controlled by Host Controller
        HOST = 0x0,
        /// Automatic Selection by Preset Value is Enabled
        AUTO = 0x1,
    };

    pub const SDHC_HC2R__SLCKSEL = enum(u1) {
        /// Fixed clock is used to sample data
        FIXED = 0x0,
        /// Tuned clock is used to sample data
        TUNED = 0x1,
    };

    pub const SDHC_HC2R__UHSMS = enum(u3) {
        /// SDR12
        SDR12 = 0x0,
        /// SDR25
        SDR25 = 0x1,
        /// SDR50
        SDR50 = 0x2,
        /// SDR104
        SDR104 = 0x3,
        /// DDR50
        DDR50 = 0x4,
        _,
    };

    pub const SDHC_HC2R__VS18EN = enum(u1) {
        /// 3.3V Signaling
        S33V = 0x0,
        /// 1.8V Signaling
        S18V = 0x1,
    };

    pub const SDHC_MC1R__CMDTYP = enum(u2) {
        /// Not a MMC specific command
        NORMAL = 0x0,
        /// Wait IRQ Command
        WAITIRQ = 0x1,
        /// Stream Command
        STREAM = 0x2,
        /// Boot Command
        BOOT = 0x3,
    };

    pub const SDHC_MCCAR__MAXCUR18V = enum(u8) {
        /// Get information via another method
        OTHER = 0x0,
        /// 4mA
        @"4MA" = 0x1,
        /// 8mA
        @"8MA" = 0x2,
        /// 12mA
        @"12MA" = 0x3,
        _,
    };

    pub const SDHC_MCCAR__MAXCUR30V = enum(u8) {
        /// Get information via another method
        OTHER = 0x0,
        /// 4mA
        @"4MA" = 0x1,
        /// 8mA
        @"8MA" = 0x2,
        /// 12mA
        @"12MA" = 0x3,
        _,
    };

    pub const SDHC_MCCAR__MAXCUR33V = enum(u8) {
        /// Get information via another method
        OTHER = 0x0,
        /// 4mA
        @"4MA" = 0x1,
        /// 8mA
        @"8MA" = 0x2,
        /// 12mA
        @"12MA" = 0x3,
        _,
    };

    pub const SDHC_NISIER__BLKGE = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__BRDRDY = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__BWRRDY = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__CINS = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__CINT = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__CMDC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__CREM = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__DMAINT = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISIER__TRFC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__BLKGE = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__BRDRDY = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__BWRRDY = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__CINS = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__CINT = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__CMDC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__CREM = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__DMAINT = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTER__TRFC = enum(u1) {
        /// Masked
        MASKED = 0x0,
        /// Enabled
        ENABLED = 0x1,
    };

    pub const SDHC_NISTR__BLKGE = enum(u1) {
        /// No Block Gap Event
        NO = 0x0,
        /// Transaction stopped at block gap
        STOP = 0x1,
    };

    pub const SDHC_NISTR__BRDRDY = enum(u1) {
        /// Not ready to read buffer
        NO = 0x0,
        /// Ready to read buffer
        YES = 0x1,
    };

    pub const SDHC_NISTR__BWRRDY = enum(u1) {
        /// Not ready to write buffer
        NO = 0x0,
        /// Ready to write buffer
        YES = 0x1,
    };

    pub const SDHC_NISTR__CINS = enum(u1) {
        /// Card state stable or Debouncing
        NO = 0x0,
        /// Card inserted
        YES = 0x1,
    };

    pub const SDHC_NISTR__CINT = enum(u1) {
        /// No Card Interrupt
        NO = 0x0,
        /// Generate Card Interrupt
        YES = 0x1,
    };

    pub const SDHC_NISTR__CMDC = enum(u1) {
        /// No command complete
        NO = 0x0,
        /// Command complete
        YES = 0x1,
    };

    pub const SDHC_NISTR__CREM = enum(u1) {
        /// Card state stable or Debouncing
        NO = 0x0,
        /// Card Removed
        YES = 0x1,
    };

    pub const SDHC_NISTR__DMAINT = enum(u1) {
        /// No DMA Interrupt
        NO = 0x0,
        /// DMA Interrupt is generated
        YES = 0x1,
    };

    pub const SDHC_NISTR__ERRINT = enum(u1) {
        /// No Error
        NO = 0x0,
        /// Error
        YES = 0x1,
    };

    pub const SDHC_NISTR__TRFC = enum(u1) {
        /// Not complete
        NO = 0x0,
        /// Command execution is completed
        YES = 0x1,
    };

    pub const SDHC_PCR__SDBPWR = enum(u1) {
        /// Power off
        OFF = 0x0,
        /// Power on
        ON = 0x1,
    };

    pub const SDHC_PCR__SDBVSEL = enum(u3) {
        /// 1.8V (Typ.)
        @"1V8" = 0x5,
        /// 3.0V (Typ.)
        @"3V0" = 0x6,
        /// 3.3V (Typ.)
        @"3V3" = 0x7,
        _,
    };

    pub const SDHC_PSR__BUFRDEN = enum(u1) {
        /// Read disable
        DISABLE = 0x0,
        /// Read enable
        ENABLE = 0x1,
    };

    pub const SDHC_PSR__BUFWREN = enum(u1) {
        /// Write disable
        DISABLE = 0x0,
        /// Write enable
        ENABLE = 0x1,
    };

    pub const SDHC_PSR__CARDDPL = enum(u1) {
        /// No card present (SDCD#=1)
        NO = 0x0,
        /// Card present (SDCD#=0)
        YES = 0x1,
    };

    pub const SDHC_PSR__CARDINS = enum(u1) {
        /// Reset or Debouncing or No Card
        NO = 0x0,
        /// Card inserted
        YES = 0x1,
    };

    pub const SDHC_PSR__CARDSS = enum(u1) {
        /// Reset or Debouncing
        NO = 0x0,
        /// No Card or Insered
        YES = 0x1,
    };

    pub const SDHC_PSR__CMDINHC = enum(u1) {
        /// Can issue command using only CMD line
        CAN = 0x0,
        /// Cannot issue command
        CANNOT = 0x1,
    };

    pub const SDHC_PSR__CMDINHD = enum(u1) {
        /// Can issue command which uses the DAT line
        CAN = 0x0,
        /// Cannot issue command which uses the DAT line
        CANNOT = 0x1,
    };

    pub const SDHC_PSR__DLACT = enum(u1) {
        /// DAT Line Inactive
        INACTIVE = 0x0,
        /// DAT Line Active
        ACTIVE = 0x1,
    };

    pub const SDHC_PSR__RTACT = enum(u1) {
        /// No valid data
        NO = 0x0,
        /// Transferring data
        YES = 0x1,
    };

    pub const SDHC_PSR__RTREQ = enum(u1) {
        /// Fixed or well-tuned sampling clock
        OK = 0x0,
        /// Sampling clock needs re-tuning
        REQUIRED = 0x1,
    };

    pub const SDHC_PSR__WRPPL = enum(u1) {
        /// Write protected (SDWP#=0)
        PROTECTED = 0x0,
        /// Write enabled (SDWP#=1)
        ENABLED = 0x1,
    };

    pub const SDHC_PSR__WTACT = enum(u1) {
        /// No valid data
        NO = 0x0,
        /// Transferring data
        YES = 0x1,
    };

    pub const SDHC_PVR__CLKGSEL = enum(u1) {
        /// Host Controller Ver2.00 Compatible Clock Generator (Divider)
        DIV = 0x0,
        /// Programmable Clock Generator
        PROG = 0x1,
    };

    pub const SDHC_PVR__DRVSEL = enum(u2) {
        /// Driver Type B is Selected
        B = 0x0,
        /// Driver Type A is Selected
        A = 0x1,
        /// Driver Type C is Selected
        C = 0x2,
        /// Driver Type D is Selected
        D = 0x3,
    };

    pub const SDHC_SRR__SWRSTALL = enum(u1) {
        /// Work
        WORK = 0x0,
        /// Reset
        RESET = 0x1,
    };

    pub const SDHC_SRR__SWRSTCMD = enum(u1) {
        /// Work
        WORK = 0x0,
        /// Reset
        RESET = 0x1,
    };

    pub const SDHC_SRR__SWRSTDAT = enum(u1) {
        /// Work
        WORK = 0x0,
        /// Reset
        RESET = 0x1,
    };

    pub const SDHC_TMR__ACMDEN = enum(u2) {
        /// Auto Command Disabled
        DISABLED = 0x0,
        /// Auto CMD12 Enable
        CMD12 = 0x1,
        /// Auto CMD23 Enable
        CMD23 = 0x2,
        _,
    };

    pub const SDHC_TMR__BCEN = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_TMR__DMAEN = enum(u1) {
        /// No data transfer or Non DMA data transfer
        DISABLE = 0x0,
        /// DMA data transfer
        ENABLE = 0x1,
    };

    pub const SDHC_TMR__DTDSEL = enum(u1) {
        /// Write (Host to Card)
        WRITE = 0x0,
        /// Read (Card to Host)
        READ = 0x1,
    };

    pub const SDHC_TMR__MSBSEL = enum(u1) {
        /// Single Block
        SINGLE = 0x0,
        /// Multiple Block
        MULTIPLE = 0x1,
    };

    pub const SDHC_WCR__WKENCINS = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_WCR__WKENCINT = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    pub const SDHC_WCR__WKENCREM = enum(u1) {
        /// Disable
        DISABLE = 0x0,
        /// Enable
        ENABLE = 0x1,
    };

    /// SDMA System Address / Argument 2
    /// offset: 0x00
    SSAR: mmio.Mmio(packed struct(u32) {
        /// SDMA System Address
        ADDR: u32,
    }),
    /// Block Size
    /// offset: 0x04
    BSR: mmio.Mmio(packed struct(u16) {
        /// Transfer Block Size
        BLOCKSIZE: u10,
        reserved12: u2 = 0,
        /// SDMA Buffer Boundary
        BOUNDARY: SDHC_BSR__BOUNDARY,
        padding: u1 = 0,
    }),
    /// Block Count
    /// offset: 0x06
    BCR: mmio.Mmio(packed struct(u16) {
        /// Blocks Count for Current Transfer
        BCNT: u16,
    }),
    /// Argument 1
    /// offset: 0x08
    ARG1R: mmio.Mmio(packed struct(u32) {
        /// Argument 1
        ARG: u32,
    }),
    /// Transfer Mode
    /// offset: 0x0c
    TMR: mmio.Mmio(packed struct(u16) {
        /// DMA Enable
        DMAEN: SDHC_TMR__DMAEN,
        /// Block Count Enable
        BCEN: SDHC_TMR__BCEN,
        /// Auto Command Enable
        ACMDEN: SDHC_TMR__ACMDEN,
        /// Data Transfer Direction Selection
        DTDSEL: SDHC_TMR__DTDSEL,
        /// Multi/Single Block Selection
        MSBSEL: SDHC_TMR__MSBSEL,
        padding: u10 = 0,
    }),
    /// Command
    /// offset: 0x0e
    CR: mmio.Mmio(packed struct(u16) {
        /// Response Type
        RESPTYP: SDHC_CR__RESPTYP,
        reserved3: u1 = 0,
        /// Command CRC Check Enable
        CMDCCEN: SDHC_CR__CMDCCEN,
        /// Command Index Check Enable
        CMDICEN: SDHC_CR__CMDICEN,
        /// Data Present Select
        DPSEL: SDHC_CR__DPSEL,
        /// Command Type
        CMDTYP: SDHC_CR__CMDTYP,
        /// Command Index
        CMDIDX: u6,
        padding: u2 = 0,
    }),
    /// Response
    /// offset: 0x10
    RR: [4]mmio.Mmio(packed struct(u32) {
        /// Command Response
        CMDRESP: u32,
    }),
    /// Buffer Data Port
    /// offset: 0x20
    BDPR: mmio.Mmio(packed struct(u32) {
        /// Buffer Data
        BUFDATA: u32,
    }),
    /// Present State
    /// offset: 0x24
    PSR: mmio.Mmio(packed struct(u32) {
        /// Command Inhibit (CMD)
        CMDINHC: SDHC_PSR__CMDINHC,
        /// Command Inhibit (DAT)
        CMDINHD: SDHC_PSR__CMDINHD,
        /// DAT Line Active
        DLACT: SDHC_PSR__DLACT,
        /// Re-Tuning Request
        RTREQ: SDHC_PSR__RTREQ,
        reserved8: u4 = 0,
        /// Write Transfer Active
        WTACT: SDHC_PSR__WTACT,
        /// Read Transfer Active
        RTACT: SDHC_PSR__RTACT,
        /// Buffer Write Enable
        BUFWREN: SDHC_PSR__BUFWREN,
        /// Buffer Read Enable
        BUFRDEN: SDHC_PSR__BUFRDEN,
        reserved16: u4 = 0,
        /// Card Inserted
        CARDINS: SDHC_PSR__CARDINS,
        /// Card State Stable
        CARDSS: SDHC_PSR__CARDSS,
        /// Card Detect Pin Level
        CARDDPL: SDHC_PSR__CARDDPL,
        /// Write Protect Pin Level
        WRPPL: SDHC_PSR__WRPPL,
        /// DAT[3:0] Line Level
        DATLL: u4,
        /// CMD Line Level
        CMDLL: u1,
        padding: u7 = 0,
    }),
    /// Host Control 1
    /// offset: 0x28
    HC1R: mmio.Mmio(packed struct(u8) {
        /// LED Control
        LEDCTRL: SDHC_HC1R__LEDCTRL,
        /// Data Width
        DW: SDHC_HC1R__DW,
        /// High Speed Enable
        HSEN: SDHC_HC1R__HSEN,
        /// DMA Select
        DMASEL: SDHC_HC1R__DMASEL,
        reserved6: u1 = 0,
        /// Card Detect Test Level
        CARDDTL: SDHC_HC1R__CARDDTL,
        /// Card Detect Signal Selection
        CARDDSEL: SDHC_HC1R__CARDDSEL,
    }),
    /// Power Control
    /// offset: 0x29
    PCR: mmio.Mmio(packed struct(u8) {
        /// SD Bus Power
        SDBPWR: SDHC_PCR__SDBPWR,
        /// SD Bus Voltage Select
        SDBVSEL: SDHC_PCR__SDBVSEL,
        padding: u4 = 0,
    }),
    /// Block Gap Control
    /// offset: 0x2a
    BGCR: mmio.Mmio(packed struct(u8) {
        /// Stop at Block Gap Request
        STPBGR: SDHC_BGCR__STPBGR,
        /// Continue Request
        CONTR: SDHC_BGCR__CONTR,
        /// Read Wait Control
        RWCTRL: SDHC_BGCR__RWCTRL,
        /// Interrupt at Block Gap
        INTBG: SDHC_BGCR__INTBG,
        padding: u4 = 0,
    }),
    /// Wakeup Control
    /// offset: 0x2b
    WCR: mmio.Mmio(packed struct(u8) {
        /// Wakeup Event Enable on Card Interrupt
        WKENCINT: SDHC_WCR__WKENCINT,
        /// Wakeup Event Enable on Card Insertion
        WKENCINS: SDHC_WCR__WKENCINS,
        /// Wakeup Event Enable on Card Removal
        WKENCREM: SDHC_WCR__WKENCREM,
        padding: u5 = 0,
    }),
    /// Clock Control
    /// offset: 0x2c
    CCR: mmio.Mmio(packed struct(u16) {
        /// Internal Clock Enable
        INTCLKEN: SDHC_CCR__INTCLKEN,
        /// Internal Clock Stable
        INTCLKS: SDHC_CCR__INTCLKS,
        /// SD Clock Enable
        SDCLKEN: SDHC_CCR__SDCLKEN,
        reserved5: u2 = 0,
        /// Clock Generator Select
        CLKGSEL: SDHC_CCR__CLKGSEL,
        /// Upper Bits of SDCLK Frequency Select
        USDCLKFSEL: u2,
        /// SDCLK Frequency Select
        SDCLKFSEL: u8,
    }),
    /// Timeout Control
    /// offset: 0x2e
    TCR: mmio.Mmio(packed struct(u8) {
        /// Data Timeout Counter Value
        DTCVAL: u4,
        padding: u4 = 0,
    }),
    /// Software Reset
    /// offset: 0x2f
    SRR: mmio.Mmio(packed struct(u8) {
        /// Software Reset For All
        SWRSTALL: SDHC_SRR__SWRSTALL,
        /// Software Reset For CMD Line
        SWRSTCMD: SDHC_SRR__SWRSTCMD,
        /// Software Reset For DAT Line
        SWRSTDAT: SDHC_SRR__SWRSTDAT,
        padding: u5 = 0,
    }),
    /// Normal Interrupt Status
    /// offset: 0x30
    NISTR: mmio.Mmio(packed struct(u16) {
        /// Command Complete
        CMDC: SDHC_NISTR__CMDC,
        /// Transfer Complete
        TRFC: SDHC_NISTR__TRFC,
        /// Block Gap Event
        BLKGE: SDHC_NISTR__BLKGE,
        /// DMA Interrupt
        DMAINT: SDHC_NISTR__DMAINT,
        /// Buffer Write Ready
        BWRRDY: SDHC_NISTR__BWRRDY,
        /// Buffer Read Ready
        BRDRDY: SDHC_NISTR__BRDRDY,
        /// Card Insertion
        CINS: SDHC_NISTR__CINS,
        /// Card Removal
        CREM: SDHC_NISTR__CREM,
        /// Card Interrupt
        CINT: SDHC_NISTR__CINT,
        reserved14: u5 = 0,
        /// Boot Acknowledge Received
        BOOTAR: u1,
        /// Error Interrupt
        ERRINT: SDHC_NISTR__ERRINT,
    }),
    /// Error Interrupt Status
    /// offset: 0x32
    EISTR: mmio.Mmio(packed struct(u16) {
        /// Command Timeout Error
        CMDTEO: SDHC_EISTR__CMDTEO,
        /// Command CRC Error
        CMDCRC: SDHC_EISTR__CMDCRC,
        /// Command End Bit Error
        CMDEND: SDHC_EISTR__CMDEND,
        /// Command Index Error
        CMDIDX: SDHC_EISTR__CMDIDX,
        /// Data Timeout Error
        DATTEO: SDHC_EISTR__DATTEO,
        /// Data CRC Error
        DATCRC: SDHC_EISTR__DATCRC,
        /// Data End Bit Error
        DATEND: SDHC_EISTR__DATEND,
        /// Current Limit Error
        CURLIM: SDHC_EISTR__CURLIM,
        /// Auto CMD Error
        ACMD: SDHC_EISTR__ACMD,
        /// ADMA Error
        ADMA: SDHC_EISTR__ADMA,
        reserved12: u2 = 0,
        /// Boot Acknowledge Error
        BOOTAE: SDHC_EISTR__BOOTAE,
        padding: u3 = 0,
    }),
    /// Normal Interrupt Status Enable
    /// offset: 0x34
    NISTER: mmio.Mmio(packed struct(u16) {
        /// Command Complete Status Enable
        CMDC: SDHC_NISTER__CMDC,
        /// Transfer Complete Status Enable
        TRFC: SDHC_NISTER__TRFC,
        /// Block Gap Event Status Enable
        BLKGE: SDHC_NISTER__BLKGE,
        /// DMA Interrupt Status Enable
        DMAINT: SDHC_NISTER__DMAINT,
        /// Buffer Write Ready Status Enable
        BWRRDY: SDHC_NISTER__BWRRDY,
        /// Buffer Read Ready Status Enable
        BRDRDY: SDHC_NISTER__BRDRDY,
        /// Card Insertion Status Enable
        CINS: SDHC_NISTER__CINS,
        /// Card Removal Status Enable
        CREM: SDHC_NISTER__CREM,
        /// Card Interrupt Status Enable
        CINT: SDHC_NISTER__CINT,
        reserved14: u5 = 0,
        /// Boot Acknowledge Received Status Enable
        BOOTAR: u1,
        padding: u1 = 0,
    }),
    /// Error Interrupt Status Enable
    /// offset: 0x36
    EISTER: mmio.Mmio(packed struct(u16) {
        /// Command Timeout Error Status Enable
        CMDTEO: SDHC_EISTER__CMDTEO,
        /// Command CRC Error Status Enable
        CMDCRC: SDHC_EISTER__CMDCRC,
        /// Command End Bit Error Status Enable
        CMDEND: SDHC_EISTER__CMDEND,
        /// Command Index Error Status Enable
        CMDIDX: SDHC_EISTER__CMDIDX,
        /// Data Timeout Error Status Enable
        DATTEO: SDHC_EISTER__DATTEO,
        /// Data CRC Error Status Enable
        DATCRC: SDHC_EISTER__DATCRC,
        /// Data End Bit Error Status Enable
        DATEND: SDHC_EISTER__DATEND,
        /// Current Limit Error Status Enable
        CURLIM: SDHC_EISTER__CURLIM,
        /// Auto CMD Error Status Enable
        ACMD: SDHC_EISTER__ACMD,
        /// ADMA Error Status Enable
        ADMA: SDHC_EISTER__ADMA,
        reserved12: u2 = 0,
        /// Boot Acknowledge Error Status Enable
        BOOTAE: u1,
        padding: u3 = 0,
    }),
    /// Normal Interrupt Signal Enable
    /// offset: 0x38
    NISIER: mmio.Mmio(packed struct(u16) {
        /// Command Complete Signal Enable
        CMDC: SDHC_NISIER__CMDC,
        /// Transfer Complete Signal Enable
        TRFC: SDHC_NISIER__TRFC,
        /// Block Gap Event Signal Enable
        BLKGE: SDHC_NISIER__BLKGE,
        /// DMA Interrupt Signal Enable
        DMAINT: SDHC_NISIER__DMAINT,
        /// Buffer Write Ready Signal Enable
        BWRRDY: SDHC_NISIER__BWRRDY,
        /// Buffer Read Ready Signal Enable
        BRDRDY: SDHC_NISIER__BRDRDY,
        /// Card Insertion Signal Enable
        CINS: SDHC_NISIER__CINS,
        /// Card Removal Signal Enable
        CREM: SDHC_NISIER__CREM,
        /// Card Interrupt Signal Enable
        CINT: SDHC_NISIER__CINT,
        reserved14: u5 = 0,
        /// Boot Acknowledge Received Signal Enable
        BOOTAR: u1,
        padding: u1 = 0,
    }),
    /// Error Interrupt Signal Enable
    /// offset: 0x3a
    EISIER: mmio.Mmio(packed struct(u16) {
        /// Command Timeout Error Signal Enable
        CMDTEO: SDHC_EISIER__CMDTEO,
        /// Command CRC Error Signal Enable
        CMDCRC: SDHC_EISIER__CMDCRC,
        /// Command End Bit Error Signal Enable
        CMDEND: SDHC_EISIER__CMDEND,
        /// Command Index Error Signal Enable
        CMDIDX: SDHC_EISIER__CMDIDX,
        /// Data Timeout Error Signal Enable
        DATTEO: SDHC_EISIER__DATTEO,
        /// Data CRC Error Signal Enable
        DATCRC: SDHC_EISIER__DATCRC,
        /// Data End Bit Error Signal Enable
        DATEND: SDHC_EISIER__DATEND,
        /// Current Limit Error Signal Enable
        CURLIM: SDHC_EISIER__CURLIM,
        /// Auto CMD Error Signal Enable
        ACMD: SDHC_EISIER__ACMD,
        /// ADMA Error Signal Enable
        ADMA: SDHC_EISIER__ADMA,
        reserved12: u2 = 0,
        /// Boot Acknowledge Error Signal Enable
        BOOTAE: u1,
        padding: u3 = 0,
    }),
    /// Auto CMD Error Status
    /// offset: 0x3c
    ACESR: mmio.Mmio(packed struct(u16) {
        /// Auto CMD12 Not Executed
        ACMD12NE: SDHC_ACESR__ACMD12NE,
        /// Auto CMD Timeout Error
        ACMDTEO: SDHC_ACESR__ACMDTEO,
        /// Auto CMD CRC Error
        ACMDCRC: SDHC_ACESR__ACMDCRC,
        /// Auto CMD End Bit Error
        ACMDEND: SDHC_ACESR__ACMDEND,
        /// Auto CMD Index Error
        ACMDIDX: SDHC_ACESR__ACMDIDX,
        reserved7: u2 = 0,
        /// Command not Issued By Auto CMD12 Error
        CMDNI: SDHC_ACESR__CMDNI,
        padding: u8 = 0,
    }),
    /// Host Control 2
    /// offset: 0x3e
    HC2R: mmio.Mmio(packed struct(u16) {
        /// UHS Mode Select
        UHSMS: SDHC_HC2R__UHSMS,
        /// 1.8V Signaling Enable
        VS18EN: SDHC_HC2R__VS18EN,
        /// Driver Strength Select
        DRVSEL: SDHC_HC2R__DRVSEL,
        /// Execute Tuning
        EXTUN: SDHC_HC2R__EXTUN,
        /// Sampling Clock Select
        SLCKSEL: SDHC_HC2R__SLCKSEL,
        reserved14: u6 = 0,
        /// Asynchronous Interrupt Enable
        ASINTEN: SDHC_HC2R__ASINTEN,
        /// Preset Value Enable
        PVALEN: SDHC_HC2R__PVALEN,
    }),
    /// Capabilities 0
    /// offset: 0x40
    CA0R: mmio.Mmio(packed struct(u32) {
        /// Timeout Clock Frequency
        TEOCLKF: SDHC_CA0R__TEOCLKF,
        reserved7: u1 = 0,
        /// Timeout Clock Unit
        TEOCLKU: SDHC_CA0R__TEOCLKU,
        /// Base Clock Frequency
        BASECLKF: SDHC_CA0R__BASECLKF,
        /// Max Block Length
        MAXBLKL: SDHC_CA0R__MAXBLKL,
        /// 8-bit Support for Embedded Device
        ED8SUP: SDHC_CA0R__ED8SUP,
        /// ADMA2 Support
        ADMA2SUP: SDHC_CA0R__ADMA2SUP,
        reserved21: u1 = 0,
        /// High Speed Support
        HSSUP: SDHC_CA0R__HSSUP,
        /// SDMA Support
        SDMASUP: SDHC_CA0R__SDMASUP,
        /// Suspend/Resume Support
        SRSUP: SDHC_CA0R__SRSUP,
        /// Voltage Support 3.3V
        V33VSUP: SDHC_CA0R__V33VSUP,
        /// Voltage Support 3.0V
        V30VSUP: SDHC_CA0R__V30VSUP,
        /// Voltage Support 1.8V
        V18VSUP: SDHC_CA0R__V18VSUP,
        reserved28: u1 = 0,
        /// 64-Bit System Bus Support
        SB64SUP: SDHC_CA0R__SB64SUP,
        /// Asynchronous Interrupt Support
        ASINTSUP: SDHC_CA0R__ASINTSUP,
        /// Slot Type
        SLTYPE: SDHC_CA0R__SLTYPE,
    }),
    /// Capabilities 1
    /// offset: 0x44
    CA1R: mmio.Mmio(packed struct(u32) {
        /// SDR50 Support
        SDR50SUP: SDHC_CA1R__SDR50SUP,
        /// SDR104 Support
        SDR104SUP: SDHC_CA1R__SDR104SUP,
        /// DDR50 Support
        DDR50SUP: SDHC_CA1R__DDR50SUP,
        reserved4: u1 = 0,
        /// Driver Type A Support
        DRVASUP: SDHC_CA1R__DRVASUP,
        /// Driver Type C Support
        DRVCSUP: SDHC_CA1R__DRVCSUP,
        /// Driver Type D Support
        DRVDSUP: SDHC_CA1R__DRVDSUP,
        reserved8: u1 = 0,
        /// Timer Count for Re-Tuning
        TCNTRT: SDHC_CA1R__TCNTRT,
        reserved13: u1 = 0,
        /// Use Tuning for SDR50
        TSDR50: SDHC_CA1R__TSDR50,
        reserved16: u2 = 0,
        /// Clock Multiplier
        CLKMULT: SDHC_CA1R__CLKMULT,
        padding: u8 = 0,
    }),
    /// Maximum Current Capabilities
    /// offset: 0x48
    MCCAR: mmio.Mmio(packed struct(u32) {
        /// Maximum Current for 3.3V
        MAXCUR33V: SDHC_MCCAR__MAXCUR33V,
        /// Maximum Current for 3.0V
        MAXCUR30V: SDHC_MCCAR__MAXCUR30V,
        /// Maximum Current for 1.8V
        MAXCUR18V: SDHC_MCCAR__MAXCUR18V,
        padding: u8 = 0,
    }),
    /// offset: 0x4c
    reserved76: [4]u8,
    /// Force Event for Auto CMD Error Status
    /// offset: 0x50
    FERACES: mmio.Mmio(packed struct(u16) {
        /// Force Event for Auto CMD12 Not Executed
        ACMD12NE: SDHC_FERACES__ACMD12NE,
        /// Force Event for Auto CMD Timeout Error
        ACMDTEO: SDHC_FERACES__ACMDTEO,
        /// Force Event for Auto CMD CRC Error
        ACMDCRC: SDHC_FERACES__ACMDCRC,
        /// Force Event for Auto CMD End Bit Error
        ACMDEND: SDHC_FERACES__ACMDEND,
        /// Force Event for Auto CMD Index Error
        ACMDIDX: SDHC_FERACES__ACMDIDX,
        reserved7: u2 = 0,
        /// Force Event for Command Not Issued By Auto CMD12 Error
        CMDNI: SDHC_FERACES__CMDNI,
        padding: u8 = 0,
    }),
    /// Force Event for Error Interrupt Status
    /// offset: 0x52
    FEREIS: mmio.Mmio(packed struct(u16) {
        /// Force Event for Command Timeout Error
        CMDTEO: SDHC_FEREIS__CMDTEO,
        /// Force Event for Command CRC Error
        CMDCRC: SDHC_FEREIS__CMDCRC,
        /// Force Event for Command End Bit Error
        CMDEND: SDHC_FEREIS__CMDEND,
        /// Force Event for Command Index Error
        CMDIDX: SDHC_FEREIS__CMDIDX,
        /// Force Event for Data Timeout Error
        DATTEO: SDHC_FEREIS__DATTEO,
        /// Force Event for Data CRC Error
        DATCRC: SDHC_FEREIS__DATCRC,
        /// Force Event for Data End Bit Error
        DATEND: SDHC_FEREIS__DATEND,
        /// Force Event for Current Limit Error
        CURLIM: SDHC_FEREIS__CURLIM,
        /// Force Event for Auto CMD Error
        ACMD: SDHC_FEREIS__ACMD,
        /// Force Event for ADMA Error
        ADMA: SDHC_FEREIS__ADMA,
        reserved12: u2 = 0,
        /// Force Event for Boot Acknowledge Error
        BOOTAE: SDHC_FEREIS__BOOTAE,
        padding: u3 = 0,
    }),
    /// ADMA Error Status
    /// offset: 0x54
    AESR: mmio.Mmio(packed struct(u8) {
        /// ADMA Error State
        ERRST: SDHC_AESR__ERRST,
        /// ADMA Length Mismatch Error
        LMIS: SDHC_AESR__LMIS,
        padding: u5 = 0,
    }),
    /// offset: 0x55
    reserved85: [3]u8,
    /// ADMA System Address n
    /// offset: 0x58
    ASAR: [1]mmio.Mmio(packed struct(u32) {
        /// ADMA System Address
        ADMASA: u32,
    }),
    /// offset: 0x5c
    reserved92: [4]u8,
    /// Preset Value n
    /// offset: 0x60
    PVR: [8]mmio.Mmio(packed struct(u16) {
        /// SDCLK Frequency Select Value for Initialization
        SDCLKFSEL: u10,
        /// Clock Generator Select Value for Initialization
        CLKGSEL: SDHC_PVR__CLKGSEL,
        reserved14: u3 = 0,
        /// Driver Strength Select Value for Initialization
        DRVSEL: SDHC_PVR__DRVSEL,
    }),
    /// offset: 0x70
    reserved112: [140]u8,
    /// Slot Interrupt Status
    /// offset: 0xfc
    SISR: mmio.Mmio(packed struct(u16) {
        /// Interrupt Signal for Each Slot
        INTSSL: u1,
        padding: u15 = 0,
    }),
    /// Host Controller Version
    /// offset: 0xfe
    HCVR: mmio.Mmio(packed struct(u16) {
        /// Spec Version
        SVER: u8,
        /// Vendor Version
        VVER: u8,
    }),
    /// offset: 0x100
    reserved256: [260]u8,
    /// MMC Control 1
    /// offset: 0x204
    MC1R: mmio.Mmio(packed struct(u8) {
        /// e.MMC Command Type
        CMDTYP: SDHC_MC1R__CMDTYP,
        reserved3: u1 = 0,
        /// e.MMC HSDDR Mode
        DDR: u1,
        /// e.MMC Open Drain Mode
        OPD: u1,
        /// e.MMC Boot Acknowledge Enable
        BOOTA: u1,
        /// e.MMC Reset Signal
        RSTN: u1,
        /// e.MMC Force Card Detect
        FCD: u1,
    }),
    /// MMC Control 2
    /// offset: 0x205
    MC2R: mmio.Mmio(packed struct(u8) {
        /// e.MMC Abort Wait IRQ
        SRESP: u1,
        /// e.MMC Abort Boot
        ABOOT: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x206
    reserved518: [2]u8,
    /// AHB Control
    /// offset: 0x208
    ACR: mmio.Mmio(packed struct(u32) {
        /// AHB Maximum Burst
        BMAX: SDHC_ACR__BMAX,
        padding: u30 = 0,
    }),
    /// Clock Control 2
    /// offset: 0x20c
    CC2R: mmio.Mmio(packed struct(u32) {
        /// Force SDCK Disabled
        FSDCLKD: SDHC_CC2R__FSDCLKD,
        padding: u31 = 0,
    }),
    /// offset: 0x210
    reserved528: [32]u8,
    /// Capabilities Control
    /// offset: 0x230
    CACR: mmio.Mmio(packed struct(u32) {
        /// Capabilities Registers Write Enable (Required to write the correct frequencies in the Capabilities Registers)
        CAPWREN: u1,
        reserved8: u7 = 0,
        /// Key (0x46)
        KEY: u8,
        padding: u16 = 0,
    }),
    /// Debug
    /// offset: 0x234
    DBGR: mmio.Mmio(packed struct(u8) {
        /// Non-intrusive debug enable
        NIDBG: SDHC_DBGR__NIDBG,
        padding: u7 = 0,
    }),
};
