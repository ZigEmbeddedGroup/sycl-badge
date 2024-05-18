const std = @import("std");
const ppm = @import("ppm.zig");
const Color = ppm.Color;
const RGB = ppm.RGB;
const Interval = @import("interval.zig");

pub const Vec3 = struct {
    data: @Vector(3, f32),

    pub fn init(xd: f32, yd: f32, zd: f32) Vec3 {
        var self = Vec3{ .data = @Vector(3, f32){ 0.0, 0.0, 0.0 } };

        self.data[0] = xd;
        self.data[1] = yd;
        self.data[2] = zd;

        return self;
    }

    pub fn zero() Vec3 {
        return Vec3{ .data = @Vector(3, f32){ 0.0, 0.0, 0.0 } };
    }

    pub fn x(self: *const Vec3) f32 {
        return self.data[0];
    }

    pub fn y(self: *const Vec3) f32 {
        return self.data[1];
    }

    pub fn z(self: *const Vec3) f32 {
        return self.data[2];
    }

    pub fn negate(self: *const Vec3) Vec3 {
        return Vec3{ .data = -self.data };
    }

    pub fn addEq(self: *Vec3, v: Vec3) *Vec3 {
        self.data += v.data;
        return self;
    }

    pub fn mulEq(self: *Vec3, scalar: f32) *Vec3 {
        self.data *= @splat(scalar);
        return self;
    }

    pub fn divEq(self: *Vec3, scalar: f32) *Vec3 {
        self.data /= @splat(scalar);
        return self;
    }

    pub fn length(self: *const Vec3) f32 {
        return std.math.sqrt(self.length_squared());
    }

    pub fn length_squared(self: *const Vec3) f32 {
        return self.data[0] * self.data[0] + self.data[1] * self.data[1] + self.data[2] * self.data[2];
    }

    pub fn add(u: *const Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data + v.data };
    }

    pub fn sub(u: *const Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data - v.data };
    }

    pub fn mul(u: *const Vec3, v: Vec3) Vec3 {
        return Vec3{ .data = u.data * v.data };
    }

    pub fn mul_scalar(u: *const Vec3, v: f32) Vec3 {
        return Vec3{ .data = u.data * @as(@Vector(3, f32), @splat(v)) };
    }

    pub fn div_scalar(u: *const Vec3, v: f32) Vec3 {
        return Vec3{ .data = u.data / @as(@Vector(3, f32), @splat(v)) };
    }

    pub fn dot(u: *const Vec3, v: Vec3) f32 {
        const res: f32 = @reduce(.Add, u.data * v.data);
        return res;
    }

    pub fn cross(u: *const Vec3, v: Vec3) Vec3 {
        const xd: f32 = u.data[1] * v.data[2] - u.data[2] * v.data[1];
        const yd: f32 = u.data[2] * v.data[0] - u.data[0] * v.data[2];
        const zd: f32 = u.data[0] * v.data[1] - u.data[1] * v.data[0];

        return init(xd, yd, zd);
    }

    pub fn unit_vector(u: *const Vec3) Vec3 {
        return u.div_scalar(u.length());
    }

    pub fn random(random_engine: std.rand.Random) Vec3 {
        return Vec3.init(random_engine.float(f32), random_engine.float(f32), random_engine.float(f32));
    }

    pub fn random_interval(random_engine: std.rand.Random, interval: Interval) Vec3 {
        var vec = Vec3.zero();
        vec.data[0] = interval.min + (interval.max - interval.min) * random_engine.float(f32);
        vec.data[1] = interval.min + (interval.max - interval.min) * random_engine.float(f32);
        vec.data[2] = interval.min + (interval.max - interval.min) * random_engine.float(f32);

        return vec;
    }

    pub fn random_in_sphere(random_engine: std.rand.Random) Vec3 {
        while (true) {
            var p = Vec3.random_interval(random_engine, .{ .min = -1, .max = 1 });

            if (p.length_squared() < 1)
                return p;
        }
    }

    pub fn random_in_unit_sphere(random_engine: std.rand.Random) Vec3 {
        return Vec3.random_in_sphere(random_engine).unit_vector();
    }

    pub fn random_on_hemisphere(random_engine: std.rand.Random, normal: Vec3) Vec3 {
        var on_unit_sphere = Vec3.random_in_unit_sphere(random_engine);

        if (on_unit_sphere.dot(normal) > 0.0) {
            return on_unit_sphere;
        } else {
            return on_unit_sphere.negate();
        }
    }

    pub fn near_zero(v: *const Vec3) bool {
        const s = 1e-8;

        return (@abs(v.data[0]) < s) and (@abs(v.data[1]) < s) and (@abs(v.data[2]) < s);
    }

    pub fn reflect(v: *const Vec3, n: Vec3) Vec3 {
        const d = v.dot(n) * 2.0;
        return v.sub(n.mul_scalar(d));
    }

    pub fn refract(uv: *const Vec3, n: Vec3, etai_over_etat: f32) Vec3 {
        const cos_theta = @min(uv.negate().dot(n), 1.0);

        const r_out_perp = (uv.add(n.mul_scalar(cos_theta))).mul_scalar(etai_over_etat);
        const r_out_parallel = n.mul_scalar(-std.math.sqrt(@abs(1.0 - r_out_perp.length_squared())));

        return r_out_perp.add(r_out_parallel);
    }

    pub fn random_in_unit_disk(random_engine: std.rand.Random) Vec3 {
        while (true) {
            var p = Vec3.zero();
            p.data[0] = -1 + 2.0 * random_engine.float(f32);
            p.data[1] = -1 + 2.0 * random_engine.float(f32);

            if (p.length_squared() < 1)
                return p;
        }
    }
};
pub const Point3 = Vec3;
pub const Color3 = Vec3;

pub fn color3_to_color(c: Color3) Color {
    return Color{ .rgb = RGB{
        .r = @intFromFloat(std.math.sqrt(c.x()) * 255.99),
        .g = @intFromFloat(std.math.sqrt(c.y()) * 255.99),
        .b = @intFromFloat(std.math.sqrt(c.z()) * 255.99),
    } };
}
