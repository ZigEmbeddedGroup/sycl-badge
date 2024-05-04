const MacosWatcher = @This();

const std = @import("std");
const Reloader = @import("../Reloader.zig");
const c = @cImport({
    @cInclude("CoreServices/CoreServices.h");
});

const log = std.log.scoped(.watcher);

paths: []const []const u8,
macos_paths: []const c.CFStringRef,
paths_to_watch: c.CFArrayRef,

pub fn init(gpa: std.mem.Allocator, paths: []const []const u8) !MacosWatcher {
    const macos_paths = try gpa.alloc(c.CFStringRef, paths.len);

    for (paths, macos_paths) |str, *ref| {
        ref.* = c.CFStringCreateWithCString(
            null,
            str.ptr,
            c.kCFStringEncodingUTF8,
        );
    }

    const paths_to_watch: c.CFArrayRef = c.CFArrayCreate(
        null,
        @ptrCast(macos_paths.ptr),
        @intCast(macos_paths.len),
        null,
    );

    return .{
        .paths = paths,
        .macos_paths = macos_paths,
        .paths_to_watch = paths_to_watch,
    };
}

pub fn deinit(watcher: *MacosWatcher, gpa: std.mem.Allocator) void {
    gpa.free(watcher.macos_paths);
    c.CFRelease(watcher.paths_to_watch);
}

fn eventStreamCallback(comptime ContextType: type) fn (
    streamRef: c.ConstFSEventStreamRef,
    clientCallBackInfo: ?*anyopaque,
    numEvents: usize,
    eventPaths: ?*anyopaque,
    eventFlags: ?[*]const c.FSEventStreamEventFlags,
    eventIds: ?[*]const c.FSEventStreamEventId,
) callconv(.C) void {
    return struct {
        fn call(
            streamRef: c.ConstFSEventStreamRef,
            clientCallBackInfo: ?*anyopaque,
            numEvents: usize,
            eventPaths: ?*anyopaque,
            eventFlags: ?[*]const c.FSEventStreamEventFlags,
            eventIds: ?[*]const c.FSEventStreamEventId,
        ) callconv(.C) void {
            _ = eventIds;
            _ = eventFlags;
            _ = streamRef;
            const ctx: *Context(ContextType) = @alignCast(@ptrCast(clientCallBackInfo));

            const watcher = ctx.watcher;
            const callback = ctx.callback;

            const paths: [*][*:0]u8 = @alignCast(@ptrCast(eventPaths));
            for (paths[0..numEvents]) |p| {
                const path = std.mem.span(p);
                log.debug("Changed: {s}\n", .{path});

                const basename = std.fs.path.basename(path);
                var base_path = path[0 .. path.len - basename.len];
                if (std.mem.endsWith(u8, base_path, "/"))
                    base_path = base_path[0 .. base_path.len - 1];

                for (watcher.paths, 0..) |target_path, idx| {
                    if (std.mem.startsWith(u8, path, target_path)) {
                        callback(ctx.context, idx);
                        break;
                    }
                }
            }
        }
    }.call;
}

pub fn Context(comptime ContextType: type) type {
    return struct {
        watcher: *const MacosWatcher,
        context: ContextType,
        callback: *const fn (ContextType, changed_handle: usize) void,
    };
}

pub fn listen(
    watcher: *MacosWatcher,
    gpa: std.mem.Allocator,
    context: anytype,
    callback: *const fn (@TypeOf(context), changed_handle: usize) void,
) !void {
    _ = gpa; // autofix
    var stream_context_context = Context(@TypeOf(context)){
        .watcher = watcher,
        .callback = callback,
        .context = context,
    };

    var stream_context: c.FSEventStreamContext = .{ .info = &stream_context_context };
    const stream: c.FSEventStreamRef = c.FSEventStreamCreate(
        null,
        &eventStreamCallback(@TypeOf(callback)),
        &stream_context,
        watcher.paths_to_watch,
        c.kFSEventStreamEventIdSinceNow,
        0.05,
        c.kFSEventStreamCreateFlagFileEvents,
    );

    c.FSEventStreamScheduleWithRunLoop(
        stream,
        c.CFRunLoopGetCurrent(),
        c.kCFRunLoopDefaultMode,
    );

    if (c.FSEventStreamStart(stream) == 0) {
        @panic("failed to start the event stream");
    }

    c.CFRunLoopRun();

    c.FSEventStreamStop(stream);
    c.FSEventStreamInvalidate(stream);
    c.FSEventStreamRelease(stream);
}
