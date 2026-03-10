/// UF2 file format parser for loading cart programs
/// UF2 (USB Flashing Format) is a file format designed for flashing microcontrollers
/// Each block is 512 bytes and self-contained
const std = @import("std");

/// UF2 block size (always 512 bytes)
pub const BLOCK_SIZE: usize = 512;

/// UF2 magic numbers for validation
pub const MAGIC_START0: u32 = 0x0A324655; // "UF2\n"
pub const MAGIC_START1: u32 = 0x9E5D5157;
pub const MAGIC_END: u32 = 0x0AB16F30;

/// RP2354B shares the same family ID as RP2350 ARM-S in MicroZig so we use it
/// RP2350 ARM-S family ID
pub const FAMILY_RP2350_ARM_S: u32 = 0xE48BFF59;
/// RP2350 ARM-NS (non-secure) family ID
pub const FAMILY_RP2350_ARM_NS: u32 = 0xE48BFF5A;
/// RP2350 RISC-V family ID
pub const FAMILY_RP2350_RISCV: u32 = 0xE48BFF5B;

/// UF2 flags
pub const Flags = struct {
    pub const NOT_MAIN_FLASH: u32 = 0x00000001;
    pub const FILE_CONTAINER: u32 = 0x00001000;
    pub const FAMILY_ID_PRESENT: u32 = 0x00002000;
    pub const MD5_CHECKSUM: u32 = 0x00004000;
    pub const EXTENSION_TAGS: u32 = 0x00008000;
};

/// Maximum payload size per block (476 bytes available, typically 256 used)
pub const MAX_PAYLOAD_SIZE: usize = 476;
pub const TYPICAL_PAYLOAD_SIZE: usize = 256;

/// UF2 block header structure (32 bytes)
pub const BlockHeader = extern struct {
    magic_start0: u32, // 0x0A324655
    magic_start1: u32, // 0x9E5D5157
    flags: u32, // Flags (see Flags struct)
    target_addr: u32, // Target flash address for this block's data
    payload_size: u32, // Number of bytes used in data (typically 256)
    block_no: u32, // Sequential block number (0-indexed)
    num_blocks: u32, // Total number of blocks in file
    file_size_or_family: u32, // File size or family ID (if flag set)
};

/// UF2 block structure (512 bytes total)
pub const Block = extern struct {
    header: BlockHeader,
    data: [MAX_PAYLOAD_SIZE]u8,
    magic_end: u32,

    /// Validate block magic numbers
    pub fn isValid(self: *const Block) bool {
        return self.header.magic_start0 == MAGIC_START0 and
            self.header.magic_start1 == MAGIC_START1 and
            self.magic_end == MAGIC_END;
    }

    /// Check if this block has a family ID
    pub fn hasFamilyId(self: *const Block) bool {
        return (self.header.flags & Flags.FAMILY_ID_PRESENT) != 0;
    }

    /// Get the family ID (only valid if hasFamilyId() returns true)
    pub fn getFamilyId(self: *const Block) u32 {
        return self.header.file_size_or_family;
    }

    /// Check if this is for any RP235X variant
    pub fn isRP235X(self: *const Block) bool {
        if (!self.hasFamilyId()) return false;
        const fam = self.getFamilyId();
        return fam == FAMILY_RP2350_ARM_S or
            fam == FAMILY_RP2350_ARM_NS or
            fam == FAMILY_RP2350_RISCV;
    }

    /// Get the payload data slice (only the used portion)
    pub fn getPayload(self: *const Block) []const u8 {
        const size = @min(self.header.payload_size, MAX_PAYLOAD_SIZE);
        return self.data[0..size];
    }
};

/// Error types for UF2 parsing
pub const Error = error{
    InvalidMagic,
    InvalidBlockSize,
    InvalidPayloadSize,
    InvalidBlockNumber,
    UnsupportedFamily,
    AddressOutOfRange,
    BlockCountMismatch,
    DataTooLarge,
};

/// UF2 file parser state
pub const Parser = struct {
    /// Expected number of blocks (from first block's num_blocks field)
    expected_blocks: u32 = 0,
    /// Number of blocks successfully parsed
    blocks_parsed: u32 = 0,
    /// Lowest target address seen
    min_addr: u32 = 0xFFFFFFFF,
    /// Highest target address + data seen
    max_addr: u32 = 0,
    /// Family ID from first block
    family_id: u32 = 0,
    /// Whether we've seen the first block
    initialized: bool = false,

    /// Reset parser state for a new file
    pub fn reset(self: *Parser) void {
        self.* = .{};
    }

    /// Parse and validate a single UF2 block
    /// Returns the block if valid, or an error
    pub fn parseBlock(self: *Parser, data: *align(1) const [BLOCK_SIZE]u8) Error!*const Block {
        const block: *const Block = @ptrCast(@alignCast(data));

        // Validate magic numbers
        if (!block.isValid()) {
            return Error.InvalidMagic;
        }

        // Validate payload size
        if (block.header.payload_size > MAX_PAYLOAD_SIZE) {
            return Error.InvalidPayloadSize;
        }

        // Initialize on first block
        if (!self.initialized) {
            self.expected_blocks = block.header.num_blocks;
            if (block.hasFamilyId()) {
                self.family_id = block.getFamilyId();
            }
            self.initialized = true;
        }

        // Validate block number
        if (block.header.block_no >= block.header.num_blocks) {
            return Error.InvalidBlockNumber;
        }

        // Track address range
        const addr = block.header.target_addr;
        const end_addr = addr + block.header.payload_size;
        if (addr < self.min_addr) {
            self.min_addr = addr;
        }
        if (end_addr > self.max_addr) {
            self.max_addr = end_addr;
        }

        self.blocks_parsed += 1;

        return block;
    }

    /// Check if a target address range is valid for cart execution
    pub fn validateAddressRange(self: *const Parser, cart_xip_start: u32, cart_xip_end: u32) Error!void {
        // Check if the UF2's address range fits within cart_xip
        if (self.min_addr < cart_xip_start or self.max_addr > cart_xip_end) {
            return Error.AddressOutOfRange;
        }
    }

    /// Get the total binary size (max_addr - min_addr)
    pub fn getBinarySize(self: *const Parser) u32 {
        if (self.max_addr <= self.min_addr) return 0;
        return self.max_addr - self.min_addr;
    }

    /// Check if all expected blocks have been parsed
    pub fn isComplete(self: *const Parser) bool {
        return self.initialized and self.blocks_parsed == self.expected_blocks;
    }
};

// Comptime validation
comptime {
    // Ensure Block is exactly 512 bytes
    if (@sizeOf(Block) != BLOCK_SIZE) {
        @compileError("Block size must be exactly 512 bytes");
    }
    // Ensure BlockHeader is exactly 32 bytes
    if (@sizeOf(BlockHeader) != 32) {
        @compileError("BlockHeader size must be exactly 32 bytes");
    }
}
