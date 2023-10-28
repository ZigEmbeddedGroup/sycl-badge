const std = @import("std");
const microzig = @import("microzig");

const io = microzig.chip.peripherals;

// LED: PA23

pub fn main() !void {

    // PORT_PMUX__PMUXO
    const pingroup: [*]volatile microzig.chip.types.peripherals.PORT.GROUP = @ptrCast(@alignCast(io.PORT));

    const pingroup_a = &pingroup[0]; // "Port A"

    pingroup_a.DIR.write(.{ .DIR = (1 << 23) });

    while (true) {
        pingroup_a.OUT.write(.{ .OUT = (1 << 23) });
        microzig.core.experimental.debug.busy_sleep(100_000);

        pingroup_a.OUT.write(.{ .OUT = 0 });
        microzig.core.experimental.debug.busy_sleep(200_000);
    }

    // CLK_PORT_APB must have the PORT bus enabled

}
