const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

const Ray = @This();

origin: Vec3,
direction: Vec3,

pub fn init(origin: Vec3, direction: Vec3) Ray {
    return Ray{
        .origin = origin,
        .direction = direction,
    };
}

pub fn at(self: *const Ray, t: f32) Vec3 {
    return self.origin.add(self.direction.mul_scalar(t));
}
