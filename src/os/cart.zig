/// Cart (Core 1) entry point, dedicated to running user programs
/// This is the Core 1 equivalent of kernel.zig
const std = @import("std");
const microzig = @import("microzig");

const multicore = @import("system/multicore.zig");
const interrupts = @import("system/interrupts.zig");
const mailbox = @import("ipc/mailbox.zig");
const loader = @import("loader/loader.zig");
const storage = @import("loader/storage.zig");
const shared_mem = @import("ipc/shared_mem.zig");

// Use panic handler from system
pub const panic = @import("system/panic.zig").panic;

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;
extern const __cart_xip_end__: u8;

/// Get cart_xip base address
fn getCartXipStart() u32 {
    return @intFromPtr(&__cart_xip_start__);
}

fn getCartXipEnd() u32 {
    return @intFromPtr(&__cart_xip_end__);
}

fn clearCore1InterruptAndFaultState() void {
    // Disable all external IRQs for Core 1 and clear pending bits.
    const NVIC_ICER0: *volatile u32 = @ptrFromInt(0xE000E180);
    const NVIC_ICER1: *volatile u32 = @ptrFromInt(0xE000E184);
    const NVIC_ICPR0: *volatile u32 = @ptrFromInt(0xE000E280);
    const NVIC_ICPR1: *volatile u32 = @ptrFromInt(0xE000E284);
    NVIC_ICER0.* = 0xFFFF_FFFF;
    NVIC_ICER1.* = 0xFFFF_FFFF;
    NVIC_ICPR0.* = 0xFFFF_FFFF;
    NVIC_ICPR1.* = 0xFFFF_FFFF;

    // Disable SysTick and clear pending exceptions that can fire immediately after handoff if not cleaned.
    const SYST_CSR: *volatile u32 = @ptrFromInt(0xE000E010);
    const SCB_ICSR: *volatile u32 = @ptrFromInt(0xE000ED04);
    SYST_CSR.* = 0;
    SCB_ICSR.* = (1 << 27) | (1 << 25); // PENDSVCLR | PENDSTCLR

    // Clear sticky fault status so stale kernel/cart faults don't poison next cart launch.
    const SCB_CFSR: *volatile u32 = @ptrFromInt(0xE000ED28);
    const SCB_HFSR: *volatile u32 = @ptrFromInt(0xE000ED2C);
    const SCB_DFSR: *volatile u32 = @ptrFromInt(0xE000ED30);
    SCB_CFSR.* = 0xFFFF_FFFF;
    SCB_HFSR.* = 0xFFFF_FFFF;
    SCB_DFSR.* = 0xFFFF_FFFF;

    asm volatile ("dsb");
    asm volatile ("isb");
}

/// Core 1 main entry point
/// Initializes IPC, waits for Core 0 to signal start, then enters main loop
pub fn main() noreturn {
    // Disable interrupts on Core 1 to prevent unhandled IRQs (e.g. DMA, USB)
    // from reaching the default panic handler when running cart code.
    interrupts.disableInterrupts();

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

/// Execute a cart loaded in cart_xip region.
/// Core 0 is the sole authority over loader state transitions (markRunning /
/// stop), so Core 1 must NOT touch loader.cart_state.  Doing so from both
/// cores creates a data race that can make the kernel see the state flicker,
/// causing it to treat the cart as stopped and restart the menu while the
/// cart is still running.
fn executeCart(vector_table_offset: u24) void {
    const cart_xip_start = getCartXipStart();
    const cart_xip_end = getCartXipEnd();
    const vector_table_addr = cart_xip_start + vector_table_offset;

    mailbox.send(mailbox.MessageType.CART_RUNNING);

    const vector_table: *const [2]u32 = @ptrFromInt(vector_table_addr);
    const initial_sp = vector_table[0];
    const entry_point = vector_table[1];

    // Validate SP/PC from cart vector table before taking over Core 1.
    // Bad values here often show up later as UsageFault INVSTATE on first
    // exception entry/return.
    if ((initial_sp & 0x7) != 0) {
        mailbox.send(mailbox.MessageType.CART_CRASHED);
        return;
    }
    if (initial_sp < 0x2002A100 or initial_sp > 0x20080000) {
        mailbox.send(mailbox.MessageType.CART_CRASHED);
        return;
    }
    if ((entry_point & 0x1) == 0) {
        mailbox.send(mailbox.MessageType.CART_CRASHED);
        return;
    }
    const entry_even = entry_point & 0xFFFF_FFFE;
    if (entry_even < cart_xip_start or entry_even >= cart_xip_end) {
        mailbox.send(mailbox.MessageType.CART_CRASHED);
        return;
    }

    clearCore1InterruptAndFaultState();

    // Point Core 1's VTOR at the cart's vector table so that any exceptions
    // (HardFault, etc.) use the cart's handlers instead of the OS kernel's.
    const VTOR: *volatile u32 = @ptrFromInt(0xE000ED08);
    VTOR.* = vector_table_addr;

    asm volatile ("dsb");
    asm volatile ("isb");

    // One-way jump — the cart takes over Core 1.  jumpToCart never returns.
    jumpToCart(initial_sp, entry_point);
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
        .short_name = @splat(0),
        .long_name = undefined,
        .long_name_len = 0,
    };
    if (loader.loadCart(info)) {
        mailbox.send(mailbox.MessageType.LOAD_COMPLETE);
    } else {
        mailbox.send(mailbox.MessageType.LOAD_ERROR);
    }
}
