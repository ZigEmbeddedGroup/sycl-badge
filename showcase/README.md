# SYCL Badge Cart Showcase

Community carts for SYCL Badge hardware and simulator targets.

## Build and Run

### Build Showcase Carts

From repository root:

```bash
zig build
```

Outputs are written to `zig-out/firmware`.

Additionally, building in the showcase directory just re-routes the command to the root zig build.

### Flash to Badge Hardware

1. Build with `zig build`.
2. Connect the badge over USB so it mounts as a mass storage drive.
3. Copy a cart `.uf2` from `zig-out/firmware` and replace `CURRENT.UF2`.
4. The cart launches immediately.

### Run in Simulator

To run carts in the simulator with reload support:

1. Start simulator UI from [simulator](../simulator/README.md).
2. Start a cart watcher from a cart project that provides a `watch` step.

For a starter workflow, use [docs/introduction](../docs/introduction/README.md).

## Cart Types in This Repository

- Showcase package carts (registered in [build.zig.zon](build.zig.zon) and [build.zig](build.zig)):
  These are package-based carts under [carts](carts) that participate in showcase package builds.
- Root-built carts:
  Some carts under [carts](carts) are built directly by root [build.zig](../build.zig) using OS-cart or MicroZig helpers.

See [carts/README.md](carts/README.md) for a curated index and per-cart notes.

## Contributing a Package Cart

If you want to submit a new package-style cart, add it under `showcase/carts/<my_cart_name>` and wire it into showcase dependencies.

### 1. Add package files and dependency

Create `build.zig.zon` with `sycl_badge` as a path dependency:

```zig
.{
    .name = "my_cart",
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

### 2. Export cart metadata and install artifacts

In package `build.zig`:

```zig
const std = @import("std");
const sycl_badge = @import("sycl_badge");

pub const author_name = "Your Name";
pub const author_handle = "your_handle"; // optional
pub const cart_title = "My Cart";
pub const description = "One-line description";

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const sycl_badge_dep = b.dependency("sycl_badge", .{});

    const cart = sycl_badge.add_cart(sycl_badge_dep, b, .{
        .name = "my-cart",
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    }) orelse return;
    cart.install(b);
}
```

### 3. Register the cart in showcase dependencies

Add it to [build.zig.zon](build.zig.zon):

```zig
.dependencies = .{
    .sycl_badge = .{ .path = ".." },
    .my_cart = .{ .path = "carts/my-cart" },
}
```

Then add it to the `carts` table in [build.zig](build.zig):

```zig
const carts = .{
    .{ "my_cart", @import("my_cart") },
};
```

