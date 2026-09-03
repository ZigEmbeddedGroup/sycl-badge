/// Program loader for UF2 cart files
/// Loads user programs from FAT12 storage to cart_xip flash region for XIP execution
const std = @import("std");
const microzig = @import("microzig");
const storage = @import("storage.zig");
const uf2 = @import("uf2.zig");
const rom = @import("../drivers/rom.zig");
const interrupt = microzig.interrupt;
const terry = @import("../system/terry.zig");
const multicore = @import("../system/multicore.zig");
const log_scope = .loader;
const log = std.log.scoped(log_scope);
const cd = @import("../cart/cart_descriptor.zig");
const mailbox = @import("../ipc/mailbox.zig");

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;
extern const __cart_xip_end__: u8;
extern const __process_ram_start__: u8;
extern const __process_ram_end__: u8;

/// XIP base address for flash
const XIP_BASE: u32 = 0x10000000;

/// Flash erase block size (4KB for RP2354B)
const FLASH_ERASE_BLOCK: usize = 4096;
const FLASH_ERASE_CMD: u8 = 0x20;

/// Cart load request structure (for IPC)
pub const CartLoadRequest = extern struct {
    start_cluster: u16,
    size: u32,
};

/// Cart state
pub const CartState = enum {
    none, // No cart loaded
    loading, // Currently loading
    ready, // Loaded and ready to execute
    running, // Currently executing on Core 1
    error_state, // Load error occurred (renamed to avoid keyword)
};

/// Cart load error types
pub const LoadError = error{
    FileNotFound,
    FileTooLarge,
    InvalidUF2,
    UnsupportedFamily,
    AddressMismatch,
    VersionMismatch,
    FlashWriteError,
    ReadError,
};

/// Current cart state
var cart_state: terry.core0.TrackedStateMachine(CartState) = undefined;

/// Loaded cart entry point
var cart_entry_point: mailbox.MessageType.CartExecute = undefined;

/// Loaded cart info
var loaded_cart_name: [11:0]u8 = undefined;
var loaded_cart_size: u32 = 0;

/// Buffer for accumulating flash write data (one erase block)
var flash_write_buffer: [FLASH_ERASE_BLOCK]u8 align(4) linksection(".process_ram") = undefined;

/// Get cart_xip region start address
pub fn getCartXipStart() u32 {
    return @intFromPtr(&__cart_xip_start__);
}

/// Get cart_xip region end address
pub fn getCartXipEnd() u32 {
    return @intFromPtr(&__cart_xip_end__);
}

/// Get cart_xip region size
pub fn getCartXipSize() u32 {
    return getCartXipEnd() - getCartXipStart();
}

pub fn getCartRamStart() u32 {
    return @intFromPtr(&__process_ram_start__);
}

pub fn getCartRamEnd() u32 {
    return @intFromPtr(&__process_ram_end__);
}

pub fn getCartRamSize() u32 {
    return getCartRamEnd() - getCartRamStart();
}

pub const CartVector = struct {
    addr: u32,
    sp: u32,
    entry: u32,
};

pub fn getCartXipVector() ?CartVector {
    const cart_xip_start = getCartXipStart();
    const cart_xip_end = getCartXipEnd();
    const vt = findVectorTableAddr(cart_xip_start, cart_xip_end) orelse return null;
    const vector_table: *const [2]u32 = @ptrFromInt(vt);
    return CartVector{ .addr = vt, .sp = vector_table[0], .entry = vector_table[1] };
}

/// Find a valid ARM Cortex-M vector table by scanning memory
/// Some toolchains add padding before the vector table, so we scan for the pattern:
/// - [0] = Stack pointer: Must be in RAM range (0x20000000-0x20080000) and aligned
/// - [1] = Reset handler: Must be in cart_xip range with thumb bit set (odd address)
/// Returns the vector table ADDRESS if found, null otherwise
/// (Core 1 will read SP and entry point from this address)
fn findVectorTableAddr(start_addr: u32, end_addr: u32) ?u32 {
    // RAM range for valid stack pointer
    const RAM_START: u32 = getCartRamStart();
    const RAM_END: u32 = getCartRamEnd();

    // Cart XIP range for valid entry point
    const xip_start = getCartXipStart();
    const xip_end = getCartXipEnd();

    // Scan in 4-byte increments (word aligned)
    // Limit scan to first 4KB to allow for toolchain padding before vectors
    const scan_limit = @min(start_addr + 4096, end_addr - 8);

    var addr = start_addr;
    while (addr < scan_limit) : (addr += 4) {
        const candidate: *const [2]u32 = @ptrFromInt(addr);
        const sp = candidate[0];
        const entry = candidate[1];

        // Check if SP is valid (in RAM range and 8-byte aligned)
        const sp_valid = (sp >= RAM_START) and (sp <= RAM_END) and ((sp & 0x7) == 0);

        // Check if entry point is valid (in cart_xip range with thumb bit set)
        const entry_addr = entry & ~@as(u32, 1); // Remove thumb bit
        const entry_valid = (entry_addr >= xip_start) and (entry_addr < xip_end) and ((entry & 1) == 1);

        if (sp_valid and entry_valid) {
            return addr; // Return vector table address, not entry point
        }
    }

    return null;
}

pub fn init() void {
    cart_state.register("loader.cart_state", .none, @src());
}

/// Get current cart state
pub fn getState() CartState {
    return cart_state.state;
}

/// Get loaded cart entry point
pub fn getEntryPoint() mailbox.MessageType.CartExecute {
    return cart_entry_point;
}

/// Check if a cart is ready to execute
pub fn isReady() bool {
    return cart_state.state == .ready;
}

/// Check if a cart is currently running
pub fn isRunning() bool {
    return cart_state.state == .running;
}

/// Mark cart as running (called when Core 1 starts execution)
pub fn markRunning() void {
    if (cart_state.state == .ready) {
        cart_state.set_state(.running, @src());
    }
}

/// Stop the current cart
pub fn stop() void {
    cart_state.set_state(.none, @src());
    cart_entry_point = undefined;
}

/// Auto-start cart if only one is present in storage
/// Returns true if a cart was auto-started, false otherwise
pub fn autoStartSingleCart() bool {
    // Count available carts
    var first_cart: storage.CartInfo = undefined;
    const cart_count = storage.countCarts(&first_cart);

    // Only auto-start if exactly one cart is present
    if (cart_count != 1) {
        return false;
    }

    // Get the cart name for loading
    const cart_name = if (first_cart.long_name_len > 0)
        first_cart.long_name[0..first_cart.long_name_len]
    else blk: {
        const end = std.mem.indexOfScalar(u8, first_cart.short_name[0..], 0) orelse first_cart.short_name.len;
        break :blk first_cart.short_name[0..end];
    };

    // Load the cart
    const entry_point = loadUF2Cart(cart_name) catch {
        return false;
    };

    // Execute the cart
    if (multicore.executeCart(entry_point)) {
        markRunning();
        return true;
    } else {
        return false;
    }
}
// Erase the cart XIP region (public interface for console command)
pub fn eraseCartRegion() LoadError!void {
    try eraseCartXipRegion();
}

/// Load a UF2 cart from FAT12 storage and program it to cart_xip flash
/// Returns the entry point address on success
pub fn loadUF2Cart(name: []const u8) LoadError!mailbox.MessageType.CartExecute {
    // If a cart is already running, stop Core 1 before erasing cart_xip.
    if (cart_state.state == .running) {
        multicore.haltCore1();
        multicore.resetCore1();
    }

    cart_state.set_state(.loading, @src());
    errdefer cart_state.set_state(.error_state, @src());

    // Find the cart in FAT12 storage
    const cart_info = storage.findCart(name) orelse {
        return LoadError.FileNotFound;
    };

    // Validate size (UF2 blocks are 512 bytes each, cart_xip is 256KB)
    // Max useful data per block is 256 bytes, so max UF2 file size is roughly 2x cart_xip size
    const max_uf2_size = (getCartXipSize() + getCartRamSize()) * 2;
    if (cart_info.size > max_uf2_size) {
        return LoadError.FileTooLarge;
    }

    // Read and parse UF2 blocks
    const start_info = try loadUF2FromStorage(cart_info);

    // Save cart info
    @memcpy(&loaded_cart_name, &cart_info.short_name);
    loaded_cart_size = cart_info.size;
    cart_entry_point = start_info;
    cart_state.set_state(.ready, @src());
    return start_info;
}

/// Internal function to load UF2 from storage and program to flash
fn loadUF2FromStorage(cart_info: storage.CartInfo) LoadError!mailbox.MessageType.CartExecute {
    const cart_xip_start = getCartXipStart();
    const cart_xip_end = getCartXipEnd();
    const cart_xip_size = getCartXipSize();
    const cart_ram_start = getCartRamStart();
    const cart_ram_end = getCartRamEnd();

    log.info("cart info: {f}", .{cart_info});
    log.info("cart_xip_start: 0x{X}", .{cart_xip_start});
    log.info("cart_xip_end: 0x{X}", .{cart_xip_end});
    log.info("cart_xip_size: 0x{X}", .{cart_xip_size});

    if (cart_info.size % uf2.BLOCK_SIZE != 0) {
        return LoadError.InvalidUF2;
    }

    var file: storage.FileIterator = .init(cart_info.size, cart_info.start_cluster);

    var parser = uf2.Parser{};

    // Track which parts of cart_xip we need to write
    var min_xip_offset: u32 = cart_xip_size;

    // Temporary buffer to accumulate binary data before flash write
    // We'll write in 4KB blocks
    var current_erase_block: u32 = 0xFFFFFFFF;
    var buffer_dirty: bool = false;

    var has_xip_blocks: bool = false;
    var has_ram_blocks: bool = false;

    var ram_cart_descriptor: ?[*]u32 = null;

    // Process each UF2 block from the buffer
    var block_index: u32 = 0;
    var file_pos: usize = 0;
    while (file.next()) |block_data| : (block_index += 1) {
        if (block_data.len != uf2.BLOCK_SIZE) {
            return LoadError.ReadError;
        }

        if (std.log.logEnabled(.debug, log_scope)) {
            for (0..512 / 8) |row| {
                const row_data = block_data[8 * row ..];
                log.debug("0x{X}: {X:0>2} {X:0>2} {X:0>2} {X:0>2} {X:0>2} {X:0>2} {X:0>2} {X:0>2}", .{
                    file_pos,
                    row_data[0],
                    row_data[1],
                    row_data[2],
                    row_data[3],
                    row_data[4],
                    row_data[5],
                    row_data[6],
                    row_data[7],
                });
                file_pos += 8;
            }
        }

        // Parse the block
        const block = parser.parseBlock(block_data[0..uf2.BLOCK_SIZE]) catch {
            log.err("Failed to parse block block_index={} num_blocks={}", .{ block_index, parser.expected_blocks });
            return LoadError.InvalidUF2;
        };

        // On first block, validate family and base address
        if (block_index == 0) {
            // Check family ID
            if (block.hasFamilyId() and !block.isRP235X()) {
                return LoadError.UnsupportedFamily;
            }
        }

        const payload = block.getPayload();
        if (payload.len == 0) {
            log.err("calculate offset within cart_xip", .{});
            return LoadError.InvalidUF2;
        }

        // Check base address is within cart_xip
        if (block.header.target_addr >= cart_xip_start and
            block.header.target_addr + payload.len < cart_xip_end)
        {
            if (has_ram_blocks) {
                // For now, we can't support uf2 files with both ram and flash data in them.
                // The flash write buffer is mapped into process RAM, so it will overlap
                // with the ram blocks and potentially clobber loaded cart memory.
                return LoadError.AddressMismatch;
            }

            // When we encounter the first xip block, erase the whole flash region
            if (!has_xip_blocks) {
                // Erase the cart_xip region
                try eraseCartXipRegion();
            }

            has_xip_blocks = true;

            const target_offset = block.header.target_addr - cart_xip_start;
            min_xip_offset = @min(min_xip_offset, target_offset);

            // Determine which erase block this belongs to
            const erase_block_num = target_offset / FLASH_ERASE_BLOCK;
            const offset_in_block = target_offset % FLASH_ERASE_BLOCK;

            // If switching to a new erase block, flush the old one
            if (erase_block_num != current_erase_block) {
                if (buffer_dirty) {
                    try flushWriteBuffer(current_erase_block, cart_xip_start);
                }
                // Initialize new buffer with 0xFF (erased flash state)
                @memset(&flash_write_buffer, 0xFF);
                current_erase_block = erase_block_num;
                buffer_dirty = false;
            }

            // Copy payload to write buffer
            const copy_len = @min(payload.len, FLASH_ERASE_BLOCK - offset_in_block);
            @memcpy(flash_write_buffer[offset_in_block .. offset_in_block + copy_len], payload[0..copy_len]);
            buffer_dirty = true;

            // Handle payload spanning multiple erase blocks (rare but possible)
            if (copy_len < payload.len) {
                // Flush current block
                try flushWriteBuffer(current_erase_block, cart_xip_start);

                // Move to next block
                current_erase_block += 1;
                @memset(&flash_write_buffer, 0xFF);

                // Copy remaining payload
                const remaining = payload.len - copy_len;
                @memcpy(flash_write_buffer[0..remaining], payload[copy_len..]);
                buffer_dirty = true;
            }
        }
        else if (block.header.target_addr >= cart_ram_start and
                 block.header.target_addr + payload.len <= cart_ram_end)
        {
            // If this RAM block was preceded by flash blocks, there is unwritten
            // flash data in the cart's memory space. The cart memory might overwrite
            // that flash data, so we need to flush it first. Once has_ram_blocks is
            // set, we don't allow any more flash blocks, so the cart memory won't
            // be overwritten again.
            if (buffer_dirty) {
                try flushWriteBuffer(current_erase_block, cart_xip_start);
                buffer_dirty = false;
                asm volatile ("" ::: .{ .memory = true });
            }

            has_ram_blocks = true;

            if (ram_cart_descriptor == null) {
                // See if we can find the cart descriptor
                const data_as_u32 = std.mem.bytesAsSlice(u32, payload[0..std.mem.alignBackward(usize, payload.len, @alignOf(u32))]);
                if (std.mem.indexOfScalar(u32, data_as_u32, cd.CART_MAGIC)) |index| {
                    const byte_offset = index * @sizeOf(u32);
                    ram_cart_descriptor = @ptrFromInt(block.header.target_addr + byte_offset);
                }
            }

            const ptr: [*]u8 = @ptrFromInt(block.header.target_addr);
            @memcpy(ptr, payload);
        }
        else
        {
            return LoadError.AddressMismatch;
        }
    }

    if (block_index == 0) {
        return LoadError.InvalidUF2;
    }

    // Flush any remaining data
    if (buffer_dirty) {
        try flushWriteBuffer(current_erase_block, cart_xip_start);
    }

    if (!parser.isComplete()) {
        log.err("parser is not complete", .{});
        return LoadError.InvalidUF2;
    }

    // Check if it's a ram cart first
    if (ram_cart_descriptor) |cart_descriptor| {
        // Verify the version
        switch (cart_descriptor[1]) {
            cd.CART_VERSION_V1 => {
                const descriptor: *cd.CartDescriptorTable_v1 = @ptrCast(cart_descriptor);
                const bss_start = @intFromPtr(descriptor.bss_start);
                const bss_end = @intFromPtr(descriptor.bss_end);
                const entry_point = @intFromPtr(descriptor.entry_point);
                // Verify the pointers
                if (bss_start < cart_ram_start or bss_start > cart_ram_end or
                    bss_end < cart_ram_start or bss_end > cart_ram_end or
                    bss_start > bss_end or
                    !(entry_point >= cart_ram_start and entry_point < cart_ram_end or
                        entry_point >= cart_xip_start and entry_point < cart_xip_end) or
                        entry_point & 1 == 0) // entry_point must be thumb
                {
                    return LoadError.AddressMismatch;
                }

                // Clear BSS
                const bss = @as([*]u8, @ptrFromInt(bss_start))[0..bss_end - bss_start];
                @memset(bss, 0);

                // Flush store pipe
                asm volatile ("dmb" ::: .{ .memory = true });

                // Return the entry point
                return .{ .xip = false, .offset = @intCast(@intFromPtr(cart_descriptor) - cart_ram_start) };
            },
            else => {
                return LoadError.VersionMismatch;
            },
        }
    }

    // Find the vector table by scanning for valid SP and entry point pattern
    // Some toolchains add padding before the vector table
    // Returns the vector table ADDRESS (not entry point) so Core 1 can read both SP and entry
    const vector_table_addr = findVectorTableAddr(cart_xip_start + min_xip_offset, cart_xip_end) orelse {
        log.debug("findVectorTableAddr: vector not found after programming", .{});
        return LoadError.FlashWriteError;
    };

    // Read back and verify vector table after programming
    const vector_table: *const [2]u32 = @ptrFromInt(vector_table_addr);
    const sp = vector_table[0];
    const entry = vector_table[1];

    const RAM_START: u32 = 0x20000000;
    const RAM_END: u32 = 0x20080000;
    const entry_addr = entry & ~@as(u32, 1);

    if (!(sp >= RAM_START and sp <= RAM_END and ((sp & 0x7) == 0) and (entry_addr >= cart_xip_start and entry_addr < cart_xip_end and ((entry & 1) == 1)))) {
        log.debug("Post-program verification FAILED: sp=0x{x} entry=0x{x}", .{ sp, entry });
        return LoadError.FlashWriteError;
    } else {
        log.debug("Post-program verification OK: vt=0x{x} sp=0x{x} entry=0x{x}", .{ vector_table_addr, sp, entry });
    }

    return .{ .xip = true, .offset = @intCast(vector_table_addr - cart_xip_start) };
}

/// Erase the entire cart_xip flash region
fn eraseCartXipRegion() LoadError!void {
    const cart_xip_start = getCartXipStart();
    const cart_xip_size = getCartXipSize();
    const flash_offset = cart_xip_start - XIP_BASE;

    log.debug("eraseCartXipRegion: flash_offset=0x{x}, size={d}", .{ flash_offset, cart_xip_size });

    const cs = interrupt.enter_critical_section();
    defer cs.leave();

    rom.flash_exit_xip();
    rom.flash_range_erase(flash_offset, cart_xip_size, FLASH_ERASE_BLOCK, FLASH_ERASE_CMD);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();
}

/// Flush write buffer to flash
fn flushWriteBuffer(erase_block_num: u32, cart_xip_start: u32) LoadError!void {
    const flash_addr = cart_xip_start + (erase_block_num * FLASH_ERASE_BLOCK);
    const flash_offset = flash_addr - XIP_BASE;

    log.debug("flushWriteBuffer: erase_block={d}, flash_offset=0x{x}", .{ erase_block_num, flash_offset });

    const cs = interrupt.enter_critical_section();
    defer cs.leave();

    rom.flash_exit_xip();
    rom.flash_range_program(flash_offset, &flash_write_buffer);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();
}

/// Legacy cart loading (for backwards compatibility with old cart format)
pub fn loadCart(info: storage.CartInfo) bool {
    // This function is deprecated - use loadUF2Cart instead
    _ = info;
    return false;
}

/// Legacy tick function (no longer needed for XIP execution)
pub fn tick() void {
    // XIP carts run directly from flash, no tick needed
}
