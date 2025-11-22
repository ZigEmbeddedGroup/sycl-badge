/// Spinlock for multicore synchronization
/// Provides synchronization functions for inter-core communication
const std = @import("std");
const microzig = @import("microzig");

const hal = microzig.hal;
const timer = @import("../drivers/timer.zig");

pub const Spinlock = hal.multicore.Spinlock;

/// Spinlock guard - automatically releases the lock when it goes out of scope
/// Usage:
///   var guard = try lock.acquireGuard();
///   defer guard.release();
///   // ... protected code ...
///  Be very careful about using this. If you can, use the withLock functions instead cause it might cause deadlocks.
pub const Guard = struct {
    lock: *Spinlock,
    acquired: bool,

    /// Release the lock (called automatically on drop/defer)
    pub fn release(self: *Guard) void {
        if (self.acquired) {
            self.lock.release();
            self.acquired = false;
        }
    }
};

/// Acquire a spinlock and return a guard
/// The guard will automatically release the lock when it goes out of scope
/// Usage:
///   var guard = acquireGuard(&lock);
///   defer guard.release();
pub fn acquireGuard(lock: *Spinlock) Guard {
    lock.acquire();
    return Guard{
        .lock = lock,
        .acquired = true,
    };
}

/// Try to acquire a spinlock without blocking (this is a microzig wrapper)
/// Returns true if the lock was acquired, false if it was already held
/// RP2350 uses hardware spinlocks (SIO block) which support non-blocking acquisition
pub fn tryAcquire(lock: *Spinlock) bool {
    return lock.try_acquire();
}

/// Try to acquire a spinlock with timeout (in microseconds)
/// Returns true if the lock was acquired, false if timeout expired
pub fn tryAcquireTimeout(lock: *Spinlock, timeout_us: u64) bool {
    const start = timer.micros();

    while (true) {
        if (tryAcquire(lock)) {
            return true;
        }

        const elapsed = timer.micros() - start;
        if (elapsed >= timeout_us) {
            return false;
        }

        // Small delay to avoid busy-waiting
        microzig.cpu.nop();
        microzig.cpu.nop();
    }
}

/// Execute a function while holding a spinlock
/// The lock is automatically acquired before execution and released after
/// Usage:
///   lock.withLock(() {
///       // protected code
///   });
pub fn withLock(lock: *Spinlock, comptime func: anytype) @TypeOf(func()) {
    lock.acquire();
    defer lock.release();
    return func();
}
