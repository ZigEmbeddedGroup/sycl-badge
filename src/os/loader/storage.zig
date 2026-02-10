/// FAT12-based cart storage in the romfs flash region
const std = @import("std");
const rom = @import("../drivers/rom.zig");
const interrupts = @import("../system/interrupts.zig");

extern const __romfs_start__: u8;
extern const __romfs_end__: u8;
extern const __romfs_region_start__: u8;
extern const __romfs_region_end__: u8;

const XIP_BASE: u32 = 0x10000000;
pub const SECTOR_SIZE: usize = 512;
const FLASH_ERASE_BLOCK: usize = 4096;
const FLASH_ERASE_CMD: u8 = 0x20;

const RESERVED_SECTORS: u16 = 1;
const VOLUME_START_LBA: u32 = 0; // Super-floppy layout (boot sector at LBA0)
const NUM_FATS: u8 = 2;
const ROOT_ENTRIES: u16 = 32; // Small root directory for 1.5MB volume
const SECTORS_PER_CLUSTER: u8 = 1; // 512B clusters for FAT12
const MEDIA_DESCRIPTOR: u8 = 0xF8;

pub const CartInfo = struct {
    start_cluster: u16,
    size: u32,
    short_name: [12]u8, // "NAME.EXT" + NUL (fallback)
    long_name: [256]u8, // Long file name buffer
    long_name_len: usize, // Act len of long name
};

const BS_BYTES_PER_SECTOR: usize = 11;
const BS_FS_TYPE: usize = 54;
const BS_SIGNATURE: usize = 510;

const DIR_ENTRY_SIZE: usize = 32;
const DIR_NAME: usize = 0;
const DIR_EXT: usize = 8;
const DIR_ATTR: usize = 11;
const DIR_FIRST_CLUSTER: usize = 26;
const DIR_FILE_SIZE: usize = 28;
const DIR_VOL_LABEL: usize = 0;

var pending_block_addr: u32 = 0;
var pending_valid: bool = false;
var pending_dirty: bool = false;
var pending_buf: [FLASH_ERASE_BLOCK]u8 align(4) = undefined;

pub fn init() void {
    // Check if filesystem size matches expected (reformat if changed)
    if (!isFormatted() or !isSizeCorrect()) {
        formatVolume();
    }
}

pub fn wipeAll() void {
    flushPendingWrites();

    const base = romfsBase();
    const size = romfsSize();
    const erase_len = (size + (FLASH_ERASE_BLOCK - 1)) & ~@as(usize, FLASH_ERASE_BLOCK - 1);
    const flash_offset = base - XIP_BASE;

    interrupts.disableInterrupts();
    defer interrupts.enableInterrupts();

    rom.flash_exit_xip();
    rom.flash_range_erase(flash_offset, erase_len, FLASH_ERASE_BLOCK, FLASH_ERASE_CMD);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();

    pending_valid = false;
    pending_dirty = false;

    formatVolume();
}

fn romfsBase() u32 {
    return @intFromPtr(&__romfs_region_start__);
}

fn romfsSize() usize {
    return @intFromPtr(&__romfs_region_end__) - @intFromPtr(&__romfs_region_start__);
}

pub fn totalSectors() u32 {
    return @intCast(romfsSize() / SECTOR_SIZE);
}

fn volumeTotalSectors() u32 {
    return totalSectors();
}

fn rootDirSectors() u16 {
    return @intCast((@as(u32, ROOT_ENTRIES) * 32 + (SECTOR_SIZE - 1)) / SECTOR_SIZE);
}

fn fatSectors() u16 {
    const total = volumeTotalSectors();
    const root_secs = rootDirSectors();
    var fat_secs: u32 = 1;
    while (true) {
        const data_sectors = total - RESERVED_SECTORS - root_secs - (@as(u32, NUM_FATS) * fat_secs);
        const clusters = data_sectors / SECTORS_PER_CLUSTER;
        // FAT12 uses 12-bit entries (1.5 bytes per cluster)
        const needed = ((clusters * 3 + 1) / 2 + (SECTOR_SIZE - 1)) / SECTOR_SIZE;
        if (needed == fat_secs) break;
        fat_secs = needed;
    }
    return @intCast(fat_secs);
}

fn dataStartLba() u32 {
    return VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors()) + rootDirSectors();
}

fn isFormatted() bool {
    // Use readSector() instead of direct flash access to ensure we see any pending/buffered data
    var boot: [SECTOR_SIZE]u8 = undefined;
    readSector(0, boot[0..]);

    const signature = readU16(boot[0..], BS_SIGNATURE);
    const bytes_per_sector = readU16(boot[0..], BS_BYTES_PER_SECTOR);
    const root_entries = readU16(boot[0..], 17);
    const fs_type = boot[BS_FS_TYPE .. BS_FS_TYPE + 8];

    // Check all BPB fields match expected values
    if (signature != 0xAA55 or bytes_per_sector != SECTOR_SIZE or root_entries != ROOT_ENTRIES or !std.mem.eql(u8, fs_type, "FAT12   ")) {
        return false;
    }
    var fat0: [SECTOR_SIZE]u8 = undefined;
    readSector(1, fat0[0..]);
    const valid = fat0[0] == MEDIA_DESCRIPTOR and fat0[1] == 0xFF and fat0[2] == 0xFF and fat0[3] == 0xFF;
    return valid;
}

/// Check if the stored filesystem size matches current expected size
fn isSizeCorrect() bool {
    var boot: [SECTOR_SIZE]u8 = undefined;
    readSector(0, boot[0..]);

    const stored_total = readU16(boot[0..], 19); // Total sectors (16-bit)
    const expected_total: u16 = @intCast(volumeTotalSectors());

    return stored_total == expected_total;
}

fn formatVolume() void {
    const volume_sectors = volumeTotalSectors();
    var boot_sector: [SECTOR_SIZE]u8 = [_]u8{0} ** SECTOR_SIZE;
    boot_sector[0] = 0xEB;
    boot_sector[1] = 0x3C;
    boot_sector[2] = 0x90;
    @memcpy(boot_sector[3..11], "SYCLBADG");
    writeU16(boot_sector[0..], BS_BYTES_PER_SECTOR, @intCast(SECTOR_SIZE));
    boot_sector[13] = SECTORS_PER_CLUSTER;
    writeU16(boot_sector[0..], 14, RESERVED_SECTORS);
    boot_sector[16] = NUM_FATS;
    writeU16(boot_sector[0..], 17, ROOT_ENTRIES);
    writeU16(boot_sector[0..], 19, @intCast(volume_sectors));
    boot_sector[21] = MEDIA_DESCRIPTOR;
    writeU16(boot_sector[0..], 22, fatSectors());
    writeU16(boot_sector[0..], 24, 32);
    writeU16(boot_sector[0..], 26, 64);
    writeU32(boot_sector[0..], 28, 0);
    writeU32(boot_sector[0..], 32, 0);
    boot_sector[36] = 0x80;
    boot_sector[38] = 0x29;
    writeU32(boot_sector[0..], 39, 0x20260120);
    @memcpy(boot_sector[43..54], "SYCLBADGE  ");
    @memcpy(boot_sector[BS_FS_TYPE .. BS_FS_TYPE + 8], "FAT12   ");
    writeU16(boot_sector[0..], BS_SIGNATURE, 0xAA55);

    writeSector(0, boot_sector[0..]);

    const fat_start = RESERVED_SECTORS;
    const fat_secs = fatSectors();
    var sector_buf: [SECTOR_SIZE]u8 = [_]u8{0} ** SECTOR_SIZE;
    sector_buf[0] = MEDIA_DESCRIPTOR;
    sector_buf[1] = 0xFF;
    sector_buf[2] = 0xFF;
    sector_buf[3] = 0xFF;

    var fat_index: u8 = 0;
    while (fat_index < NUM_FATS) : (fat_index += 1) {
        var i: u16 = 0;
        while (i < fat_secs) : (i += 1) {
            const lba = fat_start + (@as(u32, fat_index) * fat_secs) + i;
            if (i == 0) {
                // First sector of FAT has media descriptor
                sector_buf[0] = MEDIA_DESCRIPTOR;
                sector_buf[1] = 0xFF;
                sector_buf[2] = 0xFF;
                sector_buf[3] = 0x00;
            } else {
                // Subsequent FAT sectors are all zeros
                @memset(sector_buf[0..], 0);
            }
            writeSector(lba, sector_buf[0..]);
        }
    }

    const root_lba = fat_start + (@as(u32, NUM_FATS) * fat_secs);
    const root_secs = rootDirSectors();
    var j: u16 = 0;
    var zero_sector: [SECTOR_SIZE]u8 = [_]u8{0} ** SECTOR_SIZE;
    while (j < root_secs) : (j += 1) {
        writeSector(root_lba + j, zero_sector[0..]);
    }

    // Write a volume label entry in the first root directory sector.
    var label_sector: [SECTOR_SIZE]u8 = [_]u8{0} ** SECTOR_SIZE;
    @memcpy(label_sector[DIR_NAME .. DIR_NAME + 11], "SYCLBADGE  ");
    label_sector[DIR_ATTR] = 0x08; // Volume label
    writeSector(root_lba, label_sector[0..]);
    flushPendingWrites();
}

pub fn readSector(lba: u32, dst: []u8) void {
    if (lba >= totalSectors()) {
        @memset(dst[0..SECTOR_SIZE], 0);
        return;
    }
    const addr = romfsBase() + lba * SECTOR_SIZE;
    const block_addr = addr & ~@as(u32, FLASH_ERASE_BLOCK - 1);
    const block_offset = addr - block_addr;
    if (pending_valid and pending_dirty and block_addr == pending_block_addr) {
        @memcpy(dst[0..SECTOR_SIZE], pending_buf[block_offset .. block_offset + SECTOR_SIZE]);
        return;
    }
    const base_ptr: [*]const u8 = @ptrFromInt(romfsBase());
    const offset = @as(usize, lba) * SECTOR_SIZE;
    @memcpy(dst[0..SECTOR_SIZE], base_ptr[offset .. offset + SECTOR_SIZE]);
}

pub fn writeSector(lba: u32, src: []const u8) linksection(".ram_text") void {
    if (lba >= totalSectors()) {
        return;
    }

    if (src.len != SECTOR_SIZE) {
        return;
    }

    const addr = romfsBase() + lba * SECTOR_SIZE;
    const block_addr = addr & ~@as(u32, FLASH_ERASE_BLOCK - 1);
    const block_offset = addr - block_addr;

    // For now, we can only buffer one 4KB block, so if switching blocks,
    // we must flush the old block first.
    if (!pending_valid or pending_block_addr != block_addr) {
        if (pending_valid and pending_dirty and pending_block_addr != block_addr) {
            flushPending();
        }
        const block_ptr: [*]const u8 = @ptrFromInt(block_addr);
        @memcpy(pending_buf[0..FLASH_ERASE_BLOCK], block_ptr[0..FLASH_ERASE_BLOCK]);
        pending_block_addr = block_addr;
        pending_valid = true;
    }

    @memcpy(pending_buf[block_offset .. block_offset + SECTOR_SIZE], src[0..SECTOR_SIZE]);
    pending_dirty = true;
}

pub fn flushPendingWrites() linksection(".ram_text") void {
    flushPending();
}

fn flushPending() linksection(".ram_text") void {
    if (!pending_valid) {
        return; // Silent (no pending data)
    }
    if (!pending_dirty) {
        return; // Silent (nothing to flush)
    }

    const flash_offset = pending_block_addr - XIP_BASE;
    interrupts.disableInterrupts();
    defer interrupts.enableInterrupts();

    rom.flash_exit_xip();
    rom.flash_range_erase(flash_offset, FLASH_ERASE_BLOCK, FLASH_ERASE_BLOCK, FLASH_ERASE_CMD);
    rom.flash_range_program(flash_offset, pending_buf[0..FLASH_ERASE_BLOCK]);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();
    pending_dirty = false;
}

pub fn listCarts(callback: *const fn (name: []const u8, size: u32) void) void {
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    var prev_sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;
    var lfn_buf: [256]u8 = undefined;
    var has_prev_sector = false;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        // Copy current sector to prev before reading new one
        if (has_prev_sector) {
            @memcpy(&prev_sector_buf, &sector_buf);
        }
        readSector(lba, sector_buf[0..]);
        has_prev_sector = true;

        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue; // LFN
            if (attr & 0x08 != 0) continue; // volume label
            if (attr & 0x10 != 0) continue; // directory

            // Read LFN entries
            const lfn_len = readLfnEntriesMultiSector(if (lba > root_start) &prev_sector_buf else null, sector_buf[0..], i, lfn_buf[0..]);
            const display_name = if (lfn_len > 0)
                lfn_buf[0..lfn_len]
            else
                formatShortName(entry, &name_buf);

            const size = readU32(entry, DIR_FILE_SIZE);
            callback(display_name, size);
        }
    }
}

/// Count carts in storage and optionally get the first cart's info
/// Returns: number of carts found, fills in first_cart if count == 1
pub fn countCarts(first_cart: ?*CartInfo) u32 {
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    var prev_sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;
    var lfn_buf: [256]u8 = undefined;
    var has_prev_sector = false;
    var count: u32 = 0;
    var found_first = false;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        // Copy current sector to prev before reading new one
        if (has_prev_sector) {
            @memcpy(&prev_sector_buf, &sector_buf);
        }
        readSector(lba, sector_buf[0..]);
        has_prev_sector = true;

        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return count;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue; // LFN
            if (attr & 0x08 != 0) continue; // volume label
            if (attr & 0x10 != 0) continue; // directory

            count += 1;

            // If caller wants first cart info and we haven't found it yet
            if (first_cart != null and !found_first) {
                const lfn_len = readLfnEntriesMultiSector(if (lba > root_start) &prev_sector_buf else null, sector_buf[0..], i, lfn_buf[0..]);

                _ = formatShortName(entry, &name_buf);

                first_cart.?.* = CartInfo{
                    .start_cluster = readU16(entry, DIR_FIRST_CLUSTER),
                    .size = readU32(entry, DIR_FILE_SIZE),
                    .short_name = name_buf,
                    .long_name = undefined,
                    .long_name_len = lfn_len,
                };
                if (lfn_len > 0) {
                    @memcpy(first_cart.?.long_name[0..lfn_len], lfn_buf[0..lfn_len]);
                }
                found_first = true;
            }
        }
    }
    return count;
}

pub fn findCart(name: []const u8) ?CartInfo {
    var target: [12]u8 = undefined;
    const target_len = normalizeName(name, &target);
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    var prev_sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;
    var lfn_buf: [256]u8 = undefined;
    var has_prev_sector = false;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        if (has_prev_sector) {
            @memcpy(&prev_sector_buf, &sector_buf);
        }
        readSector(lba, sector_buf[0..]);
        has_prev_sector = true;

        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return null;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue;
            if (attr & 0x08 != 0) continue;
            if (attr & 0x10 != 0) continue;

            // Try to read LFN (may span sectors)
            const lfn_len = readLfnEntriesMultiSector(if (lba > root_start) &prev_sector_buf else null, sector_buf[0..], i, lfn_buf[0..]);

            // Check if name matches LFN (not case-sensitive)
            var matches = false;
            if (lfn_len > 0 and lfn_len == name.len) {
                matches = true;
                for (name, 0..) |c, idx| {
                    if (std.ascii.toLower(c) != std.ascii.toLower(lfn_buf[idx])) {
                        matches = false;
                        break;
                    }
                }
            }

            // If no LFN match, try SFN
            if (!matches) {
                const short = formatShortName(entry, &name_buf);
                matches = std.mem.eql(u8, short, target[0..target_len]);
            }

            if (matches) {
                var result: CartInfo = .{
                    .start_cluster = readU16(entry, DIR_FIRST_CLUSTER),
                    .size = readU32(entry, DIR_FILE_SIZE),
                    .short_name = name_buf,
                    .long_name = undefined,
                    .long_name_len = lfn_len,
                };
                if (lfn_len > 0) {
                    @memcpy(result.long_name[0..lfn_len], lfn_buf[0..lfn_len]);
                }
                return result;
            }
        }
    }
    return null;
}

pub fn deleteCart(name: []const u8) bool {
    var target: [12]u8 = undefined;
    const target_len = normalizeName(name, &target);
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;
    var lfn_buf: [256]u8 = undefined;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        readSector(lba, sector_buf[0..]);
        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return false;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue;
            if (attr & 0x08 != 0) continue;
            if (attr & 0x10 != 0) continue;

            const lfn_len = readLfnEntries(sector_buf[0..], i, lfn_buf[0..]);

            // Check if name matches LFN or SFN
            var matches = false;
            var lfn_start_idx: usize = 0;

            if (lfn_len > 0 and lfn_len == name.len) {
                matches = true;
                for (name, 0..) |c, idx| {
                    if (std.ascii.toLower(c) != std.ascii.toLower(lfn_buf[idx])) {
                        matches = false;
                        break;
                    }
                }
                if (matches) {
                    // Calc where LFN entries start
                    var scan_idx: isize = @as(isize, @intCast(i)) - @as(isize, DIR_ENTRY_SIZE);
                    while (scan_idx >= 0) : (scan_idx -= DIR_ENTRY_SIZE) {
                        const idx: usize = @intCast(scan_idx);
                        const lfn_entry = sector_buf[idx .. idx + DIR_ENTRY_SIZE];
                        if (lfn_entry[DIR_ATTR] != 0x0F) break;
                        lfn_start_idx = idx;
                    }
                }
            }

            if (!matches) {
                const short = formatShortName(entry, &name_buf);
                matches = std.mem.eql(u8, short, target[0..target_len]);
            }

            if (matches) {
                // Mark SFN entry as del
                sector_buf[i] = 0xE5;

                // Mark all LFN entries as del
                if (lfn_start_idx > 0 and lfn_start_idx < i) {
                    var del_idx = lfn_start_idx;
                    while (del_idx < i) : (del_idx += DIR_ENTRY_SIZE) {
                        sector_buf[del_idx] = 0xE5;
                    }
                }

                writeSector(lba, sector_buf[0..]);
                clearFatChain(readU16(entry, DIR_FIRST_CLUSTER));
                return true;
            }
        }
    }
    return false;
}

pub fn readCart(cart: CartInfo, dst: []u8) u32 {
    if (cart.size == 0) return 0;
    var bytes_left: u32 = cart.size;
    var cluster = cart.start_cluster;
    var dst_offset: usize = 0;
    var sector_buf: [SECTOR_SIZE]u8 = undefined;

    while (cluster >= 2 and cluster < 0xFFF8 and bytes_left > 0) {
        var sector_index: u8 = 0;
        while (sector_index < SECTORS_PER_CLUSTER and bytes_left > 0) : (sector_index += 1) {
            const lba = clusterToLba(cluster) + sector_index;
            readSector(lba, sector_buf[0..]);
            const copy_len = @min(bytes_left, SECTOR_SIZE);
            @memcpy(dst[dst_offset .. dst_offset + copy_len], sector_buf[0..copy_len]);
            bytes_left -= @intCast(copy_len);
            dst_offset += copy_len;
        }
        cluster = fatEntry(cluster);
    }
    return @intCast(dst_offset);
}

fn clusterToLba(cluster: u16) u32 {
    return dataStartLba() + (@as(u32, cluster - 2) * SECTORS_PER_CLUSTER);
}

fn fatEntry(cluster: u16) u16 {
    const fat_start = VOLUME_START_LBA + RESERVED_SECTORS;
    const offset = @as(u32, cluster) + (@as(u32, cluster) / 2);
    const lba = fat_start + (offset / SECTOR_SIZE);
    const index = @as(usize, offset % SECTOR_SIZE);
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    readSector(lba, sector_buf[0..]);
    const b0: u8 = sector_buf[index];
    var b1: u8 = 0;
    if (index + 1 < SECTOR_SIZE) {
        b1 = sector_buf[index + 1];
    } else {
        var next_buf: [SECTOR_SIZE]u8 = undefined;
        readSector(lba + 1, next_buf[0..]);
        b1 = next_buf[0];
    }
    if ((cluster & 1) == 0) {
        return @as(u16, b0) | (@as(u16, b1 & 0x0F) << 8);
    } else {
        return (@as(u16, b0) >> 4) | (@as(u16, b1) << 4);
    }
}

fn setFatEntry(cluster: u16, value: u16) void {
    const fat_start = VOLUME_START_LBA + RESERVED_SECTORS;
    const offset = @as(u32, cluster) + (@as(u32, cluster) / 2);
    const base_lba = fat_start + (offset / SECTOR_SIZE);
    const index = @as(usize, offset % SECTOR_SIZE);
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    var next_buf: [SECTOR_SIZE]u8 = undefined;
    var fat_index: u8 = 0;
    const val = value & 0x0FFF;
    while (fat_index < NUM_FATS) : (fat_index += 1) {
        const lba = base_lba + (@as(u32, fat_index) * fatSectors());
        readSector(lba, sector_buf[0..]);
        var use_next = false;
        if (index + 1 >= SECTOR_SIZE) {
            readSector(lba + 1, next_buf[0..]);
            use_next = true;
        }
        if ((cluster & 1) == 0) {
            sector_buf[index] = @truncate(val & 0xFF);
            const upper: u8 = @intCast((val >> 8) & 0x0F);
            if (use_next) {
                next_buf[0] = (next_buf[0] & 0xF0) | upper;
                writeSector(lba + 1, next_buf[0..]);
            } else {
                sector_buf[index + 1] = (sector_buf[index + 1] & 0xF0) | upper;
            }
        } else {
            const lower: u8 = @intCast((val << 4) & 0xF0);
            sector_buf[index] = (sector_buf[index] & 0x0F) | lower;
            const upper: u8 = @intCast((val >> 4) & 0xFF);
            if (use_next) {
                next_buf[0] = upper;
                writeSector(lba + 1, next_buf[0..]);
            } else {
                sector_buf[index + 1] = upper;
            }
        }
        writeSector(lba, sector_buf[0..]);
    }
}

fn clearFatChain(start: u16) void {
    var cluster = start;
    while (cluster >= 2 and cluster < 0xFFF8) {
        const next = fatEntry(cluster);
        setFatEntry(cluster, 0);
        cluster = next;
    }
}

fn readU16(buf: []const u8, offset: usize) u16 {
    return @as(u16, buf[offset]) | (@as(u16, buf[offset + 1]) << 8);
}

fn readU32(buf: []const u8, offset: usize) u32 {
    return @as(u32, buf[offset]) |
        (@as(u32, buf[offset + 1]) << 8) |
        (@as(u32, buf[offset + 2]) << 16) |
        (@as(u32, buf[offset + 3]) << 24);
}

fn writeU16(buf: []u8, offset: usize, value: u16) void {
    buf[offset] = @truncate(value);
    buf[offset + 1] = @truncate(value >> 8);
}

fn writeU32(buf: []u8, offset: usize, value: u32) void {
    buf[offset] = @truncate(value);
    buf[offset + 1] = @truncate(value >> 8);
    buf[offset + 2] = @truncate(value >> 16);
    buf[offset + 3] = @truncate(value >> 24);
}

/// Get Unicode chars from LFN entry (little UTF-16)
fn getLfnChar(entry: []const u8, offset: usize) u16 {
    return @as(u16, entry[offset]) | (@as(u16, entry[offset + 1]) << 8);
}

/// Calc checksum for SFN
fn sfnChecksum(sfn: []const u8) u8 {
    var sum: u8 = 0;
    for (0..11) |i| {
        sum = ((sum & 1) << 7) +% (sum >> 1) +% sfn[i];
    }
    return sum;
}

/// Read LFN entries that span across two sectors
/// prev_sector: prev sector buffer (null if first sector)
/// curr_sector: curr sector buffer
/// start_idx: SFN entry idx in curr sector
/// out: output buffer for reconstructed flname
fn readLfnEntriesMultiSector(prev_sector: ?*const [SECTOR_SIZE]u8, curr_sector: []const u8, start_idx: usize, out: []u8) usize {
    // SFN entry to get checksum from
    const sfn_entry = curr_sector[start_idx .. start_idx + DIR_ENTRY_SIZE];
    const expected_checksum = sfnChecksum(sfn_entry[DIR_NAME .. DIR_NAME + 11]);

    var lfn_chars: [256]u16 = undefined;
    var total_chars: usize = 0;
    var found_first = false;

    // Scan backwards in curr sector
    if (start_idx > 0) {
        var pos: isize = @as(isize, @intCast(start_idx)) - @as(isize, DIR_ENTRY_SIZE);
        while (pos >= 0) : (pos -= DIR_ENTRY_SIZE) {
            const idx: usize = @intCast(pos);
            const entry = curr_sector[idx .. idx + DIR_ENTRY_SIZE];

            // Stop if not an LFN entry
            if (entry[DIR_ATTR] != 0x0F) break;
            if (entry[0] == 0xE5) break; // Deleted

            // Check checksum matches
            if (entry[13] != expected_checksum) break;

            // Extract chars from this entry (13 chars per LFN entry)
            // Chars 1-5: bytes 1-10
            for (0..5) |i| {
                const c = getLfnChar(entry, 1 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }
            // Chars 6-11: bytes 14-25
            for (0..6) |i| {
                const c = getLfnChar(entry, 14 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }
            // Chars 12-13: bytes 28-31
            for (0..2) |i| {
                const c = getLfnChar(entry, 28 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }

            // Check if first (last in seq) entry
            const seq = entry[0];
            if ((seq & 0x40) != 0) {
                found_first = true;
                break;
            }
        }
    }

    if (!found_first and prev_sector != null and total_chars > 0) {
        var pos: isize = SECTOR_SIZE - DIR_ENTRY_SIZE;
        while (pos >= 0) : (pos -= DIR_ENTRY_SIZE) {
            const idx: usize = @intCast(pos);
            const entry = prev_sector.?[idx .. idx + DIR_ENTRY_SIZE];

            if (entry[DIR_ATTR] != 0x0F) break;
            if (entry[0] == 0xE5) break;
            if (entry[13] != expected_checksum) break;

            // Extract chars
            for (0..5) |i| {
                const c = getLfnChar(entry, 1 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }
            for (0..6) |i| {
                const c = getLfnChar(entry, 14 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }
            for (0..2) |i| {
                const c = getLfnChar(entry, 28 + i * 2);
                if (c != 0 and c != 0xFFFF and total_chars < lfn_chars.len) {
                    lfn_chars[total_chars] = c;
                    total_chars += 1;
                } else if (c == 0) break;
            }

            if ((entry[0] & 0x40) != 0) {
                found_first = true;
                break;
            }
        }
    }

    // If found complete LFN chain, convert to ASCII
    if (found_first and total_chars > 0) {
        var out_idx: usize = 0;
        for (0..total_chars) |i| {
            const c = lfn_chars[i];
            if (c < 0x80 and out_idx < out.len) {
                out[out_idx] = @truncate(c);
                out_idx += 1;
            }
        }
        return out_idx;
    }

    return 0;
}

/// Extract one LFN data
fn extractLfnEntry(entry: []const u8, chars_out: *[13]u16, expected_seq: *u8) bool {
    const seq = entry[0] & 0x1F;
    const is_last = (entry[0] & 0x40) != 0;

    if (is_last) {
        expected_seq.* = seq;
    } else if (expected_seq.* == 0 or seq != expected_seq.* - 1) {
        return false;
    }
    expected_seq.* = seq;

    var char_idx: usize = 0;

    // Chars 1-5 (bytes 1-10)
    var off: usize = 1;
    while (off < 11 and char_idx < 13) : ({
        off += 2;
        char_idx += 1;
    }) {
        chars_out[char_idx] = getLfnChar(entry, off);
    }
    // Chars 6-11 (bytes 14-25)
    off = 14;
    while (off < 26 and char_idx < 13) : ({
        off += 2;
        char_idx += 1;
    }) {
        chars_out[char_idx] = getLfnChar(entry, off);
    }
    // Chars 12-13 (bytes 28-31)
    off = 28;
    while (off < 32 and char_idx < 13) : ({
        off += 2;
        char_idx += 1;
    }) {
        chars_out[char_idx] = getLfnChar(entry, off);
    }

    return true;
}

/// Reconstruct flname from LFN parts (in rev order)
fn reconstructLfnName(parts: [][13]u16, out: []u8) usize {
    var out_idx: usize = 0;
    var part_idx: isize = @as(isize, @intCast(parts.len)) - 1;

    while (part_idx >= 0) : (part_idx -= 1) {
        const pidx: usize = @intCast(part_idx);
        for (parts[pidx]) |char| {
            if (char == 0x0000 or char == 0xFFFF) break;
            // ASCII conv
            if (char < 0x80 and out_idx < out.len) {
                out[out_idx] = @truncate(char);
                out_idx += 1;
            }
        }
    }

    return out_idx;
}

/// Read LFN entries and recreate long flname
/// Returns reconstructed name len, or 0 if LFN not valid
fn readLfnEntries(sector_buf: []const u8, start_idx: usize, out: []u8) usize {
    var lfn_parts: [20][13]u16 = undefined; // Max 20 LFN entries, 13 chars each
    var num_parts: usize = 0;
    var expected_seq: u8 = 0;

    // Scan bwrds to find LFN entries before this dir
    if (start_idx < DIR_ENTRY_SIZE) return 0; // Can't have LFN at start

    var scan_idx: isize = @as(isize, @intCast(start_idx)) - @as(isize, DIR_ENTRY_SIZE);
    while (scan_idx >= 0 and num_parts < 20) : (scan_idx -= DIR_ENTRY_SIZE) {
        const idx: usize = @intCast(scan_idx);
        const entry = sector_buf[idx .. idx + DIR_ENTRY_SIZE];

        if (entry[DIR_ATTR] != 0x0F) break; // Not LFN entry
        if (entry[0] == 0xE5) break; // Del entry

        const seq = entry[0] & 0x1F;
        const is_last = (entry[0] & 0x40) != 0;

        if (is_last) {
            expected_seq = seq;
        } else if (expected_seq == 0 or seq != expected_seq - 1) {
            break; // Invalid seq
        }
        expected_seq = seq;

        // Extract 13 chars from LFN entry
        var chars: [13]u16 = undefined;
        var char_idx: usize = 0;

        // Chars 1-5 (bytes 1-10)
        var off: usize = 1;
        while (off < 11 and char_idx < 13) : ({
            off += 2;
            char_idx += 1;
        }) {
            chars[char_idx] = getLfnChar(entry, off);
        }
        // Chars 6-11 (bytes 14-25)
        off = 14;
        while (off < 26 and char_idx < 13) : ({
            off += 2;
            char_idx += 1;
        }) {
            chars[char_idx] = getLfnChar(entry, off);
        }
        // Chars 12-13 (bytes 28-31)
        off = 28;
        while (off < 32 and char_idx < 13) : ({
            off += 2;
            char_idx += 1;
        }) {
            chars[char_idx] = getLfnChar(entry, off);
        }

        lfn_parts[num_parts] = chars;
        num_parts += 1;

        if (seq == 1) break; // 1st entry found
    }

    if (num_parts == 0) return 0;

    // Reconstruct flname (LFN entries are in rev order)
    var out_idx: usize = 0;
    var part_idx: isize = @as(isize, @intCast(num_parts)) - 1;
    while (part_idx >= 0) : (part_idx -= 1) {
        const pidx: usize = @intCast(part_idx);
        for (lfn_parts[pidx]) |char| {
            if (char == 0x0000 or char == 0xFFFF) break; // Ends
            // ASCII conv
            if (char < 0x80 and out_idx < out.len) {
                out[out_idx] = @truncate(char);
                out_idx += 1;
            }
        }
    }

    return out_idx;
}

fn formatShortName(entry: []const u8, buf: *[12]u8) []const u8 {
    var idx: usize = 0;
    while (idx < 8 and entry[DIR_NAME + idx] != ' ') : (idx += 1) {
        buf[idx] = entry[DIR_NAME + idx];
    }
    if (entry[DIR_EXT] != ' ') {
        buf[idx] = '.';
        idx += 1;
        var j: usize = 0;
        while (j < 3 and entry[DIR_EXT + j] != ' ') : (j += 1) {
            buf[idx] = entry[DIR_EXT + j];
            idx += 1;
        }
    }
    buf[idx] = 0;
    return buf[0..idx];
}

fn normalizeName(name: []const u8, out: *[12]u8) usize {
    var i: usize = 0;
    var dot: ?usize = null;
    while (i < name.len) : (i += 1) {
        if (name[i] == '.') {
            dot = i;
            break;
        }
    }
    var out_idx: usize = 0;
    const base_end = dot orelse name.len;
    var bi: usize = 0;
    while (bi < base_end and out_idx < 8) : (bi += 1) {
        const ch = name[bi];
        out[out_idx] = std.ascii.toUpper(ch);
        out_idx += 1;
    }
    if (dot != null) {
        out[out_idx] = '.';
        out_idx += 1;
        var ei: usize = dot.? + 1;
        var ext_len: usize = 0;
        while (ei < name.len and ext_len < 3) : ({
            ei += 1;
            ext_len += 1;
        }) {
            out[out_idx] = std.ascii.toUpper(name[ei]);
            out_idx += 1;
        }
    }
    out[out_idx] = 0;
    return out_idx;
}
