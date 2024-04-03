const microzig = @import("microzig");
const QSPI = microzig.chip.peripherals.QSPI;

const types = microzig.chip.types.peripherals.QSPI;
pub const CSMODE = types.QSPI_CTRLB__CSMODE;
pub const DATALEN = types.QSPI_CTRLB__DATALEN;
pub const MODE = types.QSPI_CTRLB__MODE;
pub const LOOPEN = types.QSPI_CTRLB__LOOPEN;
pub const ADDRLEN = types.QSPI_INSTRFRAME__ADDRLEN;
pub const OPTCODELEN = types.QSPI_INSTRFRAME__OPTCODELEN;
pub const TFRTYPE = types.QSPI_INSTRFRAME__TFRTYPE;
pub const WIDTH = types.QSPI_INSTRFRAME__WIDTH;

pub fn init() void {
    reset();
    defer enable();

    QSPI.BAUD.modify(.{
        .BAUD = 2,
    });
    QSPI.CTRLB.modify(.{
        .MODE = .{ .value = .MEMORY },
        .DATALEN = .{ .value = .@"8BITS" },
        .CSMODE = .{ .value = .LASTXFER },
    });

    for (microzig.board.qspi) |qspi_pin|
        qspi_pin.set_mux(.H);
}

pub fn reset() void {
    QSPI.CTRLA.modify(.{
        .SWRST = 1,
    });
}

pub fn enable() void {
    QSPI.CTRLA.modify(.{
        .ENABLE = 1,
    });
}

pub fn disable() void {
    QSPI.CTRLA.modify(.{
        .ENABLE = 0,
    });
}
