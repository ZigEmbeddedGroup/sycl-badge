const Reloader = @This();
const std = @import("std");
const builtin = @import("builtin");
const ws = @import("ws");

const log = std.log.scoped(.watcher);
const Watcher = switch (builtin.target.os.tag) {
    .linux => @import("watcher/LinuxWatcher.zig"),
    .macos => @import("watcher/MacosWatcher.zig"),
    .windows => @import("watcher/WindowsWatcher.zig"),
    else => @compileError("unsupported platform"),
};

gpa: std.mem.Allocator,
ws_server: ws.Server,
zig_exe: []const u8,
watcher: Watcher,
output_dir_index: usize,

clients_lock: std.Thread.Mutex = .{},
clients: std.AutoArrayHashMapUnmanaged(*ws.Conn, void) = .{},

pub fn init(
    gpa: std.mem.Allocator,
    zig_exe: []const u8,
    dirs_to_watch: []const []const u8,
) !Reloader {
    const ws_server = try ws.Server.init(gpa, .{});

    return .{
        .gpa = gpa,
        .zig_exe = zig_exe,
        .ws_server = ws_server,
        .watcher = try Watcher.init(gpa, dirs_to_watch),
        .output_dir_index = dirs_to_watch.len - 1,
    };
}

pub fn listen(reloader: *Reloader) !void {
    try reloader.watcher.listen(reloader.gpa, reloader, &onChange);
}

pub fn onChange(reloader: *Reloader, dir_that_changed: usize) void {
    if (dir_that_changed == reloader.output_dir_index) {
        std.log.info("Output changed", .{});

        reloader.clients_lock.lock();
        defer reloader.clients_lock.unlock();

        var idx: usize = 0;
        while (idx < reloader.clients.entries.len) {
            const conn = reloader.clients.entries.get(idx).key;

            conn.write("reload") catch |err| {
                log.debug("error writing to websocket: {s}", .{
                    @errorName(err),
                });
                reloader.clients.swapRemoveAt(idx);
                continue;
            };

            idx += 1;
        }
    } else {
        std.log.info("Input changed", .{});

        const result = std.ChildProcess.run(.{
            .allocator = reloader.gpa,
            .argv = &.{ reloader.zig_exe, "build" },
        }) catch |err| {
            log.err("unable to run zig build: {s}", .{@errorName(err)});
            return;
        };
        defer {
            reloader.gpa.free(result.stdout);
            reloader.gpa.free(result.stderr);
        }

        if (result.stdout.len > 0) {
            log.info("zig build stdout: {s}", .{result.stdout});
        }

        if (result.stderr.len > 0) {
            std.debug.print("{s}\n\n", .{result.stderr});
        } else {
            std.debug.print("File change triggered a successful build.\n", .{});
        }

        reloader.clients_lock.lock();
        defer reloader.clients_lock.unlock();

        var idx: usize = 0;
        while (idx < reloader.clients.entries.len) {
            const conn = reloader.clients.entries.get(idx).key;

            const BuildCommand = struct {
                command: []const u8 = "build",
                err: []const u8,
            };

            const cmd: BuildCommand = .{ .err = result.stderr };

            var buf = std.ArrayList(u8).init(reloader.gpa);
            defer buf.deinit();

            std.json.stringify(cmd, .{}, buf.writer()) catch {
                log.err("unable to generate ws message", .{});
                return;
            };

            conn.write(buf.items) catch |err| {
                log.debug("error writing to websocket: {s}", .{
                    @errorName(err),
                });
                reloader.clients.swapRemoveAt(idx);
                continue;
            };

            idx += 1;
        }
    }
}

pub fn handleWs(reloader: *Reloader, stream: std.net.Stream, h: [20]u8) void {
    var buf =
        ("HTTP/1.1 101 Switching Protocols\r\n" ++
        "Access-Control-Allow-Origin: *\r\n" ++
        "Upgrade: websocket\r\n" ++
        "Connection: upgrade\r\n" ++
        "Sec-Websocket-Accept: 0000000000000000000000000000\r\n\r\n").*;

    const key_pos = buf.len - 32;
    _ = std.base64.standard.Encoder.encode(buf[key_pos .. key_pos + 28], h[0..]);

    stream.writeAll(&buf) catch @panic("bad");

    // var conn = reloader.ws_server.newConn(stream);
    const conn = reloader.gpa.create(ws.Conn) catch @panic("bad");
    conn.* = reloader.ws_server.newConn(stream);

    var context: Handler.Context = .{ .watcher = reloader };
    var handler = Handler.init(undefined, conn, &context) catch @panic("bad");
    reloader.ws_server.handle(Handler, &handler, conn);
}

const Handler = struct {
    conn: *ws.Conn,
    context: *Context,

    const Context = struct {
        watcher: *Reloader,
    };

    pub fn init(h: ws.Handshake, conn: *ws.Conn, context: *Context) !Handler {
        _ = h;

        const watcher = context.watcher;
        watcher.clients_lock.lock();
        defer watcher.clients_lock.unlock();
        try watcher.clients.put(context.watcher.gpa, conn, {});

        return Handler{
            .conn = conn,
            .context = context,
        };
    }

    pub fn handle(handler: *Handler, message: ws.Message) !void {
        _ = handler;
        _ = message;
    }

    pub fn close(handler: *Handler) void {
        log.debug("ws connection was closed\n", .{});
        const watcher = handler.context.watcher;
        watcher.clients_lock.lock();
        defer watcher.clients_lock.unlock();
        _ = watcher.clients.swapRemove(handler.conn);
    }
};
