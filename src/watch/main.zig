const std = @import("std");
const fs = std.fs;
const mime = @import("mime");
const Allocator = std.mem.Allocator;
const Reloader = @import("Reloader.zig");
const assert = std.debug.assert;

const log = std.log.scoped(.server);
pub const std_options: std.Options = .{
    .log_level = .err,
};

const usage =
    \\usage: zine serve [options]
    \\
    \\options:
    \\      -p [port]        set the port number to listen on
    \\      --root [path]    directory of static files to serve
    \\
;

var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

const Server = struct {
    watcher: *Reloader,
    zig_out_bin_dir: std.fs.Dir,

    fn deinit(s: *Server) void {
        s.zig_out_bin_dir.close();
        s.* = undefined;
    }

    fn handleRequest(s: *Server, req: *std.http.Server.Request, cart_path: []const u8) !bool {
        var arena_impl = std.heap.ArenaAllocator.init(general_purpose_allocator.allocator());
        defer arena_impl.deinit();
        const arena = arena_impl.allocator();

        var path = req.head.target;

        if (std.mem.eql(u8, path, "/ws")) {
            var it = req.iterateHeaders();
            const key = while (it.next()) |header| {
                if (std.ascii.eqlIgnoreCase(header.name, "sec-websocket-key")) {
                    break header.value;
                }
            } else {
                log.debug("couldn't find key header!\n", .{});
                return false;
            };

            log.debug("key = '{s}'", .{key});

            var hasher = std.crypto.hash.Sha1.init(.{});
            hasher.update(key);
            hasher.update("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");

            var h: [20]u8 = undefined;
            hasher.final(&h);

            const ws = try std.Thread.spawn(.{}, Reloader.handleWs, .{
                s.watcher,
                req.server.connection.stream,
                h,
            });
            ws.detach();
            return true;
        }

        path = path[0 .. std.mem.indexOfScalar(u8, path, '?') orelse path.len];

        const ext = fs.path.extension(path);
        const mime_type = mime.extension_map.get(ext) orelse
            .@"application/octet-stream";

        if (std.mem.eql(u8, path, "/cart.wasm")) {
            const file = s.zig_out_bin_dir.openFile(std.fs.path.basename(cart_path), .{}) catch |err| switch (err) {
                error.FileNotFound => {
                    if (std.mem.endsWith(u8, req.head.target, "/")) {
                        try req.respond("404", .{
                            .status = .not_found,
                            .extra_headers = &.{
                                .{ .name = "content-type", .value = "text/plain" },
                                .{ .name = "connection", .value = "close" },
                                .{ .name = "access-control-allow-origin", .value = "*" },
                            },
                        });
                        log.debug("not found\n", .{});
                        return false;
                    } else {
                        try appendSlashRedirect(arena, req);
                        return false;
                    }
                },
                else => {
                    const message = try std.fmt.allocPrint(
                        arena,
                        "error accessing the resource: {s}",
                        .{
                            @errorName(err),
                        },
                    );
                    try req.respond(message, .{
                        .status = .internal_server_error,
                        .extra_headers = &.{
                            .{ .name = "content-type", .value = "text/html" },
                            .{ .name = "connection", .value = "close" },
                            .{ .name = "access-control-allow-origin", .value = "*" },
                        },
                    });
                    log.debug("error: {s}\n", .{@errorName(err)});
                    return false;
                },
            };
            defer file.close();

            const contents = file.readToEndAlloc(arena, std.math.maxInt(usize)) catch |err| switch (err) {
                error.IsDir => {
                    try appendSlashRedirect(arena, req);
                    return false;
                },
                else => return err,
            };

            try req.respond(contents, .{
                .status = .ok,
                .extra_headers = &.{
                    .{ .name = "content-type", .value = @tagName(mime_type) },
                    .{ .name = "connection", .value = "close" },
                    .{ .name = "access-control-allow-origin", .value = "*" },
                },
            });
            log.debug("sent file\n", .{});
        }

        return false;
    }
};

fn appendSlashRedirect(
    arena: std.mem.Allocator,
    req: *std.http.Server.Request,
) !void {
    const location = try std.fmt.allocPrint(
        arena,
        "{s}/",
        .{req.head.target},
    );
    try req.respond("404", .{
        .status = .see_other,
        .extra_headers = &.{
            .{ .name = "location", .value = location },
            .{ .name = "content-type", .value = "text/plain" },
            .{ .name = "connection", .value = "close" },
            .{ .name = "access-control-allow-origin", .value = "*" },
        },
    });
    log.debug("append final slash redirect\n", .{});
}

pub fn main() !void {
    const gpa = general_purpose_allocator.allocator();

    const args = try std.process.argsAlloc(gpa);

    log.debug("log from server!", .{});

    if (args.len < 2) fatal("missing subcommand argument", .{});

    const cmd_name = args[1];
    if (std.mem.eql(u8, cmd_name, "serve")) {
        return cmdServe(gpa, args[2..]);
    } else {
        fatal("unrecognized subcommand: '{s}'", .{cmd_name});
    }
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}

fn cmdServe(gpa: Allocator, args: []const []const u8) !void {
    std.log.info("{s}", .{args});

    var cart_path: ?[]const u8 = null;
    var dirs_to_watch: std.ArrayListUnmanaged([]const u8) = .{};
    const zig_exe = args[0];

    {
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "--cart")) {
                i += 1;
                if (i >= args.len) fatal("expected arg after '{s}'", .{arg});
                cart_path = args[i];
            } else if (std.mem.eql(u8, arg, "--input-dir")) {
                i += 1;
                if (i >= args.len) fatal("expected arg after '{s}'", .{arg});
                try dirs_to_watch.append(gpa, args[i]);
            } else {
                fatal("unrecognized arg: '{s}'", .{arg});
            }
        }
    }

    const zig_out_bin_path = std.fs.path.dirname(cart_path.?).?;
    try fs.cwd().makePath(zig_out_bin_path);

    var zig_out_bin_dir: fs.Dir = fs.cwd().openDir(zig_out_bin_path, .{ .iterate = true }) catch |e|
        fatal("unable to open directory '{s}': {s}", .{ zig_out_bin_path, @errorName(e) });
    defer zig_out_bin_dir.close();

    try dirs_to_watch.append(gpa, zig_out_bin_path);
    var watcher = try Reloader.init(gpa, zig_exe, dirs_to_watch.items);

    var server: Server = .{
        .watcher = &watcher,
        .zig_out_bin_dir = zig_out_bin_dir,
    };
    defer server.deinit();

    const watch_thread = try std.Thread.spawn(.{}, Reloader.listen, .{&watcher});
    watch_thread.detach();

    try serve(&server, cart_path.?, 2468);
}

fn serve(s: *Server, cart_path: []const u8, listen_port: u16) !void {
    const address = try std.net.Address.parseIp("127.0.0.1", listen_port);
    var tcp_server = try address.listen(.{
        .reuse_port = true,
        .reuse_address = true,
    });
    defer tcp_server.deinit();

    const server_port = tcp_server.listen_address.in.getPort();
    std.debug.assert(server_port == listen_port);

    std.debug.print("\x1b[2K\rSimulator live! Go to https://badgesim.microzig.tech/ to test your cartridge.\n", .{});

    var buffer: [1024]u8 = undefined;
    accept: while (true) {
        const conn = try tcp_server.accept();

        var http_server = std.http.Server.init(conn, &buffer);

        var became_websocket = false;

        defer {
            if (!became_websocket) {
                conn.stream.close();
            } else {
                log.debug("request became websocket\n", .{});
            }
        }

        while (http_server.state == .ready) {
            var request = http_server.receiveHead() catch |err| {
                if (err != error.HttpConnectionClosing) {
                    log.debug("connection error: {s}\n", .{@errorName(err)});
                }
                continue :accept;
            };

            became_websocket = s.handleRequest(&request, cart_path) catch |err| {
                log.debug("failed request: {s}", .{@errorName(err)});
                continue :accept;
            };
            if (became_websocket) continue :accept;
        }
    }
}

/// like fs.path.dirname but ensures a final `/`
fn dirNameWithSlash(path: []const u8) []const u8 {
    const d = fs.path.dirname(path).?;
    if (d.len > 1) {
        return path[0 .. d.len + 1];
    } else {
        return "/";
    }
}
