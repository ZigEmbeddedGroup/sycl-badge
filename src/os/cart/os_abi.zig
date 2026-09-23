//! This file contains data layouts that are used by both the cart
//! and the OS for cross-communication. The two must be kept in sync!

const std = @import("std");
const api = @import("api.zig");

// Carts begin with a Cart Descriptor Table, which tells the OS about
// the cart contents. All descriptor tables of all versions begin with
// CART_MAGIC, followed by the version number. This allows the OS to
// ensure that it is reading a valid version table before jumping to
// its entry point. The OS maintains limited backwards compatibility
// for older versions, which are maintained in this file.
pub const CART_MAGIC = 0x54C1_CA41;

pub const CART_VERSION_V1: u32 = 0x54C126_01;
pub const CartDescriptorTable_v1 = extern struct {
    magic: u32 = CART_MAGIC,
    version: u32 = CART_VERSION_V1,
    bss_start: *u8,
    bss_end: *u8,
    entry_point: *const fn () callconv(.c) void,
};

pub const CART_VERSION_CURRENT = CART_VERSION_V1;
pub const CartDescriptorTable = CartDescriptorTable_v1;

pub const DisplayColor = api.DisplayColor;
pub const NeopixelColor = api.NeopixelColor;
pub const Controls = api.Controls;
pub const Rect8 = api.Rect8;

pub const tracy_buffer_size = 4096;

// Cart IPC block lives at the start of process_ram (0x20020000).
// The OS kernel (Core 0) writes sensor/button data here each frame, and reads
// the framebuffer back to DMA it to the LCD. The cart (Core 1) reads inputs
// and writes pixels. Using process_ram avoids colliding with kernel_ram
// (0x20000000) where the OS keeps its own data structures.
const base = 0x20020000;
// zig fmt: off
pub const CartIPCData = extern struct {
    framebuffers: [2][api.screen_width][api.screen_height]DisplayColor, // x0..xA000, xA000..x14000
    tracy_ring: [tracy_buffer_size]u8, // x14000..x15000
    trace_buf: [0x80]u8,               // x15000..x15080
    neopixels: [5]NeopixelColor,       // x15080..x1508F
    _pad1: u8 = 0,                     // x1508F..x15090

    controls: Controls,                // x15090..x15092
    light_level: u16,                  // x15092..x15094

    user_led: bool,                    // x15094..x15095
    _pad2: u8 = 0,                     // x15095..x15096
    battery_level: u16,                // x15096..x15098

    dirty_rect: Rect8,                 // x15098..x1509C

    tone_freq: f32,                    // x1509C..x150A0
    tone_duration: f32,                // x150A0..x150A4
    tone_volume: f32,                  // x150A4..x150A8
    tone_flags: u32,                   // x150A8..x150AC
    global_volume: f32,                // x150AC..x150B0

    tracy_read_pos: u32,               // x150B0..x150B4, align(16)
    _pad3: [3]u32 = @splat(0),         // x150B4..x150C0, tracy_read_pos gets its own granule
    tracy_write_ctrl: u32,             // x150C0..x150C4, align(16)
    _pad4: [3]u32 = @splat(0),         // x150C4..x150D0, tracy_write_ctrl gets its own granule
    tracy_spinlock: u32,               // x150D0..x150D4, align(16)
    _pad5: [3]u32 = @splat(0),         // x150D4..x150E0, tracy_spinlock gets its own granule

    vsync_flags: u32,                  // x150E0..x150E4
    vsync_frame_ms: f32,               // x150E4..x150E8
    clear_color: DisplayColor,         // x150E8..x150EA
    _pad6: u16 = 0,                    // x150EA..x150EC

    comptime {
        // cart_xip.ld reserves 0x15100 bytes for IPC data.
        // If it grows more than that, the linker script needs to be updated.
        std.debug.assert(@sizeOf(CartIPCData) <= 0x15100);
    }
};
// zig fmt: on

pub const ipc_data: *align(0x2000) volatile CartIPCData = @ptrFromInt(base);

pub const PresentFlags = packed struct(u32) {
    const FRAMEBUFFER_READY_V2: u8 = 0x28; // see os/ipc/mailbox.zig

    framebuffer_index: u1,
    has_dirty_rect: bool,
    vsync_updated: bool,
    clear_frame: bool,
    _reserved: u20 = 0,
    tag: u8 = FRAMEBUFFER_READY_V2,
};

pub const TracyAtomicWriteCtrl = packed struct(u32) {
    write_pos: u16,
    _pad: u12 = 0,
    server_connected: bool,
    cart_buffer_active: bool,
    rtt_buffer_active: bool,
    has_thread_ctx: bool,

    pub const zero: TracyAtomicWriteCtrl = .{
        .write_pos = 0,
        .server_connected = false,
        .cart_buffer_active = false,
        .rtt_buffer_active = false,
        .has_thread_ctx = false,
    };

    pub fn inactive(ctrl: TracyAtomicWriteCtrl) bool {
        return !(ctrl.server_connected and ctrl.cart_buffer_active and ctrl.rtt_buffer_active);
    }
};

inline fn spin_lock_acquire_hw(_: *u32) void {
    const spinlock: *volatile u32 = @ptrFromInt(0xd0000128);
    while (spinlock.* == 0) {}
}

inline fn spin_lock_release_hw(_: *u32) void {
    const spinlock: *volatile u32 = @ptrFromInt(0xd0000128);
    spinlock.* = 0;
}

inline fn spin_lock_acquire_sw(lock: *u32) void {
    var tmp0: u32 = undefined;
    var tmp1: u32 = undefined;
    // Copied from pico SDK spin_lock.h
    asm volatile (
        \\ 1: ldaex %[t1], [%[lock]]         // Load the lock value with linked store
        \\    movs %[t0], #1                 // From PICO: "fill dependency slot" ...?
        \\    cmp %[t1], #0                  // check if lock is taken
        \\    bne 1b                         // retry if lock is taken
        \\    strex %[t1], %[t0], [%[lock]]  // attempt to claim the lock
        \\   cmp %[t1], #0                 //  check if we got it
        \\  bne 1b                       //   retry if not
        //\\ dmb                         //    finally, memory barrier
        : [t0] "=&r" (tmp0),
          [t1] "=&r" (tmp1),
        : [lock] "r" (lock),
        : .{ .memory = true });
}

inline fn spin_lock_release_sw(lock: *u32) void {
    const zero: u32 = 0;
    asm volatile (
        \\ stl %[zero], [%[lock]] // store with release semantics
        :
        : [zero] "r" (zero),
          [lock] "r" (lock),
    );
}

pub const spin_lock_acquire = spin_lock_acquire_hw;
pub const spin_lock_release = spin_lock_release_hw;
