const cart = @import("cart-api");
const std = @import("std");

const DisplayColor = cart.DisplayColor;

const W = cart.screen_width;
const H = cart.screen_height;
const HW = W/2;
const HH = H/2;

const white = DisplayColor{ .b = 31, .g = 63, .r = 31 };
const black = DisplayColor{ .b = 0, .g = 0, .r = 0 };
const gray = DisplayColor{ .b = 1, .g = 2, .r = 1 };

// Compute equal temperment frequency from midi note number
// Compatible with fractional note numbers for microtonal adjustment
fn freqFromMidi(midi: f32) f32 {
    return 440.0 * @exp2((midi - 69.0) / 12.0);
}

const c_maj = [_]f32 {
    60, // C4
    62, // D4
    64, // E4
    65, // F4
    67, // G4
    69, // A4
    71, // B4
    72, // C5
};
const names: [c_maj.len][:0]const u8 = .{
    "C4",
    "D4",
    "E4",
    "F4",
    "G4",
    "A4",
    "B4",
    "C4",
};
const freqs = blk: {
    var fq: [c_maj.len]f32 = undefined;
    for (&fq, c_maj) |*f, note| {
        // TODO: Temporary shift two octaves lower for sw speeds
        f.* = freqFromMidi(note - 24);
    }
    break :blk fq;
};

var note_id: u32 = names.len;
var global_frame_num: u32 = 0;

const micros_per_note: u64 = 500_000; // 0.5 second per note
var change_time: u64 = 0;
var last_abs_time: u64 = 0;

export fn start() void {
    change_time = cart.microsSinceBoot() + micros_per_note;
}

export fn update() void {
    const abs_time = cart.microsSinceBoot();
    defer last_abs_time = abs_time;

    const delta_sec: f32 = @as(f32, @floatFromInt(abs_time - last_abs_time)) * 0.000_001;
    _ = delta_sec;

    if (global_frame_num < 2) {
        cart.rect(.{
            .x = 0,
            .y = 0,
            .width = W,
            .height = H,
            .fill_color = gray,
        });
        global_frame_num += 1;
    } else {
        //cart.trace("[frame]");
    }

    if (abs_time >= change_time) {
        while (abs_time >= change_time) {
            change_time += micros_per_note;
            if (note_id >= c_maj.len) {
                note_id = 0;
            } else {
                note_id += 1;
            }
        }

        if (note_id >= c_maj.len) {
            cart.tone2(.stop);
        } else {
            cart.tone2(.{
                .frequency = freqs[note_id],
                .volume = 1.0,
            });
        }
    }

    const text = if (note_id >= c_maj.len)
        ""
    else names[note_id];

    // Clear the center of the screen with a white rect
    cart.rect(.{
        .x = HW-16,
        .y = HH-8,
        .width = 32,
        .height = 16,
        .fill_color = white,
    });
    // Draw the text
    cart.text(.{
        .str = text,
        .x = HW-8,
        .y = HH-4,
        .text_color = black,
    });
}