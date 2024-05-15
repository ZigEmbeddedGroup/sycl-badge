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
const GCLK = chip.peripherals.GCLK;
const OSCCTRL = chip.peripherals.OSCCTRL;
const TC4 = chip.peripherals.TC4;
const MCLK = chip.peripherals.MCLK;

const cart = @import("badge/cart.zig");

const led_pin = board.D13;

const Lcd = board.Lcd;
const ButtonPoller = board.ButtonPoller;
const light_sensor_pin = microzig.board.A7_LIGHT;

const adc = hal.adc.num(0);

pub const microzig_options = .{
    .interrupts = .{
        .SVCall = microzig.interrupt.Handler{ .Naked = cart.svcall_handler },
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

    clocks.mclk.set_ahb_mask(.{ .CMCC = .enabled });
    CMCC.CTRL.write(.{
        .CEN = 1,
        .padding = 0,
    });

    NVMCTRL.CTRLA.modify(.{ .AUTOWS = 1 });
    clocks.gclk.reset_blocking();
    microzig.cpu.dmb();

    // audio init
    //
    // MPU.RBAR
    // MPU.RASR
    // MPU.RBAR_A1
    // MPU.RASR_A1
    // MPU.RBAR_A2
    // MPU.RASR_A2
    // MPU.CTRL

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

    timer.init();
    init_frame_sync();

    // Light sensor adc
    light_sensor_pin.set_mux(.B);
    clocks.mclk.set_apb_mask(.{
        .ADC0 = .enabled,
        .TC0 = .enabled,
        .TC1 = .enabled,
        .TC4 = .enabled,
        .SERCOM4 = .enabled,
    });

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

    lcd.clear_screen(.{ .r = 31, .g = 0, .b = 0 });

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
