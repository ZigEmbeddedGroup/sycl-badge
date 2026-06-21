const scsi = @import("scsi.zig");

const microzig = @import("microzig");
const assert = microzig.assert;
const types = microzig.core.usb.types;
const EndianInt = microzig.core.mem.EndianInt;

const std = @import("std");
const log = std.log.scoped(.msc);

const endpoint = @import("endpoint.zig");

const storage = @import("../../loader/storage.zig");

pub const Phase = enum {
    command,
    data_in,
    data_out,
    status,
};

pub const ClassRequest = packed struct(u16) {
    recipient: types.RequestType.Recipient = .interface,
    type: types.RequestType.Type = .class,
    direction: types.Dir,
    request: enum(u8) {
        bulk_only_mass_storage_reset = 0xFF,
        get_max_lun = 0xFE,
    },
};

// The only two class requests for bulk-only mass storage
pub const bulk_only_mass_storage_reset = ClassRequest{ .direction = .out, .request = .bulk_only_mass_storage_reset };
pub const get_max_lun = ClassRequest{ .direction = .in, .request = .get_max_lun };

pub const Callbacks = struct {
    bulk_only_mass_storage_reset: *const fn (ctx: ?*anyopaque) void,
    get_max_lun: *const fn (ctx: ?*anyopaque) u4,
    queue_packet: *const fn (data: []const u8, pid: endpoint.PacketIdentifier) void,
    queue_receive: *const fn (pid: endpoint.PacketIdentifier) void,
    get_buffer: *const fn () []const u8,
};

/// Command Block Wrapper
pub const CBW = extern struct {
    sig: EndianInt(u32, .little) = .from(signature),
    tag: EndianInt(u32, .little),
    transfer_len: EndianInt(u32, .little),
    flags: Flags,
    lun: u8,
    command_len: u8,
    command_data: [16]u8,

    const size = 31;
    const signature = 0x43425355;

    pub const Flags = packed struct(u8) {
        _reserved: u7,
        direction: enum(u1) {
            out = 0,
            in = 1,
        },
    };

    pub const Command = union(scsi.Opcode) {
        test_unit_ready: *const scsi.cdb.TestUnitReady,
        request_sense: *const scsi.cdb.RequestSense,
        inquiry: *const scsi.cdb.Inquiry,
        mode_sense_6: *const scsi.cdb.ModeSense6,
        prevent_allow: *const scsi.cdb.PreventAllow,
        start_stop_unit: *const scsi.cdb.StartStopUnit,
        read_format_capacities: *const scsi.cdb.ReadFormatCapacities,
        read_capacity: *const scsi.cdb.ReadCapacity10,
        read_capacity_16: *const scsi.cdb.ReadCapacity16,
        mode_sense_10: *const scsi.cdb.ModeSense10,
        synchronize_cache: *const scsi.cdb.SynchronizeCache,
        verify: *const scsi.cdb.Verify,
        read_10: *const scsi.cdb.Read10,
        write_10: *const scsi.cdb.Write10,

        comptime {
            const type_info = @typeInfo(Command).@"union";
            for (type_info.field_names, type_info.field_types) |field_name, field_type| {
                const opcode: scsi.Opcode = @field(Command, field_name);
                const child_type = @typeInfo(field_type).pointer.child;
                const expected_bitsize = (@as(usize, opcode.cdb_format().size() - 1) * 8);
                if (@bitSizeOf(child_type) != expected_bitsize) {
                    @panic(std.fmt.comptimePrint("{s} should have a size of {} bits, it currently has {}", .{
                        @typeName(child_type),
                        expected_bitsize,
                        @bitSizeOf(child_type),
                    }));
                }
            }
        }
    };

    pub fn command(cbw: *const CBW) Command {
        const opcode: scsi.Opcode = @fromBackingInt(cbw.command_data[0]);
        inline for (@typeInfo(scsi.Opcode).@"enum".field_names) |field_name| {
            if (@field(scsi.Opcode, field_name) == opcode) {
                var ret: Command = undefined;
                @field(ret, field_name) = @ptrCast(@alignCast(&cbw.command_data[1]));
                return ret;
            }
        }

        @breakpoint();
        @panic("UNRECOGNIZED");
    }

    pub fn format(cbw: *const CBW, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("sig={X} tag={X} len={} flags.direction={} lun={} command_len={} command_data={X}", .{
            cbw.sig.native(),
            cbw.tag.native(),
            cbw.transfer_len.native(),
            cbw.flags.direction,
            cbw.lun,
            cbw.command_len,
            &cbw.command_data,
        });
    }
};

/// Command Status Wrapper
const CSW = struct {
    sig: EndianInt(u32, .little) = .from(signature),
    tag: EndianInt(u32, .little),
    residue: EndianInt(u32, .little),
    status: Status,

    const size = 13;
    const signature = 0x53425355;

    pub const Status = enum(u8) {
        passed = 0,
        failed = 1,
        /// Eg. malformed CBW
        phase_error = 2,
        _,
    };

    pub fn format(csw: *const CSW, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("sig={X} tag={X} residue={} status={}", .{
            csw.sig.native(),
            csw.tag.native(),
            csw.residue.native(),
            csw.status,
        });
    }
};

pub const Config = struct {
    max_packet_size: u8,
    max_transfer_size: u16,
    callbacks: Callbacks,
};

pub const Sense = struct {
    key: u8,
    asc: u8,
    ascq: u8,
};

pub fn MSC_Driver(comptime SetupProcessor: type, comptime config: Config) type {
    return struct {
        ready: struct {
            in: bool,
            out: bool,
        },
        endpoints: struct {
            in: endpoint.In,
            out: endpoint.Out,
        },
        sense: Sense,
        sm: StateMachine,
        ctx: ?*anyopaque,
        max_lun: [1]u8,
        // Both IN and OUT endpoints make use of this buffer, but because the
        // way this driver works, we should only ever be using it for one
        // direction at a time.
        buf_in: [storage.SECTOR_SIZE]u8 align(@alignOf(CSW)) = undefined,
        buf_out: [storage.SECTOR_SIZE]u8 align(@alignOf(CSW)) = undefined,

        const StateTag = enum {
            awaiting_cbw,
            sending_data,
            receiving_data,
            sending_csw,
            sending_sectors,
            receiving_sectors,
        };

        const StateMachine = union(StateTag) {
            awaiting_cbw,
            sending_data: struct {
                tag: u32,
                transfer_len: u32,
                payload_len: u32,
            },
            receiving_data,
            sending_csw: CSW,
            sending_sectors: SectorTransfer,
            receiving_sectors: SectorTransfer,

            const SectorTransfer = struct {
                tag: u32,
                transfer_len: u32,
                start: u32,
                lba: u32,
                logical_blocks: u32,
                block_offset: u32,
            };
        };

        pub fn init(self: *@This(), ctx: ?*anyopaque) void {
            self.* = .{
                .ctx = ctx,
                .max_lun = .{config.callbacks.get_max_lun(ctx)},
                .sm = .awaiting_cbw,
                .ready = .{
                    .in = false,
                    .out = false,
                },
                .endpoints = .{
                    .in = .{
                        .num = 1, // Hardcoded for now
                        .max_packet_size = config.max_packet_size,
                    },
                    .out = .{
                        .num = 1, // Hardcoded for now
                        .max_packet_size = config.max_packet_size,
                        .buf = &self.buf_out,
                    },
                },
                .sense = .{
                    .key = 0,
                    .asc = 0,
                    .ascq = 0,
                },
            };

            self.set_state(.awaiting_cbw);
        }

        pub fn setup_handler(setup_processor: *SetupProcessor, ctx: ?*anyopaque, pkt: *const types.SetupPacket) void {
            const self: *@This() = @ptrCast(@alignCast(ctx.?));
            const class_request: *const ClassRequest = @ptrCast(pkt);
            switch (class_request.*) {
                bulk_only_mass_storage_reset => {
                    log.info("BULK-ONLY MASS STORAGE RESET", .{});
                    config.callbacks.bulk_only_mass_storage_reset(self.ctx);
                    self.reset();
                    setup_processor.queue_in_xfer("", pkt.length.native());
                },
                get_max_lun => {
                    log.info("GET MAX LUN", .{});
                    self.max_lun[0] = config.callbacks.get_max_lun(self.ctx);
                    setup_processor.queue_in_xfer(&self.max_lun, pkt.length.native());
                },
                // TODO: how to signal that it's invalid?
                else => @panic("unrecognized class request"),
            }
        }

        fn expect_phase(self: *@This(), expected: Phase, actual: Phase) !void {
            _ = self;
            // TODO: make this more recoverable, we should be sending a phase
            // error in a CSW if there's a big issue. panics are not the way to
            // handle untrusted input, but fine for now.
            if (actual != expected)
                @panic("Failed expected phase check");
        }

        fn format(self: *@This(), w: *std.Io.Writer) std.Io.Writer.Error!void {
            try w.print("MSC STATE", .{});
            try w.print("IN:", .{});
            try w.print("  READY:    {}", .{self.ready.in});
            try w.print("  ENDPOINT: {}", .{self.endpoint.in});
            try w.print("OUT:", .{});
            try w.print("  READY:    {}", .{self.ready.out});
            try w.print("  ENDPOINT: {}", .{self.endpoint.out});
            try w.print("SENSE:", .{});
            try w.print("  KEY:  {}", .{self.sense.key});
            try w.print("  ASC:  {}", .{self.sense.asc});
            try w.print("  ASCQ: {}", .{self.sense.ascq});
            try w.print("STATE MACHINE: {}", .{self.sm});
        }

        pub fn poll(self: *@This()) void {
            switch (self.sm) {
                .awaiting_cbw => if (self.ready.out) {
                    defer self.ready.out = false;

                    const pkt = config.callbacks.get_buffer();
                    const cmd = self.endpoints.out.receive(pkt);
                    const payload = switch (cmd) {
                        .done => |info| blk: {
                            config.callbacks.queue_receive(info.next_pid);
                            break :blk info.payload;
                        },
                        .none => |next_pid| {
                            config.callbacks.queue_receive(next_pid);
                            return;
                        },
                        .stall => @panic("TODO: stall probably?"),
                    };

                    // Expected value of CBW
                    if (payload.len != 31) {
                        log.err("NOT THE CBW, not changing state, len={}", .{payload.len});
                        return;
                    }

                    const cbw: *const CBW = @ptrCast(@alignCast(payload.ptr));
                    log.debug("CBW: {f}", .{cbw});
                    const next_phase: Phase = if (cbw.transfer_len.native() == 0)
                        .status
                    else switch (cbw.flags.direction) {
                        .in => .data_in,
                        .out => .data_out,
                    };

                    const opcode: scsi.Opcode = @fromBackingInt(cbw.command_data[0]);
                    const tag = cbw.tag.native();
                    const transfer_len = cbw.transfer_len.native();
                    log.debug("opcode={} next_phase={}", .{ opcode, next_phase });
                    switch (opcode) {
                        .test_unit_ready => {
                            log.info("test_unit_ready", .{});
                            storage.flushPendingWrites();
                            self.queue_csw(tag, transfer_len, 0, .passed);
                        },
                        .verify, .prevent_allow, .start_stop_unit => {
                            log.info("{}", .{opcode});
                            self.queue_csw(tag, transfer_len, 0, .passed);
                        },
                        .synchronize_cache => {
                            log.info("synchronize_cache", .{});
                            storage.flushPendingWrites();
                            self.queue_csw(tag, transfer_len, 0, .passed);
                        },
                        .inquiry => {
                            log.info("inquiry", .{});
                            const resp_len = 36;
                            const resp = &self.buf_in;
                            // Byte 0: Peripheral Device Type (0x00 = Direct Access Block Device / Disk)
                            resp[0] = 0x00;
                            // Byte 1: RMB bit (0x80 = Removable Media)
                            resp[1] = 0x80;
                            // Byte 2: Version (0x05 = SPC-3 compliant for Windows compatibility)
                            resp[2] = 0x05;
                            // Byte 3: Response Data Format (0x02 = standard format per SPC-3)
                            resp[3] = 0x02;
                            // Byte 4: Additional Length (31 bytes following)
                            resp[4] = 31;
                            // Byte 5: Flags (0x00 = basic)
                            resp[5] = 0x00;
                            // Byte 6: Flags (0x00 = basic)
                            resp[6] = 0x00;
                            // Byte 7: Flags (0x00 = basic)
                            resp[7] = 0x00;
                            // Bytes 8-15: Vendor ID (8 bytes, space-padded)
                            @memcpy(resp[8..16], "SYCL    ");
                            // Bytes 16-31: Product ID (16 bytes, space-padded)
                            @memcpy(resp[16..32], "BadgeCarts      ");
                            // Bytes 32-35: Product Revision (4 bytes)
                            @memcpy(resp[32..36], "1.0 ");

                            self.send_data(tag, transfer_len, resp[0..resp_len]);
                        },
                        .read_capacity => {
                            const read_capacity: *const scsi.cdb.ReadCapacity10 = @ptrCast(@alignCast(&cbw.command_data[1]));
                            log.info("read_capacity: {}", .{read_capacity});
                            const total = storage.totalSectors() - 1;
                            var writer: std.Io.Writer = .fixed(&self.buf_in);
                            writer.writeInt(u32, total, .big) catch unreachable;
                            writer.writeInt(u32, @intCast(storage.SECTOR_SIZE), .big) catch unreachable;
                            self.send_data(tag, transfer_len, writer.buffered());
                        },
                        .mode_sense_6 => {
                            log.info("mode_sense_6", .{});
                            // Byte 0: mode data length
                            self.buf_in[0] = 3;
                            // Byte 1: medium type
                            self.buf_in[1] = 0;
                            // Byte 2: device-specific parameter (bit 7 = write protect)
                            self.buf_in[2] = 0x00;
                            // Byte 3: block descriptor length
                            self.buf_in[3] = 0;
                            self.send_data(tag, transfer_len, self.buf_in[0..4]);
                        },
                        .read_10 => {
                            const read_10: *const scsi.cdb.Read10 = @ptrCast(@alignCast(&cbw.command_data[1]));
                            const lba = read_10.lba.native();
                            const logical_blocks = read_10.transfer_len.native();

                            log.info("read_10: lba: 0x{X}, transfer_len: {}", .{ read_10.lba.native(), read_10.transfer_len.native() });

                            self.send_sectors(tag, transfer_len, lba, logical_blocks);
                        },
                        .write_10 => {
                            const write_10: *const scsi.cdb.Write10 = @ptrCast(@alignCast(&cbw.command_data[1]));
                            const lba = write_10.lba.native();
                            const logical_blocks = write_10.transfer_len.native();

                            log.info("write_10: lba: 0x{X}, transfer_len: {}", .{ write_10.lba.native(), write_10.transfer_len.native() });

                            self.receive_sectors(tag, transfer_len, lba, logical_blocks);
                        },
                        .request_sense => {
                            const request_sense: *const scsi.cdb.RequestSense = @ptrCast(@alignCast(&cbw.command_data[1]));
                            log.info("request_sense: {}", .{request_sense});

                            // Response code: current error
                            @memset(self.buf_in[0..18], 0);
                            // Response code: current error
                            self.buf_in[0] = 0x70;
                            self.buf_in[2] = self.sense.key;
                            // additional sense length
                            self.buf_in[7] = 10;
                            self.buf_in[12] = self.sense.asc;
                            self.buf_in[13] = self.sense.ascq;

                            self.send_data(tag, transfer_len, self.buf_in[0..18]);
                            self.sense = .{
                                .key = 0,
                                .asc = 0,
                                .ascq = 0,
                            };
                        },

                        .read_capacity_16 => {
                            log.info("read_capacity_16", .{});
                            const read_capacity: *const scsi.cdb.ReadCapacity16 = @ptrCast(@alignCast(&cbw.command_data[1]));
                            _ = read_capacity;
                            //    const total: u64 = storage.totalSectors() - 1;
                            //    var resp: [32]u8 = @splat(0);

                            //    var writer: std.Io.Writer = .fixed(&resp);
                            //    writer.writeInt(u64, total, .big) catch unreachable;
                            //    writer.writeInt(u32, @intCast(storage.SECTOR_SIZE), .big) catch unreachable;
                            @panic("TODO");
                        },
                        .read_format_capacities => {
                            log.info("read_format_capacities", .{});
                            const read_format_capacities: *const scsi.cdb.ReadFormatCapacities = @ptrCast(@alignCast(&cbw.command_data[1]));
                            _ = read_format_capacities;
                            //    const total = storage.totalSectors();
                            //    var resp: [12]u8 = undefined;
                            //    var writer: std.Io.Writer = .fixed(&resp);
                            //    writer.splatByteAll(0, 3) catch unreachable;
                            //    // Capacity list length = 8
                            //    writer.writeByte(8) catch unreachable;
                            //    // Number of blocks (total sectors)
                            //    writer.writeInt(u32, total, .big) catch unreachable;
                            //    // Descriptor type = formatted media
                            //    writer.writeByte(0x02) catch unreachable;
                            //    // Block length (3 bytes, big-endian)
                            //    writer.writeInt(u24, @intCast(storage.SECTOR_SIZE), .big) catch unreachable;
                            @panic("TODO");
                        },
                        .mode_sense_10 => {
                            log.info("mode_sense_10", .{});
                            //    // Bytes 0-1: mode data length
                            //    // Byte 2: medium type
                            //    // Byte 3: device-specific parameter (bit 7 = write protect)
                            //    // Bytes 4-5: reserved
                            //    // Bytes 6-7: block descriptor length
                            //    var resp: [8]u8 = .{ 0, 6, 0, 0x00, 0, 0, 0, 0 }; // 0x00 = writable
                            @panic("TODO");
                        },
                        else => {
                            log.info("ERROR OPCODE: {}", .{opcode});
                            self.queue_csw(tag, transfer_len, transfer_len, .phase_error);
                            @breakpoint();
                        },
                    }
                },
                .sending_sectors => |*sm| if (self.ready.in) {
                    if (sm.lba >= (sm.start + sm.logical_blocks) and sm.block_offset >= storage.SECTOR_SIZE) {
                        log.debug("sending_sectors: done: lba={} logical_blocks={} block_offset={} sector_size={}", .{
                            sm.lba, sm.logical_blocks, sm.block_offset, storage.SECTOR_SIZE,
                        });
                        self.queue_csw(sm.tag, sm.transfer_len, sm.transfer_len - (storage.SECTOR_SIZE * sm.logical_blocks), .passed);
                        return;
                    }

                    if (sm.block_offset >= storage.SECTOR_SIZE) {
                        sm.block_offset = 0;
                    }

                    if (sm.block_offset == 0) {
                        log.debug("sending_sectors: reading sector", .{});
                        storage.readSector(sm.lba, &self.buf_in);
                        sm.lba += 1;
                    }

                    log.debug("sending_sectors: lba={} logical_blocks={} block_offset={}", .{
                        sm.lba,
                        sm.logical_blocks,
                        sm.block_offset,
                    });

                    defer self.ready.in = false;
                    defer self.endpoints.in.pid.toggle();
                    const payload = self.buf_in[sm.block_offset .. sm.block_offset + self.endpoints.in.max_packet_size];
                    self.queue_packet(payload, self.endpoints.in.pid);
                    sm.block_offset += self.endpoints.in.max_packet_size;
                },
                .receiving_sectors => |*sm| if (self.ready.out) {
                    defer self.ready.out = false;

                    const pkt = config.callbacks.get_buffer();
                    assert(pkt.len + sm.block_offset <= self.buf_out.len, .{});

                    log.debug("receiving sectors: lba={} logical_blocks={} block_offset={} sector_size={} pkt.len={} transfer_len={}", .{
                        sm.lba, sm.logical_blocks, sm.block_offset, storage.SECTOR_SIZE, pkt.len, sm.transfer_len,
                    });

                    self.endpoints.out.pid.toggle();
                    config.callbacks.queue_receive(self.endpoints.out.pid);
                    @memcpy(self.buf_out[sm.block_offset .. sm.block_offset + pkt.len], pkt);
                    sm.block_offset += pkt.len;

                    if (sm.block_offset >= storage.SECTOR_SIZE) {
                        storage.writeSector(sm.lba, &self.buf_out);
                        sm.block_offset = 0;
                        sm.lba += 1;
                    }

                    if (sm.lba >= sm.start + sm.logical_blocks) {
                        log.debug("done receiving sectors", .{});

                        // TODO:
                        storage.flushPendingWrites();
                        self.queue_csw(sm.tag, sm.transfer_len, sm.transfer_len - (storage.SECTOR_SIZE * sm.logical_blocks), .passed);
                    }
                },
                .sending_data => |sending_data| if (self.ready.in) {
                    switch (self.endpoints.in.ready()) {
                        .queue => |queue| self.queue_packet(queue.payload, queue.pid),
                        .done => self.queue_csw(sending_data.tag, sending_data.transfer_len, sending_data.transfer_len - sending_data.payload_len, .passed),
                        else => @panic("TODO"),
                    }
                },
                .receiving_data => @panic("TODO"),
                .sending_csw => if (self.ready.in) {
                    switch (self.endpoints.in.ready()) {
                        .queue => |queue| self.queue_packet(queue.payload, queue.pid),
                        .done => {
                            self.set_state(.awaiting_cbw);
                            return;
                        },
                        else => @panic("TODO"),
                    }
                },
            }
        }

        fn set_state(self: *@This(), sm: StateMachine) void {
            const old: StateTag = self.sm;
            const new: StateTag = sm;
            log.debug("{} => {}", .{ old, new });
            self.sm = sm;
        }

        fn send_data(self: *@This(), tag: u32, transfer_len: u32, data: []const u8) void {
            self.endpoints.in.transfer = .start(data, transfer_len);
            self.set_state(.{
                .sending_data = .{
                    .tag = tag,
                    .transfer_len = transfer_len,
                    .payload_len = data.len,
                },
            });
        }

        fn send_sectors(self: *@This(), tag: u32, transfer_len: u32, lba: u32, logical_blocks: u32) void {
            self.set_state(.{
                .sending_sectors = .{
                    .tag = tag,
                    .transfer_len = transfer_len,
                    .start = lba,
                    .lba = lba,
                    .logical_blocks = logical_blocks,
                    .block_offset = 0,
                },
            });
        }

        fn receive_sectors(self: *@This(), tag: u32, transfer_len: u32, lba: u32, logical_blocks: u32) void {
            self.set_state(.{
                .receiving_sectors = .{
                    .tag = tag,
                    .transfer_len = transfer_len,
                    .start = lba,
                    .lba = lba,
                    .logical_blocks = logical_blocks,
                    .block_offset = 0,
                },
            });
        }

        fn queue_packet(self: *@This(), payload: []const u8, pid: endpoint.PacketIdentifier) void {
            assert(self.ready.in, .{});
            config.callbacks.queue_packet(payload, pid);
            self.ready.in = false;
        }

        fn queue_csw(self: *@This(), tag: u32, transfer_len: u32, residue: u32, status: CSW.Status) void {
            self.set_state(.{
                .sending_csw = .{
                    .tag = .from(tag),
                    .residue = .from(residue),
                    .status = status,
                },
            });

            const payload_len = CSW.size;
            const payload = std.mem.asBytes(&self.sm.sending_csw)[0..payload_len];
            self.endpoints.in.transfer = .start(payload, transfer_len);
            log.debug("CSW: {f}", .{self.sm.sending_csw});
        }

        pub fn reset(self: *@This()) void {
            self.set_state(.awaiting_cbw);
            self.ready = .{
                .in = false,
                .out = false,
            };
            self.endpoints.in.reset();
            self.endpoints.out.reset();
            config.callbacks.queue_receive(.DATA0);
        }

        pub fn in_ready(self: *@This()) void {
            log.debug("in_ready()", .{});
            self.ready.in = true;
        }

        pub fn out_ready(self: *@This()) void {
            log.debug("out_ready()", .{});
            self.ready.out = true;
        }
    };
}
