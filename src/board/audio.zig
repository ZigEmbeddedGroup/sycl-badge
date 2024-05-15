pub const sample_buffer: *volatile [2][512]u16 = &sample_buffer_storage;

pub const Function = enum(u3) {
    pulse1,
    pulse2,
    triangle,
    sine,
    noise,
};

pub const Channel = struct {
    duty: u32,
    phase: u32,
    phase_step: u31,
    phase_step_step: i32,

    duration: u31,
    attack_duration: u31,
    decay_duration: u31,
    sustain_duration: u31,
    release_duration: u31,

    volume: u31,
    volume_step: i32,
    peak_volume: u31,
    sustain_volume: u31,
    attack_volume_step: i32,
    decay_volume_step: i32,
    release_volume_step: i32,

    function: Function,
};

pub fn init() void {
    @setCold(true);

    board.A0.set_dir(.out);
    board.AVCC.set_dir(.in);
    board.SPKR_EN.set_dir(.out);
    board.SPKR_EN.write(.low);

    clocks.gclk.set_peripheral_clk_gen(.GCLK_DAC, .GCLK3);
    DAC.CTRLA.write(.{ .SWRST = 1, .ENABLE = 0, .padding = 0 });
    while (DAC.SYNCBUSY.read().SWRST != 0) {}
    board.A0.set_mux(.B);
    board.AVCC.set_mux(.B);
    DAC.CTRLB.write(.{ .DIFF = 0, .REFSEL = .{ .value = .VREFPU }, .padding = 0 });
    DAC.EVCTRL.write(.{
        .STARTEI0 = 1,
        .STARTEI1 = 0,
        .EMPTYEO0 = 0,
        .EMPTYEO1 = 0,
        .INVEI0 = 0,
        .INVEI1 = 0,
        .RESRDYEO0 = 0,
        .RESRDYEO1 = 0,
    });
    DAC.DACCTRL[0].write(.{
        .LEFTADJ = 0,
        .ENABLE = 1,
        .CCTRL = .{ .value = .CC12M },
        .reserved5 = 0,
        .FEXT = 0,
        .RUNSTDBY = 0,
        .DITHER = 1,
        .REFRESH = .{ .value = .REFRESH_0 },
        .reserved13 = 0,
        .OSR = .{ .value = .OSR_1 },
    });
    DAC.CTRLA.write(.{ .SWRST = 0, .ENABLE = 1, .padding = 0 });
    while (DAC.SYNCBUSY.read().ENABLE != 0) {}

    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}

    //clocks.gclk.set_peripheral_clk_gen(.GCLK_TC4_TC5, .GCLK3);
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 1,
        .ENABLE = 0,
        .MODE = .{ .raw = 0 },
        .PRESCSYNC = .{ .raw = 0 },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .raw = 0 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (TC5.COUNT8.SYNCBUSY.read().SWRST != 0) {}
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .value = .COUNT8 },
        .PRESCSYNC = .{ .value = .GCLK },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV1 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    TC5.COUNT8.EVCTRL.write(.{
        .EVACT = .{ .raw = 0 },
        .reserved4 = 0,
        .TCINV = 0,
        .TCEI = 0,
        .reserved8 = 0,
        .OVFEO = 1,
        .reserved12 = 0,
        .MCEO0 = 0,
        .MCEO1 = 0,
        .padding = 0,
    });
    TC5.COUNT8.PER.write(.{ .PER = 12 - 1 });
    TC5.COUNT8.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .COUNT8 },
        .PRESCSYNC = .{ .value = .GCLK },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV1 },
        .ALOCK = 0,
        .reserved16 = 0,
        .CAPTEN0 = 0,
        .CAPTEN1 = 0,
        .reserved20 = 0,
        .COPEN0 = 0,
        .COPEN1 = 0,
        .reserved24 = 0,
        .CAPTMODE0 = .{ .raw = 0 },
        .reserved27 = 0,
        .CAPTMODE1 = .{ .raw = 0 },
        .padding = 0,
    });
    while (TC5.COUNT8.SYNCBUSY.read().ENABLE != 0) {}
    TC5.COUNT8.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (TC5.COUNT8.SYNCBUSY.read().CTRLB != 0) {}

    for (&EVSYS.CHANNEL) |*channel| channel.CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.NONE,
        .reserved8 = 0,
        .PATH = .{ .raw = 0 },
        .EDGSEL = .{ .raw = 0 },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    EVSYS.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    EVSYS.CHANNEL[evsys.CHANNEL.AUDIO].CHANNEL.write(.{
        .EVGEN = evsys.EVGEN.TC5_OVF,
        .reserved8 = 0,
        .PATH = .{ .value = .ASYNCHRONOUS },
        .EDGSEL = .{ .value = .NO_EVT_OUTPUT },
        .reserved14 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .padding = 0,
    });
    EVSYS.USER[evsys.USER.DAC_START0].write(.{ .CHANNEL = evsys.CHANNEL.AUDIO + 1, .padding = 0 });

    dma.init_audio();
    while (DAC.STATUS.read().READY0 != 1) {}
    NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

pub fn mix() callconv(.C) void {
    var local_channels = channels.*;
    var speaker_enable: port.Level = .low;
    for (&sample_buffer[
        (dma.get_audio_part() + sample_buffer.len - 1) % sample_buffer.len
    ]) |*out_sample| {
        var sample: i32 = 0;
        inline for (&local_channels) |*channel| {
            if (channel.duty > 0) {
                // generate sample;
                switch (channel.function) {
                    .pulse1, .pulse2, .noise => {
                        if (channel.phase < channel.duty) {
                            sample += channel.volume;
                        } else {
                            sample -= channel.volume;
                        }
                    },
                    .triangle => {
                        sample += @intCast((@as(u64, channel.volume) * @as(u64, @abs(channel.phase >> 1))) >> 32);
                    },
                    .sine => {
                        const vol = @as(f32, @floatFromInt(channel.volume));
                        sample += @intFromFloat(vol * @sin(@as(f32, @floatFromInt(channel.phase))));
                        // sample += @intFromFloat(10 * vol * @sin(2 * std.math.pi * @as(f32, @floatFromInt(channel.phase)) / @as(f32, @floatFromInt(std.math.maxInt(@TypeOf(channel.phase))))));
                    },
                }
                // update
                channel.phase +%= channel.phase_step;
                channel.phase_step = @intCast(channel.phase_step + channel.phase_step_step);
                if (channel.duration > 0) {
                    channel.duration -= 1;
                    channel.volume = @intCast(channel.volume + channel.volume_step);
                } else if (channel.attack_duration > 0) {
                    channel.duration = channel.attack_duration;
                    channel.attack_duration = 0;
                    channel.volume = 0;
                    channel.volume_step = channel.attack_volume_step;
                } else if (channel.decay_duration > 0) {
                    channel.duration = channel.decay_duration;
                    channel.decay_duration = 0;
                    channel.volume = channel.peak_volume;
                    channel.volume_step = channel.decay_volume_step;
                } else if (channel.sustain_duration > 0) {
                    channel.duration = channel.sustain_duration;
                    channel.sustain_duration = 0;
                    channel.volume = channel.sustain_volume;
                    channel.volume_step = 0;
                } else if (channel.release_duration > 0) {
                    channel.duration = channel.release_duration;
                    channel.release_duration = 0;
                    channel.volume = channel.sustain_volume;
                    channel.volume_step = channel.release_volume_step;
                } else {
                    channel.duty = 0;
                }
            }
        }
        speaker_enable = .high; // TODO this is weird
        out_sample.* = @intCast((sample >> 16) - std.math.minInt(i16));
    }
    channels.* = local_channels;
    board.SPKR_EN.write(speaker_enable);
    dma.ack_audio();
}

pub fn set_channel(channel: usize, state: Channel) void {
    NVIC.ICER[32 / 32].write(.{ .CLRENA = 1 << 32 % 32 });
    channels[channel] = state;
    NVIC.ISER[32 / 32].write(.{ .SETENA = 1 << 32 % 32 });
}

var channels_storage: [4]Channel = .{.{
    .duty = 0,
    .phase = 0,
    .phase_step = 0,
    .phase_step_step = 0,

    .duration = 0,
    .attack_duration = 0,
    .decay_duration = 0,
    .sustain_duration = 0,
    .release_duration = 0,

    .volume = 0,
    .volume_step = 0,
    .peak_volume = 0,
    .sustain_volume = 0,
    .attack_volume_step = 0,
    .decay_volume_step = 0,
    .release_volume_step = 0,

    .function = .pulse1,
}} ** 4;
const channels: *volatile [4]Channel = &channels_storage;

var sample_buffer_storage: [2][512]u16 = .{.{0} ** 512} ** 2;

pub const dma = struct {
    pub fn init_audio() void {
        dma.init();
        DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = 0 },
            .reserved20 = 0,
            .TRIGACT = .{ .raw = 0 },
            .reserved24 = 0,
            .BURSTLEN = .{ .raw = 0 },
            .THRESHOLD = .{ .raw = 0 },
            .padding = 0,
        });
        while (DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().ENABLE != 0) {}
        DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
            .SWRST = 1,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = 0 },
            .reserved20 = 0,
            .TRIGACT = .{ .raw = 0 },
            .reserved24 = 0,
            .BURSTLEN = .{ .raw = 0 },
            .THRESHOLD = .{ .raw = 0 },
            .padding = 0,
        });
        while (DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.read().SWRST != 0) {}
        DMAC.CHANNEL[CHANNEL.AUDIO].CHINTENSET.write(.{
            .TERR = 0,
            .TCMPL = 1,
            .SUSP = 0,
            .padding = 0,
        });
        const len0 = @sizeOf(@TypeOf(audio.sample_buffer[0]));
        desc[DESC.AUDIO0].BTCTRL.write(.{
            .VALID = 1,
            .EVOSEL = .{ .value = .DISABLE },
            .BLOCKACT = .{ .value = .INT },
            .reserved8 = 0,
            .BEATSIZE = .{ .value = .HWORD },
            .SRCINC = 1,
            .DSTINC = 0,
            .STEPSEL = .{ .value = .SRC },
            .STEPSIZE = .{ .value = .X1 },
        });
        desc[DESC.AUDIO0].BTCNT.write(.{ .BTCNT = @divExact(len0, 2) });
        desc[DESC.AUDIO0].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[0]) + len0 });
        desc[DESC.AUDIO0].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&DAC.DATABUF[0]) });
        desc[DESC.AUDIO0].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO1]) });
        const len1 = @sizeOf(@TypeOf(audio.sample_buffer[1]));
        desc[DESC.AUDIO1].BTCTRL.write(.{
            .VALID = 1,
            .EVOSEL = .{ .value = .DISABLE },
            .BLOCKACT = .{ .value = .INT },
            .reserved8 = 0,
            .BEATSIZE = .{ .value = .HWORD },
            .SRCINC = 1,
            .DSTINC = 0,
            .STEPSEL = .{ .value = .SRC },
            .STEPSIZE = .{ .value = .X1 },
        });
        desc[DESC.AUDIO1].BTCNT.write(.{ .BTCNT = @divExact(len1, 2) });
        desc[DESC.AUDIO1].SRCADDR.write(.{ .SRCADDR = @intFromPtr(&audio.sample_buffer[1]) + len1 });
        desc[DESC.AUDIO1].DSTADDR.write(.{ .CHKINIT = @intFromPtr(&DAC.DATABUF[0]) });
        desc[DESC.AUDIO1].DESCADDR.write(.{ .DESCADDR = @intFromPtr(&desc[DESC.AUDIO0]) });
        microzig.cpu.dmb();
        DMAC.CHANNEL[CHANNEL.AUDIO].CHCTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 1,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .reserved8 = 0,
            .TRIGSRC = .{ .raw = TRIGSRC.DAC_EMPTY0 },
            .reserved20 = 0,
            .TRIGACT = .{ .value = .BURST },
            .reserved24 = 0,
            .BURSTLEN = .{ .value = .SINGLE },
            .THRESHOLD = .{ .value = .@"1BEAT" },
            .padding = 0,
        });
    }

    pub fn get_audio_part() usize {
        return (desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR - @intFromPtr(audio.sample_buffer) - 1) /
            @sizeOf(@TypeOf(audio.sample_buffer[0]));
    }

    pub fn ack_audio() void {
        DMAC.CHANNEL[CHANNEL.AUDIO].CHINTFLAG.write(.{
            .TERR = 0,
            .TCMPL = 1,
            .SUSP = 0,
            .padding = 0,
        });
    }

    pub fn wait_audio(i: usize) void {
        while (@intFromBool(desc_wb[DESC.AUDIO0].SRCADDR.read().SRCADDR > @intFromPtr(&audio.buffer[1])) == i) {}
    }

    fn init() void {
        if (initialized) return;
        DMAC.CTRL.write(.{
            .SWRST = 0,
            .DMAENABLE = 0,
            .reserved8 = 0,
            .LVLEN0 = 0,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (DMAC.CTRL.read().DMAENABLE != 0) {}
        DMAC.CRCSTATUS.write(.{
            .CRCBUSY = 1,
            .CRCZERO = 0,
            .CRCERR = 0,
            .padding = 0,
        });
        while (DMAC.CRCSTATUS.read().CRCBUSY != 0) {}
        DMAC.CTRL.write(.{
            .SWRST = 1,
            .DMAENABLE = 0,
            .reserved8 = 0,
            .LVLEN0 = 0,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (DMAC.CTRL.read().SWRST != 0) {}
        DMAC.BASEADDR.write(.{ .BASEADDR = @intFromPtr(&desc) });
        DMAC.WRBADDR.write(.{ .WRBADDR = @intFromPtr(&desc_wb) });
        DMAC.CTRL.write(.{
            .SWRST = 0,
            .DMAENABLE = 1,
            .reserved8 = 0,
            .LVLEN0 = 1,
            .LVLEN1 = 0,
            .LVLEN2 = 0,
            .LVLEN3 = 0,
            .padding = 0,
        });
        while (DMAC.CTRL.read().DMAENABLE == 0) {}
        initialized = true;
    }

    const CHANNEL = struct {
        const LCD = 0;
        const AUDIO = 1;
    };

    const DESC = struct {
        const LCD = 0;
        const AUDIO0 = 1;
        const AUDIO1 = 2;
    };

    const TRIGSRC = enum(u7) {
        const DISABLE = 0x00;
        const RTC_TIMESTAMP = 0x01;
        const DSU_DCC0 = 0x02;
        const DSU_DCC1 = 0x03;
        const SERCOM0_RX = 0x04;
        const SERCOM0_TX = 0x05;
        const SERCOM1_RX = 0x06;
        const SERCOM1_TX = 0x07;
        const SERCOM2_RX = 0x08;
        const SERCOM2_TX = 0x09;
        const SERCOM3_RX = 0x0A;
        const SERCOM3_TX = 0x0B;
        const SERCOM4_RX = 0x0C;
        const SERCOM4_TX = 0x0D;
        const SERCOM5_RX = 0x0E;
        const SERCOM5_TX = 0x0F;
        const SERCOM6_RX = 0x10;
        const SERCOM6_TX = 0x11;
        const SERCOM7_RX = 0x12;
        const SERCOM7_TX = 0x13;
        const CAN0_DEBUG = 0x14;
        const CAN1_DEBUG = 0x15;
        const TCC0_OVF = 0x16;
        const TCC0_MC0 = 0x17;
        const TCC0_MC1 = 0x18;
        const TCC0_MC2 = 0x19;
        const TCC0_MC3 = 0x1A;
        const TCC0_MC4 = 0x1B;
        const TCC0_MC5 = 0x1C;
        const TCC1_OVF = 0x1D;
        const TCC1_MC0 = 0x1E;
        const TCC1_MC1 = 0x1F;
        const TCC1_MC2 = 0x20;
        const TCC1_MC3 = 0x21;
        const TCC2_OVF = 0x22;
        const TCC2_MC0 = 0x23;
        const TCC2_MC1 = 0x24;
        const TCC2_MC2 = 0x25;
        const TCC3_OVF = 0x26;
        const TCC3_MC0 = 0x27;
        const TCC3_MC1 = 0x28;
        const TCC4_OVF = 0x29;
        const TCC4_MC0 = 0x2A;
        const TCC4_MC1 = 0x2B;
        const TC0_OVF = 0x2C;
        const TC0_MC0 = 0x2D;
        const TC0_MC1 = 0x2E;
        const TC1_OVF = 0x2F;
        const TC1_MC0 = 0x30;
        const TC1_MC1 = 0x31;
        const TC2_OVF = 0x32;
        const TC2_MC0 = 0x33;
        const TC2_MC1 = 0x34;
        const TC3_OVF = 0x35;
        const TC3_MC0 = 0x36;
        const TC3_MC1 = 0x37;
        const TC4_OVF = 0x38;
        const TC4_MC0 = 0x39;
        const TC4_MC1 = 0x3A;
        const TC5_OVF = 0x3B;
        const TC5_MC0 = 0x3C;
        const TC5_MC1 = 0x3D;
        const TC6_OVF = 0x3E;
        const TC6_MC0 = 0x3F;
        const TC6_MC1 = 0x40;
        const TC7_OVF = 0x41;
        const TC7_MC0 = 0x42;
        const TC7_MC1 = 0x43;
        const ADC0_RESRDY = 0x44;
        const ADC0_SEQ = 0x45;
        const ADC1_RESRDY = 0x46;
        const ADC1_SEQ = 0x47;
        const DAC_EMPTY0 = 0x48;
        const DAC_EMPTY1 = 0x49;
        const DAC_RESRDY0 = 0x4A;
        const DAC_RESRDY1 = 0x4B;
        const I2S_RX0 = 0x4C;
        const IS2_RX1 = 0x4D;
        const I2S_TX0 = 0x4E;
        const IS2_TX1 = 0x4F;
        const PCC_RX = 0x50;
        const AES_WR = 0x51;
        const AES_RD = 0x52;
        const QSPI_RX = 0x53;
        const QSPI_TX = 0x54;
    };

    var initialized = false;
    var desc: [3]DMAC_DESCRIPTOR align(8) = .{.{
        .BTCTRL = .{ .raw = 0 },
        .BTCNT = .{ .raw = 0 },
        .SRCADDR = .{ .raw = 0 },
        .DSTADDR = .{ .raw = 0 },
        .DESCADDR = .{ .raw = 0 },
    }} ** 3;
    var desc_wb: [2]DMAC_DESCRIPTOR align(8) = undefined;
};

pub const evsys = struct {
    pub const CHANNEL = struct {
        pub const AUDIO = 12;
    };
    pub const EVGEN = struct {
        pub const NONE = 0x00;
        pub const OSCCTRL_XOSC_FAIL0 = 0x01;
        pub const OSCCTRL_XOSC_FAIL1 = 0x02;
        pub const OSC32KCTRL_XOSC32K_FAIL = 0x03;
        pub const RTC_PER0 = 0x04;
        pub const RTC_PER1 = 0x05;
        pub const RTC_PER2 = 0x06;
        pub const RTC_PER3 = 0x07;
        pub const RTC_PER4 = 0x08;
        pub const RTC_PER5 = 0x09;
        pub const RTC_PER6 = 0x0A;
        pub const RTC_PER7 = 0x0B;
        pub const RTC_CMP0 = 0x0C;
        pub const RTC_CMP1 = 0x0D;
        pub const RTC_CMP2 = 0x0E;
        pub const RTC_CMP3 = 0x0F;
        pub const RTC_TAMPER = 0x10;
        pub const RTC_OVF = 0x11;
        pub const EIC_EXTENT0 = 0x12;
        pub const EIC_EXTENT1 = 0x13;
        pub const EIC_EXTENT2 = 0x14;
        pub const EIC_EXTENT3 = 0x15;
        pub const EIC_EXTENT4 = 0x16;
        pub const EIC_EXTENT5 = 0x17;
        pub const EIC_EXTENT6 = 0x18;
        pub const EIC_EXTENT7 = 0x19;
        pub const EIC_EXTENT8 = 0x1A;
        pub const EIC_EXTENT9 = 0x1B;
        pub const EIC_EXTENT10 = 0x1C;
        pub const EIC_EXTENT11 = 0x1D;
        pub const EIC_EXTENT12 = 0x1E;
        pub const EIC_EXTENT13 = 0x1F;
        pub const EIC_EXTENT14 = 0x20;
        pub const EIC_EXTENT15 = 0x21;
        pub const DMAC_CH0 = 0x22;
        pub const DMAC_CH1 = 0x23;
        pub const DMAC_CH2 = 0x24;
        pub const DMAC_CH3 = 0x25;
        pub const PAC_ACCERR = 0x26;
        pub const TCC0_OVF = 0x29;
        pub const TCC0_TRG = 0x2A;
        pub const TCC0_CNT = 0x2B;
        pub const TCC0_MC0 = 0x2C;
        pub const TCC0_MC1 = 0x2D;
        pub const TCC0_MC2 = 0x2E;
        pub const TCC0_MC3 = 0x2F;
        pub const TCC0_MC4 = 0x30;
        pub const TCC0_MC5 = 0x31;
        pub const TCC1_OVF = 0x32;
        pub const TCC1_TRG = 0x33;
        pub const TCC1_CNT = 0x34;
        pub const TCC1_MC0 = 0x35;
        pub const TCC1_MC1 = 0x36;
        pub const TCC1_MC2 = 0x37;
        pub const TCC1_MC3 = 0x38;
        pub const TCC2_OVF = 0x39;
        pub const TCC2_TRG = 0x3A;
        pub const TCC2_CNT = 0x3B;
        pub const TCC2_MC0 = 0x3C;
        pub const TCC2_MC1 = 0x3D;
        pub const TCC2_MC2 = 0x3E;
        pub const TCC3_OVF = 0x3F;
        pub const TCC3_TRG = 0x40;
        pub const TCC3_CNT = 0x41;
        pub const TCC3_MC0 = 0x42;
        pub const TCC3_MC1 = 0x43;
        pub const TCC4_OVF = 0x44;
        pub const TCC4_TRG = 0x45;
        pub const TCC4_CNT = 0x46;
        pub const TCC4_MC0 = 0x47;
        pub const TCC4_MC1 = 0x48;
        pub const TC0_OVF = 0x49;
        pub const TC0_MC0 = 0x4A;
        pub const TC0_MC1 = 0x4B;
        pub const TC1_OVF = 0x4C;
        pub const TC1_MC0 = 0x4D;
        pub const TC1_MC1 = 0x4E;
        pub const TC2_OVF = 0x4F;
        pub const TC2_MC0 = 0x50;
        pub const TC2_MC1 = 0x51;
        pub const TC3_OVF = 0x52;
        pub const TC3_MC0 = 0x53;
        pub const TC3_MC1 = 0x54;
        pub const TC4_OVF = 0x55;
        pub const TC4_MC0 = 0x56;
        pub const TC4_MC1 = 0x57;
        pub const TC5_OVF = 0x58;
        pub const TC5_MC0 = 0x59;
        pub const TC5_MC1 = 0x5A;
        pub const TC6_OVF = 0x5B;
        pub const TC6_MC0 = 0x5C;
        pub const TC6_MC1 = 0x5D;
        pub const TC7_OVF = 0x5E;
        pub const TC7_MC0 = 0x5F;
        pub const TC7_MC1 = 0x60;
        pub const PDEC_OVF = 0x61;
        pub const PDEC_ERR = 0x62;
        pub const PDEC_DIR = 0x63;
        pub const PDEC_VLC = 0x64;
        pub const PDEC_MC0 = 0x65;
        pub const PDEC_MC1 = 0x66;
        pub const ADC0_RESRDY = 0x67;
        pub const ADC0_WINMON = 0x68;
        pub const ADC1_RESRDY = 0x69;
        pub const ADC1_WINMON = 0x6A;
        pub const AC_COMP0 = 0x6B;
        pub const AC_COMP1 = 0x6C;
        pub const AC_WIN = 0x6D;
        pub const DAC_EMPTY0 = 0x6E;
        pub const DAC_EMPTY1 = 0x6F;
        pub const DAC_RESRDY0 = 0x70;
        pub const DAC_RESRDY1 = 0x71;
        pub const GMAC_TSU_CMP = 0x72;
        pub const TRNG_READY = 0x73;
        pub const CCL_LUTOUT0 = 0x74;
        pub const CCL_LUTOUT1 = 0x75;
        pub const CCL_LUTOUT2 = 0x76;
        pub const CCL_LUTOUT3 = 0x77;
    };
    pub const USER = struct {
        pub const RTC_TAMPER = 0;
        pub const PORT_EV0 = 1;
        pub const PORT_EV1 = 2;
        pub const PORT_EV2 = 3;
        pub const PORT_EV3 = 4;
        pub const DMA_CH0 = 5;
        pub const DMA_CH1 = 6;
        pub const DMA_CH2 = 7;
        pub const DMA_CH3 = 8;
        pub const DMA_CH4 = 9;
        pub const DMA_CH5 = 10;
        pub const DMA_CH6 = 11;
        pub const DMA_CH7 = 12;
        pub const CM4_TRACE_START = 14;
        pub const CM4_TRACE_STOP = 15;
        pub const CM4_TRACE_TRIG = 16;
        pub const TCC0_EV0 = 17;
        pub const TCC0_EV1 = 18;
        pub const TCC0_MC0 = 19;
        pub const TCC0_MC1 = 20;
        pub const TCC0_MC2 = 21;
        pub const TCC0_MC3 = 22;
        pub const TCC0_MC4 = 23;
        pub const TCC0_MC5 = 24;
        pub const TCC1_EV0 = 25;
        pub const TCC1_EV1 = 26;
        pub const TCC1_MC0 = 27;
        pub const TCC1_MC1 = 28;
        pub const TCC1_MC2 = 29;
        pub const TCC1_MC3 = 30;
        pub const TCC2_EV0 = 31;
        pub const TCC2_EV1 = 32;
        pub const TCC2_MC0 = 33;
        pub const TCC2_MC1 = 34;
        pub const TCC2_MC2 = 35;
        pub const TCC3_EV0 = 36;
        pub const TCC3_EV1 = 37;
        pub const TCC3_MC0 = 38;
        pub const TCC3_MC1 = 39;
        pub const TCC4_EV0 = 40;
        pub const TCC4_EV1 = 41;
        pub const TCC4_MC0 = 42;
        pub const TCC4_MC1 = 43;
        pub const TC0_EVU = 44;
        pub const TC1_EVU = 45;
        pub const TC2_EVU = 46;
        pub const TC3_EVU = 47;
        pub const TC4_EVU = 48;
        pub const TC5_EVU = 49;
        pub const TC6_EVU = 50;
        pub const TC7_EVU = 51;
        pub const PDEC_EVU0 = 52;
        pub const PDEC_EVU1 = 53;
        pub const PDEC_EVU2 = 54;
        pub const ADC0_START = 55;
        pub const ADC0_SYNC = 56;
        pub const ADC1_START = 57;
        pub const ADC1_SYNC = 58;
        pub const AC_SOC0 = 59;
        pub const AC_SOC1 = 60;
        pub const DAC_START0 = 61;
        pub const DAC_START1 = 62;
        pub const CCL_LUTIN0 = 63;
        pub const CCL_LUTIN1 = 64;
        pub const CCL_LUTIN2 = 65;
        pub const CCL_LUTIN3 = 66;
    };
};

const audio = @This();
const board = @import("../board.zig");
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const port = hal.port;
const clocks = hal.clocks;
const chip = microzig.chip;
const DAC = chip.peripherals.DAC;
const DMAC = chip.peripherals.DMAC;
const DMAC_DESCRIPTOR = chip.types.peripherals.DMAC.DMAC_DESCRIPTOR;
const TC5 = chip.peripherals.TC5;
const NVIC = chip.peripherals.NVIC;
const EVSYS = chip.peripherals.EVSYS;
