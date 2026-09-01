const microzig = @import("microzig");
const board = microzig.board;
const adc = microzig.hal.adc;

// Each physical revision of the SYCL badge board has
// a hardwired voltage divider on gpio 47/adc7 for
// detecting the hardware version from software.
// Based on the voltage reading from this pin, we can
// determine the version of  the hardware.
// Rev 0 has no connection - 0v with pull-down (< 235 ADC reading)
// Rev 1 - 0.27v (235 - 430 ADC reading)
// Add other revisions here
const r0_max = 235;
const r1_max = 430;
const num_retries: usize = 10;

/// Set this to true to add the ADC value to the
/// version readout on the cart select screen
/// and debug menu
pub var debug = false;

/// The hardware revison.
pub var revision: Revision = .unknown;

pub const Revision = enum(u16) {
    /// r0 has a green board
    r0,
    /// r1 has a purple board.
    /// This revision adds an audio driver chip which
    /// receives digital level signals.
    r1,
    unknown = 0xFFFF,

    pub fn str(r: Revision) []const u8 {
        return switch (r) {
            .r0 => "0",
            .r1 => "1",
            .unknown => "<UNKNOWN!!!>",
        };
    }
};

/// The raw ADC value, for debugging purposes
pub var raw_reading: u12 = 4095;

/// Reads the ADC to determine the version
pub fn init() void {
    board.revision_pin.set_direction(.in);
    board.revision_pin.set_pull(.down);
    board.revision_pin.set_function(.sio);
    adc.set_enabled(true);
    raw_reading = for (0..num_retries) |_| {
        break adc.convert_one_shot_blocking(board.revision_adc) catch continue;
    } else 4095;
    if (raw_reading < r0_max) {
        revision = .r0;
    } else if (raw_reading < r1_max) {
        revision = .r1;
    } else {
        revision = .unknown;
        debug = true;
    }
}
