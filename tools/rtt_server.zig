const std = @import("std");

const port: u16 = 10344;
const address: std.net.Address = std.net.Address.parseIp("127.0.0.1", port)
    catch @compileError("Couldn't parse server.address");

const connect_sleep_time_millis: u64 = 10 * 1000;

var socket_buffer: [8 * 1024]u8 = undefined;
var stdout_buffer: [8 * 1024]u8 = undefined;

pub fn main() !void {
    var stdout = std.fs.File.stdout().writer(&stdout_buffer);
    std.debug.print("Looking for RTT server at {f}\n", .{address});

    while (true) {
        const stream = std.net.tcpConnectToAddress(address) catch |err| {
            std.debug.print("Failed to connect: {}\n", .{err});
            std.debug.print("Trying again in {d} seconds\n\n", .{connect_sleep_time_millis / 1000});
            std.Thread.sleep(connect_sleep_time_millis * 1_000_000); // millis to nanos
            continue;
        };

        std.debug.print("{s}", .{"Connected to server\n"});
        var reader_data = stream.reader(&.{});

        stream_data: while (true) {
            _ = reader_data.interface().stream(&stdout.interface, .unlimited) catch |err| {
                stdout.interface.flush() catch {};
                std.debug.print("\n\n---------- Connection Lost: {} ----------\n", .{err});
                std.debug.print("{s}", .{"Attempting to reconnect.\n"});
                break :stream_data;
            };
            stdout.interface.flush() catch {};
        }
    }
}
