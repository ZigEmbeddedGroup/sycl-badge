const microzig = @import("microzig");
const std = @import("std");

pub const Color = struct {
    g: u8,
    r: u8,
    b: u8,
};

pub fn Group(comptime count: u16) type {
    return struct {
        pin: microzig.hal.port.Pin,

        const Self = @This();

        pub fn init(pin: microzig.hal.port.Pin) Self {
            pin.set_dir(.out);

            const ret = Self{ .pin = pin };
            ret.reset();

            return ret;
        }

        pub fn reset(neopixels: Self) void {
            neopixels.write_all(.{ .r = 0, .g = 0, .b = 0 });
        }

        pub fn write_all(neopixels: Self, color: Color) void {
            var colors: [count]Color = undefined;
            for (&colors) |*c|
                c.* = color;

            neopixels.write(&colors);
        }

        pub fn write(neopixels: Self, colors: *const [count]Color) void {
            var buf: [3 * count]u8 = undefined;

            for (colors, 0..) |c, i| {
                buf[(3 * i) + 0] = c.g;
                buf[(3 * i) + 1] = c.r;
                buf[(3 * i) + 2] = c.b;
            }

            neopixels.write_buf(&buf);
        }

        pub fn write_buf(neopixels: Self, buf: []const u8) void {
            microzig.cpu.disable_interrupts();
            defer microzig.cpu.enable_interrupts();

            const OUTCLR = &neopixels.pin.group.ptr().OUTCLR;
            const pin_mask = @as(u32, 1) << neopixels.pin.num;
            asm volatile (
                \\  add     r3, r2, r3;
                \\
                \\initial_pause:
                \\  str r1, [r0, #0];                       // clr
                \\  mov r6, #3000; d4: subs r6, #1; bne d4;  // 80us low
                \\
                \\loop_load:
                \\  ldrb r5, [r2, #0];                      // r5 := *ptr
                \\  add  r2, #1;                            // ptr++
                \\  movs    r4, #128;                       // r4-mask, 0x80
                \\
                \\loop_bit:
                \\  str r1, [r0, #4];                       // set
                \\  movs r6, #11; d2: subs r6, #1; bne d2;  // 300 ns high (entire T0H or start T1H)
                \\  tst r4, r5;                             // mask&r5
                \\  bne skipclr;
                \\  str r1, [r0, #0];                       // clr
                \\
                \\skipclr:
                \\  movs r6, #15; d0: subs r6, #1; bne d0;  // 388 ns low or high (start T0L or end T1H)
                \\  str r1, [r0, #0];                       // clr (possibly again, doesn't matter)
                \\  asrs     r4, r4, #1;                    // mask >>= 1
                \\  beq     nextbyte;
                \\  uxtb    r4, r4;
                \\  movs r6, #20; d1: subs r6, #1; bne d1;  // 548 ns (end TOL or entire T1L)
                \\  b       loop_bit;
                \\
                \\nextbyte:
                \\  movs r6, #18; d3: subs r6, #1; bne d3;  // extra for 936 ns total (byte end T0L or entire T1L)
                \\  cmp r2, r3;
                \\  bcs neopixel_stop;
                \\  b loop_load;
                \\
                \\neopixel_stop:
                \\
                :
                : [OUTCLR] "{r0}" (OUTCLR),
                  [pin_mask] "{r1}" (pin_mask),
                  [ptr] "{r2}" (buf.ptr),
                  [count] "{r3}" (buf.len),
                : "r4", "r5", "r6"
            );
        }
    };
}
