/// Program loader for UF2 cart files
/// Loads user programs from FAT12 storage to cart_xip flash region for XIP execution
const std = @import("std");
const microzig = @import("microzig");
const storage = @import("storage.zig");
const uf2 = @import("uf2.zig");
const rom = @import("../drivers/rom.zig");
const uart = @import("../drivers/uart.zig");
const interrupts = @import("../system/interrupts.zig");

/// Linker symbols for cart_xip region
extern const __cart_xip_start__: u8;
extern const __cart_xip_end__: u8;

/// XIP base address for flash
const XIP_BASE: u32 = 0x10000000;

/// Flash erase block size (4KB for RP2350)
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
    // Limit scan to first 64 bytes to avoid false positives
    const scan_limit = @min(start_addr + 64, end_addr - 8);

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
            var buf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "Found vector table at 0x{x}: SP=0x{x}, Entry=0x{x}\r\n", .{ addr, sp, entry }) catch "";
            uart.puts(msg);
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

/// Load a UF2 cart from FAT12 storage and program it to cart_xip flash
/// Returns the entry point address on success
pub fn loadUF2Cart(name: []const u8) LoadError!u32 {
    cart_state = .loading;
    errdefer cart_state = .error_state;

    // Find the cart in FAT12 storage
    const cart_info = storage.findCart(name) orelse {
        uart.puts("Cart not found: ");
        uart.puts(name);
        uart.puts("\r\n");
        return LoadError.FileNotFound;
    };

    uart.puts("Loading UF2: ");
    uart.puts(name);
    uart.puts("\r\n");

    // Validate size (UF2 blocks are 512 bytes each, cart_xip is 256KB)
    // Max useful data per block is 256 bytes, so max UF2 file size is roughly 2x cart_xip size
    const max_uf2_size = getCartXipSize() * 2;
    if (cart_info.size > max_uf2_size) {
        uart.puts("UF2 too large\r\n");
        return LoadError.FileTooLarge;
    }

    // Read and parse UF2 blocks
    const entry_point = try loadUF2FromStorage(cart_info);

    // Save cart info
    @memcpy(&loaded_cart_name, &cart_info.short_name);
    loaded_cart_size = cart_info.size;
    cart_entry_point = entry_point;
    cart_state = .ready;

    var buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Cart loaded, entry: 0x{x}\r\n", .{entry_point}) catch "";
    uart.puts(msg);

    return entry_point;
}

/// Internal function to load UF2 from storage and program to flash
fn loadUF2FromStorage(cart_info: storage.CartInfo) LoadError!u32 {
    const cart_xip_start = getCartXipStart();
    const cart_xip_end = getCartXipEnd();
    const cart_xip_size = getCartXipSize();

    // Read the entire UF2 file into the cart buffer first
    uart.puts("Reading UF2 file...\r\n");
    const bytes_read = storage.readCart(cart_info, &cart_buffer);
    if (bytes_read == 0 or bytes_read != cart_info.size) {
        uart.puts("Failed to read UF2 file\r\n");
        return LoadError.ReadError;
    }

    {
        var buf: [64]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Read {d} bytes\r\n", .{bytes_read}) catch "";
        uart.puts(msg);
    }

    // Debug: Print first 8 bytes
    uart.puts("UF2 header: ");
    {
        var hex_buf: [64]u8 = undefined;
        const hex_msg = std.fmt.bufPrint(&hex_buf, "{x:0>2}{x:0>2}{x:0>2}{x:0>2} {x:0>2}{x:0>2}{x:0>2}{x:0>2}\r\n", .{
            cart_buffer[0], cart_buffer[1], cart_buffer[2], cart_buffer[3],
            cart_buffer[4], cart_buffer[5], cart_buffer[6], cart_buffer[7],
        }) catch "";
        uart.puts(hex_msg);
    }

    // Calculate number of UF2 blocks
    const num_blocks = bytes_read / uf2.BLOCK_SIZE;
    if (num_blocks == 0) {
        return LoadError.InvalidUF2;
    }

    // Erase the cart_xip region
    uart.puts("Erasing cart_xip region...\r\n");
    try eraseCartXipRegion();
    uart.puts("Erase complete\r\n");

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
            var buf: [64]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "UF2 parse error at block {d}\r\n", .{block_index}) catch "";
            uart.puts(msg);
            return LoadError.InvalidUF2;
        };

        // On first block, validate family and base address
        if (block_index == 0) {
            // Check family ID
            if (block.hasFamilyId() and !block.isRP2350()) {
                uart.puts("Unsupported family ID\r\n");
                return LoadError.UnsupportedFamily;
            }

            // Check base address is within cart_xip
            if (block.header.target_addr < cart_xip_start or
                block.header.target_addr >= cart_xip_end)
            {
                var buf: [96]u8 = undefined;
                const msg = std.fmt.bufPrint(&buf, "Address 0x{x} outside cart_xip (0x{x}-0x{x})\r\n", .{ block.header.target_addr, cart_xip_start, cart_xip_end }) catch "";
                uart.puts(msg);
                return LoadError.AddressMismatch;
            }
        }

        // Debug: Show block info
        {
            var buf: [128]u8 = undefined;
            const msg = std.fmt.bufPrint(&buf, "Block {d}: target_addr=0x{x}, payload_size={d}\r\n", .{ block_index, block.header.target_addr, block.header.payload_size }) catch "";
            uart.puts(msg);
        }

        // Calculate offset within cart_xip
        const target_offset = block.header.target_addr - cart_xip_start;
        const payload = block.getPayload();

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

    uart.puts("Flash programming complete\r\n");

    // Debug: Show what we wrote and where
    {
        var buf: [128]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "min_offset: 0x{x}, max_offset: 0x{x}\r\n", .{ min_offset, max_offset }) catch "";
        uart.puts(msg);
    }

    // Find the vector table by scanning for valid SP and entry point pattern
    // Some toolchains add padding before the vector table
    // Returns the vector table ADDRESS (not entry point) so Core 1 can read both SP and entry
    const vector_table_addr = findVectorTableAddr(cart_xip_start + min_offset, cart_xip_end) orelse {
        uart.puts("Could not find valid vector table\r\n");
        return LoadError.InvalidUF2;
    };

    {
        var buf: [64]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "Vector table addr: 0x{x}\r\n", .{vector_table_addr}) catch "";
        uart.puts(msg);
    }

    return vector_table_addr;
}

/// Erase the entire cart_xip flash region
fn eraseCartXipRegion() LoadError!void {
    const cart_xip_start = getCartXipStart();
    const cart_xip_size = getCartXipSize();
    const flash_offset = cart_xip_start - XIP_BASE;

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
