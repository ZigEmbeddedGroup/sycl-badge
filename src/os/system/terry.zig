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

inline fn external_string(comptime str: [:0]const u8) [*:0]const u8 {
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

        pub fn begin(comptime max_segments: usize) Writer(max_segments) {
            return .init_with_cs();
        }

        fn Writer(comptime max_segments: usize) type {
            return struct {
                start_time_tracy: i64,
                ref_time: i64,
                extents: [max_segments][]const u8 = undefined,
                num_extents: usize = 0,
                literal_bytes: usize = 0,
                reserved_space: usize = 0,
                cs: microzig.interrupt.CriticalSection,
                thread_ctx_data: q.Packet(q.ThreadContext) = undefined,
                has_thread_ctx: bool,

                fn init_with_cs() @This() {
                    const cs = microzig.interrupt.enter_critical_section();
                    return .{
                        .cs = cs,
                        .start_time_tracy = client.get_time_core0(cs),
                        .ref_time = client.core0_thread_ref_time,
                        .has_thread_ctx = client.has_core0_thread_context,
                    };
                }

                pub fn add_extent(w: *@This(), data: []const u8) void {
                    std.debug.assert(w.num_extents < max_segments);
                    w.extents[w.num_extents] = data;
                    w.num_extents += 1;
                    w.literal_bytes += data.len;
                }

                pub fn thread_ctx(w: *@This()) void {
                    if (!w.has_thread_ctx) {
                        w.thread_ctx_data = .{ .ty = .ThreadContext, .data = .{ .thread = client.core0_thread_id } };
                        w.add_extent(std.mem.asBytes(&w.thread_ctx_data));
                        w.ref_time = 0;
                        w.has_thread_ctx = true;
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

                pub fn commit(w: *@This()) void {
                    const layout = client.wire_layout(w.literal_bytes);
                    if (client.send.available_space() >= layout.total_bytes + w.reserved_space) {
                        var cursor = client.write_header_assume_available(layout);
                        for (w.extents[0..w.num_extents]) |extent| {
                            cursor.write_assume_available(extent);
                        }
                        cursor.commit();

                        client.has_core0_thread_context = w.has_thread_ctx;
                        client.core0_thread_ref_time = w.ref_time;
                    } else {
                        client.data_overflow(w.start_time_tracy);
                    }
                }

                pub fn end(w: *@This()) void {
                    w.cs.leave();
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
        var writer = interface.begin(2);
        defer writer.end();

        const conn_id = interface.get_connection_id();

        if (client.is_buffer_full()) {
            client.push_zone(src_loc);
            _ = client.try_resume_data(writer.start_time_tracy);
        } else {
            writer.thread_ctx();
            var begin_data: q.ZoneBeginData = undefined;
            writer.add_extent( begin_data.set( writer.thread_time(), src_loc ) );
            writer.reserved_space = client.reserved_space_for_begin_zone();
            writer.commit();

            client.push_zone(src_loc);
        }

        return conn_id;
    }

    inline fn zone_end(ctx: ZoneCtxData) void {
        if (!ctx.active or client.core0_num_zones == 0) return;

        // TODO on-demand check connection ID
        if (!interface.is_connected()) {
            client.pop_zone();
            return;
        }

        outline_zone_end();
    }

    noinline fn outline_zone_end() void {
        var writer = interface.begin(2);
        defer writer.end();

        if (client.is_buffer_full()) {
            client.pop_zone();
            _ = client.try_resume_data(writer.start_time_tracy);
        } else {
            writer.thread_ctx();
            var end_data: q.ZoneEndData = undefined;
            writer.add_extent( end_data.set( writer.thread_time() ) );
            writer.reserved_space = client.reserved_space_for_end_zone();
            writer.commit();

            client.pop_zone();
        }
    }
};

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
