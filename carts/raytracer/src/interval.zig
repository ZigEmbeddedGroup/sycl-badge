const std = @import("std");

const Interval = @This();

max: f32,
min: f32,

pub fn empty() Interval {
    return .{ .min = std.math.inf(f32), .max = -std.math.inf(f32) };
}

pub fn universe() Interval {
    return .{ .min = -std.math.inf(f32), .max = std.math.inf(f32) };
}

pub fn contains(self: *const Interval, x: f32) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: *const Interval, x: f32) bool {
    return self.min < x and x < self.max;
}

pub fn clamp(self: *const Interval, x: f32) f32 {
    if (x < self.min) {
        return self.min;
    } else if (x > self.max) {
        return self.max;
    }

    return x;
}
