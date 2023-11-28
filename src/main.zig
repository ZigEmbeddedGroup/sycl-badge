const audio = @import("audio.zig");
const builtin = @import("builtin");
const cart = @import("cart.zig");
const GCLK = @import("chip.zig").GCLK;
const io = microzig.chip.peripherals;
const io_types = microzig.chip.types.peripherals;
const lcd = @import("lcd.zig");
const microzig = @import("microzig");
const NVMCTRL = @import("chip.zig").NVMCTRL;
const options = @import("options");
const Port = @import("Port.zig");
const sleep = microzig.core.experimental.debug.busy_sleep;
const std = @import("std");
const timer = @import("timer.zig");
const utils = @import("utils.zig");

pub const std_options = struct {
    pub const log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseSafe, .ReleaseFast, .ReleaseSmall => .info,
    };
    pub const logFn = log;
};

pub const microzig_options = struct {
    pub const interrupts = struct {
        const interrupt_log = std.log.scoped(.interrupt);
        const Context = extern struct {
            R0: u32,
            R1: u32,
            R2: u32,
            R3: u32,
            R12: u32,
            LR: u32,
            ReturnAddress: u32,
            xPSR: u32,
        };

        pub const NonMaskableInt = unhandled("NonMaskableInt");
        pub const HardFault = withContext(struct {
            fn handler(ctx: *Context) void {
                interrupt_log.info("[HardFault] HFSR = 0x{x}, ReturnAddress = 0x{x}", .{
                    io.SystemControl.HFSR.raw,
                    ctx.ReturnAddress,
                });
                microzig.hang();
            }
        }.handler);
        pub const MemoryManagement = withContext(struct {
            fn handler(ctx: *Context) void {
                interrupt_log.info("[MemoryManagement] CFSR = 0x{x}, MMFAR = 0x{x}, ReturnAddress = 0x{x}", .{
                    io.SystemControl.CFSR.raw,
                    io.SystemControl.MMFAR.raw,
                    ctx.ReturnAddress,
                });
                microzig.hang();
            }
        }.handler);
        pub const BusFault = withContext(struct {
            fn handler(ctx: *Context) void {
                interrupt_log.info("[BusFault] CFSR = 0x{x}, BFAR = 0x{x}, ReturnAddress = 0x{x}", .{
                    io.SystemControl.CFSR.raw,
                    io.SystemControl.BFAR.raw,
                    ctx.ReturnAddress,
                });
                microzig.hang();
            }
        }.handler);
        pub const UsageFault = withContext(struct {
            fn handler(ctx: *Context) void {
                interrupt_log.info("[UsageFault] CFSR = 0x{x}, ReturnAddress = 0x{x}", .{
                    io.SystemControl.CFSR.raw,
                    ctx.ReturnAddress,
                });
                microzig.hang();
            }
        }.handler);
        pub fn SVCall() callconv(.Naked) void {
            asm volatile (
                \\ mvns r0, lr, lsl #31 - 2
                \\ bcc 1f
                \\ ite mi
                \\ movmi r1, sp
                \\ mrspl r1, psp
                \\ ldr r2, [r1, #6 * 4]
                \\ subs r2, #2
                \\ ldrb r3, [r2, #1 * 1]
                \\ cmp r3, #0xDF
                \\ bne 1f
                \\ ldrb r3, [r2, #0 * 1]
                \\ cmp r3, #12
                \\ bhi 1f
                \\ tbb [pc, r3]
                \\0:
                \\ .byte (0f - 0b) / 2
                \\ .byte (9f - 0b) / 2
                \\ .byte (9f - 0b) / 2
                \\ .byte (2f - 0b) / 2
                \\ .byte (3f - 0b) / 2
                \\ .byte (4f - 0b) / 2
                \\ .byte (5f - 0b) / 2
                \\ .byte (6f - 0b) / 2
                \\ .byte (7f - 0b) / 2
                \\ .byte (8f - 0b) / 2
                \\ .byte (8f - 0b) / 2
                \\ .byte (10f - 0b) / 2
                \\1:
                \\ .byte (11f - 0b) / 2
                \\ .byte 0xDE
                \\ .align 1
                \\0:
                \\ ldm r1, {r0-r3}
                \\ b %[blit:P]
                \\2:
                \\ ldm r1, {r0-r3}
                \\ b %[oval:P]
                \\3:
                \\ ldm r1, {r0-r3}
                \\ b %[rect:P]
                \\4:
                \\ ldm r1, {r0-r3}
                \\ b %[text:P]
                \\5:
                \\ ldm r1, {r0-r2}
                \\ b %[vline:P]
                \\6:
                \\ ldm r1, {r0-r2}
                \\ b %[hline:P]
                \\7:
                \\ ldm r1, {r0-r3}
                \\ b %[tone:P]
                \\8:
                \\ movs r0, #0
                \\ str r0, [r1, #0 * 4]
                \\9:
                \\ bx lr
                \\10:
                \\ ldm r1, {r0-r1}
                \\ b %[trace:P]
                \\11:
                \\ lsrs r0, #31
                \\ msr control, r0
                \\ it eq
                \\ popeq {r3, r5-r11, pc}
                \\ subs r0, #1 - 0xFFFFFFFD
                \\ push {r4-r11, lr}
                \\ movs r4, #0
                \\ movs r5, #0
                \\ movs r6, #0
                \\ movs r7, #0
                \\ mov r8, r4
                \\ mov r9, r5
                \\ mov r10, r6
                \\ mov r11, r7
                \\ bx r0
                :
                : [blit] "X" (&cart.blit),
                  [oval] "X" (&cart.oval),
                  [rect] "X" (&cart.rect),
                  [text] "X" (&cart.text),
                  [vline] "X" (&cart.vline),
                  [hline] "X" (&cart.hline),
                  [tone] "X" (&cart.tone),
                  [trace] "X" (&cart.trace),
            );
        }
        pub const DebugMonitor = unhandled("DebugMonitor");
        pub const PendSV = unhandled("PendSV");
        pub const SysTick = unhandled("SysTick");
        pub const DMAC_DMAC_1 = audio.mix;

        fn unhandled(comptime name: []const u8) fn () callconv(.C) void {
            return struct {
                fn handler() callconv(.C) void {
                    interrupt_log.info(name, .{});
                    microzig.hang();
                }
            }.handler;
        }
        fn withContext(comptime handler: fn (*Context) void) fn () callconv(.Naked) void {
            return struct {
                fn interrupt() callconv(.Naked) void {
                    asm volatile (
                        \\ tst lr, #1 << 2
                        \\ ite eq
                        \\ moveq r0, sp
                        \\ mrsne r0, psp
                        \\ b %[handler:P]
                        :
                        : [handler] "X" (&handler),
                    );
                }
            }.interrupt;
        }
    };
};

const InOutError = error{NoConnection};
pub const in: std.io.Reader(void, InOutError, struct {
    fn read(_: void, buffer: []u8) InOutError!usize {
        if (usb.cdc.current_connection == 0) return error.NoConnection;
        return usb.read(2, buffer).len;
    }
}.read) = .{ .context = {} };
pub const out: std.io.Writer(void, InOutError, struct {
    fn write(_: void, data: []const u8) InOutError!usize {
        if (usb.cdc.current_connection == 0) return error.NoConnection;
        if (data.len == 0) return data.len;
        var line_it = std.mem.splitScalar(u8, data, '\n');
        var first = true;
        while (line_it.next()) |line| {
            if (!first) usb.write(2, "\r\n");
            var chunk_it = std.mem.window(u8, line, 64, 64);
            while (chunk_it.next()) |chunk| usb.write(2, chunk);
            first = false;
        }
        return data.len;
    }
}.write) = .{ .context = {} };

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    out.print("[" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ "): " ++ format ++ "\n", args) catch return;
}

pub fn dumpPeripheral(logger: anytype, comptime prefix: []const u8, pointer: anytype) void {
    switch (@typeInfo(@typeInfo(@TypeOf(pointer)).Pointer.child)) {
        .Int => {
            logger.info("[0x{x}] " ++ prefix ++ " = 0x{x}", .{ @intFromPtr(pointer), pointer.* });
        },
        .Struct => |*info| inline for (info.fields) |field| {
            if (comptime std.mem.startsWith(u8, field.name, "reserved")) continue;
            if (comptime std.mem.eql(u8, field.name, "padding")) continue;
            dumpPeripheral(logger, prefix ++ "." ++ field.name, &@field(pointer, field.name));
        },
        .Array => inline for (0.., pointer) |index, *elem| {
            dumpPeripheral(logger, std.fmt.comptimePrint("{s}[{d}]", .{ prefix, index }), elem);
        },
        else => @compileError("Unhandled type: " ++ @typeName(@TypeOf(pointer))),
    }
}

pub fn main() !void {
    io.SystemControl.CCR.modify(.{
        .NONBASETHRDENA = 0,
        .USERSETMPEND = 0,
        .reserved3 = 0,
        .UNALIGN_TRP = .{ .value = .VALUE_0 }, // TODO
        .DIV_0_TRP = 1,
        .reserved8 = 0,
        .BFHFNMIGN = 0,
        .STKALIGN = .{ .value = .VALUE_1 },
        .padding = 0,
    });
    io.SystemControl.SHCSR.modify(.{
        .MEMFAULTENA = 1,
        .BUSFAULTENA = 1,
        .USGFAULTENA = 1,
    });
    io.SystemControl.CPACR.write(.{
        .reserved20 = 0,
        .CP10 = .{ .value = .FULL },
        .CP11 = .{ .value = .FULL },
        .padding = 0,
    });

    io.MCLK.AHBMASK.modify(.{ .CMCC_ = 1 });
    io.CMCC.CTRL.write(.{
        .CEN = 1,
        .padding = 0,
    });

    io.NVMCTRL.CTRLA.modify(.{ .AUTOWS = 1 });

    io.GCLK.CTRLA.write(.{ .SWRST = 1, .padding = 0 });
    while (io.GCLK.SYNCBUSY.read().SWRST != 0) {}

    microzig.cpu.dmb();

    usb.init();
    // ID detection
    const id_port = Port.D13;
    id_port.setDir(.out);
    id_port.write(.high);
    id_port.configPtr().write(.{
        .PMUXEN = 0,
        .INEN = 1,
        .PULLEN = 1,
        .reserved6 = 0,
        .DRVSTR = 0,
        .padding = 0,
    });
    usb.reinitMode(.DEVICE);

    timer.init();
    lcd.init(.bpp24);
    audio.init();

    io.MPU.RBAR.write(.{
        .REGION = 0,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.FLASH.ADDR) >> 5,
    });
    io.MPU.RASR.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(utils.FLASH.SIZE) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(utils.FLASH.SIZE) - 1) >> 1),
        .SRD = if (options.have_cart) 0b00000111 else 0b00000000,
        .B = 0,
        .C = 1,
        .S = 0,
        .TEX = 0b000,
        .reserved24 = 0,
        .AP = 0b010,
        .reserved28 = 0,
        .XN = 0,
        .padding = 0,
    });
    io.MPU.RBAR_A1.write(.{
        .REGION = 1,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.HSRAM.ADDR) >> 5,
    });
    io.MPU.RASR_A1.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(@divExact(utils.HSRAM.SIZE, 3) * 2) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(@divExact(utils.HSRAM.SIZE, 3) * 2) - 1) >> 1),
        .SRD = if (options.have_cart) 0b11110000 else 0b00000000,
        .B = 1,
        .C = 1,
        .S = 0,
        .TEX = 0b001,
        .reserved24 = 0,
        .AP = 0b011,
        .reserved28 = 0,
        .XN = 1,
        .padding = 0,
    });
    io.MPU.RBAR_A2.write(.{
        .REGION = 2,
        .VALID = 1,
        .ADDR = @intFromPtr(utils.HSRAM.ADDR[@divExact(utils.HSRAM.SIZE, 3) * 2 ..]) >> 5,
    });
    io.MPU.RASR_A2.write(.{
        .ENABLE = 1,
        .SIZE = (@ctz(@divExact(utils.HSRAM.SIZE, 3)) - 1) & 1,
        .reserved8 = @as(u4, (@ctz(@divExact(utils.HSRAM.SIZE, 3)) - 1) >> 1),
        .SRD = 0b11001111,
        .B = 1,
        .C = 1,
        .S = 0,
        .TEX = 0b001,
        .reserved24 = 0,
        .AP = 0b011,
        .reserved28 = 0,
        .XN = 1,
        .padding = 0,
    });
    io.MPU.CTRL.write(.{
        .ENABLE = 1,
        .HFNMIENA = 0,
        .PRIVDEFENA = 1,
        .padding = 0,
    });

    cart.init();

    var was_ready = false;
    var cart_running = false;
    var color: enum { red, green, blue } = .red;
    while (true) {
        usb.tick();

        input: {
            var input_buffer: [64]u8 = undefined;
            const data = input_buffer[0 .. in.read(&input_buffer) catch |err| {
                switch (err) {
                    error.NoConnection => was_ready = false,
                }
                break :input;
            }];
            if (!was_ready) {
                std.log.info("Ready!", .{});
                cart.start();
                was_ready = true;
                cart_running = true;
            }
            if (data.len > 0) for (data) |c| switch (c) {
                else => out.writeByte(c) catch break :input,
                'A' - '@' => {
                    timer.delay(std.time.us_per_s);
                    const tempo = 0.78;
                    audio.playSong(&.{
                        &.{
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Bb4 },
                            .{ .duration = tempo * 3.00, .frequency = audio.Note.C5 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Gb5 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 1.50, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo * 0.80, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 0.20, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.F5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.D5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.F5 },
                            .{ .duration = tempo / 7.0, .frequency = audio.Note.Gb5 },
                            //
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Bb4 },
                            .{ .duration = tempo * 3.00, .frequency = audio.Note.C5 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Gb5 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 1.50, .frequency = audio.Note.F5 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Eb5 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Db5 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C5 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db5 },
                        },
                        &.{
                            .{ .duration = tempo * 8.00, .frequency = 0 },
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.Gb4 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Bb4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 2.00, .frequency = 0 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.F4 },
                            .{ .duration = tempo * 0.50, .frequency = 0 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Gb4 },
                            .{ .duration = tempo * 7.50, .frequency = 0 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.F4 },
                            .{ .duration = tempo * 0.50, .frequency = 0 },
                            .{ .duration = tempo * 0.75, .frequency = audio.Note.Gb4 },
                            .{ .duration = tempo * 0.25, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 2.00, .frequency = audio.Note.Bb4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Ab4 },
                            .{ .duration = tempo * 2.00, .frequency = 0 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.F4 },
                            .{ .duration = tempo * 0.50, .frequency = 0 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.F4 },
                        },
                        &.{
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Bb3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Gb4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            //
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Bb3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 1.00, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.C4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Gb4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Db4 },
                            .{ .duration = tempo * 0.50, .frequency = audio.Note.Ab3 },
                        },
                    });
                },
                'B' - '@' => utils.resetIntoBootloader(),
                'C' - '@' => { // Debug clock frequencies
                    const clock_log = std.log.scoped(.clock);

                    io.MCLK.APBAMASK.modify(.{ .FREQM_ = 1 });

                    // Use OSCULP32K / 512 as reference
                    io.GCLK.GENCTRL[GCLK.GEN.@"64KHz".ID].write(.{
                        .SRC = .{ .value = .OSCULP32K },
                        .reserved8 = 0,
                        .GENEN = 1,
                        .IDC = 0,
                        .OOV = 0,
                        .OE = 0,
                        .DIVSEL = .{ .value = .DIV2 },
                        .RUNSTDBY = 0,
                        .reserved16 = 0,
                        .DIV = 8,
                    });
                    io.GCLK.PCHCTRL[GCLK.PCH.FREQM_REF].write(.{
                        .GEN = .{ .value = GCLK.GEN.@"64KHz".PCHCTRL_GEN },
                        .reserved6 = 0,
                        .CHEN = 1,
                        .WRTLOCK = 0,
                        .padding = 0,
                    });

                    for (0.., &io.GCLK.GENCTRL) |gen_id, *gen_ctrl| {
                        if (gen_id == GCLK.GEN.@"64KHz".ID) continue;
                        const config = gen_ctrl.read();
                        if (config.GENEN == 0) continue;

                        io.GCLK.PCHCTRL[GCLK.PCH.FREQM_MSR].write(.{
                            .GEN = .{ .raw = @intCast(gen_id) },
                            .reserved6 = 0,
                            .CHEN = 1,
                            .WRTLOCK = 0,
                            .padding = 0,
                        });

                        // Reset Frequency Meter
                        io.FREQM.CTRLA.write(.{
                            .SWRST = 1,
                            .ENABLE = 0,
                            .padding = 0,
                        });
                        while (io.FREQM.SYNCBUSY.read().SWRST != 0) {}

                        // Run Frequency Meter
                        io.FREQM.CFGA.write(.{
                            .REFNUM = 8,
                            .padding = 0,
                        });
                        io.FREQM.CTRLA.write(.{
                            .SWRST = 0,
                            .ENABLE = 1,
                            .padding = 0,
                        });
                        while (io.FREQM.SYNCBUSY.read().ENABLE != 0) {}
                        io.FREQM.CTRLB.write(.{
                            .START = 1,
                            .padding = 0,
                        });
                        while (io.FREQM.STATUS.read().BUSY != 0) {}
                        if (io.FREQM.STATUS.read().OVF == 0) {
                            const freq = (@as(u32, io.FREQM.VALUE.read().VALUE) + 1) * 8;
                            const div = switch (config.DIVSEL.value) {
                                .DIV1 => switch (config.DIV) {
                                    0 => 1,
                                    else => |div| div,
                                },
                                .DIV2 => @as(u32, 1) << @min(config.DIV + 1, @as(u5, switch (gen_id) {
                                    else => 9,
                                    1 => 17,
                                })),
                            };
                            switch (gen_id) {
                                0 => {
                                    const hs_div = @min(io.MCLK.HSDIV.read().DIV.raw, 1);
                                    clock_log.info(
                                        "High-Speed Clock ({s} / {d}): {d} Hz",
                                        .{ @tagName(config.SRC.value), div * hs_div, freq / hs_div },
                                    );
                                    const cpu_div = @min(io.MCLK.CPUDIV.read().DIV.raw, 1);
                                    clock_log.info(
                                        "CPU Clock ({s} / {d}): {d} Hz",
                                        .{ @tagName(config.SRC.value), div * cpu_div, freq / cpu_div },
                                    );
                                },
                                else => {},
                            }
                            clock_log.info(
                                "Generator #{d} ({s} / {d}): {d} Hz",
                                .{ gen_id, @tagName(config.SRC.value), div, freq },
                            );
                        } else clock_log.warn("Unable to measure generator #{d}", .{gen_id});
                    }

                    io.GCLK.PCHCTRL[GCLK.PCH.FREQM_MSR].write(.{
                        .GEN = .{ .raw = 0 },
                        .reserved6 = 0,
                        .CHEN = 0,
                        .WRTLOCK = 0,
                        .padding = 0,
                    });
                    io.GCLK.PCHCTRL[GCLK.PCH.FREQM_REF].write(.{
                        .GEN = .{ .raw = 0 },
                        .reserved6 = 0,
                        .CHEN = 0,
                        .WRTLOCK = 0,
                        .padding = 0,
                    });

                    io.MCLK.APBAMASK.modify(.{ .FREQM_ = 0 });

                    for (0.., &io.GCLK.PCHCTRL) |pch_id, *pch_ctrl| {
                        const config = pch_ctrl.read();
                        if (config.CHEN == 0) continue;
                        clock_log.info(
                            "Peripheral Channel #{d}: Generator #{d}",
                            .{ pch_id, config.GEN.raw },
                        );
                    }
                },
                'F' - '@' => if (true) {
                    lcd.fill24(switch (color) {
                        .red => lcd.red24,
                        .green => lcd.green24,
                        .blue => lcd.blue24,
                    });
                    lcd.blit24();
                    color = switch (color) {
                        .red => .green,
                        .green => .blue,
                        .blue => .red,
                    };
                },
                'G' - '@' => if (true) {
                    lcd.rect24(.{
                        .x = 0,
                        .y = 0,
                        .width = lcd.width,
                        .height = lcd.height,
                    }, lcd.red24, lcd.green24);
                    lcd.rect24(.{
                        .x = 32,
                        .y = 32,
                        .width = lcd.width - 64,
                        .height = lcd.height - 64,
                    }, lcd.blue24, lcd.black24);
                    lcd.blit24();
                },
                'I' - '@' => if (true) lcd.invert(),
                '\r' => out.writeByte('\n') catch break :input,
                'P' - '@' => @panic("user"),
                'R' - '@' => utils.resetIntoApp(),
                'S' - '@' => for (0.., &io.PORT.GROUP) |group_i, *group|
                    std.log.info("IN{d} = 0x{X:0>8}", .{ group_i, group.IN.read().IN }),
                'T' - '@' => { // Debug timer delay
                    const timer_log = std.log.scoped(.timer);
                    timer_log.info("start...", .{});
                    for (0..10) |i| {
                        if (i > 0) timer_log.info("{d}", .{i});
                        timer.delay(std.time.us_per_s);
                    }
                    timer_log.info("done!", .{});
                },
                'U' - '@' => cart_running = !cart_running,
                0x7f => out.writeAll("\x1B[D\x1B[K") catch break :input,
            };
        }

        if (cart_running) cart.tick();
    }
}

pub const usb = struct {
    var endpoint_buffer_storage: [8][2][64]u8 align(4) = .{.{.{0} ** 64} ** 2} ** 8;
    const endpoint_buffer: *align(4) volatile [8][2][64]u8 = &endpoint_buffer_storage;
    const setup = std.mem.bytesAsValue(Setup, endpoint_buffer[0][0][0..8]);

    var endpoint_table_storage: [8]io_types.USB.USB_DESCRIPTOR align(4) = undefined;
    const endpoint_table: *align(4) volatile [8]io_types.USB.USB_DESCRIPTOR = &endpoint_table_storage;

    var current_configuration: u8 = 0;

    const cdc = struct {
        var current_connection: u8 = 0;
    };

    const EpType = enum(u3) {
        disabled,
        control,
        isochronous,
        bulk,
        interrupt,
        dual,
    };

    const pcksize = struct {
        const Size = enum(u3) {
            @"8",
            @"16",
            @"32",
            @"64",
            @"128",
            @"256",
            @"512",
            @"1023",
        };
    };

    const Setup = extern struct {
        bmRequestType: packed struct(u8) {
            recipient: enum(u5) {
                device,
                interface,
                endpoint,
                other,
                _,
            },
            kind: enum(u2) {
                standard,
                class,
                vendor,
                _,
            },
            dir: enum(u1) {
                out,
                in,
            },
        },
        bRequest: u8,
        wValue: u16,
        wIndex: u16,
        wLength: u16,

        const standard = struct {
            const Request = enum(u8) {
                GET_STATUS = 0,
                CLEAR_FEATURE = 1,
                SET_FEATURE = 3,
                SET_ADDRESS = 5,
                GET_DESCRIPTOR = 6,
                SET_DESCRIPTOR = 7,
                GET_CONFIGURATION = 8,
                SET_CONFIGURATION = 9,
                GET_INTERFACE = 10,
                SET_INTERFACE = 11,
                SYNC_FRAME = 12,
                _,
            };
            const DescriptorType = enum(u8) {
                DEVICE = 1,
                CONFIGURATION = 2,
                STRING = 3,
                INTERFACE = 4,
                ENDPOINT = 5,
                DEVICE_QUALIFIER = 6,
                OTHER_SPEED_CONFIGURATION = 7,
                INTERFACE_POWER = 8,
                _,
            };
        };

        const cdc = struct {
            const Request = enum(u8) {
                SEND_ENCAPSULATED_COMMAND = 0x00,
                GET_ENCAPSULATED_RESPONSE = 0x01,
                SET_COMM_FEATURE = 0x02,
                GET_COMM_FEATURE = 0x03,
                CLEAR_COMM_FEATURE = 0x04,

                SET_AUX_LINE_STATE = 0x10,
                SET_HOOK_STATE = 0x11,
                PULSE_SETUP = 0x12,
                SEND_PULSE = 0x13,
                SET_PULSE_TIME = 0x14,
                RING_AUX_JACK = 0x15,

                SET_LINE_CODING = 0x20,
                GET_LINE_CODING = 0x21,
                SET_CONTROL_LINE_STATE = 0x22,
                SEND_BREAK = 0x23,

                SET_RINGER_PARMS = 0x30,
                GET_RINGER_PARMS = 0x31,
                SET_OPERATION_PARMS = 0x32,
                GET_OPERATION_PARMS = 0x33,
                SET_LINE_PARMS = 0x34,
                GET_LINE_PARMS = 0x35,
                DIAL_DIGITS = 0x36,
                SET_UNIT_PARAMETER = 0x37,
                GET_UNIT_PARAMETER = 0x38,
                CLEAR_UNIT_PARAMETER = 0x39,
                GET_PROFILE = 0x3A,

                SET_ETHERNET_MULTICAST_FILTERS = 0x40,
                SET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER = 0x41,
                GET_ETHERNET_POWER_MANAGEMENT_PATTERN_FILTER = 0x42,
                SET_ETHERNET_PACKET_FILTER = 0x43,
                GET_ETHERNET_STATISTIC = 0x44,

                SET_ATM_DATA_FORMAT = 0x50,
                GET_ATM_DEVICE_STATISTICS = 0x51,
                SET_ATM_DEFAULT_VC = 0x52,
                GET_ATM_VC_STATISTICS = 0x53,

                GET_NTB_PARAMETERS = 0x80,
                GET_NET_ADDRESS = 0x81,
                SET_NET_ADDRESS = 0x82,
                GET_NTB_FORMAT = 0x83,
                SET_NTB_FORMAT = 0x84,
                GET_NTB_INPUT_SIZE = 0x85,
                SET_NTB_INPUT_SIZE = 0x86,
                GET_MAX_DATAGRAM_SIZE = 0x87,
                SET_MAX_DATAGRAM_SIZE = 0x88,
                GET_CRC_MODE = 0x89,
                SET_CRC_MODE = 0x8A,

                _,
            };
            const DescriptorType = enum(u8) {
                CS_INTERFACE = 0x24,
                CS_ENDPOINT = 0x25,
                _,
            };
        };
    };

    /// One-time initialization
    fn init() void {
        @setCold(true);

        Port.@"D-".setMux(.H);
        Port.@"D+".setMux(.H);
        io.MCLK.AHBMASK.modify(.{ .USB_ = 1 });
        io.MCLK.APBBMASK.modify(.{ .USB_ = 1 });
    }

    /// Reinitialize into the specified mode
    fn reinitMode(mode: io_types.USB.USB_CTRLA__MODE) void {
        @setCold(true);

        // Tear down clocks
        io.GCLK.GENCTRL[GCLK.GEN.@"120MHz".ID].write(.{
            .SRC = .{ .value = .OSCULP32K },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"8.4672MHz".ID].write(.{
            .SRC = .{ .raw = 0 },
            .reserved8 = 0,
            .GENEN = 0,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .raw = 0 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            (GCLK.GEN.@"120MHz".SYNCBUSY_GENCTRL |
            GCLK.GEN.@"8.4672MHz".SYNCBUSY_GENCTRL) != 0)
        {}
        io.MCLK.HSDIV.write(.{ .DIV = .{ .value = .DIV1 } });
        io.MCLK.CPUDIV.write(.{ .DIV = .{ .value = .DIV1 } });
        io.OSCCTRL.DPLL[0].DPLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DPLL[0].DPLLSYNCBUSY.read().ENABLE != 0) {}
        io.OSCCTRL.DPLL[1].DPLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DPLL[1].DPLLSYNCBUSY.read().ENABLE != 0) {}
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL0].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL1].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL0_32K].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL1_32K].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"76.8KHz".ID].write(.{
            .SRC = .{ .raw = 0 },
            .reserved8 = 0,
            .GENEN = 0,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .raw = 0 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"1MHz".ID].write(.{
            .SRC = .{ .raw = 0 },
            .reserved8 = 0,
            .GENEN = 0,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .raw = 0 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            (GCLK.GEN.@"76.8KHz".SYNCBUSY_GENCTRL |
            GCLK.GEN.@"1MHz".SYNCBUSY_GENCTRL) != 0)
        {}

        // Disable USB
        io.GCLK.PCHCTRL[GCLK.PCH.USB].write(.{
            .GEN = .{ .value = GCLK.GEN.@"120MHz".PCHCTRL_GEN },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.USB.DEVICE.CTRLA.write(.{
            .SWRST = 1,
            .ENABLE = 0,
            .RUNSTDBY = 0,
            .reserved7 = 0,
            .MODE = .{ .raw = 0 },
        });
        while (io.USB.DEVICE.SYNCBUSY.read().SWRST != 0) {}

        // Disable 48MHz Generator
        io.GCLK.PCHCTRL[GCLK.PCH.USB].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"48MHz".ID].write(.{
            .SRC = .{ .raw = 0 },
            .reserved8 = 0,
            .GENEN = 0,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .raw = 0 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            GCLK.GEN.@"48MHz".SYNCBUSY_GENCTRL != 0)
        {}

        // Switch the DFLL48M to open loop mode
        io.OSCCTRL.DFLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 0,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DFLLSYNC.read().ENABLE != 0) {}
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_DFLL48].write(.{
            .GEN = .{ .raw = 0 },
            .reserved6 = 0,
            .CHEN = 0,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.OSCCTRL.DFLLMUL.write(.{
            .MUL = 48_000_000 / 1_000,
            .FSTEP = 1,
            .reserved26 = 0,
            .CSTEP = 1,
        });
        while (io.OSCCTRL.DFLLSYNC.read().DFLLMUL != 0) {}
        io.OSCCTRL.DFLLCTRLB.write(.{
            .MODE = 0,
            .STABLE = 0,
            .LLAW = 0,
            .USBCRM = 0,
            .CCDIS = 0,
            .QLDIS = 0,
            .BPLCKC = 0,
            .WAITLOCK = 0,
        });
        while (io.OSCCTRL.DFLLSYNC.read().DFLLCTRLB != 0) {}
        io.OSCCTRL.DFLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 1,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DFLLSYNC.read().ENABLE != 0) {}
        while (io.OSCCTRL.STATUS.read().DFLLRDY == 0) {}

        // Change the reference clock
        // Switch the DFLL48M to close loop mode
        io.OSCCTRL.DFLLCTRLB.write(.{
            .MODE = 1,
            .STABLE = 0,
            .LLAW = 0,
            .USBCRM = 1,
            .CCDIS = 1,
            .QLDIS = 0,
            .BPLCKC = 0,
            .WAITLOCK = 0,
        });
        while (io.OSCCTRL.DFLLSYNC.read().DFLLCTRLB != 0) {}
        while (io.OSCCTRL.STATUS.read().DFLLRDY == 0) {}

        // Load Pad Calibration
        const pads = NVMCTRL.SW0.SW0_WORD_1.read();
        io.USB.DEVICE.PADCAL.write(.{
            .TRANSP = switch (pads.USB_TRANSP) {
                0...std.math.maxInt(u5) - 1 => |transp| transp,
                std.math.maxInt(u5) => 29,
            },
            .reserved6 = 0,
            .TRANSN = switch (pads.USB_TRANSN) {
                0...std.math.maxInt(u5) - 1 => |transn| transn,
                std.math.maxInt(u5) => 5,
            },
            .reserved12 = 0,
            .TRIM = switch (pads.USB_TRIM) {
                0...std.math.maxInt(u3) - 1 => |trim| trim,
                std.math.maxInt(u3) => 3,
            },
            .padding = 0,
        });

        // Enable 48MHz Generator
        io.GCLK.GENCTRL[GCLK.GEN.@"48MHz".ID].write(.{
            .SRC = .{ .value = .DFLL },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 0,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            GCLK.GEN.@"48MHz".SYNCBUSY_GENCTRL != 0)
        {}
        io.GCLK.PCHCTRL[GCLK.PCH.USB].write(.{
            .GEN = .{ .value = GCLK.GEN.@"48MHz".PCHCTRL_GEN },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });

        // Enable USB
        @memset(std.mem.sliceAsBytes(endpoint_table), 0x00);
        microzig.cpu.dmb();
        io.USB.DEVICE.DESCADD.write(.{ .DESCADD = @intFromPtr(endpoint_table) });
        io.USB.DEVICE.CTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 0,
            .RUNSTDBY = 0,
            .reserved7 = 0,
            .MODE = .{ .value = mode },
        });
        switch (mode) {
            .DEVICE => io.USB.DEVICE.CTRLB.modify(.{
                .SPDCONF = .{ .value = .FS },
                .DETACH = 0,
            }),
            .HOST => io.USB.HOST.CTRLB.modify(.{
                .SPDCONF = .{ .value = .NORMAL },
            }),
        }
        io.USB.DEVICE.CTRLA.write(.{
            .SWRST = 0,
            .ENABLE = 1,
            .RUNSTDBY = 0,
            .reserved7 = 0,
            .MODE = .{ .value = mode },
        });
        while (io.USB.DEVICE.SYNCBUSY.read().ENABLE != 0) {}

        // Reinitialize clocks
        io.GCLK.GENCTRL[GCLK.GEN.@"76.8KHz".ID].write(.{
            .SRC = .{ .value = .DFLL },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 1,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 625,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"1MHz".ID].write(.{
            .SRC = .{ .value = .DFLL },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = 48,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            (GCLK.GEN.@"76.8KHz".SYNCBUSY_GENCTRL |
            GCLK.GEN.@"1MHz".SYNCBUSY_GENCTRL) != 0)
        {}
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL0].write(.{
            .GEN = .{ .value = GCLK.GEN.@"76.8KHz".PCHCTRL_GEN },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.OSCCTRL.DPLL[0].DPLLCTRLB.write(.{
            .FILTER = .{ .value = .FILTER1 },
            .WUF = 0,
            .REFCLK = .{ .value = .GCLK },
            .LTIME = .{ .value = .DEFAULT },
            .LBYPASS = 0,
            .DCOFILTER = .{ .raw = 0 },
            .DCOEN = 0,
            .DIV = 0,
            .padding = 0,
        });
        const dpll0_factor = 12;
        const dpll0_frequency = 8_467_200 * dpll0_factor;
        comptime std.debug.assert(dpll0_frequency >= 96_000_000 and dpll0_frequency <= 200_000_000);
        const dpll0_ratio = @divExact(dpll0_frequency * 32, 76_800);
        io.OSCCTRL.DPLL[0].DPLLRATIO.write(.{
            .LDR = dpll0_ratio / 32 - 1,
            .reserved16 = 0,
            .LDRFRAC = dpll0_ratio % 32,
            .padding = 0,
        });
        while (io.OSCCTRL.DPLL[0].DPLLSYNCBUSY.read().DPLLRATIO != 0) {}
        io.OSCCTRL.DPLL[0].DPLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 1,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DPLL[0].DPLLSYNCBUSY.read().ENABLE != 0) {}
        io.GCLK.PCHCTRL[GCLK.PCH.OSCCTRL_FDPLL1].write(.{
            .GEN = .{ .value = GCLK.GEN.@"1MHz".PCHCTRL_GEN },
            .reserved6 = 0,
            .CHEN = 1,
            .WRTLOCK = 0,
            .padding = 0,
        });
        io.OSCCTRL.DPLL[1].DPLLCTRLB.write(.{
            .FILTER = .{ .value = .FILTER1 },
            .WUF = 0,
            .REFCLK = .{ .value = .GCLK },
            .LTIME = .{ .value = .DEFAULT },
            .LBYPASS = 0,
            .DCOFILTER = .{ .raw = 0 },
            .DCOEN = 0,
            .DIV = 0,
            .padding = 0,
        });
        const dpll1_factor = 1;
        const dpll1_frequency = 120_000_000 * dpll1_factor;
        comptime std.debug.assert(dpll1_frequency >= 96_000_000 and dpll1_frequency <= 200_000_000);
        const dpll1_ratio = @divExact(dpll1_frequency * 32, 1_000_000);
        io.OSCCTRL.DPLL[1].DPLLRATIO.write(.{
            .LDR = dpll1_ratio / 32 - 1,
            .reserved16 = 0,
            .LDRFRAC = dpll1_ratio % 32,
            .padding = 0,
        });
        while (io.OSCCTRL.DPLL[1].DPLLSYNCBUSY.read().DPLLRATIO != 0) {}
        io.OSCCTRL.DPLL[1].DPLLCTRLA.write(.{
            .reserved1 = 0,
            .ENABLE = 1,
            .reserved6 = 0,
            .RUNSTDBY = 0,
            .ONDEMAND = 0,
        });
        while (io.OSCCTRL.DPLL[1].DPLLSYNCBUSY.read().ENABLE != 0) {}
        while (io.OSCCTRL.DPLL[0].DPLLSTATUS.read().CLKRDY == 0) {}
        while (io.OSCCTRL.DPLL[1].DPLLSTATUS.read().CLKRDY == 0) {}
        io.GCLK.GENCTRL[GCLK.GEN.@"8.4672MHz".ID].write(.{
            .SRC = .{ .value = .DPLL0 },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = dpll0_factor,
        });
        io.GCLK.GENCTRL[GCLK.GEN.@"120MHz".ID].write(.{
            .SRC = .{ .value = .DPLL1 },
            .reserved8 = 0,
            .GENEN = 1,
            .IDC = 0,
            .OOV = 0,
            .OE = 0,
            .DIVSEL = .{ .value = .DIV1 },
            .RUNSTDBY = 0,
            .reserved16 = 0,
            .DIV = dpll1_factor,
        });
        while (io.GCLK.SYNCBUSY.read().GENCTRL.raw &
            (GCLK.GEN.@"8.4672MHz".SYNCBUSY_GENCTRL |
            GCLK.GEN.@"120MHz".SYNCBUSY_GENCTRL) != 0)
        {}
    }

    fn tick() void {
        // Check for End Of Reset flag
        if (io.USB.DEVICE.INTFLAG.read().EORST != 0) {
            // Clear the flag
            io.USB.DEVICE.INTFLAG.write(.{
                .SUSPEND = 0,
                .reserved2 = 0,
                .SOF = 0,
                .EORST = 1,
                .WAKEUP = 0,
                .EORSM = 0,
                .UPRSM = 0,
                .RAMACER = 0,
                .LPMNYET = 0,
                .LPMSUSP = 0,
                .padding = 0,
            });
            // Set Device address as 0
            io.USB.DEVICE.DADD.write(.{ .DADD = 0, .ADDEN = 1 });
            // Configure endpoint 0
            // Configure Endpoint 0 for Control IN and Control OUT
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPCFG.write(.{
                .EPTYPE0 = @intFromEnum(EpType.control),
                .reserved4 = 0,
                .EPTYPE1 = @intFromEnum(EpType.control),
                .padding = 0,
            });
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 0,
                .BK1RDY = 1,
            });
            // Configure control OUT Packet size to 64 bytes
            // Set Multipacket size to 8 for control OUT and byte count to 0
            endpoint_table[0].DEVICE.DEVICE_DESC_BANK[0].DEVICE.PCKSIZE.write(.{
                .BYTE_COUNT = 0,
                .MULTI_PACKET_SIZE = 8,
                .SIZE = @intFromEnum(pcksize.Size.@"64"),
                .AUTO_ZLP = 0,
            });
            // Configure control IN Packet size to 64 bytes
            endpoint_table[0].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
                .BYTE_COUNT = 0,
                .MULTI_PACKET_SIZE = 0,
                .SIZE = @intFromEnum(pcksize.Size.@"64"),
                .AUTO_ZLP = 1,
            });
            // Configure the data buffer address for control OUT
            endpoint_table[0].DEVICE.DEVICE_DESC_BANK[0].DEVICE.ADDR.write(.{
                .ADDR = @intFromPtr(&endpoint_buffer[0][0]),
            });
            // Configure the data buffer address for control IN
            endpoint_table[0].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
                .ADDR = @intFromPtr(&endpoint_buffer[0][1]),
            });
            microzig.cpu.dmb();
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });

            // Reset current configuration value to 0
            current_configuration = 0;
            cdc.current_connection = 0;
        }

        // Check for End Of SETUP flag
        if (io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.read().RXSTP != 0) setup: {
            // Clear the Received Setup flag
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPINTFLAG.write(.{
                .TRCPT0 = 0,
                .TRCPT1 = 0,
                .TRFAIL0 = 0,
                .TRFAIL1 = 0,
                .RXSTP = 1,
                .STALL0 = 0,
                .STALL1 = 0,
                .padding = 0,
            });

            // Clear the Bank 0 ready flag on Control OUT
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });

            microzig.cpu.dmb();
            switch (setup.bmRequestType.kind) {
                .standard => switch (setup.bmRequestType.recipient) {
                    .device => switch (setup.bmRequestType.dir) {
                        .out => switch (@as(Setup.standard.Request, @enumFromInt(setup.bRequest))) {
                            .SET_ADDRESS => if (setup.wIndex == 0 and setup.wLength == 0) {
                                if (std.math.cast(u7, setup.wValue)) |addr| {
                                    writeControl(&[0]u8{});
                                    io.USB.DEVICE.DADD.write(.{ .DADD = addr, .ADDEN = 1 });
                                    break :setup;
                                }
                            },
                            .SET_CONFIGURATION => {
                                if (std.math.cast(u8, setup.wValue)) |config| {
                                    writeControl(&[0]u8{});
                                    current_configuration = config;
                                    cdc.current_connection = 0;
                                    switch (config) {
                                        0 => {},
                                        1 => {
                                            io.USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPCFG.write(.{
                                                .EPTYPE0 = @intFromEnum(EpType.disabled),
                                                .reserved4 = 0,
                                                .EPTYPE1 = @intFromEnum(EpType.interrupt),
                                                .padding = 0,
                                            });
                                            endpoint_table[1].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
                                                .BYTE_COUNT = 0,
                                                .MULTI_PACKET_SIZE = 0,
                                                .SIZE = @intFromEnum(pcksize.Size.@"8"),
                                                .AUTO_ZLP = 1,
                                            });
                                            endpoint_table[1].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
                                                .ADDR = @intFromPtr(&endpoint_buffer[1][1]),
                                            });
                                            microzig.cpu.dmb();
                                            io.USB.DEVICE.DEVICE_ENDPOINT[1].DEVICE.EPSTATUSCLR.write(.{
                                                .DTGLOUT = 0,
                                                .DTGLIN = 0,
                                                .CURBK = 0,
                                                .reserved4 = 0,
                                                .STALLRQ0 = 0,
                                                .STALLRQ1 = 0,
                                                .BK0RDY = 0,
                                                .BK1RDY = 1,
                                            });

                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPCFG.write(.{
                                                .EPTYPE0 = @intFromEnum(EpType.bulk),
                                                .reserved4 = 0,
                                                .EPTYPE1 = @intFromEnum(EpType.bulk),
                                                .padding = 0,
                                            });
                                            endpoint_table[2].DEVICE.DEVICE_DESC_BANK[0].DEVICE.PCKSIZE.write(.{
                                                .BYTE_COUNT = 0,
                                                .MULTI_PACKET_SIZE = 0,
                                                .SIZE = @intFromEnum(pcksize.Size.@"64"),
                                                .AUTO_ZLP = 0,
                                            });
                                            endpoint_table[2].DEVICE.DEVICE_DESC_BANK[0].DEVICE.ADDR.write(.{
                                                .ADDR = @intFromPtr(&endpoint_buffer[2][0]),
                                            });
                                            microzig.cpu.dmb();
                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSSET.write(.{
                                                .DTGLOUT = 0,
                                                .DTGLIN = 0,
                                                .CURBK = 0,
                                                .reserved4 = 0,
                                                .STALLRQ0 = 0,
                                                .STALLRQ1 = 0,
                                                .BK0RDY = 1,
                                                .BK1RDY = 0,
                                            });
                                            endpoint_table[2].DEVICE.DEVICE_DESC_BANK[1].DEVICE.PCKSIZE.write(.{
                                                .BYTE_COUNT = 0,
                                                .MULTI_PACKET_SIZE = 0,
                                                .SIZE = @intFromEnum(pcksize.Size.@"64"),
                                                .AUTO_ZLP = 1,
                                            });
                                            endpoint_table[2].DEVICE.DEVICE_DESC_BANK[1].DEVICE.ADDR.write(.{
                                                .ADDR = @intFromPtr(&endpoint_buffer[2][1]),
                                            });
                                            microzig.cpu.dmb();
                                            io.USB.DEVICE.DEVICE_ENDPOINT[2].DEVICE.EPSTATUSCLR.write(.{
                                                .DTGLOUT = 0,
                                                .DTGLIN = 0,
                                                .CURBK = 0,
                                                .reserved4 = 0,
                                                .STALLRQ0 = 0,
                                                .STALLRQ1 = 0,
                                                .BK0RDY = 0,
                                                .BK1RDY = 1,
                                            });
                                        },
                                        else => {},
                                    }
                                    break :setup;
                                }
                            },
                            else => {},
                        },
                        .in => switch (@as(Setup.standard.Request, @enumFromInt(setup.bRequest))) {
                            .GET_DESCRIPTOR => {
                                switch (@as(Setup.standard.DescriptorType, @enumFromInt(setup.wValue >> 8))) {
                                    .DEVICE => if (@as(u8, @truncate(setup.wValue)) == 0 and setup.wIndex == 0) {
                                        writeControl(&[0x12]u8{
                                            0x12, @intFromEnum(Setup.standard.DescriptorType.DEVICE), //
                                            0x00, 0x02, //
                                            0xef, 0x02, 0x01, //
                                            64, //
                                            0x9a, 0x23, // Adafruit
                                            0x34, 0x00, //
                                            0x01, 0x42, // 42.01
                                            0x01, 0x02, 0x00, //
                                            0x01, //
                                        });
                                        break :setup;
                                    },
                                    .CONFIGURATION => if (setup.wIndex == 0) {
                                        switch (@as(u8, @truncate(setup.wValue))) {
                                            0 => {
                                                writeControl(&[0x003e]u8{
                                                    0x09, @intFromEnum(Setup.standard.DescriptorType.CONFIGURATION), //
                                                    0x3e, 0x00, //
                                                    0x02, 0x01, 0x00, //
                                                    0x80, 500 / 2, //
                                                    //
                                                    0x09, @intFromEnum(Setup.standard.DescriptorType.INTERFACE), //
                                                    0x00, 0x00, 0x01, //
                                                    0x02, 0x02, 0x00, //
                                                    0x00, //
                                                    //
                                                    0x05, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x00, //
                                                    0x10, 0x01, //
                                                    //
                                                    0x04, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x02, //
                                                    0x00, //
                                                    //
                                                    0x05, @intFromEnum(Setup.cdc.DescriptorType.CS_INTERFACE), 0x06, //
                                                    0x00, 0x01, //
                                                    //
                                                    0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                    0x81, 0x03, //
                                                    8, 0, std.math.maxInt(u8), //
                                                    //
                                                    0x09, @intFromEnum(Setup.standard.DescriptorType.INTERFACE), //
                                                    0x01, 0x00, 0x02, //
                                                    0x0a, 0x02, 0x00, //
                                                    0x00, //
                                                    //
                                                    0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                    0x02, 0x02, //
                                                    64, 0, 0, //
                                                    //
                                                    0x07, @intFromEnum(Setup.standard.DescriptorType.ENDPOINT), //
                                                    0x82, 0x02, //
                                                    64, 0, 0, //
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        }
                                    },
                                    .STRING => switch (@as(u8, @truncate(setup.wValue))) {
                                        0 => switch (setup.wIndex) {
                                            0 => {
                                                writeControl(&[4]u8{
                                                    4, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    0x09, 0x04, // English (United States)
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        },
                                        1 => switch (setup.wIndex) {
                                            0x0409 => { // English (United States)
                                                writeControl(&[38]u8{
                                                    38, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    'Z', 0x00, //
                                                    'i', 0x00, //
                                                    'g', 0x00, //
                                                    ' ', 0x00, //
                                                    'E', 0x00, //
                                                    'm', 0x00, //
                                                    'b', 0x00, //
                                                    'e', 0x00, //
                                                    'd', 0x00, //
                                                    'd', 0x00, //
                                                    'e', 0x00, //
                                                    'd', 0x00, //
                                                    ' ', 0x00, //
                                                    'G', 0x00, //
                                                    'r', 0x00, //
                                                    'o', 0x00, //
                                                    'u', 0x00, //
                                                    'p', 0x00, //
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        },
                                        2 => switch (setup.wIndex) {
                                            0x0409 => { // English (United States)
                                                writeControl(&[16]u8{
                                                    16, @intFromEnum(Setup.standard.DescriptorType.STRING), //
                                                    'B', 0x00, //
                                                    'a', 0x00, //
                                                    'd', 0x00, //
                                                    'g', 0x00, //
                                                    'e', 0x00, //
                                                    'L', 0x00, //
                                                    'C', 0x00, //
                                                });
                                                break :setup;
                                            },
                                            else => {},
                                        },
                                        else => {},
                                    },
                                    else => {},
                                }
                            },
                            else => {},
                        },
                    },
                    .interface => {},
                    .endpoint => {},
                    .other => {},
                    _ => {},
                },
                .class => switch (setup.bmRequestType.recipient) {
                    .device => {},
                    .interface => switch (setup.wIndex) {
                        0 => switch (setup.bmRequestType.dir) {
                            .out => switch (@as(Setup.cdc.Request, @enumFromInt(setup.bRequest))) {
                                .SET_LINE_CODING => if (setup.wValue == 0) {
                                    writeControl(&[0]u8{});
                                    break :setup;
                                },
                                .SET_CONTROL_LINE_STATE => if (setup.wLength == 0) {
                                    if (std.math.cast(u8, setup.wValue)) |conn| {
                                        cdc.current_connection = conn;
                                        writeControl(&[0]u8{});
                                        break :setup;
                                    }
                                },
                                else => {},
                            },
                            .in => {},
                        },
                        else => {},
                    },
                    .endpoint => {},
                    .other => {},
                    _ => {},
                },
                .vendor => {},
                _ => {},
            }
            // Stall control endpoint
            io.USB.DEVICE.DEVICE_ENDPOINT[0].DEVICE.EPSTATUSSET.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 1,
                .BK0RDY = 0,
                .BK1RDY = 0,
            });

            if (setup.bmRequestType.kind == .standard and setup.bmRequestType.dir == .in and
                setup.bRequest == @intFromEnum(Setup.standard.Request.GET_DESCRIPTOR) and
                setup.wValue >> 8 == @intFromEnum(Setup.standard.DescriptorType.DEVICE_QUALIFIER))
            {} else {
                std.log.scoped(.usb).err("Unhandled request: 0x{X:0<2}", .{setup.bRequest});
            }
        }
    }

    fn read(ep: u3, data: []u8) []u8 {
        const ep_buffer = &endpoint_buffer[ep][0];
        const ep_descs: *volatile [8]io_types.USB.USB_DESCRIPTOR = @ptrFromInt(io.USB.DEVICE.DESCADD.read().DESCADD);
        const ep_desc = &ep_descs[ep].DEVICE.DEVICE_DESC_BANK[0].DEVICE;
        const ep_ctrl = &io.USB.DEVICE.DEVICE_ENDPOINT[ep].DEVICE;

        if (ep_ctrl.EPSTATUS.read().BK0RDY != 0) {
            microzig.cpu.dmb();
            const len = ep_desc.PCKSIZE.read().BYTE_COUNT;
            @memcpy(data[0..len], ep_buffer[0..len]);
            ep_ctrl.EPSTATUSCLR.write(.{
                .DTGLOUT = 0,
                .DTGLIN = 0,
                .CURBK = 0,
                .reserved4 = 0,
                .STALLRQ0 = 0,
                .STALLRQ1 = 0,
                .BK0RDY = 1,
                .BK1RDY = 0,
            });
            return data[0..len];
        }
        return data[0..0];
    }

    fn writeControl(data: []const u8) void {
        write(0, data[0..@min(data.len, setup.wLength)]);
    }

    fn write(ep: u3, data: []const u8) void {
        const ep_buffer = &endpoint_buffer[ep][1];
        @memcpy(ep_buffer[0..data.len], data);
        microzig.cpu.dmb();

        const ep_descs: *volatile [8]io_types.USB.USB_DESCRIPTOR = @ptrFromInt(io.USB.DEVICE.DESCADD.read().DESCADD);
        // Set the buffer address for ep data
        const ep_desc = &ep_descs[ep].DEVICE.DEVICE_DESC_BANK[1].DEVICE;
        ep_desc.ADDR.write(.{ .ADDR = @intFromPtr(ep_buffer) });
        // Set the byte count as zero
        // Set the multi packet size as zero for multi-packet transfers where length > ep size
        ep_desc.PCKSIZE.modify(.{
            .BYTE_COUNT = @as(u14, @intCast(data.len)),
            .MULTI_PACKET_SIZE = 0,
        });
        // Clear the transfer complete flag
        const ep_ctrl = &io.USB.DEVICE.DEVICE_ENDPOINT[ep].DEVICE;
        ep_ctrl.EPINTFLAG.write(.{
            .TRCPT0 = 0,
            .TRCPT1 = 1,
            .TRFAIL0 = 0,
            .TRFAIL1 = 0,
            .RXSTP = 0,
            .STALL0 = 0,
            .STALL1 = 0,
            .padding = 0,
        });
        // Set the bank as ready
        ep_ctrl.EPSTATUSSET.write(.{
            .DTGLOUT = 0,
            .DTGLIN = 0,
            .CURBK = 0,
            .reserved4 = 0,
            .STALLRQ0 = 0,
            .STALLRQ1 = 0,
            .BK0RDY = 0,
            .BK1RDY = 1,
        });
        // Wait for transfer to complete
        while (ep_ctrl.EPINTFLAG.read().TRCPT1 == 0) {}
    }
};
