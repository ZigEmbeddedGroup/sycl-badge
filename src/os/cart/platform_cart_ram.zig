//! OS Cart Platform Wrapper
//!

const std = @import("std");
const root = @import("root");
const cart_api = @import("api.zig");
const abi = @import("os_abi.zig");
const q = @import("tracy_protocol");

const ipc_data = abi.ipc_data;

const start_code = struct {
    // Variables exported by the linker script
    extern var __bss_start__: u8;
    extern var __bss_end__: u8;

    export const cart_descriptor: abi.CartDescriptorTable linksection(".cart_descriptor") = .{
        .bss_start = &__bss_start__,
        .bss_end = &__bss_end__,
        .entry_point = &_start,
    };
};

pub fn export_start_code() void {
    comptime {
        _ = start_code;
    }
}

export fn _start() callconv(.c) void {
    // Sync the timer with the other core for tracy
    os_align_cycles();

    root.start();
    while (true) {
        // Keep the cycle counter accurate
        // TODO we could record uS times around each cart call,
        // to handle any large drift.
        _ = cycles();

        root.update();
        // Signal Core 0 that this frame is complete and wait for the
        // LCD flush to finish before starting the next frame.
        cart_api.present();
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Inputs and Outputs                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn micros_since_boot() u64 {
    const TIMER0_TIMEHR: *volatile u32 = @ptrFromInt(0x400b0008);
    const TIMER0_TIMELR: *volatile u32 = @ptrFromInt(0x400b000c);
    const lr = TIMER0_TIMELR.*; // always lr first
    const hr = TIMER0_TIMEHR.*;
    return (@as(u64, hr) << 32) | lr;
}

/// Volatile: kernel (Core 0) writes button state every frame; cart must read fresh each access.
pub const controls: *const volatile cart_api.Controls = &ipc_data.controls;
pub const light_level: *volatile u12 = @ptrCast(&ipc_data.light_level);
pub const neopixels: *volatile [5]cart_api.NeopixelColor = &ipc_data.neopixels;
pub const user_led: *volatile bool = &ipc_data.user_led;
pub const battery_level: *volatile u12 = @ptrCast(&ipc_data.battery_level);

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Frame Management                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const framebuffers: [2]cart_api.FramebufferPtr = .{ @volatileCast(&ipc_data.framebuffers[0]), @volatileCast(&ipc_data.framebuffers[1]) };

var vsync_updated: bool = false;
var has_in_flight_frame: bool = false;
var present_timeout_events: u32 = 0;
const present_wait_time_limit: u32 = 500_000; // 0.5 seconds

pub fn set_vsync_disabled() void {
    ipc_data.vsync_flags = 0;
    vsync_updated = true;
}

pub fn set_vsync_enabled(target_frame_ms: f32) void {
    ipc_data.vsync_frame_ms = target_frame_ms;
    ipc_data.vsync_flags = 1;
    vsync_updated = true;
}

pub fn set_vsync_dynamic() void {
    set_vsync_enabled(0);
}

pub fn present_and_acquire(draw_buffer_index: u1, dirty_rect: cart_api.Rect8, clear_color: ?cart_api.DisplayColor) void {
    // RP2350 SIO FIFO registers (same address on both cores, core-local view)
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const SIO_FIFO_RD: *volatile u32 = @ptrFromInt(0xD0000058);

    const FIFO_RDY: u32 = 1 << 1; // write-FIFO ready (space available)
    const FIFO_VLD: u32 = 1 << 0; // read-FIFO valid (data available)

    // Message constants — must match mailbox.MessageType values in the OS.
    const FRAMEBUFFER_DONE: u32 = 0x25000002;

    // Drain completion messages to release the in-flight slot.
    while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
        const reply = SIO_FIFO_RD.*;
        if (reply == FRAMEBUFFER_DONE) {
            has_in_flight_frame = false;
        }
    }

    if (has_in_flight_frame) {
        const spin_start_time = micros_since_boot();
        while (has_in_flight_frame) {
            while (SIO_FIFO_ST.* & FIFO_VLD == 0) {
                asm volatile ("nop");
                const now = micros_since_boot();
                if (now - spin_start_time >= present_wait_time_limit) {
                    // Stop waiting rather than deadlocking Core 1 forever.
                    present_timeout_events +%= 1;
                    // Keep trace volume low: log only occasionally.
                    if ((present_timeout_events & 0x3f) == 0x01) {
                        trace("[PRESENT] timeout waiting FRAMEBUFFER_DONE");
                    }
                    return;
                }
            }
            const reply = SIO_FIFO_RD.*;
            if (reply == FRAMEBUFFER_DONE) {
                has_in_flight_frame = false;
            }
        }
    }

    const message: abi.PresentFlags = .{
        .framebuffer_index = draw_buffer_index,
        .has_dirty_rect = dirty_rect.has_area(),
        .vsync_updated = vsync_updated,
        .clear_frame = clear_color != null,
    };
    vsync_updated = false;

    ipc_data.dirty_rect = dirty_rect;

    if (clear_color) |color| {
        ipc_data.clear_color = .from_color(color);
    }

    const spin_start_time = micros_since_boot();
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
        asm volatile ("nop");
        const now = micros_since_boot();
        if (now - spin_start_time >= present_wait_time_limit) {
            present_timeout_events +%= 1;
            if ((present_timeout_events & 0x3f) == 0x01) {
                trace("[PRESENT] timeout waiting FIFO_RDY");
            }
            return;
        }
    }

    // Ensure all framebuffer and IPC writes are available for the other core
    asm volatile ("dmb" ::: .{ .memory = true });
    // Send the message
    SIO_FIFO_WR.* = @bitCast(message);
    // SEV to wake Core 0 in case it's in WFE.
    asm volatile ("sev");

    has_in_flight_frame = true;
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn tone2(options: cart_api.Tone2Options) void {
    const CART_TONE: u32 = 0x27000000;
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const FIFO_RDY: u32 = 1 << 1;

    ipc_data.tone_freq = options.frequency;
    ipc_data.tone_duration = options.duration;
    ipc_data.tone_volume = options.volume;
    ipc_data.tone_flags = @bitCast(options.flags);

    while (SIO_FIFO_ST.* & FIFO_RDY == 0) asm volatile ("nop");
    SIO_FIFO_WR.* = CART_TONE;
    asm volatile ("sev");
}

/// Adjust the volume of all audio, 0.0 - 1.0. This is a perceptually
/// linear scale from about -50dB to 0dB adjustment from the maximum
/// speaker volume.
pub fn set_global_volume(volume: f32) void {
    const CART_VOLUME: u32 = 0x29000000;
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const FIFO_RDY: u32 = 1 << 1;

    ipc_data.global_volume = volume;

    while (SIO_FIFO_ST.* & FIFO_RDY == 0) asm volatile ("nop");
    SIO_FIFO_WR.* = CART_VOLUME;
    asm volatile ("sev");
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Profiling Functions                                                       │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// A 64 bit offset to align core 1 times with core 0 times. This is set before
/// cart startup by the OS.
var cycles_offset: i64 = 0;
var last_cycles: u32 = 0;
/// Cycle count for profiling. This must be called at least once every 30
/// seconds to maintain accuracy. The OS will call it before every update() to
/// maintain this, but if update() ever takes more than 30 seconds there may be
/// mistakes.
pub fn cycles() i64 {
    const DWT_CYCCNT: *volatile u32 = @ptrFromInt(0xe0001004);
    const cycles_low = DWT_CYCCNT.*;
    if (cycles_low < last_cycles) {
        @branchHint(.unlikely);
        cycles_offset += (1 << 32);
    }
    last_cycles = cycles_low;
    return cycles_offset + cycles_low;
}

/// Aligns core 0 and core 1 cycle counts for profiling. If you have an
/// extremely long update (30+ seconds), or you put core 1 to sleep, you can
/// call this to resynchronize and restore correct timing in tracy. This
/// function must wait until the OS is ready to synchronize timing, which could
/// take several milliseconds in the worst case.
noinline fn os_align_cycles() void {
    // RP2350 SIO FIFO registers (same address on both cores, core-local view)
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const SIO_FIFO_RD: *volatile u32 = @ptrFromInt(0xD0000058);

    const FIFO_RDY: u32 = 1 << 1; // write-FIFO ready (space available)
    const FIFO_VLD: u32 = 1 << 0; // read-FIFO valid (data available)

    // Message constants — must match mailbox.MessageType values in the OS.
    const SYNC_TIME_REQ_CLR: u32 = 0x2a000001;
    const SYNC_TIME_ACK_CLR: u32 = 0x2a000002;
    const SYNC_TIME_REQ_TIME: u32 = 0x2a000003;

    // Clear OS FIFO
    while (SIO_FIFO_ST.* & FIFO_VLD != 0) {
        _ = SIO_FIFO_RD.*;
    }

    // Tell OS to clear its fifo
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {}
    SIO_FIFO_WR.* = SYNC_TIME_REQ_CLR;

    // Wait for OS to acknowledge clearing its fifo
    while (true) {
        while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
        if (SIO_FIFO_RD.* == SYNC_TIME_ACK_CLR) break;
    }

    // Send time request for immediate processing
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {}
    SIO_FIFO_WR.* = SYNC_TIME_REQ_TIME;

    // Read cycle count at approx same time as other core
    const DWT_CYCCNT: *volatile u32 = @ptrFromInt(0xe0001004);
    const cycles_low = DWT_CYCCNT.*;

    while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
    const time_high = SIO_FIFO_RD.*;

    while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
    const time_low = SIO_FIFO_RD.*;

    const target_time: i64 = @bitCast(@as(u64, time_high) << 32 | time_low);
    cycles_offset = target_time - cycles_low;
    last_cycles = cycles_low;
}

const external_linksection = ".rodata";

const tracy_ring: [*]u8 = @volatileCast(&ipc_data.tracy_ring);
const tracy_atomic_write_ctrl: *u32 = @volatileCast(&ipc_data.tracy_write_ctrl);
const tracy_atomic_read_pos: *u32 = @volatileCast(&ipc_data.tracy_read_pos);
const tracy_spinlock: *u32 = @volatileCast(&ipc_data.tracy_spinlock);
var tracy_ref_time: i64 = 0;

fn StringWrap(comptime str: [:0]const u8) type {
    return struct {
        const bytes linksection(external_linksection) = str[0..str.len :0].*;
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

inline fn ring_available(read_pos: u16, write_pos: u16, size: u16) u16 {
    return (read_pos -% 1 -% write_pos) & (size - 1);
}

const RingBufferWriter = struct {
    buf: [*]u8,
    size: u16,
    write_pos: u16,
    read_pos: u16,

    inline fn available(w: *RingBufferWriter) u16 {
        return ring_available(w.read_pos, w.write_pos, w.size);
    }

    inline fn write_assume_available(w: *RingBufferWriter, bytes: []const u8) void {
        const first_len = @min(w.size - w.write_pos, bytes.len);
        @memcpy(w.buf[w.write_pos..][0..first_len], bytes[0..first_len]);
        if (first_len < bytes.len) {
            const second_len = bytes.len - first_len;
            @memcpy(w.buf[0..second_len], bytes[first_len..]);
        }
        w.write_pos = @intCast((w.write_pos +% bytes.len) & (w.size - 1));
    }
};

inline fn cmpxchg_strong(ptr: *volatile u32, expected: u32, new: u32) ?u32 {
    abi.spin_lock_acquire(tracy_spinlock);
    defer abi.spin_lock_release(tracy_spinlock);

    const value = ptr.*;
    if (value != expected) {
        @branchHint(.unlikely);
        return value;
    }
    ptr.* = new;
    return null;

    // var actual: u32 = undefined;
    // var failure: u32 = undefined;
    // asm volatile (
    //     \\ 1: ldaex %[actual], [%[ptr]]
    //     \\    movs %[failure], #1
    //     \\    cmp %[actual], %[expected]
    //     \\    bne 1f
    //     \\    strex %[failure], %[new], [%[ptr]]
    //     \\    cmp %[failure], #0
    //     \\    bne 1b
    //     \\    dmb
    //     \\ 1:
    //     : [actual] "=&r" (actual)
    //     , [failure] "=&r" (failure)
    //     : [ptr] "r" (ptr)
    //     , [expected] "r" (expected)
    //     , [new] "r" (new)
    //     : .{ .memory = true }
    // );

    // return if (failure != 0) actual else null;
    // return @cmpxchgStrong(T, ptr, expected, new, success, fail);
}

inline fn write_tracy_data_with_delta_time(time: i64, record_block: bool, data_wrapper: anytype) bool {
    var write_ctrl_word = @atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst);
    while (true) {
        var write_ctrl: abi.TracyAtomicWriteCtrl = @bitCast(write_ctrl_word);
        if (write_ctrl.inactive()) return false;

        var ref_time = tracy_ref_time;
        if (!write_ctrl.has_thread_ctx) {
            @branchHint(.unlikely);
            ref_time = 0;
            write_ctrl.has_thread_ctx = true;
        }

        {
            const delta = time - ref_time;
            ref_time = time;

            var writer: RingBufferWriter = .{
                .buf = tracy_ring,
                .size = abi.tracy_buffer_size,
                .write_pos = write_ctrl.write_pos,
                .read_pos = @truncate(@atomicLoad(u32, tracy_atomic_read_pos, .seq_cst)),
            };

            const bytes = data_wrapper.set(delta);

            if (writer.available() < bytes.len) {
                @branchHint(.unlikely);

                if (!record_block) continue;
                return write_tracy_data_blocking_with_delta_time(time, write_ctrl.write_pos, data_wrapper);
            }

            writer.write_assume_available(bytes);

            write_ctrl.write_pos = writer.write_pos;
        }

        write_ctrl_word = if (cmpxchg_strong(tracy_atomic_write_ctrl, write_ctrl_word, @bitCast(write_ctrl))) |v| v else {
            tracy_ref_time = ref_time;
            return true;
        };
    }
}

noinline fn write_tracy_data_blocking_with_delta_time(time: i64, write_pos: u16, data_wrapper: anytype) bool {
    const src_loc = external_source_location("Too Much Data!", @src(), 0xDF0F3F);

    // TODO handle graceful data loss rather than blocking
    const space_needed = data_wrapper.max_size() + @sizeOf(q.Packet(q.ZoneBegin16)) + @sizeOf(q.ZoneEndData);
    while (true) {
        // Check if we have space
        const read_pos = @atomicLoad(u32, tracy_atomic_read_pos, .acquire);
        if (space_needed <= ring_available(@intCast(read_pos), write_pos, abi.tracy_buffer_size)) break;

        // Check if server disconnected
        var new_write_ctrl: abi.TracyAtomicWriteCtrl = @bitCast(@atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst));
        if (new_write_ctrl.inactive()) return false;
    }

    // We have space! Record the new delta.
    // It might be impossible for this loop to actually loop,
    // but we have it just in case.
    var write_ctrl_word = @atomicLoad(u32, tracy_atomic_write_ctrl, .seq_cst);
    while (true) {
        var write_ctrl: abi.TracyAtomicWriteCtrl = @bitCast(write_ctrl_word);
        if (write_ctrl.inactive()) return false;

        var ref_time = tracy_ref_time;
        if (!write_ctrl.has_thread_ctx) {
            @branchHint(.unlikely);
            ref_time = 0;
            write_ctrl.has_thread_ctx = true;
        }

        {
            const delta = time - ref_time;
            ref_time = time;

            var writer: RingBufferWriter = .{
                .buf = tracy_ring,
                .size = abi.tracy_buffer_size,
                .write_pos = write_ctrl.write_pos,
                .read_pos = @truncate(@atomicLoad(u32, tracy_atomic_read_pos, .seq_cst)),
            };

            const bytes = data_wrapper.set(delta);

            writer.write_assume_available(bytes);

            const begin = q.packet(.ZoneBegin16, .{ .time = 0, .srcloc = @intFromPtr(src_loc) });
            writer.write_assume_available(std.mem.asBytes(&begin));

            var end: q.ZoneEndData = undefined;
            const post_time = cycles();
            writer.write_assume_available(end.set(post_time - ref_time));
            ref_time = post_time;

            write_ctrl.write_pos = writer.write_pos;
        }

        write_ctrl_word = if (cmpxchg_strong(tracy_atomic_write_ctrl, write_ctrl_word, @bitCast(write_ctrl))) |v| v else {
            tracy_ref_time = ref_time;
            return true;
        };
    }
}

pub noinline fn outline_zone_begin_static(time: i64, record_block: bool, src_loc: *const q.SourceLocationData) bool {
    const ZoneBegin = struct {
        data: q.ZoneBeginData = undefined,
        src_loc: *const q.SourceLocationData,

        pub fn set(self: *@This(), dt: i64) []const u8 {
            return self.data.set(dt, self.src_loc);
        }

        pub fn max_size(_: *@This()) usize {
            return @sizeOf(q.ZoneBeginData);
        }
    };

    var data: ZoneBegin = .{ .src_loc = src_loc };
    return write_tracy_data_with_delta_time(time, record_block, &data);
}

pub noinline fn outline_zone_end(time: i64, record_block: bool) void {
    var data: q.ZoneEndData = undefined;
    _ = write_tracy_data_with_delta_time(time, record_block, &data);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn rand() u32 {
    // RP2350 ROSC STATUS register: bit 16 = RANDOMBIT
    const ROSC_STATUS: *const volatile u32 = @ptrFromInt(0x4006000C);
    var result: u32 = 0;
    for (0..32) |_| {
        result = (result << 1) | ((ROSC_STATUS.* >> 16) & 1);
    }
    return result;
}

pub fn trace(x: []const u8) void {
    const TRACE_BUF_SIZE: usize = 128;
    const CART_TRACE: u8 = 0x26;
    const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
    const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
    const FIFO_RDY: u32 = 1 << 1;

    const len: u24 = @intCast(@min(x.len, TRACE_BUF_SIZE - 1));
    const buf: [*]volatile u8 = &ipc_data.trace_buf;
    for (x[0..len], 0..) |c, i| buf[i] = c;
    buf[len] = 0;

    const msg: u32 = (@as(u32, CART_TRACE) << 24) | len;
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {
        asm volatile ("nop");
    }
    SIO_FIFO_WR.* = msg;
    asm volatile ("sev");
}
