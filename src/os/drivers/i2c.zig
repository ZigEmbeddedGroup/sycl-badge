const microzig = @import("microzig");
const board = microzig.board;
const rp2xxx = microzig.hal;

pub fn init() void {
    const i2c = board.rev1.i2c;

    i2c.sda.set_slew_rate(.slow);
    i2c.scl.set_slew_rate(.slow);

    i2c.sda.set_schmitt_trigger_enabled(true);
    i2c.scl.set_schmitt_trigger_enabled(true);

    i2c.sda.set_function(.i2c);
    i2c.scl.set_function(.i2c);

    i2c.instance.apply(.{
        .clock_config = rp2xxx.clock_config,
    });
}

pub fn poll() void {}
