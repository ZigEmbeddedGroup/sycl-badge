//! FAT12 Driver
const microzig = @import("microzig");
const assert = microzig.assert;

const std = @import("std");
const log = std.log.scoped(.fat);

pub const Region = enum(u2) {
    reserved = 0,
    fat = 1,
    root_directory = 2,
    file_and_directory_data = 3,
};

pub const Type = enum {
    fat12,
    fat16,
    fat32,
};

const endian = std.lang.Endian.little;

// 0th sector
pub const BootSector = packed struct(@Int(.unsigned, 512 * 8)) {
    jmp_boot: u24,
    oem_name: u64,
    /// Must be 512, 1024, 2048, or 4096
    bytes_per_sector: enum(u16) {
        _,

        pub fn valid(self: @This()) bool {
            return switch (@backingInt(self)) {
                512, 1024, 2048, 4096 => true,
                else => false,
            };
        }
    },
    /// Must be a power of two greater than 0
    sectors_per_cluster: enum(u8) {
        _,

        pub fn valid(self: @This()) bool {
            return switch (@backingInt(self)) {
                1, 2, 4, 8, 16, 32, 64 => true,
                else => false,
            };
        }
    },
    /// Must not be zero
    reserved_sector_count: u16,
    /// The count of file allocation tables
    num_fats: u8,
    /// Count of 32-byte directory entries in the root directory
    root_entry_count: u16,
    /// The total sector count if it is less than 0x10000, otherwise zero.
    total_sectors_16: u16,
    media: enum(u8) {
        _,

        pub fn valid(self: @This()) bool {
            return switch (@backingInt(self)) {
                0xF0, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF => true,
                else => false,
            };
        }
    } = @fromBackingInt(0xF0),
    /// Count of sectors occupied by one FAT
    sectors_per_fat: u16,
    sectors_per_track: u16,

    num_heads: u16,
    hidden_sectors: u32,
    /// The total sector count if it is greater or equal to 0x10000, otherwise
    /// zero.
    total_sectors_32: u32,

    // FAT12/FAT16 diverge from FAT32 starting here.

    drive_num: u8,
    reserved1: u8,
    boot_sig: u8,
    volume_id: u32,
    volume_label: u88,
    file_system_type: u64,
    _zeroes: @Int(.unsigned, 448 * 8) = 0,
    signature_word: u16 = signature_value,

    fn assert_offset(comptime field_name: []const u8, expected_offset: usize) void {
        const offset = @offsetOf(BootSector, field_name);
        if (offset != expected_offset)
            @panic(std.fmt.comptimePrint("BootSector field {s} expected offset was {} but it's really {}", .{ field_name, expected_offset, offset }));
    }

    comptime {
        assert_offset("bytes_per_sector", 11);
        assert_offset("sectors_per_cluster", 13);
        assert_offset("reserved_sector_count", 14);
        assert_offset("num_fats", 16);
        assert_offset("root_entry_count", 17);
        assert_offset("total_sectors_16", 19);
        assert_offset("media", 21);
        assert_offset("sectors_per_fat", 22);
        assert_offset("sectors_per_track", 24);
        assert_offset("num_heads", 26);
        assert_offset("hidden_sectors", 28);
        assert_offset("total_sectors_32", 32);
        assert_offset("drive_num", 36);
        assert_offset("boot_sig", 38);
        assert_offset("volume_id", 39);
        assert_offset("volume_label", 43);
        assert_offset("file_system_type", 54);
        assert_offset("signature_word", 510);
    }

    const signature_value = 0xAA55;

    pub fn format(bs: *const BootSector, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.print(
            \\BOOT SECTOR:
            \\  JMP BOOT: 0x{X}
            \\  OEM NAME: {X}
            \\  BYTES PER SECTOR: {}
            \\  SECTORS PER CLUSTER: {}
            \\  RESERVED SECTOR COUNT: {}
            \\  NUM FATS: {}
            \\  ROOT ENTRIES: {}
            \\  TOTAL SECTORS(16): {}
            \\  MEDIA: 0x{X}
            \\  FAT SIZE(16): {}
            \\  SECTORS PER TRACKING INTERRUPT: {}
            \\  NUM HEADS: {}
            \\  HIDDEN SECTORS: {}
            \\  TOTAL SECTORS(32): {}
            \\  DRIVE NUM: {}
            \\  BOOT_SIG: {}
            \\  VOLUME ID: {}
            \\  VOLUME_LABEL: {X}
            \\  FILE SYSTEM TYPE: {X}
            \\  SIGNATURE WORD: 0x{X}
            \\
        , .{
            bs.jmp_boot,
            bs.oem_name,
            bs.bytes_per_sector,
            bs.sectors_per_cluster,
            bs.reserved_sector_count,
            bs.num_fats,
            bs.root_entry_count,
            bs.total_sectors_16,
            @backingInt(bs.media),
            bs.sectors_per_fat,
            bs.sectors_per_track,
            bs.num_heads,
            bs.hidden_sectors,
            bs.total_sectors_32,
            bs.drive_num,
            bs.boot_sig,
            bs.volume_id,
            bs.volume_label,
            bs.file_system_type,
            bs.signature_word,
        });
    }

    pub fn valid(bs: *const BootSector) bool {
        const jmp_boot: *const [3]u8 = @ptrCast(&bs.jmp_boot);
        log.info("jmp_boot: {X}", .{jmp_boot});
        switch (jmp_boot[0]) {
            0xE9 => {},
            0xEB => if (jmp_boot[2] != 0x90) return false,
            else => return false,
        }

        log.info("BYTES PER SECTOR: {}", .{bs.bytes_per_sector});
        if (!bs.bytes_per_sector.valid())
            return false;

        log.info("SECTORS PER CLUSTER: {}", .{bs.sectors_per_cluster});
        if (!bs.sectors_per_cluster.valid())
            return false;

        log.info("RESERVED_SECTOR COUNT: {}", .{bs.reserved_sector_count});
        if (bs.reserved_sector_count == 0)
            return false;

        // TODO: there is more but this is fine for now

        log.info("SIGNATURE_WORD: 0x{X}", .{bs.signature_word});
        return bs.signature_word == signature_value;
    }

    pub const SizeUnit = enum {
        byte,
        sector,
    };

    pub const Size = union(SizeUnit) {
        byte: usize,
        sector: usize,
    };

    pub fn calc_fat_offset(bs: *const BootSector, unit: SizeUnit, fat_idx: usize) Size {
        assert(fat_idx < bs.num_fats, .{});
        const sector_offset = bs.reserved_sector_count + (fat_idx * bs.sectors_per_fat);
        return switch (unit) {
            .sector => .{ .sector = sector_offset },
            .byte => .{ .byte = @backingInt(bs.bytes_per_sector) * sector_offset },
        };
    }

    pub fn fat(bs: *const BootSector, fat_idx: usize) FAT12 {
        const base: [*]const u8 = @ptrFromInt(@intFromPtr(bs) + bs.calc_fat_offset(.byte, fat_idx).byte);
        return .{
            .raw = base[0..(bs.sectors_per_fat * @backingInt(bs.bytes_per_sector))],
        };
    }

    pub fn total_sectors(bs: *const BootSector) u32 {
        return if (bs.total_sectors_16 > 0)
            bs.total_sectors_16
        else
            bs.total_sectors_32;
    }

    pub fn root_dir_sectors(bs: *const BootSector) u32 {
        return ((bs.root_entry_count * 32) + (@backingInt(bs.bytes_per_sector) - 1)) / @backingInt(bs.bytes_per_sector);
    }

    pub fn get_type(bs: *const BootSector) Type {
        const data_sectors = bs.total_sectors() - (bs.reserved_sector_count + (bs.num_fats * bs.sectors_per_fat) + bs.root_dir_sectors());
        const clusters = data_sectors / @backingInt(bs.sectors_per_cluster);
        return switch (clusters) {
            0...4084 => .fat12,
            4085...65524 => .fat16,
            else => .fat32,
        };
    }

    /// THe root directory is a special container file
    pub fn root_dir_sector_start(bs: *const BootSector) u32 {
        return bs.reserved_sections + (bs.num_fats * bs.fat_size_16);
    }

    pub fn root_dir_size(bs: *const BootSector) u32 {
        return bs.root_entry_count * 32; // because each entry is 32 bytes
    }

    fn fat12_entry_from_cluster(bs: *const BootSector, cluster: u32) FAT12.Entry {
        // note: rounds down
        const fat_offset = cluster + (cluster / 2);
        const fat_sector = bs.reserved_sector_count + (fat_offset / bs.bytes_per_sector);
        const fat_ent_offset = fat_offset % bs.bytes_per_sector;
        if (fat_ent_offset == (bs.bytes_per_sector) - 1) {
            // THis cluster access spans a sector.
            //
            // with FAT12, always consider loading cluster N and N+1
        }

        const fat_number = 1;
        const sector_number = (fat_number * bs.fat_size_16) + fat_sector;
        _ = sector_number;
        // TODO:
    }
};

pub const FAT12 = struct {
    raw: []const u8,

    /// The FAT defines a singly linked list of clusters of a file and thereby maps
    /// the data region of the volume by cluster number. The first data cluster in
    /// the volume is cluster 2.
    pub const Entry = enum(u12) {
        first = 0x002,
        max = 0xFEE,
        defective = 0xFF7,
        eof = 0xFFF,
        _,

        pub fn valid(entry: Entry) bool {
            return switch (@backingInt(entry)) {
                @backingInt(Entry.first)...@backingInt(Entry.max) => true,
                else => false,
            };
        }

        pub fn format(entry: Entry, w: *std.Io.Writer) std.Io.Writer.Error!void {
            switch (entry) {
                .first => try w.print("first", .{}),
                .max => try w.print("max", .{}),
                .defective => try w.print("defective", .{}),
                .eof => try w.print("eof", .{}),
                _ => try w.print("{X:0>3}", .{@backingInt(entry)}),
            }
        }
    };

    pub fn entries(fat: *const FAT12) usize {
        return fat.raw.len * 3 / 2;
    }

    pub fn at(fat: *const FAT12, idx: usize) Entry {
        const offset = idx * 3 / 2;
        const ptr: *align(1) const u16 = @ptrCast(&fat.raw[offset]);
        const raw_entry: u12 = if (idx & 1 == 1)
            @truncate(ptr.* >> 4)
        else
            @truncate(ptr.*);

        return @bitCast(raw_entry);
    }

    pub fn format(fat: *const FAT12, w: *std.Io.Writer) std.Io.Writer.Error!void {
        const width = 16;
        //for (0..fat.entries() / width) |row| {
        const row = 0;
        try w.print("0x{X:0>4}:", .{row * width});
        for (0..width) |col| {
            try w.print(" {f}", .{fat.at((row * width) + col)});
        }
        try w.print("\n", .{});
        //}
    }
};

pub const DirectoryEntry = extern struct {
    name: [11]u8,
    attributes: Attributes,
    _reserved: [10]u8,
    time: u16,
    date: u16,
    starting_cluster: u16,
    filesize: u32,
};

pub const Attributes = packed struct(u8) {
    /// The file cannot be modified
    read_only: bool,
    /// The corresponding file or subdirectory must not be listed unless
    /// explicitly requested
    hidden: bool,
    /// Tagged as a component of the operating system
    system: bool,
    /// The corresponding entry contains the volume label
    volume_label: bool,
    /// The corresponding entry represents a directory, a child of the
    /// containing directory
    ///
    /// File size for this must always be zero.
    directory: bool,
    /// Must be set when the file is created, renamed, or modified. The
    /// presence indicates that the file has changed in some way.
    archive: bool,
    _unused: u2,
};

pub const Directory = packed struct(@Int(.unsigned, 32 * 8)) {
    name: u88,
    attributes: Attributes,
    _reserved0: u8,
    creation_time_tenths: enum(u8) {
        _,

        pub fn valid(self: @This()) bool {
            return switch (@backingInt(self)) {
                0...199 => true,
                else => false,
            };
        }
    },
    creation_time: u16,
    creation_date: u16,
    last_access_date: u16,
    // Only valid for FAT32
    first_data_cluster_high: u16 = 0,
    last_write_time: u16,
    last_write_date: u16,
    first_data_cluster_low: u16,
    // Size in bytes
    file_size: u32,

    pub fn init() void {
        // When a new directory is created, the following must be done:
        // - set archive flag
        // - set file size to 0
        // - at least one cluster must be allocated
        // - if only one is allocated, then the associated entry must be set as EOF
        // - contents of allocated clusters must be set to 0
        // - The directory must have two files:
        //  - .
        //  - ..
    }
};
