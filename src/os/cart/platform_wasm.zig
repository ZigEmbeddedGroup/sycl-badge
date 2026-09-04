
const start_code = struct {
    const root = @import("root");

    export fn start() void {
        root.start();
    }

    export fn update() void {
        root.update();
    }
};

pub fn export_start_code() void {
    comptime {
        _ = start_code;
    }
}
