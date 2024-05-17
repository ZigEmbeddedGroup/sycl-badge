pub const Tone = struct {
    frequency: u32,
    duration: u32,
};

const g3: u32 = 196;
const a3: u32 = 220;
const b3: u32 = 247;
const c4: u32 = 262;
const d4: u32 = 294;
const e4: u32 = 330;
const f4: u32 = 349;
const g4: u32 = 392;
const a4: u32 = 440;
const b4: u32 = 494;
const c5: u32 = 523;
const d5: u32 = 587;
const e5: u32 = 659;

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
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = c4, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    .{ .frequency = g3, .duration = 20 },
    .{ .frequency = g4, .duration = 10 },
    // melody comes in...
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
};

pub const melody = [_]Tone{
    .{ .frequency = 0, .duration = 480 },
    .{ .frequency = d4 << 16 | e4, .duration = 60 },
    .{ .frequency = g4 << 16 | e4, .duration = 50 },
    .{ .frequency = a4, .duration = 10 },
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
    .{ .frequency = f4 << 16 | g4, .duration = (20 << 8) },
};
