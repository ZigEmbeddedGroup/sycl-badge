const WindowsWatcher = @This();

const std = @import("std");
const windows = std.os.windows;
const Reloader = @import("../Reloader.zig");

handles: std.ArrayListUnmanaged(windows.HANDLE) = .{},

pub fn init(gpa: std.mem.Allocator, paths: []const []const u8) error{ InvalidHandle, OutOfMemory }!WindowsWatcher {
    var watcher = WindowsWatcher{};
    errdefer watcher.deinit(gpa);

    try watcher.handles.ensureUnusedCapacity(gpa, paths.len);

    var path_buf = std.ArrayListUnmanaged(u8){};
    defer path_buf.deinit(gpa);

    for (paths) |path| {
        try path_buf.ensureUnusedCapacity(gpa, path.len + 1);
        path_buf.appendSliceAssumeCapacity(path);
        path_buf.appendAssumeCapacity(0);

        const handle = FindFirstChangeNotificationA(
            @ptrCast(path_buf.items),
            windows.TRUE,
            windows.FILE_NOTIFY_CHANGE_LAST_WRITE | windows.FILE_NOTIFY_CHANGE_FILE_NAME | windows.FILE_NOTIFY_CHANGE_DIR_NAME,
        );
        if (handle == std.os.windows.INVALID_HANDLE_VALUE) return error.InvalidHandle;
        watcher.handles.appendAssumeCapacity(handle);
    }

    return watcher;
}

pub fn deinit(watcher: *WindowsWatcher, gpa: std.mem.Allocator) void {
    for (watcher.handles.items) |handle| {
        windows.CloseHandle(handle);
    }
    watcher.handles.deinit(gpa);
}

pub fn listen(
    watcher: *WindowsWatcher,
    gpa: std.mem.Allocator,
    context: anytype,
    callback: *const fn (@TypeOf(context), changed_handle: usize) void,
) error{ UnknownWaitStatus, NextChangeFailed, WaitAbandoned, Unexpected }!void {
    _ = gpa;

    wait_loop: while (true) {
        const status = windows.WaitForMultipleObjectsEx(watcher.handles.items, false, windows.INFINITE, false) catch |err| switch (err) {
            error.WaitTimeOut => unreachable,
            else => |e| return e,
        };

        for (watcher.handles.items, 0..) |handle, offset| {
            if (status == windows.WAIT_OBJECT_0 + offset) {
                callback(context, offset);
                // Stop multifiring
                while (true) {
                    if (FindNextChangeNotification(handle) == windows.FALSE) return error.NextChangeFailed;
                    const status_2 = windows.WaitForMultipleObjectsEx(&.{handle}, false, 10, false) catch |err| switch (err) {
                        error.WaitTimeOut => break,
                        else => |e| return e,
                    };
                    if (status_2 != windows.WAIT_OBJECT_0) return error.UnknownWaitStatus;
                }
                if (FindNextChangeNotification(handle) == windows.FALSE) return error.NextChangeFailed;
                continue :wait_loop;
            }
        }

        return error.UnknownWaitStatus;
    }
}

extern fn FindFirstChangeNotificationA(
    lpPathName: windows.LPCSTR,
    bWatchSubtree: windows.BOOL,
    dwNotifyFilter: windows.DWORD,
) callconv(windows.WINAPI) windows.HANDLE;

extern fn FindNextChangeNotification(
    handle: windows.HANDLE,
) callconv(windows.WINAPI) windows.BOOL;
