const api = @import("api.zig");

pub const screen_width = api.screen_width;
pub const screen_height = api.screen_height;

pub const Framebuffer = api.Framebuffer;
pub const DisplayColor = api.DisplayColor;
pub const NeopixelColor = api.NeopixelColor;
pub const Controls = api.Controls;
pub const Rect8 = api.Rect8;

pub const SimulatorAPI = extern struct {
    is_running: *const fn () callconv(.c) bool,
    micros_since_boot: *const fn () callconv(.c) u64,
    check_flags: *const fn (u32) callconv(.c) bool,
    wait_for_flags: *const fn (u32) callconv(.c) void,
    set_flags: *const fn (u32) callconv(.c) void,
};

pub const SimulatorIO = extern struct {
    framebuffers: [2]api.Framebuffer align(api.framebuffer_alignment),
    neopixels: [5]NeopixelColor align(4),
    _pad: u8 = 0,
    controls: Controls = @bitCast(@as(u16, 0)),
    light_level: u16,
    battery_level: u16,
    user_led: bool = false,
    sim_running: bool,
    dirty_rect: Rect8,
    clear_color: DisplayColor,
    framebuffer_index: u8,
    audio_buffer_ptr: ?*anyopaque,
    audio_buffer_len: u32,
    audio_buffer_tail: u32,
    audio_buffer_head: u32,
    audio_volume: f32,

    api: *const SimulatorAPI,
};

pub const FLAG_PRESENT_METADATA = 1 << 0;
pub const FLAG_PRESENT_FRAME = 1 << 1;
pub const FLAG_AUDIO_VOLUME = 1 << 2;
pub const FLAG_START_AUDIO = 1 << 3;
pub const FLAG_STOP_AUDIO = 1 << 4;
