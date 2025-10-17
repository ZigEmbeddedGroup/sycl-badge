const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const ADC = extern struct {
    pub const ADC_AVGCTRL__SAMPLENUM = enum(u4) {
        /// 1 sample
        @"1" = 0x0,
        /// 2 samples
        @"2" = 0x1,
        /// 4 samples
        @"4" = 0x2,
        /// 8 samples
        @"8" = 0x3,
        /// 16 samples
        @"16" = 0x4,
        /// 32 samples
        @"32" = 0x5,
        /// 64 samples
        @"64" = 0x6,
        /// 128 samples
        @"128" = 0x7,
        /// 256 samples
        @"256" = 0x8,
        /// 512 samples
        @"512" = 0x9,
        /// 1024 samples
        @"1024" = 0xa,
        _,
    };

    pub const ADC_CTRLA__DUALSEL = enum(u2) {
        /// Start event or software trigger will start a conversion on both ADCs
        BOTH = 0x0,
        /// START event or software trigger will alternatingly start a conversion on ADC0 and ADC1
        INTERLEAVE = 0x1,
        _,
    };

    pub const ADC_CTRLA__PRESCALER = enum(u3) {
        /// Peripheral clock divided by 2
        DIV2 = 0x0,
        /// Peripheral clock divided by 4
        DIV4 = 0x1,
        /// Peripheral clock divided by 8
        DIV8 = 0x2,
        /// Peripheral clock divided by 16
        DIV16 = 0x3,
        /// Peripheral clock divided by 32
        DIV32 = 0x4,
        /// Peripheral clock divided by 64
        DIV64 = 0x5,
        /// Peripheral clock divided by 128
        DIV128 = 0x6,
        /// Peripheral clock divided by 256
        DIV256 = 0x7,
    };

    pub const ADC_CTRLB__RESSEL = enum(u2) {
        /// 12-bit result
        @"12BIT" = 0x0,
        /// For averaging mode output
        @"16BIT" = 0x1,
        /// 10-bit result
        @"10BIT" = 0x2,
        /// 8-bit result
        @"8BIT" = 0x3,
    };

    pub const ADC_CTRLB__WINMODE = enum(u3) {
        /// No window mode (default)
        DISABLE = 0x0,
        /// RESULT > WINLT
        MODE1 = 0x1,
        /// RESULT < WINUT
        MODE2 = 0x2,
        /// WINLT < RESULT < WINUT
        MODE3 = 0x3,
        /// !(WINLT < RESULT < WINUT)
        MODE4 = 0x4,
        _,
    };

    pub const ADC_INPUTCTRL__MUXNEG = enum(u5) {
        /// ADC AIN0 Pin
        AIN0 = 0x0,
        /// ADC AIN1 Pin
        AIN1 = 0x1,
        /// ADC AIN2 Pin
        AIN2 = 0x2,
        /// ADC AIN3 Pin
        AIN3 = 0x3,
        /// ADC AIN4 Pin
        AIN4 = 0x4,
        /// ADC AIN5 Pin
        AIN5 = 0x5,
        /// ADC AIN6 Pin
        AIN6 = 0x6,
        /// ADC AIN7 Pin
        AIN7 = 0x7,
        /// Internal Ground
        GND = 0x18,
        _,
    };

    pub const ADC_INPUTCTRL__MUXPOS = enum(u5) {
        /// ADC AIN0 Pin
        AIN0 = 0x0,
        /// ADC AIN1 Pin
        AIN1 = 0x1,
        /// ADC AIN2 Pin
        AIN2 = 0x2,
        /// ADC AIN3 Pin
        AIN3 = 0x3,
        /// ADC AIN4 Pin
        AIN4 = 0x4,
        /// ADC AIN5 Pin
        AIN5 = 0x5,
        /// ADC AIN6 Pin
        AIN6 = 0x6,
        /// ADC AIN7 Pin
        AIN7 = 0x7,
        /// ADC AIN8 Pin
        AIN8 = 0x8,
        /// ADC AIN9 Pin
        AIN9 = 0x9,
        /// ADC AIN10 Pin
        AIN10 = 0xa,
        /// ADC AIN11 Pin
        AIN11 = 0xb,
        /// ADC AIN12 Pin
        AIN12 = 0xc,
        /// ADC AIN13 Pin
        AIN13 = 0xd,
        /// ADC AIN14 Pin
        AIN14 = 0xe,
        /// ADC AIN15 Pin
        AIN15 = 0xf,
        /// ADC AIN16 Pin
        AIN16 = 0x10,
        /// ADC AIN17 Pin
        AIN17 = 0x11,
        /// ADC AIN18 Pin
        AIN18 = 0x12,
        /// ADC AIN19 Pin
        AIN19 = 0x13,
        /// ADC AIN20 Pin
        AIN20 = 0x14,
        /// ADC AIN21 Pin
        AIN21 = 0x15,
        /// ADC AIN22 Pin
        AIN22 = 0x16,
        /// ADC AIN23 Pin
        AIN23 = 0x17,
        /// 1/4 Scaled Core Supply
        SCALEDCOREVCC = 0x18,
        /// 1/4 Scaled VBAT Supply
        SCALEDVBAT = 0x19,
        /// 1/4 Scaled I/O Supply
        SCALEDIOVCC = 0x1a,
        /// Bandgap Voltage
        BANDGAP = 0x1b,
        /// Temperature Sensor
        PTAT = 0x1c,
        /// Temperature Sensor
        CTAT = 0x1d,
        /// DAC Output
        DAC = 0x1e,
        /// PTC output (only on ADC0)
        PTC = 0x1f,
    };

    pub const ADC_REFCTRL__REFSEL = enum(u4) {
        /// Internal Bandgap Reference
        INTREF = 0x0,
        /// 1/2 VDDANA
        INTVCC0 = 0x2,
        /// VDDANA
        INTVCC1 = 0x3,
        /// External Reference
        AREFA = 0x4,
        /// External Reference
        AREFB = 0x5,
        /// External Reference (only on ADC1)
        AREFC = 0x6,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u16) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        reserved3: u1 = 0,
        /// Dual Mode Trigger Selection
        DUALSEL: ADC_CTRLA__DUALSEL,
        /// Slave Enable
        SLAVEEN: u1,
        /// Run in Standby
        RUNSTDBY: u1,
        /// On Demand Control
        ONDEMAND: u1,
        /// Prescaler Configuration
        PRESCALER: ADC_CTRLA__PRESCALER,
        reserved15: u4 = 0,
        /// Rail to Rail Operation Enable
        R2R: u1,
    }),
    /// Event Control
    /// offset: 0x02
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Flush Event Input Enable
        FLUSHEI: u1,
        /// Start Conversion Event Input Enable
        STARTEI: u1,
        /// Flush Event Invert Enable
        FLUSHINV: u1,
        /// Start Conversion Event Invert Enable
        STARTINV: u1,
        /// Result Ready Event Out
        RESRDYEO: u1,
        /// Window Monitor Event Out
        WINMONEO: u1,
        padding: u2 = 0,
    }),
    /// Debug Control
    /// offset: 0x03
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Run
        DBGRUN: u1,
        padding: u7 = 0,
    }),
    /// Input Control
    /// offset: 0x04
    INPUTCTRL: mmio.Mmio(packed struct(u16) {
        /// Positive Mux Input Selection
        MUXPOS: ADC_INPUTCTRL__MUXPOS,
        reserved7: u2 = 0,
        /// Differential Mode
        DIFFMODE: u1,
        /// Negative Mux Input Selection
        MUXNEG: ADC_INPUTCTRL__MUXNEG,
        reserved15: u2 = 0,
        /// Stop DMA Sequencing
        DSEQSTOP: u1,
    }),
    /// Control B
    /// offset: 0x06
    CTRLB: mmio.Mmio(packed struct(u16) {
        /// Left-Adjusted Result
        LEFTADJ: u1,
        /// Free Running Mode
        FREERUN: u1,
        /// Digital Correction Logic Enable
        CORREN: u1,
        /// Conversion Result Resolution
        RESSEL: ADC_CTRLB__RESSEL,
        reserved8: u3 = 0,
        /// Window Monitor Mode
        WINMODE: ADC_CTRLB__WINMODE,
        /// Window Single Sample
        WINSS: u1,
        padding: u4 = 0,
    }),
    /// Reference Control
    /// offset: 0x08
    REFCTRL: mmio.Mmio(packed struct(u8) {
        /// Reference Selection
        REFSEL: ADC_REFCTRL__REFSEL,
        reserved7: u3 = 0,
        /// Reference Buffer Offset Compensation Enable
        REFCOMP: u1,
    }),
    /// offset: 0x09
    reserved9: [1]u8,
    /// Average Control
    /// offset: 0x0a
    AVGCTRL: mmio.Mmio(packed struct(u8) {
        /// Number of Samples to be Collected
        SAMPLENUM: ADC_AVGCTRL__SAMPLENUM,
        /// Adjusting Result / Division Coefficient
        ADJRES: u3,
        padding: u1 = 0,
    }),
    /// Sample Time Control
    /// offset: 0x0b
    SAMPCTRL: mmio.Mmio(packed struct(u8) {
        /// Sampling Time Length
        SAMPLEN: u6,
        reserved7: u1 = 0,
        /// Comparator Offset Compensation Enable
        OFFCOMP: u1,
    }),
    /// Window Monitor Lower Threshold
    /// offset: 0x0c
    WINLT: mmio.Mmio(packed struct(u16) {
        /// Window Lower Threshold
        WINLT: u16,
    }),
    /// Window Monitor Upper Threshold
    /// offset: 0x0e
    WINUT: mmio.Mmio(packed struct(u16) {
        /// Window Upper Threshold
        WINUT: u16,
    }),
    /// Gain Correction
    /// offset: 0x10
    GAINCORR: mmio.Mmio(packed struct(u16) {
        /// Gain Correction Value
        GAINCORR: u12,
        padding: u4 = 0,
    }),
    /// Offset Correction
    /// offset: 0x12
    OFFSETCORR: mmio.Mmio(packed struct(u16) {
        /// Offset Correction Value
        OFFSETCORR: u12,
        padding: u4 = 0,
    }),
    /// Software Trigger
    /// offset: 0x14
    SWTRIG: mmio.Mmio(packed struct(u8) {
        /// ADC Conversion Flush
        FLUSH: u1,
        /// Start ADC Conversion
        START: u1,
        padding: u6 = 0,
    }),
    /// offset: 0x15
    reserved21: [23]u8,
    /// Interrupt Enable Clear
    /// offset: 0x2c
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Result Ready Interrupt Disable
        RESRDY: u1,
        /// Overrun Interrupt Disable
        OVERRUN: u1,
        /// Window Monitor Interrupt Disable
        WINMON: u1,
        padding: u5 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x2d
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Result Ready Interrupt Enable
        RESRDY: u1,
        /// Overrun Interrupt Enable
        OVERRUN: u1,
        /// Window Monitor Interrupt Enable
        WINMON: u1,
        padding: u5 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x2e
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Result Ready Interrupt Flag
        RESRDY: u1,
        /// Overrun Interrupt Flag
        OVERRUN: u1,
        /// Window Monitor Interrupt Flag
        WINMON: u1,
        padding: u5 = 0,
    }),
    /// Status
    /// offset: 0x2f
    STATUS: mmio.Mmio(packed struct(u8) {
        /// ADC Busy Status
        ADCBUSY: u1,
        reserved2: u1 = 0,
        /// Window Comparator Counter
        WCC: u6,
    }),
    /// Synchronization Busy
    /// offset: 0x30
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// SWRST Synchronization Busy
        SWRST: u1,
        /// ENABLE Synchronization Busy
        ENABLE: u1,
        /// Input Control Synchronization Busy
        INPUTCTRL: u1,
        /// Control B Synchronization Busy
        CTRLB: u1,
        /// Reference Control Synchronization Busy
        REFCTRL: u1,
        /// Average Control Synchronization Busy
        AVGCTRL: u1,
        /// Sampling Time Control Synchronization Busy
        SAMPCTRL: u1,
        /// Window Monitor Lower Threshold Synchronization Busy
        WINLT: u1,
        /// Window Monitor Upper Threshold Synchronization Busy
        WINUT: u1,
        /// Gain Correction Synchronization Busy
        GAINCORR: u1,
        /// Offset Correction Synchronization Busy
        OFFSETCORR: u1,
        /// Software Trigger Synchronization Busy
        SWTRIG: u1,
        padding: u20 = 0,
    }),
    /// DMA Sequencial Data
    /// offset: 0x34
    DSEQDATA: mmio.Mmio(packed struct(u32) {
        /// DMA Sequential Data
        DATA: u32,
    }),
    /// DMA Sequential Control
    /// offset: 0x38
    DSEQCTRL: mmio.Mmio(packed struct(u32) {
        /// Input Control
        INPUTCTRL: u1,
        /// Control B
        CTRLB: u1,
        /// Reference Control
        REFCTRL: u1,
        /// Average Control
        AVGCTRL: u1,
        /// Sampling Time Control
        SAMPCTRL: u1,
        /// Window Monitor Lower Threshold
        WINLT: u1,
        /// Window Monitor Upper Threshold
        WINUT: u1,
        /// Gain Correction
        GAINCORR: u1,
        /// Offset Correction
        OFFSETCORR: u1,
        reserved31: u22 = 0,
        /// ADC Auto-Start Conversion
        AUTOSTART: u1,
    }),
    /// DMA Sequencial Status
    /// offset: 0x3c
    DSEQSTAT: mmio.Mmio(packed struct(u32) {
        /// Input Control
        INPUTCTRL: u1,
        /// Control B
        CTRLB: u1,
        /// Reference Control
        REFCTRL: u1,
        /// Average Control
        AVGCTRL: u1,
        /// Sampling Time Control
        SAMPCTRL: u1,
        /// Window Monitor Lower Threshold
        WINLT: u1,
        /// Window Monitor Upper Threshold
        WINUT: u1,
        /// Gain Correction
        GAINCORR: u1,
        /// Offset Correction
        OFFSETCORR: u1,
        reserved31: u22 = 0,
        /// DMA Sequencing Busy
        BUSY: u1,
    }),
    /// Result Conversion Value
    /// offset: 0x40
    RESULT: mmio.Mmio(packed struct(u16) {
        /// Result Conversion Value
        RESULT: u16,
    }),
    /// offset: 0x42
    reserved66: [2]u8,
    /// Last Sample Result
    /// offset: 0x44
    RESS: mmio.Mmio(packed struct(u16) {
        /// Last ADC conversion result
        RESS: u16,
    }),
    /// offset: 0x46
    reserved70: [2]u8,
    /// Calibration
    /// offset: 0x48
    CALIB: mmio.Mmio(packed struct(u16) {
        /// Bias Comparator Scaling
        BIASCOMP: u3,
        reserved4: u1 = 0,
        /// Bias R2R Ampli scaling
        BIASR2R: u3,
        reserved8: u1 = 0,
        /// Bias Reference Buffer Scaling
        BIASREFBUF: u3,
        padding: u5 = 0,
    }),
};
