const microzig = @import("microzig");
const std = @import("std");

const cart = @import("cart-api");
pub const Color = extern struct {
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
            microzig.cpu.interrupt.disable_interrupts();
            defer microzig.cpu.interrupt.enable_interrupts();

            const OUTCLR = &neopixels.pin.group.ptr().OUTCLR;
            const pin_mask = @as(u32, 1) << neopixels.pin.num;
            var clobber_r0: usize = undefined;
            var clobber_r1: usize = undefined;
            var clobber_r2: usize = undefined;
            var clobber_r3: usize = undefined;
            asm volatile (
                \\  add     r3, r2, r3;
                \\
                \\1: // initial_pause:
                \\  str r1, [r0, #0];                       // clr
                \\  mov r6, #3000; 0: subs r6, #1; bne 0b;  // 80us low
                \\
                \\2: // loop_load:
                \\  ldrb r5, [r2, #0];                      // r5 := *ptr
                \\  add  r2, #1;                            // ptr++
                \\  movs    r4, #128;                       // r4-mask, 0x80
                \\
                \\3: // loop_bit:
                \\  str r1, [r0, #4];                       // set
                \\  movs r6, #11; 0: subs r6, #1; bne 0b;   // 300 ns high (entire T0H or start T1H)
                \\  tst r4, r5;                             // mask&r5
                \\  bne 4f;
                \\  str r1, [r0, #0];                       // clr
                \\
                \\4: // skipclr:
                \\  movs r6, #15; 0: subs r6, #1; bne 0b;   // 388 ns low or high (start T0L or end T1H)
                \\  str r1, [r0, #0];                       // clr (possibly again, doesn't matter)
                \\  asrs     r4, r4, #1;                    // mask >>= 1
                \\  beq     5f;
                \\  uxtb    r4, r4;
                \\  movs r6, #20; 0: subs r6, #1; bne 0b;   // 548 ns (end TOL or entire T1L)
                \\  b       3b;
                \\
                \\5: // nextbyte:
                \\  movs r6, #18; 0: subs r6, #1; bne 0b;   // extra for 936 ns total (byte end T0L or entire T1L)
                \\  cmp r2, r3;
                \\  bcs 6f;
                \\  b 2b;
                \\
                \\6: // neopixel_stop:
                \\
                : [clobber_r0] "={r0}" (clobber_r0),
                  [clobber_r1] "={r1}" (clobber_r1),
                  [clobber_r2] "={r2}" (clobber_r2),
                  [clobber_r3] "={r3}" (clobber_r3),
                : [OUTCLR] "{r0}" (OUTCLR),
                  [pin_mask] "{r1}" (pin_mask),
                  [ptr] "{r2}" (buf.ptr),
                  [count] "{r3}" (buf.len),
                : .{ .r4 = true, .r5 = true, .r6 = true });
        }
    };
}
