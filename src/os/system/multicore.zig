/// Multicore management
const std = @import("std");
const microzig = @import("microzig");
const cart = @import("../cart.zig");

const interrupt = microzig.interrupts;
const peripherals = microzig.chip.peripherals;

const CriticalSection = interrupt.CriticalSection;
const SIO = peripherals.SIO;
const PSM = peripherals.PSM;
const PPB = peripherals.PPB;
