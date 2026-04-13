const microzig = @import("microzig");
const ADC = microzig.chip.types.peripherals.ADC;
const NVMCTRL = struct {
    pub const SW0: *volatile microzig.chip.types.peripherals.FUSES.SW0_FUSES = @ptrFromInt(0x00800080);
};

pub const Div = ADC.ADC_CTRLA__PRESCALER;
pub const PositiveInput = ADC.ADC_INPUTCTRL__MUXPOS;
pub const NegativeInput = ADC.ADC_INPUTCTRL__MUXNEG;
pub const DiffMode = enum { single_ended, differential };

pub const Adc = enum(u1) {
    ADC0,
    ADC1,

    fn get_regs(adc: Adc) *volatile ADC {
        return switch (adc) {
            .ADC0 => microzig.chip.peripherals.ADC0,
            .ADC1 => microzig.chip.peripherals.ADC1,
        };
    }

    pub fn init(adc: Adc, div: Div) void {
        const regs = adc.get_regs();

        adc.wait_for_sync(.SWRST);

        adc.reset();

        regs.CTRLA.modify(.{
            .PRESCALER = div,
        });
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
        regs.CTRLA.write(.{
            .SWRST = 1,
            .ENABLE = 0,
            .reserved3 = 0,
            .DUALSEL = @enumFromInt(0),
            .SLAVEEN = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
            .PRESCALER = @enumFromInt(0),
            .reserved15 = 0,
            .R2R = 0,
        });
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

    pub fn set_input(
        adc: Adc,
        pos: PositiveInput,
        neg: NegativeInput,
        diff_mode: DiffMode,
        seq_stop: enum { continuous, stop },
    ) void {
        const regs = adc.get_regs();
        regs.INPUTCTRL.write(.{
            .MUXPOS = pos,
            .reserved7 = 0,
            .DIFFMODE = @intFromEnum(diff_mode),
            .MUXNEG = neg,
            .reserved15 = 0,
            .DSEQSTOP = @intFromEnum(seq_stop),
        });

        adc.wait_for_sync(.INPUTCTRL);
    }

    pub fn start_conversion(adc: Adc) void {
        const regs = adc.get_regs();
        regs.SWTRIG.write(.{
            .FLUSH = 0,
            .START = 1,
            .padding = 0,
        });

        adc.wait_for_sync(.SWTRIG);
        while (regs.SWTRIG.read().START != 0) {}
    }

    pub fn wait_for_result(adc: Adc) void {
        const regs = adc.get_regs();
        while (regs.INTFLAG.read().RESRDY != 1) {}
        regs.INTFLAG.write(.{
            .RESRDY = 1,
            .OVERRUN = 0,
            .WINMON = 0,
            .padding = 0,
        });
    }

    pub fn get_result(adc: Adc) u16 {
        const regs = adc.get_regs();
        return regs.RESULT.read().RESULT;
    }

    pub fn single_shot_blocking(adc: Adc) u16 {
        adc.start_conversion();
        adc.wait_for_result();
        return adc.get_result();
    }
};

pub fn num(n: u1) Adc {
    return @enumFromInt(n);
}
