/// Spinlock for multicore synchronization
const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;

pub const Spinlock = hal.multicore.Spinlock;
