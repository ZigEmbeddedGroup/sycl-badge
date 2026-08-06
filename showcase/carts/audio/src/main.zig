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
const lt_blue = DisplayColor{ .b = 31, .g = 15, .r = 7 };
const yellow = DisplayColor{ .b = 0, .g = 63, .r = 31 };

// Compute equal temperment frequency from midi note number
// Compatible with fractional note numbers for microtonal adjustment
fn freqFromMidi(midi: f32) f32 {
    // exp2 causes illegal instruction, so we use exp instead to emulate
    return 440.0 * @exp((midi - 69.0) * (@log(2.0) / 12.0));
}

const major = [_]u32 {
    0,
    2,
    4,
    5,
    7,
    9,
    11,
    12,
};
const note_names_sharps: [12][]const u8 = .{
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
};
const note_names_flats: [12][]const u8 = .{
    "C",
    "Db",
    "D",
    "Eb",
    "E",
    "F",
    "Gb",
    "G",
    "Ab",
    "A",
    "Bb",
    "B",
};
const major_scale_uses_sharps: [12]bool = .{
    true,  // Techincally C major has neither sharps nor flats
    false, // Db major, though sometimes C# major
    true,  // D major
    false, // Eb major
    true,  // E major
    false, // F major
    false, // Can be either, F# major (#) or Gb major (b)
    true,  // G major
    false, // Ab major
    true,  // A major
    false, // Bb major
    true,  // B major
};

const wave_shapes = [_]cart.Tone2Options.Shape{
    .square,
    .triangle,
    .sawtooth,
};
var active_wave_shape: u32 = 0;

var fundamental: u32 = 48;
var scale_pos: u32 = major.len;
var global_frame_num: u32 = 0;
var short: bool = false;

const micros_per_note: u64 = 500_000; // 0.5 second per note
var change_time: u64 = 0;
var last_abs_time: u64 = 0;

var volume: f32 = 1.0;

export fn start() void {
    change_time = cart.microsSinceBoot() + micros_per_note;
}

var was_down = false;
var was_up = false;

const piano_min_note = 21;
const piano_max_note = 108;
const piano_max_fundamental = piano_max_note - 12;

export fn update() void {
    const abs_time = cart.microsSinceBoot();
    defer last_abs_time = abs_time;

    const delta_sec: f32 = @as(f32, @floatFromInt(abs_time - last_abs_time)) * 0.000_001;

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

    var note_changed = false;

    const controls = cart.controls;

    if (controls.left) {
        volume = @max(0.0, volume - delta_sec);
    }
    if (controls.right) {
        volume = @min(1.0, volume + delta_sec);
    }

    var selected_param: enum {
        octave,
        note,
        shape,
    } = .octave;

    if (controls.a) {
        selected_param = .shape;
    } else if (controls.b) {
        selected_param = .note;
    }

    if (controls.down and !was_down) {
        switch (selected_param) {
            .octave => if (fundamental >= piano_min_note + 12) {
                fundamental -= 12;
                note_changed = true;
            },
            .note => if (fundamental > piano_min_note) {
                fundamental -= 1;
                note_changed = true;
            },
            .shape => {
                active_wave_shape += 1;
                if (active_wave_shape >= wave_shapes.len) {
                    active_wave_shape = 0;
                }
                note_changed = true;
            },
        }
        
    }
    if (controls.up and !was_up) {
        switch (selected_param) {
            .octave => if (fundamental <= piano_max_fundamental - 12) {
                fundamental += 12;
                note_changed = true;
            },
            .note => if (fundamental < piano_max_fundamental) {
                fundamental += 1;
                note_changed = true;
            },
            .shape => {
                if (active_wave_shape == 0) {
                    active_wave_shape = wave_shapes.len;
                }
                active_wave_shape -= 1;
                note_changed = true;
            }
        }
    }
    was_down = controls.down;
    was_up = controls.up;

    if (controls.left or controls.right) {
        cart.setGlobalVolume(volume);
    }

    if (abs_time >= change_time or note_changed) {
        while (abs_time >= change_time) {
            change_time += micros_per_note;
            if (scale_pos >= major.len) {
                scale_pos = 0;
                short = !short;
            } else {
                scale_pos += 1;
            }
        }

        if (scale_pos >= major.len) {
            cart.tone2(.stop);
        } else {
            cart.tone2(.{
                .frequency = freqFromMidi(@floatFromInt(fundamental + major[scale_pos])),
                .volume = 1.0,
                .duration = if (short) 0.25 else -1.0,
                .flags = .{ .shape = wave_shapes[active_wave_shape] },
            });
        }
    }

    const note_names = if (major_scale_uses_sharps[fundamental % 12])
        note_names_sharps
    else note_names_flats;

    const scale_name = note_names[fundamental % 12];

    var buf: [20]u8 = undefined;

    const volume_top = HH-10;
    const volume_bot = volume_top + 20;
    const vol_width = 12*8 + 2*8;

    // Clear behind the scale name
    const max_scale_width = 10*8;
    cart.rect(.{
        .x = HW - max_scale_width/2,
        .y = volume_top - 10,
        .width = max_scale_width,
        .height = 8,
        .fill_color = gray,
    });

    // Then draw the scale name
    const text = std.fmt.bufPrint(&buf, "{s}{d} major", .{scale_name, fundamental / 12 - 1})
        catch "Err";
    var x_pos: u16 = @intCast(HW - text.len * 4);
    cart.text(.{
        .str = text[0..scale_name.len],
        .x = x_pos,
        .y = volume_top - 10,
        .text_color = if (selected_param == .note) yellow else white,
    });
    x_pos += @intCast(8*scale_name.len);
    cart.text(.{
        .str = text[scale_name.len..][0..2],
        .x = x_pos,
        .y = volume_top - 10,
        .text_color = if (selected_param == .octave) yellow else white,
    });
    x_pos += 8*2;
    cart.text(.{
        .str = text[scale_name.len+2..],
        .x = x_pos,
        .y = volume_top - 10,
        .text_color = white,
    });

    // Clear the center of the screen with a white rect
    cart.rect(.{
        .x = HW-vol_width/2 - 2,
        .y = volume_top,
        .width = vol_width + 4,
        .height = 20,
        .fill_color = white,
    });
    // Draw the volume slider
    cart.rect(.{
        .x = HW-vol_width/2,
        .y = HH-8,
        .width = @intFromFloat(volume * @as(comptime_float, vol_width) + 0.5),
        .height = 16,
        .fill_color = lt_blue,
    });

    // Draw the note name and frequency
    if (scale_pos < major.len) {
        const midi_note = fundamental + major[scale_pos];
        const freq = freqFromMidi(@floatFromInt(midi_note));
        const name = note_names[midi_note % 12];
        const note_text = std.fmt.bufPrint(&buf, "{s}{d} {d:5.1}Hz", .{ name, midi_note / 12 - 1, freq })
            catch "Err";
        // Draw the text
        cart.text(.{
            .str = note_text,
            .x = @intCast(HW-4*note_text.len),
            .y = HH-4,
            .text_color = black,
        });
    }

    // Clear behind the wave shape
    cart.rect(.{
        .x = HW - max_scale_width/2,
        .y = volume_bot + 2,
        .width = max_scale_width,
        .height = 8,
        .fill_color = gray,
    });

    // Draw the wave shape
    const wave_name = std.fmt.bufPrint(&buf, ".{s}", .{ @tagName(wave_shapes[active_wave_shape]) })
        catch "Err";
    cart.text(.{
        .str = wave_name,
        .x = @intCast(HW - wave_name.len * 4),
        .y = volume_bot + 2,
        .text_color = if (selected_param == .shape) yellow else white,
    });
}