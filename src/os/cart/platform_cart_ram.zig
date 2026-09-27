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
    // Drain completion messages to release the in-flight slot.
    while (fifo_try_recv()) |msg| {
        handle_os_message(msg);
    }

    if (has_in_flight_frame) {
        @branchHint(.unlikely); // Not actually unlikely, but we want the other
        // path to be fast, and this path can be slow.
        const spin_start_time = micros_since_boot();
        while (true) {
            if (fifo_try_recv()) |msg| {
                handle_os_message(msg);
                if (!has_in_flight_frame) break;
            }

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

            busy_wait();
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
        ipc_data.clear_color = color;
    }

    // Ensure all framebuffer and IPC writes are available for the other core
    asm volatile ("dmb" ::: .{ .memory = true });
    // Send the message
    fifo_send(@bitCast(message));

    has_in_flight_frame = true;
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

/// Adjust the volume of all audio, 0.0 - 1.0. This is a perceptually
/// linear scale from about -50dB to 0dB adjustment from the maximum
/// speaker volume.
pub fn set_global_volume(volume: f32) void {
    ipc_data.global_volume = volume;

    asm volatile ("dmb" ::: .{ .memory = true });

    fifo_send(abi.CART_VOLUME);
}

var audio_running = false;

pub fn audio_set_buffer(comptime T: type, buffer: []align(8) T) void {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }

    if (audio_running) {
        fifo_send(abi.CART_STOP_AUDIO);
        while (audio_running) {
            if (fifo_try_recv()) |msg| {
                handle_os_message(msg);
            }
        }
    }

    ipc_data.audio_buffer_ptr = if (buffer.len > 0) buffer.ptr else null;
    ipc_data.audio_buffer_len = @intCast(buffer.len);
    ipc_data.audio_buffer_tail = 0;
    ipc_data.audio_buffer_head = 0;

    asm volatile ("dmb" ::: .{ .memory = true });

    if (buffer.len > 0) {
        audio_running = true;
        fifo_send(abi.CART_START_AUDIO);
    } else {
        audio_running = false;
    }
}

pub fn audio_get_buffer(comptime T: type) ?[]T {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }

    if (ipc_data.audio_buffer_ptr) |ptr| {
        const byte_ptr: [*]T = @ptrCast(ptr);
        const tail = ipc_data.audio_buffer_tail;
        const head = ipc_data.audio_buffer_head;

        if (tail <= head) {
            const slice = byte_ptr[head .. ipc_data.audio_buffer_len - @intFromBool(tail == 0)];
            return if (slice.len == 0) null else slice;
        } else if (tail > head + 1) {
            return byte_ptr[head .. tail - 1];
        }
    }
    return null;
}

pub fn audio_submit_samples(num: usize) void {
    std.debug.assert(ipc_data.audio_buffer_ptr != null); // audio_set_buffer must have been called
    const len = ipc_data.audio_buffer_len;
    const tail = ipc_data.audio_buffer_tail;
    const head = ipc_data.audio_buffer_head;
    const available = if (tail <= head) len - 1 - (head - tail) else tail - head - 1;
    std.debug.assert(len <= available); // audio_submit_samples called with more than could be filled from audio_get_buffer
    var new_head = head + @as(u32, @intCast(num));
    while (new_head >= len) {
        new_head -= len;
    }
    asm volatile ("dmb" ::: .{ .memory = true });
    ipc_data.audio_buffer_head = new_head;
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
    // Clear OS FIFO
    while (fifo_try_recv()) |msg| {
        handle_os_message(msg);
    }

    // Tell OS to clear its fifo
    fifo_send(abi.SYNC_TIME_REQ_CLR);

    // Wait for OS to acknowledge clearing its fifo
    while (true) {
        const msg = fifo_recv();
        if (msg == abi.SYNC_TIME_ACK_CLR) break;

        handle_os_message(msg);
    }

    // Send time request for immediate processing
    fifo_send_fast(abi.SYNC_TIME_REQ_TIME);

    // Read cycle count at approx same time as other core
    const DWT_CYCCNT: *volatile u32 = @ptrFromInt(0xe0001004);
    const cycles_low = DWT_CYCCNT.*;

    const time_high = fifo_recv();
    const time_low = fifo_recv();

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
    const TRACE_BUF_SIZE: usize = ipc_data.trace_buf.len;

    const len: u24 = @intCast(@min(x.len, TRACE_BUF_SIZE - 1));
    const buf: [*]volatile u8 = &ipc_data.trace_buf;
    for (x[0..len], 0..) |c, i| buf[i] = c;
    buf[len] = 0;

    const msg: u32 = (@as(u32, abi.CART_TRACE) << 24) | len;
    fifo_send(msg);
}

// RP2350 SIO FIFO registers (same address on both cores, core-local view)
const SIO_FIFO_ST: *volatile u32 = @ptrFromInt(0xD0000050);
const SIO_FIFO_WR: *volatile u32 = @ptrFromInt(0xD0000054);
const SIO_FIFO_RD: *volatile u32 = @ptrFromInt(0xD0000058);

const FIFO_RDY: u32 = 1 << 1; // write-FIFO ready (space available)
const FIFO_VLD: u32 = 1 << 0; // read-FIFO valid (data available)

// Send a message to the OS. May block up to a few hundred uS
// waiting for the OS to clear its queue. Note that this
// function may drain messages from the OS as well. If you
// are expecting a particular protocol and you know that the
// OS is not going to fill its fifo, use fifo_send_fast instead.
fn fifo_send(msg: u32) void {
    while (true) {
        const status = SIO_FIFO_ST.*;
        if (status & FIFO_RDY != 0) {
            @branchHint(.likely);
            break;
        }
        // To avoid a potential deadlock where both
        // cores are waiting on a full queue, drain
        // messages while trying to send.
        if (status & FIFO_VLD != 0) {
            handle_os_message(SIO_FIFO_RD.*);
        }
    }
    SIO_FIFO_WR.* = msg;
    asm volatile ("sev");
}

inline fn fifo_send_fast(msg: u32) void {
    while (SIO_FIFO_ST.* & FIFO_RDY == 0) {}
    SIO_FIFO_WR.* = msg;
}

fn fifo_recv() u32 {
    while (SIO_FIFO_ST.* & FIFO_VLD == 0) {}
    return SIO_FIFO_RD.*;
}

fn fifo_try_recv() ?u32 {
    if (SIO_FIFO_ST.* & FIFO_VLD == 0) return null;
    return SIO_FIFO_RD.*;
}

fn handle_os_message(msg: u32) void {
    if (msg == abi.FRAMEBUFFER_DONE) {
        has_in_flight_frame = false;
    }
    if (msg == abi.OS_ACK_STOP_AUDIO) {
        audio_running = false;
    }
}

fn busy_wait() void {
    // If we need to do something like servicing audio while waiting for
    // vsync, we could add that here.
}
