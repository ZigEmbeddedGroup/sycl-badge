const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

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

pub const SUPC_BOD33__ACTION = enum(u2) {
    /// No action
    NONE = 0x0,
    /// The BOD33 generates a reset
    RESET = 0x1,
    /// The BOD33 generates an interrupt
    INT = 0x2,
    /// The BOD33 puts the device in backup sleep mode
    BKUP = 0x3,
};

pub const WDT_CONFIG__PER = enum(u4) {
    /// 8 clock cycles
    CYC8 = 0x0,
    /// 16 clock cycles
    CYC16 = 0x1,
    /// 32 clock cycles
    CYC32 = 0x2,
    /// 64 clock cycles
    CYC64 = 0x3,
    /// 128 clock cycles
    CYC128 = 0x4,
    /// 256 clock cycles
    CYC256 = 0x5,
    /// 512 clock cycles
    CYC512 = 0x6,
    /// 1024 clock cycles
    CYC1024 = 0x7,
    /// 2048 clock cycles
    CYC2048 = 0x8,
    /// 4096 clock cycles
    CYC4096 = 0x9,
    /// 8192 clock cycles
    CYC8192 = 0xa,
    /// 16384 clock cycles
    CYC16384 = 0xb,
    _,
};

pub const WDT_CONFIG__WINDOW = enum(u4) {
    /// 8 clock cycles
    CYC8 = 0x0,
    /// 16 clock cycles
    CYC16 = 0x1,
    /// 32 clock cycles
    CYC32 = 0x2,
    /// 64 clock cycles
    CYC64 = 0x3,
    /// 128 clock cycles
    CYC128 = 0x4,
    /// 256 clock cycles
    CYC256 = 0x5,
    /// 512 clock cycles
    CYC512 = 0x6,
    /// 1024 clock cycles
    CYC1024 = 0x7,
    /// 2048 clock cycles
    CYC2048 = 0x8,
    /// 4096 clock cycles
    CYC4096 = 0x9,
    /// 8192 clock cycles
    CYC8192 = 0xa,
    /// 16384 clock cycles
    CYC16384 = 0xb,
    _,
};

pub const WDT_EWCTRL__EWOFFSET = enum(u4) {
    /// 8 clock cycles
    CYC8 = 0x0,
    /// 16 clock cycles
    CYC16 = 0x1,
    /// 32 clock cycles
    CYC32 = 0x2,
    /// 64 clock cycles
    CYC64 = 0x3,
    /// 128 clock cycles
    CYC128 = 0x4,
    /// 256 clock cycles
    CYC256 = 0x5,
    /// 512 clock cycles
    CYC512 = 0x6,
    /// 1024 clock cycles
    CYC1024 = 0x7,
    /// 2048 clock cycles
    CYC2048 = 0x8,
    /// 4096 clock cycles
    CYC4096 = 0x9,
    /// 8192 clock cycles
    CYC8192 = 0xa,
    /// 16384 clock cycles
    CYC16384 = 0xb,
    _,
};

pub const SW0_FUSES = extern struct {
    /// SW0 Page Word 0
    /// offset: 0x00
    SW0_WORD_0: mmio.Mmio(packed struct(u32) {
        /// PAIR0 Bias Calibration
        AC_BIAS0: u2,
        /// ADC Comparator Scaling
        ADC0_BIASCOMP: u3,
        /// ADC Bias Reference Buffer Scaling
        ADC0_BIASREFBUF: u3,
        /// ADC Bias R2R ampli scaling
        ADC0_BIASR2R: u3,
        reserved16: u5 = 0,
        /// ADC Comparator Scaling
        ADC1_BIASCOMP: u3,
        /// ADC Bias Reference Buffer Scaling
        ADC1_BIASREFBUF: u3,
        /// ADC Bias R2R ampli scaling
        ADC1_BIASR2R: u3,
        padding: u7 = 0,
    }),
    /// SW0 Page Word 1
    /// offset: 0x04
    SW0_WORD_1: mmio.Mmio(packed struct(u32) {
        /// USB pad Transn calibration
        USB_TRANSN: u5,
        /// USB pad Transp calibration
        USB_TRANSP: u5,
        /// USB pad Trim calibration
        USB_TRIM: u3,
        padding: u19 = 0,
    }),
};

pub const TEMP_LOG_FUSES = extern struct {
    /// TEMP_LOG Page Word 0
    /// offset: 0x00
    TEMP_LOG_WORD_0: mmio.Mmio(packed struct(u32) {
        /// Integer part of room temperature in oC
        ROOM_TEMP_VAL_INT: u8,
        /// Decimal part of room temperature
        ROOM_TEMP_VAL_DEC: u4,
        /// Integer part of hot temperature in oC
        HOT_TEMP_VAL_INT: u8,
        /// Decimal part of hot temperature
        HOT_TEMP_VAL_DEC: u4,
        /// 2's complement of the internal 1V reference drift at room temperature (versus a 1.0 centered value)
        ROOM_INT1V_VAL: u8,
    }),
    /// TEMP_LOG Page Word 1
    /// offset: 0x04
    TEMP_LOG_WORD_1: mmio.Mmio(packed struct(u32) {
        /// 2's complement of the internal 1V reference drift at hot temperature (versus a 1.0 centered value)
        HOT_INT1V_VAL: u8,
        /// 12-bit ADC conversion at room temperature PTAT
        ROOM_ADC_VAL_PTAT: u12,
        /// 12-bit ADC conversion at hot temperature PTAT
        HOT_ADC_VAL_PTAT: u12,
    }),
    /// TEMP_LOG Page Word 2
    /// offset: 0x08
    TEMP_LOG_WORD_2: mmio.Mmio(packed struct(u32) {
        /// 12-bit ADC conversion at room temperature CTAT
        ROOM_ADC_VAL_CTAT: u12,
        /// 12-bit ADC conversion at hot temperature CTAT
        HOT_ADC_VAL_CTAT: u12,
        padding: u8 = 0,
    }),
};

pub const USER_FUSES = extern struct {
    /// USER Page Word 0
    /// offset: 0x00
    USER_WORD_0: mmio.Mmio(packed struct(u32) {
        /// BOD33 Disable
        BOD33_DIS: u1,
        /// BOD33 User Level
        BOD33USERLEVEL: u8,
        /// BOD33 Action
        BOD33_ACTION: SUPC_BOD33__ACTION,
        /// BOD33 Hysteresis
        BOD33_HYST: u4,
        reserved26: u11 = 0,
        /// Bootloader Size
        NVMCTRL_BOOTPROT: NVMCTRL_STATUS__BOOTPROT,
        padding: u2 = 0,
    }),
    /// USER Page Word 1
    /// offset: 0x04
    USER_WORD_1: mmio.Mmio(packed struct(u32) {
        /// Number Of Physical NVM Blocks Composing a SmartEEPROM Sector
        NVMCTRL_SEESBLK: u4,
        /// Size Of SmartEEPROM Page
        NVMCTRL_SEEPSZ: u3,
        /// RAM ECC Disable fuse
        RAMECC_ECCDIS: u1,
        reserved16: u8 = 0,
        /// WDT Enable
        WDT_ENABLE: u1,
        /// WDT Always On
        WDT_ALWAYSON: u1,
        /// WDT Period
        WDT_PER: WDT_CONFIG__PER,
        /// WDT Window
        WDT_WINDOW: WDT_CONFIG__WINDOW,
        /// WDT Early Warning Offset
        WDT_EWOFFSET: WDT_EWCTRL__EWOFFSET,
        /// WDT Window Mode Enable
        WDT_WEN: u1,
        padding: u1 = 0,
    }),
    /// USER Page Word 2
    /// offset: 0x08
    USER_WORD_2: mmio.Mmio(packed struct(u32) {
        /// NVM Region Locks
        NVMCTRL_REGION_LOCKS: u32,
    }),
};
