/// Cart (Core 1) entry point, dedicated to running user programs (this is kernel.zig but for the second core)
const std = @import("std");
const microzig = @import("microzig");

const multicore = @import("system/multicore.zig");
const mailbox = @import("ipc/mailbox.zig");
const loader = @import("loader/loader.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

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
/// Processes messages from Core 0 (loader requests, etc.)
fn mainLoop() noreturn {
    while (true) {
        // Check for messages from Core 0
        if (mailbox.tryReceive()) |msg| {
            handleMessage(msg);
        }

        // TODO: Check if a user program is running and needs to be ticked
        // TODO: Handle program execution
        // TODO: Some code for switching programs

        // Small delay to prevent busy-waiting
        microzig.cpu.nop();
    }
}

/// Handle a message from Core 0
fn handleMessage(msg: mailbox.Message) void {
    // Handle core control messages (exact match)
    if (msg == mailbox.MessageType.CORE_STOP) {
        // Core 0 wants Core 1 to stop
        // For now we'll just halt (in the final system, we might want to just clean up)
        while (true) {
            microzig.cpu.nop();
        }
    } else if (msg == mailbox.MessageType.CORE_RESET) {
        // Core 0 wants Core 1 to reset
        // This would typically involve restarting the loader
        // For now we'll just re-enter main loop
        return;
    } else if (msg == mailbox.MessageType.CORE_START) {
        // This should have been handled in waitForStartSignal but handle it here too for safety
        return;
    }

    // Handle typed messages (with message type prefix)
    const msg_type = mailbox.MessageType.getType(msg);

    switch (msg_type) {
        0x10 => {
            // Loader messages
            if (msg == mailbox.MessageType.LOAD_REQUEST) {
                // Core 0 wants us to load a program
                // Extract payload (pointer to cart data or cart ID)
                const payload = mailbox.MessageType.getPayload(msg);
                handleLoadRequest(payload);
            }
        },
        else => {
            // Unknown message type (ignoring for now but might want to log?)
        },
    }
}

/// Handle a load request from Core 0
/// payload: typically a pointer or ID to the cart data
fn handleLoadRequest(payload: u24) void {
    // TODO: Implement actual loading logic

    // temp because we don't have multicore setup yet
    _ = payload;
    mailbox.send(mailbox.MessageType.LOAD_COMPLETE);
}
