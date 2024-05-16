const std = @import("std");

const MNIST_WEIGHT = @embedFile("mnist-ggml-model-f32.gguf");
pub fn main() !void {
    const model: Mnist = Mnist.load(MNIST_WEIGHT);
    const fs = try std.fs.cwd().createFile("mnist.q2.bin", .{});
    defer fs.close();

    try fs.writeAll(std.mem.asBytes(&model));
}

const Mnist = struct {
    weight0: [784 * 500 / 4]u8,
    bias0: [500]f32,
    weight1: [500 * 10 / 4]u8,
    bias1: [10]f32,
    pub fn load(data: []const u8) Mnist {
        var res: Mnist = undefined;

        var i: usize = 0;
        i += 4; // header
        i += 3 * 4; // n_dims, n_in, n_hidden
        i += readAndQuantize(std.mem.sliceAsBytes(&res.weight0), data[i..], 784 * 500);
        i += 2 * 4; // n_dims, n_hidden
        @memcpy(&res.bias0, std.mem.bytesAsSlice(f32, data[i..][0 .. 500 * 4]));
        i += 500 * 4;

        i += 3 * 4; // n_dims, n_hidden, n_out
        i += readAndQuantize(std.mem.sliceAsBytes(&res.weight1), data[i..], 500 * 10);
        i += 2 * 4; // n_dims, n_out
        @memcpy(&res.bias1, std.mem.bytesAsSlice(f32, data[i..]));
        return res;
    }
};

fn readAndQuantize(dst: []u8, src: []const u8, n: usize) usize {
    const weights = std.mem.bytesAsSlice(@Vector(8, f32), src[0 .. n * 4]);
    // @compileLog(weights.len, dst.len);
    if (2 * weights.len != dst.len) @panic("dim mismatch");
    for (weights, 0..) |w, j| {
        //  TODO: respect row boundaries
        const v_0: @Vector(8, f32) = @splat(0);
        const pos: u8 = @bitCast(w > v_0);
        const neg: u8 = @bitCast(w < v_0);
        dst[2 * j] = pos;
        dst[2 * j + 1] = neg;
    }
    return n * 4;
}

inline fn read(T: type, data: []const u8, i: usize) struct { T, usize } {
    const bytes = data[i..][0..@sizeOf(T)].*;
    return .{ std.mem.readInt(T, &bytes, .little), i + @sizeOf(T) };
}
