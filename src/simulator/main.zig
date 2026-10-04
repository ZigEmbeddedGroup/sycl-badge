const std = @import("std");
const sdl = @import("sdl3");
const cart = @import("cart_thread.zig");
const abi = cart.abi;
const assets = @import("assets.zig");

const log = std.log.scoped(.simulator);


var window: ?*sdl.SDL_Window = null;
var renderer: ?*sdl.SDL_Renderer = null;
var app_texture: ?*sdl.SDL_Texture = null;

var debug_audio_mode: enum {
    none,
    app_audio,
    mixed_audio,
} = .none;

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

const v_width = 1920;
const v_height = 1080;

const audio_width_samples = 1764 * 5;
const audio_height_rows = 25 / 5;
const audio_row_height = @as(comptime_float, @floatFromInt(v_height)) / @as(comptime_float, audio_height_rows);
const audio_span = 0.9 * audio_row_height;
var audio_points: [audio_width_samples * audio_height_rows]sdl.SDL_FPoint = undefined;
var audio_cursor: struct {
    row_pos: u32 = 0,
    row_base: f32 = audio_row_height,
    array_idx: u32 = 0,

    fn write(c: *@This(), val_01: f32) void {
        audio_points[c.array_idx].y = c.row_base - val_01 * audio_span;

        c.array_idx += 1;
        if (c.array_idx == audio_points.len) {
            c.* = .{};
        } else {
            c.row_pos += 1;
            if (c.row_pos == audio_width_samples) {
                c.row_pos = 0;
                c.row_base += audio_row_height;
            }
        }
    }
} = .{};

fn init_audio_points() void {
    var ptr: [*]sdl.SDL_FPoint = &audio_points;
    var row_pos: f32 = audio_row_height - 0.5 * audio_span;
    for (0..audio_height_rows) |_| {
        for (0..audio_width_samples) |samp| {
            const samp_pos = @as(f32, @floatFromInt(samp)) * (@as(comptime_float, @floatFromInt(v_width)) / @as(comptime_float, @floatFromInt(audio_width_samples)));
            ptr[samp] = fpoint(samp_pos, row_pos);
        }
        row_pos += audio_row_height;
        ptr += audio_width_samples;
    }
}

fn update_audio_points(comptime T: type, samples: []const T) void {
    for (samples) |samp| {
        const samp_01 = switch (T) {
            u8 => @as(f32, @floatFromInt(samp)) / 255.0,
            i16 => @as(f32, @floatFromInt(@as(u16, @bitCast(samp)) ^ 0x8000)) / @as(f32, @floatFromInt((1 << 16) - 1)),
            else => @compileError("Unsupported type: " ++ @typeName(T)),
        };
        audio_cursor.write(samp_01);
    }
}

fn render_audio_points() void {
    // Yellow audio lines
    var ptr: [*]const sdl.SDL_FPoint = &audio_points;
    _ = sdl.SDL_SetRenderDrawColorFloat(renderer, 1.0, 1.0, 0.0, sdl.SDL_ALPHA_OPAQUE_FLOAT);
    for (0..audio_height_rows) |_| {
        _ = sdl.SDL_RenderLines(renderer, ptr, audio_width_samples);
        ptr += audio_width_samples;
    }

    _ = sdl.SDL_SetRenderDrawColorFloat(renderer, 0.1, 0.1, 0.1, sdl.SDL_ALPHA_OPAQUE_FLOAT);
    for (0..audio_height_rows) |row| {
        const row_f: f32 = @floatFromInt(row);
        const min = (row_f + 1.0) * audio_row_height;
        const max = min - audio_span;
        _ = sdl.SDL_RenderLine(renderer, 0, min + 1.0, v_width, min + 1.0);
        _ = sdl.SDL_RenderLine(renderer, 0, max - 1.0, v_width, max - 1.0);
    }
}

var global_volume: f32 = 1.0;
var vol_amplitude: f32 = 1.0;

// Note: This must be kept in sync with the implementation in drivers/audio.zig
fn calc_perceptually_linear_amplitude_for_volume(volume: f32) f32 {
    // This exponential scale never quite hits zero, so force it to.
    if (volume <= 0.0) return 0.0;
    // Adjust the volume on a log scale for perceptual linearity
    // Total range of 50 dB between min and max volume
    const clipped_vol = @max(0.0, @min(1.0, volume));
    const db_range = -50.0;
    const exp_range = db_range / 20.0 * @log(10.0);
    const vol_adjust_exp = exp_range * (1.0 - clipped_vol);
    return @exp(vol_adjust_exp);
}

const neopixel_diameter: f32 = 43.5;
const neo_tex_size: u32 = @intFromFloat(@ceil(neopixel_diameter + 3.0));

const neopixel_positions: [5]sdl.SDL_FPoint = .{
    fpoint(747, 909),
    fpoint(855, 909),
    fpoint(964, 909),
    fpoint(1072, 909),
    fpoint(1180, 909),
};

const led_r_pos = fpoint(-3, 0);
const led_g_pos = fpoint(0, 0);
const led_b_pos = fpoint(3, 0);

var neopixel_colors: [5]abi.NeopixelColor = @splat(.{ .r = 0, .g = 0, .b = 0 });

pub fn main(init: std.process.Init) !void {
    gpa = init.gpa;
    io = init.io;

    init_audio_points();

    if (!sdl.SDL_SetAppMetadata("Example Renderer Clear", "1.0", "com.example.renderer-clear")) {
        std.debug.panic("SDL_SetAppMetadata failed: {s}\n", .{sdl.SDL_GetError()});
    }

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO)) {
        std.debug.panic("SDL_Init failed: {s}\n", .{sdl.SDL_GetError()});
    }
    defer sdl.SDL_Quit();

    if (!sdl.SDL_CreateWindowAndRenderer("SYCL 2026 Badge Simulator", 640 * 2, 480 * 2, sdl.SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        std.debug.panic("SDL_CreateWindowAndRenderer failed: {s}", .{sdl.SDL_GetError()});
    }
    if (!sdl.SDL_SetRenderLogicalPresentation(renderer, v_width, v_height, sdl.SDL_LOGICAL_PRESENTATION_LETTERBOX)) {
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

    assets.load(renderer);

    const audio_spec: sdl.SDL_AudioSpec = .{
        .format = sdl.SDL_AUDIO_S16,
        .channels = 1,
        .freq = 44100,
    };
    const audio_stream = sdl.SDL_OpenAudioDeviceStream(sdl.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, null, null);
    if (audio_stream == null) {
        std.debug.panic("SDL_OpenAudioDeviceStream failed: {s}, audio will be disabled.", .{sdl.SDL_GetError()});
    }
    var audio_running = false;
    var audio_needs_resume = false;

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

        // TODO graceful shutdown, wait for audio to drain.
        if (cart.sim_thread_check_flags(abi.FLAG_STOP_AUDIO)) {
            cart.sim_thread_clear_flags(abi.FLAG_STOP_AUDIO);
            if (audio_running) {
                audio_running = false;
                if (audio_stream != null) {
                    _ = sdl.SDL_PauseAudioStreamDevice(audio_stream);
                    _ = sdl.SDL_ClearAudioStream(audio_stream);
                }
            }
        }

        if (cart.sim_thread_check_flags(abi.FLAG_START_AUDIO)) {
            cart.sim_thread_clear_flags(abi.FLAG_START_AUDIO);
            if (!audio_running) {
                audio_running = true;
                audio_needs_resume = true;
            }
        }

        if (cart.sim_thread_get_volume()) |new_volume| {
            global_volume = @max(0.0, @min(new_volume, 1.0));
            vol_amplitude = calc_perceptually_linear_amplitude_for_volume(new_volume);
        }

        // service audio, ensure at least 3 frames of data
        const min_audio_samples = 3 * 44100 / 60;
        if (audio_running) {
            const queued = @max(0, sdl.SDL_GetAudioStreamQueued(audio_stream));
            if (queued < min_audio_samples) {
                const chunk_size = 512;
                const to_fill = std.mem.alignForward(usize, min_audio_samples - @as(usize, @intCast(queued)), chunk_size);

                const vol_mult: u32 = @intFromFloat(@as(f64, 0x00_FF_FF_FF) * vol_amplitude);
                const vol_add: u32 = @bitCast(-%@as(i32, @bitCast(@as(u32, @intFromFloat(@as(f64, 0x7FFF_FFFF) * vol_amplitude)))));

                var filled: u32 = 0;
                while (filled < to_fill) {
                    var buf: [chunk_size]u8 = undefined;
                    var mixed_buf: [chunk_size]i16 = undefined;
                    const samples = cart.sim_thread_consume_audio(&buf);

                    if (debug_audio_mode == .app_audio) {
                        update_audio_points(u8, buf[0..samples]);
                    }

                    // Mix the audio using the volume scalar
                    for (0..samples) |i| {
                        mixed_buf[i] = @bitCast(@as(u16, @intCast((buf[i] * vol_mult +% vol_add) >> 16)));
                    }

                    if (debug_audio_mode == .mixed_audio) {
                        update_audio_points(i16, mixed_buf[0..samples]);
                    }

                    _ = sdl.SDL_PutAudioStreamData(audio_stream, &mixed_buf, @intCast(samples * @sizeOf(u16)));
                    filled += @intCast(samples);
                    if (samples < chunk_size) break;
                }

                if (audio_needs_resume and @as(usize, @intCast(queued)) + filled >= min_audio_samples) {
                    _ = sdl.SDL_ResumeAudioStreamDevice(audio_stream);
                    audio_needs_resume = false;
                }
                _ = sdl.SDL_FlushAudioStream(audio_stream);
            } else if (audio_needs_resume) {
                _ = sdl.SDL_ResumeAudioStreamDevice(audio_stream);
                audio_needs_resume = false;
            }
        }

        if (cart.sim_thread_acquire_framebuffer()) |info| {
            defer cart.sim_thread_release_framebuffer();

            neopixel_colors = info.neopixels;

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

        _ = sdl.SDL_RenderTexture(renderer, assets.sim_bg, null, null);

        for (neopixel_positions, neopixel_colors) |pos, color| {
            if (color.r == 0 and color.g == 0 and color.b == 0) continue;
            // Layers:
            // 1. background
            // 2. bloom
            // 3. dot bloom
            // 4. circle
            // 5. dot

            const color_float: [3]f32 = .{
                @as(f32, @floatFromInt(color.r)) / 255.0,
                @as(f32, @floatFromInt(color.g)) / 255.0,
                @as(f32, @floatFromInt(color.b)) / 255.0,
            };
            const max = @max(@max(color_float[0], color_float[1]), color_float[2]);
            const saturated_color = saturate_color(color_float, max);
            const whiteness = @min(1.0, max * 2.0);
            const too_bright_color: [3]f32 = .{
                std.math.lerp(saturated_color[0], 1.0, whiteness),
                std.math.lerp(saturated_color[1], 1.0, whiteness),
                std.math.lerp(saturated_color[2], 1.0, whiteness),
            };

            // Premultiplied alpha in SDL means we need to multiply the color by the alpha mod
            const bg_alpha = @min(1.0, max * 4.0);
            _ = sdl.SDL_SetTextureColorModFloat(assets.npx_bg.tex, bg_alpha, bg_alpha, bg_alpha);
            _ = sdl.SDL_SetTextureAlphaModFloat(assets.npx_bg.tex, bg_alpha);
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_bg.tex, null, &assets.npx_bg.at(pos));

            _ = sdl.SDL_SetTextureColorMod(assets.npx_bloom_small.tex, color.r, color.g, color.b); 
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_bloom_small.tex, null, &assets.npx_bloom_small.at(pos));

            // Circle
            const ring_alpha = @min(1.0, 0.25 + max * 2.0);
            _ = sdl.SDL_SetTextureColorModFloat(assets.npx_ring.tex, too_bright_color[0] * ring_alpha, too_bright_color[1] * ring_alpha, too_bright_color[2] * ring_alpha);
            _ = sdl.SDL_SetTextureAlphaModFloat(assets.npx_ring.tex, ring_alpha);
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_ring.tex, null, &assets.npx_ring.at(pos));

            // Dot blooms
            _ = sdl.SDL_SetTextureColorMod(assets.npx_bloom_small.tex, color.r, 0, 0);
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_bloom_small.tex, null, &assets.npx_bloom_small.at(fp_add(pos, led_r_pos)));
            _ = sdl.SDL_SetTextureColorMod(assets.npx_bloom_small.tex, 0, color.g, 0);
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_bloom_small.tex, null, &assets.npx_bloom_small.at(fp_add(pos, led_g_pos)));
            _ = sdl.SDL_SetTextureColorMod(assets.npx_bloom_small.tex, 0, 0, color.b);
            _ = sdl.SDL_RenderTexture(renderer, assets.npx_bloom_small.tex, null, &assets.npx_bloom_small.at(fp_add(pos, led_b_pos)));


            // const rect: sdl.SDL_FRect = .{ .x = pos.x, .y = pos.y, .w = neo_tex_size, .h = neo_tex_size };
            // _ = sdl.SDL_RenderTexture(renderer, neopixel_tex, null, &rect);
        }

        const app_screen_left = 751 - 6;
        const app_screen_right = 1218 + 4;
        const app_screen_top = 284 - 6;
        const app_screen_topleft = fpoint(app_screen_left, app_screen_top);
        // N.B. These are the opposite of what they are named because the texture is transposed.
        const app_screen_botleft = fpoint(app_screen_right, app_screen_top);
        const delta_x = app_screen_botleft.x - app_screen_topleft.x;
        const delta_y = @as(f32, @floatFromInt(abi.screen_height)) * delta_x / @as(f32, @floatFromInt(abi.screen_width));
        const app_screen_topright = fpoint(app_screen_left, app_screen_top + delta_y);
        _ = sdl.SDL_RenderTextureAffine(renderer, app_texture, null, &app_screen_topleft, &app_screen_topright, &app_screen_botleft);

        if (debug_audio_mode != .none) {
            render_audio_points();
        }

        // put the newly-cleared rendering on the screen.
        _ = sdl.SDL_RenderPresent(renderer);
    }
}

fn saturate_color(color: [3]f32, max: f32) [3]f32 {
    if (max == 0) return color;
    return .{
        color[0] / max,
        color[1] / max,
        color[2] / max,
    };
}

fn fpoint(x: f32, y: f32) sdl.SDL_FPoint {
    return .{ .x = x, .y = y };
}

fn fp_add(a: sdl.SDL_FPoint, b: sdl.SDL_FPoint) sdl.SDL_FPoint {
    return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}
