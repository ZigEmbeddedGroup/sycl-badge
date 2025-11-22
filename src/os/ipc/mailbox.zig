/// Inter-core mailbox using RP2350 hardware FIFO
/// Wraps MicroZig hal.multicore.fifo
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const timer = @import("../drivers/timer.zig");

const fifo = hal.multicore.fifo;

/// Message type for inter-core communication
/// The FIFO can hold 32-bit values, so we use u32 as the message type
/// For more complex messages, use a pointer to shared memory
///
/// Memory Layout:
/// - Core 0 (Kernel): 0x20000000 - 0x20020000 (128KB, 1/4 SRAM)
/// - Core 1 (User): 0x20020000 - 0x20080000 (384KB, 3/4 SRAM)
/// - Shared memory: 0x2001C000 - 0x20020000 (64KB, accessible to both cores)
pub const Message = u32;

/// Mailbox error types
pub const Error = error{
    FIFOFull,
    FIFOEmpty,
    Timeout,
};

/// Send a message to the other core (blocking)
/// Blocks until there's space in the FIFO
pub fn send(msg: Message) void {
    fifo.push_blocking(msg);
}

/// Send a message to the other core (non-blocking)
/// Returns error if FIFO is full
pub fn trySend(msg: Message) Error!void {
    if (fifo.try_push(msg)) {
        return;
    } else {
        return Error.FIFOFull;
    }
}

/// Receive a message from the other core (blocking)
/// Blocks until a message is available
pub fn receive() Message {
    return fifo.pop_blocking();
}

/// Receive a message from the other core (non-blocking)
/// Returns null if no message is available
pub fn tryReceive() ?Message {
    return fifo.try_pop();
}

/// Clear all messages from the FIFO
pub fn clear() void {
    while (fifo.try_pop()) |_| {}
}

/// Message type constants for common operations
pub const MessageType = struct {
    // Core control messages
    pub const CORE_READY: Message = 0x00000001; // Core 1 signals it's initialized and ready
    pub const CORE_START: Message = 0x00000002; // Core 0 tells Core 1 to start processing
    pub const CORE_STOP: Message = 0x00000003;
    pub const CORE_RESET: Message = 0x00000004;

    // Loader messages
    pub const LOAD_REQUEST: Message = 0x10000000;
    pub const LOAD_COMPLETE: Message = 0x10000001;
    pub const LOAD_ERROR: Message = 0x10000002;

    // Application messages (user-defined range: 0x20000000 - 0xFFFFFFFF)
    pub const APP_BASE: Message = 0x20000000;

    /// Create a custom message type with payload
    /// Usage: MessageType.withPayload(0x01, 0x12345678) -> 0x0112345678
    pub fn withPayload(msg_type: u8, payload: u24) Message {
        return (@as(Message, msg_type) << 24) | payload;
    }

    /// Extract message type from a message
    pub fn getType(msg: Message) u8 {
        return @truncate(msg >> 24);
    }

    /// Extract payload from a message
    pub fn getPayload(msg: Message) u24 {
        return @truncate(msg);
    }
};
