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

pub fn tone2(options: cart_api.Tone2Options) void {
    // TODO: Update sim to handle new tone api
    _ = options;
    // const adj_duration: u32 = if (options.duration == -1)
    //     std.math.maxInt(u32)
    // else
    //     @intFromFloat(@round(options.duration * 60.0));
    // struct {
    //     extern fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void;
    // }.tone(
    //     @intFromFloat(@round(options.frequency)),
    //     adj_duration,
    //     @intFromFloat(@round(options.volume * 100.0)),
    //     0,
    // );
}

pub fn set_global_volume(volume: f32) void {
    // TODO sim volume
    _ = volume;
    // simulator_io_block.api.wait_for_flags(abi.FLAG_AUDIO_VOLUME);

    // simulator_io_block.audio_volume = volume;

    // simulator_io_block.api.set_flags(abi.FLAG_AUDIO_VOLUME);
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub extern fn rand() u32;

pub fn trace(x: []const u8) void {
    std.debug.print("[cart]: {s}\n", .{x});
}
