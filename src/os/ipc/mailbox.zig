/// Inter-core mailbox using RP2354B hardware FIFO
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
    fifo.write_blocking(msg);
}

/// Send a message to the other core (non-blocking)
/// Returns error if FIFO is full
pub fn trySend(msg: Message) Error!void {
    if (fifo.write(msg)) {
        return;
    } else {
        return Error.FIFOFull;
    }
}

/// Receive a message from the other core (blocking)
/// Blocks until a message is available
pub fn receive() Message {
    return fifo.read_blocking();
}

/// Receive a message from the other core (non-blocking)
/// Returns null if no message is available
pub fn tryReceive() ?Message {
    return fifo.read();
}

/// Clear all messages from the FIFO
pub fn clear() void {
    while (fifo.read()) |_| {}
}

/// Message type constants for common operations
pub const MessageType = struct {
    // Core control messages
    pub const CORE_READY: Message = 0x00000001; // Core 1 signals it's initialized and ready
    pub const CORE_START: Message = 0x00000002; // Core 0 tells Core 1 to start processing
    pub const CORE_STOP: Message = 0x00000003;
    pub const CORE_RESET: Message = 0x00000004;

    // Loader messages (legacy)
    pub const LOAD_REQUEST: Message = 0x10000000;
    pub const LOAD_COMPLETE: Message = 0x10000001;
    pub const LOAD_ERROR: Message = 0x10000002;

    // UF2 loader messages
    pub const UF2_LOAD_START: Message = 0x10000010; // Core 0 starting UF2 load
    pub const UF2_LOAD_COMPLETE: Message = 0x10000011; // UF2 load complete, ready to execute
    pub const UF2_LOAD_ERROR: Message = 0x10000012; // UF2 load failed

    // Cart execution messages
    // CART_EXECUTE: payload contains entry point address (lower 24 bits)
    // For full 32-bit entry point, use shared memory
    pub const CART_EXECUTE: u8 = 0x20; // Execute cart at entry point
    pub const CART_RUNNING: Message = 0x20000001; // Core 1 confirms cart is running
    pub const CART_FINISHED: Message = 0x20000002; // Cart execution completed
    pub const CART_CRASHED: Message = 0x20000003; // Cart crashed/faulted

    // Cart control message types (use withPayload)
    pub const CART_LOAD: u8 = 0x11;
    pub const CART_STOP: u8 = 0x12;

    // Framebuffer sync messages (new-API carts)
    // Core 1 sends FRAMEBUFFER_READY after finishing a frame.
    // Core 0 flushes the shared-RAM framebuffer to the LCD, then
    // replies with FRAMEBUFFER_DONE so Core 1 knows it can start
    // writing the next frame without tearing.
    pub const FRAMEBUFFER_READY: Message = 0x25000001;
    pub const FRAMEBUFFER_DONE: Message = 0x25000002;

    // Async/double-buffer framebuffer present (type + payload)
    // Message type: 0x28
    // payload bit 0 = buffer index (0 or 1)
    // payload bit 1 = dirty-rect present (1 = use CART_DIRTY_RECT_*)
    pub const FRAMEBUFFER_READY_V2: u8 = 0x28;

    /// Cart trace (debug) messages: type 0x26, payload = length.
    /// Cart writes string to CART_TRACE_BUF before sending.
    /// Located at 0x20034020 (immediately after two framebuffers:
    /// 0x20020020 + 2 * 0xA000).
    /// The cart linker script reserves 0x20034020–0x200340FF for IPC buffers so
    /// cart globals never alias these addresses.
    pub const CART_TRACE: u8 = 0x26;
    pub const CART_TRACE_BUF: u32 = 0x20034020; // 128 bytes, after both framebuffers
    pub const CART_TRACE_BUF_SIZE: u32 = 128;

    /// Cart tone (buzzer) messages: type 0x27.
    /// Cart writes freq (u32) and duration (u32) to CART_TONE_* before sending.
    /// Duration is in 60ths of a second (same as ToneOptions); kernel converts to ms.
    pub const CART_TONE: u8 = 0x27;
    pub const CART_TONE_FREQ: u32 = 0x200340A0; // freq_hz (u32)
    pub const CART_TONE_DURATION: u32 = 0x200340A4; // duration in 60ths (u32)

    /// Dirty-rectangle metadata for FRAMEBUFFER_READY_V2 (all u16).
    /// Rect is in cart space: x:[0..159], y:[0..127], width:[1..160], height:[1..128]
    pub const CART_DIRTY_RECT_X: u32 = 0x200340B0;
    pub const CART_DIRTY_RECT_Y: u32 = 0x200340B2;
    pub const CART_DIRTY_RECT_W: u32 = 0x200340B4;
    pub const CART_DIRTY_RECT_H: u32 = 0x200340B6;

    // Application messages (user-defined range: 0x30000000 - 0xFFFFFFFF)
    pub const APP_BASE: Message = 0x30000000;

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

    /// Create a CART_EXECUTE message with entry point offset
    /// The offset is relative to cart_xip_start (0x101C0000)
    /// This allows 24-bit payload to address full 256KB cart region
    pub fn cartExecute(entry_point_offset: u24) Message {
        return withPayload(CART_EXECUTE, entry_point_offset);
    }

    /// Check if a message is a CART_EXECUTE message
    pub fn isCartExecute(msg: Message) bool {
        return getType(msg) == CART_EXECUTE;
    }

    /// Get entry point offset from CART_EXECUTE message
    pub fn getEntryPointOffset(msg: Message) u24 {
        return getPayload(msg);
    }
};
