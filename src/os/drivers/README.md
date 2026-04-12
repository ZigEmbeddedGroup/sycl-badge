# Driver Inventory

Hardware-facing drivers for the OS kernel are defined in this folder.

## Main Drivers

- [lcd.zig](lcd.zig): LCD controller integration and screen update helpers
- [gpio.zig](gpio.zig): buttons, LEDs, and GPIO operations
- [timer.zig](timer.zig): timing primitives
- [dma.zig](dma.zig): DMA channel control used by display and other flows
- [usb.zig](usb.zig): USB runtime integration
- [usb_msc.zig](usb_msc.zig): mass-storage support
- [rom.zig](rom.zig): RP ROM call wrappers and helpers

## Driver Ownership

Drivers are initialized and orchestrated by OS startup and kernel logic:

- [../system/init.zig](../system/init.zig)
- [../kernel.zig](../kernel.zig)
