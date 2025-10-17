const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const RTC = extern union {
    pub const Mode = enum {
        MODE0,
        MODE1,
        MODE2,
    };

    pub fn get_mode(self: *volatile @This()) Mode {
        {
            const value = self.MODE0.CTRLA.read().MODE;
            switch (value) {
                0,
                => return .MODE0,
                else => {},
            }
        }
        {
            const value = self.MODE1.CTRLA.read().MODE;
            switch (value) {
                1,
                => return .MODE1,
                else => {},
            }
        }
        {
            const value = self.MODE2.CTRLA.read().MODE;
            switch (value) {
                2,
                => return .MODE2,
                else => {},
            }
        }

        unreachable;
    }

    pub const RTC_MODE0_CTRLA__MODE = enum(u2) {
        /// Mode 0: 32-bit Counter
        COUNT32 = 0x0,
        /// Mode 1: 16-bit Counter
        COUNT16 = 0x1,
        /// Mode 2: Clock/Calendar
        CLOCK = 0x2,
        _,
    };

    pub const RTC_MODE0_CTRLA__PRESCALER = enum(u4) {
        /// CLK_RTC_CNT = GCLK_RTC/1
        OFF = 0x0,
        /// CLK_RTC_CNT = GCLK_RTC/1
        DIV1 = 0x1,
        /// CLK_RTC_CNT = GCLK_RTC/2
        DIV2 = 0x2,
        /// CLK_RTC_CNT = GCLK_RTC/4
        DIV4 = 0x3,
        /// CLK_RTC_CNT = GCLK_RTC/8
        DIV8 = 0x4,
        /// CLK_RTC_CNT = GCLK_RTC/16
        DIV16 = 0x5,
        /// CLK_RTC_CNT = GCLK_RTC/32
        DIV32 = 0x6,
        /// CLK_RTC_CNT = GCLK_RTC/64
        DIV64 = 0x7,
        /// CLK_RTC_CNT = GCLK_RTC/128
        DIV128 = 0x8,
        /// CLK_RTC_CNT = GCLK_RTC/256
        DIV256 = 0x9,
        /// CLK_RTC_CNT = GCLK_RTC/512
        DIV512 = 0xa,
        /// CLK_RTC_CNT = GCLK_RTC/1024
        DIV1024 = 0xb,
        _,
    };

    pub const RTC_MODE0_CTRLB__ACTF = enum(u3) {
        /// CLK_RTC_OUT = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_OUT = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_OUT = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_OUT = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_OUT = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_OUT = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_OUT = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_OUT = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE0_CTRLB__DEBF = enum(u3) {
        /// CLK_RTC_DEB = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_DEB = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_DEB = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_DEB = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_DEB = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_DEB = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_DEB = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_DEB = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE1_CTRLA__MODE = enum(u2) {
        /// Mode 0: 32-bit Counter
        COUNT32 = 0x0,
        /// Mode 1: 16-bit Counter
        COUNT16 = 0x1,
        /// Mode 2: Clock/Calendar
        CLOCK = 0x2,
        _,
    };

    pub const RTC_MODE1_CTRLA__PRESCALER = enum(u4) {
        /// CLK_RTC_CNT = GCLK_RTC/1
        OFF = 0x0,
        /// CLK_RTC_CNT = GCLK_RTC/1
        DIV1 = 0x1,
        /// CLK_RTC_CNT = GCLK_RTC/2
        DIV2 = 0x2,
        /// CLK_RTC_CNT = GCLK_RTC/4
        DIV4 = 0x3,
        /// CLK_RTC_CNT = GCLK_RTC/8
        DIV8 = 0x4,
        /// CLK_RTC_CNT = GCLK_RTC/16
        DIV16 = 0x5,
        /// CLK_RTC_CNT = GCLK_RTC/32
        DIV32 = 0x6,
        /// CLK_RTC_CNT = GCLK_RTC/64
        DIV64 = 0x7,
        /// CLK_RTC_CNT = GCLK_RTC/128
        DIV128 = 0x8,
        /// CLK_RTC_CNT = GCLK_RTC/256
        DIV256 = 0x9,
        /// CLK_RTC_CNT = GCLK_RTC/512
        DIV512 = 0xa,
        /// CLK_RTC_CNT = GCLK_RTC/1024
        DIV1024 = 0xb,
        _,
    };

    pub const RTC_MODE1_CTRLB__ACTF = enum(u3) {
        /// CLK_RTC_OUT = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_OUT = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_OUT = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_OUT = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_OUT = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_OUT = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_OUT = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_OUT = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE1_CTRLB__DEBF = enum(u3) {
        /// CLK_RTC_DEB = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_DEB = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_DEB = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_DEB = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_DEB = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_DEB = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_DEB = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_DEB = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE2_ALARM_ALARM__HOUR = enum(u5) {
        /// Morning hour
        AM = 0x0,
        /// Afternoon hour
        PM = 0x10,
        _,
    };

    pub const RTC_MODE2_ALARM_MASK__SEL = enum(u3) {
        /// Alarm Disabled
        OFF = 0x0,
        /// Match seconds only
        SS = 0x1,
        /// Match seconds and minutes only
        MMSS = 0x2,
        /// Match seconds, minutes, and hours only
        HHMMSS = 0x3,
        /// Match seconds, minutes, hours, and days only
        DDHHMMSS = 0x4,
        /// Match seconds, minutes, hours, days, and months only
        MMDDHHMMSS = 0x5,
        /// Match seconds, minutes, hours, days, months, and years
        YYMMDDHHMMSS = 0x6,
        _,
    };

    pub const RTC_MODE2_CLOCK__HOUR = enum(u5) {
        /// AM when CLKREP in 12-hour
        AM = 0x0,
        /// PM when CLKREP in 12-hour
        PM = 0x10,
        _,
    };

    pub const RTC_MODE2_CTRLA__MODE = enum(u2) {
        /// Mode 0: 32-bit Counter
        COUNT32 = 0x0,
        /// Mode 1: 16-bit Counter
        COUNT16 = 0x1,
        /// Mode 2: Clock/Calendar
        CLOCK = 0x2,
        _,
    };

    pub const RTC_MODE2_CTRLA__PRESCALER = enum(u4) {
        /// CLK_RTC_CNT = GCLK_RTC/1
        OFF = 0x0,
        /// CLK_RTC_CNT = GCLK_RTC/1
        DIV1 = 0x1,
        /// CLK_RTC_CNT = GCLK_RTC/2
        DIV2 = 0x2,
        /// CLK_RTC_CNT = GCLK_RTC/4
        DIV4 = 0x3,
        /// CLK_RTC_CNT = GCLK_RTC/8
        DIV8 = 0x4,
        /// CLK_RTC_CNT = GCLK_RTC/16
        DIV16 = 0x5,
        /// CLK_RTC_CNT = GCLK_RTC/32
        DIV32 = 0x6,
        /// CLK_RTC_CNT = GCLK_RTC/64
        DIV64 = 0x7,
        /// CLK_RTC_CNT = GCLK_RTC/128
        DIV128 = 0x8,
        /// CLK_RTC_CNT = GCLK_RTC/256
        DIV256 = 0x9,
        /// CLK_RTC_CNT = GCLK_RTC/512
        DIV512 = 0xa,
        /// CLK_RTC_CNT = GCLK_RTC/1024
        DIV1024 = 0xb,
        _,
    };

    pub const RTC_MODE2_CTRLB__ACTF = enum(u3) {
        /// CLK_RTC_OUT = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_OUT = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_OUT = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_OUT = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_OUT = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_OUT = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_OUT = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_OUT = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE2_CTRLB__DEBF = enum(u3) {
        /// CLK_RTC_DEB = CLK_RTC/2
        DIV2 = 0x0,
        /// CLK_RTC_DEB = CLK_RTC/4
        DIV4 = 0x1,
        /// CLK_RTC_DEB = CLK_RTC/8
        DIV8 = 0x2,
        /// CLK_RTC_DEB = CLK_RTC/16
        DIV16 = 0x3,
        /// CLK_RTC_DEB = CLK_RTC/32
        DIV32 = 0x4,
        /// CLK_RTC_DEB = CLK_RTC/64
        DIV64 = 0x5,
        /// CLK_RTC_DEB = CLK_RTC/128
        DIV128 = 0x6,
        /// CLK_RTC_DEB = CLK_RTC/256
        DIV256 = 0x7,
    };

    pub const RTC_MODE2_TIMESTAMP__HOUR = enum(u5) {
        /// AM when CLKREP in 12-hour
        AM = 0x0,
        /// PM when CLKREP in 12-hour
        PM = 0x10,
        _,
    };

    pub const RTC_TAMPCTRL__IN0ACT = enum(u2) {
        /// Off (Disabled)
        OFF = 0x0,
        /// Wake without timestamp
        WAKE = 0x1,
        /// Capture timestamp
        CAPTURE = 0x2,
        /// Compare IN0 to OUT
        ACTL = 0x3,
    };

    pub const RTC_TAMPCTRL__IN1ACT = enum(u2) {
        /// Off (Disabled)
        OFF = 0x0,
        /// Wake without timestamp
        WAKE = 0x1,
        /// Capture timestamp
        CAPTURE = 0x2,
        /// Compare IN1 to OUT
        ACTL = 0x3,
    };

    pub const RTC_TAMPCTRL__IN2ACT = enum(u2) {
        /// Off (Disabled)
        OFF = 0x0,
        /// Wake without timestamp
        WAKE = 0x1,
        /// Capture timestamp
        CAPTURE = 0x2,
        /// Compare IN2 to OUT
        ACTL = 0x3,
    };

    pub const RTC_TAMPCTRL__IN3ACT = enum(u2) {
        /// Off (Disabled)
        OFF = 0x0,
        /// Wake without timestamp
        WAKE = 0x1,
        /// Capture timestamp
        CAPTURE = 0x2,
        /// Compare IN3 to OUT
        ACTL = 0x3,
    };

    pub const RTC_TAMPCTRL__IN4ACT = enum(u2) {
        /// Off (Disabled)
        OFF = 0x0,
        /// Wake without timestamp
        WAKE = 0x1,
        /// Capture timestamp
        CAPTURE = 0x2,
        /// Compare IN4 to OUT
        ACTL = 0x3,
    };

    MODE0: extern struct {
        /// MODE0 Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u16) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: RTC_MODE0_CTRLA__MODE,
            reserved7: u3 = 0,
            /// Clear on Match
            MATCHCLR: u1,
            /// Prescaler
            PRESCALER: RTC_MODE0_CTRLA__PRESCALER,
            reserved13: u1 = 0,
            /// BKUP Registers Reset On Tamper Enable
            BKTRST: u1,
            /// GP Registers Reset On Tamper Enable
            GPTRST: u1,
            /// Count Read Synchronization Enable
            COUNTSYNC: u1,
        }),
        /// MODE0 Control B
        /// offset: 0x02
        CTRLB: mmio.Mmio(packed struct(u16) {
            /// General Purpose 0 Enable
            GP0EN: u1,
            /// General Purpose 2 Enable
            GP2EN: u1,
            reserved4: u2 = 0,
            /// Debouncer Majority Enable
            DEBMAJ: u1,
            /// Debouncer Asynchronous Enable
            DEBASYNC: u1,
            /// RTC Output Enable
            RTCOUT: u1,
            /// DMA Enable
            DMAEN: u1,
            /// Debounce Freqnuency
            DEBF: RTC_MODE0_CTRLB__DEBF,
            reserved12: u1 = 0,
            /// Active Layer Freqnuency
            ACTF: RTC_MODE0_CTRLB__ACTF,
            padding: u1 = 0,
        }),
        /// MODE0 Event Control
        /// offset: 0x04
        EVCTRL: mmio.Mmio(packed struct(u32) {
            /// Periodic Interval 0 Event Output Enable
            PEREO0: u1,
            /// Periodic Interval 1 Event Output Enable
            PEREO1: u1,
            /// Periodic Interval 2 Event Output Enable
            PEREO2: u1,
            /// Periodic Interval 3 Event Output Enable
            PEREO3: u1,
            /// Periodic Interval 4 Event Output Enable
            PEREO4: u1,
            /// Periodic Interval 5 Event Output Enable
            PEREO5: u1,
            /// Periodic Interval 6 Event Output Enable
            PEREO6: u1,
            /// Periodic Interval 7 Event Output Enable
            PEREO7: u1,
            /// Compare 0 Event Output Enable
            CMPEO0: u1,
            /// Compare 1 Event Output Enable
            CMPEO1: u1,
            reserved14: u4 = 0,
            /// Tamper Event Output Enable
            TAMPEREO: u1,
            /// Overflow Event Output Enable
            OVFEO: u1,
            /// Tamper Event Input Enable
            TAMPEVEI: u1,
            padding: u15 = 0,
        }),
        /// MODE0 Interrupt Enable Clear
        /// offset: 0x08
        INTENCLR: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Interrupt Enable
            PER0: u1,
            /// Periodic Interval 1 Interrupt Enable
            PER1: u1,
            /// Periodic Interval 2 Interrupt Enable
            PER2: u1,
            /// Periodic Interval 3 Interrupt Enable
            PER3: u1,
            /// Periodic Interval 4 Interrupt Enable
            PER4: u1,
            /// Periodic Interval 5 Interrupt Enable
            PER5: u1,
            /// Periodic Interval 6 Interrupt Enable
            PER6: u1,
            /// Periodic Interval 7 Interrupt Enable
            PER7: u1,
            /// Compare 0 Interrupt Enable
            CMP0: u1,
            /// Compare 1 Interrupt Enable
            CMP1: u1,
            reserved14: u4 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE0 Interrupt Enable Set
        /// offset: 0x0a
        INTENSET: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Interrupt Enable
            PER0: u1,
            /// Periodic Interval 1 Interrupt Enable
            PER1: u1,
            /// Periodic Interval 2 Interrupt Enable
            PER2: u1,
            /// Periodic Interval 3 Interrupt Enable
            PER3: u1,
            /// Periodic Interval 4 Interrupt Enable
            PER4: u1,
            /// Periodic Interval 5 Interrupt Enable
            PER5: u1,
            /// Periodic Interval 6 Interrupt Enable
            PER6: u1,
            /// Periodic Interval 7 Interrupt Enable
            PER7: u1,
            /// Compare 0 Interrupt Enable
            CMP0: u1,
            /// Compare 1 Interrupt Enable
            CMP1: u1,
            reserved14: u4 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE0 Interrupt Flag Status and Clear
        /// offset: 0x0c
        INTFLAG: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0
            PER0: u1,
            /// Periodic Interval 1
            PER1: u1,
            /// Periodic Interval 2
            PER2: u1,
            /// Periodic Interval 3
            PER3: u1,
            /// Periodic Interval 4
            PER4: u1,
            /// Periodic Interval 5
            PER5: u1,
            /// Periodic Interval 6
            PER6: u1,
            /// Periodic Interval 7
            PER7: u1,
            /// Compare 0
            CMP0: u1,
            /// Compare 1
            CMP1: u1,
            reserved14: u4 = 0,
            /// Tamper
            TAMPER: u1,
            /// Overflow
            OVF: u1,
        }),
        /// Debug Control
        /// offset: 0x0e
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Run During Debug
            DBGRUN: u1,
            padding: u7 = 0,
        }),
        /// offset: 0x0f
        reserved15: [1]u8,
        /// MODE0 Synchronization Busy Status
        /// offset: 0x10
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Busy
            SWRST: u1,
            /// Enable Bit Busy
            ENABLE: u1,
            /// FREQCORR Register Busy
            FREQCORR: u1,
            /// COUNT Register Busy
            COUNT: u1,
            reserved5: u1 = 0,
            /// COMP 0 Register Busy
            COMP0: u1,
            /// COMP 1 Register Busy
            COMP1: u1,
            reserved15: u8 = 0,
            /// Count Synchronization Enable Bit Busy
            COUNTSYNC: u1,
            /// General Purpose 0 Register Busy
            GP0: u1,
            /// General Purpose 1 Register Busy
            GP1: u1,
            /// General Purpose 2 Register Busy
            GP2: u1,
            /// General Purpose 3 Register Busy
            GP3: u1,
            padding: u12 = 0,
        }),
        /// Frequency Correction
        /// offset: 0x14
        FREQCORR: mmio.Mmio(packed struct(u8) {
            /// Correction Value
            VALUE: u7,
            /// Correction Sign
            SIGN: u1,
        }),
        /// offset: 0x15
        reserved21: [3]u8,
        /// MODE0 Counter Value
        /// offset: 0x18
        COUNT: mmio.Mmio(packed struct(u32) {
            /// Counter Value
            COUNT: u32,
        }),
        /// offset: 0x1c
        reserved28: [4]u8,
        /// MODE0 Compare n Value
        /// offset: 0x20
        COMP: [2]mmio.Mmio(packed struct(u32) {
            /// Compare Value
            COMP: u32,
        }),
        /// offset: 0x28
        reserved40: [24]u8,
        /// General Purpose
        /// offset: 0x40
        GP: [4]mmio.Mmio(packed struct(u32) {
            /// General Purpose
            GP: u32,
        }),
        /// offset: 0x50
        reserved80: [16]u8,
        /// Tamper Control
        /// offset: 0x60
        TAMPCTRL: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Action
            IN0ACT: RTC_TAMPCTRL__IN0ACT,
            /// Tamper Input 1 Action
            IN1ACT: RTC_TAMPCTRL__IN1ACT,
            /// Tamper Input 2 Action
            IN2ACT: RTC_TAMPCTRL__IN2ACT,
            /// Tamper Input 3 Action
            IN3ACT: RTC_TAMPCTRL__IN3ACT,
            /// Tamper Input 4 Action
            IN4ACT: RTC_TAMPCTRL__IN4ACT,
            reserved16: u6 = 0,
            /// Tamper Level Select 0
            TAMLVL0: u1,
            /// Tamper Level Select 1
            TAMLVL1: u1,
            /// Tamper Level Select 2
            TAMLVL2: u1,
            /// Tamper Level Select 3
            TAMLVL3: u1,
            /// Tamper Level Select 4
            TAMLVL4: u1,
            reserved24: u3 = 0,
            /// Debouncer Enable 0
            DEBNC0: u1,
            /// Debouncer Enable 1
            DEBNC1: u1,
            /// Debouncer Enable 2
            DEBNC2: u1,
            /// Debouncer Enable 3
            DEBNC3: u1,
            /// Debouncer Enable 4
            DEBNC4: u1,
            padding: u3 = 0,
        }),
        /// MODE0 Timestamp
        /// offset: 0x64
        TIMESTAMP: mmio.Mmio(packed struct(u32) {
            /// Count Timestamp Value
            COUNT: u32,
        }),
        /// Tamper ID
        /// offset: 0x68
        TAMPID: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Detected
            TAMPID0: u1,
            /// Tamper Input 1 Detected
            TAMPID1: u1,
            /// Tamper Input 2 Detected
            TAMPID2: u1,
            /// Tamper Input 3 Detected
            TAMPID3: u1,
            /// Tamper Input 4 Detected
            TAMPID4: u1,
            reserved31: u26 = 0,
            /// Tamper Event Detected
            TAMPEVT: u1,
        }),
        /// offset: 0x6c
        reserved108: [20]u8,
        /// Backup
        /// offset: 0x80
        BKUP: [8]mmio.Mmio(packed struct(u32) {
            /// Backup
            BKUP: u32,
        }),
    },
    MODE1: extern struct {
        /// MODE1 Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u16) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: RTC_MODE1_CTRLA__MODE,
            reserved8: u4 = 0,
            /// Prescaler
            PRESCALER: RTC_MODE1_CTRLA__PRESCALER,
            reserved13: u1 = 0,
            /// BKUP Registers Reset On Tamper Enable
            BKTRST: u1,
            /// GP Registers Reset On Tamper Enable
            GPTRST: u1,
            /// Count Read Synchronization Enable
            COUNTSYNC: u1,
        }),
        /// MODE1 Control B
        /// offset: 0x02
        CTRLB: mmio.Mmio(packed struct(u16) {
            /// General Purpose 0 Enable
            GP0EN: u1,
            /// General Purpose 2 Enable
            GP2EN: u1,
            reserved4: u2 = 0,
            /// Debouncer Majority Enable
            DEBMAJ: u1,
            /// Debouncer Asynchronous Enable
            DEBASYNC: u1,
            /// RTC Output Enable
            RTCOUT: u1,
            /// DMA Enable
            DMAEN: u1,
            /// Debounce Freqnuency
            DEBF: RTC_MODE1_CTRLB__DEBF,
            reserved12: u1 = 0,
            /// Active Layer Freqnuency
            ACTF: RTC_MODE1_CTRLB__ACTF,
            padding: u1 = 0,
        }),
        /// MODE1 Event Control
        /// offset: 0x04
        EVCTRL: mmio.Mmio(packed struct(u32) {
            /// Periodic Interval 0 Event Output Enable
            PEREO0: u1,
            /// Periodic Interval 1 Event Output Enable
            PEREO1: u1,
            /// Periodic Interval 2 Event Output Enable
            PEREO2: u1,
            /// Periodic Interval 3 Event Output Enable
            PEREO3: u1,
            /// Periodic Interval 4 Event Output Enable
            PEREO4: u1,
            /// Periodic Interval 5 Event Output Enable
            PEREO5: u1,
            /// Periodic Interval 6 Event Output Enable
            PEREO6: u1,
            /// Periodic Interval 7 Event Output Enable
            PEREO7: u1,
            /// Compare 0 Event Output Enable
            CMPEO0: u1,
            /// Compare 1 Event Output Enable
            CMPEO1: u1,
            /// Compare 2 Event Output Enable
            CMPEO2: u1,
            /// Compare 3 Event Output Enable
            CMPEO3: u1,
            reserved14: u2 = 0,
            /// Tamper Event Output Enable
            TAMPEREO: u1,
            /// Overflow Event Output Enable
            OVFEO: u1,
            /// Tamper Event Input Enable
            TAMPEVEI: u1,
            padding: u15 = 0,
        }),
        /// MODE1 Interrupt Enable Clear
        /// offset: 0x08
        INTENCLR: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Interrupt Enable
            PER0: u1,
            /// Periodic Interval 1 Interrupt Enable
            PER1: u1,
            /// Periodic Interval 2 Interrupt Enable
            PER2: u1,
            /// Periodic Interval 3 Interrupt Enable
            PER3: u1,
            /// Periodic Interval 4 Interrupt Enable
            PER4: u1,
            /// Periodic Interval 5 Interrupt Enable
            PER5: u1,
            /// Periodic Interval 6 Interrupt Enable
            PER6: u1,
            /// Periodic Interval 7 Interrupt Enable
            PER7: u1,
            /// Compare 0 Interrupt Enable
            CMP0: u1,
            /// Compare 1 Interrupt Enable
            CMP1: u1,
            /// Compare 2 Interrupt Enable
            CMP2: u1,
            /// Compare 3 Interrupt Enable
            CMP3: u1,
            reserved14: u2 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE1 Interrupt Enable Set
        /// offset: 0x0a
        INTENSET: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Interrupt Enable
            PER0: u1,
            /// Periodic Interval 1 Interrupt Enable
            PER1: u1,
            /// Periodic Interval 2 Interrupt Enable
            PER2: u1,
            /// Periodic Interval 3 Interrupt Enable
            PER3: u1,
            /// Periodic Interval 4 Interrupt Enable
            PER4: u1,
            /// Periodic Interval 5 Interrupt Enable
            PER5: u1,
            /// Periodic Interval 6 Interrupt Enable
            PER6: u1,
            /// Periodic Interval 7 Interrupt Enable
            PER7: u1,
            /// Compare 0 Interrupt Enable
            CMP0: u1,
            /// Compare 1 Interrupt Enable
            CMP1: u1,
            /// Compare 2 Interrupt Enable
            CMP2: u1,
            /// Compare 3 Interrupt Enable
            CMP3: u1,
            reserved14: u2 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE1 Interrupt Flag Status and Clear
        /// offset: 0x0c
        INTFLAG: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0
            PER0: u1,
            /// Periodic Interval 1
            PER1: u1,
            /// Periodic Interval 2
            PER2: u1,
            /// Periodic Interval 3
            PER3: u1,
            /// Periodic Interval 4
            PER4: u1,
            /// Periodic Interval 5
            PER5: u1,
            /// Periodic Interval 6
            PER6: u1,
            /// Periodic Interval 7
            PER7: u1,
            /// Compare 0
            CMP0: u1,
            /// Compare 1
            CMP1: u1,
            /// Compare 2
            CMP2: u1,
            /// Compare 3
            CMP3: u1,
            reserved14: u2 = 0,
            /// Tamper
            TAMPER: u1,
            /// Overflow
            OVF: u1,
        }),
        /// Debug Control
        /// offset: 0x0e
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Run During Debug
            DBGRUN: u1,
            padding: u7 = 0,
        }),
        /// offset: 0x0f
        reserved15: [1]u8,
        /// MODE1 Synchronization Busy Status
        /// offset: 0x10
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Bit Busy
            SWRST: u1,
            /// Enable Bit Busy
            ENABLE: u1,
            /// FREQCORR Register Busy
            FREQCORR: u1,
            /// COUNT Register Busy
            COUNT: u1,
            /// PER Register Busy
            PER: u1,
            /// COMP 0 Register Busy
            COMP0: u1,
            /// COMP 1 Register Busy
            COMP1: u1,
            /// COMP 2 Register Busy
            COMP2: u1,
            /// COMP 3 Register Busy
            COMP3: u1,
            reserved15: u6 = 0,
            /// Count Synchronization Enable Bit Busy
            COUNTSYNC: u1,
            /// General Purpose 0 Register Busy
            GP0: u1,
            /// General Purpose 1 Register Busy
            GP1: u1,
            /// General Purpose 2 Register Busy
            GP2: u1,
            /// General Purpose 3 Register Busy
            GP3: u1,
            padding: u12 = 0,
        }),
        /// Frequency Correction
        /// offset: 0x14
        FREQCORR: mmio.Mmio(packed struct(u8) {
            /// Correction Value
            VALUE: u7,
            /// Correction Sign
            SIGN: u1,
        }),
        /// offset: 0x15
        reserved21: [3]u8,
        /// MODE1 Counter Value
        /// offset: 0x18
        COUNT: mmio.Mmio(packed struct(u16) {
            /// Counter Value
            COUNT: u16,
        }),
        /// offset: 0x1a
        reserved26: [2]u8,
        /// MODE1 Counter Period
        /// offset: 0x1c
        PER: mmio.Mmio(packed struct(u16) {
            /// Counter Period
            PER: u16,
        }),
        /// offset: 0x1e
        reserved30: [2]u8,
        /// MODE1 Compare n Value
        /// offset: 0x20
        COMP: [4]mmio.Mmio(packed struct(u16) {
            /// Compare Value
            COMP: u16,
        }),
        /// offset: 0x28
        reserved40: [24]u8,
        /// General Purpose
        /// offset: 0x40
        GP: [4]mmio.Mmio(packed struct(u32) {
            /// General Purpose
            GP: u32,
        }),
        /// offset: 0x50
        reserved80: [16]u8,
        /// Tamper Control
        /// offset: 0x60
        TAMPCTRL: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Action
            IN0ACT: RTC_TAMPCTRL__IN0ACT,
            /// Tamper Input 1 Action
            IN1ACT: RTC_TAMPCTRL__IN1ACT,
            /// Tamper Input 2 Action
            IN2ACT: RTC_TAMPCTRL__IN2ACT,
            /// Tamper Input 3 Action
            IN3ACT: RTC_TAMPCTRL__IN3ACT,
            /// Tamper Input 4 Action
            IN4ACT: RTC_TAMPCTRL__IN4ACT,
            reserved16: u6 = 0,
            /// Tamper Level Select 0
            TAMLVL0: u1,
            /// Tamper Level Select 1
            TAMLVL1: u1,
            /// Tamper Level Select 2
            TAMLVL2: u1,
            /// Tamper Level Select 3
            TAMLVL3: u1,
            /// Tamper Level Select 4
            TAMLVL4: u1,
            reserved24: u3 = 0,
            /// Debouncer Enable 0
            DEBNC0: u1,
            /// Debouncer Enable 1
            DEBNC1: u1,
            /// Debouncer Enable 2
            DEBNC2: u1,
            /// Debouncer Enable 3
            DEBNC3: u1,
            /// Debouncer Enable 4
            DEBNC4: u1,
            padding: u3 = 0,
        }),
        /// MODE1 Timestamp
        /// offset: 0x64
        TIMESTAMP: mmio.Mmio(packed struct(u32) {
            /// Count Timestamp Value
            COUNT: u16,
            padding: u16 = 0,
        }),
        /// Tamper ID
        /// offset: 0x68
        TAMPID: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Detected
            TAMPID0: u1,
            /// Tamper Input 1 Detected
            TAMPID1: u1,
            /// Tamper Input 2 Detected
            TAMPID2: u1,
            /// Tamper Input 3 Detected
            TAMPID3: u1,
            /// Tamper Input 4 Detected
            TAMPID4: u1,
            reserved31: u26 = 0,
            /// Tamper Event Detected
            TAMPEVT: u1,
        }),
        /// offset: 0x6c
        reserved108: [20]u8,
        /// Backup
        /// offset: 0x80
        BKUP: [8]mmio.Mmio(packed struct(u32) {
            /// Backup
            BKUP: u32,
        }),
    },
    MODE2: extern struct {
        /// MODE2 Control A
        /// offset: 0x00
        CTRLA: mmio.Mmio(packed struct(u16) {
            /// Software Reset
            SWRST: u1,
            /// Enable
            ENABLE: u1,
            /// Operating Mode
            MODE: RTC_MODE2_CTRLA__MODE,
            reserved6: u2 = 0,
            /// Clock Representation
            CLKREP: u1,
            /// Clear on Match
            MATCHCLR: u1,
            /// Prescaler
            PRESCALER: RTC_MODE2_CTRLA__PRESCALER,
            reserved13: u1 = 0,
            /// BKUP Registers Reset On Tamper Enable
            BKTRST: u1,
            /// GP Registers Reset On Tamper Enable
            GPTRST: u1,
            /// Clock Read Synchronization Enable
            CLOCKSYNC: u1,
        }),
        /// MODE2 Control B
        /// offset: 0x02
        CTRLB: mmio.Mmio(packed struct(u16) {
            /// General Purpose 0 Enable
            GP0EN: u1,
            /// General Purpose 2 Enable
            GP2EN: u1,
            reserved4: u2 = 0,
            /// Debouncer Majority Enable
            DEBMAJ: u1,
            /// Debouncer Asynchronous Enable
            DEBASYNC: u1,
            /// RTC Output Enable
            RTCOUT: u1,
            /// DMA Enable
            DMAEN: u1,
            /// Debounce Freqnuency
            DEBF: RTC_MODE2_CTRLB__DEBF,
            reserved12: u1 = 0,
            /// Active Layer Freqnuency
            ACTF: RTC_MODE2_CTRLB__ACTF,
            padding: u1 = 0,
        }),
        /// MODE2 Event Control
        /// offset: 0x04
        EVCTRL: mmio.Mmio(packed struct(u32) {
            /// Periodic Interval 0 Event Output Enable
            PEREO0: u1,
            /// Periodic Interval 1 Event Output Enable
            PEREO1: u1,
            /// Periodic Interval 2 Event Output Enable
            PEREO2: u1,
            /// Periodic Interval 3 Event Output Enable
            PEREO3: u1,
            /// Periodic Interval 4 Event Output Enable
            PEREO4: u1,
            /// Periodic Interval 5 Event Output Enable
            PEREO5: u1,
            /// Periodic Interval 6 Event Output Enable
            PEREO6: u1,
            /// Periodic Interval 7 Event Output Enable
            PEREO7: u1,
            /// Alarm 0 Event Output Enable
            ALARMEO0: u1,
            /// Alarm 1 Event Output Enable
            ALARMEO1: u1,
            reserved14: u4 = 0,
            /// Tamper Event Output Enable
            TAMPEREO: u1,
            /// Overflow Event Output Enable
            OVFEO: u1,
            /// Tamper Event Input Enable
            TAMPEVEI: u1,
            padding: u15 = 0,
        }),
        /// MODE2 Interrupt Enable Clear
        /// offset: 0x08
        INTENCLR: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Interrupt Enable
            PER0: u1,
            /// Periodic Interval 1 Interrupt Enable
            PER1: u1,
            /// Periodic Interval 2 Interrupt Enable
            PER2: u1,
            /// Periodic Interval 3 Interrupt Enable
            PER3: u1,
            /// Periodic Interval 4 Interrupt Enable
            PER4: u1,
            /// Periodic Interval 5 Interrupt Enable
            PER5: u1,
            /// Periodic Interval 6 Interrupt Enable
            PER6: u1,
            /// Periodic Interval 7 Interrupt Enable
            PER7: u1,
            /// Alarm 0 Interrupt Enable
            ALARM0: u1,
            /// Alarm 1 Interrupt Enable
            ALARM1: u1,
            reserved14: u4 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE2 Interrupt Enable Set
        /// offset: 0x0a
        INTENSET: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0 Enable
            PER0: u1,
            /// Periodic Interval 1 Enable
            PER1: u1,
            /// Periodic Interval 2 Enable
            PER2: u1,
            /// Periodic Interval 3 Enable
            PER3: u1,
            /// Periodic Interval 4 Enable
            PER4: u1,
            /// Periodic Interval 5 Enable
            PER5: u1,
            /// Periodic Interval 6 Enable
            PER6: u1,
            /// Periodic Interval 7 Enable
            PER7: u1,
            /// Alarm 0 Interrupt Enable
            ALARM0: u1,
            /// Alarm 1 Interrupt Enable
            ALARM1: u1,
            reserved14: u4 = 0,
            /// Tamper Enable
            TAMPER: u1,
            /// Overflow Interrupt Enable
            OVF: u1,
        }),
        /// MODE2 Interrupt Flag Status and Clear
        /// offset: 0x0c
        INTFLAG: mmio.Mmio(packed struct(u16) {
            /// Periodic Interval 0
            PER0: u1,
            /// Periodic Interval 1
            PER1: u1,
            /// Periodic Interval 2
            PER2: u1,
            /// Periodic Interval 3
            PER3: u1,
            /// Periodic Interval 4
            PER4: u1,
            /// Periodic Interval 5
            PER5: u1,
            /// Periodic Interval 6
            PER6: u1,
            /// Periodic Interval 7
            PER7: u1,
            /// Alarm 0
            ALARM0: u1,
            /// Alarm 1
            ALARM1: u1,
            reserved14: u4 = 0,
            /// Tamper
            TAMPER: u1,
            /// Overflow
            OVF: u1,
        }),
        /// Debug Control
        /// offset: 0x0e
        DBGCTRL: mmio.Mmio(packed struct(u8) {
            /// Run During Debug
            DBGRUN: u1,
            padding: u7 = 0,
        }),
        /// offset: 0x0f
        reserved15: [1]u8,
        /// MODE2 Synchronization Busy Status
        /// offset: 0x10
        SYNCBUSY: mmio.Mmio(packed struct(u32) {
            /// Software Reset Bit Busy
            SWRST: u1,
            /// Enable Bit Busy
            ENABLE: u1,
            /// FREQCORR Register Busy
            FREQCORR: u1,
            /// CLOCK Register Busy
            CLOCK: u1,
            reserved5: u1 = 0,
            /// ALARM 0 Register Busy
            ALARM0: u1,
            /// ALARM 1 Register Busy
            ALARM1: u1,
            reserved11: u4 = 0,
            /// MASK 0 Register Busy
            MASK0: u1,
            /// MASK 1 Register Busy
            MASK1: u1,
            reserved15: u2 = 0,
            /// Clock Synchronization Enable Bit Busy
            CLOCKSYNC: u1,
            /// General Purpose 0 Register Busy
            GP0: u1,
            /// General Purpose 1 Register Busy
            GP1: u1,
            /// General Purpose 2 Register Busy
            GP2: u1,
            /// General Purpose 3 Register Busy
            GP3: u1,
            padding: u12 = 0,
        }),
        /// Frequency Correction
        /// offset: 0x14
        FREQCORR: mmio.Mmio(packed struct(u8) {
            /// Correction Value
            VALUE: u7,
            /// Correction Sign
            SIGN: u1,
        }),
        /// offset: 0x15
        reserved21: [3]u8,
        /// MODE2 Clock Value
        /// offset: 0x18
        CLOCK: mmio.Mmio(packed struct(u32) {
            /// Second
            SECOND: u6,
            /// Minute
            MINUTE: u6,
            /// Hour
            HOUR: RTC_MODE2_CLOCK__HOUR,
            /// Day
            DAY: u5,
            /// Month
            MONTH: u4,
            /// Year
            YEAR: u6,
        }),
        /// offset: 0x1c
        reserved28: [4]u8,
        /// MODE2_ALARM Alarm n Value
        /// offset: 0x20
        ALARM0: mmio.Mmio(packed struct(u32) {
            /// Second
            SECOND: u6,
            /// Minute
            MINUTE: u6,
            /// Hour
            HOUR: RTC_MODE2_ALARM_ALARM__HOUR,
            /// Day
            DAY: u5,
            /// Month
            MONTH: u4,
            /// Year
            YEAR: u6,
        }),
        /// MODE2_ALARM Alarm n Mask
        /// offset: 0x24
        MASK0: mmio.Mmio(packed struct(u8) {
            /// Alarm Mask Selection
            SEL: RTC_MODE2_ALARM_MASK__SEL,
            padding: u5 = 0,
        }),
        /// offset: 0x25
        reserved37: [3]u8,
        /// MODE2_ALARM Alarm n Value
        /// offset: 0x28
        ALARM1: mmio.Mmio(packed struct(u32) {
            /// Second
            SECOND: u6,
            /// Minute
            MINUTE: u6,
            /// Hour
            HOUR: RTC_MODE2_ALARM_ALARM__HOUR,
            /// Day
            DAY: u5,
            /// Month
            MONTH: u4,
            /// Year
            YEAR: u6,
        }),
        /// MODE2_ALARM Alarm n Mask
        /// offset: 0x2c
        MASK1: mmio.Mmio(packed struct(u8) {
            /// Alarm Mask Selection
            SEL: RTC_MODE2_ALARM_MASK__SEL,
            padding: u5 = 0,
        }),
        /// offset: 0x2d
        reserved45: [19]u8,
        /// General Purpose
        /// offset: 0x40
        GP: [4]mmio.Mmio(packed struct(u32) {
            /// General Purpose
            GP: u32,
        }),
        /// offset: 0x50
        reserved80: [16]u8,
        /// Tamper Control
        /// offset: 0x60
        TAMPCTRL: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Action
            IN0ACT: RTC_TAMPCTRL__IN0ACT,
            /// Tamper Input 1 Action
            IN1ACT: RTC_TAMPCTRL__IN1ACT,
            /// Tamper Input 2 Action
            IN2ACT: RTC_TAMPCTRL__IN2ACT,
            /// Tamper Input 3 Action
            IN3ACT: RTC_TAMPCTRL__IN3ACT,
            /// Tamper Input 4 Action
            IN4ACT: RTC_TAMPCTRL__IN4ACT,
            reserved16: u6 = 0,
            /// Tamper Level Select 0
            TAMLVL0: u1,
            /// Tamper Level Select 1
            TAMLVL1: u1,
            /// Tamper Level Select 2
            TAMLVL2: u1,
            /// Tamper Level Select 3
            TAMLVL3: u1,
            /// Tamper Level Select 4
            TAMLVL4: u1,
            reserved24: u3 = 0,
            /// Debouncer Enable 0
            DEBNC0: u1,
            /// Debouncer Enable 1
            DEBNC1: u1,
            /// Debouncer Enable 2
            DEBNC2: u1,
            /// Debouncer Enable 3
            DEBNC3: u1,
            /// Debouncer Enable 4
            DEBNC4: u1,
            padding: u3 = 0,
        }),
        /// MODE2 Timestamp
        /// offset: 0x64
        TIMESTAMP: mmio.Mmio(packed struct(u32) {
            /// Second Timestamp Value
            SECOND: u6,
            /// Minute Timestamp Value
            MINUTE: u6,
            /// Hour Timestamp Value
            HOUR: RTC_MODE2_TIMESTAMP__HOUR,
            /// Day Timestamp Value
            DAY: u5,
            /// Month Timestamp Value
            MONTH: u4,
            /// Year Timestamp Value
            YEAR: u6,
        }),
        /// Tamper ID
        /// offset: 0x68
        TAMPID: mmio.Mmio(packed struct(u32) {
            /// Tamper Input 0 Detected
            TAMPID0: u1,
            /// Tamper Input 1 Detected
            TAMPID1: u1,
            /// Tamper Input 2 Detected
            TAMPID2: u1,
            /// Tamper Input 3 Detected
            TAMPID3: u1,
            /// Tamper Input 4 Detected
            TAMPID4: u1,
            reserved31: u26 = 0,
            /// Tamper Event Detected
            TAMPEVT: u1,
        }),
        /// offset: 0x6c
        reserved108: [20]u8,
        /// Backup
        /// offset: 0x80
        BKUP: [8]mmio.Mmio(packed struct(u32) {
            /// Backup
            BKUP: u32,
        }),
    },
};
