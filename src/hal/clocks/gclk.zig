const microzig = @import("microzig");
const peripherals = microzig.chip.peripherals;
pub const GCLK = peripherals.GCLK;
const types = microzig.chip.types;

/// For SYNCBUSY
const Genctrl = types.peripherals.GCLK.GCLK_SYNCBUSY__GENCTRL;
pub const Generator = types.peripherals.GCLK.GCLK_PCHCTRL__GEN;
pub const Source = types.peripherals.GCLK.GCLK_GENCTRL__SRC;
pub const DivSelection = microzig.chip.types.peripherals.GCLK.GCLK_GENCTRL__DIVSEL;

pub const PeripheralIndex = enum(u6) {
    GCLK_OSCCTRL_DFLL48 = 0,
    GCLK_OSCCTRL_FDPLL0 = 1,
    GCLK_OSCCTRL_FDPLL1 = 2,
    // TODO:
    //3 GCLK_OSCCTRL_FDPLL0_32K GCLK_OSCCTRL_FDPLL1_32K GCLK_SDHC0_SLOW GCLK_SDHC1_SLOW GCLK_SERCOM[0..7]_SLOW
    //FDPLL0 32KHz clock for internal lock timer FDPLL1 32KHz clock for internal lock timer SDHC0 Slow
    //SDHC1 Slow
    //SERCOM[0..7] Slow
    GCLK_EIC = 4,
    GCLK_FREQM_MSR = 5,
    GCLK_FREQM_REF = 6,
    GCLK_SERCOM0_CORE = 7,
    GCLK_SERCOM1_CORE = 8,
    GCLK_TC0_TC1 = 9,
    GCLK_USB = 10,
    // TODO:
    //22:11 GCLK_EVSYS[0..11] EVSYS[0..11]
    GCLK_SERCOM2_CORE = 23,
    GCLK_SERCOM3_CORE = 24,
    GCLK_TCC0_TCC1 = 25,
    GCLK_TC2_TC3 = 26,
    GCLK_CAN0 = 27,
    GCLK_CAN1 = 28,
    GCLK_TCC2_TCC3 = 29,
    GCLK_TC4_TC5 = 30,
    GCLK_PDEC = 31,
    GCLK_AC = 32,
    GCLK_CCL = 33,
    GCLK_SERCOM4_CORE = 34,
    GCLK_SERCOM5_CORE = 35,
    GCLK_SERCOM6_CORE = 36,
    GCLK_SERCOM7_CORE = 37,
    GCLK_TCC4 = 38,
    GCLK_TC6_TC7 = 39,
    GCLK_ADC0 = 40,
    GCLK_ADC1 = 41,
    GCLK_DAC = 42,
    GCLK_I2S = 43, // TODO: and 44?
    GCLK_SDHC0 = 45,
    GCLK_SDHC1 = 46,
    GCLK_CM4_TRACE = 47,
};

pub fn reset_blocking() void {
    GCLK.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    while (GCLK.SYNCBUSY.read().SWRST != 0) {}
}

pub fn wait_for_sync_mask(mask: u12) void {
    while ((GCLK.SYNCBUSY.read().GENCTRL.raw & mask) != 0) {}
}

pub const EnableGeneratorOptions = struct {
    divsel: microzig.chip.types.peripherals.GCLK.GCLK_GENCTRL__DIVSEL = .DIV1,
    div: u16 = 1,
};

pub fn enable_generator(gen: Generator, source: Source, opts: EnableGeneratorOptions) void {
    GCLK.GENCTRL[@intFromEnum(gen)].write(.{
        .SRC = .{ .value = source },
        .reserved8 = 0,
        .GENEN = 1,
        .IDC = 0,
        .OOV = 0,
        .OE = 0,
        .DIVSEL = .{ .value = opts.divsel },
        .RUNSTDBY = 0,
        .reserved16 = 0,
        .DIV = opts.div,
    });

    while ((GCLK.SYNCBUSY.raw & @as(u32, 1) << @intFromEnum(gen) + 2) == 1) {}
}

/// Set the Generic Clock Generator for a peripheral, it will also enable the
/// peripheral channel.
pub fn set_peripheral_clk_gen(peripheral: PeripheralIndex, gen: Generator) void {
    GCLK.PCHCTRL[@intFromEnum(peripheral)].write(.{
        .GEN = .{ .value = gen },
        // TODO: maybe change API to make this more explicit?
        .CHEN = 1,
        .WRTLOCK = 0,

        .reserved6 = 0,
        .padding = 0,
    });
}

pub fn peripheral_is_enabled(peripheral: PeripheralIndex) bool {
    return GCLK.PCHCTRL[@intFromEnum(peripheral)].read().CHEN == 1;
}

pub fn disable_peripheral_channel(peripheral: PeripheralIndex) void {
    GCLK.PCHCTRL[@intFromEnum(peripheral)].modify(.{
        .CHEN = 0,
    });
}
