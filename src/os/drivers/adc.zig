const std = @import("std");

const microzig = @import("microzig");
const board = microzig.board;
const adc = microzig.hal.adc;

const terry = @import("../system/terry.zig");

pub var battery_voltage: f32 = 0.0;
pub var battery_level: u8 = 0;

pub var light_level: u12 = std.math.maxInt(u12);

var waiting_for: terry.core0.TrackedStateMachine(enum { battery, light }) = undefined;

pub fn init() void {
    board.battery_level_pin.set_direction(.in);
    board.battery_level_pin.set_pull(.disabled);
    board.battery_level_pin.set_function(.sio);

    board.light_sensor_pin.set_direction(.in);
    board.light_sensor_pin.set_pull(.disabled);
    board.light_sensor_pin.set_function(.sio);

    adc.set_enabled(true);

    adc.select_input(board.battery_level_adc);
    adc.start(.one_shot);
    waiting_for.register("adc.waiting_for", .battery, @src());
}

pub fn poll() void {
    if (!adc.is_ready()) return;

    if (adc.read_result()) |raw| {
        switch (waiting_for.state) {
            .battery => {
                const read_voltage = 3.3 * @as(f32, @floatFromInt(raw)) / std.math.maxInt(@TypeOf(raw));
                // The battery voltage goes through a /2 divider before being read.
                battery_voltage = read_voltage * 2;

                // The maximum voltage is theoretically ~4.5V, but it seems to often be a little
                // higher for some reason, so scale to 4.7 to get a bit of extra range.
                battery_level = @floor(battery_voltage / 4.7 * std.math.maxInt(@TypeOf(battery_level)));
            },
            .light => {
                light_level = raw;
            },
        }
    } else |err| switch (err) {
        error.Conversion => adc.start(.one_shot), // try again
    }

    switch (waiting_for.state) {
        .battery => {
            adc.select_input(board.light_sensor_adc);
            adc.start(.one_shot);
            waiting_for.set_state(.light, @src());
        },
        .light => {
            adc.select_input(board.battery_level_adc);
            adc.start(.one_shot);
            waiting_for.set_state(.battery, @src());
        },
    }
}
