const std = @import("std");
//const zine = @import("zine");

const root = @import("root");
// cart imports
const carts = .{
    .{ "zeroman", @import("zeroman") },
    .{ "blobs", @import("blobs") },
    .{ "metalgear_timer", @import("metalgear_timer") },
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    inline for (carts) |cart| {
        const cart_name = cart[0];
        const cart_import = cart[1];
        _ = cart_import.author_name;
        if (@hasDecl(cart_import, "author_handle"))
            _ = cart_import.author_handle;
        _ = cart_import.cart_title;
        _ = cart_import.description;
        const dep = b.dependency(cart_name, .{ .optimize = optimize });
        b.getInstallStep().dependOn(dep.builder.getInstallStep());
    }

    //zine.addWebsite(b, .{
    //    .title = "SYCL Badge Showcase",
    //    .host_url = "https://sample.com",
    //    .layouts_dir_path = "layouts",
    //    .content_dir_path = "content",
    //    .static_dir_path = "static",
    //}) catch unreachable;
}
