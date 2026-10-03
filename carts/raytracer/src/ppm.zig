const std = @import("std");

pub const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const Color = packed union {
    value: u24,
    rgb: RGB,
};

// pub const PPM = struct {
//     width: usize,
//     height: usize,
//     data: []Color,
//     allocator: std.mem.Allocator,

//     pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !PPM {
//         const self = PPM{
//             .width = width,
//             .height = height,
//             .data = try allocator.alloc(Color, width * height),
//             .allocator = allocator,
//         };

//         return self;
//     }

//     pub fn deinit(self: *PPM) void {
//         self.allocator.free(self.data);
//     }

//     // pub fn save_to_file(self: *PPM, filename: []const u8) !void {
//     //     var file = try std.fs.cwd().createFile(filename, .{});
//     //     defer file.close();
//     //     errdefer file.close();

//     //     const fwriter = file.writer();
//     //     var bufferedWriter = std.io.bufferedWriter(fwriter);
//     //     var bwriter = bufferedWriter.writer();

//     //     try bwriter.print("P3\n{} {}\n255\n", .{ self.width, self.height });

//     //     for (self.data) |pixel| {
//     //         try bwriter.print("{} {} {}\n", .{ pixel.rgb.r, pixel.rgb.g, pixel.rgb.b });
//     //     }

//     //     try bufferedWriter.flush();
//     // }
// };
