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

const led_pin = board.A5_D13;

const lcd = board.lcd;
const ButtonPoller = board.ButtonPoller;
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
    // Enable safety traps
    SystemControl.CCR.modify(.{
        .NONBASETHRDENA = 0,
        .USERSETMPEND = 0,
        .UNALIGN_TRP = .{ .value = .VALUE_0 }, // TODO
        .DIV_0_TRP = 1,
        .BFHFNMIGN = 0,
        .STKALIGN = .{ .value = .VALUE_1 },
    });
    // Enable FPU access.
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
    microzig.cpu.dmb();

    clocks.gclk.reset_blocking();

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

    const dpll0_factor = 1;
    clocks.enable_dpll(0, .GCLK2, .{
        .factor = dpll0_factor,
        .input_freq_hz = 1_000_000,
        .output_freq_hz = 120_000_000,
    });

    clocks.gclk.set_peripheral_clk_gen(.GCLK_ADC0, .GCLK2);
    clocks.gclk.set_peripheral_clk_gen(.GCLK_TC0_TC1, .GCLK2);
    clocks.gclk.enable_generator(.GCLK0, .DPLL0, .{
        .divsel = .DIV1,
        .div = dpll0_factor,
    });

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

    const dpll1_factor = 12;
    clocks.enable_dpll(1, .GCLK1, .{
        .factor = dpll1_factor,
        .input_freq_hz = 76_800,
        .output_freq_hz = 8_467_200,
    });

    clocks.gclk.enable_generator(.GCLK3, .DPLL1, .{
        .divsel = .DIV1,
        .div = dpll1_factor,
    });
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

    timer.init();
    audio.init(&cart.call_audio);

    // Light sensor adc
    microzig.board.A6_LIGHT.set_mux(.B);

    const state = clocks.get_state();
    const freqs = clocks.Frequencies.get(state);
    _ = freqs;

    lcd.init(.bpp16, @ptrCast(cart.api.framebuffer));

    const neopixels = board.Neopixels.init(board.D8_NEOPIX);
    adc.init(.DIV16);
    adc.set_input(.AIN6, .GND, .single_ended, .stop);
    adc.enable();
    const poller = ButtonPoller.init();
    led_pin.set_dir(.out);

    cart.start();
    while (true) {
        const light_reading = adc.single_shot_blocking();
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
    }
}
