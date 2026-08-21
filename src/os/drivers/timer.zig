const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

// HAL + time imports
const time = microzig.drivers.time;
const system_timer = hal.system_timer;

const timer0 = system_timer.num(0);
pub const Absolute = time.Absolute;

const terry = @import("../system/terry.zig");

// -----------------------------------------------------------------------------
// Time utilities
// -----------------------------------------------------------------------------
pub fn get_time_since_boot() Absolute {
    return @enumFromInt(timer0.read());
}

/// Sleep for milliseconds (blocking)
pub fn sleep_ms(time_ms: u32) void {
    sleep_us(time_ms * 1000);
}

/// Sleep for microseconds (blocking)
pub fn sleep_us(time_us: u64) void {
    const z = terry.core0.zone_color_cond("Sleep", @src(), 0x6f6f6f, time_us > 500); defer z.end();

    const end_time = time.make_timeout_us(get_time_since_boot(), time_us);
    while (!end_time.is_reached_by(get_time_since_boot())) {}
}

/// Get current time in milliseconds
pub fn millis() u64 {
    return timer0.read() / 1000;
}

/// Get current time in microseconds
pub fn micros() u64 {
    return timer0.read();
}
