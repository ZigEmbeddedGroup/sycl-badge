const std = @import("std");
const sdl = @import("sdl3");
const Image = @import("zigimg").Image;

const root = @import("root");

const sim_bg_jpg = @embedFile("assets/sim_bg.jpg");
const npx_bg_png = @embedFile("assets/npx_bg.png");
const npx_bloom_small_png = @embedFile("assets/npx_bloom_small.png");
//const npx_bloom_png = @embedFile("assets/npx_bloom.png");
const npx_dot_bloom_png = @embedFile("assets/npx_dot_bloom.png");
const npx_dot_png = @embedFile("assets/npx_dot.png");
const npx_ring_png = @embedFile("assets/npx_ring.png");

pub const NpxTexture = struct {
    tex: ?*sdl.SDL_Texture = null,
    width: u32,
    height: u32,
    center_x: f32,
    center_y: f32,

    pub fn at(tex: NpxTexture, pos: sdl.SDL_FPoint) sdl.SDL_FRect {
        return .{
            .x = pos.x - tex.center_x,
            .y = pos.y - tex.center_y,
            .w = @floatFromInt(tex.width),
            .h = @floatFromInt(tex.height),
        };
    }
};

pub var sim_bg: ?*sdl.SDL_Texture = null;
pub var npx_bg: NpxTexture = undefined;
pub var npx_bloom_small: NpxTexture = undefined;
//pub var npx_bloom: NpxTexture = undefined;
pub var npx_dot_bloom: NpxTexture = undefined;
pub var npx_dot: NpxTexture = undefined;
pub var npx_ring: NpxTexture = undefined;

pub fn load(renderer: ?*sdl.SDL_Renderer) void {
    sim_bg = load_tex(renderer, sim_bg_jpg, "sim_bg.jpg").tex;

    npx_bg = load_tex(renderer, npx_bg_png, "npx_bg.png");
    _ = sdl.SDL_SetTextureBlendMode(npx_bg.tex, sdl.SDL_BLENDMODE_BLEND_PREMULTIPLIED);

    npx_bloom_small = load_tex(renderer, npx_bloom_small_png, "npx_bloom_small.png");
    _ = sdl.SDL_SetTextureBlendMode(npx_bloom_small.tex, sdl.SDL_BLENDMODE_ADD);
    npx_bloom_small.center_x -= 1;
    npx_bloom_small.center_y += 23;

    //npx_bloom = load_tex(renderer, npx_bloom_png, "npx_bloom.png");
    //_ = sdl.SDL_SetTextureBlendMode(npx_bloom.tex, sdl.SDL_BLENDMODE_ADD);

    npx_dot_bloom = load_tex(renderer, npx_dot_bloom_png, "npx_dot_bloom.png");
    _ = sdl.SDL_SetTextureBlendMode(npx_dot_bloom.tex, sdl.SDL_BLENDMODE_ADD);

    npx_dot = load_tex(renderer, npx_dot_png, "npx_dot.png");
    _ = sdl.SDL_SetTextureBlendMode(npx_dot.tex, sdl.SDL_BLENDMODE_BLEND_PREMULTIPLIED);

    npx_ring = load_tex(renderer, npx_ring_png, "npx_ring.png");
    _ = sdl.SDL_SetTextureBlendMode(npx_ring.tex, sdl.SDL_BLENDMODE_BLEND_PREMULTIPLIED);
}

fn load_tex(renderer: ?*sdl.SDL_Renderer, data: []const u8, name: []const u8) NpxTexture {
    var image = Image.fromMemory(root.gpa, data) catch |err| {
        std.debug.panic("Load {s} failed: {s}", .{name, @errorName(err)});
    };
    const pixel_format: struct {
        sdl_format: sdl.SDL_PixelFormat,
        buffer_ptr: *u8,
        pitch_bytes: u32,
    } = switch (image.pixels) {
        .rgb24 => |pixels| .{
            .sdl_format = sdl.SDL_PIXELFORMAT_RGB24,
            .buffer_ptr = @ptrCast(pixels.ptr),
            .pitch_bytes = @intCast(image.width * 3),
        },
        .rgba32 => |pixels| .{
            .sdl_format = sdl.SDL_PIXELFORMAT_RGBA32,
            .buffer_ptr = @ptrCast(pixels.ptr),
            .pitch_bytes = @intCast(image.width * 4),
        },
        else => std.debug.panic("Unhandled pixel format in {s}: {s}", .{name, @tagName(std.meta.activeTag(image.pixels))}),
    };
    const surface = sdl.SDL_CreateSurfaceFrom(
        @intCast(image.width),
        @intCast(image.height),
        pixel_format.sdl_format,
        pixel_format.buffer_ptr,
        @intCast(pixel_format.pitch_bytes),
    );
    if (surface == null) {
        std.debug.panic("SDL_CreateSurfaceFrom failed: {s}", .{sdl.SDL_GetError()});
    }
    const tex = sdl.SDL_CreateTextureFromSurface(renderer, surface);
    if (tex == null) {
        std.debug.panic("SDL_CreateTextureFromSurface failed: {s}", .{sdl.SDL_GetError()});
    }
    const width = image.width;
    const height = image.height;
    sdl.SDL_DestroySurface(surface);
    image.deinit(root.gpa);

    return .{
        .tex = tex,
        .width = @intCast(width),
        .height = @intCast(height),
        .center_x = @as(f32, @floatFromInt(width)) * 0.5,
        .center_y = @as(f32, @floatFromInt(height)) * 0.5,
    };
}

