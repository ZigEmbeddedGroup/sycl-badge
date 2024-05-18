const std = @import("std");
const hittable = @import("hit.zig");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const HittableList = hittable.HittableList;
const Sphere = hittable.Sphere;
const Camera = @import("camera.zig");
const material = @import("material.zig");
const LambertianMaterial = material.LambertianMaterial;
const MetalMaterial = material.MetalMaterial;
const DialectricMaterial = material.DialectricMaterial;
const Material = material.Material;
const Interval = @import("interval.zig");

var angle: f32 = 0;

export fn start() void {
    angle = 0;
}

export fn update() void {
    angle += 15.0;
    main_program() catch return;
}

var buffer = [_]u8{0} ** 16384;
pub fn main_program() !void {
    // Allocator

    var gpa = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = gpa.allocator();

    var world = try HittableList.init(allocator);
    var ground_mat = LambertianMaterial.init(Vec3.init(0.5, 0.5, 0.5));
    var ground = Sphere.init(Vec3.init(0, -1000, 0), 1000, ground_mat.material());
    try world.objects.append(ground.hittable());

    // Camera
    const radius = 10.0;
    const angle_rad = angle / 180.0 * std.math.pi;
    const x = radius * std.math.sin(angle_rad);
    const y = radius * std.math.cos(angle_rad);

    var camera = Camera.init(Vec3.init(x, 2, y));

    var a: i32 = -5;
    while (a < 5) : (a += 1) {
        var b: i32 = -5;
        while (b < 5) : (b += 1) {
            const mat_choose: f32 = camera.random.float(f32);

            var center = Vec3.init(@as(f32, @floatFromInt(a)) + 0.9 * camera.random.float(f32), 0.2, @as(f32, @floatFromInt(b)) + 0.9 * camera.random.float(f32));

            if (center.sub(Vec3.init(4, 0.2, 0)).length() > 0.9) {
                var materials: Material = undefined;

                if (mat_choose < 0.8) {
                    const color = Vec3.random(camera.random);
                    var mat = try allocator.create(LambertianMaterial);
                    mat.* = LambertianMaterial.init(color);
                    materials = mat.material();
                } else if (mat_choose < 0.95) {
                    const color = Vec3.random_interval(camera.random, Interval{ .min = 0.5, .max = 1.0 });
                    const fuzz = camera.random.float(f32) * 0.5;

                    var mat = try allocator.create(MetalMaterial);
                    mat.* = MetalMaterial.init(color, fuzz);
                    materials = mat.material();
                } else {
                    var mat = try allocator.create(DialectricMaterial);
                    mat.* = DialectricMaterial.init(1.5);
                    materials = mat.material();
                }

                var sphere = try allocator.create(Sphere);
                sphere.* = Sphere.init(center, 0.2, materials);

                try world.objects.append(sphere.hittable());
            }
        }
    }

    var material1 = DialectricMaterial.init(1.5);
    var material2 = LambertianMaterial.init(Vec3.init(0.4, 0.2, 0.1));
    var material3 = MetalMaterial.init(Vec3.init(0.7, 0.6, 0.5), 0.0);

    var sphere1 = Sphere.init(Vec3.init(0, 0.75, 0), 0.75, material1.material());
    var sphere2 = Sphere.init(Vec3.init(-2.5, 0.75, 0), 0.75, material2.material());
    var sphere3 = Sphere.init(Vec3.init(2.5, 0.75, 0), 0.75, material3.material());

    try world.objects.append(sphere1.hittable());
    try world.objects.append(sphere2.hittable());
    try world.objects.append(sphere3.hittable());

    try camera.render(&world);
}
