/// USB Mass Storage Class (MSC) driver
const std = @import("std");
const microzig = @import("microzig");
const storage = @import("../loader/storage.zig");
const uart = @import("uart.zig");

const usb = microzig.hal.usb;
const types = usb.types;

pub fn MscClassDriver(comptime UsbDeviceType: type) type {
    return struct {
        const Self = @This();
        const _ = UsbDeviceType;

        device: ?types.UsbDevice = null,
        ep_in: u8 = 0,
        ep_out: u8 = 0,

        state: State = .await_cbw,
        cbw_buf: [CBW_SIZE]u8 = undefined,
        cbw_len: usize = 0,
        out_buf: [512]u8 = undefined, // Buffer for receiving USB OUT data
        cbw_tag: u32 = 0,
        cbw_transfer_len: u32 = 0,
        cbw_flags: u8 = 0,
        cbw_cmd: [16]u8 = undefined,
        need_arm_out: bool = false, // Flag to defer OUT endpoint arming

        csw_buf: [CSW_SIZE]u8 = undefined,
        sense: Sense = .{},

        in_buf: [64]u8 = undefined,
        in_len: usize = 0,
        in_offset: usize = 0,

        block_buf: [storage.SECTOR_SIZE]u8 = undefined,
        block_offset: usize = 0,
        current_lba: u32 = 0,
        remaining_blocks: u32 = 0,
        data_residue: u32 = 0,

        const State = enum {
            await_cbw,
            data_in,
            data_out,
            send_csw,
        };

        const CBW_SIGNATURE: u32 = 0x43425355;
        const CSW_SIGNATURE: u32 = 0x53425355;
        const CBW_SIZE: usize = 31;
        const CSW_SIZE: usize = 13;

        const Sense = struct {
            key: u8 = 0,
            asc: u8 = 0,
            ascq: u8 = 0,
        };

        const SCSI_TEST_UNIT_READY = 0x00;
        const SCSI_REQUEST_SENSE = 0x03;
        const SCSI_INQUIRY = 0x12;
        const SCSI_MODE_SENSE_6 = 0x1A;
        const SCSI_PREVENT_ALLOW = 0x1E;
        const SCSI_START_STOP_UNIT = 0x1B;
        const SCSI_READ_FORMAT_CAPACITIES = 0x23;
        const SCSI_READ_CAPACITY = 0x25;
        const SCSI_READ_CAPACITY_16 = 0x9E;
        const SCSI_MODE_SENSE_10 = 0x5A;
        const SCSI_SYNCHRONIZE_CACHE = 0x35;
        const SCSI_VERIFY = 0x2F;
        const SCSI_READ_10 = 0x28;
        const SCSI_WRITE_10 = 0x2A;

        const MSC_RESET = 0xFF;
        const MSC_GET_MAX_LUN = 0xFE;

        fn init(ptr: *anyopaque, device: types.UsbDevice) void {
            var self: *Self = @ptrCast(@alignCast(ptr));
            self.device = device;
            self.sense = .{};
        }

        fn open(ptr: *anyopaque, cfg: []const u8) !usize {
            var self: *Self = @ptrCast(@alignCast(ptr));
            var curr_cfg = cfg;

            if (tryGetDescAs(types.InterfaceDescriptor, curr_cfg)) |desc_itf| {
                if (desc_itf.interface_class != 0x08) return types.DriverErrors.UnsupportedInterfaceClassType;
                if (desc_itf.interface_subclass != 0x06) return types.DriverErrors.UnsupportedInterfaceSubClassType;
            } else {
                return types.DriverErrors.ExpectedInterfaceDescriptor;
            }

            curr_cfg = getDescNext(curr_cfg);

            var endpoints: u8 = 0;
            while (endpoints < 2) : (endpoints += 1) {
                if (tryGetDescAs(types.EndpointDescriptor, curr_cfg)) |desc_ep| {
                    switch (types.Endpoint.dir_from_address(desc_ep.endpoint_address)) {
                        .In => self.ep_in = desc_ep.endpoint_address,
                        .Out => self.ep_out = desc_ep.endpoint_address,
                    }
                    self.device.?.endpoint_open(curr_cfg[0..desc_ep.length]);
                    curr_cfg = getDescNext(curr_cfg);
                }
            }

            self.prepare_out();
            return cfg.len - curr_cfg.len;
        }

        fn class_control(ptr: *anyopaque, stage: types.ControlStage, setup: *const types.SetupPacket) bool {
            var self: *Self = @ptrCast(@alignCast(ptr));
            if (setup.request_type.type != .Class) return false;
            if (stage != .Setup) return true;

            switch (setup.request) {
                MSC_RESET => {
                    self.resetState();
                    self.device.?.control_ack(setup);
                },
                MSC_GET_MAX_LUN => {
                    const max_lun: u8 = 0;
                    self.device.?.control_transfer(setup, &.{max_lun});
                },
                else => {},
            }
            return true;
        }

        fn transfer(ptr: *anyopaque, ep_addr: u8, data: []u8) void {
            var self: *Self = @ptrCast(@alignCast(ptr));

            if (ep_addr == self.ep_out) {
                self.handle_out(data);
            } else if (ep_addr == self.ep_in) {
                self.handle_in();
            }
        }

        fn handle_out(self: *Self, data: []u8) void {
            switch (self.state) {
                .await_cbw => {
                    const copy_len = @min(data.len, self.cbw_buf.len - self.cbw_len);
                    @memcpy(self.cbw_buf[self.cbw_len .. self.cbw_len + copy_len], data[0..copy_len]);
                    self.cbw_len += copy_len;
                    if (self.cbw_len >= self.cbw_buf.len) {
                        const signature = read_u32_le(self.cbw_buf[0..], 0);
                        if (signature != CBW_SIGNATURE) {
                            var buf: [64]u8 = undefined;
                            const text = std.fmt.bufPrint(&buf, "MSC invalid CBW signature: 0x{x}\r\n", .{signature}) catch "";
                            uart.puts(text);
                            self.resetState();
                            self.need_arm_out = true; // Defer arming to avoid re-entrancy
                            return;
                        }
                        self.cbw_tag = read_u32_le(self.cbw_buf[0..], 4);
                        self.cbw_transfer_len = read_u32_le(self.cbw_buf[0..], 8);
                        self.cbw_flags = self.cbw_buf[12];
                        @memcpy(self.cbw_cmd[0..], self.cbw_buf[15 .. 15 + 16]);
                        self.process_cbw();
                        if (self.state == .data_out) {
                            self.need_arm_out = true;
                        }
                    } else {
                        // Partial CBW received, need more data
                        self.need_arm_out = true; // Defer arming to avoid re-entrancy
                    }
                },
                .data_out => {
                    var offset: usize = 0;
                    // Process all data in the packet
                    while (offset < data.len) {
                        if (self.remaining_blocks > 0) {
                            // Normal write: copy data to block buffer
                            const copy_len = @min(data.len - offset, self.block_buf.len - self.block_offset);
                            @memcpy(self.block_buf[self.block_offset .. self.block_offset + copy_len], data[offset .. offset + copy_len]);
                            self.block_offset += copy_len;
                            offset += copy_len;
                            if (self.data_residue >= copy_len) {
                                self.data_residue -= @intCast(copy_len);
                            } else {
                                self.data_residue = 0;
                            }
                            if (self.block_offset == self.block_buf.len) {
                                storage.writeSector(self.current_lba, self.block_buf[0..]);
                                self.current_lba += 1;
                                self.remaining_blocks -= 1;
                                self.block_offset = 0;
                                @memset(&self.block_buf, 0); // Clear for next block
                            }
                        } else {
                            // Already written all blocks but packet has more data
                            const remaining_in_packet = data.len - offset;
                            if (self.data_residue >= remaining_in_packet) {
                                self.data_residue -= @intCast(remaining_in_packet);
                            } else {
                                self.data_residue = 0;
                            }
                            break; // Exit loop when all data is processed
                        }
                    }
                    if (self.remaining_blocks == 0) {
                        // Ensure writes are committed so carts survive power cycles.
                        storage.flushPendingWrites();
                        self.send_csw(0);
                    } else {
                        // More data needed, defer arming OUT endpoint
                        self.need_arm_out = true;
                    }
                },
                else => {
                    // For any other state, defer arming OUT endpoint
                    self.need_arm_out = true;
                },
            }
        }

        fn handle_in(self: *Self) void {
            switch (self.state) {
                .data_in => {
                    self.send_next_in_chunk();
                },
                .send_csw => {
                    self.resetState();
                    self.prepare_out();
                },
                else => {},
            }
        }

        fn process_cbw(self: *Self) void {
            self.cbw_len = 0;
            self.resetCsw(0);
            self.in_len = 0;
            self.in_offset = 0;
            self.block_offset = 0;
            self.remaining_blocks = 0;
            self.data_residue = self.cbw_transfer_len;

            switch (self.cbw_cmd[0]) {
                SCSI_TEST_UNIT_READY => {
                    // Silently flush any pending writes
                    storage.flushPendingWrites();
                    self.data_residue = 0;
                    self.send_csw(0);
                },
                SCSI_INQUIRY => {
                    self.prepare_inquiry();
                },
                SCSI_READ_CAPACITY => {
                    self.prepare_read_capacity();
                },
                SCSI_MODE_SENSE_6 => {
                    self.prepare_mode_sense();
                },
                SCSI_MODE_SENSE_10 => {
                    self.prepare_mode_sense_10();
                },
                SCSI_START_STOP_UNIT => {
                    self.data_residue = 0;
                    self.send_csw(0);
                },
                SCSI_READ_FORMAT_CAPACITIES => {
                    self.prepare_read_format_capacities();
                },
                SCSI_READ_CAPACITY_16 => {
                    self.prepare_read_capacity_16();
                },
                SCSI_SYNCHRONIZE_CACHE => {
                    storage.flushPendingWrites();
                    self.data_residue = 0;
                    self.send_csw(0);
                },
                SCSI_VERIFY => {
                    self.data_residue = 0;
                    self.send_csw(0);
                },
                SCSI_REQUEST_SENSE => {
                    self.prepare_request_sense();
                },
                SCSI_PREVENT_ALLOW => {
                    self.data_residue = 0;
                    self.send_csw(0);
                },
                SCSI_READ_10 => {
                    self.start_read10();
                },
                SCSI_WRITE_10 => {
                    self.start_write10();
                },
                else => {
                    self.set_sense(0x05, 0x20, 0x00); // Illegal request/Invalid Command
                    self.data_residue = 0;
                    self.send_csw(1);
                },
            }
        }

        fn prepare_inquiry(self: *Self) void {
            var resp: [36]u8 = [_]u8{0} ** 36;
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
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_read_capacity(self: *Self) void {
            const total = storage.totalSectors() - 1;
            var resp: [8]u8 = undefined;
            write_be_u32(resp[0..4], total);
            write_be_u32(resp[4..8], @intCast(storage.SECTOR_SIZE));
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_read_capacity_16(self: *Self) void {
            const total: u64 = storage.totalSectors() - 1;
            var resp: [32]u8 = [_]u8{0} ** 32;
            write_be_u64(resp[0..8], total);
            write_be_u32(resp[8..12], @intCast(storage.SECTOR_SIZE));
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_read_format_capacities(self: *Self) void {
            const total = storage.totalSectors();
            var resp: [12]u8 = [_]u8{0} ** 12;
            // Capacity list length = 8
            resp[3] = 8;
            // Number of blocks (total sectors)
            write_be_u32(resp[4..8], total);
            // Descriptor type = formatted media
            resp[8] = 0x02;
            // Block length (3 bytes, big-endian)
            const blk: u32 = @intCast(storage.SECTOR_SIZE);
            resp[9] = @truncate(blk >> 16);
            resp[10] = @truncate(blk >> 8);
            resp[11] = @truncate(blk);
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_mode_sense(self: *Self) void {
            // Byte 0: mode data length
            // Byte 1: medium type
            // Byte 2: device-specific parameter (bit 7 = write protect)
            // Byte 3: block descriptor length
            var resp: [4]u8 = .{ 3, 0, 0x00, 0 }; // 0x00 = writable
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_mode_sense_10(self: *Self) void {
            // Bytes 0-1: mode data length
            // Byte 2: medium type
            // Byte 3: device-specific parameter (bit 7 = write protect)
            // Bytes 4-5: reserved
            // Bytes 6-7: block descriptor length
            var resp: [8]u8 = .{ 0, 6, 0, 0x00, 0, 0, 0, 0 }; // 0x00 = writable
            self.queue_in(resp[0..resp.len]);
        }

        fn prepare_request_sense(self: *Self) void {
            var resp: [18]u8 = [_]u8{0} ** 18;
            resp[0] = 0x70; // Response code: current error
            resp[2] = self.sense.key;
            resp[7] = 10; // Additional sense length
            resp[12] = self.sense.asc;
            resp[13] = self.sense.ascq;
            self.queue_in(resp[0..resp.len]);
            // Clear sense after reporting it otherwise Windows sees the same error on every "REQUEST_SENSE"
            self.sense = .{ .key = 0, .asc = 0, .ascq = 0 };
        }

        fn start_read10(self: *Self) void {
            self.current_lba = read_be_u32(self.cbw_cmd[2..6]);
            self.remaining_blocks = read_be_u16(self.cbw_cmd[7..9]);
            const total = storage.totalSectors();

            // Validate LBA range (allow 0-block reads, and allow LBA at boundary if 0 blocks)
            if (self.current_lba > total or (self.remaining_blocks > 0 and self.current_lba + self.remaining_blocks > total)) {
                self.set_sense(0x05, 0x21, 0x00); // ILLEGAL_REQUEST: LBA out of range
                self.send_csw(1);
                return;
            }

            // Handle 0-block reads as successful no-op
            if (self.remaining_blocks == 0) {
                self.data_residue = 0;
                self.send_csw(0);
                return;
            }

            self.block_offset = 0;
            self.load_block();
            self.state = .data_in;
            self.send_block_chunk();
        }

        fn start_write10(self: *Self) void {
            self.current_lba = read_be_u32(self.cbw_cmd[2..6]);
            self.remaining_blocks = read_be_u16(self.cbw_cmd[7..9]);
            const total = storage.totalSectors();

            // Validate LBA range (allow 0-block writes, and allow LBA at boundary if 0 blocks)
            if (self.current_lba > total or (self.remaining_blocks > 0 and self.current_lba + self.remaining_blocks > total)) {
                self.set_sense(0x05, 0x21, 0x00); // ILLEGAL_REQUEST: LBA out of range
                self.send_csw(1);
                return;
            }

            // Handle 0-block writes as successful no-op
            if (self.remaining_blocks == 0) {
                self.data_residue = 0;
                self.send_csw(0);
                return;
            }

            // Prepare to receive data
            self.block_offset = 0;
            // Clear block buffer to ensure no stale data, windows can detect corruption if buffer has old data
            @memset(&self.block_buf, 0);
            self.state = .data_out;
        }

        fn queue_in(self: *Self, data: []const u8) void {
            self.in_len = @min(data.len, self.in_buf.len);
            @memcpy(self.in_buf[0..self.in_len], data[0..self.in_len]);
            self.in_offset = 0;
            self.state = .data_in;
            self.send_next_in_chunk();
        }

        fn send_next_in_chunk(self: *Self) void {
            if (self.in_offset < self.in_len) {
                const chunk = @min(self.in_len - self.in_offset, max_packet_size);
                self.device.?.endpoint_transfer(self.ep_in, self.in_buf[self.in_offset .. self.in_offset + chunk]);
                self.in_offset += chunk;
                if (self.data_residue >= chunk) {
                    self.data_residue -= @intCast(chunk);
                } else {
                    self.data_residue = 0;
                }
                return;
            }

            if (self.remaining_blocks > 0) {
                self.send_block_chunk();
                return;
            }

            self.send_csw(0);
        }

        fn load_block(self: *Self) void {
            // Pass a slice, not an array pointer
            storage.readSector(self.current_lba, self.block_buf[0..]);
            self.current_lba += 1;
            self.block_offset = 0;
        }

        fn send_block_chunk(self: *Self) void {
            if (self.block_offset >= self.block_buf.len) {
                self.remaining_blocks -= 1;
                if (self.remaining_blocks == 0) {
                    self.send_csw(0);
                    return;
                }
                self.load_block();
            }
            const chunk = @min(self.block_buf.len - self.block_offset, max_packet_size);
            self.device.?.endpoint_transfer(self.ep_in, self.block_buf[self.block_offset .. self.block_offset + chunk]);
            self.block_offset += chunk;
            if (self.data_residue >= chunk) {
                self.data_residue -= @intCast(chunk);
            } else {
                self.data_residue = 0;
            }
        }

        fn send_csw(self: *Self, status: u8) void {
            self.writeCsw(status);
            self.state = .send_csw;
            self.device.?.endpoint_transfer(self.ep_in, &self.csw_buf);
        }

        fn set_sense(self: *Self, key: u8, asc: u8, ascq: u8) void {
            self.sense = .{ .key = key, .asc = asc, .ascq = ascq };
        }

        fn resetState(self: *Self) void {
            self.state = .await_cbw;
            self.cbw_len = 0;
            self.remaining_blocks = 0;
            self.block_offset = 0;
            self.in_len = 0;
            self.in_offset = 0;
            self.need_arm_out = false;
        }

        fn prepare_out(self: *Self) void {
            if (self.device != null) {
                // The endpoint max packet size is 64 bytes for bulk transfers
                const buf_size = @min(max_packet_size, self.out_buf.len);
                self.device.?.endpoint_transfer(self.ep_out, self.out_buf[0..buf_size]);
            }
        }

        fn read_be_u16(buf: []const u8) u16 {
            return (@as(u16, buf[0]) << 8) | buf[1];
        }

        fn read_be_u32(buf: []const u8) u32 {
            return (@as(u32, buf[0]) << 24) | (@as(u32, buf[1]) << 16) | (@as(u32, buf[2]) << 8) | buf[3];
        }

        fn write_be_u32(buf: []u8, value: u32) void {
            buf[0] = @truncate(value >> 24);
            buf[1] = @truncate(value >> 16);
            buf[2] = @truncate(value >> 8);
            buf[3] = @truncate(value);
        }

        fn write_be_u64(buf: []u8, value: u64) void {
            buf[0] = @truncate(value >> 56);
            buf[1] = @truncate(value >> 48);
            buf[2] = @truncate(value >> 40);
            buf[3] = @truncate(value >> 32);
            buf[4] = @truncate(value >> 24);
            buf[5] = @truncate(value >> 16);
            buf[6] = @truncate(value >> 8);
            buf[7] = @truncate(value);
        }

        fn resetCsw(self: *Self, status: u8) void {
            write_u32_le(self.csw_buf[0..4], CSW_SIGNATURE);
            write_u32_le(self.csw_buf[4..8], self.cbw_tag);
            write_u32_le(self.csw_buf[8..12], self.data_residue);
            self.csw_buf[12] = status;
        }

        fn writeCsw(self: *Self, status: u8) void {
            self.resetCsw(status);
        }

        pub fn driver(self: *Self) types.UsbClassDriver {
            return .{
                .ptr = self,
                .fn_init = init,
                .fn_open = open,
                .fn_class_control = class_control,
                .fn_transfer = transfer,
            };
        }

        /// Must be called from USB poll loop to handle deferred OUT endpoint arming
        /// This ensures endpoint_transfer() is not called from within a transfer callback
        pub fn poll(self: *Self) void {
            if (self.need_arm_out) {
                self.need_arm_out = false;
                self.prepare_out();
            }
        }
    };
}

const max_packet_size: usize = 64;

fn descLen(cfg: []const u8) u8 {
    return cfg[0];
}

fn descType(cfg: []const u8) u8 {
    return cfg[1];
}

fn getDescNext(cfg: []const u8) []const u8 {
    return cfg[descLen(cfg)..];
}

fn tryGetDescAs(comptime T: type, cfg: []const u8) ?*const T {
    if (cfg.len == 0) return null;
    const exp = @field(T, "const_descriptor_type");
    if (cfg[1] != @intFromEnum(exp)) return null;
    return @ptrCast(@constCast(cfg.ptr));
}

fn read_u32_le(buf: []const u8, offset: usize) u32 {
    return @as(u32, buf[offset]) |
        (@as(u32, buf[offset + 1]) << 8) |
        (@as(u32, buf[offset + 2]) << 16) |
        (@as(u32, buf[offset + 3]) << 24);
}

fn write_u32_le(buf: []u8, value: u32) void {
    buf[0] = @truncate(value);
    buf[1] = @truncate(value >> 8);
    buf[2] = @truncate(value >> 16);
    buf[3] = @truncate(value >> 24);
}
