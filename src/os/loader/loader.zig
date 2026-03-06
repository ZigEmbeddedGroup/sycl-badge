/// Program loader for UF2 cart files
/// Loads user programs from FAT12 storage to cart_xip flash region for XIP execution
const std = @import("std");
const microzig = @import("microzig");
const storage = @import("storage.zig");
const uf2 = @import("uf2.zig");
const rom = @import("../drivers/rom.zig");
const interrupts = @import("../system/interrupts.zig");
const debug_log = @import("../debug_log.zig");

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;
extern const __cart_xip_end__: u8;

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
    FlashWriteError,
    ReadError,
};

/// Current cart state
var cart_state: CartState = .none;

/// Loaded cart entry point (Reset_Handler address from vector table)
var cart_entry_point: u32 = 0;

/// Loaded cart info
var loaded_cart_name: [12]u8 = undefined;
var loaded_cart_size: u32 = 0;

/// Buffer for accumulating flash write data (one erase block)
var flash_write_buffer: [FLASH_ERASE_BLOCK]u8 align(4) linksection(".process_ram") = undefined;

/// Buffer for reading entire UF2 file from storage
/// 320KB should be enough for most carts (max cart binary is 256KB, UF2 overhead ~2x)
var cart_buffer: [320 * 1024]u8 align(4) linksection(".process_ram") = undefined;

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
    const RAM_START: u32 = 0x20000000;
    const RAM_END: u32 = 0x20080000;

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

/// Get current cart state
pub fn getState() CartState {
    return cart_state;
}

/// Get loaded cart entry point
pub fn getEntryPoint() u32 {
    return cart_entry_point;
}

/// Check if a cart is ready to execute
pub fn isReady() bool {
    return cart_state == .ready;
}

/// Check if a cart is currently running
pub fn isRunning() bool {
    return cart_state == .running;
}

/// Mark cart as running (called when Core 1 starts execution)
pub fn markRunning() void {
    if (cart_state == .ready) {
        cart_state = .running;
    }
}

/// Stop the current cart
pub fn stop() void {
    cart_state = .none;
    cart_entry_point = 0;
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

    // Import multicore for executing the cart
    const multicore = @import("../system/multicore.zig");

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
pub fn loadUF2Cart(name: []const u8) LoadError!u32 {
    // If a cart is already running, stop Core 1 before erasing cart_xip.
    if (cart_state == .running) {
        const multicore = @import("../system/multicore.zig");
        multicore.haltCore1();
        multicore.resetCore1();
    }

    cart_state = .loading;
    errdefer cart_state = .error_state;

    // Find the cart in FAT12 storage
    const cart_info = storage.findCart(name) orelse {
        return LoadError.FileNotFound;
    };

    // Validate size (UF2 blocks are 512 bytes each, cart_xip is 256KB)
    // Max useful data per block is 256 bytes, so max UF2 file size is roughly 2x cart_xip size
    const max_uf2_size = @min(getCartXipSize() * 2, @as(u32, @intCast(cart_buffer.len)));
    if (cart_info.size > max_uf2_size) {
        return LoadError.FileTooLarge;
    }

    // Read and parse UF2 blocks
    const entry_point = try loadUF2FromStorage(cart_info);

    // Save cart info
    @memcpy(&loaded_cart_name, &cart_info.short_name);
    loaded_cart_size = cart_info.size;
    cart_entry_point = entry_point;
    cart_state = .ready;
    return entry_point;
}

/// Internal function to load UF2 from storage and program to flash
fn loadUF2FromStorage(cart_info: storage.CartInfo) LoadError!u32 {
    const cart_xip_start = getCartXipStart();
    const cart_xip_end = getCartXipEnd();
    const cart_xip_size = getCartXipSize();

    // Read the entire UF2 file into the cart buffer first
    const bytes_read = storage.readCart(cart_info, &cart_buffer);
    if (bytes_read == 0 or bytes_read != cart_info.size) {
        return LoadError.ReadError;
    }
    if (bytes_read % uf2.BLOCK_SIZE != 0) {
        return LoadError.InvalidUF2;
    }

    // Calculate number of UF2 blocks
    const num_blocks = bytes_read / uf2.BLOCK_SIZE;
    if (num_blocks == 0) {
        return LoadError.InvalidUF2;
    }

    // Debug: record file/blocks info
    var _uf2_msg: [128]u8 = undefined;
    const _uf2_slice = std.fmt.bufPrint(_uf2_msg[0..], "UF2 read: {d} bytes, blocks={d}\r\n", .{ bytes_read, num_blocks }) catch "";
    if (_uf2_slice.len != 0) debug_log.record(_uf2_slice);

    // Erase the cart_xip region
    try eraseCartXipRegion();
    var parser = uf2.Parser{};
    var block_index: u32 = 0;

    // Track which parts of cart_xip we need to write
    var min_offset: u32 = cart_xip_size;
    var max_offset: u32 = 0;

    // Temporary buffer to accumulate binary data before flash write
    // We'll write in 4KB blocks
    var current_erase_block: u32 = 0xFFFFFFFF;
    var buffer_dirty: bool = false;

    // Process each UF2 block from the buffer
    while (block_index < num_blocks) {
        const block_offset = block_index * uf2.BLOCK_SIZE;
        const block_data = cart_buffer[block_offset..][0..uf2.BLOCK_SIZE];

        // Parse the block
        const block = parser.parseBlock(block_data) catch {
            return LoadError.InvalidUF2;
        };

        // On first block, validate family and base address
        if (block_index == 0) {
            // Check family ID
            if (block.hasFamilyId() and !block.isRP235X()) {
                return LoadError.UnsupportedFamily;
            }

            // Check block count matches file length
            if (block.header.num_blocks != num_blocks) {
                return LoadError.InvalidUF2;
            }

            // Check base address is within cart_xip
            if (block.header.target_addr < cart_xip_start or
                block.header.target_addr >= cart_xip_end)
            {
                return LoadError.AddressMismatch;
            }
        }

        // Calculate offset within cart_xip
        const target_offset = block.header.target_addr - cart_xip_start;
        const payload = block.getPayload();
        if (payload.len == 0) {
            return LoadError.InvalidUF2;
        }

        // Validate each block address range
        if (block.header.target_addr < cart_xip_start or
            block.header.target_addr + @as(u32, @intCast(payload.len)) > cart_xip_end)
        {
            return LoadError.AddressMismatch;
        }

        // Track extent
        if (target_offset < min_offset) min_offset = target_offset;
        if (target_offset + @as(u32, @intCast(payload.len)) > max_offset) {
            max_offset = target_offset + @as(u32, @intCast(payload.len));
        }

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

        block_index += 1;
    }

    // Flush any remaining data
    if (buffer_dirty) {
        try flushWriteBuffer(current_erase_block, cart_xip_start);
    }

    // Find the vector table by scanning for valid SP and entry point pattern
    // Some toolchains add padding before the vector table
    // Returns the vector table ADDRESS (not entry point) so Core 1 can read both SP and entry
    if (!parser.isComplete()) {
        return LoadError.InvalidUF2;
    }
    parser.validateAddressRange(cart_xip_start, cart_xip_end) catch {
        return LoadError.AddressMismatch;
    };

    const vector_table_addr = findVectorTableAddr(cart_xip_start + min_offset, cart_xip_end) orelse {
        debug_log.record("findVectorTableAddr: vector not found after programming");
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
        var _verify_msg: [128]u8 = undefined;
        const _verify_failed_slice = std.fmt.bufPrint(_verify_msg[0..], "Post-program verification FAILED: sp=0x{x} entry=0x{x}\r\n", .{ sp, entry }) catch "";
        if (_verify_failed_slice.len != 0) debug_log.record(_verify_failed_slice);
        return LoadError.FlashWriteError;
    } else {
        var _verify_ok_msg: [128]u8 = undefined;
        const _verify_ok_slice = std.fmt.bufPrint(_verify_ok_msg[0..], "Post-program verification OK: vt=0x{x} sp=0x{x} entry=0x{x}\r\n", .{ vector_table_addr, sp, entry }) catch "";
        if (_verify_ok_slice.len != 0) debug_log.record(_verify_ok_slice);
    }

    return vector_table_addr;
}

/// Erase the entire cart_xip flash region
fn eraseCartXipRegion() LoadError!void {
    const cart_xip_start = getCartXipStart();
    const cart_xip_size = getCartXipSize();
    const flash_offset = cart_xip_start - XIP_BASE;

    // Record erase attempt for debugging
    var _erase_msg: [128]u8 = undefined;
    const _erase_slice = std.fmt.bufPrint(_erase_msg[0..], "eraseCartXipRegion: flash_offset=0x{x}, size={d}\r\n", .{ flash_offset, cart_xip_size }) catch "";
    if (_erase_slice.len != 0) debug_log.record(_erase_slice);

    interrupts.disableInterrupts();
    defer interrupts.enableInterrupts();

    rom.flash_exit_xip();
    rom.flash_range_erase(flash_offset, cart_xip_size, FLASH_ERASE_BLOCK, FLASH_ERASE_CMD);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();
}

/// Flush write buffer to flash
fn flushWriteBuffer(erase_block_num: u32, cart_xip_start: u32) LoadError!void {
    const flash_addr = cart_xip_start + (erase_block_num * FLASH_ERASE_BLOCK);
    const flash_offset = flash_addr - XIP_BASE;

    // Debug: record write attempt
    var _fw_msg: [128]u8 = undefined;
    const _fw_slice = std.fmt.bufPrint(_fw_msg[0..], "flushWriteBuffer: erase_block={d}, flash_offset=0x{x}\r\n", .{ erase_block_num, flash_offset }) catch "";
    if (_fw_slice.len != 0) debug_log.record(_fw_slice);

    interrupts.disableInterrupts();
    defer interrupts.enableInterrupts();

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
