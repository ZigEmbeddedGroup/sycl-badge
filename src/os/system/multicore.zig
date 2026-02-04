/// Multicore management
/// Handles initialization and coordination of Core 1 (user program loader)
const std = @import("std");
const microzig = @import("microzig");
const cart = @import("../cart.zig");
const hal = microzig.hal;
const interrupt = microzig.interrupts;
const peripherals = microzig.chip.peripherals;

const mailbox = @import("../ipc/mailbox.zig");
const shared_mem = @import("../ipc/shared_mem.zig");
const timer = @import("../drivers/timer.zig");

const CriticalSection = interrupt.CriticalSection;
const SIO = peripherals.SIO;
const PSM = peripherals.PSM;
const PPB = peripherals.PPB;

/// Core 1 stack (4 kB)
/// Located in process RAM (Core 1's memory)
var core1_stack: [1024]u32 align(8) linksection(".process_ram") = undefined;

extern const _external_interrupt_table: usize; // For riscv only

pub const fifo = hal.multicore.fifo;

/// Core 1 initialization state
var core1_initialized: bool = false;
var core1_running: bool = false;

/// Initialize Core 1 with default entrypoint (cart.zig main)
/// This sets up IPC, launches core 1, waits for it to be ready, then signals it to start
pub fn initCore1() void {
    if (core1_initialized) {
        return; // Already initialized
    }

    // Initialize IPC systems on Core 0 first (they should already be initialized in theory)
    shared_mem.init();
    mailbox.clear(); // Clear any stale messages

    // Launch Core 1 with cart entrypoint
    launch_core1(cart.main);

    // Wait for Core 1 to signal it's ready
    waitForCore1Ready();

    // Now tell Core 1 to start its main loop
    mailbox.send(mailbox.MessageType.CORE_START);

    core1_initialized = true;
    core1_running = true;
}

/// Initialize Core 1 with custom entrypoint
pub fn initCore1WithEntrypoint(entrypoint: *const fn () void) void {
    if (core1_initialized) {
        return; // If already initialized
    }

    // Initialize IPC systems on Core 0 first
    shared_mem.init();
    mailbox.clear();

    // Launch Core 1
    launch_core1(entrypoint);

    // Wait for Core 1 to signal it's ready
    waitForCore1Ready();

    // Now tell Core 1 to start its main loop
    mailbox.send(mailbox.MessageType.CORE_START);

    core1_initialized = true;
    core1_running = true;
}

/// Launch Core 1 with default stack
/// Lower-level function - prefer initCore1() for proper initialization
pub fn launch_core1(entrypoint: *const fn () void) void {
    hal.multicore.launch_core1(entrypoint);
}

/// Launch Core 1 with custom stack
/// Lower-level function - prefer initCore1() for proper initialization
pub fn launch_core1_with_stack(entrypoint: *const fn () void, stack: []u32) void {
    hal.multicore.launch_core1_with_stack(entrypoint, stack);
}

/// Wait for Core 1 to signal it's ready
/// Core 1 should send MessageType.CORE_READY when initialized
fn waitForCore1Ready() void {
    const timeout_us: u64 = 1_000_000; // 1 second timeout
    const start = timer.micros();

    while (true) {
        if (mailbox.tryReceive()) |msg| {
            if (msg == mailbox.MessageType.CORE_READY) {
                return; // Core 1 is ready
            }
        }

        const elapsed = timer.micros() - start;
        if (elapsed >= timeout_us) {
            // Timeout - Core 1 may not have initialized properly
            // Continue anyway, but mark as potentially not ready
            return;
        }

        microzig.cpu.nop();
    }
}

/// Check if Core 1 is running
pub fn isCore1Running() bool {
    return core1_running;
}

/// Check if Core 1 is initialized
pub fn isCore1Initialized() bool {
    return core1_initialized;
}

/// Halt Core 1 (stops execution)
/// Uses processor reset to forcefully stop Core 1
/// This works even if Core 1 is stuck or running a cart
pub fn haltCore1() void {
    if (!core1_running) {
        return;
    }

    // Use PPB (Private Peripheral Bus) to reset Core 1
    // On RP2350, we can use the CPUID and reset mechanism

    // First, drain the FIFO to prevent any stale messages
    mailbox.clear();
    fifo.drain();

    // Reset Core 1 by writing to PSM FRCE_OFF then releasing
    // This forcefully powers down Core 1
    PSM.FRCE_OFF.modify(.{ .PROC1 = 1 });

    // Brief delay for reset to take effect (no waiting on DONE which may hang)
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        microzig.cpu.nop();
    }

    // Release the force-off
    PSM.FRCE_OFF.modify(.{ .PROC1 = 0 });

    // Wait for PSM to settle
    timer.sleep_ms(1);

    // Drain FIFO again after reset
    fifo.drain();
    mailbox.clear();

    core1_running = false;
    core1_initialized = false;
}

/// Reset Core 1 (restarts it)
pub fn resetCore1() void {
    haltCore1();
    timer.sleep_ms(10);

    // Re-launch with cart entrypoint
    launch_core1(cart.main);
    waitForCore1Ready();
    mailbox.send(mailbox.MessageType.CORE_START);
    core1_running = true;
}

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;

/// Get cart_xip base address
fn getCartXipStart() u32 {
    return @intFromPtr(&__cart_xip_start__);
}

/// Execute a cart that has been loaded into cart_xip
/// entry_point: Full 32-bit entry point address
/// Returns true if message was sent successfully
pub fn executeCart(entry_point: u32) bool {
    if (!core1_running) {
        return false;
    }

    const cart_xip_start = getCartXipStart();

    // Calculate offset from cart_xip_start
    // Entry point must be within cart_xip region
    if (entry_point < cart_xip_start) {
        return false;
    }

    const offset = entry_point - cart_xip_start;

    // Offset must fit in 24 bits (256KB = 0x40000, fits in 24 bits)
    if (offset > 0xFFFFFF) {
        return false;
    }

    // Send CART_EXECUTE message to Core 1
    const msg = mailbox.MessageType.cartExecute(@intCast(offset));
    mailbox.send(msg);

    return true;
}

/// Initialize Core 1's environment
/// Should be called at the start of Core 1's main function
/// Sets up IPC and signals Core 0 that Core 1 is ready (but not started yet)
/// Core 1 should then wait for Core 0 to send CORE_START before entering main loop
/// In theory Core 1 should always come after Core 0 so we don't need to worry about this
pub fn initCore1Environment() void {
    // Initialize IPC systems
    shared_mem.init(); // Core 1 can attach to existing regions
    mailbox.clear(); // Clear any stale messages

    // Signal Core 0 that we're initialized and ready
    mailbox.send(mailbox.MessageType.CORE_READY);

    // Memory barrier to ensure message is sent
    microzig.cpu.dmb();
}
