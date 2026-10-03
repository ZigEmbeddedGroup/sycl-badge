const std = @import("std");
const Build = std.Build;

pub const author_name = "Fabio Arnold";
pub const author_handle = "CaptainHorst";
pub const cart_title = "Zeroman";
pub const description = "<TODO>: get Fabio to give a description";


pub fn build_cart(b: *Build, cart: *Build.Module, cart_api: *Build.Module, step: *Build.Step) void {
    @setEvalBranchQuota(5000);
    const convert = b.addExecutable(.{
        .name = "convert_gfx",
        .root_module = b.createModule(.{
            .root_source_file = b.path("showcase/carts/zeroman/build/convert_gfx.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
            .link_libc = true,
        }),
    });
    convert.root_module.addImport("zigimg", b.dependency("zigimg", .{}).module("zigimg"));

    const gen_gfx = b.addRunArtifact(convert);
    inline for (zeroman_assets) |file| {
        gen_gfx.addArg("-i");
        gen_gfx.addFileArg(b.path(file.path));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.bits}));
        gen_gfx.addArg(std.fmt.comptimePrint("{}", .{file.transparency}));
    }
    gen_gfx.addArg("-o");
    const gfx_zig = gen_gfx.addOutputFileArg("gfx.zig");

    const gfx_mod = b.createModule(.{
        .root_source_file = gfx_zig,
        .imports = &.{
            .{
                .name = "packed_int_array",
                .module = b.createModule(.{
                    .root_source_file = b.path("showcase/carts/zeroman/src/packed_int_array.zig"),
                }),
            },
        },
    });
    gfx_mod.addImport("cart-api", cart_api);
    step.dependOn(&gen_gfx.step);
    cart.addImport("gfx", gfx_mod);
}

const GfxAsset = struct { path: []const u8, bits: u4, transparency: bool };

const zeroman_assets = [_]GfxAsset{
    .{ .path = "showcase/carts/zeroman/assets/door.png", .bits = 2, .transparency = false },
    .{ .path = "showcase/carts/zeroman/assets/effects.png", .bits = 2, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/font.png", .bits = 2, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/gopher.png", .bits = 4, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/healthbar.png", .bits = 4, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/hurt.png", .bits = 1, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/needleman.png", .bits = 4, .transparency = false },
    .{ .path = "showcase/carts/zeroman/assets/shot.png", .bits = 2, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/spike.png", .bits = 2, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/teleport.png", .bits = 2, .transparency = true },
    .{ .path = "showcase/carts/zeroman/assets/title.png", .bits = 4, .transparency = false },
    .{ .path = "showcase/carts/zeroman/assets/zero.png", .bits = 4, .transparency = true },
};
