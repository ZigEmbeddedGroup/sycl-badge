const std = @import("std");
const Build = std.Build;
const LazyPath = Build.LazyPath;

const img = @import("img");

pub fn add_static_screen(b: *Build, image_file: []const u8) *Build.Step.Options {
    return add_static_screen_impl(b, image_file) catch unreachable;
}

pub fn add_static_screen_impl(b: *Build, image_file: []const u8) !*Build.Step.Options {
    const options = b.addOptions();

    const image = img.Image.fromFilePath(b.allocator, image_file);
    defer image.deinit();

    //const data = &.{};

    //options.addOptionPath("data", data);

    return options;
}
