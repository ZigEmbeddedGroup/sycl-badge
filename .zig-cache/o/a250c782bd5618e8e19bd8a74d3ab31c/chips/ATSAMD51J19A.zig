const microzig = @import("microzig");
const mmio = microzig.mmio;

pub const types = @import("types.zig");

pub const Interrupt = struct {
    name: [:0]const u8,
    index: i16,
    description: ?[:0]const u8,
};

pub const properties = struct {
    pub const GCLK_ID_TRACE = "47";
    pub const NUM_IRQ = "137";
    pub const __ARCH_ARM = "1";
    pub const __ARCH_ARM_CORTEX_M = "1";
    pub const __CM4_REV = "0x0001";
    pub const __DEBUG_LVL = "3";
    pub const __DEVICE_IS_SAM = "1";
    pub const __FPU_PRESENT = "1";
    pub const __MPU_PRESENT = "1";
    pub const __NVIC_PRIO_BITS = "3";
    pub const __TRACE_LVL = "2";
    pub const __VTOR_PRESENT = "1";
    pub const __Vendor_SysTickConfig = "0";
    pub const family = "SAMD";
    pub const series = "SAMD51";
};

pub const interrupts: []const Interrupt = &.{
    .{ .name = "Reset", .index = -15, .description = "Reset Vector, invoked on Power up and warm reset" },
    .{ .name = "NonMaskableInt", .index = -14, .description = "Non maskable Interrupt, cannot be stopped or preempted" },
    .{ .name = "HardFault", .index = -13, .description = "Hard Fault, all classes of Fault" },
    .{ .name = "MemoryManagement", .index = -12, .description = "Memory Management, MPU mismatch, including Access Violation and No Match" },
    .{ .name = "BusFault", .index = -11, .description = "Bus Fault, Pre-Fetch-, Memory Access Fault, other address/memory related Fault" },
    .{ .name = "UsageFault", .index = -10, .description = "Usage Fault, i.e. Undef Instruction, Illegal State Transition" },
    .{ .name = "SVCall", .index = -5, .description = "System Service Call via SVC instruction" },
    .{ .name = "DebugMonitor", .index = -4, .description = "Debug Monitor" },
    .{ .name = "PendSV", .index = -2, .description = "Pendable request for system service" },
    .{ .name = "SysTick", .index = -1, .description = "System Tick Timer" },
    .{ .name = "PM_PM", .index = 0, .description = "Power Manager" },
    .{ .name = "MCLK_MCLK", .index = 1, .description = "Main Clock" },
    .{ .name = "OSCCTRL_OSCCTRL_XOSC0", .index = 2, .description = "External Oscillator 0" },
    .{ .name = "OSCCTRL_OSCCTRL_XOSC1", .index = 3, .description = "External Oscillator 1" },
    .{ .name = "OSCCTRL_OSCCTRL_DFLL", .index = 4, .description = "Digital Frequency Locked Loop" },
    .{ .name = "OSCCTRL_OSCCTRL_DPLL0", .index = 5, .description = "Digital Phase Locked Loop 0" },
    .{ .name = "OSCCTRL_OSCCTRL_DPLL1", .index = 6, .description = "Digital Phase Locked Loop 1" },
    .{ .name = "OSC32KCTRL_OSC32KCTRL", .index = 7, .description = "32Khz Oscillator Controller" },
    .{ .name = "SUPC_SUPC_OTHER", .index = 8, .description = "Suppyly controller" },
    .{ .name = "SUPC_SUPC_BODDET", .index = 9, .description = "Brown Out Detection" },
    .{ .name = "WDT_WDT", .index = 10, .description = "Watch Dog Timer" },
    .{ .name = "RTC_RTC", .index = 11, .description = "Real Time Counter" },
    .{ .name = "EIC_EIC_EXTINT_0", .index = 12, .description = "EIC Channel 0" },
    .{ .name = "EIC_EIC_EXTINT_1", .index = 13, .description = "EIC Channel 1" },
    .{ .name = "EIC_EIC_EXTINT_2", .index = 14, .description = "EIC Channel 2" },
    .{ .name = "EIC_EIC_EXTINT_3", .index = 15, .description = "EIC Channel 3" },
    .{ .name = "EIC_EIC_EXTINT_4", .index = 16, .description = "EIC Channel 4" },
    .{ .name = "EIC_EIC_EXTINT_5", .index = 17, .description = "EIC Channel 5" },
    .{ .name = "EIC_EIC_EXTINT_6", .index = 18, .description = "EIC Channel 6" },
    .{ .name = "EIC_EIC_EXTINT_7", .index = 19, .description = "EIC Channel 7" },
    .{ .name = "EIC_EIC_EXTINT_8", .index = 20, .description = "EIC Channel 8" },
    .{ .name = "EIC_EIC_EXTINT_9", .index = 21, .description = "EIC Channel 9" },
    .{ .name = "EIC_EIC_EXTINT_10", .index = 22, .description = "EIC Channel 10" },
    .{ .name = "EIC_EIC_EXTINT_11", .index = 23, .description = "EIC Channel 11" },
    .{ .name = "EIC_EIC_EXTINT_12", .index = 24, .description = "EIC Channel 12" },
    .{ .name = "EIC_EIC_EXTINT_13", .index = 25, .description = "EIC Channel 13" },
    .{ .name = "EIC_EIC_EXTINT_14", .index = 26, .description = "EIC Channel 14" },
    .{ .name = "EIC_EIC_EXTINT_15", .index = 27, .description = "EIC Channel 15" },
    .{ .name = "FREQM_FREQM", .index = 28, .description = "Frequency Meter" },
    .{ .name = "NVMCTRL_NVMCTRL_0", .index = 29, .description = "Non-Volatile Memory Controller" },
    .{ .name = "NVMCTRL_NVMCTRL_1", .index = 30, .description = "NVMCTRL SmartEEPROM Interrupts" },
    .{ .name = "DMAC_DMAC_0", .index = 31, .description = "DMA Channel 0" },
    .{ .name = "DMAC_DMAC_1", .index = 32, .description = "DMA Channel 1" },
    .{ .name = "DMAC_DMAC_2", .index = 33, .description = "DMA Channel 2" },
    .{ .name = "DMAC_DMAC_3", .index = 34, .description = "DMA Channel 3" },
    .{ .name = "DMAC_DMAC_OTHER", .index = 35, .description = "DMA Channel 4..X" },
    .{ .name = "EVSYS_EVSYS_0", .index = 36, .description = "Event System Channel 0" },
    .{ .name = "EVSYS_EVSYS_1", .index = 37, .description = "Event System Channel 1" },
    .{ .name = "EVSYS_EVSYS_2", .index = 38, .description = "Event System Channel 2" },
    .{ .name = "EVSYS_EVSYS_3", .index = 39, .description = "Event System Channel 3" },
    .{ .name = "EVSYS_EVSYS_OTHER", .index = 40, .description = "Event System Channel 4..X" },
    .{ .name = "PAC_PAC", .index = 41, .description = "Peripheral Access Controller" },
    .{ .name = "RAMECC_RAMECC", .index = 45, .description = "RAM Error Correction Code" },
    .{ .name = "SERCOM0_SERCOM0_0", .index = 46, .description = "Serial Communication Interface 0" },
    .{ .name = "SERCOM0_SERCOM0_1", .index = 47, .description = "Serial Communication Interface 0" },
    .{ .name = "SERCOM0_SERCOM0_2", .index = 48, .description = "Serial Communication Interface 0" },
    .{ .name = "SERCOM0_SERCOM0_OTHER", .index = 49, .description = "Serial Communication Interface 0" },
    .{ .name = "SERCOM1_SERCOM1_0", .index = 50, .description = "Serial Communication Interface 1" },
    .{ .name = "SERCOM1_SERCOM1_1", .index = 51, .description = "Serial Communication Interface 1" },
    .{ .name = "SERCOM1_SERCOM1_2", .index = 52, .description = "Serial Communication Interface 1" },
    .{ .name = "SERCOM1_SERCOM1_OTHER", .index = 53, .description = "Serial Communication Interface 1" },
    .{ .name = "SERCOM2_SERCOM2_0", .index = 54, .description = "Serial Communication Interface 2" },
    .{ .name = "SERCOM2_SERCOM2_1", .index = 55, .description = "Serial Communication Interface 2" },
    .{ .name = "SERCOM2_SERCOM2_2", .index = 56, .description = "Serial Communication Interface 2" },
    .{ .name = "SERCOM2_SERCOM2_OTHER", .index = 57, .description = "Serial Communication Interface 2" },
    .{ .name = "SERCOM3_SERCOM3_0", .index = 58, .description = "Serial Communication Interface 3" },
    .{ .name = "SERCOM3_SERCOM3_1", .index = 59, .description = "Serial Communication Interface 3" },
    .{ .name = "SERCOM3_SERCOM3_2", .index = 60, .description = "Serial Communication Interface 3" },
    .{ .name = "SERCOM3_SERCOM3_OTHER", .index = 61, .description = "Serial Communication Interface 3" },
    .{ .name = "SERCOM4_SERCOM4_0", .index = 62, .description = "Serial Communication Interface 4" },
    .{ .name = "SERCOM4_SERCOM4_1", .index = 63, .description = "Serial Communication Interface 4" },
    .{ .name = "SERCOM4_SERCOM4_2", .index = 64, .description = "Serial Communication Interface 4" },
    .{ .name = "SERCOM4_SERCOM4_OTHER", .index = 65, .description = "Serial Communication Interface 4" },
    .{ .name = "SERCOM5_SERCOM5_0", .index = 66, .description = "Serial Communication Interface 5" },
    .{ .name = "SERCOM5_SERCOM5_1", .index = 67, .description = "Serial Communication Interface 5" },
    .{ .name = "SERCOM5_SERCOM5_2", .index = 68, .description = "Serial Communication Interface 5" },
    .{ .name = "SERCOM5_SERCOM5_OTHER", .index = 69, .description = "Serial Communication Interface 5" },
    .{ .name = "USB_USB_OTHER", .index = 80, .description = "Universal Serial Bus" },
    .{ .name = "USB_USB_SOF_HSOF", .index = 81, .description = "USB Start of Frame" },
    .{ .name = "USB_USB_TRCPT0", .index = 82, .description = "USB Transfer Complete 0" },
    .{ .name = "USB_USB_TRCPT1", .index = 83, .description = "USB Transfer Complete 1" },
    .{ .name = "TCC0_TCC0_OTHER", .index = 85, .description = "Timer Counter Control 0" },
    .{ .name = "TCC0_TCC0_MC0", .index = 86, .description = "TCC Match/Compare 0" },
    .{ .name = "TCC0_TCC0_MC1", .index = 87, .description = "TCC Match/Compare 1" },
    .{ .name = "TCC0_TCC0_MC2", .index = 88, .description = "TCC Match/Compare 2" },
    .{ .name = "TCC0_TCC0_MC3", .index = 89, .description = "TCC Match/Compare 3" },
    .{ .name = "TCC0_TCC0_MC4", .index = 90, .description = "TCC Match/Compare 4" },
    .{ .name = "TCC0_TCC0_MC5", .index = 91, .description = "TCC Match/Compare 5" },
    .{ .name = "TCC1_TCC1_OTHER", .index = 92, .description = "Timer Counter Control 1" },
    .{ .name = "TCC1_TCC1_MC0", .index = 93, .description = "TCC Match/Compare 0" },
    .{ .name = "TCC1_TCC1_MC1", .index = 94, .description = "TCC Match/Compare 1" },
    .{ .name = "TCC1_TCC1_MC2", .index = 95, .description = "TCC Match/Compare 2" },
    .{ .name = "TCC1_TCC1_MC3", .index = 96, .description = "TCC Match/Compare 3" },
    .{ .name = "TCC2_TCC2_OTHER", .index = 97, .description = "Timer Counter Control 2" },
    .{ .name = "TCC2_TCC2_MC0", .index = 98, .description = "TCC Match/Compare 0" },
    .{ .name = "TCC2_TCC2_MC1", .index = 99, .description = "TCC Match/Compare 1" },
    .{ .name = "TCC2_TCC2_MC2", .index = 100, .description = "TCC Match/Compare 2" },
    .{ .name = "TCC3_TCC3_OTHER", .index = 101, .description = "Timer Counter Control 3" },
    .{ .name = "TCC3_TCC3_MC0", .index = 102, .description = "TCC Match/Compare 0" },
    .{ .name = "TCC3_TCC3_MC1", .index = 103, .description = "TCC Match/Compare 1" },
    .{ .name = "TCC4_TCC4_OTHER", .index = 104, .description = "Timer Counter Control 4" },
    .{ .name = "TCC4_TCC4_MC0", .index = 105, .description = "TCC Match/Compare 0" },
    .{ .name = "TCC4_TCC4_MC1", .index = 106, .description = "TCC Match/Compare 1" },
    .{ .name = "TC0_TC0", .index = 107, .description = "Timer Counter 0" },
    .{ .name = "TC1_TC1", .index = 108, .description = "Timer Counter 1" },
    .{ .name = "TC2_TC2", .index = 109, .description = "Timer Counter 2" },
    .{ .name = "TC3_TC3", .index = 110, .description = "Timer Counter 3" },
    .{ .name = "TC4_TC4", .index = 111, .description = "Timer Counter 4" },
    .{ .name = "TC5_TC5", .index = 112, .description = "Timer Counter 5" },
    .{ .name = "PDEC_PDEC_OTHER", .index = 115, .description = "Position Decoder" },
    .{ .name = "PDEC_PDEC_MC0", .index = 116, .description = "PDEC Match/Compare 0" },
    .{ .name = "PDEC_PDEC_MC1", .index = 117, .description = "PDEC Match Compare 1" },
    .{ .name = "ADC0_ADC0_OTHER", .index = 118, .description = "Analog To Digital Converter 0" },
    .{ .name = "ADC0_ADC0_RESRDY", .index = 119, .description = "ADC0 Result Ready" },
    .{ .name = "ADC1_ADC1_OTHER", .index = 120, .description = "Analog To Digital Converter 1" },
    .{ .name = "ADC1_ADC1_RESRDY", .index = 121, .description = "ADC1 Result Ready" },
    .{ .name = "AC_AC", .index = 122, .description = "Analog Comparator" },
    .{ .name = "DAC_DAC_OTHER", .index = 123, .description = "Digital to Analog Converter" },
    .{ .name = "DAC_DAC_EMPTY_0", .index = 124, .description = "DAC Buffer 0 Empty" },
    .{ .name = "DAC_DAC_EMPTY_1", .index = 125, .description = "DAC Buffer 1 Empty" },
    .{ .name = "DAC_DAC_RESRDY_0", .index = 126, .description = "DAC Filter 0 Result Ready" },
    .{ .name = "DAC_DAC_RESRDY_1", .index = 127, .description = "DAC Filter 1 Result Ready" },
    .{ .name = "I2S_I2S", .index = 128, .description = "Inter-IC Sound Interface" },
    .{ .name = "PCC_PCC", .index = 129, .description = "Parallel Capture Controller" },
    .{ .name = "AES_AES", .index = 130, .description = "Advanced Encryption Standard" },
    .{ .name = "TRNG_TRNG", .index = 131, .description = "True Random Generator" },
    .{ .name = "ICM_ICM", .index = 132, .description = "Integrity Check Monitor" },
    .{ .name = "PUKCC_PUKCC", .index = 133, .description = "Public-Key Cryptography Controller" },
    .{ .name = "QSPI_QSPI", .index = 134, .description = "Quad SPI interface" },
    .{ .name = "SDHC0_SDHC0", .index = 135, .description = "SD/MMC Host Controller 0" },
};

pub const VectorTable = extern struct {
    const Handler = microzig.interrupt.Handler;
    const unhandled = microzig.interrupt.unhandled;

    initial_stack_pointer: *const anyopaque,
    Reset: Handler,
    /// Non maskable Interrupt, cannot be stopped or preempted
    NonMaskableInt: Handler = unhandled,
    /// Hard Fault, all classes of Fault
    HardFault: Handler = unhandled,
    /// Memory Management, MPU mismatch, including Access Violation and No Match
    MemoryManagement: Handler = unhandled,
    /// Bus Fault, Pre-Fetch-, Memory Access Fault, other address/memory related Fault
    BusFault: Handler = unhandled,
    /// Usage Fault, i.e. Undef Instruction, Illegal State Transition
    UsageFault: Handler = unhandled,
    reserved5: [4]u32 = undefined,
    /// System Service Call via SVC instruction
    SVCall: Handler = unhandled,
    /// Debug Monitor
    DebugMonitor: Handler = unhandled,
    reserved11: [1]u32 = undefined,
    /// Pendable request for system service
    PendSV: Handler = unhandled,
    /// System Tick Timer
    SysTick: Handler = unhandled,
    /// Power Manager
    PM_PM: Handler = unhandled,
    /// Main Clock
    MCLK_MCLK: Handler = unhandled,
    /// External Oscillator 0
    OSCCTRL_OSCCTRL_XOSC0: Handler = unhandled,
    /// External Oscillator 1
    OSCCTRL_OSCCTRL_XOSC1: Handler = unhandled,
    /// Digital Frequency Locked Loop
    OSCCTRL_OSCCTRL_DFLL: Handler = unhandled,
    /// Digital Phase Locked Loop 0
    OSCCTRL_OSCCTRL_DPLL0: Handler = unhandled,
    /// Digital Phase Locked Loop 1
    OSCCTRL_OSCCTRL_DPLL1: Handler = unhandled,
    /// 32Khz Oscillator Controller
    OSC32KCTRL_OSC32KCTRL: Handler = unhandled,
    /// Suppyly controller
    SUPC_SUPC_OTHER: Handler = unhandled,
    /// Brown Out Detection
    SUPC_SUPC_BODDET: Handler = unhandled,
    /// Watch Dog Timer
    WDT_WDT: Handler = unhandled,
    /// Real Time Counter
    RTC_RTC: Handler = unhandled,
    /// EIC Channel 0
    EIC_EIC_EXTINT_0: Handler = unhandled,
    /// EIC Channel 1
    EIC_EIC_EXTINT_1: Handler = unhandled,
    /// EIC Channel 2
    EIC_EIC_EXTINT_2: Handler = unhandled,
    /// EIC Channel 3
    EIC_EIC_EXTINT_3: Handler = unhandled,
    /// EIC Channel 4
    EIC_EIC_EXTINT_4: Handler = unhandled,
    /// EIC Channel 5
    EIC_EIC_EXTINT_5: Handler = unhandled,
    /// EIC Channel 6
    EIC_EIC_EXTINT_6: Handler = unhandled,
    /// EIC Channel 7
    EIC_EIC_EXTINT_7: Handler = unhandled,
    /// EIC Channel 8
    EIC_EIC_EXTINT_8: Handler = unhandled,
    /// EIC Channel 9
    EIC_EIC_EXTINT_9: Handler = unhandled,
    /// EIC Channel 10
    EIC_EIC_EXTINT_10: Handler = unhandled,
    /// EIC Channel 11
    EIC_EIC_EXTINT_11: Handler = unhandled,
    /// EIC Channel 12
    EIC_EIC_EXTINT_12: Handler = unhandled,
    /// EIC Channel 13
    EIC_EIC_EXTINT_13: Handler = unhandled,
    /// EIC Channel 14
    EIC_EIC_EXTINT_14: Handler = unhandled,
    /// EIC Channel 15
    EIC_EIC_EXTINT_15: Handler = unhandled,
    /// Frequency Meter
    FREQM_FREQM: Handler = unhandled,
    /// Non-Volatile Memory Controller
    NVMCTRL_NVMCTRL_0: Handler = unhandled,
    /// NVMCTRL SmartEEPROM Interrupts
    NVMCTRL_NVMCTRL_1: Handler = unhandled,
    /// DMA Channel 0
    DMAC_DMAC_0: Handler = unhandled,
    /// DMA Channel 1
    DMAC_DMAC_1: Handler = unhandled,
    /// DMA Channel 2
    DMAC_DMAC_2: Handler = unhandled,
    /// DMA Channel 3
    DMAC_DMAC_3: Handler = unhandled,
    /// DMA Channel 4..X
    DMAC_DMAC_OTHER: Handler = unhandled,
    /// Event System Channel 0
    EVSYS_EVSYS_0: Handler = unhandled,
    /// Event System Channel 1
    EVSYS_EVSYS_1: Handler = unhandled,
    /// Event System Channel 2
    EVSYS_EVSYS_2: Handler = unhandled,
    /// Event System Channel 3
    EVSYS_EVSYS_3: Handler = unhandled,
    /// Event System Channel 4..X
    EVSYS_EVSYS_OTHER: Handler = unhandled,
    /// Peripheral Access Controller
    PAC_PAC: Handler = unhandled,
    reserved56: [3]u32 = undefined,
    /// RAM Error Correction Code
    RAMECC_RAMECC: Handler = unhandled,
    /// Serial Communication Interface 0
    SERCOM0_SERCOM0_0: Handler = unhandled,
    /// Serial Communication Interface 0
    SERCOM0_SERCOM0_1: Handler = unhandled,
    /// Serial Communication Interface 0
    SERCOM0_SERCOM0_2: Handler = unhandled,
    /// Serial Communication Interface 0
    SERCOM0_SERCOM0_OTHER: Handler = unhandled,
    /// Serial Communication Interface 1
    SERCOM1_SERCOM1_0: Handler = unhandled,
    /// Serial Communication Interface 1
    SERCOM1_SERCOM1_1: Handler = unhandled,
    /// Serial Communication Interface 1
    SERCOM1_SERCOM1_2: Handler = unhandled,
    /// Serial Communication Interface 1
    SERCOM1_SERCOM1_OTHER: Handler = unhandled,
    /// Serial Communication Interface 2
    SERCOM2_SERCOM2_0: Handler = unhandled,
    /// Serial Communication Interface 2
    SERCOM2_SERCOM2_1: Handler = unhandled,
    /// Serial Communication Interface 2
    SERCOM2_SERCOM2_2: Handler = unhandled,
    /// Serial Communication Interface 2
    SERCOM2_SERCOM2_OTHER: Handler = unhandled,
    /// Serial Communication Interface 3
    SERCOM3_SERCOM3_0: Handler = unhandled,
    /// Serial Communication Interface 3
    SERCOM3_SERCOM3_1: Handler = unhandled,
    /// Serial Communication Interface 3
    SERCOM3_SERCOM3_2: Handler = unhandled,
    /// Serial Communication Interface 3
    SERCOM3_SERCOM3_OTHER: Handler = unhandled,
    /// Serial Communication Interface 4
    SERCOM4_SERCOM4_0: Handler = unhandled,
    /// Serial Communication Interface 4
    SERCOM4_SERCOM4_1: Handler = unhandled,
    /// Serial Communication Interface 4
    SERCOM4_SERCOM4_2: Handler = unhandled,
    /// Serial Communication Interface 4
    SERCOM4_SERCOM4_OTHER: Handler = unhandled,
    /// Serial Communication Interface 5
    SERCOM5_SERCOM5_0: Handler = unhandled,
    /// Serial Communication Interface 5
    SERCOM5_SERCOM5_1: Handler = unhandled,
    /// Serial Communication Interface 5
    SERCOM5_SERCOM5_2: Handler = unhandled,
    /// Serial Communication Interface 5
    SERCOM5_SERCOM5_OTHER: Handler = unhandled,
    reserved84: [10]u32 = undefined,
    /// Universal Serial Bus
    USB_USB_OTHER: Handler = unhandled,
    /// USB Start of Frame
    USB_USB_SOF_HSOF: Handler = unhandled,
    /// USB Transfer Complete 0
    USB_USB_TRCPT0: Handler = unhandled,
    /// USB Transfer Complete 1
    USB_USB_TRCPT1: Handler = unhandled,
    reserved98: [1]u32 = undefined,
    /// Timer Counter Control 0
    TCC0_TCC0_OTHER: Handler = unhandled,
    /// TCC Match/Compare 0
    TCC0_TCC0_MC0: Handler = unhandled,
    /// TCC Match/Compare 1
    TCC0_TCC0_MC1: Handler = unhandled,
    /// TCC Match/Compare 2
    TCC0_TCC0_MC2: Handler = unhandled,
    /// TCC Match/Compare 3
    TCC0_TCC0_MC3: Handler = unhandled,
    /// TCC Match/Compare 4
    TCC0_TCC0_MC4: Handler = unhandled,
    /// TCC Match/Compare 5
    TCC0_TCC0_MC5: Handler = unhandled,
    /// Timer Counter Control 1
    TCC1_TCC1_OTHER: Handler = unhandled,
    /// TCC Match/Compare 0
    TCC1_TCC1_MC0: Handler = unhandled,
    /// TCC Match/Compare 1
    TCC1_TCC1_MC1: Handler = unhandled,
    /// TCC Match/Compare 2
    TCC1_TCC1_MC2: Handler = unhandled,
    /// TCC Match/Compare 3
    TCC1_TCC1_MC3: Handler = unhandled,
    /// Timer Counter Control 2
    TCC2_TCC2_OTHER: Handler = unhandled,
    /// TCC Match/Compare 0
    TCC2_TCC2_MC0: Handler = unhandled,
    /// TCC Match/Compare 1
    TCC2_TCC2_MC1: Handler = unhandled,
    /// TCC Match/Compare 2
    TCC2_TCC2_MC2: Handler = unhandled,
    /// Timer Counter Control 3
    TCC3_TCC3_OTHER: Handler = unhandled,
    /// TCC Match/Compare 0
    TCC3_TCC3_MC0: Handler = unhandled,
    /// TCC Match/Compare 1
    TCC3_TCC3_MC1: Handler = unhandled,
    /// Timer Counter Control 4
    TCC4_TCC4_OTHER: Handler = unhandled,
    /// TCC Match/Compare 0
    TCC4_TCC4_MC0: Handler = unhandled,
    /// TCC Match/Compare 1
    TCC4_TCC4_MC1: Handler = unhandled,
    /// Timer Counter 0
    TC0_TC0: Handler = unhandled,
    /// Timer Counter 1
    TC1_TC1: Handler = unhandled,
    /// Timer Counter 2
    TC2_TC2: Handler = unhandled,
    /// Timer Counter 3
    TC3_TC3: Handler = unhandled,
    /// Timer Counter 4
    TC4_TC4: Handler = unhandled,
    /// Timer Counter 5
    TC5_TC5: Handler = unhandled,
    reserved127: [2]u32 = undefined,
    /// Position Decoder
    PDEC_PDEC_OTHER: Handler = unhandled,
    /// PDEC Match/Compare 0
    PDEC_PDEC_MC0: Handler = unhandled,
    /// PDEC Match Compare 1
    PDEC_PDEC_MC1: Handler = unhandled,
    /// Analog To Digital Converter 0
    ADC0_ADC0_OTHER: Handler = unhandled,
    /// ADC0 Result Ready
    ADC0_ADC0_RESRDY: Handler = unhandled,
    /// Analog To Digital Converter 1
    ADC1_ADC1_OTHER: Handler = unhandled,
    /// ADC1 Result Ready
    ADC1_ADC1_RESRDY: Handler = unhandled,
    /// Analog Comparator
    AC_AC: Handler = unhandled,
    /// Digital to Analog Converter
    DAC_DAC_OTHER: Handler = unhandled,
    /// DAC Buffer 0 Empty
    DAC_DAC_EMPTY_0: Handler = unhandled,
    /// DAC Buffer 1 Empty
    DAC_DAC_EMPTY_1: Handler = unhandled,
    /// DAC Filter 0 Result Ready
    DAC_DAC_RESRDY_0: Handler = unhandled,
    /// DAC Filter 1 Result Ready
    DAC_DAC_RESRDY_1: Handler = unhandled,
    /// Inter-IC Sound Interface
    I2S_I2S: Handler = unhandled,
    /// Parallel Capture Controller
    PCC_PCC: Handler = unhandled,
    /// Advanced Encryption Standard
    AES_AES: Handler = unhandled,
    /// True Random Generator
    TRNG_TRNG: Handler = unhandled,
    /// Integrity Check Monitor
    ICM_ICM: Handler = unhandled,
    /// Public-Key Cryptography Controller
    PUKCC_PUKCC: Handler = unhandled,
    /// Quad SPI interface
    QSPI_QSPI: Handler = unhandled,
    /// SD/MMC Host Controller 0
    SDHC0_SDHC0: Handler = unhandled,
};

pub const peripherals = struct {
    pub const PAC: *volatile types.peripherals.PAC = @ptrFromInt(0x40000000);
    pub const PM: *volatile types.peripherals.PM = @ptrFromInt(0x40000400);
    pub const MCLK: *volatile types.peripherals.MCLK = @ptrFromInt(0x40000800);
    pub const RSTC: *volatile types.peripherals.RSTC = @ptrFromInt(0x40000c00);
    /// Oscillators Control
    pub const OSCCTRL: *volatile types.peripherals.OSCCTRL.OSCCTRL = @ptrFromInt(0x40001000);
    pub const OSC32KCTRL: *volatile types.peripherals.OSC32KCTRL = @ptrFromInt(0x40001400);
    pub const SUPC: *volatile types.peripherals.SUPC = @ptrFromInt(0x40001800);
    pub const GCLK: *volatile types.peripherals.GCLK = @ptrFromInt(0x40001c00);
    pub const WDT: *volatile types.peripherals.WDT = @ptrFromInt(0x40002000);
    pub const RTC: *volatile types.peripherals.RTC = @ptrFromInt(0x40002400);
    pub const EIC: *volatile types.peripherals.EIC = @ptrFromInt(0x40002800);
    pub const FREQM: *volatile types.peripherals.FREQM = @ptrFromInt(0x40002c00);
    pub const SERCOM0: *volatile types.peripherals.SERCOM = @ptrFromInt(0x40003000);
    pub const SERCOM1: *volatile types.peripherals.SERCOM = @ptrFromInt(0x40003400);
    pub const TC0: *volatile types.peripherals.TC = @ptrFromInt(0x40003800);
    pub const TC1: *volatile types.peripherals.TC = @ptrFromInt(0x40003c00);
    /// Universal Serial Bus
    pub const USB: *volatile types.peripherals.USB.USB = @ptrFromInt(0x41000000);
    pub const DSU: *volatile types.peripherals.DSU = @ptrFromInt(0x41002000);
    pub const NVMCTRL: *volatile types.peripherals.NVMCTRL = @ptrFromInt(0x41004000);
    pub const CMCC: *volatile types.peripherals.CMCC = @ptrFromInt(0x41006000);
    /// Port Module
    pub const PORT: *volatile types.peripherals.PORT.PORT = @ptrFromInt(0x41008000);
    /// Direct Memory Access Controller
    pub const DMAC: *volatile types.peripherals.DMAC.DMAC = @ptrFromInt(0x4100a000);
    /// HSB Matrix
    pub const HMATRIX: *volatile types.peripherals.HMATRIXB.HMATRIXB = @ptrFromInt(0x4100c000);
    /// Event System Interface
    pub const EVSYS: *volatile types.peripherals.EVSYS.EVSYS = @ptrFromInt(0x4100e000);
    pub const SERCOM2: *volatile types.peripherals.SERCOM = @ptrFromInt(0x41012000);
    pub const SERCOM3: *volatile types.peripherals.SERCOM = @ptrFromInt(0x41014000);
    pub const TCC0: *volatile types.peripherals.TCC = @ptrFromInt(0x41016000);
    pub const TCC1: *volatile types.peripherals.TCC = @ptrFromInt(0x41018000);
    pub const TC2: *volatile types.peripherals.TC = @ptrFromInt(0x4101a000);
    pub const TC3: *volatile types.peripherals.TC = @ptrFromInt(0x4101c000);
    pub const RAMECC: *volatile types.peripherals.RAMECC = @ptrFromInt(0x41020000);
    pub const TCC2: *volatile types.peripherals.TCC = @ptrFromInt(0x42000c00);
    pub const TCC3: *volatile types.peripherals.TCC = @ptrFromInt(0x42001000);
    pub const TC4: *volatile types.peripherals.TC = @ptrFromInt(0x42001400);
    pub const TC5: *volatile types.peripherals.TC = @ptrFromInt(0x42001800);
    pub const PDEC: *volatile types.peripherals.PDEC = @ptrFromInt(0x42001c00);
    pub const AC: *volatile types.peripherals.AC = @ptrFromInt(0x42002000);
    pub const AES: *volatile types.peripherals.AES = @ptrFromInt(0x42002400);
    pub const TRNG: *volatile types.peripherals.TRNG = @ptrFromInt(0x42002800);
    /// Integrity Check Monitor
    pub const ICM: *volatile types.peripherals.ICM.ICM = @ptrFromInt(0x42002c00);
    pub const QSPI: *volatile types.peripherals.QSPI = @ptrFromInt(0x42003400);
    pub const CCL: *volatile types.peripherals.CCL = @ptrFromInt(0x42003800);
    pub const SERCOM4: *volatile types.peripherals.SERCOM = @ptrFromInt(0x43000000);
    pub const SERCOM5: *volatile types.peripherals.SERCOM = @ptrFromInt(0x43000400);
    pub const TCC4: *volatile types.peripherals.TCC = @ptrFromInt(0x43001000);
    pub const ADC0: *volatile types.peripherals.ADC = @ptrFromInt(0x43001c00);
    pub const ADC1: *volatile types.peripherals.ADC = @ptrFromInt(0x43002000);
    pub const DAC: *volatile types.peripherals.DAC = @ptrFromInt(0x43002400);
    pub const I2S: *volatile types.peripherals.I2S = @ptrFromInt(0x43002800);
    pub const PCC: *volatile types.peripherals.PCC = @ptrFromInt(0x43002c00);
    pub const SDHC0: *volatile types.peripherals.SDHC = @ptrFromInt(0x45000000);
    pub const ITM: *volatile types.peripherals.ITM = @ptrFromInt(0xe0000000);
    pub const DWT: *volatile types.peripherals.DWT = @ptrFromInt(0xe0001000);
    pub const SystemControl: *volatile types.peripherals.SystemControl = @ptrFromInt(0xe000e000);
    pub const SysTick: *volatile types.peripherals.SysTick = @ptrFromInt(0xe000e010);
    pub const NVIC: *volatile types.peripherals.NVIC = @ptrFromInt(0xe000e100);
    pub const MPU: *volatile types.peripherals.MPU = @ptrFromInt(0xe000ed90);
    pub const CoreDebug: *volatile types.peripherals.CoreDebug = @ptrFromInt(0xe000edf0);
    pub const FPU: *volatile types.peripherals.FPU = @ptrFromInt(0xe000ef30);
    pub const TPI: *volatile types.peripherals.TPI = @ptrFromInt(0xe0040000);
    pub const ETM: *volatile types.peripherals.ETM = @ptrFromInt(0xe0041000);
};
