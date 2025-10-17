const microzig = @import("microzig");
const mmio = microzig.mmio;

const types = @import("../../types.zig");

pub const MCLK = extern struct {
    pub const MCLK_CPUDIV__DIV = enum(u8) {
        /// Divide by 1
        DIV1 = 0x1,
        /// Divide by 2
        DIV2 = 0x2,
        /// Divide by 4
        DIV4 = 0x4,
        /// Divide by 8
        DIV8 = 0x8,
        /// Divide by 16
        DIV16 = 0x10,
        /// Divide by 32
        DIV32 = 0x20,
        /// Divide by 64
        DIV64 = 0x40,
        /// Divide by 128
        DIV128 = 0x80,
        _,
    };

    pub const MCLK_HSDIV__DIV = enum(u8) {
        /// Divide by 1
        DIV1 = 0x1,
        _,
    };

    /// offset: 0x00
    reserved0: [1]u8,
    /// Interrupt Enable Clear
    /// offset: 0x01
    INTENCLR: mmio.Mmio(packed struct(u8) {
        /// Clock Ready Interrupt Enable
        CKRDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Enable Set
    /// offset: 0x02
    INTENSET: mmio.Mmio(packed struct(u8) {
        /// Clock Ready Interrupt Enable
        CKRDY: u1,
        padding: u7 = 0,
    }),
    /// Interrupt Flag Status and Clear
    /// offset: 0x03
    INTFLAG: mmio.Mmio(packed struct(u8) {
        /// Clock Ready
        CKRDY: u1,
        padding: u7 = 0,
    }),
    /// HS Clock Division
    /// offset: 0x04
    HSDIV: mmio.Mmio(packed struct(u8) {
        /// CPU Clock Division Factor
        DIV: MCLK_HSDIV__DIV,
    }),
    /// CPU Clock Division
    /// offset: 0x05
    CPUDIV: mmio.Mmio(packed struct(u8) {
        /// Low-Power Clock Division Factor
        DIV: MCLK_CPUDIV__DIV,
    }),
    /// offset: 0x06
    reserved6: [10]u8,
    /// AHB Mask
    /// offset: 0x10
    AHBMASK: mmio.Mmio(packed struct(u32) {
        /// HPB0 AHB Clock Mask
        HPB0_: u1,
        /// HPB1 AHB Clock Mask
        HPB1_: u1,
        /// HPB2 AHB Clock Mask
        HPB2_: u1,
        /// HPB3 AHB Clock Mask
        HPB3_: u1,
        /// DSU AHB Clock Mask
        DSU_: u1,
        /// HMATRIX AHB Clock Mask
        HMATRIX_: u1,
        /// NVMCTRL AHB Clock Mask
        NVMCTRL_: u1,
        /// HSRAM AHB Clock Mask
        HSRAM_: u1,
        /// CMCC AHB Clock Mask
        CMCC_: u1,
        /// DMAC AHB Clock Mask
        DMAC_: u1,
        /// USB AHB Clock Mask
        USB_: u1,
        /// BKUPRAM AHB Clock Mask
        BKUPRAM_: u1,
        /// PAC AHB Clock Mask
        PAC_: u1,
        /// QSPI AHB Clock Mask
        QSPI_: u1,
        reserved15: u1 = 0,
        /// SDHC0 AHB Clock Mask
        SDHC0_: u1,
        reserved19: u3 = 0,
        /// ICM AHB Clock Mask
        ICM_: u1,
        /// PUKCC AHB Clock Mask
        PUKCC_: u1,
        /// QSPI_2X AHB Clock Mask
        QSPI_2X_: u1,
        /// NVMCTRL_SMEEPROM AHB Clock Mask
        NVMCTRL_SMEEPROM_: u1,
        /// NVMCTRL_CACHE AHB Clock Mask
        NVMCTRL_CACHE_: u1,
        padding: u8 = 0,
    }),
    /// APBA Mask
    /// offset: 0x14
    APBAMASK: mmio.Mmio(packed struct(u32) {
        /// PAC APB Clock Enable
        PAC_: u1,
        /// PM APB Clock Enable
        PM_: u1,
        /// MCLK APB Clock Enable
        MCLK_: u1,
        /// RSTC APB Clock Enable
        RSTC_: u1,
        /// OSCCTRL APB Clock Enable
        OSCCTRL_: u1,
        /// OSC32KCTRL APB Clock Enable
        OSC32KCTRL_: u1,
        /// SUPC APB Clock Enable
        SUPC_: u1,
        /// GCLK APB Clock Enable
        GCLK_: u1,
        /// WDT APB Clock Enable
        WDT_: u1,
        /// RTC APB Clock Enable
        RTC_: u1,
        /// EIC APB Clock Enable
        EIC_: u1,
        /// FREQM APB Clock Enable
        FREQM_: u1,
        /// SERCOM0 APB Clock Enable
        SERCOM0_: u1,
        /// SERCOM1 APB Clock Enable
        SERCOM1_: u1,
        /// TC0 APB Clock Enable
        TC0_: u1,
        /// TC1 APB Clock Enable
        TC1_: u1,
        padding: u16 = 0,
    }),
    /// APBB Mask
    /// offset: 0x18
    APBBMASK: mmio.Mmio(packed struct(u32) {
        /// USB APB Clock Enable
        USB_: u1,
        /// DSU APB Clock Enable
        DSU_: u1,
        /// NVMCTRL APB Clock Enable
        NVMCTRL_: u1,
        reserved4: u1 = 0,
        /// PORT APB Clock Enable
        PORT_: u1,
        reserved6: u1 = 0,
        /// HMATRIX APB Clock Enable
        HMATRIX_: u1,
        /// EVSYS APB Clock Enable
        EVSYS_: u1,
        reserved9: u1 = 0,
        /// SERCOM2 APB Clock Enable
        SERCOM2_: u1,
        /// SERCOM3 APB Clock Enable
        SERCOM3_: u1,
        /// TCC0 APB Clock Enable
        TCC0_: u1,
        /// TCC1 APB Clock Enable
        TCC1_: u1,
        /// TC2 APB Clock Enable
        TC2_: u1,
        /// TC3 APB Clock Enable
        TC3_: u1,
        reserved16: u1 = 0,
        /// RAMECC APB Clock Enable
        RAMECC_: u1,
        padding: u15 = 0,
    }),
    /// APBC Mask
    /// offset: 0x1c
    APBCMASK: mmio.Mmio(packed struct(u32) {
        reserved3: u3 = 0,
        /// TCC2 APB Clock Enable
        TCC2_: u1,
        /// TCC3 APB Clock Enable
        TCC3_: u1,
        /// TC4 APB Clock Enable
        TC4_: u1,
        /// TC5 APB Clock Enable
        TC5_: u1,
        /// PDEC APB Clock Enable
        PDEC_: u1,
        /// AC APB Clock Enable
        AC_: u1,
        /// AES APB Clock Enable
        AES_: u1,
        /// TRNG APB Clock Enable
        TRNG_: u1,
        /// ICM APB Clock Enable
        ICM_: u1,
        reserved13: u1 = 0,
        /// QSPI APB Clock Enable
        QSPI_: u1,
        /// CCL APB Clock Enable
        CCL_: u1,
        padding: u17 = 0,
    }),
    /// APBD Mask
    /// offset: 0x20
    APBDMASK: mmio.Mmio(packed struct(u32) {
        /// SERCOM4 APB Clock Enable
        SERCOM4_: u1,
        /// SERCOM5 APB Clock Enable
        SERCOM5_: u1,
        reserved4: u2 = 0,
        /// TCC4 APB Clock Enable
        TCC4_: u1,
        reserved7: u2 = 0,
        /// ADC0 APB Clock Enable
        ADC0_: u1,
        /// ADC1 APB Clock Enable
        ADC1_: u1,
        /// DAC APB Clock Enable
        DAC_: u1,
        /// I2S APB Clock Enable
        I2S_: u1,
        /// PCC APB Clock Enable
        PCC_: u1,
        padding: u20 = 0,
    }),
};
