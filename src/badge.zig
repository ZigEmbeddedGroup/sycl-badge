//! This is firmware for the SYCL badge.
//!
//! The badge image
//! For normal operation, the default app will run. Pressing select will go to
//! the main menu. The default app will display the SYCL logo, users will be
//! able to change the default app.
//!
//! Apps will have the option to to save state to non-volatile memory. This
//! will prompt the user. The user will either exit without saving, save and
//! exit, or cancel.
//!
//! TODO:
//! - USB mass drive
//! - USB CDC logging
const std = @import("std");
const builtin = @import("builtin");

const microzig = @import("microzig");
const board = microzig.board;
const cpu = microzig.cpu;
const chip = microzig.chip;
const hal = microzig.hal;
const clocks = hal.clocks;
const timer = hal.timer;
const sercom = hal.sercom;

// direct peripheral access
const SystemControl = chip.peripherals.SystemControl;
const CMCC = chip.peripherals.CMCC;
const NVMCTRL = chip.peripherals.NVMCTRL;
const TC4 = chip.peripherals.TC4;
const MPU = chip.peripherals.MPU;

const cart = @import("badge/cart.zig");

const led_pin = board.D13;

const Lcd = board.Lcd;
const ButtonPoller = board.ButtonPoller;
const light_sensor_pin = microzig.board.A7_LIGHT;
const audio = board.audio;

const adc = hal.adc.num(0);

const utils = @import("utils.zig");

pub const microzig_options = .{
    .interrupts = .{
        .SVCall = microzig.interrupt.Handler{ .Naked = cart.svcall_handler },
        .DMAC_DMAC_1 = .{ .C = &audio.mix },
    },
};

pub fn main() !void {
    SystemControl.CCR.modify(.{
        .NONBASETHRDENA = 0,
        .USERSETMPEND = 0,
        .UNALIGN_TRP = .{ .value = .VALUE_0 }, // TODO
        .DIV_0_TRP = 1,
        .BFHFNMIGN = 0,
        .STKALIGN = .{ .value = .VALUE_1 },
    });
    SystemControl.SHCSR.modify(.{
        .MEMFAULTENA = 1,
        .BUSFAULTENA = 1,
        .USGFAULTENA = 1,
    });
    SystemControl.CPACR.write(.{
        .reserved20 = 0,
        .CP10 = .{ .value = .FULL },
        .CP11 = .{ .value = .FULL },
        .padding = 0,
    });

    clocks.mclk.set_ahb_mask(.{
        .CMCC = .enabled,
        .DMAC = .enabled,
    });
    CMCC.CTRL.write(.{
        .CEN = 1,
        .padding = 0,
    });

    NVMCTRL.CTRLA.modify(.{ .AUTOWS = 1 });
    clocks.gclk.reset_blocking();
    microzig.cpu.dmb();

    MPU.RBAR.write(.{
        .REGION = 0,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.FLASH.ADDR) >> 5,
    });
    MPU.RASR.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(utils.FLASH.SIZE) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(utils.FLASH.SIZE) - 1) >> 1),
        .SRD = 0b00000111,
        .B = 0,
        .C = 1,
        .S = 0,
        .TEX = 0b000,
        .reserved24 = 0,
        .AP = 0b010,
        .reserved28 = 0,
        .XN = 0,
        .padding = 0,
    });
    MPU.RBAR_A1.write(.{
        .REGION = 1,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.HSRAM.ADDR) >> 5,
    });
    MPU.RASR_A1.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(@divExact(utils.HSRAM.SIZE, 3) * 2) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(@divExact(utils.HSRAM.SIZE, 3) * 2) - 1) >> 1),
        .SRD = 0b00000000,
        .B = 1,
        .C = 1,
        .S = 0,
        .TEX = 0b001,
        .reserved24 = 0,
        .AP = 0b011,
        .reserved28 = 0,
        .XN = 1,
        .padding = 0,
    });
    MPU.RBAR_A2.write(.{
        .REGION = 2,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.HSRAM.ADDR[@divExact(utils.HSRAM.SIZE, 3) * 2 ..]) >> 5,
    });
    MPU.RASR_A2.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(@divExact(utils.HSRAM.SIZE, 3)) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(@divExact(utils.HSRAM.SIZE, 3)) - 1) >> 1),
        .SRD = 0b11001111,
        .B = 1,
        .C = 1,
        .S = 0,
        .TEX = 0b001,
        .reserved24 = 0,
        .AP = 0b011,
        .reserved28 = 0,
        .XN = 1,
        .padding = 0,
    });
    MPU.CTRL.write(.{
        .ENABLE = 1,
        .HFNMIENA = 0,
        .PRIVDEFENA = 1,
        .padding = 0,
    });

    // GCLK0 feeds the CPU so put it on OSCULP32K for now
    clocks.gclk.enable_generator(.GCLK0, .OSCULP32K, .{});

    // Enable the first chain of clock generators:
    //
    // FDLL (48MHz) => GCLK2 (1MHz) => DPLL0 (120MHz) => GCLK0 (120MHz)
    //                              => ADC0 (1MHz)
    //                              => TC0 (1MHz)
    //                              => TC1 (1MHz)
    //
    clocks.gclk.enable_generator(.GCLK2, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    clocks.enable_dpll(0, .GCLK2, .{
        .factor = 1,
        .input_freq_hz = 1_000_000,
        .output_freq_hz = 120_000_000,
    });

    clocks.gclk.set_peripheral_clk_gen(.GCLK_ADC0, .GCLK2);
    clocks.gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK2);
    clocks.gclk.enable_generator(.GCLK0, .DPLL0, .{});

    // The second chain of clock generators:
    //
    // FDLL (48MHz) => GCLK1 (76.8KHz) => DPLL1 (8.467MHz) => GCLK3 (8.467MHz) => TC4 (8.467MHz)
    //

    // The we use GCLK1 here because it's able to divide much more than the
    // other generators, the other generators max out at 512
    clocks.gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 625,
    });

    clocks.enable_dpll(1, .GCLK1, .{
        .factor = 12,
        .input_freq_hz = 76_800,
        .output_freq_hz = 8_467_200,
    });

    clocks.gclk.enable_generator(.GCLK3, .DPLL1, .{});
    clocks.gclk.set_peripheral_clk_gen(.GCLK_TC4_TC5, .GCLK3);
    clocks.gclk.set_peripheral_clk_gen(.GCLK_SERCOM4_CORE, .GCLK0);

    clocks.mclk.set_apb_mask(.{
        .ADC0 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
        .TC4 = .enabled,
        .SERCOM4 = .enabled,
        .TC5 = .enabled,
        .DAC = .enabled,
        .EVSYS = .enabled,
    });

    {
        var buffer: [128]u8 = undefined;
        const io_types = chip.types.peripherals;
        const io = chip.peripherals;

        const GCLK = struct {
            pub const GEN = struct {
                fn Gen(comptime id: u4) type {
                    const tag = std.fmt.comptimePrint("GCLK{d}", .{id});
                    return struct {
                        pub const ID = id;
                        pub const SYNCBUSY_GENCTRL = @intFromEnum(@field(io_types.GCLK.GCLK_SYNCBUSY__GENCTRL, tag));
                        pub const PCHCTRL_GEN = @field(io_types.GCLK.GCLK_PCHCTRL__GEN, tag);
                    };
                }
                pub const @"120MHz" = Gen(0);
                pub const @"76.8KHz" = Gen(1);
                pub const @"48MHz" = Gen(2);
                pub const @"8.4672MHz" = Gen(3);
                pub const @"1MHz" = Gen(4);
                pub const @"64KHz" = Gen(11);
            };
            pub const PCH = struct {
                pub const OSCCTRL_DFLL48 = 0;
                pub const OSCCTRL_FDPLL0 = 1;
                pub const OSCCTRL_FDPLL1 = 2;
                pub const OSCCTRL_FDPLL0_32K = 3;
                pub const OSCCTRL_FDPLL1_32K = 3;
                pub const SDHC0_SLOW = 3;
                pub const SDHC1_SLOW = 3;
                pub const SERCOM0_SLOW = 3;
                pub const SERCOM1_SLOW = 3;
                pub const SERCOM2_SLOW = 3;
                pub const SERCOM3_SLOW = 3;
                pub const SERCOM4_SLOW = 3;
                pub const SERCOM5_SLOW = 3;
                pub const SERCOM6_SLOW = 3;
                pub const SERCOM7_SLOW = 3;
                pub const EIC = 4;
                pub const FREQM_MSR = 5;
                pub const FREQM_REF = 6;
                pub const SERCOM0_CORE = 7;
                pub const SERCOM1_CORE = 8;
                pub const TC0 = 9;
                pub const TC1 = 9;
                pub const USB = 10;
                pub const EVSYS0 = 11;
                pub const EVSYS1 = 12;
                pub const EVSYS2 = 13;
                pub const EVSYS3 = 14;
                pub const EVSYS4 = 15;
                pub const EVSYS5 = 16;
                pub const EVSYS6 = 17;
                pub const EVSYS7 = 18;
                pub const EVSYS8 = 19;
                pub const EVSYS9 = 20;
                pub const EVSYS10 = 21;
                pub const EVSYS11 = 22;
                pub const SERCOM2_CORE = 23;
                pub const SERCOM3_CORE = 24;
                pub const TCC0_CORE = 25;
                pub const TCC1_CORE = 25;
                pub const TC2 = 26;
                pub const TC3 = 26;
                pub const CAN0 = 27;
                pub const CAN1 = 28;
                pub const TCC2 = 29;
                pub const TCC3 = 29;
                pub const TC4 = 30;
                pub const TC5 = 30;
                pub const PDEC = 31;
                pub const AC = 32;
                pub const CCL = 33;
                pub const SERCOM4_CORE = 34;
                pub const SERCOM5_CORE = 35;
                pub const SERCOM6_CORE = 36;
                pub const SERCOM7_CORE = 37;
                pub const TCC4 = 38;
                pub const TC6 = 39;
                pub const TC7 = 39;
                pub const ADC0 = 40;
                pub const ADC1 = 41;
                pub const DAC = 42;
                pub const I2C = .{ 43, 44 };
                pub const SDHC0 = 45;
                pub const SDHC1 = 46;
                pub const CM4_TRACE = 47;
            };
        };

        io.MCLK.APBAMASK.modify(.{ .FREQM_ = 1 });

        // Use OSCULP32K / 512 as reference
        io.GCLK.GENCTRL[GCLK.GEN.@"64KHz".ID].write(.{
            .SRC = .{ .value = .OSCULP32K },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV2 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 8,
        });
        io.GCLK.PCHCTRL[GCLK.PCH.FREQM_REF].write(.{
            .GEN = .{ .value = GCLK.GEN.@"64KHz".PCHCTRL_GEN },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });

        for (0.., &io.GCLK.GENCTRL) |gen_id, *gen_ctrl| {
            if (gen_id == GCLK.GEN.@"64KHz".ID) continue;
            const config = gen_ctrl.read();
            if (config.GENEN == 0) continue;

            io.GCLK.PCHCTRL[GCLK.PCH.FREQM_MSR].write(.{
                .GEN = .{ .raw = @intCast(gen_id) },
                .reserved6 = 0,
                .CHEN = 1,
                .WRTLOCK = 0,
                .padding = 0,
            });

            // Reset Frequency Meter
            io.FREQM.CTRLA.write(.{
                .SWRST = 1,
                .ENABLE = 0,
                .padding = 0,
            });
            while (io.FREQM.SYNCBUSY.read().SWRST != 0) {}

            // Run Frequency Meter
            io.FREQM.CFGA.write(.{
                .REFNUM = 8,
                .padding = 0,
            });
            io.FREQM.CTRLA.write(.{
                .SWRST = 0,
                .ENABLE = 1,
                .padding = 0,
            });
            while (io.FREQM.SYNCBUSY.read().ENABLE != 0) {}
            io.FREQM.CTRLB.write(.{
                .START = 1,
                .padding = 0,
            });
            while (io.FREQM.STATUS.read().BUSY != 0) {}
            if (io.FREQM.STATUS.read().OVF == 0) {
                const freq = (@as(u32, io.FREQM.VALUE.read().VALUE) + 1) * 8;
                const div = switch (config.DIVSEL.value) {
                    .DIV1 => switch (config.DIV) {
                        0 => 1,
                        else => |div| div,
                    },
                    .DIV2 => @as(u32, 1) << @min(config.DIV + 1, @as(u5, switch (gen_id) {
                        else => 9,
                        1 => 17,
                    })),
                };
                switch (gen_id) {
                    0 => {
                        const hs_div = @min(io.MCLK.HSDIV.read().DIV.raw, 1);
                        _ = std.fmt.bufPrintZ(
                            &buffer,
                            "High-Speed Clock ({s} / {d}): {d} Hz",
                            .{ @tagName(config.SRC.value), div * hs_div, freq / hs_div },
                        ) catch {};
                        @breakpoint();
                        const cpu_div = @min(io.MCLK.CPUDIV.read().DIV.raw, 1);
                        _ = std.fmt.bufPrintZ(
                            &buffer,
                            "CPU Clock ({s} / {d}): {d} Hz",
                            .{ @tagName(config.SRC.value), div * cpu_div, freq / cpu_div },
                        ) catch {};
                        @breakpoint();
                    },
                    else => {},
                }
                _ = std.fmt.bufPrintZ(
                    &buffer,
                    "Generator #{d} ({s} / {d}): {d} Hz",
                    .{ gen_id, @tagName(config.SRC.value), div, freq },
                ) catch {};
                @breakpoint();
            } else {
                _ = std.fmt.bufPrintZ(&buffer, "Unable to measure generator #{d}", .{gen_id}) catch {};
                @breakpoint();
            }
        }

        io.GCLK.PCHCTRL[GCLK.PCH.FREQM_MSR].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.PCHCTRL[GCLK.PCH.FREQM_REF].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });

        io.MCLK.APBAMASK.modify(.{ .FREQM_ = 0 });

        for (0.., &io.GCLK.PCHCTRL) |pch_id, *pch_ctrl| {
            const config = pch_ctrl.read();
            if (config.CHEN == 0) continue;
            _ = std.fmt.bufPrintZ(
                &buffer,
                "Peripheral Channel #{d}: Generator #{d}",
                .{ pch_id, config.GEN.raw },
            ) catch {};
            @breakpoint();
        }

        if (true) while (true) asm volatile ("");
    }

    timer.init();
    audio.init();
    init_frame_sync();

    // Light sensor adc
    light_sensor_pin.set_mux(.B);

    const state = clocks.get_state();
    const freqs = clocks.Frequencies.get(state);
    _ = freqs;

    const lcd = Lcd.init(.{
        .spi = sercom.spi.Master.init(.SERCOM4, .{
            .cpha = .LEADING_EDGE,
            .cpol = .IDLE_LOW,
            .dord = .MSB,
            .dopo = .PAD2,
            .ref_freq_hz = 120_000_000,
            .baud_freq_hz = 4_000_000,
        }),
        .pins = .{
            .rst = board.TFT_RST,
            .lite = board.TFT_LITE,
            .dc = board.TFT_DC,
            .cs = board.TFT_CS,
            .sck = board.TFT_SCK,
            .mosi = board.TFT_MOSI,
        },
        .fb = .{
            .bpp16 = @ptrCast(cart.api.framebuffer),
        },
    });

    lcd.clear_screen(.{ .r = 0, .g = 0, .b = 0 });

    const neopixels = board.Neopixels.init(board.D8_NEOPIX);
    adc.init();
    const poller = ButtonPoller.init();
    led_pin.set_dir(.out);

    cart.start();
    while (true) {
        //if (!frame_is_ready())
        //    continue;

        const light_reading = adc.single_shot_blocking(.AIN6);
        cart.api.light_level.* = @intCast(light_reading);

        const buttons = poller.read_from_port();
        cart.api.controls.* = .{
            .start = buttons.start == 1,
            .select = buttons.select == 1,
            .a = buttons.a == 1,
            .b = buttons.b == 1,
            .click = buttons.click == 1,
            .up = buttons.up == 1,
            .down = buttons.down == 1,
            .left = buttons.left == 1,
            .right = buttons.right == 1,
        };

        cart.tick();
        var pixels: [5]board.NeopixelColor = undefined;
        for (&pixels, cart.api.neopixels) |*local, pixel|
            local.* = .{
                .r = pixel.r,
                .g = pixel.g,
                .b = pixel.b,
            };

        neopixels.write(&pixels);
        led_pin.write(if (cart.api.red_led.*) .high else .low);
        lcd.set_window(0, 0, 160, 128);
        lcd.send_colors(@ptrCast(cart.api.framebuffer));
    }
}

pub fn init_frame_sync() void {
    TC4.COUNT16.CTRLA.write(.{
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
    while (TC4.COUNT16.SYNCBUSY.read().ENABLE != 0) {}

    TC4.COUNT16.CTRLA.write(.{
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
    while (TC4.COUNT16.SYNCBUSY.read().SWRST != 0) {}
    TC4.COUNT16.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 0,
        .MODE = .{ .value = .COUNT16 },
        .PRESCSYNC = .{ .value = .PRESC },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV64 },
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
    TC4.COUNT16.WAVE.write(.{ .WAVEGEN = .{ .value = .MFRQ }, .padding = 0 });
    TC4.COUNT16.CC[0].write(.{ .CC = @divExact(8_467_200, 64 * 60) - 1 });
    while (TC4.COUNT16.SYNCBUSY.read().CC0 != 0) {}
    TC4.COUNT16.CTRLA.write(.{
        .SWRST = 0,
        .ENABLE = 1,
        .MODE = .{ .value = .COUNT16 },
        .PRESCSYNC = .{ .value = .PRESC },
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
        .PRESCALER = .{ .value = .DIV64 },
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
    while (TC4.COUNT16.SYNCBUSY.read().ENABLE != 0) {}
    TC4.COUNT16.CTRLBSET.write(.{
        .DIR = 0,
        .LUPD = 0,
        .ONESHOT = 0,
        .reserved5 = 0,
        .CMD = .{ .value = .RETRIGGER },
    });
    while (TC4.COUNT16.SYNCBUSY.read().CTRLB != 0) {}
}

pub fn frame_is_ready() bool {
    if (TC4.COUNT16.INTFLAG.read().OVF != 1) return false;
    TC4.COUNT16.INTFLAG.write(.{
        .OVF = 1,
        .ERR = 0,
        .reserved4 = 0,
        .MC0 = 0,
        .MC1 = 0,
        .padding = 0,
    });
    return true;
}
