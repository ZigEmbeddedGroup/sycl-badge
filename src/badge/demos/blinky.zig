const microzig = @import("microzig");

const led_pin = microzig.board.D13;

pub fn main() !void {
    // Initialize pins
    led_pin.set_dir(.out);

    const period = 200000;
    while (true) {
        delay_count(period);
        led_pin.write(.high);
        delay_count(period);
        led_pin.write(.low);
    }
}

fn delay_count(count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {}
}
