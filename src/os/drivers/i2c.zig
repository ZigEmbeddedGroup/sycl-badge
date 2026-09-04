const microzig = @import("microzig");
const board = microzig.board;
const rp2xxx = microzig.hal;

const rev = @import("rev.zig");

const Setup = struct {
    instance: rp2xxx.i2c.I2C,
    sda: rp2xxx.gpio.Pin,
    scl: rp2xxx.gpio.Pin,
};

pub fn init() void {
    const setup: Setup = switch (rev.revision) {
        .r0 => return, // Doesn't have the I2C connector
        .r1 => .{
            .instance = board.rev1.i2c.instance,
            .sda = board.rev1.i2c.sda,
            .scl = board.rev1.i2c.scl,
        },
        .r2 => .{
            .instance = board.rev2.i2c.instance,
            .sda = board.rev2.i2c.sda,
            .scl = board.rev2.i2c.scl,
        },
        .unknown => @panic("unknown revision"),
    };

    setup.sda.set_slew_rate(.slow);
    setup.scl.set_slew_rate(.slow);

    setup.sda.set_schmitt_trigger_enabled(true);
    setup.scl.set_schmitt_trigger_enabled(true);

    setup.sda.set_function(.i2c);
    setup.scl.set_function(.i2c);

    setup.instance.apply(.{
        .clock_config = rp2xxx.clock_config,
    });
}

pub fn poll() void {
    // TODO: come up with an IO system for carts to communicate over I2C.
}
