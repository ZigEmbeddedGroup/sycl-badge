const microzig = @import("microzig");
const timer = @import("timer.zig");

const ws2812_program = blk: {
    @setEvalBranchQuota(10_000);
    break :blk microzig.hal.pio.assemble(
        \\;
        \\; Copyright (c) 2020 Raspberry Pi (Trading) Ltd.
        \\;
        \\; SPDX-License-Identifier: BSD-3-Clause
        \\;
        \\.program ws2812
        \\.side_set 1
        \\
        \\.define public T1 2
        \\.define public T2 5
        \\.define public T3 3
        \\
        \\.wrap_target
        \\bitloop:
        \\    out x, 1       side 0 [T3 - 1] ; Side-set still takes place when instruction stalls
        \\    jmp !x do_zero side 1 [T1 - 1] ; Branch on the bit we shifted out. Positive pulse
        \\do_one:
        \\    jmp  bitloop   side 1 [T2 - 1] ; Continue driving high, for a long pulse
        \\do_zero:
        \\    nop            side 0 [T2 - 1] ; Or drive low, for a short pulse
        \\.wrap
    , .{}).get_program_by_name("ws2812");
};

const pio_cycles_per_bit: comptime_int = ws2812_program.defines[0].value + //T1
    ws2812_program.defines[1].value + //T2
    ws2812_program.defines[2].value; //T3

const pio_target_bitrate = 800_000; // bits per second

const pio_reset_us = 50;
const pio_transaction_us = 1_000_000 * 4 * 32 / pio_target_bitrate;
const pio_min_send_interval = pio_transaction_us + pio_reset_us + 20; // 20 uS safety in case pio clock is off

const pio = microzig.board.neopixel_pio;
const sm: microzig.hal.pio.StateMachine = .sm0;
const pin = microzig.board.neopixel_pin;

pub fn init() void {
    pio.gpio_init(pin);
    pio.sm_set_pindir(sm, pin, 1, .out) catch @panic("neopixel setup failed");

    const div = @as(f32, @floatFromInt(microzig.hal.clock_config.sys.?.frequency())) /
        (pio_target_bitrate * pio_cycles_per_bit);

    pio.sm_load_and_start_program(sm, ws2812_program, .{
        .clkdiv = .from_float(div),
        .pin_mappings = .{
            .side_set = .single(pin),
        },
        .shift = .{
            .out_shiftdir = .left,
            .autopull = true,
            .pull_threshold = 0,
            .join_tx = true,
        },
    }) catch @panic("neopixel setup failed");
    pio.sm_set_enabled(sm, true);
}

var pixels_dirty: bool = false;
var pixel_data: [4]u32 = @splat(0);
var next_send_time: u64 = 0;

pub inline fn poll() void {
    if (pixels_dirty) {
        poll_outline();
    }
}

noinline fn poll_outline() void {
    if (can_send_pixels()) {
        send_pixels();
    }
}

fn can_send_pixels() bool {
    return pio.sm_fifo_level(sm, .tx) == 0 and
        timer.micros() >= next_send_time;
}

fn send_pixels() void {
    do_write_pixels();
    next_send_time = timer.micros() + pio_min_send_interval;
    pixels_dirty = false;
}

noinline fn do_write_pixels() linksection(".data") void {
    const ptr = pio.sm_get_tx_fifo(sm);
    ptr.* = pixel_data[0];
    ptr.* = pixel_data[1];
    ptr.* = pixel_data[2];
    ptr.* = pixel_data[3];
}

pub fn set_neopixels(noalias data: *const [4]u32) void {
    // The neopixels from the cart are left-to-right,
    // but we set them right-to-left.
    // This is some black magic to reverse the order.
    const data0 = @byteSwap(data[0]);
    const data1 = @byteSwap(data[1]);
    const data2 = @byteSwap(data[2]);
    const data3 = @byteSwap(data[3]);

    const word_pixel_data: [*]volatile u32 = &pixel_data;
    const half_pixel_data: [*]volatile u16 = @ptrCast(&pixel_data);
    const byte_pixel_data: [*]volatile u8 = @ptrCast(&pixel_data);
    word_pixel_data[0] = data3;
    byte_pixel_data[0] = @truncate(data2 >> 16);
    half_pixel_data[2] = @truncate(data1);
    half_pixel_data[3] = @truncate(data2);
    word_pixel_data[2] = data1;
    half_pixel_data[4] = @intCast(data1 >> 16);
    byte_pixel_data[10] = @truncate(data0);
    byte_pixel_data[11] = @truncate(data2 >> 24);
    word_pixel_data[3] = data0 & 0xFFFFFF00;

    pixels_dirty = true;
}

pub noinline fn reset() linksection(".data") void {
    @memset(&pixel_data, 0);
    pixels_dirty = true;
}
