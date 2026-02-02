/// Cart (Core 1) entry point, dedicated to running user programs
/// This is the Core 1 equivalent of kernel.zig
const std = @import("std");
const microzig = @import("microzig");

const multicore = @import("system/multicore.zig");
const mailbox = @import("ipc/mailbox.zig");
const loader = @import("loader/loader.zig");
const storage = @import("loader/storage.zig");
const shared_mem = @import("ipc/shared_mem.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;

/// Get cart_xip base address
fn getCartXipStart() u32 {
    return @intFromPtr(&__cart_xip_start__);
}

/// Core 1 main entry point
/// Initializes IPC, waits for Core 0 to signal start, then enters main loop
pub fn main() noreturn {
    // Initialize Core 1's environment
    multicore.initCore1Environment();

    // Wait for Core 0 to signal that we should start
    // This ensures Core 0 (kernel) is fully initialized before Core 1 (carts) begins processing
    waitForStartSignal();

    // Enter main loop
    mainLoop();
}

/// Wait for Core 0 to send the start signal
fn waitForStartSignal() void {
    while (true) {
        if (mailbox.tryReceive()) |msg| {
            if (msg == mailbox.MessageType.CORE_START) {
                // Core 0 has signaled us to start
                return;
            }
            // If it's a different message, do something with it
            // For now just continue waiting for CORE_START
        }
        microzig.cpu.nop();
    }
}

/// Main loop for Core 1
/// Processes messages from Core 0 (loader requests, cart execution, etc.)
fn mainLoop() noreturn {
    while (true) {
        // Check for messages from Core 0
        if (mailbox.tryReceive()) |msg| {
            handleMessage(msg);
        }

        // Small delay to prevent busy-waiting
        microzig.cpu.nop();
    }
}

/// Handle a message from Core 0
fn handleMessage(msg: mailbox.Message) void {
    // Handle core control messages (exact match)
    if (msg == mailbox.MessageType.CORE_STOP) {
        // Core 0 wants Core 1 to stop
        // Halt until reset
        while (true) {
            microzig.cpu.wfi();
        }
    } else if (msg == mailbox.MessageType.CORE_RESET) {
        // Core 0 wants Core 1 to reset
        // Re-enter main loop
        return;
    } else if (msg == mailbox.MessageType.CORE_START) {
        // Already started, ignore
        return;
    }

    // Handle typed messages (with message type prefix)
    const msg_type = mailbox.MessageType.getType(msg);

    switch (msg_type) {
        mailbox.MessageType.CART_EXECUTE => {
            // Execute cart at the given entry point offset
            const entry_offset = mailbox.MessageType.getEntryPointOffset(msg);
            executeCart(entry_offset);
        },
        mailbox.MessageType.CART_LOAD => {
            // Legacy cart load (deprecated)
            const payload = mailbox.MessageType.getPayload(msg);
            handleCartLoad(payload);
        },
        mailbox.MessageType.CART_STOP => {
            loader.stop();
        },
        0x10 => {
            // Legacy loader messages
            if (msg == mailbox.MessageType.LOAD_REQUEST) {
                const payload = mailbox.MessageType.getPayload(msg);
                handleLoadRequest(payload);
            }
        },
        else => {
            // Unknown message type
        },
    }
}

/// Execute a cart loaded in cart_xip region
/// entry_offset: Offset from cart_xip_start to the entry point
fn executeCart(entry_offset: u24) void {
    const cart_xip_start = getCartXipStart();
    const entry_point = cart_xip_start + entry_offset;

    // Signal that we're starting execution
    mailbox.send(mailbox.MessageType.CART_RUNNING);

    // Mark cart as running in loader state
    loader.markRunning();

    // Read initial stack pointer from vector table at cart_xip_start
    // ARM Cortex-M vector table: [0] = initial SP, [1] = Reset_Handler
    const vector_table: *const [2]u32 = @ptrFromInt(cart_xip_start);
    const initial_sp = vector_table[0];

    // Jump to cart entry point
    // This is a one-way jump - the cart takes over Core 1
    jumpToCart(initial_sp, entry_point);

    // If we somehow return (cart exited), signal completion
    mailbox.send(mailbox.MessageType.CART_FINISHED);
    loader.stop();
}

/// Jump to cart code with new stack pointer
/// This function does not return - it transfers control to the cart
fn jumpToCart(stack_pointer: u32, entry_point: u32) void {
    // Set up the stack pointer and jump to the entry point
    // Using inline assembly for ARM Cortex-M
    asm volatile (
        \\  msr msp, %[sp]
        \\  dsb
        \\  isb
        \\  bx %[entry]
        :
        : [sp] "r" (stack_pointer),
          [entry] "r" (entry_point),
    );

    // Should never reach here
    unreachable;
}

/// Handle a legacy load request from Core 0
fn handleLoadRequest(payload: u24) void {
    _ = payload;
    mailbox.send(mailbox.MessageType.LOAD_COMPLETE);
}

/// Handle legacy cart load (deprecated - use UF2 loading instead)
fn handleCartLoad(payload: u24) void {
    const region_id: shared_mem.RegionId = @intCast(payload);
    const mem = shared_mem.attach(region_id) orelse {
        mailbox.send(mailbox.MessageType.LOAD_ERROR);
        return;
    };
    if (mem.len < @sizeOf(loader.CartLoadRequest)) {
        mailbox.send(mailbox.MessageType.LOAD_ERROR);
        return;
    }
    const req = std.mem.bytesAsValue(loader.CartLoadRequest, mem[0..@sizeOf(loader.CartLoadRequest)]).*;
    const info: storage.CartInfo = .{
        .start_cluster = req.start_cluster,
        .size = req.size,
        .short_name = [_]u8{0} ** 12,
    };
    if (loader.loadCart(info)) {
        mailbox.send(mailbox.MessageType.LOAD_COMPLETE);
    } else {
        mailbox.send(mailbox.MessageType.LOAD_ERROR);
    }
}
