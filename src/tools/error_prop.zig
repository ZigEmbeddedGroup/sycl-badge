const std = @import("std");

pub const Tolerance = struct {
    min: f64,
    max: f64,

    pub fn percent(value: f64) Tolerance {
        return .{
            .min = 1.0 - (value / 100.0),
            .max = 1.0 + (value / 100.0),
        };
    }
};

pub fn Range(comptime T: type) type {
    return struct {
        min: T,
        max: T,

        fn si_prefix(exp: i8) fn (T, Tolerance) R {
            return struct {
                fn func(value: T, tolerance: Tolerance) R {
                    const prefix = std.math.pow(T, 10, exp);
                    return .{
                        .min = prefix * value * tolerance.min,
                        .max = prefix * value * tolerance.max,
                    };
                }
            }.func;
        }

        pub const kilo = si_prefix(3);

        const R = @This();

        // generic function that runs the operation every which way, and picks
        // the min and max without thinking too hard
        fn propagate(op: fn (T, T) T) fn (R, R) R {
            return struct {
                pub fn func(r1: R, r2: R) R {
                    const results: @Vector(4, T) = .{
                        op(r1.min, r2.min),
                        op(r1.min, r2.max),
                        op(r1.max, r2.min),
                        op(r1.max, r2.max),
                    };

                    return .{
                        .min = @reduce(.Min, results),
                        .max = @reduce(.Max, results),
                    };
                }
            }.func;
        }

        fn add_op(a: T, b: T) T {
            return a + b;
        }

        fn mul_op(a: T, b: T) T {
            return a * b;
        }

        fn div_op(a: T, b: T) T {
            return a / b;
        }

        fn parallel_op(a: T, b: T) T {
            return (a * b) / (a + b);
        }

        fn divider_op(bottom: T, top: T) T {
            return bottom / (bottom + top);
        }

        pub const add = propagate(add_op);
        pub const mul = propagate(mul_op);
        pub const div = propagate(div_op);
        pub const parallel = propagate(parallel_op);
        pub const divider = propagate(divider_op);

        pub fn mul_scalar(self: R, scalar: T) R {
            return .{
                .min = self.min * scalar,
                .max = self.max * scalar,
            };
        }

        pub const RoundMode = enum {
            /// Smaller range
            optimistic,
            /// Bigger range
            pessimistic,
        };

        pub fn round(self: R, mode: RoundMode) R {
            return switch (mode) {
                .pessimistic => .{
                    .min = @floor(self.min),
                    .max = @ceil(self.max),
                },
                .optimistic => @panic("TODO"),
            };
        }

        pub fn pad(self: R, padding: T) R {
            return .{
                .min = self.min - padding,
                .max = self.max + padding,
            };
        }

        fn within(point: T, range: R) bool {
            return point >= range.min and point <= range.max;
        }
        pub fn overlaps(a: R, b: R) bool {
            return within(a.min, b) or
                within(a.max, b) or
                within(b.min, a) or
                within(b.max, a);
        }
    };
}
