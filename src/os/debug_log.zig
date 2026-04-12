/// Simple debug log ring buffer for early-boot and loader/storage diagnostics
const std = @import("std");

pub const ENTRY_LEN = 128;
pub const MAX_ENTRIES = 32;

var entries: [MAX_ENTRIES][ENTRY_LEN]u8 = undefined;
var lengths: [MAX_ENTRIES]usize = undefined;
var head: usize = 0;
var count: usize = 0;

/// Record a message into the ring buffer (truncates if longer than ENTRY_LEN-1)
pub fn record(msg: []const u8) void {
    var idx: usize = 0;
    if (count < MAX_ENTRIES) {
        idx = (head + count) % MAX_ENTRIES;
        count += 1;
    } else {
        idx = head;
        head = (head + 1) % MAX_ENTRIES;
    }

    const to_copy = if (msg.len < ENTRY_LEN - 1) msg.len else ENTRY_LEN - 1;
    @memcpy(entries[idx][0..to_copy], msg[0..to_copy]);
    lengths[idx] = to_copy;
    entries[idx][to_copy] = 0; // NUL terminator for convenience
}

/// Iterate over entries in oldest->newest order and invoke `callback` for each.
/// After iteration the buffer is cleared.
pub fn forEachEntry(callback: fn (msg: []const u8) void) void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const idx = (head + i) % MAX_ENTRIES;
        callback(entries[idx][0..lengths[idx]]);
    }

    // Clear buffer after dumping
    head = 0;
    count = 0;
}
