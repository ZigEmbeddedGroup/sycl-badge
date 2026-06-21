//! PCB revision is detected at runtime on the badge using a voltage divider.
//!
//! This program helps lay out the ranges of values we expect to see, and what
//! the next voltage divider should look like.
//!
//! To begin, our first revision had nothing, we expect that this would show as
//! roughly zero on the ADC due to the floating pin. (This needs to be
//! confirmed).
//!
//!                       3.3V
//!                        |
//!                        R1
//!                        |
//! ADC INPUT -----+-------+
//!                |       |
//!               Rin      R2
//!                |       |
//!               GND     GND
//!
const std = @import("std");

const error_prop = @import("error_prop.zig");
const Range = error_prop.Range(f64);

// R1 values are in kilo ohms
var revision_resistors = [_]f64{
    // ADC counts less than revision 1 range means revision 0.
    100, // Starts at revision 1
};

pub fn calc_version_range(r1_scalar: f64) Range {
    // Datasheet says it's minimum 100K ohm, with no max, so set the max to 100M
    // since that's close enough to infinity for me. R2 can stay at 10k forever.
    // And we can alter the value of R1 for every version. Resistors will always
    // have a tolerance of 1%.
    const rin = Range{ .min = 100_000, .max = 100_000_000 };
    const r2: Range = .kilo(10, .percent(1));

    // The first selection of r1
    const r1: Range = .kilo(r1_scalar, .percent(1));
    const rbot = r2.parallel(rin);
    const divider_ratio = rbot.divider(r1);
    const adc_conversion = divider_ratio.mul_scalar(4096).round(.pessimistic).pad(50);
    return adc_conversion;
}

pub fn main() !void {
    var revision_adc_ranges: [revision_resistors.len]Range = undefined;
    for (&revision_adc_ranges, revision_resistors) |*adc_range, resistor| {
        adc_range.* = calc_version_range(resistor);
    }

    // Check that none of the ranges overlap
    for (revision_adc_ranges, 0..) |range_a, i| {
        for (revision_adc_ranges[i + 1 ..], 0..) |range_b, j| {
            if (range_a.overlaps(range_b)) {
                std.log.err("Revision {} overlaps with Revision {}: {} vs. {}", .{
                    i + 1,
                    j + i + 2,
                    range_a,
                    range_b,
                });
                std.process.exit(1);
            }
        }
    }

    for (revision_adc_ranges, 0..) |adc_range, i| {
        const revision = i + 1;
        std.log.info("revision {}: min={} max={}", .{ revision, adc_range.min, adc_range.max });
    }
}
