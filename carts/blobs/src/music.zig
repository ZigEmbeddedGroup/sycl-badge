const std = @import("std");

pub const Tone = struct {
    frequency: u32,
    duration: u32,
};

const f3: u32 = 175;
const g3: u32 = 196;
const a3: u32 = 220;
const asharp3: u32 = 233;
const b3: u32 = 247;
const c4: u32 = 262;
const d4: u32 = 294;
const e4: u32 = 330;
const f4: u32 = 349;
const g4: u32 = 392;
const gsharp4: u32 = 415;
const a4: u32 = 440;
const b4: u32 = 494;
const c5: u32 = 523;
const csharp5: u32 = 554;
const d5: u32 = 587;
const dsharp5: u32 = 622;
const e5: u32 = 659;

// One beat is 30 ticks (swung: root 20 + chick 10), 4 beats per bar.
// Form: intro (4 bars), A (4 bars, half cadence on G), B (4 bars),
// A' (4 bars, resolves to C), then loop. bass and melody must stay the
// same total length, this is checked at comptime below.

pub const bass = [_]Tone{
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = 0, .duration = 30 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = 0, .duration = 30 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = a3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = b3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    // 240
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    // 360
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    // 480 melody comes in...
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    //
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    //
    .{ .frequency = d4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = d4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = d4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = d4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    // B section
    .{ .frequency = f3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = f3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    //
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = b3, .duration = 10 },
    .{ .frequency = asharp3, .duration = 20 },
    .{ .frequency = a3, .duration = 70 }, // hold
    //
    .{ .frequency = f3, .duration = 20 },
    .{ .frequency = f4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = f4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = f4, .duration = 10 },
    .{ .frequency = b3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },

    .{ .frequency = c4, .duration = 30 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = a3, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = b3, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
};

pub const melody = [_]Tone{
    .{ .frequency = 0, .duration = 480 },
    .{ .frequency = d4 << 16 | e4, .duration = 60 },
    .{ .frequency = g4 << 16 | e4, .duration = 50 },
    .{ .frequency = a4, .duration = 10 },
    //
    .{ .frequency = (b4 - 20) << 16 | b4, .duration = 30 },
    .{ .frequency = (a4 - 20) << 16 | a4, .duration = 30 },
    .{ .frequency = d4 << 16 | g4, .duration = 90 },
    .{ .frequency = g4 << 16 | e4, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = d5 << 16 | e5, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = c5 << 16 | d5, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = b4 << 16 | c5, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = a4 << 16 | b4, .duration = 20 },
    .{ .frequency = 0, .duration = 10 },
    .{ .frequency = g4 << 16 | a4, .duration = 60 },
    //

    // B section
    .{ .frequency = 0, .duration = 20 },
    .{ .frequency = a4 - 10, .duration = 10 },
    .{ .frequency = gsharp4 | (gsharp4 - 4) << 16, .duration = 20 },
    .{ .frequency = a4 - 5, .duration = 10 },
    .{ .frequency = c5 << 16 | c5 - 30, .duration = 25 },
    .{ .frequency = 0, .duration = 5 },
    .{ .frequency = d5 << 16 | d5 - 40, .duration = 30 },
    //
    .{ .frequency = e5 | (e5 - 10) << 16, .duration = 20 },
    .{ .frequency = dsharp5, .duration = 10 },
    .{ .frequency = d5, .duration = 20 },
    .{ .frequency = csharp5 | (csharp5 - 40) << 16, .duration = 70 },

    .{ .frequency = 0, .duration = 20 },
    .{ .frequency = c5 - 20, .duration = 10 },
    .{ .frequency = a4 - 20, .duration = 20 },
    .{ .frequency = c5, .duration = 10 },
    .{ .frequency = b4 | (b4 - 20) << 16, .duration = 30 },
    .{ .frequency = f4 | (g4 - 20) << 16, .duration = 30 },
    .{ .frequency = c5, .duration = 30 },
    .{ .frequency = 0, .duration = 90 },
};

fn totalTicks(tones: []const Tone) u32 {
    var total: u32 = 0;
    for (tones) |t| {
        // blobs.zig uses the duration directly as the tone length in ticks,
        // so it must be plain sustain ticks (no attack/decay/release bits).
        // Rests are never sent to the mixer so they can be any length.
        if (t.frequency != 0 and t.duration > 0xff) @compileError(std.fmt.comptimePrint(
            "tone duration 0x{x} is not a plain tick count",
            .{t.duration},
        ));
        total += t.duration;
    }
    return total;
}

comptime {
    const bass_ticks = totalTicks(&bass);
    const melody_ticks = totalTicks(&melody);
    if (bass_ticks != melody_ticks) @compileError(std.fmt.comptimePrint(
        "bass ({} ticks) and melody ({} ticks) are out of sync",
        .{ bass_ticks, melody_ticks },
    ));
    if (bass_ticks % 120 != 0) @compileError(std.fmt.comptimePrint(
        "song length ({} ticks) is not a whole number of 4-beat bars",
        .{bass_ticks},
    ));
}
