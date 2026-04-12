# Inter-Core IPC

IPC between Core 0 and Core 1 is implemented in this folder.

## Files

- [mailbox.zig](mailbox.zig): message encoding and mailbox send/receive helpers
- [shared_mem.zig](shared_mem.zig): shared memory regions used by cross-core flows
- [spinlock.zig](spinlock.zig): synchronization primitives

## High-Level Flow

- Core 0 sends control messages (start, stop, cart execute)
- Core 1 receives messages and performs cart actions
- Shared memory carries frame input/output data and related state

See runtime consumers:

- [../kernel.zig](../kernel.zig)
- [../cart.zig](../cart.zig)
