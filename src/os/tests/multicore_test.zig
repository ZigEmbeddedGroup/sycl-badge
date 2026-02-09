/// Multicore functionality test
/// Tests Core 0 <-> Core 1 communication via FIFO and shared memory
const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;
const gpio = hal.gpio;
const board = microzig.board;
const timer = @import("../drivers/timer.zig");
const usb = @import("../drivers/usb.zig");
const multicore = @import("../system/multicore.zig");
const mailbox = @import("../ipc/mailbox.zig");
const shared_mem = @import("../ipc/shared_mem.zig");

const led = board.led_pin;

// Test commands
const TEST_FIFO: u32 = 0x7E57_F1F0;
const TEST_SHMEM: u32 = 0x7E57_5E3E;
const TEST_SPINLOCK: u32 = 0x7E57_5911;
const DONE_SHMEM: u32 = 0xD09E_5E3E;
const FAIL_SHMEM: u32 = 0xFA11_5E3E;
const DONE_SPINLOCK: u32 = 0xD09E_5911;

// Test state
var test_passed: bool = false;
var core1_ready: bool = false;

// Shared memory test
var shared_region_id: shared_mem.RegionId = 0;

/// Core 1 entry point for testing
fn core1_test_main() void {
    // Signal we're alive
    mailbox.send(0xC0DE_0001);

    // Process test commands in a loop
    while (true) {
        // Wait for test command
        const cmd = mailbox.receive();

        if (cmd == TEST_FIFO) {
            // FIFO echo test - receive and send back
            const value = mailbox.receive();
            mailbox.send(value + 1);
        } else if (cmd == TEST_SHMEM) {
            // Shared memory test
            // Wait for shared memory ID
            const region_id: shared_mem.RegionId = @truncate(mailbox.receive());

            if (shared_mem.attach(region_id)) |mem| {
                // Read value from shared memory, increment it, write it back
                const value = mem[0];
                mem[0] = value + 1;

                // Signal completion
                mailbox.send(DONE_SHMEM);
            } else {
                mailbox.send(FAIL_SHMEM);
            }
        } else if (cmd == TEST_SPINLOCK) {
            // Spinlock test
            const spinlock = hal.multicore.Spinlock.init(10);

            // Try to acquire spinlock
            spinlock.lock();
            timer.sleep_ms(100); // Hold it briefly
            spinlock.unlock();

            mailbox.send(DONE_SPINLOCK);
        } else if (cmd == 0xC0DE_DEAD) {
            // Test complete signal from Core 0
            break;
        }
    }

    // Keep Core 1 alive
    while (true) {
        timer.sleep_ms(100);
    }
}

/// Test FIFO communication
fn testFIFO() bool {
    _ = usb.printf("Testing FIFO communication...\r\n", .{});

    // Send test command
    mailbox.send(TEST_FIFO);

    // Send test value
    const test_value: u32 = 0x1234_5678;
    mailbox.send(test_value);

    // Wait for response with timeout
    const start = timer.micros();
    while (timer.micros() - start < 1_000_000) { // 1 second timeout
        usb.poll();
        if (mailbox.tryReceive()) |response| {
            if (response == test_value + 1) {
                _ = usb.printf("FIFO test PASSED\r\n", .{});
                return true;
            } else {
                _ = usb.printf("FIFO test FAILED: wrong value\r\n", .{});
                return false;
            }
        }
    }

    _ = usb.printf("FIFO test FAILED: timeout\r\n", .{});
    return false;
}

/// Test shared memory
fn testSharedMemory() bool {
    _ = usb.printf("Testing shared memory...\r\n", .{});

    // Create shared memory region
    const result = shared_mem.create(256) orelse {
        _ = usb.printf("Shared memory test FAILED: couldn't create region\r\n", .{});
        return false;
    };

    // Write initial value
    result.mem[0] = 42;

    // Tell Core 1 to access it
    mailbox.send(TEST_SHMEM);
    mailbox.send(@as(u32, result.id));

    // Wait for completion
    const start = timer.micros();
    while (timer.micros() - start < 1_000_000) { // 1 second timeout
        usb.poll();
        if (mailbox.tryReceive()) |response| {
            if (response == DONE_SHMEM) {
                // Check if Core 1 modified the value
                if (result.mem[0] == 43) {
                    _ = usb.printf("Shared memory test PASSED\r\n", .{});
                    return true;
                } else {
                    _ = usb.printf("Shared memory test FAILED: value not modified\r\n", .{});
                    return false;
                }
            } else if (response == FAIL_SHMEM) {
                _ = usb.printf("Shared memory test FAILED: Core 1 couldn't attach\r\n", .{});
                return false;
            }
        }
    }

    _ = usb.printf("Shared memory test FAILED: timeout\r\n", .{});
    return false;
}

/// Test spinlock synchronization
fn testSpinlock() bool {
    _ = usb.printf("Testing spinlock...\r\n", .{});

    const spinlock = hal.multicore.Spinlock.init(10);

    // Acquire lock on Core 0
    spinlock.lock();

    // Tell Core 1 to try to acquire it
    mailbox.send(TEST_SPINLOCK);

    // Hold lock for a bit
    timer.sleep_ms(200);

    // Release lock
    spinlock.unlock();

    // Wait for Core 1 to signal completion
    const start = timer.micros();
    while (timer.micros() - start < 2_000_000) { // 2 second timeout
        usb.poll();
        if (mailbox.tryReceive()) |response| {
            if (response == DONE_SPINLOCK) {
                _ = usb.printf("Spinlock test PASSED\r\n", .{});
                return true;
            }
        }
    }

    _ = usb.printf("Spinlock test FAILED: timeout\r\n", .{});
    return false;
}

/// Run all multicore tests
pub fn runTests() void {
    _ = usb.printf("\r\n=== Multicore Functionality Test ===\r\n\r\n", .{});

    // Initialize LED
    led.set_function(.sio);
    led.set_direction(.out);
    led.put(0);

    // Initialize IPC
    shared_mem.init();
    mailbox.clear();

    // Launch Core 1
    _ = usb.printf("Launching Core 1...\r\n", .{});
    multicore.launch_core1(core1_test_main);

    // Wait for Core 1 ready signal
    _ = usb.printf("Waiting for Core 1...\r\n", .{});
    const start = timer.micros();
    var core1_alive = false;
    while (timer.micros() - start < 2_000_000) { // 2 second timeout
        usb.poll();
        if (mailbox.tryReceive()) |msg| {
            if (msg == 0xC0DE_0001) {
                core1_alive = true;
                break;
            }
        }
    }

    if (!core1_alive) {
        _ = usb.printf("ERROR: Core 1 failed to start!\r\n", .{});
        return;
    }

    _ = usb.printf("Core 1 started successfully\r\n\r\n", .{});

    // Run tests
    var all_passed = true;

    all_passed = testFIFO() and all_passed;
    timer.sleep_ms(100);

    all_passed = testSharedMemory() and all_passed;
    timer.sleep_ms(100);

    all_passed = testSpinlock() and all_passed;
    timer.sleep_ms(100);

    // Signal Core 1 to stop
    mailbox.send(0xC0DE_DEAD);

    // Print results
    _ = usb.printf("\r\n=== Test Results ===\r\n", .{});
    if (all_passed) {
        _ = usb.printf("ALL TESTS PASSED!\r\n", .{});
        // Solid LED on success
        led.put(1);
    } else {
        _ = usb.printf("SOME TESTS FAILED!\r\n", .{});
        // LED will blink via main loop if needed
    }
}
