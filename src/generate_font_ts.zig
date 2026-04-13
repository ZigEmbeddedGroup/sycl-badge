const std = @import("std");
const font = @import("font.zig").font;

pub fn main() !void {
    var debug_alloc = std.heap.DebugAllocator(.{}){};
    defer _ = debug_alloc.deinit();

    var file = try std.fs.cwd().createFile("simulator/src/font.ts", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(&buffer);
    const writer = &file_writer.interface;

    try writer.writeAll("export const FONT = Uint8Array.of(\n");
    for (font) |char| {
        try writer.writeAll("    ");
        for (char) |byte| {
            try writer.print("0x{X:0>2}, ", .{byte});
        }

        try writer.writeByte('\n');
    }

    try writer.writeAll(");\n");
    try file_writer.end();
}
