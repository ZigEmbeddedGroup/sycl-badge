/// FAT12-based cart storage in the romfs flash region
const std = @import("std");
const rom = @import("../drivers/rom.zig");
const uart = @import("../drivers/uart.zig");
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
    short_name: [12]u8, // "NAME.EXT" + NUL
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
    uart.puts("\r\nStorage Init\r\n");

    var buf: [96]u8 = undefined;
    const base = romfsBase();
    const msg = std.fmt.bufPrint(&buf, "ROMFS base: 0x{x} size: {d}KB\r\n", .{ base, romfsSize() / 1024 }) catch "";
    uart.puts(msg);

    if (!isFormatted()) {
        uart.puts("Not Formatted, Formatting now.\r\n");
        formatVolume();
        uart.puts("Format complete\r\n");
    } else {
        uart.puts("Already formatted, preserving existing data\r\n");
    }

    // Test: Read LBA 19 and show first 16 bytes to verify persistence
    var test_sector: [SECTOR_SIZE]u8 = undefined;
    readSector(19, test_sector[0..]);
    uart.puts("LBA 19 data[0..16]: ");
    for (test_sector[0..16]) |byte| {
        var hex_buf: [3]u8 = undefined;
        const hex = std.fmt.bufPrint(&hex_buf, "{x:0>2}", .{byte}) catch "";
        uart.puts(hex);
    }
    uart.puts("\r\n");

    debugDump();
    uart.puts("Storage Init Complete\r\n");
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
    const base_ptr: [*]const u8 = @ptrFromInt(romfsBase());
    const boot = base_ptr[0..SECTOR_SIZE];
    const signature = readU16(boot, BS_SIGNATURE);
    const bytes_per_sector = readU16(boot, BS_BYTES_PER_SECTOR);
    const root_entries = readU16(boot, 17);
    const fs_type = boot[BS_FS_TYPE .. BS_FS_TYPE + 8];

    // Debug: Show what we found
    var buf: [128]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "Check format: sig=0x{x:0>4} bps={d} root={d} fstype=", .{ signature, bytes_per_sector, root_entries }) catch "";
    uart.puts(msg);
    for (fs_type) |c| {
        var cbuf: [2]u8 = undefined;
        cbuf[0] = if (c >= 32 and c < 127) c else '.';
        cbuf[1] = 0;
        uart.puts(cbuf[0..1]);
    }
    uart.puts("\r\n");

    // Check all BPB fields match expected values
    if (signature != 0xAA55 or bytes_per_sector != SECTOR_SIZE or root_entries != ROOT_ENTRIES or !std.mem.eql(u8, fs_type, "FAT12   ")) {
        uart.puts("Format check FAILED (boot sector invalid)\r\n");
        return false;
    }
    var fat0: [SECTOR_SIZE]u8 = undefined;
    readSector(1, fat0[0..]);
    const valid = fat0[0] == MEDIA_DESCRIPTOR and fat0[1] == 0xFF and fat0[2] == 0xFF and fat0[3] == 0x00;
    if (!valid) {
        var buf2: [64]u8 = undefined;
        const msg2 = std.fmt.bufPrint(&buf2, "Format check FAILED (FAT: {x:0>2} {x:0>2} {x:0>2} {x:0>2})\r\n", .{ fat0[0], fat0[1], fat0[2], fat0[3] }) catch "";
        uart.puts(msg2);
    }
    return valid;
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
    sector_buf[3] = 0x00;

    var fat_index: u8 = 0;
    while (fat_index < NUM_FATS) : (fat_index += 1) {
        var i: u16 = 0;
        while (i < fat_secs) : (i += 1) {
            const lba = fat_start + (@as(u32, fat_index) * fat_secs) + i;
            writeSector(lba, sector_buf[0..]);
            @memset(sector_buf[0..], 0);
        }
        sector_buf[0] = MEDIA_DESCRIPTOR;
        sector_buf[1] = 0xFF;
        sector_buf[2] = 0xFF;
        sector_buf[3] = 0x00;
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

fn debugDump() void {
    var sector: [SECTOR_SIZE]u8 = undefined;
    readSector(0, sector[0..]);
    const bytes_per_sector = readU16(sector[0..], BS_BYTES_PER_SECTOR);
    const sectors_per_cluster = sector[13];
    const reserved = readU16(sector[0..], 14);
    const fats = sector[16];
    const root_entries = readU16(sector[0..], 17);
    const total16 = readU16(sector[0..], 19);
    const media = sector[21];
    const fat_secs = readU16(sector[0..], 22);
    const fs_type = sector[BS_FS_TYPE .. BS_FS_TYPE + 8];

    var buf: [160]u8 = undefined;
    uart.puts("FAT boot sector:\r\n");
    const line = std.fmt.bufPrint(
        &buf,
        "  BPS={d} SPC={d} RSV={d} FATS={d} ROOT={d} TOT16={d} FATSEC={d} MEDIA=0x{x}\r\n",
        .{ bytes_per_sector, sectors_per_cluster, reserved, fats, root_entries, total16, fat_secs, media },
    ) catch "";
    uart.puts(line);
    uart.puts("  FS TYPE: ");
    uart.puts(fs_type);
    uart.puts("\r\n");

    uart.puts("  BOOT HEX: ");
    dumpHex(sector[0..64]);
    uart.puts("\r\n");

    // Dump FAT0 (first sector) and ROOT (first sector) for debugging.
    readSector(1, sector[0..]);
    uart.puts("  FAT0 HEX: ");
    dumpHex(sector[0..64]);
    uart.puts("\r\n");

    const root_lba = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    readSector(root_lba, sector[0..]);
    uart.puts("  ROOT0 HEX: ");
    dumpHex(sector[0..64]);
    uart.puts("\r\n");
}

fn dumpHex(bytes: []const u8) void {
    var buf: [3]u8 = undefined;
    for (bytes) |b| {
        _ = std.fmt.bufPrint(&buf, "{x:0>2} ", .{b}) catch {
            return;
        };
        uart.puts(buf[0..3]);
    }
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
        uart.puts("ERROR: writeSector LBA out of range\r\n");
        return;
    }

    if (src.len != SECTOR_SIZE) {
        var buf: [64]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "ERROR: writeSector wrong size: {d}\r\n", .{src.len}) catch "";
        uart.puts(msg);
        return;
    }

    const addr = romfsBase() + lba * SECTOR_SIZE;
    const block_addr = addr & ~@as(u32, FLASH_ERASE_BLOCK - 1);
    const block_offset = addr - block_addr;

    // Log every write with first 4 bytes to verify data
    var buf: [96]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "WRITE LBA={d} data[0..4]={x:0>2}{x:0>2}{x:0>2}{x:0>2}\r\n", .{ lba, src[0], src[1], src[2], src[3] }) catch "";
    uart.puts(msg);

    // For now, we can only buffer one 4KB block, so if switching blocks,
    // we must flush the old block first.
    if (!pending_valid or pending_block_addr != block_addr) {
        if (pending_valid and pending_dirty and pending_block_addr != block_addr) {
            uart.puts("Switching blocks, flushing old\r\n");
            flushPending();
        }
        const block_ptr: [*]const u8 = @ptrFromInt(block_addr);
        @memcpy(pending_buf[0..FLASH_ERASE_BLOCK], block_ptr[0..FLASH_ERASE_BLOCK]);
        pending_block_addr = block_addr;
        pending_valid = true;
    }

    @memcpy(pending_buf[block_offset .. block_offset + SECTOR_SIZE], src[0..SECTOR_SIZE]);
    pending_dirty = true;
    uart.puts("Marked dirty=true\r\n");
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

    var buf: [96]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "FLUSH: 4KB @ 0x{x}\r\n", .{pending_block_addr}) catch "";
    uart.puts(msg);

    const flash_offset = pending_block_addr - XIP_BASE;
    interrupts.disableInterrupts();
    defer interrupts.enableInterrupts();

    rom.flash_exit_xip();
    rom.flash_range_erase(flash_offset, FLASH_ERASE_BLOCK, FLASH_ERASE_BLOCK, FLASH_ERASE_CMD);
    rom.flash_range_program(flash_offset, pending_buf[0..FLASH_ERASE_BLOCK]);
    rom.flash_flush_cache();
    rom.flash_enter_cmd_xip();
    pending_dirty = false;
    uart.puts("FLUSH: complete\r\n");
}

pub fn listCarts(callback: *const fn (name: []const u8, size: u32) void) void {
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        readSector(lba, sector_buf[0..]);
        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue; // LFN
            if (attr & 0x08 != 0) continue; // volume label
            if (attr & 0x10 != 0) continue; // directory
            const short = formatShortName(entry, &name_buf);
            const size = readU32(entry, DIR_FILE_SIZE);
            callback(short, size);
        }
    }
}

pub fn findCart(name: []const u8) ?CartInfo {
    var target: [12]u8 = undefined;
    const target_len = normalizeName(name, &target);
    var sector_buf: [SECTOR_SIZE]u8 = undefined;
    const root_start = VOLUME_START_LBA + RESERVED_SECTORS + (@as(u32, NUM_FATS) * fatSectors());
    const root_secs = rootDirSectors();
    var lba: u32 = root_start;
    var remaining: u16 = root_secs;
    var name_buf: [12]u8 = undefined;

    while (remaining > 0) : ({
        lba += 1;
        remaining -= 1;
    }) {
        readSector(lba, sector_buf[0..]);
        var i: usize = 0;
        while (i < SECTOR_SIZE) : (i += DIR_ENTRY_SIZE) {
            const entry = sector_buf[i .. i + DIR_ENTRY_SIZE];
            if (entry[0] == 0x00) return null;
            if (entry[0] == 0xE5) continue;
            const attr = entry[DIR_ATTR];
            if (attr == 0x0F) continue;
            if (attr & 0x08 != 0) continue;
            if (attr & 0x10 != 0) continue;
            const short = formatShortName(entry, &name_buf);
            if (std.mem.eql(u8, short, target[0..target_len])) {
                return .{
                    .start_cluster = readU16(entry, DIR_FIRST_CLUSTER),
                    .size = readU32(entry, DIR_FILE_SIZE),
                    .short_name = name_buf,
                };
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
            const short = formatShortName(entry, &name_buf);
            if (std.mem.eql(u8, short, target[0..target_len])) {
                sector_buf[i] = 0xE5;
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
