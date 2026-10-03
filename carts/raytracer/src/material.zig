const std = @import("std");
const Ray = @import("ray.zig");
const hit = @import("hit.zig");
const HitRecord = hit.HitRecord;
const vec = @import("vec.zig");
const Color3 = vec.Color3;
const Vec3 = vec.Vec3;

pub const Material = struct {
    ptr: *anyopaque,
    vtable: VTable,
    const VTable = struct {
        scatter: *const fn (ctx: *anyopaque, random_engine: std.Random, ray_in: Ray, record: HitRecord, attenuation: *Color3, scattered: *Ray) bool,
    };
};

pub const LambertianMaterial = struct {
    albedo: Color3,

    pub fn init(col: Color3) LambertianMaterial {
        return LambertianMaterial{
            .albedo = col,
        };
    }

    pub fn scatter(ctx: *anyopaque, random_engine: std.Random, ray_in: Ray, record: HitRecord, attenuation: *Color3, ray_out: *Ray) bool {
        _ = ray_in;

        const self: *LambertianMaterial = @ptrCast(@alignCast(ctx));

        var scatter_dir = record.normal.add(Vec3.random_in_unit_sphere(random_engine));

        if (scatter_dir.near_zero())
            scatter_dir = record.normal;

        ray_out.* = Ray{ .origin = record.point, .direction = scatter_dir };
        attenuation.* = self.albedo;

        return true;
    }

    pub fn material(self: *LambertianMaterial) Material {
        return .{
            .ptr = self,
            .vtable = .{
                .scatter = scatter,
            },
        };
    }
};

pub const MetalMaterial = struct {
    albedo: Color3,
    fuzz: f32,

    pub fn init(col: Color3, f: f32) MetalMaterial {
        return MetalMaterial{
            .albedo = col,
            .fuzz = if (f < 1) f else 1.0,
        };
    }

    pub fn scatter(ctx: *anyopaque, random_engine: std.Random, ray_in: Ray, record: HitRecord, attenuation: *Color3, ray_out: *Ray) bool {
        const self: *MetalMaterial = @ptrCast(@alignCast(ctx));

        var reflected = ray_in.direction.unit_vector().reflect(record.normal);
        ray_out.* = Ray{ .origin = record.point, .direction = reflected.add(Vec3.random_in_unit_sphere(random_engine).mul_scalar(self.fuzz)) };
        attenuation.* = self.albedo;

        return true;
    }

    pub fn material(self: *MetalMaterial) Material {
        return .{
            .ptr = self,
            .vtable = .{
                .scatter = scatter,
            },
        };
    }
};

pub fn reflectance(cosine: f32, ref_idx: f32) f32 {
    var r0 = (1 - ref_idx) / (1 + ref_idx);
    r0 = r0 * r0;

    return r0 + (1 - r0) * std.math.pow(f32, (1 - cosine), 5);
}

pub const DialectricMaterial = struct {
    ir: f32,

    pub fn init(refraction: f32) DialectricMaterial {
        return DialectricMaterial{ .ir = refraction };
    }

    pub fn scatter(ctx: *anyopaque, random_engine: std.Random, ray_in: Ray, record: HitRecord, attenuation: *Color3, scattered: *Ray) bool {
        const self: *DialectricMaterial = @ptrCast(@alignCast(ctx));

        attenuation.* = Color3.init(1.0, 1.0, 1.0);
        const refraction_ratio = if (record.front_face) 1.0 / self.ir else self.ir;

        const unit_direciton = ray_in.direction.unit_vector();

        const cos_theta = @min(unit_direciton.negate().dot(record.normal), 1.0);
        const sin_theta = std.math.sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = refraction_ratio * sin_theta > 1.0;
        var direction: Vec3 = undefined;

        if (cannot_refract or reflectance(cos_theta, refraction_ratio) > random_engine.float(f32)) {
            direction = unit_direciton.reflect(record.normal);
        } else {
            direction = unit_direciton.refract(record.normal, refraction_ratio);
        }

        scattered.* = Ray{ .origin = record.point, .direction = direction };

        return true;
    }

    pub fn material(self: *DialectricMaterial) Material {
        return .{
            .ptr = self,
            .vtable = .{
                .scatter = scatter,
            },
        };
    }
};
