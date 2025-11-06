/// Shared memory region for inter-core communication
/// PICO_SHARED_MEMORY starts at 0x20000000 and is 64KB in size (I think)
const std = @import("std");
const microzig = @import("microzig");