# SYCL Badge Cart Showcase

Here is a number of carts people have made with the SYCL Badge.

## Contributing

If you'd like to share what you've made with the SYCL Badge you can PR your
project. This helps the project because we can test changes to the base badge
firmware against a large number of applications, and in the future we'd like to
generate a website from all this info. To add your project you're going to add
it as a Zig package:

1. Put your code under `carts/<my_cart_name>/`. Add `sycl_badge` as a path
   dependency:

```zig
.{
    .name = "blobs",
    .version = "0.0.0",
    .dependencies = .{
        .sycl_badge = .{ .path = "../../.." },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

2. Build your cart in the package `build.zig` and export some metadata
   (`author_handle` is optional):

```zig
const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Jonathan Marler";
pub const author_handle = "marler";
pub const cart_title = "blobs";
pub const description = "<TODO>: get Marler to give a description";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "blobs",
        .optimize = optimize,
        .root_source_file = b.path("src/blobs.zig"),
    });
    cart.install(b);
}
```

2. Add it as a path dependency of `showcase` in `build.zig.zon`:

```zig
.{
    .name = "sycl-badge/showcase",
    .version = "0.0.0",
    .dependencies = .{
        .sycl_badge = .{
            .path = "..",
        },
        //.zine = .{
        //    .path = "../../zine",
        //},

        // Carts go here
        .zeroman = .{ .path = "carts/zeroman" },
        .blobs = .{ .path = "carts/blobs" },
    },
    .paths = .{
        "README.md",
        "build.zig.zon",
        "build.zig",
        "carts",
    },
}

```

3. Fill in the table of cart dependencies in `build.zig`:

```zig
const carts = .{
    .{ "zeroman", @import("zeroman") },
    .{ "blobs", @import("blobs") },
    // Right here
};
```

