/* Cart memory map for the SYCL Badge v2 (RP2354B), Core 1.
 *
 * Mirrors `src/cart/cart_xip.ld` in the badge tree, which is what the Zig carts
 * link against. The OS owns both numbers, so they are not ours to choose:
 *
 *   FLASH  the cart_xip region. `src/os/loader/loader.zig` erases it, programs
 *          the UF2 payload into it, and refuses any image whose target
 *          addresses fall outside it. The cart runs XIP, straight from here.
 *
 *   RAM    starts past everything the OS reserves at the bottom of process_ram:
 *          the IPC block (0x20020000), both framebuffers (through 0x2003401F),
 *          the trace buffer, the tone parameters and the dirty rect. The .ld
 *          rounds that boundary up to 0x20034100 and so do we.
 *
 * The initial stack pointer lands at ORIGIN(RAM) + LENGTH(RAM) = 0x20080000.
 * `executeCart` in `src/os/cart.zig` validates it before handing over Core 1:
 * it must be 8-byte aligned and inside 0x2002A100 ..= 0x20080000, so the top of
 * this region is exactly the highest value the OS will accept.
 */
MEMORY
{
  FLASH (rx)  : ORIGIN = 0x101C0000, LENGTH = 256K
  RAM   (rwx) : ORIGIN = 0x20034100, LENGTH = 0x4BF00
}
