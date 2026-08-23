/// Terry is a reimplementation of the Tracy 0.14.0 client designed for a
/// low-memory threadless microcontroller environment with RTT output.

const terry = @import("terry.zig");
const q = @import("terry_protocol.zig");

const timer = @import("../drivers/timer.zig");
const rev = @import("../drivers/rev.zig");
const rtt = @import("../drivers/rtt.zig");
const mzrtt = @import("../drivers/microzig_rtt.zig");

const std = @import("std");
const builtin = @import("builtin");
const microzig = @import("microzig");

pub const log = rtt.log_core0;
pub const logf = rtt.logf_core0;

pub const send = rtt.tracy_send;
const recv = rtt.tracy_recv;

// TODO OS sampling
/// Frequency with which OS samples are collected, in uS.
const os_sampling_period: i64 = 0;

// TODO on demand is not implemented yet
const support_on_demand = false;

const State = enum {
    uninitialized,
    wait_for_server,
    handshake,
    send_welcome_msg,
    send_on_demand_payload,
    new_connection,
    
    connected,
    buffer_full,

    timeout,
    terminating,
    bad_protocol_version,
    unrecoverable_error,
    terminal,
};

var tmp_packet: [q.MaxPacketSize]u8 = undefined;
var tmp_packet_data: []const u8 = undefined;
fn tmp_packet_as(comptime PacketType: type) *align(1) PacketType {
    return @ptrCast(&tmp_packet);
}

const PendingPacket = enum {
    no_packet,
    server_query,
    external_name_pt1,
    timeout,
    terminal,
};

var pending_packet_type: PendingPacket = .no_packet;

var state: State = .uninitialized;
var startup_time: i64 = 0;
var last_keep_alive_us: u64 = 0;

// 1 second timeout is probably too large, but for now we want to
// give the server/host the benefit of the doubt.
pub const server_timeout_us = 1_000_000;

// TIDs in Terry are pointers to the static string that names them.
// So the core0 id here is the address of the descriptive name to
// be used in the Tracy view.
const core0_thread_id_ptr = terry.external_string("Core 0 (OS)");
pub fn core0_thread_id() u32 { return @intFromPtr(core0_thread_id_ptr); }

pub var core0_thread_ref_time: i64 = 0;
pub var has_core0_thread_context: bool = false;

pub var interrupt_trace_enabled: bool = false;
var disconnect_requested: bool = false;

var atomic_connection_id: u16 = 0;
var atomic_is_connected: bool = false;

pub var param_callback_obj: ?*anyopaque = null;
pub var param_callback_fn: ?*const fn(?*anyopaque, u32, i32) void = null;

var last_up_read: usize = 0;
var last_up_write: usize = 0;

const Cursor = mzrtt.channel.Up.Cursor;

pub const WireLayout = struct {
    total_bytes: usize,
    header_bytes: usize,
    lz4_bytes: usize,
    data_bytes: usize,
};

fn header_size(literal_bytes: usize) usize {
    // Fast case for small lengths, which is most of them
    if (literal_bytes < 15+255) {
        return 1 + @as(usize, @intFromBool(literal_bytes >= 15));
    }
    // 4 bytes compressed len, 1 byte token, ceil(max(0, data_bytes - 15) / 255) bytes len
    return 1 + (literal_bytes + (255 - 15)) / 255;
}

fn match_copy_len_bytes(copy_len: usize) usize {
    // Fast case for small lengths, which is most of them
    if (copy_len < 19+255) {
        return @intFromBool(copy_len >= 19);
    }
    return (copy_len + (255 - 19)) / 255;
}

pub inline fn wire_layout(data_bytes: usize) WireLayout {
    const lz4_header_bytes = header_size(data_bytes);
    return .{
        .total_bytes = 4 + lz4_header_bytes + data_bytes,
        .header_bytes = 4 + lz4_header_bytes,
        .lz4_bytes = lz4_header_bytes + data_bytes,
        .data_bytes = data_bytes,
    };
}

pub inline fn write_header_assume_available(w: WireLayout) Cursor {
    var cursor = send.cursor();
    // 32 bit length
    var len_32: u32 = @intCast(w.lz4_bytes);
    cursor.write_assume_available(std.mem.asBytes(&len_32));
    // encoded LZ4 length
    cursor.write_byte_assume_available(@as(u8, @min(w.data_bytes, 15)) << 4);
    if (w.data_bytes >= 15) {
        var rem = w.data_bytes - 15;
        while (true) {
            cursor.write_byte_assume_available(@intCast(@min(rem, 255)));
            if (rem < 255) break;
            rem -= 255;
        }
    }

    return cursor;
}

pub fn data_total_len(data: []const []const u8) usize {
    var data_bytes: usize = 0;
    for (data) |sub| {
        data_bytes += sub.len;
    }
    return data_bytes;
}

const core0_max_zones = 64;
var core0_zones: [core0_max_zones]*const q.SourceLocationData = undefined;
pub var core0_num_zones: u32 = 0;

pub const TrackedSMEntry = struct {
    name: [*:0]const u8,
    srcloc: *const q.SourceLocationData,
    next: ?*TrackedSMEntry = null,
};

var core0_tracked_states: ?*TrackedSMEntry = null;
var core0_num_tracked_states: u32 = 0;

var core0_pending_states: ?*TrackedSMEntry = null;
var core0_num_pending_states: u32 = 0;

pub fn add_tracked_state(entry: *TrackedSMEntry) void {
    entry.next = core0_tracked_states;
    core0_tracked_states = entry;
    core0_num_tracked_states += 1;
}

pub fn add_pending_state(entry: *TrackedSMEntry) void {
    entry.next = core0_pending_states;
    core0_pending_states = entry;
    core0_num_pending_states += 1;
}

pub fn push_zone(srcloc: *const q.SourceLocationData) void {
    if (core0_num_zones < core0_max_zones) {
        core0_zones[core0_num_zones] = srcloc;
    }
    core0_num_zones += 1;
}

pub fn pop_zone() void {
    core0_num_zones -= 1;
}

/// To emit a bulk end operation, we need an encoded sequence of:
/// [1 byte ThreadContext + 4 byte threadID] ++ [ 1 byte ZoneEnd64 tag, 8 bytes timestamp] ++ [1 byte ZoneEnd16, 0x00_00] ** N-1 ++ [1 byte ZoneBegin16, 0x00_00, 4 bytes data missing srcloc, 4 bytes zero]
/// We can take advantage of the LZ4 match-copy for that last repeating chunk, but doing so is a bit tricky because
/// of historical restrictions on the LZ4 format:
///  - The last literal must be at least 5 bytes (satisfied by our uncompressible ZoneBegin trailer)
///  - The last match copy must start at least 12 bytes before the end (satisfied by our ZoneBegin trailer)
/// And of course the real restriction that match copies must copy at least 4 bytes, which means we need at least two 3-byte ZoneEnd16
/// zones before we can start a match copy
/// For 0 zones: 2 byte header + 5+17 uncompressable = 24 bytes
/// For 1-3 zones: 2 byte header + 14 + 3*(N-1) + 11 bytes uncompressable (LZ4 requires at least 5 bytes in the last literal)
/// 1: 27, 2: 30, 3: 33
/// We can encode a match copy in the header up to a length of 18, which means we max out at N=2+18/3=8
/// For 4-8  zones: 2 byte header + 14 + 3 bytes + 2 byte offset + 1 byte final header + 11 bytes final literal
/// 4-8: 33 bytes
/// If we add one byte of matchlen, we can support matchlen up to 254+15+4, for N=2+273/3=93
/// For 9-93 zones: 2 byte header + 14 + 3 bytes + 2 byte offset + 1 byte matchlen + 1 byte final header + 11 bytes final literal
/// 9-93: 34 bytes
/// From there every extra byte adds 85 more depth, extending the match copy by up to 255 more bytes.
fn compute_zone_bulk_end_max_len(num_zones: u32) usize {
    // Tracy has a hard limit for how much data can be decompressed at once. This limit is like 70k zones, but here's an assert just in case.
    const max_zones = (q.TargetFrameSize - @sizeOf(q.Packet(q.ThreadContext)) - @sizeOf(q.Packet(q.ZoneEnd)) - @sizeOf(q.Packet(q.ZoneBegin16))) / @sizeOf(q.Packet(q.ZoneEnd16)) + 1;
    std.debug.assert(num_zones <= max_zones);

    var starter_literal_size: usize = 0;

    starter_literal_size += @sizeOf(q.Packet(q.ThreadContext));

    // Special case: With zero zones, we just open a zone for "Data Lost", which is variable sized based on dt.
    if (num_zones == 0) {
        starter_literal_size += @sizeOf(q.ZoneBeginData);
        return wire_layout(starter_literal_size).total_bytes;
    }

    starter_literal_size += @sizeOf(q.ZoneEndData);

    // With less than 4 zones, we can't meaningfully compress the data. The whole thing is a literal.
    if (num_zones < 4) {
        starter_literal_size += (num_zones - 1) * @sizeOf(q.Packet(q.ZoneEnd16)) + @sizeOf(q.Packet(q.ZoneBegin16));
        return wire_layout(starter_literal_size).total_bytes;
    }

    // With more than 4 zones, we add one empty packet and then a huge match copy for it.
    starter_literal_size += @sizeOf(q.Packet(q.ZoneEnd16));

    const bytes_to_copy = @sizeOf(q.Packet(q.ZoneEnd16)) * (num_zones - 2);
    const ext_copy_bytes = match_copy_len_bytes(bytes_to_copy);

    const starter_header_size = header_size(starter_literal_size);
    const total_lz4_size: u32 = starter_header_size + starter_literal_size + 2 + ext_copy_bytes + 1 + @sizeOf(q.Packet(q.ZoneBegin16));

    return @sizeOf(u32) + total_lz4_size;
}

fn core0_emit_zone_bulk_end(time: i64) void {
    const warning_zone = terry.external_source_location("Data Lost, Too Many Zones!", @src(), 0xcc1100);

    const num_zones = core0_num_zones;

    logf("TERRY: BULK END for {d} zones\n", .{num_zones});

    var starter_literal_size: usize = 0;

    const emit_thread_context = !has_core0_thread_context;
    var thread_ctx: q.Packet(q.ThreadContext) = undefined;
    const dt = if (emit_thread_context) blk: {
        starter_literal_size += @sizeOf(@TypeOf(thread_ctx));
        thread_ctx = .{ .ty = .ThreadContext, .data = .{ .thread = core0_thread_id() } };
        has_core0_thread_context = true;
        break :blk time;
    } else time - core0_thread_ref_time;
    core0_thread_ref_time = time;

    // Special case: With zero zones, we just open a zone for "Data Lost", which is variable sized based on dt.
    if (num_zones == 0) {
        var first_begin: q.ZoneBeginData = undefined;
        const begin_bytes = first_begin.set(dt, warning_zone);
        starter_literal_size += begin_bytes.len;

        const layout = wire_layout(starter_literal_size);
        var cursor = write_header_assume_available(layout);
        if (emit_thread_context) {
            cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
        }
        cursor.write_assume_available(begin_bytes);
        cursor.commit();

        return;
    }

    var first_end: q.ZoneEndData = undefined;
    const first_end_bytes = first_end.set(dt);
    starter_literal_size += first_end_bytes.len;

    const repeat_end = q.packet(.ZoneEnd16, .{ .time = 0 });
    const begin_error = q.packet(.ZoneBegin16, .{ .time = 0, .srcloc = @intFromPtr(warning_zone) });


    // With less than 4 zones, we can't meaningfully compress the data. The whole thing is a literal.
    if (num_zones < 4) {
        starter_literal_size += (num_zones - 1) * @sizeOf(@TypeOf(repeat_end)) + @sizeOf(@TypeOf(begin_error));

        const layout = wire_layout(starter_literal_size);
        var cursor = write_header_assume_available(layout);
        if (emit_thread_context) {
            cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
        }
        cursor.write_assume_available(first_end_bytes);
        for (1..num_zones) |_| {
            cursor.write_assume_available(std.mem.asBytes(&repeat_end));
        }
        cursor.write_assume_available(std.mem.asBytes(&begin_error));
        cursor.commit();

        return;
    }

    // With more than 4 zones, we add one empty packet and then a huge match copy for it.
    starter_literal_size += @sizeOf(@TypeOf(repeat_end));

    const bytes_to_copy = @sizeOf(@TypeOf(repeat_end)) * (num_zones - 2);
    const ext_copy_bytes = match_copy_len_bytes(bytes_to_copy);

    const starter_header_size = header_size(starter_literal_size);
    const total_lz4_size: u32 = starter_header_size + starter_literal_size + 2 + ext_copy_bytes + 1 + @sizeOf(@TypeOf(begin_error));

    const token_high: u8 = @min(15, starter_literal_size);
    const token_low: u8 = @min(19, bytes_to_copy) - 4;
    const token = token_high << 4 | token_low;

    var cursor = send.cursor();
    cursor.write_assume_available(std.mem.asBytes(&total_lz4_size));
    cursor.write_byte_assume_available(token);
    if (starter_literal_size >= 15) {
        var rem = starter_literal_size - 15;
        while (true) {
            cursor.write_byte_assume_available(@min(rem, 255));
            if (rem < 255) break;
            rem -= 255;
        }
    }
    if (emit_thread_context) {
        cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
    }
    cursor.write_assume_available(first_end_bytes);
    cursor.write_assume_available(std.mem.asBytes(&repeat_end));
    // 16 bit little endian offset of 3 for the match copy
    cursor.write_byte_assume_available(@sizeOf(@TypeOf(repeat_end)));
    cursor.write_byte_assume_available(0);
    // extended match copy length bytes
    if (bytes_to_copy >= 19) {
        var rem = bytes_to_copy - 19;
        while (true) {
            cursor.write_byte_assume_available(@min(rem, 255));
            if (rem < 255) break;
            rem -= 255;
        }
    }
    // Second and final block: Literal for the start zone. This just needs the token byte
    cursor.write_byte_assume_available(@intCast(@sizeOf(@TypeOf(begin_error)) << 4));
    cursor.write_assume_available(std.mem.asBytes(&begin_error));
    cursor.commit();
}

/// For a bulk start operation, we have this sequence:
/// [1 byte ThreadContext + 4 byte threadID] ++ [1 byte ZoneEnd64 tag, 8 bytes timestamp] ++ [1 byte ZoneBegin16, 0x00_00, 4 bytes srcloc, 4 bytes zero] ** N
///                                        ^5                                           ^5+9=14                                                        ^14+11=25
/// The srcloc changes for each item, but we can encode the sequence [4 bytes zero, 1 byte ZoneBegin16, 2 bytes zero] as a match copy between the srclocs.
/// Because of the historical LZ4 requirements, the last literal will always be the [4 bytes srcloc, 4 bytes zero] for the last item
/// For 0 items: 1 byte header, 14 byte payload
/// For 1 item: 2 byte header, 25 incompressible + 8 tail = 35 bytes
/// for 2 items: Compressing would violate 12 byte rule, so 46 bytes
/// For 3-(max+1), 2 byte header, 25+3 incompressible, 2 offset, [1 header, 4 srcloc, 2 offset] ** N-2, 1 final header, 8 tail = 48-496 bytes
/// After item (max+1), all of the srclocs are the same value, so we can encode the rest of the sequence as one big match copy.
/// We must take care to satisfy the historical requirements of 5+ bytes tail and 12+bytes between the dest of the last copy and the end.
/// At the end of the stream described above, we have
/// [1 header, 4 srcloc, 2 offset], with the stream containing [... 4 byte 0, 1 byte ZoneBegin16, 0x00_00, 4 deep_srcloc],
/// which we can then repeat for 11*N-(max+1) bytes before ending with a literal of the MSB of srcloc and 4 bytes of zero
/// So our whole sequence is:
/// For (max+2)+, 2 byte header, 25+4 incompressible, 2 offset, [1 header, 4 srcloc, 2 offset] ** (max+1)-2, [1 header, 4 srcloc, 2 offset, ext matchlen], 1 header, 8 tail
fn compute_zone_bulk_begin_max_len(num_zones: u32) usize {
    // Tracy has a hard limit for how much data can be decompressed at once. This limit is like 23k zones, but here's an assert just in case.
    const max_zones = (q.TargetFrameSize - @sizeOf(q.Packet(q.ThreadContext)) - @sizeOf(q.Packet(q.ZoneEnd))) / @sizeOf(q.Packet(q.ZoneBegin16));
    std.debug.assert(num_zones <= max_zones);

    var starter_literal_size: usize = 0;
    starter_literal_size += @sizeOf(q.Packet(q.ThreadContext));
    starter_literal_size += @sizeOf(q.ZoneEndData);

    // Special case: With zero zones, we just open a zone for "Data Lost", which is variable sized based on dt.
    if (num_zones == 0) {
        return wire_layout(starter_literal_size).total_bytes;
    }

    starter_literal_size += @sizeOf(q.Packet(q.ZoneBegin16));

    if (num_zones == 1) {
        return wire_layout(starter_literal_size).total_bytes;
    }

    starter_literal_size += @sizeOf(q.Packet(q.ZoneBegin16));

    if (num_zones == 2) {
        return wire_layout(starter_literal_size).total_bytes;
    }

    starter_literal_size -= 4;

    // The last srcloc will be emitted in a literal tail
    const tail_size = 9; // 0x80 header, 4 srcloc, 4 zero

    const item_block_size = 1 + 4 + 2; // token 0x43, src_loc 4, 0x000b
    // -2: 1 for the original begin and one for the tail
    const repeat_payload_size = @as(u32, @min(num_zones-1, core0_max_zones) - 2) * item_block_size;

    // If we go past the end of the recorded zone stack, emit a repeated "unknown" begin.
    var error_copy_bytes: usize = 0;
    var error_repeat_size: usize = 0;
    if (num_zones > core0_max_zones + 1) {
        // 7 bytes to align to the next srcloc, plus a full copy for every repeat
        // -2: 1 for the original literal and 1 for the trailer
        error_copy_bytes = 7 + (num_zones - core0_max_zones - 2) * @sizeOf(q.Packet(q.ZoneBegin16));
        error_repeat_size = item_block_size + match_copy_len_bytes(error_copy_bytes);
    }

    const total_lz4_size: u32 = header_size(starter_literal_size) + starter_literal_size + 2 + repeat_payload_size + error_repeat_size + tail_size;

    return @sizeOf(u32) + total_lz4_size;
}

fn core0_emit_zone_bulk_begin(time: i64) void {
    const overflow_zone = terry.external_source_location("Zones Too Deep", @src(), 0x4E3729);

    var starter_literal_size: usize = 0;

    const num_zones = core0_num_zones;

    logf("TERRY: BULK BEGIN for {d} zones\n", .{num_zones});

    const emit_thread_context = !has_core0_thread_context;
    var thread_ctx: q.Packet(q.ThreadContext) = undefined;
    const dt = if (emit_thread_context) blk: {
        starter_literal_size += @sizeOf(@TypeOf(thread_ctx));
        thread_ctx = .{ .ty = .ThreadContext, .data = .{ .thread = core0_thread_id() } };
        has_core0_thread_context = true;
        break :blk time;
    } else time - core0_thread_ref_time;
    core0_thread_ref_time = time;

    var end_data: q.ZoneEndData = undefined;
    const end_bytes = end_data.set(dt);
    starter_literal_size += end_bytes.len;

    // Special case: With zero zones, we just open a zone for "Data Lost", which is variable sized based on dt.
    if (num_zones == 0) {
        const layout = wire_layout(starter_literal_size);
        var cursor = write_header_assume_available(layout);
        if (emit_thread_context) {
            cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
        }
        cursor.write_assume_available(end_bytes);
        cursor.commit();

        return;
    }

    const first_srcloc = core0_zones[0];
    var begin_one = q.packet(.ZoneBegin16, .{ .time = 0, .srcloc = @intFromPtr(first_srcloc) });
    starter_literal_size += @sizeOf(@TypeOf(begin_one));

    if (num_zones == 1) {
        const layout = wire_layout(starter_literal_size);
        var cursor = write_header_assume_available(layout);
        if (emit_thread_context) {
            cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
        }
        cursor.write_assume_available(end_bytes);
        cursor.write_assume_available(std.mem.asBytes(&begin_one));
        cursor.commit();

        return;
    }

    starter_literal_size += @sizeOf(@TypeOf(begin_one));

    if (num_zones == 2) {
        const layout = wire_layout(starter_literal_size);
        var cursor = write_header_assume_available(layout);
        if (emit_thread_context) {
            cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
        }
        cursor.write_assume_available(end_bytes);
        cursor.write_assume_available(std.mem.asBytes(&begin_one));
        begin_one.data.srcloc = @intFromPtr(core0_zones[1]);
        cursor.write_assume_available(std.mem.asBytes(&begin_one));
        cursor.commit();

        return;
    }

    // Remove 4 zeros from the starter literal, this will be part of the first copy
    starter_literal_size -= 4;

    // The last srcloc will be emitted in a literal tail
    const tail_size = 9; // 0x80 header, 4 srcloc, 4 zero

    const item_block_size = 1 + 4 + 2; // token 0x43, src_loc 4, 0x000b
    // -2 for the original begin, -1 for the tail
    const last_repeat_zone: u32 = @min(num_zones-1, core0_max_zones);
    const repeat_payload_size = (last_repeat_zone - 2) * item_block_size;

    // If we go past the end of the recorded zone stack, emit a repeated "unknown" begin.
    var error_copy_bytes: usize = 0;
    var error_repeat_size: usize = 0;
    if (num_zones > core0_max_zones + 1) { // +1 because of the tail
        // 7 bytes to align to the next srcloc, plus a full copy for every repeat
        // -2: 1 for the original literal and 1 for the trailer
        error_copy_bytes = 7 + (num_zones - core0_max_zones - 2) * @sizeOf(q.Packet(q.ZoneBegin16));
        error_repeat_size = item_block_size + match_copy_len_bytes(error_copy_bytes);
    }

    const total_lz4_size: u32 = header_size(starter_literal_size) + starter_literal_size + 2 + repeat_payload_size + error_repeat_size + tail_size;

    var cursor = send.cursor();
    cursor.write_assume_available(std.mem.asBytes(&total_lz4_size));

    const token_high: u8 = @min(15, starter_literal_size);
    const token_low: u8 = 3; // +4, copy 7 byte payload
    cursor.write_byte_assume_available(token_high << 4 | token_low);
    if (starter_literal_size >= 15) {
        var rem = starter_literal_size - 15;
        while (true) {
            cursor.write_byte_assume_available(@min(255, rem));
            if (rem < 255) break;
            rem -= 255;
        }
    }
    if (emit_thread_context) {
        cursor.write_assume_available(std.mem.asBytes(&thread_ctx));
    }
    cursor.write_assume_available(end_bytes);
    cursor.write_assume_available(std.mem.asBytes(&begin_one));
    // We can't match copy less than 4 bytes, so we include some of
    // the second item here to make a larger copyable region
    cursor.write_assume_available(&.{ @intFromEnum(q.Type.ZoneBegin16), 0, 0 });
    cursor.write_assume_available(&std.mem.toBytes(@as(u32, @intFromPtr(core0_zones[1]))));
    // Match copy start at the beginning of begin_one
    cursor.write_assume_available(&std.mem.toBytes(@as(u16, @sizeOf(@TypeOf(begin_one)))));
    // Length was 3 in token, no more length bytes here

    // Now we have a literal for every src loc
    for (core0_zones[2..last_repeat_zone]) |srcloc| {
        comptime std.debug.assert(@sizeOf(@TypeOf(srcloc)) == 4); // This whole thing is built for 4-byte pointers.
        cursor.write_byte_assume_available(0x43); // 4 byte literal, 3+4 byte copy
        cursor.write_assume_available(std.mem.asBytes(&srcloc)); // literal srcloc
        cursor.write_assume_available(&std.mem.toBytes(@as(u16, @sizeOf(@TypeOf(begin_one))))); // copy from one item back
    }

    // Then, if we have so many zones that we start repeating the error src loc,
    // we output a single big match copy for all of those repeats.
    if (num_zones > core0_max_zones + 1) { // +1 because of the tail
        const err_token_high: u8 = 4;
        const err_token_low: u8 = @min(19, error_copy_bytes) - 4;
        cursor.write_byte_assume_available(err_token_high << 4 | err_token_low);
        cursor.write_assume_available(&std.mem.toBytes(overflow_zone));
        cursor.write_assume_available(&std.mem.toBytes(@as(u16, @sizeOf(@TypeOf(begin_one))))); // copy from one item back
        if (error_copy_bytes >= 19) {
            var rem = error_copy_bytes - 19;
            while (true) {
                cursor.write_byte_assume_available(@min(255, rem));
                if (rem < 255) break;
                rem -= 255;
            }
        }
    }

    // Last literal. In the case of going past core0_max_zones, we could include some of this in
    // the match copy, but with the 5-byte rule for the last block it would only save 3 bytes,
    // so it's not worth the extra work that would be needed to calculate the length.
    const last_zone = if (num_zones <= core0_max_zones) core0_zones[num_zones-1] else overflow_zone;
    cursor.write_byte_assume_available(0x80);
    cursor.write_assume_available(&std.mem.toBytes(@as(u64, @intFromPtr(last_zone))));
    cursor.commit();
}

/// To end the state machines, we have this sequence for each state machine:
/// [1 byte ThreadContext + 4 byte name ptr], [1 byte ZoneEnd tag, 8 bytes timestamp], [1 byte ZoneBegin16 tag, 2 bytes zero, 4 bytes error zone, 4 bytes zero]
/// Within each packet, the only values that change are the name ptr. Everything else is long enough to satisfy the standard requirements.
fn compute_sm_bulk_end_len(num_states: u32) usize {
    if (num_states == 0) return 0; // no packet

    if (num_states == 1) {
        // just a literal
        return wire_layout(@sizeOf(q.TrackedSMUpdatePacket)).total_bytes;
    }

    // Each repeat copies 21 bytes, which means it needs 1 byte of extended matchlen.
    // The last repeat copies only 12 bytes, so it needs 0 bytes of extended matchlen.
    // We consider a repeat to include the matchlen from the previous 
    const starter_literal_len = @sizeOf(q.TrackedSMUpdatePacket) + @sizeOf(q.Packet(q.ThreadContext));
    const starter_lz4_len = header_size(starter_literal_len) + starter_literal_len + 2; // 2 byte offset
    const num_repeats = num_states - 2;
    const single_repeat_lz4_bytes = 1 + 1 + 4 + 2; // extended matchlen + header + name ptr + offset
    const repeat_lz4_len = num_repeats * single_repeat_lz4_bytes;
    const tail_literal_len = 8;
    const tail_lz4_len = header_size(tail_literal_len) + tail_literal_len;
    const total_lz4_len: u32 = starter_lz4_len + repeat_lz4_len + tail_lz4_len;

    return 4 + total_lz4_len; // 4 byte size plus big data packet
}

fn core0_emit_sm_bulk_end(time: i64) void {
    const warning_zone = terry.external_source_location("Data Lost, Too Many Zones!", @src(), 0xcc1100);

    const num_states = core0_num_tracked_states;
    if (num_states == 0) return; // no packet

    has_core0_thread_context = false;

    if (num_states == 1) {
        const track = core0_tracked_states.?;
        // just a literal
        var packet: q.TrackedSMUpdatePacket = undefined;
        const bytes = packet.set(track.name, time, warning_zone);
        const layout = wire_layout(bytes.len);
        var cursor = write_header_assume_available(layout);
        cursor.write_assume_available(bytes);
        cursor.commit();

        return;
    }

    // Each repeat copies 21 bytes, which means it needs 1 byte of extended matchlen.
    // The last repeat copies only 12 bytes, so it needs 0 bytes of extended matchlen.
    // We consider a repeat to include the matchlen from the previous 
    const starter_literal_len = @sizeOf(q.TrackedSMUpdatePacket) + @sizeOf(q.Packet(q.ThreadContext));
    const starter_lz4_len = header_size(starter_literal_len) + starter_literal_len + 2; // 2 byte offset
    const num_repeats = num_states - 2;
    const single_repeat_lz4_bytes = 1 + 1 + 4 + 2; // extended matchlen + header + name ptr + offset
    const repeat_lz4_len = num_repeats * single_repeat_lz4_bytes;
    const tail_literal_len = 8;
    const tail_lz4_len = header_size(tail_literal_len) + tail_literal_len;
    const total_lz4_len: u32 = starter_lz4_len + repeat_lz4_len + tail_lz4_len;

    var track = core0_tracked_states.?;
    var cursor = send.cursor();
    cursor.write_assume_available(std.mem.asBytes(&total_lz4_len));
    
    var packet: q.TrackedSMUpdatePacket = undefined;
    comptime { std.debug.assert(starter_literal_len >= 15 and starter_literal_len < (15 + 255)); }
    comptime { std.debug.assert(@sizeOf(q.TrackedSMUpdatePacket) - 4 >= 15 + 4); }

    // First literal header
    cursor.write_byte_assume_available(if (num_states == 2) 0xF8 else 0xFF);
    cursor.write_byte_assume_available(@intCast(starter_literal_len - 15));
    // First literal data, first item and second up to ctx
    cursor.write_assume_available( packet.set(track.name, time, warning_zone) );
    track = track.next.?;
    packet.ctx.data = .{ .thread = @intFromPtr(track.name) };
    cursor.write_assume_available( std.mem.asBytes(&packet.ctx) );
    const offset: u16 = @sizeOf(q.TrackedSMUpdatePacket);
    cursor.write_assume_available( &std.mem.toBytes(offset) );

    for (2..num_states) |n| {
        track = track.next.?;
        cursor.write_byte_assume_available( @intCast(@sizeOf(q.TrackedSMUpdatePacket) - 4 - 19) );
        cursor.write_byte_assume_available( if (n+1 == num_states) 0xF8 else 0xFF );
        cursor.write_assume_available( &std.mem.toBytes(@as(u32, @intFromPtr(track.name))) );
        cursor.write_assume_available( &std.mem.toBytes(offset) );
    }

    cursor.write_byte_assume_available(0x80);
    cursor.write_assume_available( &std.mem.toBytes(@as(u64, @intFromPtr(warning_zone))) );

    cursor.commit();
}

/// [1 byte ThreadContext + 4 byte name ptr], [1 byte ZoneBegin tag, 8 bytes timestamp, 4 bytes zone, 4 bytes zero]
/// The name ptr and zone are uncompressable.
fn core0_compute_sm_bulk_declare_len() usize {
    const num_states = core0_num_pending_states;
    if (num_states == 0) return 0;
    if (num_states == 1) return wire_layout(@sizeOf(q.TrackedSMRegisterPacket)).total_bytes;
    
    const first_literal_size = @sizeOf(q.TrackedSMRegisterPacket) + @sizeOf(q.Packet(q.ThreadContext));
    const single_repeat_size = 1 + 4 + 2 + 1 + 4 + 2;
    const last_literal_size = 8;

    const total_lz4_size = header_size(first_literal_size) + first_literal_size + 2 + (single_repeat_size * (num_states - 2)) + header_size(last_literal_size) + last_literal_size;

    return 4 + total_lz4_size;
}

fn core0_emit_sm_bulk_declare_and_mark_tracked(time: i64) void {
    const num_states = core0_num_pending_states;
    if (num_states == 0) return;

    // We are going to invalidate core0 thread context
    has_core0_thread_context = false;

    // At the end of this function, `track` will be the last pending state.
    // at that point, we need to clear the pending states and link them
    // into the tracked list.
    var track = core0_pending_states.?;
    defer {
        std.debug.assert(track.next == null);
        track.next = core0_tracked_states;
        core0_tracked_states = core0_pending_states;
        core0_pending_states = null;

        core0_num_tracked_states += num_states;
        core0_num_pending_states = 0;
    }

    if (num_states == 1) {
        var packet: q.TrackedSMRegisterPacket = undefined;
        const bytes = packet.set(track.name, time, track.srcloc);
        const layout = wire_layout(bytes.len);
        var cursor = write_header_assume_available(layout);
        cursor.write_assume_available(bytes);

        std.debug.assert(cursor.uncommitted_len() == layout.total_bytes);
        std.debug.assert(cursor.uncommitted_len() == core0_compute_sm_bulk_declare_len());

        cursor.commit();

        return;
    }

    const first_literal_size = @sizeOf(q.TrackedSMRegisterPacket) + @sizeOf(q.Packet(q.ThreadContext));
    const single_repeat_size = 1 + 4 + 2 + 1 + 4 + 2;
    const last_literal_size = 8;

    const total_lz4_size: u32 = header_size(first_literal_size) + first_literal_size + 2 + (single_repeat_size * (num_states - 2)) + header_size(last_literal_size) + last_literal_size;

    var cursor = send.cursor();
    cursor.write_assume_available(&std.mem.toBytes(total_lz4_size));

    comptime { std.debug.assert(header_size(first_literal_size) == 2); }
    cursor.write_byte_assume_available(0xF5);
    cursor.write_byte_assume_available(@intCast( first_literal_size - 15 ));
    var packet: q.TrackedSMRegisterPacket = undefined;
    const bytes = packet.set(track.name, time, track.srcloc);
    cursor.write_assume_available(bytes);

    track = track.next.?;
    packet.ctx.data = .{ .thread = @intFromPtr(track.name) };
    cursor.write_assume_available(std.mem.asBytes(&packet.ctx));

    const offset: u16 = @sizeOf(q.TrackedSMRegisterPacket);
    cursor.write_assume_available(&std.mem.toBytes(offset));

    for (2..num_states) |_| {
        cursor.write_byte_assume_available(0x41);
        cursor.write_assume_available(&std.mem.toBytes(@as(u32, @intFromPtr(track.srcloc))));
        cursor.write_assume_available(&std.mem.toBytes(offset));
        track = track.next.?;
        cursor.write_byte_assume_available(0x45);
        cursor.write_assume_available(&std.mem.toBytes(@as(u32, @intFromPtr(track.name))));
        cursor.write_assume_available(&std.mem.toBytes(offset));
    }

    cursor.write_byte_assume_available(0x80);
    cursor.write_assume_available(&std.mem.toBytes(@as(u64, @intFromPtr(track.srcloc))));

    std.debug.assert(cursor.uncommitted_len() == 4 + total_lz4_size);
    std.debug.assert(cursor.uncommitted_len() == core0_compute_sm_bulk_declare_len());

    cursor.commit();
}

/// [1 byte ThreadContext + 4 byte name ptr], [1 byte ZoneEnd tag, 8 bytes timestamp], [1 byte ZoneBegin16 tag, 2 bytes zero, 4 bytes zone, 4 bytes zero]
/// The name ptr and zone are uncompressable.
fn core0_compute_sm_bulk_update_len() usize {
    const num_states = core0_num_pending_states;
    if (num_states == 0) return 0;
    if (num_states == 1) return wire_layout(@sizeOf(q.TrackedSMUpdatePacket)).total_bytes;

    const first_literal_size = @sizeOf(q.TrackedSMUpdatePacket) + @sizeOf(q.Packet(q.ThreadContext));
    const single_repeat_size = 1 + 4 + 2 + 1 + 4 + 2;
    const last_literal_size = 8;

    const total_lz4_size = header_size(first_literal_size) + first_literal_size + 2 + (single_repeat_size * (num_states - 2)) + header_size(last_literal_size) + last_literal_size;

    return 4 + total_lz4_size;

}

fn core0_emit_sm_bulk_update(time: i64) void {
    const num_states = core0_num_tracked_states;
    if (num_states == 0) return;

    // We are going to invalidate core0 thread context
    has_core0_thread_context = false;

    var track = core0_tracked_states.?;
    defer { std.debug.assert(track.next == null); }

    if (num_states == 1) {
        var packet: q.TrackedSMUpdatePacket = undefined;
        const bytes = packet.set(track.name, time, track.srcloc);
        const layout = wire_layout(bytes.len);
        var cursor = write_header_assume_available(layout);
        cursor.write_assume_available(bytes);

        std.debug.assert(cursor.uncommitted_len() == layout.total_bytes);
        std.debug.assert(cursor.uncommitted_len() == compute_sm_bulk_end_len(num_states));
        cursor.commit();

        return;
    }

    const first_literal_size = @sizeOf(q.TrackedSMUpdatePacket) + @sizeOf(q.Packet(q.ThreadContext));
    const single_repeat_size = 1 + 4 + 2 + 1 + 4 + 2;
    const last_literal_size = 8;

    const total_lz4_size: u32 = header_size(first_literal_size) + first_literal_size + 2 + (single_repeat_size * (num_states - 2)) + header_size(last_literal_size) + last_literal_size;

    var cursor = send.cursor();
    cursor.write_assume_available(&std.mem.toBytes(total_lz4_size));

    comptime { std.debug.assert(header_size(first_literal_size) == 2); }
    cursor.write_byte_assume_available(0xF8);
    cursor.write_byte_assume_available(@intCast( first_literal_size - 15 ));
    var packet: q.TrackedSMUpdatePacket = undefined;
    const bytes = packet.set(track.name, time, track.srcloc);
    cursor.write_assume_available(bytes);

    track = track.next.?;
    packet.ctx.data = .{ .thread = @intFromPtr(track.name) };
    cursor.write_assume_available(std.mem.asBytes(&packet.ctx));

    const offset: u16 = @sizeOf(q.TrackedSMUpdatePacket);
    cursor.write_assume_available(&std.mem.toBytes(offset));

    for (2..num_states) |_| {
        cursor.write_byte_assume_available(0x41);
        cursor.write_assume_available(&std.mem.toBytes(@as(u32, @intFromPtr(track.srcloc))));
        cursor.write_assume_available(&std.mem.toBytes(offset));
        track = track.next.?;
        cursor.write_byte_assume_available(0x48);
        cursor.write_assume_available(&std.mem.toBytes(@as(u32, @intFromPtr(track.name))));
        cursor.write_assume_available(&std.mem.toBytes(offset));
    }

    cursor.write_byte_assume_available(0x80);
    cursor.write_assume_available(&std.mem.toBytes(@as(u64, @intFromPtr(track.srcloc))));

    std.debug.assert(cursor.uncommitted_len() == total_lz4_size + 4);
    std.debug.assert(cursor.uncommitted_len() == compute_sm_bulk_end_len(num_states));
    cursor.commit();
}

fn core0_compute_bulk_end_len(num_zones: u32, num_sms: u32) usize {
    return compute_zone_bulk_end_max_len(num_zones) +
        compute_sm_bulk_end_len(num_sms);
}

fn core0_emit_bulk_end(time: i64) void {
    const write_size = core0_compute_bulk_end_len(core0_num_zones, core0_num_tracked_states);
    std.debug.assert(send.available_space() >= write_size);
    const start_pos = send.write_offset;

    core0_emit_zone_bulk_end(time);
    core0_emit_sm_bulk_end(time);

    const end_pos = send.write_offset;
    const len = if (start_pos <= end_pos) end_pos - start_pos else send.size + end_pos - start_pos;
    std.debug.assert(len == write_size);
}

fn core0_compute_bulk_begin_len(num_zones: u32) usize {
    return compute_zone_bulk_begin_max_len(num_zones) +
        core0_compute_sm_bulk_update_len() +
        core0_compute_sm_bulk_declare_len();
}

fn core0_emit_bulk_begin(time: i64) void {
    const write_size = core0_compute_bulk_begin_len(core0_num_zones);
    std.debug.assert(send.available_space() >= write_size);
    const start_pos = send.write_offset;

    core0_emit_zone_bulk_begin(time);
    core0_emit_sm_bulk_update(time);
    core0_emit_sm_bulk_declare_and_mark_tracked(time);

    const end_pos = send.write_offset;
    const len = if (start_pos <= end_pos) end_pos - start_pos else send.size + end_pos - start_pos;
    std.debug.assert(len == write_size);
}

pub inline fn reserved_space_for_begin_zone() usize {
    return core0_compute_bulk_end_len(core0_num_zones + 1, core0_num_tracked_states);
}

pub inline fn reserved_space_for_end_zone() usize {
    return core0_compute_bulk_end_len(@max(1, core0_num_zones) - 1, core0_num_tracked_states);
}

pub inline fn reserved_space_for_non_zone() usize {
    return core0_compute_bulk_end_len(core0_num_zones, core0_num_tracked_states);
}

pub inline fn reserved_space_post_bulk_begin() usize {
    return core0_compute_bulk_end_len(core0_num_zones, core0_num_pending_states + core0_num_tracked_states);
}

pub fn available_space_with_reservation() usize {
    const raw_available = send.available_space();
    if (state == .connected) {
        const reserved_space = reserved_space_for_non_zone();
        std.debug.assert(raw_available >= reserved_space);
        return raw_available - reserved_space;
    } else {
        return raw_available;
    }
}

// Set time_high to force absolute times to be 64 bit.
// This ensures that packet sizes with thread contexts
// are predictable, which simplifies some of the LZ4
// packing routines for bulk begin/end.
// This limit would naturally be hit after about 30
// seconds, so forcing these to be large doesn't
// significantly impact our overall bandwidth.
var time_high: u32 = q.ProtocolOffset32Bit >> 32 + 1;
var time_last: u32 = 0;
pub fn get_time_core0(cs: microzig.interrupt.CriticalSection) i64 {
    _ = cs; // Just to make sure the caller has a crit sec
    //return @bitCast(timer.micros());
    // For higher precision, we read the 32-bit clock counter.
    // Note that this timer will wrap about once every 30 seconds,
    // which should be enough for this code to accurately guess
    // the high part. But if we have very long running intervals
    // between calls to get_time, we could use the system timer
    // to fix up the longer time periods.
    const time = microzig.chip.peripherals.PPB.DWT_CYCCNT.raw;
    if (time < time_last) time_high += 1;
    time_last = time;
    return @bitCast(@as(u64, time_high) << 32 | time);
}

pub fn is_connected_core0() bool {
    return @atomicLoad(bool, &atomic_is_connected, .unordered);
}

pub fn is_connected_core1() bool {
    return @atomicLoad(bool, &atomic_is_connected, .acquire);
}

pub fn get_connection_id_core0() u16 {
    return @atomicLoad(u16, &atomic_connection_id, .unordered);
}

pub fn get_connection_id_core1() bool {
    return @atomicLoad(u16, &atomic_connection_id, .acquire);
}

// If a RTT transaction on core 0 times out, call this to trigger a disconnect.
pub fn core0_rtt_timeout(stream_valid: bool) void {
    log("\nTERRY: CORE0 RTT TIMEOUT!\n\n");
    if (is_connected_core0()) {
        @atomicStore(bool, &atomic_is_connected,false, .release);
        clear_queues(); // We've probably been blocking for a while, unblock other threads.

        // Note: Changing the state here might interrupt a pending send.
        // This is fine, sends are atomic packets and can safely be cancelled.
        // Still good to keep in mind.
        if (stream_valid) {
            send_empty(.Terminate, .timeout);
        } else {
            state = .timeout;
        }
    }
}

pub fn wait_for_connection(deadline: u64) !bool {
    while (true) {
        if (is_connected_core0()) return true;
        if (state == .terminal) return false;
        if (timer.micros() > deadline) return error.Timeout;
        poll();
    }
}

pub fn is_waiting_for_connection() bool {
    return !is_connected_core0() and state != .terminal;
}

pub fn is_buffer_full() bool {
    return state == .buffer_full;
}

pub fn try_resume_data(time: i64) bool {
    const resume_safety_margin = 128;
    const necessary_bytes = core0_compute_bulk_begin_len(core0_num_zones) + resume_safety_margin + reserved_space_post_bulk_begin();
    if (send.available_space() >= necessary_bytes) {
        core0_emit_bulk_begin(time);
        state = .connected;
        return true;
    }
    return false;
}

pub fn data_overflow(time: i64) void {
    @as(*volatile State, &state).* = .buffer_full;
    core0_emit_bulk_end(time);
    state = .buffer_full;
}

pub fn poll() void {
    // After handling a packet, if we haven't processed queues this poll, we need to do that.
    // Otherwise skip the queues and handle another server query.
    var poll_queues_after_packet = true;

    dispatch: switch (state) {
        .uninitialized => {
            microzig.chip.peripherals.PPB.DWT_CTRL.modify(.{ .CYCCNTENA = 1 });
            startup_time = get_time_core0(undefined);
            log("TERRY: .uninitialized => .wait_for_server\n");
            state = .wait_for_server;
            continue :dispatch state;
        },
        .wait_for_server => {
            // TODO more robust shibboleth handling is necessary for on-demand,
            // where there might be junk from the previous connection before
            // the shibboleth, which could offset the rtt stream arbitrarily.
            // We really want to search the RTT queue for the shibboleth, and
            // clear it if not found.
            var shibboleth: [q.HandshakeShibboleth.len]u8 = undefined;
            if (recv.read_if_available(&shibboleth)) {
                if (std.mem.eql(u8, &shibboleth, q.HandshakeShibboleth)) {
                    log("TERRY: .wait_for_server => .handshake\n");
                    state = .handshake;
                } else {
                    log("TERRY: invalid shibboleth! => .terminal\n");
                    state = .terminal;
                }
                continue :dispatch state;
            }
        },
        .handshake => {
            var protocol_ver: u32 = 0;
            if (recv.read_if_available(std.mem.asBytes(&protocol_ver))) {
                if (protocol_ver != q.ProtocolVersion) {
                    logf("TERRY: invalid protocol version! expect {d}, found {d}\n", .{q.ProtocolVersion, protocol_ver});
                    state = .bad_protocol_version;
                } else {
                    log("TERRY: .handshake => .send_welcome_msg\n");
                    state = .send_welcome_msg;
                }
                continue :dispatch state;
            }
        },
        .send_welcome_msg => {
            const msg = make_welcome_msg();
            if (send.write_if_available(std.mem.asBytes(&msg))) {
                log("TERRY: .send_welcome_msg => .send_on_demand_payload\n");
                state = .send_on_demand_payload;
                continue :dispatch state;
            }
        },
        .send_on_demand_payload => {
            // TODO on-demand
            log("TERRY: .send_on_demand_payload => .new_connection\n");
            state = .new_connection;
            continue :dispatch state;
        },
        .new_connection => {
            if (support_on_demand) {
                clear_queues();
            }

            // Make sure we have enough space for some data and a bulk end before starting
            std.debug.assert(core0_num_zones == 0); // TODO on-demand this might not be true on reconnect, might need special handling
            if (send.available_space() < 128 + core0_compute_sm_bulk_declare_len() + reserved_space_post_bulk_begin()) {
                return;
            }

            // Declare any tracked state machines
            has_core0_thread_context = false;
            core0_emit_sm_bulk_declare_and_mark_tracked(get_time_core0(undefined));

            if (support_on_demand) {
                @atomicRmw(u16, &atomic_connection_id, .Add, 1, .release);
            }
            @atomicStore(bool, &atomic_is_connected, true, .release);

            interrupt_trace_enabled = true;
            last_keep_alive_us = timer.micros();
            log("TERRY: .new_connection => .connected\n");
            state = .connected;
            continue :dispatch state;
        },
        .connected => {
            try_send_packet();
            if (state != .connected) {
                continue :dispatch state;
            }

            if (!disconnect_requested) {
                do_systime();
                do_syspower();
                // TODO round-robin to avoid serial queue starvation deadlock?
                send_core1_queue();
                send_serial_queue();
            } else {
                clear_queues();
            }

            // TODO keep-alive once every 5 seconds

            poll_queues_after_packet = false;

            var query: q.ServerQueryPacket = undefined;
            while (pending_packet_type == .no_packet and state == .connected) {
                // TODO maybe put a deadline here to avoid very long polls handling a chatty server

                if (!recv.read_if_available(std.mem.asBytes(&query))) break;

                logf("TERRY: server query: {s}\n", .{@tagName(query.@"type")});

                switch (query.@"type") {
                    .ServerQueryString => send_string_ptr(query.ptr, .StringData, .server_query),
                    .ServerQueryPlotName => send_string_ptr(query.ptr, .PlotName, .server_query),
                    .ServerQueryFrameName => send_string_ptr(query.ptr, .FrameName, .server_query),
                    .ServerQueryFiberName => send_string_ptr(query.ptr, .FiberName, .server_query),

                    // Normally query.ptr for ServerQueryThreadString would be a TID, but since we don't
                    // have TIDs, Terry uses pointers to the name string as its the thread identifier.
                    // Note that this is also used for Tracked State Machine names, which are tracked as if they were threads.
                    .ServerQueryThreadString => send_string_ptr(query.ptr, .ThreadName, .server_query),

                    .ServerQueryExternalName => send_string(query.ptr, "???", .ExternalThreadName, .external_name_pt1), // External name request sends two strings in response

                    .ServerQuerySourceLocation => send_src_loc(query.ptr, .server_query),

                    .ServerQueryCallstackFrame => send_empty(.AckServerQueryNoop, .server_query), // no symbol info
                    .ServerQuerySymbol => send_empty(.AckServerQueryNoop, .server_query),
                    .ServerQuerySymbolCode => send_empty(.AckSymbolCodeNotAvailable, .server_query),
                    .ServerQuerySourceCode => send_empty(.AckSourceCodeNotAvailable, .server_query),

                    // Query data is only used by source code queries, which we don't support.
                    // So just pretend we're recording it, but we can ignore the data.
                    .ServerQueryDataTransfer => send_empty(.AckServerQueryNoop, .server_query),
                    .ServerQueryDataTransferPart => send_empty(.AckServerQueryNoop, .server_query),

                    .ServerQueryParameter => {
                        const param_idx: u32 = @intCast(query.ptr >> 32);
                        const param_val: i32 = @bitCast(@as(u32, @truncate(query.ptr)));
                        if (param_callback_fn) |func| {
                            func(param_callback_obj, param_idx, param_val);
                        }
                        send_empty(.AckServerQueryNoop, .server_query);
                    },

                    // Disconnect is a handshake.
                    // Server sends Disconnect, client sends Terminate, server sends Terminate.
                    // Client can also send Terminate unprompted, which may result in the server
                    // sending Terminate back.
                    .ServerQueryDisconnect => {
                        disconnect_requested = true;
                        send_empty(.Terminate, .server_query);
                    },
                    .ServerQueryTerminate => {
                        state = .terminating;
                        continue :dispatch state;
                    },
                    _ => {
                        // TODO any special error handling to do here?
                        std.debug.assert(false);
                    },
                }

                try_send_packet();
                if (state != .connected) {
                    continue :dispatch state;
                }
            }
        },

        .buffer_full => {
            clear_queues();
            const time = get_time_core0(undefined);
            if (try_resume_data(time)) {
                continue :dispatch .connected;
            }
        },

        .terminating => {
            @atomicStore(bool, &atomic_is_connected, false, .release);
            if (support_on_demand) {
                // TODO the server might send trailing packets before signing off, we need to
                // handle clearing these out or we will get an invalid shibboleth and end up
                // in .unrecoverable_error
                log("TERRY: .terminating => .wait_for_server\n");
                state = .wait_for_server;
            } else {
                // Terminating is effectively unrecoverable, no more connections can be made
                // unless on-demand is supported.
                log("TERRY: .terminating => .terminal\n");
                state = .terminal;
            }
            // Don't continue the state here, let poll() loop.
        },

        .timeout => {
            // TODO can we reset an RTT stream safely? Do that to the send stream if possible.
            if (support_on_demand) {
                // TODO the server might send trailing packets before signing off, we need to
                // handle clearing these out or we will get an invalid shibboleth and end up
                // in .unrecoverable_error
                log("TERRY: .timeout => .wait_for_server\n");
                state = .wait_for_server;
            } else {
                // Terminating is effectively unrecoverable, no more connections can be made
                // unless on-demand is supported.
                log("TERRY: .timeout => .terminal\n");
                state = .terminal;
            }
            // Don't continue the state here, let poll() loop.
        },

        .bad_protocol_version => {
            const status = q.HandshakeStatus.HandshakeProtocolMismatch;
            if (send.write_if_available(std.mem.asBytes(&status))) {
                log("TERRY: .bad_protocol_version => .wait_for_server\n");
                state = .wait_for_server;
                return; // We could continue with this state, but we'll let the OS loop once to avoid the possibility of a long poll.
            }
        },

        .unrecoverable_error => {
            // Be kind, tell the server we are disconnecting
            if (@atomicLoad(bool, &atomic_is_connected, .unordered)) {
                send_empty(.Terminate, .terminal);
                @atomicStore(bool, &atomic_is_connected, false, .release);
            } else {
                log("TERRY: .unrecoverable_error => .terminal\n");
                state = .terminal;
            }
            continue :dispatch state;
        },
        .terminal => {
            clear_queues();
        },
    }
}

fn try_send_packet() void {
    if (pending_packet_type == .no_packet) return;

    const ty = tmp_packet_as(q.Type).*;
    const packet_size = q.PacketSize[@intFromEnum(ty)];
    const data_size = packet_size + tmp_packet_data.len;
    const layout = wire_layout(data_size);
    const size = layout.total_bytes;
    // The packet needs to be sent as a single operation
    // If we can send it without blocking, do so.
    {
        // Use a critical section to make sure interrupts don't write zones in
        // the middle of our string.
        var cs = microzig.interrupt.enter_critical_section();
        const available = available_space_with_reservation();
        if (available >= size) {
            var cursor = write_header_assume_available(layout);
            cursor.write_assume_available(tmp_packet[0..packet_size]);
            cursor.write_assume_available(tmp_packet_data);
            cursor.commit();

            cs.leave();
        } else if (size > rtt.tracy_send_size / 3 and available >= layout.header_bytes + packet_size) {
            // TODO: Large packet sends should probably not block. Instead,
            // they could disable profiling with a bulk end, then on poll send
            // any available data before 
            const z = terry.core0.zone("Terry Send Large Data Packet (Interrupt Profiling Disabled)", @src()); defer z.end();

            // The packet is likely too large to be able to send
            // without blocking. We're going to do a blocking send.
            // We can't safely disable interrupts for that long,
            // so instead we are just going to disable tracing from
            // interrupts to keep them from messing with the data.
            const deadline = timer.micros() + server_timeout_us;
            interrupt_trace_enabled = false;
            defer interrupt_trace_enabled = true;
            std.mem.doNotOptimizeAway(&interrupt_trace_enabled);
            cs.leave();

            var cursor = write_header_assume_available(layout);
            cursor.write_assume_available(tmp_packet[0..packet_size]);
            cursor.commit(); // commit immediately, this packet is too large for one transaction

            send.write_blocking_with_deadline(tmp_packet_data, deadline) catch {
                // We wrote a partial message, but can't write more without halting.
                // the system. This might mean the server disconnected, or just that
                // it's running slowly.
                // In the future we could choose to temporarily disable tracy,
                // run a poll loop, and then come back to it. This could possibly
                // leave the zones in an inconsistent but recoverable state.
                // For now though, we'll just disconnect.
                log("TERRY: .send_packet => .unrecoverable_error, timeout in large send\n");
                state = .unrecoverable_error;
                return;
            };

            if (state == .connected) {
                const space_needed = reserved_space_for_non_zone();
                while (send.available_space() < space_needed) {
                    if (timer.micros() > deadline) {
                        // TODO the output stream is consistent in this state, we might be able to
                        // recover from this one.
                        log("TERRY: .send_packet => .unrecoverable_error, timeout in large send\n");
                        state = .unrecoverable_error;
                        return;
                    }
                }
            }
        } else {
            // Small packet but we can't send it now, try it next poll.
            // TODO if this happens for too long, risk a blocking send.
            cs.leave();
            return;
        }
    }

    tmp_packet_data.len = 0;
    state = switch (pending_packet_type) {
        .no_packet => unreachable,
        .server_query => state,
        .timeout => .timeout,
        .terminal => .terminal,
        .external_name_pt1 => {
            // Packet from pt1 is still valid and has the thread ID in it
            const thread_id = tmp_packet_as(q.Packet(q.StringTransfer16)).data.ptr;
            // TODO: This is the process name. Maybe include cart info?
            send_string(thread_id, "???", .ExternalName, .server_query);
            return try_send_packet();
        },
    };

    pending_packet_type = .no_packet;

    logf("TERRY: .send_packet => .{s}\n", .{@tagName(state)});
}

fn send_string_ptr(ptr: u64, ty: q.Type, pending_ty: PendingPacket) void {
    // TODO fault tolerant string len search
    const str = std.mem.span(@as([*:0]const u8, @ptrFromInt(@as(usize, @intCast(ptr)))));
    send_string(ptr, str, ty, pending_ty);
}

fn send_string(id: u64, str: []const u8, ty: q.Type, pending_ty: PendingPacket) void {
    pending_packet_type = pending_ty;
    const len_16: u16 = @intCast(@min(str.len, ~@as(u16, 0)));
    tmp_packet_as(q.Packet(q.StringTransfer16)).* = .{
        .ty = ty,
        .data = .{ .ptr = id, .len = len_16 },
    };
    tmp_packet_data = str[0..len_16];
    logf("TERRY: send_string .{s}='{s}' => .{s}\n", .{ @tagName(ty), str, @tagName(pending_packet_type) });
}

fn send_src_loc(ptr: u64, pending_ty: PendingPacket) void {
    pending_packet_type = pending_ty;
    const src_loc: *q.SourceLocationData = @ptrFromInt(@as(usize, @intCast(ptr)));
    tmp_packet_as(q.Packet(q.SourceLocation)).* = .{
        .ty = .SourceLocation,
        .data = .{
            .name = @intFromPtr(src_loc.name),
            .file = @intFromPtr(src_loc.file),
            .function = @intFromPtr(src_loc.function),
            .line = src_loc.line,
            .b = @intCast(src_loc.color & 0xFF),
            .g = @intCast(src_loc.color >> 8 & 0xFF),
            .r = @intCast(src_loc.color >> 16 & 0xFF),
        },
    };
    tmp_packet_data.len = 0;
    logf("TERRY: send_src_loc '{s}@{s}:{d}' => .{s}\n", .{ src_loc.function orelse "<null>", src_loc.file orelse "<null>", src_loc.line, @tagName(pending_packet_type) });
}

fn send_empty(ty: q.Type, pending_ty: PendingPacket) void {
    pending_packet_type = pending_ty;
    std.debug.assert(q.PayloadSize[@intFromEnum(ty)] == 0);
    tmp_packet_as(q.Packet(q.Empty)).* = .{ .ty = ty, .data = .{} };
    tmp_packet_data.len = 0;
    logf("TERRY: send_empty .{s} => .{s}\n", .{ @tagName(ty), @tagName(pending_packet_type) });
}

fn clear_queues() void {
    // TODO once we have multiple threads, this function should
    // dequeue and throw away any data from other threads,
    // to prevent them from blocking on a full queue.
}

fn send_core1_queue() void {
    // TODO copy data from the Core 1 queue to the RTT port
}

fn send_serial_queue() void {
    // TODO copy data from the serial queue to the RTT port
}

fn do_systime() void {
    // TODO maybe emit systime packets?
}

fn do_syspower() void {
    // TODO emit power status packets
}

// TODO get this through a real config somewhere
const clk_frequency = 125_000_000;

inline fn make_welcome_msg() q.WelcomeMessage {
    var msg: q.WelcomeMessage = .{
        //.timerMul = 1000.0, // nanoseconds per tick
        .timerMul = 1_000_000_000.0 / clk_frequency,
        .initBegin = 0,
        .initEnd = startup_time,
        .resolution = 1, // timer increments by 1
        .epoch = 0, // no knowledge of time since epoch is available
        .exectime = 0, // TODO this is the mtime of the executable file. We actually might know this.
        .pid = 1, // PID 1, the OS
        .samplingPeriod = os_sampling_period,
        .flags = .{
            .CodeTransfer = false,
            .CombineSamples = false,
            .IdentifySamples = false,
            .IgnoreMemFaults = false,
            .OnDemand = support_on_demand,
        },
        .cpuArch = .CpuArchArm32,
        .cpuManufacturer = std.mem.zeroes([12]u8),
        .cpuId = 0, // No cpuid on arm
        .programName = std.mem.zeroes([q.WelcomeMessageProgramNameSize]u8),
        .hostInfo = std.mem.zeroes([q.WelcomeMessageHostInfoSize]u8),
    };
    const prg_name = "sycl-os-kernel.uf2";
    msg.programName[0..prg_name.len].* = prg_name[0..].*;
    _ = std.fmt.bufPrint(&msg.hostInfo,
        \\OS: SYCL
        \\Compiler: Zig {f}
        \\User: root
        \\Arch: ARM
        \\CPU: Cortex-M33
        \\Device: SYCL Badge V2 rev{d}
        \\CPU cores: 2
        \\RAM: 520 KB
        \\Client: Terry
        \\
    , .{ builtin.zig_version, rev.rev }) catch @panic("Host Info too large!");
    return msg;
}
