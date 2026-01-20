/// Minimal allocator for wasm3 (bump allocator, free is a no-op)
const std = @import("std");

const HEAP_SIZE: usize = 96 * 1024;
const HEADER_SIZE: usize = @sizeOf(usize);

var heap: [HEAP_SIZE]u8 align(8) linksection(".process_ram") = undefined;
var heap_offset: usize = 0;

pub export fn malloc(size: usize) ?*anyopaque {
    if (size == 0) return null;
    const aligned = std.mem.alignForward(usize, size, 8);
    const total = aligned + HEADER_SIZE;
    if (heap_offset + total > HEAP_SIZE) {
        return null;
    }
    const header_ptr = @as(*usize, @ptrCast(@alignCast(&heap[heap_offset])));
    header_ptr.* = aligned;
    const payload_ptr = @as([*]u8, @ptrCast(header_ptr)) + HEADER_SIZE;
    heap_offset += total;
    return @ptrCast(payload_ptr);
}

pub export fn calloc(count: usize, size: usize) ?*anyopaque {
    const total = count * size;
    const ptr = malloc(total) orelse return null;
    @memset(@as([*]u8, @ptrCast(ptr))[0..total], 0);
    return ptr;
}

pub export fn free(_: ?*anyopaque) void {}

pub export fn realloc(ptr: ?*anyopaque, size: usize) ?*anyopaque {
    if (ptr == null) return malloc(size);
    const payload_ptr: [*]u8 = @ptrCast(ptr.?);
    const header_ptr: *usize = @ptrCast(@alignCast(payload_ptr - HEADER_SIZE));
    const old_size = header_ptr.*;
    const new_ptr = malloc(size) orelse return null;
    const copy_len = @min(old_size, size);
    @memcpy(@as([*]u8, @ptrCast(new_ptr))[0..copy_len], payload_ptr[0..copy_len]);
    return new_ptr;
}
