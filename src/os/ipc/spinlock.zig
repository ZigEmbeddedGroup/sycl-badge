/// Spinlock for multicore synchronization
/// Re-exports MicroZig's hardware spinlock implementation
const microzig = @import("microzig");

// Re-export MicroZig's Spinlock directly
// Usage: const lock = Spinlock.init(0);
//        lock.lock();
//        defer lock.unlock();
pub const Spinlock = microzig.hal.multicore.Spinlock;
