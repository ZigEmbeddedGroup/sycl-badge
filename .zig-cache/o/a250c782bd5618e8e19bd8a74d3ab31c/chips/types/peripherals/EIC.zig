const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const EIC = extern struct {
    pub const EIC_ASYNCH__ASYNCH = enum(u16) {
        /// Edge detection is clock synchronously operated
        SYNC = 0x0,
        /// Edge detection is clock asynchronously operated
        ASYNC = 0x1,
        _,
    };

    pub const EIC_CONFIG__SENSE0 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE1 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE2 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE3 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE4 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE5 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE6 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CONFIG__SENSE7 = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising edge detection
        RISE = 0x1,
        /// Falling edge detection
        FALL = 0x2,
        /// Both edges detection
        BOTH = 0x3,
        /// High level detection
        HIGH = 0x4,
        /// Low level detection
        LOW = 0x5,
        _,
    };

    pub const EIC_CTRLA__CKSEL = enum(u1) {
        /// Clocked by GCLK
        CLK_GCLK = 0x0,
        /// Clocked by ULP32K
        CLK_ULP32K = 0x1,
    };

    pub const EIC_DPRESCALER__PRESCALER0 = enum(u3) {
        /// EIC clock divided by 2
        DIV2 = 0x0,
        /// EIC clock divided by 4
        DIV4 = 0x1,
        /// EIC clock divided by 8
        DIV8 = 0x2,
        /// EIC clock divided by 16
        DIV16 = 0x3,
        /// EIC clock divided by 32
        DIV32 = 0x4,
        /// EIC clock divided by 64
        DIV64 = 0x5,
        /// EIC clock divided by 128
        DIV128 = 0x6,
        /// EIC clock divided by 256
        DIV256 = 0x7,
    };

    pub const EIC_DPRESCALER__PRESCALER1 = enum(u3) {
        /// EIC clock divided by 2
        DIV2 = 0x0,
        /// EIC clock divided by 4
        DIV4 = 0x1,
        /// EIC clock divided by 8
        DIV8 = 0x2,
        /// EIC clock divided by 16
        DIV16 = 0x3,
        /// EIC clock divided by 32
        DIV32 = 0x4,
        /// EIC clock divided by 64
        DIV64 = 0x5,
        /// EIC clock divided by 128
        DIV128 = 0x6,
        /// EIC clock divided by 256
        DIV256 = 0x7,
    };

    pub const EIC_DPRESCALER__STATES0 = enum(u1) {
        /// 3 low frequency samples
        LFREQ3 = 0x0,
        /// 7 low frequency samples
        LFREQ7 = 0x1,
    };

    pub const EIC_DPRESCALER__STATES1 = enum(u1) {
        /// 3 low frequency samples
        LFREQ3 = 0x0,
        /// 7 low frequency samples
        LFREQ7 = 0x1,
    };

    pub const EIC_DPRESCALER__TICKON = enum(u1) {
        /// Clocked by GCLK
        CLK_GCLK_EIC = 0x0,
        /// Clocked by Low Frequency Clock
        CLK_LFREQ = 0x1,
    };

    pub const EIC_NMICTRL__NMIASYNCH = enum(u1) {
        /// Edge detection is clock synchronously operated
        SYNC = 0x0,
        /// Edge detection is clock asynchronously operated
        ASYNC = 0x1,
    };

    pub const EIC_NMICTRL__NMISENSE = enum(u3) {
        /// No detection
        NONE = 0x0,
        /// Rising-edge detection
        RISE = 0x1,
        /// Falling-edge detection
        FALL = 0x2,
        /// Both-edges detection
        BOTH = 0x3,
        /// High-level detection
        HIGH = 0x4,
        /// Low-level detection
        LOW = 0x5,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u8) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        reserved4: u2 = 0,
        /// Clock Selection
        CKSEL: EIC_CTRLA__CKSEL,
        padding: u3 = 0,
    }),
    /// Non-Maskable Interrupt Control
    /// offset: 0x01
    NMICTRL: mmio.Mmio(packed struct(u8) {
        /// Non-Maskable Interrupt Sense Configuration
        NMISENSE: EIC_NMICTRL__NMISENSE,
        /// Non-Maskable Interrupt Filter Enable
        NMIFILTEN: u1,
        /// Asynchronous Edge Detection Mode
        NMIASYNCH: EIC_NMICTRL__NMIASYNCH,
        padding: u3 = 0,
    }),
    /// Non-Maskable Interrupt Flag Status and Clear
    /// offset: 0x02
    NMIFLAG: mmio.Mmio(packed struct(u16) {
        /// Non-Maskable Interrupt
        NMI: u1,
        padding: u15 = 0,
    }),
    /// Synchronization Busy
    /// offset: 0x04
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// Software Reset Synchronization Busy Status
        SWRST: u1,
        /// Enable Synchronization Busy Status
        ENABLE: u1,
        padding: u30 = 0,
    }),
    /// Event Control
    /// offset: 0x08
    EVCTRL: mmio.Mmio(packed struct(u32) {
        /// External Interrupt Event Output Enable
        EXTINTEO: u16,
        padding: u16 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x0c
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// External Interrupt Enable
        EXTINT: u16,
        padding: u16 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x10
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// External Interrupt Enable
        EXTINT: u16,
        padding: u16 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x14
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// External Interrupt
        EXTINT: u16,
        padding: u16 = 0,
    }),
    /// External Interrupt Asynchronous Mode
    /// offset: 0x18
    ASYNCH: mmio.Mmio(packed struct(u32) {
        /// Asynchronous Edge Detection Mode
        ASYNCH: EIC_ASYNCH__ASYNCH,
        padding: u16 = 0,
    }),
    /// External Interrupt Sense Configuration
    /// offset: 0x1c
    CONFIG: [2]mmio.Mmio(packed struct(u32) {
        /// Input Sense Configuration 0
        SENSE0: EIC_CONFIG__SENSE0,
        /// Filter Enable 0
        FILTEN0: u1,
        /// Input Sense Configuration 1
        SENSE1: EIC_CONFIG__SENSE1,
        /// Filter Enable 1
        FILTEN1: u1,
        /// Input Sense Configuration 2
        SENSE2: EIC_CONFIG__SENSE2,
        /// Filter Enable 2
        FILTEN2: u1,
        /// Input Sense Configuration 3
        SENSE3: EIC_CONFIG__SENSE3,
        /// Filter Enable 3
        FILTEN3: u1,
        /// Input Sense Configuration 4
        SENSE4: EIC_CONFIG__SENSE4,
        /// Filter Enable 4
        FILTEN4: u1,
        /// Input Sense Configuration 5
        SENSE5: EIC_CONFIG__SENSE5,
        /// Filter Enable 5
        FILTEN5: u1,
        /// Input Sense Configuration 6
        SENSE6: EIC_CONFIG__SENSE6,
        /// Filter Enable 6
        FILTEN6: u1,
        /// Input Sense Configuration 7
        SENSE7: EIC_CONFIG__SENSE7,
        /// Filter Enable 7
        FILTEN7: u1,
    }),
    /// offset: 0x24
    reserved36: [12]u8,
    /// Debouncer Enable
    /// offset: 0x30
    DEBOUNCEN: mmio.Mmio(packed struct(u32) {
        /// Debouncer Enable
        DEBOUNCEN: u16,
        padding: u16 = 0,
    }),
    /// Debouncer Prescaler
    /// offset: 0x34
    DPRESCALER: mmio.Mmio(packed struct(u32) {
        /// Debouncer Prescaler
        PRESCALER0: EIC_DPRESCALER__PRESCALER0,
        /// Debouncer number of states
        STATES0: EIC_DPRESCALER__STATES0,
        /// Debouncer Prescaler
        PRESCALER1: EIC_DPRESCALER__PRESCALER1,
        /// Debouncer number of states
        STATES1: EIC_DPRESCALER__STATES1,
        reserved16: u8 = 0,
        /// Pin Sampler frequency selection
        TICKON: EIC_DPRESCALER__TICKON,
        padding: u15 = 0,
    }),
    /// Pin State
    /// offset: 0x38
    PINSTATE: mmio.Mmio(packed struct(u32) {
        /// Pin State
        PINSTATE: u16,
        padding: u16 = 0,
    }),
};
