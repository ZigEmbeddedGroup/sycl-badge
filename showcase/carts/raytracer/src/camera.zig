const Camera = @This();
const vec = @import("vec.zig");
const Point3 = vec.Point3;
const Vec3 = vec.Vec3;
const Color3 = vec.Color3;
const std = @import("std");
const Ray = @import("ray.zig");
const hit = @import("hit.zig");
const HittableList = hit.HittableList;
const HitRecord = hit.HitRecord;
const Interval = @import("interval.zig");
const cart = @import("cart-api");

const aspect_ratio = 5.0 / 4.0;
const image_width: usize = 160;
const image_height: usize = @intFromFloat(@as(f32, @floatFromInt(image_width)) / aspect_ratio);

const theta: f32 = vfov / 180.0 * std.math.pi;
const h: f32 = std.math.tan(theta / 2.0);
const viewport_height: f32 = 2 * h * focus_distance;
const viewport_width: f32 = viewport_height * @as(f32, @floatFromInt(image_width)) / @as(f32, @floatFromInt(image_height));
const vfov: f32 = 20;
const lookat = Point3.init(0, 0, 0);
const vup = Vec3.init(0, 1, 0);
const defocus_angle: f32 = 0.6;
const focus_distance: f32 = 10.0;

lookfrom: Vec3,
pixel00_location: Vec3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
camera_center: Vec3,
samples: usize,
max_children: usize,
rand_engine: std.rand.DefaultPrng,
random: std.rand.Random,
u: Vec3,
v: Vec3,
w: Vec3,
defocus_disk_u: Vec3,
defocus_disk_v: Vec3,

pub fn init(self: *Camera, position: Vec3) void {
    self.lookfrom = position;
    self.camera_center = self.lookfrom;

    self.w = self.lookfrom.sub(lookat).unit_vector();
    self.u = vup.cross(self.w).unit_vector();
    self.v = self.w.cross(self.u);

    var viewport_u = self.u.mul_scalar(viewport_width);
    var viewport_v = self.v.mul_scalar(-viewport_height);

    self.pixel_delta_u = viewport_u.div_scalar(@floatFromInt(image_width));
    self.pixel_delta_v = viewport_v.div_scalar(@floatFromInt(image_height));

    self.rand_engine = std.rand.DefaultPrng.init(0);
    self.random = self.rand_engine.random();
    self.samples = 25;
    self.max_children = 7;

    var viewport_upper_left = self.camera_center.sub(self.w.mul_scalar(focus_distance)).sub(viewport_u.div_scalar(2.0)).sub(viewport_v.div_scalar(2.0));
    self.pixel00_location = viewport_upper_left.add(self.pixel_delta_u.add(self.pixel_delta_v).mul_scalar(0.5));

    const defocus_radians = (defocus_angle / 2.0) / 180.0 * std.math.pi;
    const defocus_radius = focus_distance * @tan(defocus_radians);

    self.defocus_disk_u = self.u.mul_scalar(defocus_radius);
    self.defocus_disk_v = self.v.mul_scalar(defocus_radius);
}

fn pixel_sample_square(self: *Camera) Vec3 {
    const x = -0.5 + self.random.float(f32);
    const y = -0.5 + self.random.float(f32);

    return self.pixel_delta_u.mul_scalar(x).add(self.pixel_delta_v.mul_scalar(y));
}

fn defocus_disk_sample(self: *Camera) Vec3 {
    const p = Vec3.random_in_unit_disk(self.random);
    return self.camera_center.add(self.defocus_disk_u.mul_scalar(p.data[0])).add(self.defocus_disk_v.mul_scalar(p.data[1]));
}

pub fn get_ray(self: *Camera, i: u32, j: u32) Ray {
    var pixel_center = self.pixel00_location.add(self.pixel_delta_u.mul_scalar(@floatFromInt(i))).add(self.pixel_delta_v.mul_scalar(@floatFromInt(j)));
    var pixel_sample = pixel_center.add(self.pixel_sample_square());

    const ray_origin = if (defocus_angle <= 0) self.camera_center else self.defocus_disk_sample();
    const ray_direction = pixel_sample.sub(ray_origin);

    return Ray.init(ray_origin, ray_direction);
}

pub fn render(self: *Camera, world: *HittableList) !void {
    var j: u32 = 0;
    while (j < image_height) : (j += 1) {
        //std.debug.print("Scanlines Remaining: {}\n", .{image_height - j});

        var i: u32 = 0;
        while (i < image_width) : (i += 1) {
            var col = Color3.zero();

            for (0..self.samples) |_| {
                const ray = self.get_ray(i, j);
                _ = col.addEq(self.ray_color(ray, self.max_children, world));
            }

            const samples: f32 = @floatFromInt(self.samples);
            col = col.div_scalar(samples);

            const color = vec.color3_to_color(col);
            cart.framebuffer[i][j].setColor(.{
                .r = @truncate(color.rgb.r >> 3),
                .g = @truncate(color.rgb.g >> 2),
                .b = @truncate(color.rgb.b >> 3),
            });
        }
    }
    //std.debug.print("Done!\n", .{});
}

fn ray_color(self: *Camera, ray: Ray, depth: usize, world: *HittableList) Color3 {
    var hit_record: HitRecord = undefined;

    if (depth == 0) {
        return Color3.zero();
    }

    if (world.hit(ray, Interval{ .min = 0.001, .max = std.math.inf(f32) }, &hit_record)) {
        var scattered: Ray = undefined;
        var attenuation: Color3 = undefined;

        const mat = hit_record.mat;
        if (mat.vtable.scatter(mat.ptr, self.random, ray, hit_record, &attenuation, &scattered)) {
            var col = self.ray_color(scattered, depth - 1, world);
            return col.mul(attenuation);
        }

        return Color3.zero();
    }

    var dir = ray.direction.unit_vector();
    const a = 0.5 * (dir.y() + 1.0);

    const white = Color3.init(1.0, 1.0, 1.0);
    const blue = Color3.init(0.5, 0.7, 1.0);

    return white.mul_scalar(1.0 - a).add(blue.mul_scalar(a));
}
