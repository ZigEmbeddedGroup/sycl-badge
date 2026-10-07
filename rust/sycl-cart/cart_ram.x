/* Linker script for a SYCL Badge v2 RAM cart, running on Core 1.
 *
 * Mirrors `src/cart/cart_ram.ld` in the badge tree, which is what the Zig carts
 * link against. The OS owns the numbers, so they are not ours to choose:
 *
 *   RAM  starts past everything the OS reserves at the bottom of process_ram:
 *        the IPC block at 0x20020000 (controls, both framebuffers, the trace
 *        buffer, the tone parameters, the dirty rect and the tracy ring), which
 *        `CartIPCData` in `src/os/cart/os_abi.zig` asserts fits in 0x15100 bytes.
 *        cart_ram.ld starts cart memory at 0x20035100 and so do we. The end is
 *        the end of process_ram.
 *
 * The loader (`src/os/loader/loader.zig`) copies every UF2 block whose target
 * address falls in this window straight into RAM, finds the cart descriptor
 * below by scanning for its magic, zeroes `[__bss_start__, __bss_end__)`, and
 * hands over to `executeCart` in `src/os/cart.zig`, which sets MSP to the top
 * of process_ram (0x20080000) and jumps to the descriptor's entry point.
 *
 * Nothing copies `.data`: it is linked at its final address and arrives there
 * inside the UF2. There is no startup code between the loader and `_start`.
 */
MEMORY
{
  RAM (rwx) : ORIGIN = 0x20035100, LENGTH = 0x4AF00
}

ENTRY(_start)

/* The stack grows down from the top of RAM. cart_ram.ld reserves this much of
 * it and refuses to link a cart whose .bss reaches into the reserve; the OS
 * itself never checks, so the linker is the only guard. */
__stack_size__ = 32K;
__stack_top__ = ORIGIN(RAM) + LENGTH(RAM);
__stack_limit__ = __stack_top__ - __stack_size__;

SECTIONS
{
  /* Our own vector table, so a HardFault reaches the handler `cart!` emits
   * rather than the OS's. `platform::init` points VTOR at it, and VTOR wants
   * 128-byte alignment: ORIGIN(RAM) is 256-aligned, and it goes first. */
  .vector_table ORIGIN(RAM) :
  {
    KEEP(*(.vector_table))
  } > RAM

  /* Cart descriptor, `CartDescriptorTable_v1` in `src/os/cart/os_abi.zig`:
   *
   *   magic, version, bss_start, bss_end, entry_point
   *
   * The loader scans every RAM block for the magic and takes the first hit, so
   * this sits right behind the vector table, in the first UF2 block. The bss
   * bounds are linker facts, so the linker writes the table. Bit 0 of the entry
   * marks it as Thumb code, which the loader insists on. */
  .cart_descriptor :
  {
    . = ALIGN(4);
    LONG(0x54C1CA41)
    LONG(0x54C12601)
    LONG(__bss_start__)
    LONG(__bss_end__)
    LONG(_start | 1)
  } > RAM

  .text :
  {
    . = ALIGN(4);
    *(.text .text.*)
    . = ALIGN(4);
  } > RAM

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata .rodata.*)
    . = ALIGN(4);
  } > RAM

  /* Linked in place: VMA == LMA, so there is no startup copy to get wrong. */
  .data :
  {
    . = ALIGN(4);
    *(.data .data.*)
    . = ALIGN(4);
  } > RAM

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start__ = .;
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
  } > RAM

  /* Unwind tables. Every profile sets panic = "abort", so nothing walks them. */
  /DISCARD/ :
  {
    *(.ARM.exidx .ARM.exidx.*)
    *(.ARM.extab .ARM.extab.*)
  }

  ASSERT(__bss_end__ <= __stack_limit__, "ERROR: .bss reaches into the 32K stack reserve")
  ASSERT((__stack_top__ & 0x7) == 0, "ERROR: stack top is not 8-byte aligned")
}
