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

var note_id: u32 = 0;
var frame_num: u32 = 0;
var global_frame_num: u32 = 0;

export fn start() void {

}

export fn update() void {
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

    var text: [:0]const u8 = undefined;
    if (note_id >= c_maj.len) {
        //cart.tone2(.stop);
        text = "";
        frame_num += 1;
        if (frame_num >= 10) {
            note_id = 0;
            frame_num = 0;
        }
    } else {
        const freq = 440.0; //freqFromMidi(c_maj[note_id]);
        text = names[note_id];
        if (frame_num == 0) {
            _ = freq;
            // cart.tone2(.{
            //     .frequency = freq,
            //     .volume = 1.0,
            // });
            cart.tone(.{
                .frequency = 440,
                .duration = 60,
                .volume = 100,
                .flags = .{ .channel = .pulse1 },
            });
        }

        frame_num += 1;
        if (frame_num >= 10) {
            note_id += 1;
            frame_num = 0;
        }
    }

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