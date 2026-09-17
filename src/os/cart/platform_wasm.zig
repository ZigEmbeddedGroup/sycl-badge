const std = @import("std");
const cart_api = @import("api.zig");

const start_code = struct {
    const root = @import("root");

    export fn start() void {
        root.start();
    }

    export fn update() void {
        root.update();
    }
};

pub fn export_start_code() void {
    comptime {
        _ = start_code;
    }
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Inputs and Outputs                                                        │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn micros_since_boot() u64 {
    // TODO
    const statics = struct {
        var last_val: u64 = 0;
    };
    statics.last_val += 1000;
    return statics.last_val;
}

// TODO Fill in this IO block every frame before calling update()
var io: struct {
    controls: cart_api.Controls = @bitCast(@as(u16, 0)),
    light_level: u12 = ~@as(u12, 0),
    neopixels: [5]cart_api.NeopixelColor = @splat(.{ .r = 0, .g = 0, .b = 0 }),
    user_led: bool = false,
    battery_level: u12 = ~@as(u12, 0),
} = .{};

pub const controls: *const volatile cart_api.Controls = &io.controls;
pub const light_level: *volatile u12 = &io.light_level;
pub const neopixels: *volatile [5]cart_api.NeopixelColor = &io.neopixels;
pub const user_led: *volatile bool = &io.user_led;
pub const battery_level: *volatile u12 = &io.battery_level;

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Frame Management                                                          │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

var framebuffer_data: [2]cart_api.Framebuffer align(cart_api.framebuffer_alignment) = undefined;
pub const framebuffers: [2]cart_api.FramebufferPtr = .{ &framebuffer_data[0], &framebuffer_data[1] };

pub fn present_and_acquire(draw_buffer_index: u1, dirty_rect: cart_api.Rect8, clear_color: ?cart_api.DisplayColor) void {
    // TODO wasm present mid-frame
    _ = draw_buffer_index;
    _ = dirty_rect;
    _ = clear_color;
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Sound Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub fn tone2(options: cart_api.Tone2Options) void {
    // TODO: Update wasm to handle new float values
    const adj_duration: u32 = if (options.duration == -1)
        std.math.maxInt(u32)
    else
        @intFromFloat(@round(options.duration * 60.0));
    struct {
        extern fn tone(frequency: u32, duration: u32, volume: u32, flags: u32) void;
    }.tone(
        @intFromFloat(@round(options.frequency)),
        adj_duration,
        @intFromFloat(@round(options.volume * 100.0)),
        0,
    );
}

pub fn set_global_volume(volume: f32) void {
    _ = volume;
    // TODO wasm volume
}

// ┌───────────────────────────────────────────────────────────────────────────┐
// │                                                                           │
// │ Other Functions                                                           │
// │                                                                           │
// └───────────────────────────────────────────────────────────────────────────┘

pub extern fn rand() u32;

pub fn trace(x: []const u8) void {
    struct {
        extern fn trace(str_ptr: [*]const u8, str_len: usize) void;
    }.trace(x.ptr, x.len);
}
