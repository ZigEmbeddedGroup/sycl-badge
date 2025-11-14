/// Multicore management
const std = @import("std");
const microzig = @import("microzig");
const core1 = @import("../core1.zig");

const interrupt = microzig.interrupts;
const peripherals = microzig.chip.peripherals;

const CriticalSection = interrupt.CriticalSection;
const SIO = peripherals.SIO;
const PSM = peripherals.PSM;
const PPB = peripherals.PPB;
