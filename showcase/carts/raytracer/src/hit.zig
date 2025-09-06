const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Point3 = vec.Point3;
const Interval = @import("interval.zig");
const Ray = @import("ray.zig");
const std = @import("std");
const ArrayListManaged = std.array_list.Managed;
const material = @import("material.zig");
const Material = material.Material;

pub const HitRecord = struct {
    point: Point3,
    normal: Vec3,
    t: f32,
    front_face: bool,
    mat: Material,

    pub fn set_face_normal(self: *HitRecord, ray: Ray, outward_normal: Vec3) void {
        self.front_face = ray.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negate();
    }
};

pub const Hittable = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        hit: *const fn (ctx: *anyopaque, ray: Ray, ray_t: Interval, hit_record: *HitRecord, ret_addr: usize) bool,
    };

    pub fn rawHit(self: Hittable, ray: Ray, ray_t: Interval, hit_record: *HitRecord, ret_addr: usize) bool {
        return self.vtable.hit(self.ptr, ray, ray_t, hit_record, ret_addr);
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f32,
    mat: Material,

    pub fn init(center: Point3, radius: f32, mat: Material) Sphere {
        return Sphere{ .center = center, .radius = radius, .mat = mat };
    }

    pub fn hit(ctx: *anyopaque, ray: Ray, ray_t: Interval, hit_record: *HitRecord, ret_addr: usize) bool {
        _ = ret_addr;
        const self: *Sphere = @ptrCast(@alignCast(ctx));

        const oc = ray.origin.sub(self.center);
        const a = ray.direction.length_squared();
        const half_b = oc.dot(ray.direction);
        const c = oc.length_squared() - self.radius * self.radius;

        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0)
            return false;

        const sqrtd = std.math.sqrt(discriminant);

        var root = (-half_b - sqrtd) / a;

        if (!ray_t.surrounds(root)) {
            root = (-half_b + sqrtd) / a;
            if (!ray_t.surrounds(root))
                return false;
        }

        hit_record.t = root;
        hit_record.point = ray.at(root);
        const outward_normal = hit_record.point.sub(self.center).div_scalar(self.radius);
        hit_record.set_face_normal(ray, outward_normal);
        hit_record.mat = self.mat;

        return true;
    }

    pub fn hittable(self: *Sphere) Hittable {
        return .{
            .ptr = self,
            .vtable = &.{
                .hit = hit,
            },
        };
    }
};

pub const HittableList = struct {
    objects: ArrayListManaged(Hittable),

    pub fn init(allocator: std.mem.Allocator) !HittableList {
        var self: HittableList = undefined;
        self.objects = ArrayListManaged(Hittable).init(allocator);
        return self;
    }

    pub fn hit(self: *HittableList, ray: Ray, ray_t: Interval, hit_record: *HitRecord) bool {
        var record: HitRecord = undefined;
        var hit_anything: bool = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |item| {
            const is_hit = item.vtable.hit(item.ptr, ray, ray_t, &record, @returnAddress());

            if (is_hit) {
                // Make sure record is only set if it's closer
                if (record.t < closest_so_far) {
                    hit_anything = true;
                    closest_so_far = record.t;
                    hit_record.* = record;
                }
            }
        }

        return hit_anything;
    }
};
