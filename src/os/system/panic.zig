/// Panic handler for kernel (We can just copy the panic from kernel.zig and replace it by calling this file)
const std = @import("std");
const microzig = @import("microzig");
const multicore = @import("multicore.zig");