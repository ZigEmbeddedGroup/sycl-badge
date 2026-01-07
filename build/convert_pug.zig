const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <input.png> <output.zig>\n", .{args[0]});
        return error.InvalidArgs;
    }

    const input_path = args[1];
    const output_path = args[2];

    var image = try zigimg.Image.fromFilePath(allocator, input_path);
    defer image.deinit();

    std.debug.print("Image loaded: {}x{}, format: {}\n", .{ image.width, image.height, image.pixelFormat() });

    // Target dimensions
    const target_width: usize = 160;
    const target_height: usize = 128;

    const output_file = try std.fs.cwd().createFile(output_path, .{});
    defer output_file.close();

    const writer = output_file.writer();

    // Write the header
    try writer.writeAll("// Auto-generated RGB565 image data from pugImg.png\n");
    try writer.writeAll("// 160x128 pixels, 2 bytes per pixel (RGB565 format)\n\n");
    try writer.print("pub const pug_image_data: [{}]u8 = .{{\n", .{target_width * target_height * 2});

    var bytes_written: usize = 0;
    var y: usize = 0;
    while (y < target_height) : (y += 1) {
        var x: usize = 0;
        while (x < target_width) : (x += 1) {
            // Calculate source pixel (with scaling if needed)
            const src_x = @min((x * image.width) / target_width, image.width - 1);
            const src_y = @min((y * image.height) / target_height, image.height - 1);

            // Get pixel color based on image format
            const r_float: f32 = blk: {
                switch (image.pixels) {
                    .rgba32 => |pixels| {
                        const pixel = pixels[src_y * image.width + src_x];
                        const rgba = pixel.toU32Rgba();
                        const r = @as(f32, @floatFromInt((rgba >> 24) & 0xFF)) / 255.0;
                        const g = @as(f32, @floatFromInt((rgba >> 16) & 0xFF)) / 255.0;
                        const b = @as(f32, @floatFromInt((rgba >> 8) & 0xFF)) / 255.0;

                        // Convert to RGB565
                        const r5: u5 = @intFromFloat(r * 31.0);
                        const g6: u6 = @intFromFloat(g * 63.0);
                        const b5: u5 = @intFromFloat(b * 31.0);

                        // Pack into RGB565 (BGR format for ST7735)
                        const hi: u8 = (@as(u8, b5) << 3) | @as(u8, g6 >> 3);
                        const lo: u8 = (@as(u8, g6 & 0x07) << 5) | @as(u8, r5);

                        if (bytes_written % 16 == 0) {
                            try writer.writeAll("    ");
                        }

                        try writer.print("0x{X:0>2}, 0x{X:0>2}, ", .{ hi, lo });
                        bytes_written += 2;

                        if (bytes_written % 16 == 0) {
                            try writer.writeAll("\n");
                        }
                        break :blk 0.0; // dummy return
                    },
                    .rgb24 => |pixels| {
                        const pixel = pixels[src_y * image.width + src_x];
                        const r = @as(f32, @floatFromInt(pixel.r)) / 255.0;
                        const g = @as(f32, @floatFromInt(pixel.g)) / 255.0;
                        const b = @as(f32, @floatFromInt(pixel.b)) / 255.0;

                        // Convert to RGB565
                        const r5: u5 = @intFromFloat(r * 31.0);
                        const g6: u6 = @intFromFloat(g * 63.0);
                        const b5: u5 = @intFromFloat(b * 31.0);

                        // Pack into RGB565 (BGR format for ST7735)
                        const hi: u8 = (@as(u8, b5) << 3) | @as(u8, g6 >> 3);
                        const lo: u8 = (@as(u8, g6 & 0x07) << 5) | @as(u8, r5);

                        if (bytes_written % 16 == 0) {
                            try writer.writeAll("    ");
                        }

                        try writer.print("0x{X:0>2}, 0x{X:0>2}, ", .{ hi, lo });
                        bytes_written += 2;

                        if (bytes_written % 16 == 0) {
                            try writer.writeAll("\n");
                        }
                        break :blk 0.0; // dummy return
                    },
                    else => {
                        std.debug.print("Unsupported pixel format: {}\n", .{image.pixelFormat()});
                        return error.UnsupportedPixelFormat;
                    },
                }
            };
            _ = r_float;
        }
    }

    if (bytes_written % 16 != 0) {
        try writer.writeAll("\n");
    }

    try writer.writeAll("};\n");

    std.debug.print("Converted {s} to {s}\n", .{ input_path, output_path });
    std.debug.print("Output size: {} bytes ({} x {} pixels)\n", .{ target_width * target_height * 2, target_width, target_height });
}
