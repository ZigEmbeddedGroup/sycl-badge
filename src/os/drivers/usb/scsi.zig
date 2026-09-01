//! SCSI Definitions
//!
//! SPC-3 and SBC-3 are the sources for current values.
const std = @import("std");
const microzig = @import("microzig");
const EndianInt = microzig.core.mem.EndianInt;

pub const Opcode = enum(u8) {
    test_unit_ready = 0x00,
    request_sense = 0x03,
    inquiry = 0x12,
    mode_sense_6 = 0x1a,
    prevent_allow = 0x1e,
    start_stop_unit = 0x1b,
    read_format_capacities = 0x23,
    read_capacity = 0x25,
    read_capacity_16 = 0x9e,
    mode_sense_10 = 0x5a,
    synchronize_cache = 0x35,
    verify = 0x2f,
    read_10 = 0x28,
    write_10 = 0x2a,
    _,

    pub fn cdb_format(op: Opcode) cdb.Format {
        const group: Group = @fromBackingInt(@intCast(@as(u8, @bitCast(op)) >> 5));
        return group.format();
    }
};

pub const Command = enum(u5) {
    inquiry = 0x12,
    test_unit_ready = 0x00,
    request_sense = 0x03,
    mode_sense = 0x1A,
    prevent_allow = 0x1E,
    start_stop_unit = 0x1B,
    read_format_capacities = 0x03,
    read_capacity = 0x05,
    synchronize_cache = 0x15,
    verify,
    read,
    write,
};

pub const Group = enum(u3) {
    _,

    pub fn format(g: Group) cdb.Format {
        return switch (@backingInt(g)) {
            0b000 => .six,
            0b001, 0b010 => .ten,
            0b100 => .sixteen,
            0b101 => .twelve,
            0b011 => .reserved,
            0b110, 0b111 => .vendor_specific,
        };
    }

    // Keep these for the non ambiguous groups/sizes
    pub const six: Group = @fromBackingInt(0b000);
    pub const sixteen: Group = @fromBackingInt(0b100);
    pub const twelve: Group = @fromBackingInt(0b101);
    pub const reserved: Group = @fromBackingInt(0b011);
};

pub const cdb = struct {
    pub const Format = enum {
        six,
        ten,
        twelve,
        sixteen,

        reserved,
        vendor,

        pub fn size(f: Format) u5 {
            return switch (f) {
                .six => 6,
                .ten => 10,
                .twelve => 12,
                .sixteen => 16,

                .reserved, .vendor => 0,
            };
        }
    };

    pub const TestUnitReady = packed struct(u40) {
        _reserved: u32,
        control: u8,
    };

    pub const RequestSense = packed struct(u40) {
        desc: u1,
        _reserved: u23,
        allocation_length: u8,
        control: u8,
    };

    pub const Inquiry = packed struct(u40) {
        evpd: u1,
        obsolete: u1,
        _reserved: u6,
        page_code: u8,
        allocation_length: EndianInt(u16, .big),
        control: u8,
    };

    pub const ModeSense6 = packed struct(u40) {
        _reserved0: u3,
        dbd: u1,
        _reserved1: u4,
        page_code: u6,
        pc: u2,
        subpage_code: u8,
        allocation_len: u8,
        control: u8,
    };

    pub const PreventAllow = packed struct(u40) {
        _reserved: u30,
        prevent: u2,
        control: u8,
    };

    pub const StartStopUnit = packed struct(u40) {
        immed: u1,
        _reserved0: u15,
        power_condition_modifier: u4,
        _reserved1: u4,
        start: u1,
        loej: u1,
        no_flush: u1,
        _reserved2: u1,
        power_condition: u4,
        control: u8,
    };

    pub const ReadFormatCapacities = packed struct(u72) {
        todo: u72,
    };

    pub const SynchronizeCache10 = packed struct(u72) {
        obsolete: u1,
        immed: u1,
        sync_nv: u1,
        reserved: u5,
        lba: EndianInt(u32, .big),
        group_number: u5,
        _reserved: u3,
        number_of_blocks: EndianInt(u16, .big),
        control: u8,
    };

    pub const SynchronizeCache16 = packed struct(u120) {
        obsolete: u1,
        immed: u1,
        sync_nv: u1,
        reserved: u5,
        lba: EndianInt(u64, .big),
        number_of_blocks: EndianInt(u32, .big),
        group_number: u5,
        _reserved: u3,
        control: u8,
    };

    pub const Verify10 = packed struct(u72) {
        obsolete: u1,
        bytchk: u1,
        _reserved0: u2,
        dpo: u1,
        vrprotect: u2,
        lba: EndianInt(u32, .big),
        group_number: u5,
        _reserved1: u2,
        _restricted: u1,
        verification_len: EndianInt(u16, .big),
        control: u8,
    };

    pub const Verify12 = packed struct(u88) {
        obsolete: u1,
        bytchk: u1,
        _reserved0: u2,
        dpo: u1,
        vrprotect: u2,
        lba: EndianInt(u32, .big),
        verification_len: EndianInt(u32, .big),
        group_number: u5,
        _reserved1: u2,
        _restricted: u1,
        control: u8,
    };

    pub const Verify16 = packed struct(u120) {
        obsolete: u1,
        bytchk: u1,
        _reserved0: u2,
        dpo: u1,
        vrprotect: u2,
        lba: EndianInt(u64, .big),
        verification_len: EndianInt(u32, .big),
        group_number: u5,
        _reserved1: u2,
        _restricted: u1,
        control: u8,
    };

    pub const Read10 = packed struct(u72) {
        obsolete: u1,
        fua_nv: u1,
        _reserved0: u1,
        fua: u1,
        dpo: u1,
        rdprotect: u3,
        lba: EndianInt(u32, .big),
        group_number: u5,
        _reserved1: u3,
        transfer_len: EndianInt(u16, .big),
        control: u8,
    };

    pub const Write10 = packed struct(u72) {
        obsolete: u1,
        fua_nv: u1,
        _reserved0: u1,
        fua: u1,
        dpo: u1,
        wrprotect: u3,
        lba: EndianInt(u32, .big),
        group_number: u5,
        _reserved1: u3,
        transfer_len: EndianInt(u16, .big),
        control: u8,
    };

    pub const ReadCapacity10 = packed struct(u72) {
        obsolete: u1,
        _reserved0: u7,
        lba: EndianInt(u32, .big),
        _reserved1: u23,
        pmi: u1,
        control: u8,
    };

    pub const ReadCapacity16 = packed struct(u120) {
        service_action: u5 = 0x10,
        _reserved0: u3,
        lba: EndianInt(u64, .big),
        allocation_len: EndianInt(u32, .big),
        pmi: u1,
        _reserved1: u7,
        control: u8,
    };

    pub const ModeSense10 = packed struct(u72) {
        _reserved0: u3,
        dbd: u1,
        llbaa: u1,
        _reserved1: u3,
        page_code: u6,
        pc: u2,
        subpage_code: u8,
        _reserved2: u24,
        allocation_len: EndianInt(u16, .big),
        control: u8,
    };
};

pub const response = struct {
    pub const DeviceIdentification_VPD_Page = packed struct(u32) {
        peripheral_device_type: PeripheralDeviceType,
        peripheral_qualifier: u3,
        page_code: u8,
        page_length: EndianInt(u16, .big),

        // TODO: Following this structure in memory, there is a list of
        // variable length descriptors
    };

    // ReadCapacityParamData
};

pub const PeripheralDeviceType = enum(u5) {
    /// Eg. magnetic disc
    direct_access_block = 0x00,
    /// Eg. Magnetic tape
    sequential_access = 0x01,
    printer = 0x02,
    processor = 0x03,
    write_once = 0x04,
    cd_dvd = 0x05,
    /// Obsolete
    scanner = 0x06,
    optical_memory = 0x07,
    /// Eg. jukeboxes
    medium_changer = 0x08,
    /// Obsolete
    communications = 0x09,
    /// Eg. RAID
    storage_array_controller = 0x0C,
    enclosure_services = 0x0D,
    simplified_direct_access = 0x0E,
    optical_card_reader_writer = 0x0F,
    bridge_controller_commands = 0x10,
    object_based_storage = 0x11,
    automation_drive_interface = 0x12,
    well_known_logical_unit = 0x1E,
    unknown_or_no_type = 0x1F,

    _,
};
