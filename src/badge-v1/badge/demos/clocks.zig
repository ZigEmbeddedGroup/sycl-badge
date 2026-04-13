const microzig = @import("microzig");
const clocks = microzig.hal.clocks;

pub fn main() void {
    const state = clocks.get_state();
    _ = state;

    while (true) {}
}
