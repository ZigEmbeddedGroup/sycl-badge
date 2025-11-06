/// Program loader, loads user programs from flash to RAM
const std = @import("std");
const microzig = @import("microzig");
const mailbox = @import("../ipc/mailbox.zig");
