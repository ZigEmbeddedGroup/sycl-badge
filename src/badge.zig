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
const hal = microzig.hal;
const clocks = hal.clocks;
const cpu = microzig.cpu;
const chip = microzig.chip;

// direct peripheral access
const SystemControl = chip.peripherals.SystemControl;
const CMCC = chip.peripherals.CMCC;
const NVMCTRL = chip.peripherals.NVMCTRL;
const GCLK = chip.peripherals.GCLK;
const OSCCTRL = chip.peripherals.OSCCTRL;

const cart = @import("badge/cart.zig");

const led_pin = board.D13;

const Lcd = board.Lcd;
const Buttons = board.Buttons;
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

    // init USB
    // usb reinit mode
    // timer init
    // lcd init
    // audio init
    //
    // MPU.RBAR
    // MPU.RASR
    // MPU.RBAR_A1
    // MPU.RASR_A1
    // MPU.RBAR_A2
    // MPU.RASR_A2
    // MPU.CTRL
    //
    // cart init
    //  pins
    //  bss
    //  data

    clocks.gclk.enable_generator(.GCLK0, .OSCULP32K, .{
        .divsel = .DIV1,
        .div = 1,
    });

    clocks.gclk.enable_generator(.GCLK1, .DFLL, .{
        .divsel = .DIV1,
        .div = 48,
    });

    clocks.gclk.set_peripheral_clk_gen(.GCLK_OSCCTRL_FDPLL1, .GCLK1);

    OSCCTRL.DPLL[1].DPLLCTRLB.write(.{
        .FILTER = .{ .value = .FILTER1 },
        .WUF = 0,
        .REFCLK = .{ .value = .GCLK },
        .LTIME = .{ .value = .DEFAULT },
        .LBYPASS = 0,
        .DCOFILTER = .{ .raw = 0 },
        .DCOEN = 0,
        .DIV = 0,
        .padding = 0,
    });

    const dpll1_factor = 1;
    const dpll1_frequency = 120_000_000 * dpll1_factor;
    comptime std.debug.assert(dpll1_frequency >= 96_000_000 and dpll1_frequency <= 200_000_000);
    const dpll1_ratio = @divExact(dpll1_frequency * 32, 1_000_000);
    OSCCTRL.DPLL[1].DPLLRATIO.write(.{
        .LDR = dpll1_ratio / 32 - 1,
        .reserved16 = 0,
        .LDRFRAC = dpll1_ratio % 32,
        .padding = 0,
    });
    while (OSCCTRL.DPLL[1].DPLLSYNCBUSY.read().DPLLRATIO != 0) {}

    OSCCTRL.DPLL[1].DPLLCTRLA.write(.{
        .reserved1 = 0,
        .ENABLE = 1,
        .reserved6 = 0,
        .RUNSTDBY = 0,
        .ONDEMAND = 0,
    });
    while (OSCCTRL.DPLL[1].DPLLSYNCBUSY.read().ENABLE != 0) {}
    while (OSCCTRL.DPLL[1].DPLLSTATUS.read().CLKRDY == 0) {}

    clocks.gclk.enable_generator(.GCLK0, .DPLL1, .{
        .divsel = .DIV1,
        .div = 1,
    });

    // Light sensor adc
    light_sensor_pin.set_mux(.B);
    clocks.mclk.set_apb_mask(.{ .ADC0 = .enabled });
    clocks.gclk.set_peripheral_clk_gen(.GCLK_ADC0, .GCLK1);

    const state = clocks.get_state();
    const freqs = clocks.Frequencies.get(state);
    _ = freqs;

    const neopixels = board.Neopixels.init(board.D8_NEOPIX);
    adc.init();
    Buttons.configure();
    led_pin.set_dir(.out);

    cart.start();
    while (true) {
        const light_reading = adc.single_shot_blocking(.AIN6);
        cart.api.light_level.* = @intCast(light_reading);

        const buttons = Buttons.read_from_port();
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
    }
}
