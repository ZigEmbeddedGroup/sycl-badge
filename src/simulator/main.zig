const std = @import("std");
const sdl = @import("sdl3");
const cart = @import("cart_thread.zig");
const abi = cart.abi;
const Image = @import("zigimg").Image;

const log = std.log.scoped(.simulator);

const sim_bg_jpg_data = @embedFile("assets/sim_bg.jpg");

var window: ?*sdl.SDL_Window = null;
var renderer: ?*sdl.SDL_Renderer = null;
var app_texture: ?*sdl.SDL_Texture = null;

var running = true;

pub var gpa: std.mem.Allocator = undefined;
pub var io: std.Io = undefined;

var raw_keyboard_state: []const bool = &.{};

fn init_keyboard_state() void {
    var key_state_len: i32 = 0;
    const key_state_array: [*]const bool = sdl.SDL_GetKeyboardState(&key_state_len);
    if (key_state_len > 0) {
        raw_keyboard_state = key_state_array[0..@intCast(key_state_len)];
    }
}

fn is_key_pressed(scancode: u32) bool {
    if (scancode >= raw_keyboard_state.len) return false;
    return raw_keyboard_state[@intCast(scancode)];
}

fn is_any_key_pressed(scancodes: []const u32) bool {
    for (scancodes) |code| {
        if (is_key_pressed(code)) return true;
    }
    return false;
}

const DpadButton = enum {
    center,
    left,
    right,
    up,
    down,
};
var dpad_actives_buf: [5]DpadButton = undefined;

// Only one DPad button can be physically pressed at a time.
// If multiple keyboard keys are pressed, this list tracks
// them in LRU order so that only one is pressed at a time.
var dpad_actives: std.ArrayList(DpadButton) = blk: {
    var list: std.ArrayList(DpadButton) = .fromOwnedSlice(&dpad_actives_buf);
    list.items.len = 0;
    break :blk list;
};

const scancodes_dpad_up = [_]u32{ sdl.SDL_SCANCODE_W, sdl.SDL_SCANCODE_UP, sdl.SDL_SCANCODE_KP_8 };
const scancodes_dpad_left = [_]u32{ sdl.SDL_SCANCODE_A, sdl.SDL_SCANCODE_LEFT, sdl.SDL_SCANCODE_KP_4 };
const scancodes_dpad_down = [_]u32{ sdl.SDL_SCANCODE_S, sdl.SDL_SCANCODE_DOWN, sdl.SDL_SCANCODE_KP_2 };
const scancodes_dpad_right = [_]u32{ sdl.SDL_SCANCODE_D, sdl.SDL_SCANCODE_RIGHT, sdl.SDL_SCANCODE_KP_6 };
const scancodes_dpad_center = [_]u32{ sdl.SDL_SCANCODE_E, sdl.SDL_SCANCODE_RCTRL, sdl.SDL_SCANCODE_KP_5 };
const scancodes_select = [_]u32{ sdl.SDL_SCANCODE_BACKSPACE, sdl.SDL_SCANCODE_T };
const scancodes_start = [_]u32{ sdl.SDL_SCANCODE_RETURN, sdl.SDL_SCANCODE_Y };
const scancodes_a = [_]u32{ sdl.SDL_SCANCODE_Z, sdl.SDL_SCANCODE_K };
const scancodes_b = [_]u32{ sdl.SDL_SCANCODE_X, sdl.SDL_SCANCODE_J };

fn dpad_to_scancodes(dpad: DpadButton) []const u32 {
    return switch (dpad) {
        .up => &scancodes_dpad_up,
        .left => &scancodes_dpad_left,
        .down => &scancodes_dpad_down,
        .right => &scancodes_dpad_right,
        .center => &scancodes_dpad_center,
    };
}

fn scancode_to_dpad(scancode: u32) ?DpadButton {
    for (std.enums.values(DpadButton)) |button| {
        if (std.mem.indexOfScalar(u32, dpad_to_scancodes(button), scancode)) |_| return button;
    }
    return null;
}

fn update_cart_controls() void {
    var controls: abi.Controls = @bitCast(@as(u16, 0));
    controls.a = is_any_key_pressed(&scancodes_a);
    controls.b = is_any_key_pressed(&scancodes_b);
    controls.start = is_any_key_pressed(&scancodes_start);
    controls.select = is_any_key_pressed(&scancodes_select);

    const active_dpad = while (dpad_actives.items.len > 0) {
        if (!is_any_key_pressed(dpad_to_scancodes(dpad_actives.items[0]))) {
            _ = dpad_actives.orderedRemove(0);
        } else break dpad_actives.items[0];
    } else null;

    if (active_dpad) |button| switch (button) {
        .up => controls.up = true,
        .down => controls.down = true,
        .left => controls.left = true,
        .right => controls.right = true,
        .center => controls.click = true,
    };

    cart.sim_thread_update_controls(controls);
}

pub fn main(init: std.process.Init) !void {
    gpa = init.gpa;
    io = init.io;

    if (!sdl.SDL_SetAppMetadata("Example Renderer Clear", "1.0", "com.example.renderer-clear")) {
        std.debug.panic("SDL_SetAppMetadata failed: {s}\n", .{sdl.SDL_GetError()});
    }

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        std.debug.panic("SDL_Init failed: {s}\n", .{sdl.SDL_GetError()});
    }
    defer sdl.SDL_Quit();

    if (!sdl.SDL_CreateWindowAndRenderer("SYCL 2026 Badge Simulator", 640 * 2, 480 * 2, sdl.SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        std.debug.panic("SDL_CreateWindowAndRenderer failed: {s}", .{sdl.SDL_GetError()});
    }
    if (!sdl.SDL_SetRenderLogicalPresentation(renderer, 1920, 1080, sdl.SDL_LOGICAL_PRESENTATION_LETTERBOX)) {
        std.debug.panic("SDL_SetRenderLogicalPresentation failed: {s}", .{sdl.SDL_GetError()});
    }

    _ = sdl.SDL_SetRenderVSync(renderer, 1);

    // N.B. the texture is transposed to match the layout of the cart memory.
    app_texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_BGR565, sdl.SDL_TEXTUREACCESS_STREAMING, abi.screen_height, abi.screen_width);
    if (app_texture == null) {
        std.debug.panic("SDL_CreateTexture failed: {s}", .{sdl.SDL_GetError()});
    }

    _ = sdl.SDL_SetTextureScaleMode(app_texture, sdl.SDL_SCALEMODE_NEAREST);

    cart.sim_thread_start_cart_thread();
    defer cart.sim_thread_join_cart_thread();

    init_keyboard_state();

    // Load the background
    // const sim_bg_stream = sdl.SDL_IOFromConstMem(sim_bg_jpg_data, sim_bg_jpg_data.len);
    // const sim_bg_surface = sdl.SDL_LoadJPG_IO(sim_bg_stream, false);
    // const sim_bg_tex = sdl.SDL_CreateTextureFromSurface(renderer, sim_bg_surface);
    // sdl.SDL_DestroySurface(sim_bg_surface);

    const sim_bg_image = Image.fromMemory(gpa, sim_bg_jpg_data) catch |err| {
        std.debug.panic("Load sim_bg.jpg failed: {s}", .{@errorName(err)});
    };
    std.debug.assert(sim_bg_image.pixels == .rgb24);
    const sim_bg_surface = sdl.SDL_CreateSurfaceFrom(@intCast(sim_bg_image.width), @intCast(sim_bg_image.height), sdl.SDL_PIXELFORMAT_RGB24, sim_bg_image.pixels.rgb24.ptr, @intCast(sim_bg_image.width * 3));
    if (sim_bg_surface == null) {
        std.debug.panic("SDL_CreateSurfaceFrom failed: {s}", .{sdl.SDL_GetError()});
    }
    const sim_bg_tex = sdl.SDL_CreateTextureFromSurface(renderer, sim_bg_surface);
    if (sim_bg_tex == null) {
        std.debug.panic("SDL_CreateTextureFromSurface failed: {s}", .{sdl.SDL_GetError()});
    }
    //sdl.SDL_DestroySurface(sim_bg_surface);

    while (running) {
        if (cart.sim_thread_check_cart_stopped()) {
            running = false;
        }

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.SDL_EVENT_KEY_DOWN => {
                    if (scancode_to_dpad(event.key.scancode)) |button| {
                        if (std.mem.indexOfScalar(DpadButton, dpad_actives.items, button)) |idx|
                            _ = dpad_actives.orderedRemove(idx);
                        dpad_actives.appendAssumeCapacity(button);
                    }
                },
                sdl.SDL_EVENT_KEY_UP => {
                    if (scancode_to_dpad(event.key.scancode)) |button| {
                        if (std.mem.indexOfScalar(DpadButton, dpad_actives.items, button)) |idx|
                            _ = dpad_actives.orderedRemove(idx);
                    }
                },
                sdl.SDL_EVENT_QUIT => {
                    running = false;
                },
                else => {},
            }
        }

        update_cart_controls();

        if (cart.sim_thread_acquire_framebuffer()) |info| {
            defer cart.sim_thread_release_framebuffer();

            if (info.dirty_rect.has_area()) {
                // N.B. texture is transposed, so swap x and y
                const rect: sdl.SDL_Rect = .{
                    .x = info.dirty_rect.min_y,
                    .y = info.dirty_rect.min_x,
                    .w = info.dirty_rect.max_y - info.dirty_rect.min_y,
                    .h = info.dirty_rect.max_x - info.dirty_rect.min_x,
                };
                var pixel_ptr: ?*anyopaque = null;
                var pitch_bytes: i32 = 0;

                // Update the SDL texture contents
                if (sdl.SDL_LockTexture(app_texture, &rect, &pixel_ptr, &pitch_bytes) and pixel_ptr != null and pitch_bytes > 0) {
                    defer sdl.SDL_UnlockTexture(app_texture);

                    var src_pixels: [*]abi.DisplayColor = @ptrCast(&info.framebuffer[info.dirty_rect.min_x][info.dirty_rect.min_y]);
                    const src_pitch = abi.screen_height;
                    var dst_pixels: [*]abi.DisplayColor = @ptrCast(@alignCast(pixel_ptr.?));
                    const dst_pitch = @as(u32, @intCast(pitch_bytes)) / @sizeOf(abi.DisplayColor);

                    const copy_len = info.dirty_rect.max_y - info.dirty_rect.min_y;
                    for (info.dirty_rect.min_x..info.dirty_rect.max_x) |_| {
                        @memcpy(dst_pixels[0..copy_len], src_pixels[0..copy_len]);
                        src_pixels += src_pitch;
                        dst_pixels += dst_pitch;
                    }
                }
            }

            // Implement OS fast clear
            if (info.clear_color) |color| {
                for (info.framebuffer) |*col| {
                    @memset(col, color);
                }
            }
        }

        //const now = @as(f64, @floatFromInt(sdl.SDL_GetTicks())) / 1000.0; // convert from milliseconds to seconds.

        _ = sdl.SDL_SetRenderDrawColorFloat(renderer, 0.2, 0.2, 0.2, sdl.SDL_ALPHA_OPAQUE_FLOAT);
        _ = sdl.SDL_RenderClear(renderer);

        _ = sdl.SDL_RenderTexture(renderer, sim_bg_tex, null, null);

        const app_screen_topleft = fpoint(741, 277);
        // N.B. These are the opposite of what they are named because the texture is transposed.
        const app_screen_topright = fpoint(742, 686);
        const app_screen_botleft = fpoint(1253, 275);
        _ = sdl.SDL_RenderTextureAffine(renderer, app_texture, null, &app_screen_topleft, &app_screen_topright, &app_screen_botleft);

        // put the newly-cleared rendering on the screen.
        _ = sdl.SDL_RenderPresent(renderer);
    }
}

fn fpoint(x: f32, y: f32) sdl.SDL_FPoint {
    return .{ .x = x, .y = y };
}
