const cart = @import("cart-api");

pub const Note = struct {
    duration: f32,
    frequency: f32,

    pub const A5: f32 = 880.0000;
    pub const Ab5: f32 = 830.6094;
    pub const G5: f32 = 783.9909;
    pub const Gb5: f32 = 739.9888;
    pub const F5: f32 = 698.4565;
    pub const E5: f32 = 659.2551;
    pub const Eb5: f32 = 622.2540;
    pub const D5: f32 = 587.3295;
    pub const Db5: f32 = 554.3653;
    pub const C5: f32 = 523.2511;
    pub const B4: f32 = 493.8833;
    pub const Bb4: f32 = 466.1638;
    pub const A4: f32 = 440.0000;
    pub const Ab4: f32 = 415.3047;
    pub const G4: f32 = 391.9954;
    pub const Gb4: f32 = 369.9944;
    pub const F4: f32 = 349.2282;
    pub const E4: f32 = 329.6276;
    pub const Eb4: f32 = 311.1270;
    pub const D4: f32 = 293.6648;
    pub const Db4: f32 = 277.1826;
    pub const C4: f32 = 261.6256;
    pub const B3: f32 = 246.9417;
    pub const Bb3: f32 = 233.0819;
    pub const A3: f32 = 220.0000;
    pub const Ab3: f32 = 207.6523;
    pub const G3: f32 = 195.9977;
    pub const Gb3: f32 = 184.9972;
    pub const F3: f32 = 174.6141;
    pub const E3: f32 = 164.8138;
    pub const Eb3: f32 = 155.5635;
    pub const D3: f32 = 146.8324;
    pub const Db3: f32 = 138.5913;
    pub const C3: f32 = 130.8128;
    pub const B2: f32 = 123.4708;
    pub const Bb2: f32 = 116.5409;
    pub const A2: f32 = 110.0000;
};

const tempo = 0.78;
const song: [3][]const Note = .{
    &.{
        .{ .duration = tempo * 0.75, .frequency = Note.F5 },
        .{ .duration = tempo * 0.25, .frequency = Note.Db5 },
        .{ .duration = tempo * 2.00, .frequency = Note.Ab4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Bb4 },
        .{ .duration = tempo * 3.00, .frequency = Note.C5 },
        .{ .duration = tempo * 1.00, .frequency = Note.Db5 },
        .{ .duration = tempo * 0.75, .frequency = Note.Eb5 },
        .{ .duration = tempo * 0.25, .frequency = Note.F5 },
        .{ .duration = tempo * 2.00, .frequency = Note.Gb5 },
        .{ .duration = tempo * 1.00, .frequency = Note.F5 },
        .{ .duration = tempo * 1.50, .frequency = Note.F5 },
        .{ .duration = tempo * 0.50, .frequency = Note.Eb5 },
        .{ .duration = tempo * 0.80, .frequency = Note.Db5 },
        .{ .duration = tempo * 0.20, .frequency = Note.Eb5 },
        .{ .duration = tempo / 7.0, .frequency = Note.Eb5 },
        .{ .duration = tempo / 7.0, .frequency = Note.F5 },
        .{ .duration = tempo / 7.0, .frequency = Note.Eb5 },
        .{ .duration = tempo / 7.0, .frequency = Note.D5 },
        .{ .duration = tempo / 7.0, .frequency = Note.Eb5 },
        .{ .duration = tempo / 7.0, .frequency = Note.F5 },
        .{ .duration = tempo / 7.0, .frequency = Note.Gb5 },
        //
        .{ .duration = tempo * 0.75, .frequency = Note.F5 },
        .{ .duration = tempo * 0.25, .frequency = Note.Db5 },
        .{ .duration = tempo * 2.00, .frequency = Note.Ab4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Bb4 },
        .{ .duration = tempo * 3.00, .frequency = Note.C5 },
        .{ .duration = tempo * 1.00, .frequency = Note.Db5 },
        .{ .duration = tempo * 0.75, .frequency = Note.Eb5 },
        .{ .duration = tempo * 0.25, .frequency = Note.F5 },
        .{ .duration = tempo * 2.00, .frequency = Note.Gb5 },
        .{ .duration = tempo * 1.00, .frequency = Note.F5 },
        .{ .duration = tempo * 1.50, .frequency = Note.F5 },
        .{ .duration = tempo * 0.50, .frequency = Note.Eb5 },
        .{ .duration = tempo * 1.00, .frequency = Note.Db5 },
        .{ .duration = tempo * 0.50, .frequency = Note.C5 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db5 },
    },
    &.{
        .{ .duration = tempo * 8.00, .frequency = 0 },
        .{ .duration = tempo * 0.75, .frequency = Note.Gb4 },
        .{ .duration = tempo * 0.25, .frequency = Note.Ab4 },
        .{ .duration = tempo * 2.00, .frequency = Note.Bb4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Ab4 },
        .{ .duration = tempo * 2.00, .frequency = 0 },
        .{ .duration = tempo * 0.50, .frequency = Note.F4 },
        .{ .duration = tempo * 0.50, .frequency = 0 },
        .{ .duration = tempo * 0.50, .frequency = Note.Gb4 },
        .{ .duration = tempo * 7.50, .frequency = 0 },
        .{ .duration = tempo * 0.50, .frequency = Note.F4 },
        .{ .duration = tempo * 0.50, .frequency = 0 },
        .{ .duration = tempo * 0.75, .frequency = Note.Gb4 },
        .{ .duration = tempo * 0.25, .frequency = Note.Ab4 },
        .{ .duration = tempo * 2.00, .frequency = Note.Bb4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Ab4 },
        .{ .duration = tempo * 2.00, .frequency = 0 },
        .{ .duration = tempo * 0.50, .frequency = Note.F4 },
        .{ .duration = tempo * 0.50, .frequency = 0 },
        .{ .duration = tempo * 0.50, .frequency = Note.F4 },
    },
    &.{
        .{ .duration = tempo * 0.50, .frequency = Note.Db3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Bb3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Gb4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        //
        .{ .duration = tempo * 0.50, .frequency = Note.Db3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Bb3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 1.00, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.C4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Gb4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
        .{ .duration = tempo * 0.50, .frequency = Note.Db4 },
        .{ .duration = tempo * 0.50, .frequency = Note.Ab3 },
    },
};

var time: f32 = 0.0;
var channels_note_index = [1]usize{0} ** song.len;
var channels_note_start = [1]f32{0.0} ** song.len;

pub export fn start() void {}

pub export fn update() void {
    time += 1.0 / 10.0; // TODO: should be higher fps once lcd is dma'd
    for (
        0..,
        &channels_note_index,
        &channels_note_start,
        &song,
    ) |channel_idx, *note_index, *note_start, notes| {
        if (note_index.* > notes.len) continue;
        const next_note_time =
            note_start.* + if (note_index.* > 0) notes[note_index.* - 1].duration else 0.0;
        if (time >= next_note_time) {
            note_index.* += 1;
            if (note_index.* > notes.len) continue;
            const note = notes[note_index.* - 1];
            note_start.* = next_note_time;
            const vol: u32 = if (cart.controls.a) 25 else 50;
            const fun: cart.ToneOptions.Flags.Function = if (cart.controls.a) .pulse1 else .triangle;
            cart.tone(.{
                .frequency = @intFromFloat(note.frequency + 0.5),
                .duration = @intFromFloat(@max(note.duration - 0.04, 0.0) * 60),
                .volume = vol,
                .flags = .{
                    .channel = @intCast(channel_idx),
                    .function = fun,
                },
            });
        }
    }
}
