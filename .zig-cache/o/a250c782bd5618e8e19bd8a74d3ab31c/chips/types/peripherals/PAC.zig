const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const PAC = extern struct {
    pub const PAC_WRCTRL__KEY = enum(u8) {
        /// No action
        OFF = 0x0,
        /// Clear protection
        CLR = 0x1,
        /// Set protection
        SET = 0x2,
        /// Set and lock protection
        SETLCK = 0x3,
        _,
    };

    /// Write control
    /// offset: 0x00
    WRCTRL: mmio.Mmio(packed struct(u32) {
        /// Peripheral identifier
        PERID: u16,
        /// Peripheral access control key
        KEY: PAC_WRCTRL__KEY,
        padding: u8 = 0,
    }),
    /// Event control
    /// offset: 0x04
    EVCTRL: mmio.Mmio(packed struct(u8) {
        /// Peripheral acess error event output
        ERREO: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x05
    reserved5: [3]u8,
    /// Interrupt enable clear
    /// offset: 0x08
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Peripheral access error interrupt disable
        ERR: u1,
        padding: u7 = 0,
    }),
    /// Interrupt enable set
    /// offset: 0x09
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Peripheral access error interrupt enable
        ERR: u1,
        padding: u7 = 0,
    }),
    /// offset: 0x0a
    reserved10: [6]u8,
    /// Bridge interrupt flag status
    /// offset: 0x10
    INTFLAGAHB: mmio.Mmio(packed struct(u32) {
        /// FLASH
        FLASH_: u1,
        /// FLASH_ALT
        FLASH_ALT_: u1,
        /// SEEPROM
        SEEPROM_: u1,
        /// RAMCM4S
        RAMCM4S_: u1,
        /// RAMPPPDSU
        RAMPPPDSU_: u1,
        /// RAMDMAWR
        RAMDMAWR_: u1,
        /// RAMDMACICM
        RAMDMACICM_: u1,
        /// HPB0
        HPB0_: u1,
        /// HPB1
        HPB1_: u1,
        /// HPB2
        HPB2_: u1,
        /// HPB3
        HPB3_: u1,
        /// PUKCC
        PUKCC_: u1,
        /// SDHC0
        SDHC0_: u1,
        reserved14: u1 = 0,
        /// QSPI
        QSPI_: u1,
        /// BKUPRAM
        BKUPRAM_: u1,
        padding: u16 = 0,
    }),
    /// Peripheral interrupt flag status - Bridge A
    /// offset: 0x14
    INTFLAGA: mmio.Mmio(packed struct(u32) {
        /// PAC
        PAC_: u1,
        /// PM
        PM_: u1,
        /// MCLK
        MCLK_: u1,
        /// RSTC
        RSTC_: u1,
        /// OSCCTRL
        OSCCTRL_: u1,
        /// OSC32KCTRL
        OSC32KCTRL_: u1,
        /// SUPC
        SUPC_: u1,
        /// GCLK
        GCLK_: u1,
        /// WDT
        WDT_: u1,
        /// RTC
        RTC_: u1,
        /// EIC
        EIC_: u1,
        /// FREQM
        FREQM_: u1,
        /// SERCOM0
        SERCOM0_: u1,
        /// SERCOM1
        SERCOM1_: u1,
        /// TC0
        TC0_: u1,
        /// TC1
        TC1_: u1,
        padding: u16 = 0,
    }),
    /// Peripheral interrupt flag status - Bridge B
    /// offset: 0x18
    INTFLAGB: mmio.Mmio(packed struct(u32) {
        /// USB
        USB_: u1,
        /// DSU
        DSU_: u1,
        /// NVMCTRL
        NVMCTRL_: u1,
        /// CMCC
        CMCC_: u1,
        /// PORT
        PORT_: u1,
        /// DMAC
        DMAC_: u1,
        /// HMATRIX
        HMATRIX_: u1,
        /// EVSYS
        EVSYS_: u1,
        reserved9: u1 = 0,
        /// SERCOM2
        SERCOM2_: u1,
        /// SERCOM3
        SERCOM3_: u1,
        /// TCC0
        TCC0_: u1,
        /// TCC1
        TCC1_: u1,
        /// TC2
        TC2_: u1,
        /// TC3
        TC3_: u1,
        reserved16: u1 = 0,
        /// RAMECC
        RAMECC_: u1,
        padding: u15 = 0,
    }),
    /// Peripheral interrupt flag status - Bridge C
    /// offset: 0x1c
    INTFLAGC: mmio.Mmio(packed struct(u32) {
        reserved3: u3 = 0,
        /// TCC2
        TCC2_: u1,
        /// TCC3
        TCC3_: u1,
        /// TC4
        TC4_: u1,
        /// TC5
        TC5_: u1,
        /// PDEC
        PDEC_: u1,
        /// AC
        AC_: u1,
        /// AES
        AES_: u1,
        /// TRNG
        TRNG_: u1,
        /// ICM
        ICM_: u1,
        /// PUKCC
        PUKCC_: u1,
        /// QSPI
        QSPI_: u1,
        /// CCL
        CCL_: u1,
        padding: u17 = 0,
    }),
    /// Peripheral interrupt flag status - Bridge D
    /// offset: 0x20
    INTFLAGD: mmio.Mmio(packed struct(u32) {
        /// SERCOM4
        SERCOM4_: u1,
        /// SERCOM5
        SERCOM5_: u1,
        reserved4: u2 = 0,
        /// TCC4
        TCC4_: u1,
        reserved7: u2 = 0,
        /// ADC0
        ADC0_: u1,
        /// ADC1
        ADC1_: u1,
        /// DAC
        DAC_: u1,
        /// I2S
        I2S_: u1,
        /// PCC
        PCC_: u1,
        padding: u20 = 0,
    }),
    /// offset: 0x24
    reserved36: [16]u8,
    /// Peripheral write protection status - Bridge A
    /// offset: 0x34
    STATUSA: mmio.Mmio(packed struct(u32) {
        /// PAC APB Protect Enable
        PAC_: u1,
        /// PM APB Protect Enable
        PM_: u1,
        /// MCLK APB Protect Enable
        MCLK_: u1,
        /// RSTC APB Protect Enable
        RSTC_: u1,
        /// OSCCTRL APB Protect Enable
        OSCCTRL_: u1,
        /// OSC32KCTRL APB Protect Enable
        OSC32KCTRL_: u1,
        /// SUPC APB Protect Enable
        SUPC_: u1,
        /// GCLK APB Protect Enable
        GCLK_: u1,
        /// WDT APB Protect Enable
        WDT_: u1,
        /// RTC APB Protect Enable
        RTC_: u1,
        /// EIC APB Protect Enable
        EIC_: u1,
        /// FREQM APB Protect Enable
        FREQM_: u1,
        /// SERCOM0 APB Protect Enable
        SERCOM0_: u1,
        /// SERCOM1 APB Protect Enable
        SERCOM1_: u1,
        /// TC0 APB Protect Enable
        TC0_: u1,
        /// TC1 APB Protect Enable
        TC1_: u1,
        padding: u16 = 0,
    }),
    /// Peripheral write protection status - Bridge B
    /// offset: 0x38
    STATUSB: mmio.Mmio(packed struct(u32) {
        /// USB APB Protect Enable
        USB_: u1,
        /// DSU APB Protect Enable
        DSU_: u1,
        /// NVMCTRL APB Protect Enable
        NVMCTRL_: u1,
        /// CMCC APB Protect Enable
        CMCC_: u1,
        /// PORT APB Protect Enable
        PORT_: u1,
        /// DMAC APB Protect Enable
        DMAC_: u1,
        /// HMATRIX APB Protect Enable
        HMATRIX_: u1,
        /// EVSYS APB Protect Enable
        EVSYS_: u1,
        reserved9: u1 = 0,
        /// SERCOM2 APB Protect Enable
        SERCOM2_: u1,
        /// SERCOM3 APB Protect Enable
        SERCOM3_: u1,
        /// TCC0 APB Protect Enable
        TCC0_: u1,
        /// TCC1 APB Protect Enable
        TCC1_: u1,
        /// TC2 APB Protect Enable
        TC2_: u1,
        /// TC3 APB Protect Enable
        TC3_: u1,
        reserved16: u1 = 0,
        /// RAMECC APB Protect Enable
        RAMECC_: u1,
        padding: u15 = 0,
    }),
    /// Peripheral write protection status - Bridge C
    /// offset: 0x3c
    STATUSC: mmio.Mmio(packed struct(u32) {
        reserved3: u3 = 0,
        /// TCC2 APB Protect Enable
        TCC2_: u1,
        /// TCC3 APB Protect Enable
        TCC3_: u1,
        /// TC4 APB Protect Enable
        TC4_: u1,
        /// TC5 APB Protect Enable
        TC5_: u1,
        /// PDEC APB Protect Enable
        PDEC_: u1,
        /// AC APB Protect Enable
        AC_: u1,
        /// AES APB Protect Enable
        AES_: u1,
        /// TRNG APB Protect Enable
        TRNG_: u1,
        /// ICM APB Protect Enable
        ICM_: u1,
        /// PUKCC APB Protect Enable
        PUKCC_: u1,
        /// QSPI APB Protect Enable
        QSPI_: u1,
        /// CCL APB Protect Enable
        CCL_: u1,
        padding: u17 = 0,
    }),
    /// Peripheral write protection status - Bridge D
    /// offset: 0x40
    STATUSD: mmio.Mmio(packed struct(u32) {
        /// SERCOM4 APB Protect Enable
        SERCOM4_: u1,
        /// SERCOM5 APB Protect Enable
        SERCOM5_: u1,
        reserved4: u2 = 0,
        /// TCC4 APB Protect Enable
        TCC4_: u1,
        reserved7: u2 = 0,
        /// ADC0 APB Protect Enable
        ADC0_: u1,
        /// ADC1 APB Protect Enable
        ADC1_: u1,
        /// DAC APB Protect Enable
        DAC_: u1,
        /// I2S APB Protect Enable
        I2S_: u1,
        /// PCC APB Protect Enable
        PCC_: u1,
        padding: u20 = 0,
    }),
};
