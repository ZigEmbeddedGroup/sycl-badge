pub const client = @import("terry_client.zig");
const q = @import("terry_protocol.zig");

const mz_rtt = @import("../drivers/microzig_rtt.zig");
const rtt = @import("../drivers/rtt.zig");
const timer = @import("../drivers/timer.zig");
const std = @import("std");

const microzig = @import("microzig");

pub const poll = client.poll;

const external_linksection = ".rodata";

fn StringWrap(comptime str: [:0]const u8) type {
    return struct {
        const bytes linksection(external_linksection) = str[0..str.len:0].*;
    };
}

pub inline fn external_string(comptime str: [:0]const u8) [*:0]const u8 {
    return &StringWrap(str).bytes;
}

fn SourceLocationWrap(name: ?[:0]const u8, zig_src_loc: std.builtin.SourceLocation, color: u32) type {
    return struct {
        pub const src_loc: q.SourceLocationData linksection(external_linksection) = .{
            .name = if (name) |n| external_string(n) else null,
            .function = external_string(zig_src_loc.fn_name),
            .file = external_string(zig_src_loc.file),
            .line = zig_src_loc.line,
            .color = color,
        };
    };
}

pub inline fn external_source_location(comptime name: ?[:0]const u8, comptime zig_src_loc: std.builtin.SourceLocation, comptime color: u32) *const q.SourceLocationData {
    return &SourceLocationWrap(name, zig_src_loc, color).src_loc;
}


pub const ZoneCtxData = struct {
    pub const inactive: ZoneCtxData = .{ .active = false, .conn_id = undefined };

    active: bool,
    conn_id: u16,
};


pub const core0 = struct {
    const interface = struct {
        pub const is_connected = client.is_connected_core0;
        pub const get_connection_id = client.get_connection_id_core0;

        pub fn begin(comptime max_segments: usize, cs: microzig.interrupt.CriticalSection) Writer(max_segments) {
            return .init_with_cs(cs);
        }

        fn Writer(comptime max_segments: usize) type {
            return struct {
                start_time_tracy: i64,
                ref_time: i64,
                extents: [max_segments][]const u8 = undefined,
                num_extents: usize = 0,
                literal_bytes: usize = 0,
                reserved_space: usize = 0,
                has_core0_thread_ctx: bool,

                fn init_with_cs(cs: microzig.interrupt.CriticalSection) @This() {
                    return .{
                        .start_time_tracy = client.get_time_core0(cs),
                        .ref_time = client.core0_thread_ref_time,
                        .has_core0_thread_ctx = client.has_core0_thread_context,
                    };
                }

                pub fn add_extent(w: *@This(), data: []const u8) void {
                    std.debug.assert(w.num_extents < max_segments);
                    w.extents[w.num_extents] = data;
                    w.num_extents += 1;
                    w.literal_bytes += data.len;
                }

                pub fn thread_ctx(w: *@This(), thread_ctx_data: *q.Packet(q.ThreadContext)) void {
                    if (!w.has_core0_thread_ctx) {
                        thread_ctx_data.* = .{ .ty = .ThreadContext, .data = .{ .thread = client.core0_thread_id() } };
                        w.add_extent(std.mem.asBytes(thread_ctx_data));
                        w.ref_time = 0;
                        w.has_core0_thread_ctx = true;
                    }
                }

                pub fn thread_time(w: *@This()) i64 {
                    return w.thread_time_at(w.start_time_tracy);
                }

                pub fn thread_time_at(w: *@This(), time: i64) i64 {
                    const delta = time - w.ref_time;
                    w.ref_time = time;
                    return delta;
                }

                pub fn commit(w: *@This()) bool {
                    const layout = client.wire_layout(w.literal_bytes);
                    if (client.send.available_space() >= layout.total_bytes + w.reserved_space) {
                        var cursor = client.write_header_assume_available(layout);
                        for (w.extents[0..w.num_extents]) |extent| {
                            cursor.write_assume_available(extent);
                        }
                        cursor.commit();

                        client.has_core0_thread_context = w.has_core0_thread_ctx;
                        client.core0_thread_ref_time = w.ref_time;

                        return true;
                    } else {
                        client.data_overflow(w.start_time_tracy);

                        return false;
                    }
                }
            };
        }
    };

    pub const Zone = struct {
        data: ZoneCtxData,

        pub inline fn end(z: Zone) void {
            zone_end(z.data);
        }
    };

    pub inline fn fn_zone(comptime loc: std.builtin.SourceLocation) Zone {
        return zone_color_cond(null, loc, 0, true);
    }
    pub inline fn fn_zone_color(comptime loc: std.builtin.SourceLocation, comptime color: u32) Zone {
        return zone_color_cond(null, loc, color, true);
    }
    pub inline fn zone(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation) Zone {
        return zone_color_cond(name, loc, 0, true);
    }
    pub inline fn zone_color(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, comptime color: u32) Zone {
        return zone_color_cond(external_source_location(name, loc, color), true);
    }
    pub inline fn fn_zone_cond(comptime loc: std.builtin.SourceLocation, active: bool) Zone {
        return zone_color_cond(null, loc, 0, active);
    }
    pub inline fn fn_zone_color_cond(comptime loc: std.builtin.SourceLocation, comptime color: u32, active: bool) Zone {
        return zone_color_cond(null, loc, color, active);
    }
    pub inline fn zone_cond(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, active: bool) Zone {
        return zone_color_cond(name, loc, 0, active);
    }
    pub inline fn zone_color_cond(comptime name: ?[:0]const u8, comptime loc: std.builtin.SourceLocation, comptime color: u32, active: bool) Zone {
        return .{ .data = zone_begin_static(external_source_location(name, loc, color), active) };
    }

    inline fn zone_begin_static(src_loc: *const q.SourceLocationData, active: bool) ZoneCtxData {
        // TODO on-demand check connection ID
        if (!active or !interface.is_connected()) return .inactive;

        const conn_id = outline_zone_begin_static(src_loc);
        return .{
            .active = true,
            .conn_id = conn_id,
        };
    }

    noinline fn outline_zone_begin_static(src_loc: *const q.SourceLocationData) u16 {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        var writer = interface.begin(2, cs);

        const conn_id = interface.get_connection_id();

        if (client.is_buffer_full()) {
            client.push_zone(src_loc);
            _ = client.try_resume_data(writer.start_time_tracy);
        } else {
            var thread_ctx_data: q.Packet(q.ThreadContext) = undefined;
            writer.thread_ctx(&thread_ctx_data);
            var begin_data: q.ZoneBeginData = undefined;
            writer.add_extent( begin_data.set( writer.thread_time(), src_loc ) );
            writer.reserved_space = client.reserved_space_for_begin_zone();
            _ = writer.commit();

            client.push_zone(src_loc);
        }

        return conn_id;
    }

    inline fn zone_end(ctx: ZoneCtxData) void {
        if (!ctx.active or client.core0_num_zones == 0) return;

        // TODO on-demand check connection ID
        if (!interface.is_connected()) {
            // TODO Needs CS?
            client.pop_zone();
            return;
        }

        outline_zone_end();
    }

    noinline fn outline_zone_end() void {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        var writer = interface.begin(2, cs);

        if (client.is_buffer_full()) {
            client.pop_zone();
            _ = client.try_resume_data(writer.start_time_tracy);
        } else {
            var thread_ctx_data: q.Packet(q.ThreadContext) = undefined;
            writer.thread_ctx(&thread_ctx_data);
            var end_data: q.ZoneEndData = undefined;
            writer.add_extent( end_data.set( writer.thread_time() ) );
            writer.reserved_space = client.reserved_space_for_end_zone();
            _ = writer.commit();

            client.pop_zone();
        }
    }

    /// A StateMachine which is recorded in Tracy and shown as its own thread
    /// register() must be called first, to initialize the state machine,
    /// then set_state() can be called to update the state.
    pub fn TrackedStateMachine(comptime State: type) type {
        return struct {
            state: State,
            track: client.TrackedSMEntry,

            pub inline fn register(self: *@This(), comptime name: [:0]const u8, comptime initial_state: State, comptime src: std.builtin.SourceLocation) void {
                self.register_color(name, initial_state, src, 0);
            }

            pub inline fn register_color(self: *@This(), comptime name: [:0]const u8, comptime initial_state: State, comptime src: std.builtin.SourceLocation, comptime color: u32) void {
                self.* = .{
                    .state = initial_state,
                    .track = .{
                        .name = external_string(name),
                        .srcloc = external_source_location(@tagName(initial_state), src, color),
                    },
                };

                outline_register(&self.track);
            }

            pub inline fn set_state(self: *@This(), comptime state: State, comptime src: std.builtin.SourceLocation) void {
                self.set_state_color(state, src, 0);
            }

            // TODO: Instead of taking @src() here, generate a bunch of static source locations for all the tag names, and pick
            // one based on a runtime state value passed here.
            pub inline fn set_state_color(self: *@This(), comptime state: State, comptime src: std.builtin.SourceLocation, comptime color: u32) void {
                self.state = state;
                self.track.srcloc = external_source_location(@tagName(state), src, color);

                if (!interface.is_connected()) return;

                outline_update_state(&self.track);
            }

        };
    }

    noinline fn outline_register(track: *client.TrackedSMEntry) void {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        if (!interface.is_connected() or client.is_buffer_full()) {
            client.add_pending_state(track);
            return;
        }

        var writer = interface.begin(1, cs);

        var packet: q.TrackedSMRegisterPacket = undefined;

        writer.add_extent( packet.set(track.name, writer.start_time_tracy, track.srcloc) );
        writer.has_core0_thread_ctx = false;

        writer.reserved_space = client.reserved_space_for_non_zone();

        if (writer.commit()) {
            @branchHint(.likely);
            client.add_tracked_state(track);
        } else {
            client.add_pending_state(track);
        }
    }

    noinline fn outline_add_to_dirty_without_cs(track: *client.TrackedSMEntry) void {

        // Need to check is_in_dirty again because it may have been set between
        // our first check and when we took the critical section.
        std.mem.doNotOptimizeAway(track);
        if (!track.is_in_dirty) {
            add_to_dirty(track);
        }
    }

    noinline fn add_to_dirty(track: *client.TrackedSMEntry) void {
        std.debug.assert(!track.is_in_dirty);
        track.is_in_dirty = true;
        track.next_dirty = client.core0_dirty_list;
        client.core0_dirty_list = track;
        client.core0_num_dirty += 1;
    }

    noinline fn outline_update_state(track: *client.TrackedSMEntry) void {
        const cs = microzig.interrupt.enter_critical_section();
        defer cs.leave();

        var writer = interface.begin(1, cs);

        if (client.is_buffer_full()) {
            _ = client.try_resume_data(writer.start_time_tracy);
        } else {
            var packet: q.TrackedSMUpdatePacket = undefined;
            writer.add_extent( packet.set(track.name, writer.start_time_tracy, track.srcloc) );
            writer.has_core0_thread_ctx = false; // Clear the thread context

            writer.reserved_space = client.reserved_space_for_non_zone();

            _ = writer.commit();
        }
    }
};

const EnumLiteral = @Type(.enum_literal);
fn field_slice(str: anytype, start: EnumLiteral, end: EnumLiteral) []const u8 {
    const Struct = @typeInfo(@TypeOf(str)).pointer.child;
    comptime { std.debug.assert(@typeInfo(Struct).@"struct".layout == .@"extern"); }
    const start_offset = @offsetOf(Struct, @tagName(start));
    const end_offset = @offsetOf(Struct, @tagName(end)) + @sizeOf(@TypeOf(@field(str, @tagName(end))));
    comptime { std.debug.assert(start_offset <= end_offset); }
    return std.mem.asBytes(str)[start_offset..end_offset];
}

pub fn register_parameter_callback(
    comptime Ctx: type,
    comptime cb: fn(*Ctx, u32, i32) void,
    ctx: *Ctx,
) void {
    client.param_callback_obj = ctx;
    client.param_callback_fn = struct {
        fn param_callback(ptr: ?*anyopaque, param_idx: u32, param_val: u32) void {
            cb(@ptrCast(ptr), param_idx, param_val);
        }
    }.param_callback;
}

pub fn register_parameter_callback_static(
    comptime cb: fn(u32, i32) void,
) void {
    client.param_callback_obj = null;
    client.param_callback_fn = struct {
        fn param_callback_static(ptr: ?*anyopaque, param_idx: u32, param_val: u32) void {
            _ = ptr;
            cb(param_idx, param_val);
        }
    }.param_callback_static;
}
