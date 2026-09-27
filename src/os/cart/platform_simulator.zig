//! This file contains data layouts that are used by both the cart
//! and the simulator for cross-communication. The two must be kept in sync!

const std = @import("std");
const cart_api = @import("api.zig");
const abi = @import("sim_abi.zig");

const start_code = struct {
    const root = @import("root");

    export fn cart_must_call_export_start_code() void {
        root.start();
        while (simulator_io_block.api.is_running()) {
            root.update();
            cart_api.present();
        }
    }
};

pub fn export_start_code() void {
    comptime {
        _ = start_code;
        _ = &simulator_io_block;
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Inputs and Outputs                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

export var simulator_io_block: abi.SimulatorIO = undefined;

pub fn micros_since_boot() u64 {
    return simulator_io_block.api.micros_since_boot();
}

pub const neopixels: *volatile [5]cart_api.NeopixelColor = &simulator_io_block.neopixels;
pub const user_led: *volatile bool = &simulator_io_block.user_led;

pub const controls: *const volatile cart_api.Controls = &simulator_io_block.controls;
pub const light_level: *const volatile u12 = &simulator_io_block.light_level;
pub const battery_level: *const volatile u12 = &simulator_io_block.battery_level;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Frame Management                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub const framebuffers: [2]cart_api.FramebufferPtr = .{ &simulator_io_block.framebuffers[0], &simulator_io_block.framebuffers[1] };

pub fn present_and_acquire(draw_buffer_index: u1, dirty_rect: cart_api.Rect8, clear_color: ?cart_api.DisplayColor) void {
    simulator_io_block.api.wait_for_flags(abi.FLAG_PRESENT_METADATA | abi.FLAG_PRESENT_FRAME);

    simulator_io_block.framebuffer_index = draw_buffer_index;
    simulator_io_block.dirty_rect = dirty_rect;
    if (clear_color) |clear| {
        simulator_io_block.clear_color = clear;
    }

    simulator_io_block.api.set_flags(abi.FLAG_PRESENT_METADATA | abi.FLAG_PRESENT_FRAME);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn set_global_volume(volume: f32) void {
    simulator_io_block.api.wait_for_flags(abi.FLAG_AUDIO_VOLUME);
    simulator_io_block.audio_volume = volume;
    simulator_io_block.api.set_flags(abi.FLAG_AUDIO_VOLUME);
}

pub fn audio_set_buffer(comptime T: type, buffer: []align(8) T) void {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }

    simulator_io_block.api.set_flags(abi.FLAG_STOP_AUDIO);
    simulator_io_block.api.wait_for_flags(abi.FLAG_STOP_AUDIO);

    simulator_io_block.audio_buffer_ptr = if (buffer.len > 0) buffer.ptr else null;
    simulator_io_block.audio_buffer_len = @intCast(buffer.len);
    @atomicStore(u32, &simulator_io_block.audio_buffer_tail, 0, .seq_cst);
    @atomicStore(u32, &simulator_io_block.audio_buffer_head, 0, .seq_cst);

    if (buffer.len > 0) {
        simulator_io_block.api.set_flags(abi.FLAG_START_AUDIO);
    }
}

pub fn audio_get_buffer(comptime T: type) ?[]T {
    if (T != u8) {
        @compileError("Only u8 samples are currently supported.");
    }

    if (simulator_io_block.audio_buffer_ptr) |ptr| {
        const byte_ptr: [*]T = @ptrCast(ptr);
        const tail = @atomicLoad(u32, &simulator_io_block.audio_buffer_tail, .acquire);
        const head = @atomicLoad(u32, &simulator_io_block.audio_buffer_head, .unordered);

        if (tail <= head) {
            const slice = byte_ptr[head .. simulator_io_block.audio_buffer_len - @intFromBool(tail == 0)];
            return if (slice.len == 0) null else slice;
        } else if (tail > head + 1) {
            return byte_ptr[head .. tail - 1];
        }
    }
    return null;
}

pub fn audio_submit_samples(num: usize) void {
    std.debug.assert(simulator_io_block.audio_buffer_ptr != null); // audio_set_buffer must have been called
    const len = simulator_io_block.audio_buffer_len;
    const tail = @atomicLoad(u32, &simulator_io_block.audio_buffer_tail, .acquire);
    const head = @atomicLoad(u32, &simulator_io_block.audio_buffer_head, .unordered);
    const available = if (tail <= head) len - 1 - (head - tail) else tail - head - 1;
    std.debug.assert(len <= available); // audio_submit_samples called with more than could be filled from audio_get_buffer
    var new_head = head + @as(u32, @intCast(num));
    while (new_head >= len) {
        new_head -= len;
    }
    @atomicStore(u32, &simulator_io_block.audio_buffer_head, new_head, .release);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub extern fn rand() u32;

pub fn trace(x: []const u8) void {
    _ = x;
    //std.debug.print("[cart]: {s}\n", .{x});
}
