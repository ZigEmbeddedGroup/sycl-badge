/// WASM runtime wrapper using wasm3
const std = @import("std");
const microzig = @import("microzig");

const lcd = @import("../drivers/lcd.zig");
const uart = @import("../drivers/uart.zig");
const timer = @import("../drivers/timer.zig");
const wasm_alloc = @import("wasm3_alloc.zig");
comptime {
    _ = wasm_alloc;
}

const wasm3 = struct {
    pub const M3Result = ?[*:0]const u8;
    pub const IM3Environment = ?*anyopaque;
    pub const IM3Runtime = ?*anyopaque;
    pub const IM3Module = ?*anyopaque;
    pub const IM3Function = ?*anyopaque;
    pub const IM3ImportContext = ?*anyopaque;

    extern fn m3_NewEnvironment() IM3Environment;
    extern fn m3_FreeEnvironment(env: IM3Environment) void;
    extern fn m3_NewRuntime(env: IM3Environment, stack_size: u32, userdata: ?*anyopaque) IM3Runtime;
    extern fn m3_FreeRuntime(runtime: IM3Runtime) void;
    extern fn m3_ParseModule(env: IM3Environment, module: *IM3Module, wasm: [*]const u8, size: usize) M3Result;
    extern fn m3_LoadModule(runtime: IM3Runtime, module: IM3Module) M3Result;
    extern fn m3_FreeModule(module: IM3Module) void;
    extern fn m3_RunStart(module: IM3Module) M3Result;
    extern fn m3_FindFunction(out_fn: *IM3Function, runtime: IM3Runtime, name: [*:0]const u8) M3Result;
    extern fn m3_CallV(function: IM3Function, ...) M3Result;
    extern fn m3_LinkRawFunction(module: IM3Module, module_name: [*:0]const u8, func_name: [*:0]const u8, signature: [*:0]const u8, f: *const anyopaque) M3Result;
};

pub const MAX_CART_SIZE: usize = 256 * 1024;
const FLASH_PAGE_SIZE: usize = 256;
const FLASH_PAGE_COUNT: usize = 128;
const NAME_START: [*:0]const u8 = "start";
const NAME_UPDATE: [*:0]const u8 = "update";
const NAME_INIT: [*:0]const u8 = "_initialize";
const NAME_ENV: [*:0]const u8 = "env";
const NAME_RECT: [*:0]const u8 = "rect";
const NAME_OVAL: [*:0]const u8 = "oval";
const NAME_LINE: [*:0]const u8 = "line";
const NAME_HLINE: [*:0]const u8 = "hline";
const NAME_VLINE: [*:0]const u8 = "vline";
const NAME_BLIT: [*:0]const u8 = "blit";
const NAME_TEXT: [*:0]const u8 = "text";
const NAME_TONE: [*:0]const u8 = "tone";
const NAME_READ_FLASH: [*:0]const u8 = "read_flash";
const NAME_WRITE_FLASH_PAGE: [*:0]const u8 = "write_flash_page";
const NAME_RAND: [*:0]const u8 = "rand";
const NAME_TRACE: [*:0]const u8 = "trace";

var cart_buffer: [MAX_CART_SIZE]u8 align(8) linksection(".process_ram") = undefined;
var flash_buffer: [FLASH_PAGE_SIZE * FLASH_PAGE_COUNT]u8 align(8) linksection(".process_ram") = undefined;

pub fn cartBuffer() *[MAX_CART_SIZE]u8 {
    return &cart_buffer;
}

extern fn env_rect(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_oval(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_line(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_hline(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_vline(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_blit(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_text(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_tone(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_read_flash(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_write_flash_page(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_rand(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;
extern fn env_trace(runtime: wasm3.IM3Runtime, ctx: wasm3.IM3ImportContext, sp: [*]u64, mem: ?*anyopaque) callconv(.c) ?*const anyopaque;

pub const Runtime = struct {
    env: ?wasm3.IM3Environment = null,
    runtime: ?wasm3.IM3Runtime = null,
    module: ?wasm3.IM3Module = null,
    start_fn: wasm3.IM3Function = null,
    update_fn: wasm3.IM3Function = null,
    init_fn: wasm3.IM3Function = null,

    pub fn load(self: *Runtime, wasm_bytes: []const u8) bool {
        self.stop();
        @memset(flash_buffer[0..], 0);
        const env = wasm3.m3_NewEnvironment();
        if (env == null) return false;
        self.env = env;
        const runtime = wasm3.m3_NewRuntime(env, 64 * 1024, null);
        if (runtime == null) return false;
        self.runtime = runtime;

        var module: wasm3.IM3Module = null;
        if (wasm3.m3_ParseModule(env, &module, wasm_bytes.ptr, wasm_bytes.len) != null) {
            return false;
        }
        if (wasm3.m3_LoadModule(runtime, module) != null) {
            return false;
        }
        self.module = module;
        if (!linkImports(module)) {
            return false;
        }

        _ = wasm3.m3_FindFunction(&self.start_fn, runtime, NAME_START);
        _ = wasm3.m3_FindFunction(&self.update_fn, runtime, NAME_UPDATE);
        _ = wasm3.m3_FindFunction(&self.init_fn, runtime, NAME_INIT);
        return true;
    }

    pub fn start(self: *Runtime) void {
        if (self.module) |mod| {
            _ = wasm3.m3_RunStart(mod);
        }
        if (self.init_fn) |fnc| {
            _ = wasm3.m3_CallV(fnc);
        }
        if (self.start_fn) |fnc| {
            _ = wasm3.m3_CallV(fnc);
        }
    }

    pub fn update(self: *Runtime) void {
        if (self.update_fn) |fnc| {
            _ = wasm3.m3_CallV(fnc);
        }
    }

    pub fn stop(self: *Runtime) void {
        if (self.module) |mod| {
            wasm3.m3_FreeModule(mod);
        }
        if (self.runtime) |rt| {
            wasm3.m3_FreeRuntime(rt);
        }
        if (self.env) |env| {
            wasm3.m3_FreeEnvironment(env);
        }
        self.* = .{};
    }
};

fn linkImports(module: wasm3.IM3Module) bool {
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_RECT, "v(iiiiii)", env_rect) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_OVAL, "v(iiiiii)", env_oval) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_LINE, "v(iiiii)", env_line) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_HLINE, "v(iiii)", env_hline) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_VLINE, "v(iiii)", env_vline) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_BLIT, "v(*iiiiiiii)", env_blit) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_TEXT, "v(ii*iii)", env_text) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_TONE, "v(iiii)", env_tone) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_READ_FLASH, "i(i*i)", env_read_flash) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_WRITE_FLASH_PAGE, "v(i*)", env_write_flash_page) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_RAND, "i()", env_rand) != null) return false;
    if (wasm3.m3_LinkRawFunction(module, NAME_ENV, NAME_TRACE, "v(*i)", env_trace) != null) return false;
    return true;
}

fn colorFromValue(value: i32) ?lcd.Color16 {
    if (value == -1) return null;
    return @bitCast(@as(u16, @truncate(@as(u32, @intCast(value)))));
}

fn drawLine(x0: i32, y0: i32, x1: i32, y1: i32, color: lcd.Color16) void {
    var x = x0;
    var y = y0;
    const dx = absI32(x1 - x0);
    const dy = -absI32(y1 - y0);
    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err: i32 = dx + dy;
    while (true) {
        lcd.drawPixel(@intCast(x), @intCast(y), color);
        if (x == x1 and y == y1) break;
        const e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y += sy;
        }
    }
}

fn drawOval(x: i32, y: i32, w: i32, h: i32, stroke: ?lcd.Color16, fill: ?lcd.Color16) void {
    if (w <= 0 or h <= 0) return;
    const a = @as(f32, @floatFromInt(w - 1)) / 2.0;
    const b = @as(f32, @floatFromInt(h - 1)) / 2.0;
    const cx = @as(f32, @floatFromInt(x)) + a;
    var yy: i32 = 0;
    while (yy < h) : (yy += 1) {
        const dy = @as(f32, @floatFromInt(yy)) - b;
        const ratio = 1.0 - (dy * dy) / (b * b);
        if (ratio < 0) continue;
        const dx = a * std.math.sqrt(ratio);
        const x0 = @as(i32, @intFromFloat(cx - dx));
        const x1 = @as(i32, @intFromFloat(cx + dx));
        if (fill) |fc| {
            lcd.drawHLine(@intCast(x0), @intCast(y + yy), @intCast(x1 - x0 + 1), fc);
        }
        if (stroke) |sc| {
            lcd.drawPixel(@intCast(x0), @intCast(y + yy), sc);
            lcd.drawPixel(@intCast(x1), @intCast(y + yy), sc);
        }
    }
}

pub export fn wasm_env_rect(stroke: i32, fill: i32, x: i32, y: i32, w: i32, h: i32) void {
    const stroke_color = colorFromValue(stroke);
    const fill_color = colorFromValue(fill);
    if (w <= 0 or h <= 0) return;
    const ux: u16 = @intCast(@max(0, x));
    const uy: u16 = @intCast(@max(0, y));
    const uw: u16 = @intCast(@max(0, w));
    const uh: u16 = @intCast(@max(0, h));
    if (fill_color) |c| {
        lcd.fillRect(ux, uy, uw, uh, c);
    }
    if (stroke_color) |c| {
        lcd.drawRect(ux, uy, uw, uh, c);
    }
}

pub export fn wasm_env_oval(stroke: i32, fill: i32, x: i32, y: i32, w: i32, h: i32) void {
    drawOval(x, y, w, h, colorFromValue(stroke), colorFromValue(fill));
}

pub export fn wasm_env_line(color: i32, x1: i32, y1: i32, x2: i32, y2: i32) void {
    if (colorFromValue(color)) |c| {
        drawLine(x1, y1, x2, y2, c);
    }
}

pub export fn wasm_env_hline(color: i32, x: i32, y: i32, len: i32) void {
    if (len <= 0) return;
    if (colorFromValue(color)) |c| {
        lcd.drawHLine(@intCast(@max(0, x)), @intCast(@max(0, y)), @intCast(@max(0, len)), c);
    }
}

pub export fn wasm_env_vline(color: i32, x: i32, y: i32, len: i32) void {
    if (len <= 0) return;
    if (colorFromValue(color)) |c| {
        lcd.drawVLine(@intCast(@max(0, x)), @intCast(@max(0, y)), @intCast(@max(0, len)), c);
    }
}

pub export fn wasm_env_blit(sprite: [*]const u16, x: i32, y: i32, w: u32, h: u32, src_x: u32, src_y: u32, stride: u32, flags: u32) void {
    const flip_x = (flags & 1) != 0;
    const flip_y = (flags & 2) != 0;
    const rotate = (flags & 4) != 0;
    const stride_val = if (stride == 0) w else stride;
    var yy: u32 = 0;
    while (yy < h) : (yy += 1) {
        var xx: u32 = 0;
        while (xx < w) : (xx += 1) {
            const src_index = (src_y + yy) * stride_val + (src_x + xx);
            const color: lcd.Color16 = @bitCast(@as(u16, sprite[src_index]));
            var tx: i32 = @intCast(xx);
            var ty: i32 = @intCast(yy);
            if (flip_x) tx = @intCast(w - 1 - xx);
            if (flip_y) ty = @intCast(h - 1 - yy);
            if (rotate) {
                const tmp = tx;
                tx = ty;
                ty = @as(i32, @intCast(w - 1)) - tmp;
            }
            const px = x + tx;
            const py = y + ty;
            if (px >= 0 and py >= 0) {
                lcd.drawPixel(@intCast(px), @intCast(py), color);
            }
        }
    }
}

pub export fn wasm_env_text(text_color: u32, bg_color: u32, text: [*]const u8, len: u32, x: i32, y: i32) void {
    const fg: lcd.Color16 = @bitCast(@as(u16, @truncate(text_color)));
    const bg: lcd.Color16 = @bitCast(@as(u16, @truncate(bg_color)));
    lcd.drawString(@intCast(@max(0, x)), @intCast(@max(0, y)), text[0..len], fg, bg, 1);
}

pub export fn wasm_env_tone(_: u32, _: u32, _: u32, _: u32) void {}

pub export fn wasm_env_read_flash(offset: u32, dst: [*]u8, len: u32) u32 {
    if (offset >= @as(u32, @intCast(flash_buffer.len))) return 0;
    const max_len = @min(len, @as(u32, @intCast(flash_buffer.len)) - offset);
    const start: usize = @intCast(offset);
    const end: usize = start + @as(usize, @intCast(max_len));
    @memcpy(dst[0..max_len], flash_buffer[start..end]);
    return max_len;
}

pub export fn wasm_env_write_flash_page(page: u32, src: [*]const u8) void {
    const offset: usize = @as(usize, @intCast(page)) * FLASH_PAGE_SIZE;
    if (offset + FLASH_PAGE_SIZE > flash_buffer.len) return;
    @memcpy(flash_buffer[offset .. offset + FLASH_PAGE_SIZE], src[0..FLASH_PAGE_SIZE]);
}

var rand_state: u32 = 0x12345678;

pub export fn wasm_env_rand() u32 {
    if (rand_state == 0x12345678) {
        rand_state = @truncate(timer.micros());
    }
    rand_state = rand_state * 1664525 + 1013904223;
    return rand_state;
}

pub export fn wasm_env_trace(text: [*]const u8, len: u32) void {
    uart.puts(text[0..len]);
    uart.puts("\r\n");
}

fn absI32(value: i32) i32 {
    return if (value < 0) -value else value;
}
