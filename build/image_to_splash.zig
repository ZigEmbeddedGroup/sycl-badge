const std = @import("std");
const img = @import("img");

const Arguments = struct {
    output_path: ?[]const u8 = null,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var input_file_arg: ?[]const u8 = null;
    var output_file_arg: ?[]const u8 = null;

    {
        var i: u32 = 1;
        while (i < args.len) : (i += 1) {
            if (std.mem.eql(u8, args[i], "-o")) {
                if (i + 1 >= args.len)
                    return error.MissingOutputFileArg;

                output_file_arg = args[i + 1];
                i += 1;
            } else {
                input_file_arg = args[i];
            }
        }
    }

    const input_file_path = input_file_arg orelse unreachable;
    const output_file_path = output_file_arg orelse unreachable;

    var image = try img.Image.fromFilePath(allocator, input_file_path);
    defer image.deinit();

    if (image.width != 160 or image.height != 128) {
        std.log.err("Image must be 160x128 but it is {}x{}!!!", .{ image.width, image.height });
    }

    const output_file = try std.fs.cwd().createFile(output_file_path, .{});
    defer output_file.close();

    const writer = output_file.writer();
    try writer.print(
        \\const microzig = @import("microzig");
        \\const board = microzig.board;
        \\const lcd = board.lcd;
        \\
        \\pub const data = [{}]lcd.Color16 {{
        \\
    , .{image.height * image.width});
    switch (image.pixelFormat()) {
        .rgba32 => {
            for (image.pixels.rgba32) |pixel| {
                const lcd_pixel = img.color.Rgb565.fromU32Rgba(pixel.toU32Rgba());
                try writer.print(
                    \\    .{{ .b = {}, .g = {}, .r = {} }},
                    \\
                , .{
                    lcd_pixel.b,
                    lcd_pixel.g,
                    lcd_pixel.r,
                });
            }
        },
        else => {
            std.log.err("TODO: {}", .{image.pixelFormat()});
            return error.TodoPixelFormat;
        },
    }

    try writer.writeAll(
        \\};
        \\
    );
}
