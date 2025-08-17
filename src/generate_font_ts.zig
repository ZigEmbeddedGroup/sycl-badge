const std = @import("std");
const font = @import("font.zig").font;

pub fn main() !void {
    var debug_alloc = std.heap.DebugAllocator(.{}){};
    defer _ = debug_alloc.deinit();

    var file = try std.fs.cwd().createFile("simulator/src/font.ts", .{});
    defer file.close();

    try file.writer().writeAll("export const FONT = Uint8Array.of(\n");
    for (font) |char| {
        try file.writer().writeAll("   ");
        for (char) |byte| {
            try file.writer().print(" 0x{X:0>2},", .{byte});
        }

        try file.writer().writeByte('\n');
    }

    try file.writer().writeAll(");\n");
}
