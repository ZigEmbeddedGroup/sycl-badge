/// Fork of MicroZig's RTT library which adds a few features needed for tracy
const std = @import("std");
const microzig = @import("microzig");
const timer = @import("timer.zig");

fn memory_barrier() void {
    microzig.cpu.dmb();
    asm volatile ("" ::: .{ .memory = true });
}

/// Header that indicates to the connected probe how many up/down channels are in use.
///
/// The RTT header is found based on the string "SEGGER RTT", so we need to avoid storing
/// the whole string in memory anywhere other than this header (otherwise host software
/// may choose the wrong location). Storing it reversed in the variable "init_str" and then
/// copying it over accomplishes this.
pub const Header = extern struct {
    id: [16]u8,
    max_up_channels: usize,
    max_down_channels: usize,

    pub fn init(self: *Header, comptime max_up_channels: usize, comptime max_down_channels: usize) void {
        self.max_up_channels = max_up_channels;
        self.max_down_channels = max_down_channels;

        const init_str = "\x00\x00\x00\x00\x00\x00TTR REGGES";

        std.mem.doNotOptimizeAway(self);

        // Ensure no memory reordering can occur and all accesses are finished before
        // marking block "valid" and writing header string. This prevents the JLINK
        // from finding a "valid" block while offets/pointers aren't yet valid.
        memory_barrier();
        for (0..init_str.len) |i| {
            self.id[i] = init_str[init_str.len - i - 1];
        }
        memory_barrier();
    }
};

pub const channel = struct {
    pub const Mode = enum(usize) {
        NoBlockSkip = 0,
        NoBlockTrim = 1,
        BlockIfFull = 2,
        _,
    };

    /// Configuration for an up or down channel per the RTT spec
    pub const Config = struct {
        name: [*:0]const u8,
        buffer_size: usize,
        mode: Mode,
    };

    /// Represents a target -> host communication channel.
    ///
    /// Implements a ring buffer of size - 1 bytes, as this implementation
    /// does not fill up the buffer in order to avoid the problem of being unable to
    /// distinguish between full and empty.
    pub const Up = extern struct {
        /// Name is optional and is not required by the spec. Standard names so far are:
        /// "Terminal", "SysView", "J-Scope_t4i4"
        name: [*:0]const u8,

        buffer: [*]u8,

        /// Note from above actual buffer size is size - 1 bytes
        size: usize,

        write_offset: usize,
        raw_read_offset: usize,

        /// Contains configuration flags. Flags[31:24] are used for validity check and must be zero.
        /// Flags[23:2] are reserved for future use. Flags[1:0] = RTT operating mode.
        flags: usize,

        const Self = @This();

        fn init(
            self: *Self,
            name: [*:0]const u8,
            buffer: []u8,
            mode_: Mode,
        ) void {
            self.name = name;
            self.size = buffer.len;
            self.set_mode(mode_);
            self.write_offset = 0;
            self.raw_read_offset = 0;

            std.mem.doNotOptimizeAway(self);
            std.mem.doNotOptimizeAway(buffer);

            // Ensure buffer pointer is set last and can't be reordered
            memory_barrier();
            self.buffer = buffer.ptr;
        }

        pub fn mode(self: *Self) Mode {
            return std.meta.intToEnum(Mode, self.flags & 3) catch unreachable;
        }

        pub fn set_mode(self: *Self, mode_: Mode) void {
            self.flags = (self.flags & ~@as(usize, 3)) | @intFromEnum(mode_);
        }

        pub fn load_read_offset(self: *Self) usize {
            return @as(*volatile usize, &self.raw_read_offset).*;
        }

        /// Writes up to available space left in buffer for reading by probe, returning number of bytes
        /// written.
        pub fn write_available(self: *Self, bytes: []const u8) usize {
            var c = self.cursor();
            const written = c.write_available(bytes);
            if (written != 0) {
                c.commit();
            }
            return written;
        }

        pub fn write_assume_available(self: *Self, bytes: []const u8) void {
            var c = self.cursor();
            c.write_assume_available(bytes);
            c.commit();
        }

        /// Blocks until all bytes are written to buffer
        pub fn write_blocking(self: *Self, bytes: []const u8) usize {
            const count = bytes.len;
            var written: usize = 0;
            while (written != count) {
                written += self.write_available(bytes[written..]);
            }
            return count;
        }

        pub fn write_blocking_with_deadline(self: *Self, bytes: []const u8, deadline: u64) !void {
            const count = bytes.len;
            var written: usize = 0;
            while (written != count) {
                const this_write = self.write_available(bytes[written..]);
                written += this_write;
                if (this_write == 0 and timer.micros() > deadline) {
                    return error.Timeout;
                }
            }
        }

        pub fn write_if_available(self: *Self, buf: []const u8) bool {
            if (self.available_space() >= buf.len) {
                self.write_assume_available(buf);
                return true;
            }
            return false;
        }

        /// Behavior depends on up channel's mode, attempts to write all
        /// bytes to the RTT control block, and returns how many it successfully wrote.
        /// Writing less than requested number of bytes is not an error.
        pub fn write(self: *Self, bytes: []const u8) usize {
            return switch (self.mode()) {
                .NoBlockSkip => if (self.write_if_available(bytes)) bytes.len else 0,
                .NoBlockTrim => self.write_available(bytes),
                .BlockIfFull => self.write_blocking(bytes),
                _ => unreachable,
            };
        }

        /// Available space in the ring buffer for writing, including wrap-around
        pub fn available_space(self: *Self) usize {
            // The probe can change self.read_offset via memory modification at any time,
            // so must perform a volatile read on this value.
            const read_offset = self.load_read_offset();

            if (read_offset <= self.write_offset) {
                return self.size - 1 - (self.write_offset - read_offset);
            } else {
                return read_offset - self.write_offset - 1;
            }
        }

        /// A cursor is used to transactionally put data into the buffer, in case an
        /// operation may fail. The writes are not made available to the reader
        /// until commit() is called. If commit() is never called, the data
        /// will never be made available. Only one cursor can be used at a time, and the
        /// channel must not be written at all while a cursor is active.
        pub fn cursor(self: *Self) Cursor {
            return .init(self);
        }

        pub const Cursor = struct {
            chan: *Up,
            write_pos: usize,

            pub fn init(chan: *Up) Cursor {
                const offset = chan.write_offset;
                return .{
                    .chan = chan,
                    .write_pos = offset,
                };
            }

            pub fn write_byte_assume_available(c: *Cursor, byte: u8) void {
                c.chan.buffer[c.write_pos] = byte;
                c.write_pos += 1;
                if (c.write_pos == c.chan.size) c.write_pos = 0;
            }

            pub fn write_assume_available(c: *Cursor, bytes: []const u8) void {
                var write_offset = c.write_pos;
                const first_write = @min(c.chan.size - write_offset, bytes.len);
                @memcpy(c.chan.buffer[write_offset .. write_offset + first_write], bytes[0..first_write]);
                write_offset += first_write;
                if (first_write < bytes.len) {
                    @memcpy(c.chan.buffer[0 .. bytes.len - first_write], bytes[first_write..]);
                    write_offset = bytes.len - first_write;
                }
                if (write_offset >= c.chan.size) write_offset = 0;
                c.write_pos = write_offset;
            }

            pub fn get_available(c: *const Cursor) usize {
                const read_offset = c.chan.load_read_offset();

                if (read_offset <= c.write_pos) {
                    return c.chan.size + read_offset - c.write_pos - 1;
                } else {
                    return read_offset - c.write_pos - 1;
                }
            }

            pub fn write_available(c: *Cursor, bytes: []const u8) usize {
                const available = c.get_available();
                if (available == 0) return 0;

                const to_write = @min(bytes.len, available);
                c.write_assume_available(bytes[0..to_write]);

                return to_write;
            }

            pub fn write_if_available(c: *Cursor, buf: []const u8) bool {
                if (c.available_space() >= buf.len) {
                    c.write_assume_available(buf);
                    return true;
                }
                return false;
            }

            pub fn uncommitted_len(c: *const Cursor) usize {
                const commit_pos = c.chan.write_offset;
                return if (commit_pos < c.write_pos) c.write_pos - commit_pos
                    else c.chan.size + c.write_pos - commit_pos;
            }

            pub fn commit(c: *const Cursor) void {
                std.debug.assert(c.get_available() >= c.uncommitted_len());
                std.mem.doNotOptimizeAway(c.chan);
                std.mem.doNotOptimizeAway(c.chan.buffer);
                memory_barrier();
                @atomicStore(usize, &c.chan.write_offset, c.write_pos, .seq_cst);
            }
        };

        /// Implements the std.Io.Writer interface
        pub const Writer = struct {
            up_channel: *Self,
            interface: std.Io.Writer,

            fn init(uc: *Self, buf: []u8) Writer {
                return .{
                    .up_channel = uc,
                    .interface = .{
                        .vtable = &.{
                            .drain = drain,
                        },
                        .buffer = buf,
                        .end = 0,
                    },
                };
            }

            /// Implements drain for the Io.Writer interface. Note that this will drop data if it can't all fit
            /// in the RTT Up channel buffer. This is to prevent constantly returning a WriteError when a debug
            /// probe isn't connected.
            ///
            /// TODO: build.zig option that allows users to opt-in to returning WriteError on full RTT buffer?
            fn drain(io_w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
                const up: *Self = @as(*Writer, @alignCast(@fieldParentPtr("interface", io_w))).up_channel;

                const buffered = io_w.buffered();
                if (buffered.len > 0) {
                    _ = up.write_if_available(buffered);
                    _ = io_w.consumeAll();
                }
                var n: usize = 0;
                for (data[0 .. data.len - 1]) |d| {
                    _ = up.write_if_available(d);
                    n += d.len;
                }
                for (0..splat) |_| {
                    const to_splat = data[data.len - 1];
                    _ = up.write_if_available(to_splat);
                    n += to_splat.len;
                }
                return n;
            }
        };

        pub fn writer(uc: *Self, buf: []u8) Writer {
            return Writer.init(uc, buf);
        }
    };

    /// Represents a host -> target communication channel.
    ///
    /// Implements a ring buffer of size - 1 bytes, as this implementation
    /// does not fill up the buffer in order to avoid the problem of being unable to
    /// distinguish between full and empty.
    pub const Down = extern struct {
        /// Name is optional and is not required by the spec. Standard names so far are:
        /// "Terminal", "SysView", "J-Scope_t4i4"
        name: [*:0]const u8,

        buffer: [*]u8,

        /// Note from above actual buffer size is size - 1 bytes
        size: usize,

        write_offset: usize,
        read_offset: usize,

        /// Contains configuration flags. Flags[31:24] are used for validity check and must be zero.
        /// Flags[23:2] are reserved for future use. Flags[1:0] = RTT operating mode.
        flags: usize,

        const Self = @This();

        pub fn init(
            self: *Self,
            name: [*:0]const u8,
            buffer: []u8,
            mode_: Mode,
        ) void {
            self.name = name;
            self.size = buffer.len;
            self.set_mode(mode_);
            self.write_offset = 0;
            self.read_offset = 0;

            std.mem.doNotOptimizeAway(self);
            std.mem.doNotOptimizeAway(buffer);

            // Ensure buffer pointer is set last and can't be reordered
            memory_barrier();
            self.buffer = buffer.ptr;
        }

        pub fn mode(self: *Self) Mode {
            return std.meta.intToEnum(Mode, self.mode & 3);
        }

        pub fn set_mode(self: *Self, mode_: Mode) void {
            self.flags = (self.flags & ~@as(usize, 3)) | @intFromEnum(mode_);
        }

        /// Reads up to a number of bytes from probe non-blocking. Reading less than the requested number of bytes
        /// is not an error.
        ///
        /// TODO: Does the channel's mode actually matter here?
        pub fn read_available(self: *Self, bytes: []u8) usize {
            // The probe can change self.write_offset via memory modification at any time,
            // so must perform a volatile read on this value.
            const write_offset = @as(*volatile usize, @ptrCast(&self.write_offset)).*;
            var read_offset = self.read_offset;

            var bytes_read: usize = 0;
            // Read from current read position to wrap-around of buffer, first
            if (read_offset > write_offset) {
                const count = @min(self.size - read_offset, bytes.len);
                @memcpy(bytes[0..count], self.buffer[read_offset .. read_offset + count]);
                bytes_read += count;
                read_offset += count;

                // Handle wrap-around
                if (read_offset >= self.size) read_offset = 0;
            }

            // We've now either wrapped around or were wrapped around to begin with
            if (read_offset < write_offset) {
                const remaining_bytes = @min(write_offset - read_offset, bytes[bytes_read..].len);
                // Read remaining items of buffer
                if (remaining_bytes > 0) {
                    @memcpy(bytes[bytes_read .. bytes_read + remaining_bytes], self.buffer[read_offset .. read_offset + remaining_bytes]);
                    bytes_read += remaining_bytes;
                    read_offset += remaining_bytes;
                }
            }

            // Force data write to be complete before writing the read_offset, in case CPU
            // is allowed to change the order of memory accesses
            memory_barrier();
            self.read_offset = read_offset;

            return bytes_read;
        }

        /// Number of bytes from probe available in ring buffer.
        pub fn bytes_available(self: *Self) usize {

            // The probe can change self.write_offset via memory modification at any time,
            // so must perform a volatile read on this value.
            const write_offset = @as(*volatile usize, @ptrCast(&self.write_offset)).*;
            if (self.read_offset > write_offset) {
                return self.size - self.read_offset + write_offset;
            } else {
                return write_offset - self.read_offset;
            }
        }

        pub fn read_if_available(self: *Self, buf: []u8) bool {
            // TODO OPT: we can do fewer volatile reads here by merging these functions,
            // but for now this is fast enough.
            if (self.bytes_available() >= buf.len) {
                const bytes_read = self.read_available(buf);
                std.debug.assert(bytes_read == buf.len);
                return true;
            }
            return false;
        }

        /// Implements the std.Io.Reader interface
        pub const Reader = struct {
            down_channel: *Self,
            interface: std.Io.Reader,

            fn init(dc: *Self, buf: []u8) Reader {
                return .{
                    .down_channel = dc,
                    .interface = .{
                        .vtable = &.{
                            .stream = stream,

                            // Default discarding behavior is acceptable, and will still work even with a zero
                            // length buffer
                            .discard = std.Io.Reader.defaultDiscard,

                            // The default behavior prioritizes reading entire internal buffers worth of data rather
                            // than directly calling RTT reads individually, which is exactly what is desired
                            .readVec = std.Io.Reader.defaultReadVec,

                            // The default rebase behavior of moving data back to the start of the internal buffer
                            // is acceptable
                            .rebase = std.Io.Reader.defaultRebase,
                        },
                        .buffer = buf,
                        .end = 0,
                        .seek = 0,
                    },
                };
            }

            /// Fetches new data directly from the RTT ring buffer
            fn stream(io_r: *std.Io.Reader, io_w: *std.Io.Writer, limit: std.Io.Limit) std.Io.Reader.StreamError!usize {
                const down: *Self = @as(*Reader, @alignCast(@fieldParentPtr("interface", io_r))).down_channel;
                const dest = limit.slice(try io_w.writableSliceGreedy(1));
                if (down.bytes_available() == 0) return error.EndOfStream;
                const n = down.read_available(dest);
                io_w.advance(n);
                return n;
            }
        };

        pub fn reader(self: *Self, buffer: []u8) Reader {
            return Reader.init(self, buffer);
        }
    };
};

/// Constructs a struct type where each field is a u8 array of size specified by channel config.
///
/// Fields follow the naming convention "up_buffer_N" for up channels, and "down_buffer_N" for down channels.
fn BuildBufferStorageType(comptime up_channels: []const channel.Config, comptime down_channels: []const channel.Config) type {
    const fields: []const std.builtin.Type.StructField = comptime v: {
        var fields_temp: [up_channels.len + down_channels.len]std.builtin.Type.StructField = undefined;
        for (up_channels, 0..) |up_cfg, idx| {
            const buffer_type = [up_cfg.buffer_size]u8;
            fields_temp[idx] = .{
                .name = std.fmt.comptimePrint("up_buffer_{d}", .{idx}),
                .type = buffer_type,
                .is_comptime = false,
                .alignment = @alignOf(buffer_type),
                .default_value_ptr = null,
            };
        }
        for (down_channels, 0..) |down_cfg, idx| {
            const buffer_type = [down_cfg.buffer_size]u8;
            fields_temp[up_channels.len + idx] = .{
                .name = std.fmt.comptimePrint("down_buffer_{d}", .{idx}),
                .type = buffer_type,
                .is_comptime = false,
                .alignment = @alignOf(buffer_type),
                .default_value_ptr = null,
            };
        }
        break :v &fields_temp;
    };

    return @Type(.{
        .@"struct" = .{
            .layout = .@"extern",
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
}

/// Creates a control block struct for the given channel configs. Buffer storage is also contained within this struct, although
/// per the RTT spec it doesn't have to be.
fn ControlBlock(comptime up_channels: []const channel.Config, comptime down_channels: []const channel.Config) type {
    if (up_channels.len == 0 or down_channels.len == 0) {
        @compileError("Must have at least 1 up and down channel configured");
    }

    const BufferContainerType = BuildBufferStorageType(up_channels, down_channels);
    return extern struct {
        header: Header,
        up_channels: [up_channels.len]channel.Up,
        down_channels: [down_channels.len]channel.Down,
        buffers: BufferContainerType,

        pub fn init(self: *@This()) void {
            comptime var i: usize = 0;

            std.mem.doNotOptimizeAway(self);

            inline while (i < up_channels.len) : (i += 1) {
                self.up_channels[i].init(
                    up_channels[i].name,
                    &@field(self.buffers, std.fmt.comptimePrint("up_buffer_{d}", .{i})),
                    up_channels[i].mode,
                );
            }
            i = 0;
            inline while (i < down_channels.len) : (i += 1) {
                self.down_channels[i].init(
                    down_channels[i].name,
                    &@field(self.buffers, std.fmt.comptimePrint("down_buffer_{d}", .{i})),
                    down_channels[i].mode,
                );
            }
            // Prevent compiler from re-ordering header init function as it must come last
            memory_barrier();
            self.header.init(up_channels.len, down_channels.len);
        }
    };
}

/// Compile time configuration of RTT instance
pub const Config = struct {
    up_channels: []const channel.Config = &[_]channel.Config{.{ .name = "Terminal", .buffer_size = 1024, .mode = .NoBlockSkip }},
    down_channels: []const channel.Config = &[_]channel.Config{.{ .name = "Terminal", .buffer_size = 16, .mode = .BlockIfFull }},
    /// Optionally place the RTT control block (and buffers) in a specific linker section
    linker_section: ?[]const u8 = null,
};

/// Creates an RTT namespace given the compile time configuration with functions for writing/reading from RTT channels.
pub fn RTT(comptime config: Config) type {
    return struct {
        const mb_fn = config.memory_barrier_fn orelse memory_barrier.empty_memory_barrier;
        var control_block: ControlBlock(
            config.up_channels,
            config.down_channels,
        ) = undefined;

        comptime {
            @export(&control_block, .{
                .name = "RttControlBlock",
                .section = config.linker_section,
            });
        }

        /// Initialize RTT, must be called prior to calling any other API functions
        pub fn init() void {
            control_block.init();
        }

        pub fn up_channel(channel_number: usize) *channel.Up {
            return &control_block.up_channels[channel_number];
        }

        pub fn down_channel(channel_number: usize) *channel.Down {
            return &control_block.down_channels[channel_number];
        }
    };
}
