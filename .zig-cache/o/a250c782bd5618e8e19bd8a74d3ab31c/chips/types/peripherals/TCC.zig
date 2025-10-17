const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const TCC = extern struct {
    pub const TCC_CTRLA__PRESCALER = enum(u3) {
        /// No division
        DIV1 = 0x0,
        /// Divide by 2
        DIV2 = 0x1,
        /// Divide by 4
        DIV4 = 0x2,
        /// Divide by 8
        DIV8 = 0x3,
        /// Divide by 16
        DIV16 = 0x4,
        /// Divide by 64
        DIV64 = 0x5,
        /// Divide by 256
        DIV256 = 0x6,
        /// Divide by 1024
        DIV1024 = 0x7,
    };

    pub const TCC_CTRLA__PRESCSYNC = enum(u2) {
        /// Reload or reset counter on next GCLK
        GCLK = 0x0,
        /// Reload or reset counter on next prescaler clock
        PRESC = 0x1,
        /// Reload or reset counter on next GCLK and reset prescaler counter
        RESYNC = 0x2,
        _,
    };

    pub const TCC_CTRLA__RESOLUTION = enum(u2) {
        /// Dithering is disabled
        NONE = 0x0,
        /// Dithering is done every 16 PWM frames
        DITH4 = 0x1,
        /// Dithering is done every 32 PWM frames
        DITH5 = 0x2,
        /// Dithering is done every 64 PWM frames
        DITH6 = 0x3,
    };

    pub const TCC_CTRLBCLR__CMD = enum(u3) {
        /// No action
        NONE = 0x0,
        /// Clear start, restart or retrigger
        RETRIGGER = 0x1,
        /// Force stop
        STOP = 0x2,
        /// Force update or double buffered registers
        UPDATE = 0x3,
        /// Force COUNT read synchronization
        READSYNC = 0x4,
        /// One-shot DMA trigger
        DMAOS = 0x5,
        _,
    };

    pub const TCC_CTRLBCLR__IDXCMD = enum(u2) {
        /// Command disabled: Index toggles between cycles A and B
        DISABLE = 0x0,
        /// Set index: cycle B will be forced in the next cycle
        SET = 0x1,
        /// Clear index: cycle A will be forced in the next cycle
        CLEAR = 0x2,
        /// Hold index: the next cycle will be the same as the current cycle
        HOLD = 0x3,
    };

    pub const TCC_CTRLBSET__CMD = enum(u3) {
        /// No action
        NONE = 0x0,
        /// Clear start, restart or retrigger
        RETRIGGER = 0x1,
        /// Force stop
        STOP = 0x2,
        /// Force update or double buffered registers
        UPDATE = 0x3,
        /// Force COUNT read synchronization
        READSYNC = 0x4,
        /// One-shot DMA trigger
        DMAOS = 0x5,
        _,
    };

    pub const TCC_CTRLBSET__IDXCMD = enum(u2) {
        /// Command disabled: Index toggles between cycles A and B
        DISABLE = 0x0,
        /// Set index: cycle B will be forced in the next cycle
        SET = 0x1,
        /// Clear index: cycle A will be forced in the next cycle
        CLEAR = 0x2,
        /// Hold index: the next cycle will be the same as the current cycle
        HOLD = 0x3,
    };

    pub const TCC_EVCTRL__CNTSEL = enum(u2) {
        /// An interrupt/event is generated when a new counter cycle starts
        START = 0x0,
        /// An interrupt/event is generated when a counter cycle ends
        END = 0x1,
        /// An interrupt/event is generated when a counter cycle ends, except for the first and last cycles
        BETWEEN = 0x2,
        /// An interrupt/event is generated when a new counter cycle starts or a counter cycle ends
        BOUNDARY = 0x3,
    };

    pub const TCC_EVCTRL__EVACT0 = enum(u3) {
        /// Event action disabled
        OFF = 0x0,
        /// Start, restart or re-trigger counter on event
        RETRIGGER = 0x1,
        /// Count on event
        COUNTEV = 0x2,
        /// Start counter on event
        START = 0x3,
        /// Increment counter on event
        INC = 0x4,
        /// Count on active state of asynchronous event
        COUNT = 0x5,
        /// Stamp capture
        STAMP = 0x6,
        /// Non-recoverable fault
        FAULT = 0x7,
    };

    pub const TCC_EVCTRL__EVACT1 = enum(u3) {
        /// Event action disabled
        OFF = 0x0,
        /// Re-trigger counter on event
        RETRIGGER = 0x1,
        /// Direction control
        DIR = 0x2,
        /// Stop counter on event
        STOP = 0x3,
        /// Decrement counter on event
        DEC = 0x4,
        /// Period capture value in CC0 register, pulse width capture value in CC1 register
        PPW = 0x5,
        /// Period capture value in CC1 register, pulse width capture value in CC0 register
        PWP = 0x6,
        /// Non-recoverable fault
        FAULT = 0x7,
    };

    pub const TCC_FCTRLA__BLANK = enum(u2) {
        /// Blanking applied from start of the ramp
        START = 0x0,
        /// Blanking applied from rising edge of the output waveform
        RISE = 0x1,
        /// Blanking applied from falling edge of the output waveform
        FALL = 0x2,
        /// Blanking applied from each toggle of the output waveform
        BOTH = 0x3,
    };

    pub const TCC_FCTRLA__CAPTURE = enum(u3) {
        /// No capture
        DISABLE = 0x0,
        /// Capture on fault
        CAPT = 0x1,
        /// Minimum capture
        CAPTMIN = 0x2,
        /// Maximum capture
        CAPTMAX = 0x3,
        /// Minimum local detection
        LOCMIN = 0x4,
        /// Maximum local detection
        LOCMAX = 0x5,
        /// Minimum and maximum local detection
        DERIV0 = 0x6,
        /// Capture with ramp index as MSB value
        CAPTMARK = 0x7,
    };

    pub const TCC_FCTRLA__CHSEL = enum(u2) {
        /// Capture value stored in channel 0
        CC0 = 0x0,
        /// Capture value stored in channel 1
        CC1 = 0x1,
        /// Capture value stored in channel 2
        CC2 = 0x2,
        /// Capture value stored in channel 3
        CC3 = 0x3,
    };

    pub const TCC_FCTRLA__HALT = enum(u2) {
        /// Halt action disabled
        DISABLE = 0x0,
        /// Hardware halt action
        HW = 0x1,
        /// Software halt action
        SW = 0x2,
        /// Non-recoverable fault
        NR = 0x3,
    };

    pub const TCC_FCTRLA__SRC = enum(u2) {
        /// Fault input disabled
        DISABLE = 0x0,
        /// MCEx (x=0,1) event input
        ENABLE = 0x1,
        /// Inverted MCEx (x=0,1) event input
        INVERT = 0x2,
        /// Alternate fault (A or B) state at the end of the previous period
        ALTFAULT = 0x3,
    };

    pub const TCC_FCTRLB__BLANK = enum(u2) {
        /// Blanking applied from start of the ramp
        START = 0x0,
        /// Blanking applied from rising edge of the output waveform
        RISE = 0x1,
        /// Blanking applied from falling edge of the output waveform
        FALL = 0x2,
        /// Blanking applied from each toggle of the output waveform
        BOTH = 0x3,
    };

    pub const TCC_FCTRLB__CAPTURE = enum(u3) {
        /// No capture
        DISABLE = 0x0,
        /// Capture on fault
        CAPT = 0x1,
        /// Minimum capture
        CAPTMIN = 0x2,
        /// Maximum capture
        CAPTMAX = 0x3,
        /// Minimum local detection
        LOCMIN = 0x4,
        /// Maximum local detection
        LOCMAX = 0x5,
        /// Minimum and maximum local detection
        DERIV0 = 0x6,
        /// Capture with ramp index as MSB value
        CAPTMARK = 0x7,
    };

    pub const TCC_FCTRLB__CHSEL = enum(u2) {
        /// Capture value stored in channel 0
        CC0 = 0x0,
        /// Capture value stored in channel 1
        CC1 = 0x1,
        /// Capture value stored in channel 2
        CC2 = 0x2,
        /// Capture value stored in channel 3
        CC3 = 0x3,
    };

    pub const TCC_FCTRLB__HALT = enum(u2) {
        /// Halt action disabled
        DISABLE = 0x0,
        /// Hardware halt action
        HW = 0x1,
        /// Software halt action
        SW = 0x2,
        /// Non-recoverable fault
        NR = 0x3,
    };

    pub const TCC_FCTRLB__SRC = enum(u2) {
        /// Fault input disabled
        DISABLE = 0x0,
        /// MCEx (x=0,1) event input
        ENABLE = 0x1,
        /// Inverted MCEx (x=0,1) event input
        INVERT = 0x2,
        /// Alternate fault (A or B) state at the end of the previous period
        ALTFAULT = 0x3,
    };

    pub const TCC_WAVE__RAMP = enum(u2) {
        /// RAMP1 operation
        RAMP1 = 0x0,
        /// Alternative RAMP2 operation
        RAMP2A = 0x1,
        /// RAMP2 operation
        RAMP2 = 0x2,
        /// Critical RAMP2 operation
        RAMP2C = 0x3,
    };

    pub const TCC_WAVE__WAVEGEN = enum(u3) {
        /// Normal frequency
        NFRQ = 0x0,
        /// Match frequency
        MFRQ = 0x1,
        /// Normal PWM
        NPWM = 0x2,
        /// Dual-slope critical
        DSCRITICAL = 0x4,
        /// Dual-slope with interrupt/event condition when COUNT reaches ZERO
        DSBOTTOM = 0x5,
        /// Dual-slope with interrupt/event condition when COUNT reaches ZERO or TOP
        DSBOTH = 0x6,
        /// Dual-slope with interrupt/event condition when COUNT reaches TOP
        DSTOP = 0x7,
        _,
    };

    /// Control A
    /// offset: 0x00
    CTRLA: mmio.Mmio(packed struct(u32) {
        /// Software Reset
        SWRST: u1,
        /// Enable
        ENABLE: u1,
        reserved5: u3 = 0,
        /// Enhanced Resolution
        RESOLUTION: TCC_CTRLA__RESOLUTION,
        reserved8: u1 = 0,
        /// Prescaler
        PRESCALER: TCC_CTRLA__PRESCALER,
        /// Run in Standby
        RUNSTDBY: u1,
        /// Prescaler and Counter Synchronization Selection
        PRESCSYNC: TCC_CTRLA__PRESCSYNC,
        /// Auto Lock
        ALOCK: u1,
        /// Master Synchronization (only for TCC Slave Instance)
        MSYNC: u1,
        reserved23: u7 = 0,
        /// DMA One-shot Trigger Mode
        DMAOS: u1,
        /// Capture Channel 0 Enable
        CPTEN0: u1,
        /// Capture Channel 1 Enable
        CPTEN1: u1,
        /// Capture Channel 2 Enable
        CPTEN2: u1,
        /// Capture Channel 3 Enable
        CPTEN3: u1,
        /// Capture Channel 4 Enable
        CPTEN4: u1,
        /// Capture Channel 5 Enable
        CPTEN5: u1,
        padding: u2 = 0,
    }),
    /// Control B Clear
    /// offset: 0x04
    CTRLBCLR: mmio.Mmio(packed struct(u8) {
        /// Counter Direction
        DIR: u1,
        /// Lock Update
        LUPD: u1,
        /// One-Shot
        ONESHOT: u1,
        /// Ramp Index Command
        IDXCMD: TCC_CTRLBCLR__IDXCMD,
        /// TCC Command
        CMD: TCC_CTRLBCLR__CMD,
    }),
    /// Control B Set
    /// offset: 0x05
    CTRLBSET: mmio.Mmio(packed struct(u8) {
        /// Counter Direction
        DIR: u1,
        /// Lock Update
        LUPD: u1,
        /// One-Shot
        ONESHOT: u1,
        /// Ramp Index Command
        IDXCMD: TCC_CTRLBSET__IDXCMD,
        /// TCC Command
        CMD: TCC_CTRLBSET__CMD,
    }),
    /// offset: 0x06
    reserved6: [2]u8,
    /// Synchronization Busy
    /// offset: 0x08
    SYNCBUSY: mmio.Mmio(packed struct(u32) {
        /// Swrst Busy
        SWRST: u1,
        /// Enable Busy
        ENABLE: u1,
        /// Ctrlb Busy
        CTRLB: u1,
        /// Status Busy
        STATUS: u1,
        /// Count Busy
        COUNT: u1,
        /// Pattern Busy
        PATT: u1,
        /// Wave Busy
        WAVE: u1,
        /// Period Busy
        PER: u1,
        /// Compare Channel 0 Busy
        CC0: u1,
        /// Compare Channel 1 Busy
        CC1: u1,
        /// Compare Channel 2 Busy
        CC2: u1,
        /// Compare Channel 3 Busy
        CC3: u1,
        /// Compare Channel 4 Busy
        CC4: u1,
        /// Compare Channel 5 Busy
        CC5: u1,
        padding: u18 = 0,
    }),
    /// Recoverable Fault A Configuration
    /// offset: 0x0c
    FCTRLA: mmio.Mmio(packed struct(u32) {
        /// Fault A Source
        SRC: TCC_FCTRLA__SRC,
        reserved3: u1 = 0,
        /// Fault A Keeper
        KEEP: u1,
        /// Fault A Qualification
        QUAL: u1,
        /// Fault A Blanking Mode
        BLANK: TCC_FCTRLA__BLANK,
        /// Fault A Restart
        RESTART: u1,
        /// Fault A Halt Mode
        HALT: TCC_FCTRLA__HALT,
        /// Fault A Capture Channel
        CHSEL: TCC_FCTRLA__CHSEL,
        /// Fault A Capture Action
        CAPTURE: TCC_FCTRLA__CAPTURE,
        /// Fault A Blanking Prescaler
        BLANKPRESC: u1,
        /// Fault A Blanking Time
        BLANKVAL: u8,
        /// Fault A Filter Value
        FILTERVAL: u4,
        padding: u4 = 0,
    }),
    /// Recoverable Fault B Configuration
    /// offset: 0x10
    FCTRLB: mmio.Mmio(packed struct(u32) {
        /// Fault B Source
        SRC: TCC_FCTRLB__SRC,
        reserved3: u1 = 0,
        /// Fault B Keeper
        KEEP: u1,
        /// Fault B Qualification
        QUAL: u1,
        /// Fault B Blanking Mode
        BLANK: TCC_FCTRLB__BLANK,
        /// Fault B Restart
        RESTART: u1,
        /// Fault B Halt Mode
        HALT: TCC_FCTRLB__HALT,
        /// Fault B Capture Channel
        CHSEL: TCC_FCTRLB__CHSEL,
        /// Fault B Capture Action
        CAPTURE: TCC_FCTRLB__CAPTURE,
        /// Fault B Blanking Prescaler
        BLANKPRESC: u1,
        /// Fault B Blanking Time
        BLANKVAL: u8,
        /// Fault B Filter Value
        FILTERVAL: u4,
        padding: u4 = 0,
    }),
    /// Waveform Extension Configuration
    /// offset: 0x14
    WEXCTRL: mmio.Mmio(packed struct(u32) {
        /// Output Matrix
        OTMX: u2,
        reserved8: u6 = 0,
        /// Dead-time Insertion Generator 0 Enable
        DTIEN0: u1,
        /// Dead-time Insertion Generator 1 Enable
        DTIEN1: u1,
        /// Dead-time Insertion Generator 2 Enable
        DTIEN2: u1,
        /// Dead-time Insertion Generator 3 Enable
        DTIEN3: u1,
        reserved16: u4 = 0,
        /// Dead-time Low Side Outputs Value
        DTLS: u8,
        /// Dead-time High Side Outputs Value
        DTHS: u8,
    }),
    /// Driver Control
    /// offset: 0x18
    DRVCTRL: mmio.Mmio(packed struct(u32) {
        /// Non-Recoverable State 0 Output Enable
        NRE0: u1,
        /// Non-Recoverable State 1 Output Enable
        NRE1: u1,
        /// Non-Recoverable State 2 Output Enable
        NRE2: u1,
        /// Non-Recoverable State 3 Output Enable
        NRE3: u1,
        /// Non-Recoverable State 4 Output Enable
        NRE4: u1,
        /// Non-Recoverable State 5 Output Enable
        NRE5: u1,
        /// Non-Recoverable State 6 Output Enable
        NRE6: u1,
        /// Non-Recoverable State 7 Output Enable
        NRE7: u1,
        /// Non-Recoverable State 0 Output Value
        NRV0: u1,
        /// Non-Recoverable State 1 Output Value
        NRV1: u1,
        /// Non-Recoverable State 2 Output Value
        NRV2: u1,
        /// Non-Recoverable State 3 Output Value
        NRV3: u1,
        /// Non-Recoverable State 4 Output Value
        NRV4: u1,
        /// Non-Recoverable State 5 Output Value
        NRV5: u1,
        /// Non-Recoverable State 6 Output Value
        NRV6: u1,
        /// Non-Recoverable State 7 Output Value
        NRV7: u1,
        /// Output Waveform 0 Inversion
        INVEN0: u1,
        /// Output Waveform 1 Inversion
        INVEN1: u1,
        /// Output Waveform 2 Inversion
        INVEN2: u1,
        /// Output Waveform 3 Inversion
        INVEN3: u1,
        /// Output Waveform 4 Inversion
        INVEN4: u1,
        /// Output Waveform 5 Inversion
        INVEN5: u1,
        /// Output Waveform 6 Inversion
        INVEN6: u1,
        /// Output Waveform 7 Inversion
        INVEN7: u1,
        /// Non-Recoverable Fault Input 0 Filter Value
        FILTERVAL0: u4,
        /// Non-Recoverable Fault Input 1 Filter Value
        FILTERVAL1: u4,
    }),
    /// offset: 0x1c
    reserved28: [2]u8,
    /// Debug Control
    /// offset: 0x1e
    DBGCTRL: mmio.Mmio(packed struct(u8) {
        /// Debug Running Mode
        DBGRUN: u1,
        reserved2: u1 = 0,
        /// Fault Detection on Debug Break Detection
        FDDBD: u1,
        padding: u5 = 0,
    }),
    /// offset: 0x1f
    reserved31: [1]u8,
    /// Event Control
    /// offset: 0x20
    EVCTRL: mmio.Mmio(packed struct(u32) {
        /// Timer/counter Input Event0 Action
        EVACT0: TCC_EVCTRL__EVACT0,
        /// Timer/counter Input Event1 Action
        EVACT1: TCC_EVCTRL__EVACT1,
        /// Timer/counter Output Event Mode
        CNTSEL: TCC_EVCTRL__CNTSEL,
        /// Overflow/Underflow Output Event Enable
        OVFEO: u1,
        /// Retrigger Output Event Enable
        TRGEO: u1,
        /// Timer/counter Output Event Enable
        CNTEO: u1,
        reserved12: u1 = 0,
        /// Inverted Event 0 Input Enable
        TCINV0: u1,
        /// Inverted Event 1 Input Enable
        TCINV1: u1,
        /// Timer/counter Event 0 Input Enable
        TCEI0: u1,
        /// Timer/counter Event 1 Input Enable
        TCEI1: u1,
        /// Match or Capture Channel 0 Event Input Enable
        MCEI0: u1,
        /// Match or Capture Channel 1 Event Input Enable
        MCEI1: u1,
        /// Match or Capture Channel 2 Event Input Enable
        MCEI2: u1,
        /// Match or Capture Channel 3 Event Input Enable
        MCEI3: u1,
        /// Match or Capture Channel 4 Event Input Enable
        MCEI4: u1,
        /// Match or Capture Channel 5 Event Input Enable
        MCEI5: u1,
        reserved24: u2 = 0,
        /// Match or Capture Channel 0 Event Output Enable
        MCEO0: u1,
        /// Match or Capture Channel 1 Event Output Enable
        MCEO1: u1,
        /// Match or Capture Channel 2 Event Output Enable
        MCEO2: u1,
        /// Match or Capture Channel 3 Event Output Enable
        MCEO3: u1,
        /// Match or Capture Channel 4 Event Output Enable
        MCEO4: u1,
        /// Match or Capture Channel 5 Event Output Enable
        MCEO5: u1,
        padding: u2 = 0,
    }),
    /// Interrupt Enable Clear
    /// offset: 0x24
    INTENCLR: mmio.Mmio(packed struct(u32) {
        /// Overflow Interrupt Enable
        OVF: u1,
        /// Retrigger Interrupt Enable
        TRG: u1,
        /// Counter Interrupt Enable
        CNT: u1,
        /// Error Interrupt Enable
        ERR: u1,
        reserved10: u6 = 0,
        /// Non-Recoverable Update Fault Interrupt Enable
        UFS: u1,
        /// Non-Recoverable Debug Fault Interrupt Enable
        DFS: u1,
        /// Recoverable Fault A Interrupt Enable
        FAULTA: u1,
        /// Recoverable Fault B Interrupt Enable
        FAULTB: u1,
        /// Non-Recoverable Fault 0 Interrupt Enable
        FAULT0: u1,
        /// Non-Recoverable Fault 1 Interrupt Enable
        FAULT1: u1,
        /// Match or Capture Channel 0 Interrupt Enable
        MC0: u1,
        /// Match or Capture Channel 1 Interrupt Enable
        MC1: u1,
        /// Match or Capture Channel 2 Interrupt Enable
        MC2: u1,
        /// Match or Capture Channel 3 Interrupt Enable
        MC3: u1,
        /// Match or Capture Channel 4 Interrupt Enable
        MC4: u1,
        /// Match or Capture Channel 5 Interrupt Enable
        MC5: u1,
        padding: u10 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x28
    INTENSET: mmio.Mmio(packed struct(u32) {
        /// Overflow Interrupt Enable
        OVF: u1,
        /// Retrigger Interrupt Enable
        TRG: u1,
        /// Counter Interrupt Enable
        CNT: u1,
        /// Error Interrupt Enable
        ERR: u1,
        reserved10: u6 = 0,
        /// Non-Recoverable Update Fault Interrupt Enable
        UFS: u1,
        /// Non-Recoverable Debug Fault Interrupt Enable
        DFS: u1,
        /// Recoverable Fault A Interrupt Enable
        FAULTA: u1,
        /// Recoverable Fault B Interrupt Enable
        FAULTB: u1,
        /// Non-Recoverable Fault 0 Interrupt Enable
        FAULT0: u1,
        /// Non-Recoverable Fault 1 Interrupt Enable
        FAULT1: u1,
        /// Match or Capture Channel 0 Interrupt Enable
        MC0: u1,
        /// Match or Capture Channel 1 Interrupt Enable
        MC1: u1,
        /// Match or Capture Channel 2 Interrupt Enable
        MC2: u1,
        /// Match or Capture Channel 3 Interrupt Enable
        MC3: u1,
        /// Match or Capture Channel 4 Interrupt Enable
        MC4: u1,
        /// Match or Capture Channel 5 Interrupt Enable
        MC5: u1,
        padding: u10 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x2c
    INTFLAG: mmio.Mmio(packed struct(u32) {
        /// Overflow
        OVF: u1,
        /// Retrigger
        TRG: u1,
        /// Counter
        CNT: u1,
        /// Error
        ERR: u1,
        reserved10: u6 = 0,
        /// Non-Recoverable Update Fault
        UFS: u1,
        /// Non-Recoverable Debug Fault
        DFS: u1,
        /// Recoverable Fault A
        FAULTA: u1,
        /// Recoverable Fault B
        FAULTB: u1,
        /// Non-Recoverable Fault 0
        FAULT0: u1,
        /// Non-Recoverable Fault 1
        FAULT1: u1,
        /// Match or Capture 0
        MC0: u1,
        /// Match or Capture 1
        MC1: u1,
        /// Match or Capture 2
        MC2: u1,
        /// Match or Capture 3
        MC3: u1,
        /// Match or Capture 4
        MC4: u1,
        /// Match or Capture 5
        MC5: u1,
        padding: u10 = 0,
    }),
    /// Status
    /// offset: 0x30
    STATUS: mmio.Mmio(packed struct(u32) {
        /// Stop
        STOP: u1,
        /// Ramp
        IDX: u1,
        /// Non-recoverable Update Fault State
        UFS: u1,
        /// Non-Recoverable Debug Fault State
        DFS: u1,
        /// Slave
        SLAVE: u1,
        /// Pattern Buffer Valid
        PATTBUFV: u1,
        reserved7: u1 = 0,
        /// Period Buffer Valid
        PERBUFV: u1,
        /// Recoverable Fault A Input
        FAULTAIN: u1,
        /// Recoverable Fault B Input
        FAULTBIN: u1,
        /// Non-Recoverable Fault0 Input
        FAULT0IN: u1,
        /// Non-Recoverable Fault1 Input
        FAULT1IN: u1,
        /// Recoverable Fault A State
        FAULTA: u1,
        /// Recoverable Fault B State
        FAULTB: u1,
        /// Non-Recoverable Fault 0 State
        FAULT0: u1,
        /// Non-Recoverable Fault 1 State
        FAULT1: u1,
        /// Compare Channel 0 Buffer Valid
        CCBUFV0: u1,
        /// Compare Channel 1 Buffer Valid
        CCBUFV1: u1,
        /// Compare Channel 2 Buffer Valid
        CCBUFV2: u1,
        /// Compare Channel 3 Buffer Valid
        CCBUFV3: u1,
        /// Compare Channel 4 Buffer Valid
        CCBUFV4: u1,
        /// Compare Channel 5 Buffer Valid
        CCBUFV5: u1,
        reserved24: u2 = 0,
        /// Compare Channel 0 Value
        CMP0: u1,
        /// Compare Channel 1 Value
        CMP1: u1,
        /// Compare Channel 2 Value
        CMP2: u1,
        /// Compare Channel 3 Value
        CMP3: u1,
        /// Compare Channel 4 Value
        CMP4: u1,
        /// Compare Channel 5 Value
        CMP5: u1,
        padding: u2 = 0,
    }),
    /// Count
    /// offset: 0x34
    COUNT: mmio.Mmio(packed struct(u32) {
        /// Counter Value
        COUNT: u24,
        padding: u8 = 0,
    }),
    /// Pattern
    /// offset: 0x38
    PATT: mmio.Mmio(packed struct(u16) {
        /// Pattern Generator 0 Output Enable
        PGE0: u1,
        /// Pattern Generator 1 Output Enable
        PGE1: u1,
        /// Pattern Generator 2 Output Enable
        PGE2: u1,
        /// Pattern Generator 3 Output Enable
        PGE3: u1,
        /// Pattern Generator 4 Output Enable
        PGE4: u1,
        /// Pattern Generator 5 Output Enable
        PGE5: u1,
        /// Pattern Generator 6 Output Enable
        PGE6: u1,
        /// Pattern Generator 7 Output Enable
        PGE7: u1,
        /// Pattern Generator 0 Output Value
        PGV0: u1,
        /// Pattern Generator 1 Output Value
        PGV1: u1,
        /// Pattern Generator 2 Output Value
        PGV2: u1,
        /// Pattern Generator 3 Output Value
        PGV3: u1,
        /// Pattern Generator 4 Output Value
        PGV4: u1,
        /// Pattern Generator 5 Output Value
        PGV5: u1,
        /// Pattern Generator 6 Output Value
        PGV6: u1,
        /// Pattern Generator 7 Output Value
        PGV7: u1,
    }),
    /// offset: 0x3a
    reserved58: [2]u8,
    /// Waveform Control
    /// offset: 0x3c
    WAVE: mmio.Mmio(packed struct(u32) {
        /// Waveform Generation
        WAVEGEN: TCC_WAVE__WAVEGEN,
        reserved4: u1 = 0,
        /// Ramp Mode
        RAMP: TCC_WAVE__RAMP,
        reserved7: u1 = 0,
        /// Circular period Enable
        CIPEREN: u1,
        /// Circular Channel 0 Enable
        CICCEN0: u1,
        /// Circular Channel 1 Enable
        CICCEN1: u1,
        /// Circular Channel 2 Enable
        CICCEN2: u1,
        /// Circular Channel 3 Enable
        CICCEN3: u1,
        reserved16: u4 = 0,
        /// Channel 0 Polarity
        POL0: u1,
        /// Channel 1 Polarity
        POL1: u1,
        /// Channel 2 Polarity
        POL2: u1,
        /// Channel 3 Polarity
        POL3: u1,
        /// Channel 4 Polarity
        POL4: u1,
        /// Channel 5 Polarity
        POL5: u1,
        reserved24: u2 = 0,
        /// Swap DTI Output Pair 0
        SWAP0: u1,
        /// Swap DTI Output Pair 1
        SWAP1: u1,
        /// Swap DTI Output Pair 2
        SWAP2: u1,
        /// Swap DTI Output Pair 3
        SWAP3: u1,
        padding: u4 = 0,
    }),
    /// Period
    /// offset: 0x40
    PER: mmio.Mmio(packed struct(u32) {
        /// Dithering Cycle Number
        DITHER: u4,
        /// Period Value
        PER: u20,
        padding: u8 = 0,
    }),
    /// Compare and Capture
    /// offset: 0x44
    CC: [6]mmio.Mmio(packed struct(u32) {
        /// Dithering Cycle Number
        DITHER: u4,
        /// Channel Compare/Capture Value
        CC: u20,
        padding: u8 = 0,
    }),
    /// offset: 0x5c
    reserved92: [8]u8,
    /// Pattern Buffer
    /// offset: 0x64
    PATTBUF: mmio.Mmio(packed struct(u16) {
        /// Pattern Generator 0 Output Enable Buffer
        PGEB0: u1,
        /// Pattern Generator 1 Output Enable Buffer
        PGEB1: u1,
        /// Pattern Generator 2 Output Enable Buffer
        PGEB2: u1,
        /// Pattern Generator 3 Output Enable Buffer
        PGEB3: u1,
        /// Pattern Generator 4 Output Enable Buffer
        PGEB4: u1,
        /// Pattern Generator 5 Output Enable Buffer
        PGEB5: u1,
        /// Pattern Generator 6 Output Enable Buffer
        PGEB6: u1,
        /// Pattern Generator 7 Output Enable Buffer
        PGEB7: u1,
        /// Pattern Generator 0 Output Enable
        PGVB0: u1,
        /// Pattern Generator 1 Output Enable
        PGVB1: u1,
        /// Pattern Generator 2 Output Enable
        PGVB2: u1,
        /// Pattern Generator 3 Output Enable
        PGVB3: u1,
        /// Pattern Generator 4 Output Enable
        PGVB4: u1,
        /// Pattern Generator 5 Output Enable
        PGVB5: u1,
        /// Pattern Generator 6 Output Enable
        PGVB6: u1,
        /// Pattern Generator 7 Output Enable
        PGVB7: u1,
    }),
    /// offset: 0x66
    reserved102: [6]u8,
    /// Period Buffer
    /// offset: 0x6c
    PERBUF: mmio.Mmio(packed struct(u32) {
        /// Dithering Buffer Cycle Number
        DITHERBUF: u4,
        /// Period Buffer Value
        PERBUF: u20,
        padding: u8 = 0,
    }),
    /// Compare and Capture Buffer
    /// offset: 0x70
    CCBUF: [6]mmio.Mmio(packed struct(u32) {
        /// Channel Compare/Capture Buffer Value
        CCBUF: u4,
        /// Dithering Buffer Cycle Number
        DITHERBUF: u20,
        padding: u8 = 0,
    }),
};
