const std = @import("std");
pub const abi = @import("sim_abi");
const sdl = @import("sdl3");
const root = @import("root");

extern fn cart_must_call_export_start_code() void;
extern var simulator_io_block: abi.SimulatorIO;

var performance_period_us: f64 = 0;
var cart_start_time: u64 = 0;

var cart_flags_mutex: std.Io.Mutex = .init;
var cart_flags_updated: std.Io.Condition = .init;
var cart_flags_raw: u32 = 0;

var cart_thread: std.Io.Future(i32) = undefined;

var cart_running: bool = false;
var cart_stopped: bool = false;

pub fn sim_thread_check_cart_stopped() bool {
    return @atomicLoad(bool, &cart_stopped, .seq_cst);
}

pub fn sim_thread_update_controls(controls: abi.Controls) void {
    @atomicStore(abi.Controls, &simulator_io_block.controls, controls, .seq_cst);
}

pub fn sim_thread_start_cart_thread() void {
    @atomicStore(bool, &cart_running, true, .seq_cst);
    @atomicStore(bool, &cart_stopped, false, .seq_cst);
    cart_thread = root.io.concurrent(cart_thread_func, .{null}) catch @panic("System io doesn't support concurrency");
}

pub fn sim_thread_join_cart_thread() void {
    @atomicStore(bool, &cart_running, false, .seq_cst);
    _ = cart_thread.cancel(root.io);
}

pub fn sim_thread_check_flags(flags: u32) bool {
    cart_flags_mutex.lockUncancelable(root.io);
    defer cart_flags_mutex.unlock(root.io);

    return (cart_flags_raw & flags) == flags;
}

pub fn sim_thread_clear_flags(flags: u32) void {
    {
        cart_flags_mutex.lockUncancelable(root.io);
        defer cart_flags_mutex.unlock(root.io);

        cart_flags_raw &= ~flags;
    }

    cart_flags_updated.signal(root.io);
}

pub fn sim_thread_consume_audio(buf: []u8) usize {
    var written: u32 = 0;
    const ptr = if (simulator_io_block.audio_buffer_ptr) |ptr| @as([*]u8, @ptrCast(ptr)) else {
        return 0;
    };
    const len = simulator_io_block.audio_buffer_len;
    const tail = @atomicLoad(u32, &simulator_io_block.audio_buffer_tail, .unordered);
    const head = @atomicLoad(u32, &simulator_io_block.audio_buffer_head, .acquire);
    if (tail == head) {
        return 0;
    }

    if (tail <= head) {
        written = @min(buf.len, head - tail);
        @memcpy(buf[0..written], ptr + tail);
        @atomicStore(u32, &simulator_io_block.audio_buffer_tail, tail + written, .release);
    } else if (tail + buf.len <= len) {
        written = @intCast(buf.len);
        @memcpy(buf[0..written], ptr + tail);
        const new_tail = if (tail + buf.len == len) 0 else tail + buf.len;
        @atomicStore(u32, &simulator_io_block.audio_buffer_tail, @intCast(new_tail), .release);
    } else {
        written = len - tail;
        @memcpy(buf[0..written], ptr + tail);
        const remain = @min(head, buf.len - written);
        if (remain > 0) {
            @memcpy(buf[written..][0..remain], ptr);
            written += remain;
        }
        @atomicStore(u32, &simulator_io_block.audio_buffer_tail, remain, .release);
    }

    return written;
}

pub fn sim_thread_get_volume() ?f32 {
    if (sim_thread_check_flags(abi.FLAG_AUDIO_VOLUME)) {
        const volume = simulator_io_block.audio_volume;
        sim_thread_clear_flags(abi.FLAG_AUDIO_VOLUME);
        return volume;
    }
    return null;
}

pub const FramebufferData = struct {
    framebuffer: *abi.Framebuffer,
    dirty_rect: abi.Rect8,
    clear_color: ?abi.DisplayColor,
};

pub fn sim_thread_acquire_framebuffer() ?FramebufferData {
    if (!sim_thread_check_flags(abi.FLAG_PRESENT_FRAME | abi.FLAG_PRESENT_METADATA)) {
        return null;
    }

    const result: FramebufferData = .{
        .framebuffer = &simulator_io_block.framebuffers[simulator_io_block.framebuffer_index],
        .dirty_rect = simulator_io_block.dirty_rect,
        .clear_color = null,
    };

    sim_thread_clear_flags(abi.FLAG_PRESENT_METADATA);

    return result;
}

pub fn sim_thread_release_framebuffer() void {
    sim_thread_clear_flags(abi.FLAG_PRESENT_FRAME);
}

fn cart_thread_func(_: ?*anyopaque) callconv(.c) i32 {
    // Init the IO Block
    @memset(std.mem.asBytes(&simulator_io_block), 0);
    simulator_io_block.light_level = ~@as(u12, 0);
    simulator_io_block.battery_level = ~@as(u12, 0);
    simulator_io_block.api = &sim_api;

    performance_period_us = 1_000_000.0 / @as(f64, @floatFromInt(sdl.SDL_GetPerformanceFrequency()));
    cart_start_time = sdl.SDL_GetPerformanceCounter();

    // Call cart main
    cart_must_call_export_start_code();

    @atomicStore(bool, &cart_stopped, true, .seq_cst);

    return 0;
}

const sim_api: abi.SimulatorAPI = .{
    .is_running = &cart_is_running,
    .micros_since_boot = &cart_micros_since_boot,
    .check_flags = &cart_check_flags,
    .set_flags = &cart_set_flags,
    .wait_for_flags = &cart_wait_for_flags,
};

fn cart_mark_canceled() void {
    @atomicStore(bool, &cart_running, false, .seq_cst);
}

fn cart_is_running() callconv(.c) bool {
    root.io.checkCancel() catch cart_mark_canceled();
    return @atomicLoad(bool, &cart_running, .seq_cst);
}

fn cart_micros_since_boot() callconv(.c) u64 {
    const micros: f64 = @as(f64, @floatFromInt(sdl.SDL_GetPerformanceCounter() -% cart_start_time)) * performance_period_us;
    return @intFromFloat(micros);
}

fn cart_check_flags(flags: u32) callconv(.c) bool {
    cart_flags_mutex.lock(root.io) catch {
        cart_mark_canceled();
        return true;
    };
    defer cart_flags_mutex.unlock(root.io);

    return (cart_flags_raw & flags == 0);
}

fn cart_set_flags(flags: u32) callconv(.c) void {
    cart_flags_mutex.lock(root.io) catch {
        cart_mark_canceled();
        return;
    };
    defer cart_flags_mutex.unlock(root.io);

    cart_flags_raw |= flags;
}

fn cart_wait_for_flags(flags: u32) callconv(.c) void {
    cart_flags_mutex.lock(root.io) catch {
        cart_mark_canceled();
        return;
    };
    defer cart_flags_mutex.unlock(root.io);

    while (cart_flags_raw & flags != 0) {
        cart_flags_updated.wait(root.io, &cart_flags_mutex) catch {
            cart_mark_canceled();
            return;
        };
    }
}
