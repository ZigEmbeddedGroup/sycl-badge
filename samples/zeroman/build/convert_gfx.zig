const std = @import("std");
const allocator = std.heap.c_allocator;
const Image = @import("zigimg").Image;

const ConvertFile = struct {
    path: []const u8,
    bits: u4,
    transparency: bool,
};

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    var in_files = std.ArrayList(ConvertFile).init(allocator);
    var out_path: []const u8 = undefined;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-i")) {
            const path = args.next() orelse return error.MissingArg;
            const bits = args.next() orelse return error.MissingArg;
            const transparency = args.next() orelse return error.MissingArg;
            try in_files.append(.{ .path = path, .bits = @intCast(bits[0] - '0'), .transparency = transparency[0] == 't' });
        } else if (std.mem.eql(u8, arg, "-o")) {
            out_path = args.next() orelse return error.MissingArg;
        }
    }
    std.debug.print("{s}\n", .{out_path});

    const out_file = try std.fs.cwd().createFile(out_path, .{});
    defer out_file.close();

    const writer = out_file.writer();
    try writer.writeAll("const PackedIntSlice = @import(\"std\").packed_int_array.PackedIntSlice;\n");
    try writer.writeAll("const DisplayColor = @import(\"wasm4\").DisplayColor;\n\n");

    for (in_files.items) |in_file| {
        try convert(in_file, writer);
    }
}

fn convert(args: ConvertFile, writer: std.fs.File.Writer) !void {
    const N = 8 / args.bits;

    var image = try Image.fromFilePath(allocator, args.path);
    defer image.deinit();

    var colors = std.ArrayList(Color).init(allocator);
    defer colors.deinit();
    if (args.transparency) try colors.append(.{ .r = 31, .g = 0, .b = 31 });
    var indices = try std.ArrayList(usize).initCapacity(allocator, image.width * image.height);
    defer indices.deinit();
    var it = image.iterator();
    while (it.next()) |pixel| {
        const color = Color{
            .r = @intFromFloat(31.0 * pixel.r),
            .g = @intFromFloat(63.0 * pixel.g),
            .b = @intFromFloat(31.0 * pixel.b),
        };
        const index = try getIndex(&colors, color);
        indices.appendAssumeCapacity(index);
    }
    std.debug.print("{} colors: {any}\n", .{ colors.items.len, colors.items });
    var packed_data = try allocator.alloc(u8, indices.items.len / N);
    defer allocator.free(packed_data);
    for (packed_data, 0..) |_, i| {
        packed_data[i] = 0;
        for (0..N) |n| {
            const shift: u3 = @intCast(n * args.bits);
            packed_data[i] |= @intCast(indices.items[N * i + n] << shift);
        }
    }

    {
        const name = std.fs.path.stem(args.path);
        try writer.print("pub const {s} = struct {{\n", .{name});

        try writer.print("    pub const w = {};\n", .{image.width});
        try writer.print("    pub const h = {};\n", .{image.height});

        try writer.writeAll("    pub const colors = [_]DisplayColor{\n");
        for (colors.items) |c| {
            try writer.print("        .{{ .red = {}, .green = {}, .blue = {} }},\n", .{ c.r, c.g, c.b });
        }
        try writer.writeAll("    };\n");

        try writer.print("    pub const indices = PackedIntSlice(u{}).init(@constCast(data[0..]), data.len * {});\n", .{ args.bits, N });
        try writer.writeAll("    const data = [_]u8{\n");
        for (packed_data, 0..) |index, i| {
            if (i % 32 == 0) try writer.writeAll("        ");
            try writer.print("{}, ", .{index});
            if ((i + 1) % 32 == 0) try writer.writeAll("\n");
        }
        try writer.writeAll("    };\n");

        try writer.writeAll("};\n\n");
    }
}

pub const Color = packed struct(u16) {
    b: u5,
    g: u6,
    r: u5,

    fn eql(self: Color, other: Color) bool {
        return @as(u16, @bitCast(self)) == @as(u16, @bitCast(other));
    }
};

fn getIndex(colors: *std.ArrayList(Color), color: Color) !usize {
    for (colors.items, 0..) |c, i| {
        if (c.eql(color)) return i;
    }
    try colors.append(color);
    return colors.items.len - 1;
}
