/// Input file is a png.
/// Output file is a zon of Display Color.
/// Output is a zig file with constant display buffers.
const convert_gfx = @This();

const std = @import("std");
const allocator = std.heap.c_allocator;
const Image = @import("zigimg").Image;

const cart = @import("cart-api");

const ConvertFile = struct {
    path: []const u8,
};

var io_mem: std.Io.Threaded = .init_single_threaded;
const io = io_mem.io();

pub fn main(init: std.process.Init.Minimal) !void {
    var args = try init.args.iterateAllocator(allocator);
    defer args.deinit();

    _ = args.next();
    var in_path: []const u8 = undefined;
    var out_path: []const u8 = undefined;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-i")) {
            in_path = args.next() orelse return error.MissingArg;
        } else if (std.mem.eql(u8, arg, "-o")) {
            out_path = args.next() orelse return error.MissingArg;
        }
    }

    const out_file = try std.Io.Dir.cwd().createFile(io, out_path, .{});
    defer out_file.close(io);

    var writer_buf: [4096]u8 = undefined;
    var out_file_writer = out_file.writer(io, &writer_buf);
    const writer = &out_file_writer.interface;

    try convert(in_path, writer);

    writer.flush() catch |err| std.debug.panic("Error flushing output: {s}\n", .{@errorName(err)});
}

fn convert(in_path: []const u8, writer: *std.Io.Writer) !void {
    const read_buffer = try allocator.alloc(u8, 4 * 1024 * 1024);
    defer allocator.free(read_buffer);
    var image = Image.fromFilePath(allocator, io, in_path, read_buffer) catch |err| {
        std.debug.panic("Error loading image from {s}: {s}\n", .{ in_path, @errorName(err) });
        return err;
    };
    defer image.deinit(allocator);

    // frame buffer is [width][height]DisplayColor
    // std.debug.print("image: width {}, height: {}", .{ image.width, image.height });
    var frame_buffer: cart.Framebuffer = undefined;
    if (image.width != frame_buffer.len) std.debug.panic("mismatch image width and frame buffer, {} != {}", .{ image.width, frame_buffer.len });
    if (image.height != frame_buffer[0].len) std.debug.panic("mismatch image height and frame buffer, {} != {}", .{ image.height, frame_buffer[0].len });

    var it = image.iterator();

    for (0..cart.screen_height) |y| {
        for (0..cart.screen_width) |x| {
            const pixel = it.next() orelse @panic("wrong size image?");
            frame_buffer[x][y] = cart.DisplayColor{
                .r = @intFromFloat(31.0 * pixel.r),
                .g = @intFromFloat(63.0 * pixel.g),
                .b = @intFromFloat(31.0 * pixel.b),
            };
        }
    }

    try std.zon.stringify.serialize(frame_buffer, .{}, writer);
}
