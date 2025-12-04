/// Shared memory region for inter-core communication
/// RP2354B Memory Layout:
/// - Kernel RAM (Core 0): 0x20000000 - 0x20020000 (128KB, 1/4 of SRAM)
/// - Process RAM (Core 1): 0x20020000 - 0x20080000 (384KB, 3/4 of SRAM)
/// - Shared memory is placed at a fixed address accessible to both cores
///   Located at the end of kernel RAM to allow both cores to access it
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

const Spinlock = @import("spinlock.zig").Spinlock;

/// Shared memory region identifier
pub const RegionId = u8;

/// Maximum number of shared memory regions
const MAX_REGIONS = 16;

/// Shared memory pool base address
/// Located at 0x2001C000 (64KB before end of kernel RAM)
/// This leaves 64KB for kernel use and provides 64KB for shared memory
/// Both cores can access this region since they share the same physical SRAM
pub const SHARED_MEM_BASE_ADDR: u32 = 0x2001C000;
pub const SHARED_MEM_POOL_SIZE: usize = 64 * 1024; // 64KB

/// Shared memory region descriptor
const Region = struct {
    id: RegionId,
    base: [*]u8,
    size: usize,
    in_use: bool,
};

/// Shared memory registry structure - placed at the start of shared memory
/// This ensures both cores can access the registry
const Registry = struct {
    regions: [MAX_REGIONS]Region,
    next_region_id: RegionId,
    pool_offset: usize,
    lock: Spinlock,
};

/// Shared memory pool - located at fixed address accessible to both cores
/// Registry is at the start, followed by the actual memory pool
const REGISTRY_SIZE: usize = std.mem.alignForward(usize, @sizeOf(Registry), 4);
const POOL_SIZE: usize = SHARED_MEM_POOL_SIZE - REGISTRY_SIZE;

/// Get pointer to registry structure
fn getRegistryPtr() *Registry {
    return @ptrFromInt(SHARED_MEM_BASE_ADDR);
}

/// Get pointer to shared memory pool (after registry)
fn getPoolPtr() *[POOL_SIZE]u8 {
    return @ptrFromInt(SHARED_MEM_BASE_ADDR + REGISTRY_SIZE);
}

/// Initialize the shared memory system
/// Must be called once per core before using shared memory
/// Core 0 should initialize first, then core 1 can attach
pub fn init() void {
    const registry = getRegistryPtr();

    // Only initialize on first call (use a simple flag check)
    registry.lock.lock();
    defer registry.lock.unlock();

    // Check if already initialized (next_region_id != 0 means initialized)
    if (registry.next_region_id == 0) {
        // Initialize registry
        for (&registry.regions) |*region| {
            region.* = .{
                .id = 0,
                .base = undefined,
                .size = 0,
                .in_use = false,
            };
        }
        registry.next_region_id = 1;
        registry.pool_offset = 0;
        registry.lock = hal.multicore.Spinlock.init(0); // Use hardware spinlock 0

        // Clear the pool
        const pool = getPoolPtr();
        @memset(pool, 0);

        microzig.cpu.dmb();
    }
}

/// Create a new shared memory region
/// Returns a slice to the allocated memory, or null if allocation fails
/// The region can be accessed by both cores using the returned ID
pub fn create(size: usize) ?struct { id: RegionId, mem: []u8 } {
    // Ensure size is aligned to 4 bytes
    const aligned_size = std.mem.alignForward(usize, size, 4);

    if (aligned_size == 0 or aligned_size > SHARED_MEM_POOL_SIZE) {
        return null;
    }

    const registry = getRegistryPtr();
    const pool = getPoolPtr();

    registry.lock.lock();
    defer registry.lock.unlock();

    // Check if we have space in the pool
    if (registry.pool_offset + aligned_size > POOL_SIZE) {
        return null;
    }

    // Find an available region slot
    var slot: ?usize = null;
    for (&registry.regions, 0..) |*region, i| {
        if (!region.in_use) {
            slot = i;
            break;
        }
    }

    if (slot == null) {
        return null; // No available region slots
    }

    // Allocate from the pool
    const base: [*]u8 = @ptrCast(&pool[registry.pool_offset]);
    registry.pool_offset += aligned_size;

    // Register the region
    const id = registry.next_region_id;
    registry.next_region_id +%= 1;
    if (registry.next_region_id == 0) {
        registry.next_region_id = 1; // Skip 0 as it's reserved
    }

    registry.regions[slot.?] = .{
        .id = id,
        .base = base,
        .size = aligned_size,
        .in_use = true,
    };

    // Memory barrier to ensure writes are visible to other cores
    microzig.cpu.dmb();

    return .{
        .id = id,
        .mem = base[0..aligned_size],
    };
}

/// Attach to an existing shared memory region by ID
/// Returns a slice to the region, or null if the region doesn't exist
pub fn attach(id: RegionId) ?[]u8 {
    if (id == 0) {
        return null; // ID 0 is reserved
    }

    const registry = getRegistryPtr();

    registry.lock.lock();
    defer registry.lock.unlock();

    // Memory barrier to ensure we see the latest state
    microzig.cpu.dmb();

    // Find the region
    for (&registry.regions) |*region| {
        if (region.in_use and region.id == id) {
            // Memory barrier before returning
            microzig.cpu.dmb();
            return region.base[0..region.size];
        }
    }

    return null; // Region not found
}

/// Direct access to the shared memory pool base address
/// might lead to errors not 10000% sure not really an expert at this
pub const SHARED_MEM_BASE: *align(4) [SHARED_MEM_POOL_SIZE]u8 = @ptrFromInt(SHARED_MEM_BASE_ADDR);
