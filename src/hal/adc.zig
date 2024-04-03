const microzig = @import("microzig");
const ADC = microzig.chip.types.peripherals.ADC;
const NVMCTRL = struct {
    pub const SW0: *volatile microzig.chip.types.peripherals.FUSES.SW0_FUSES = @ptrFromInt(0x00800080);
};

pub const PositiveInput = ADC.ADC_INPUTCTRL__MUXPOS;
pub const NegativeInput = ADC.ADC_INPUTCTRL__MUXNEG;

pub const Adc = enum(u1) {
    ADC0,
    ADC1,

    fn get_regs(adc: Adc) *volatile ADC {
        return switch (adc) {
            .ADC0 => microzig.chip.peripherals.ADC0,
            .ADC1 => microzig.chip.peripherals.ADC1,
        };
    }

    pub fn init(adc: Adc) void {
        adc.wait_for_sync(.SWRST);

        adc.reset();
        defer adc.enable();

        adc.calibrate();

        // CTRLB
        // REFCTRL
        // EVCTRL
        // INPUTCTRL
        // AVGCTRL
        // SAMPCTRL
        // WINLT
        // WINUT
        // GAINCORR
        // OFFSETCORR
        // DBGCTRL
        // CTRLA
    }

    pub fn enable(adc: Adc) void {
        const regs = adc.get_regs();
        regs.CTRLA.modify(.{
            .ENABLE = 1,
        });

        adc.wait_for_sync(.ENABLE);
    }

    pub fn disable(adc: Adc) void {
        const regs = adc.get_regs();
        regs.CTRLA.modify(.{
            .ENABLE = 0,
        });

        adc.wait_for_sync(.ENABLE);
    }

    pub const Sync = enum {
        SWRST,
        ENABLE,
        INPUTCTRL,
        SWTRIG,
    };

    pub fn wait_for_sync(adc: Adc, sync: Sync) void {
        const regs = adc.get_regs();
        while (true) {
            const busy = regs.SYNCBUSY.read();
            if (switch (sync) {
                .SWRST => busy.SWRST,
                .ENABLE => busy.ENABLE,
                .INPUTCTRL => busy.INPUTCTRL,
                .SWTRIG => busy.SWTRIG,
            } == 0) {
                break;
            }
        }
    }

    pub fn reset(adc: Adc) void {
        const regs = adc.get_regs();
        regs.CTRLA.modify(.{ .SWRST = 1 });
        adc.wait_for_sync(.SWRST);
    }

    pub fn calibrate(adc: Adc) void {
        const fuses = NVMCTRL.SW0.SW0_WORD_0.read();
        const regs = adc.get_regs();
        regs.CALIB.write(.{
            .BIASCOMP = switch (adc) {
                .ADC0 => fuses.ADC0_BIASCOMP,
                .ADC1 => fuses.ADC1_BIASCOMP,
            },
            .BIASR2R = switch (adc) {
                .ADC0 => fuses.ADC0_BIASR2R,
                .ADC1 => fuses.ADC1_BIASR2R,
            },
            .BIASREFBUF = switch (adc) {
                .ADC0 => fuses.ADC0_BIASREFBUF,
                .ADC1 => fuses.ADC1_BIASREFBUF,
            },

            .reserved4 = 0,
            .reserved8 = 0,
            .padding = 0,
        });
    }

    pub fn set_input(adc: Adc, input: PositiveInput) void {
        const regs = adc.get_regs();
        regs.INPUTCTRL.modify(.{
            .MUXPOS = .{ .value = input },
        });

        adc.wait_for_sync(.INPUTCTRL);
    }

    pub fn start_conversion(adc: Adc) void {
        const regs = adc.get_regs();
        regs.SWTRIG.modify(.{
            .START = 1,
        });

        adc.wait_for_sync(.SWTRIG);
    }

    pub fn wait_for_result_blocking(adc: Adc) void {
        const regs = adc.get_regs();
        while (regs.INTFLAG.read().RESRDY == 0) {}
    }

    pub fn single_shot_blocking(adc: Adc, input: PositiveInput) u16 {
        adc.set_input(input);
        adc.start_conversion();
        adc.wait_for_result_blocking();

        const regs = adc.get_regs();
        return regs.RESULT.read().RESULT;
    }
};

pub fn num(n: u1) Adc {
    return @enumFromInt(n);
}
