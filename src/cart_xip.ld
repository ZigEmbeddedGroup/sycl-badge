/*
 * Cart XIP Linker Script
 * 
 * This linker script is for building cart programs that run on Core 1
 * of the SYCL Badge OS. Carts are executed directly from flash (XIP)
 * at the cart_xip region.
 *
 * Memory Map:
 *   Cart Code (XIP):  0x101C0000 - 0x10200000 (256KB)
 *   Cart RAM:         0x20020000 - 0x20080000 (384KB process_ram)
 *
 * Usage:
 *   When building carts, use this linker script to ensure the cart
 *   is linked for the correct execution address.
 *
 * Requirements:
 *   - Cart binary must be <= 256KB
 *   - Entry point must be at vector table offset 4 (Reset_Handler)
 *   - Cart should use process_ram for all RAM needs
 */

ENTRY(_start)

MEMORY
{
    /* Cart code region - execute in place from flash */
    /* This must match the cart_xip region in the OS linker script */
    FLASH(rx) : ORIGIN = 0x101C0000, LENGTH = 256K

    /* Cart RAM region - for variables, stack, heap */
    /* This is the process_ram region managed by the OS */
    RAM(rwx) : ORIGIN = 0x20020000, LENGTH = 384K
}

SECTIONS
{
    /* Vector table MUST be at the VERY start of flash (offset 0) */
    /* ARM Cortex-M: [0] = initial SP, [1] = Reset_Handler */
    .isr_vector :
    {
        KEEP(*(.isr_vector))
    } > FLASH

    /* Code and read-only data */
    .text :
    {
        . = ALIGN(4);
        KEEP(*(.vectors))
        KEEP(*(.vector_table))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH

    /* ARM exception unwind tables */
    .ARM.extab : { *(.ARM.extab*) } > FLASH
    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx*)
        __exidx_end = .;
    } > FLASH

    /* Initialized data - stored in flash, copied to RAM at startup */
    .data :
    {
        . = ALIGN(4);
        __data_start__ = .;
        microzig_data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end__ = .;
        microzig_data_end = .;
    } > RAM AT> FLASH

    __data_load_start__ = LOADADDR(.data);
    microzig_data_load_start = LOADADDR(.data);

    /* Zero-initialized data */
    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        microzig_bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = .;
        microzig_bss_end = .;
    } > RAM

    /* Heap starts after BSS */
    .heap (NOLOAD) :
    {
        . = ALIGN(8);
        __heap_start__ = .;
        /* Heap grows upward toward stack */
    } > RAM

    /* Stack at end of RAM, grows downward */
    /* Reserve 16KB for stack */
    __stack_size__ = 16K;
    __stack_top__ = ORIGIN(RAM) + LENGTH(RAM);
    __stack_limit__ = __stack_top__ - __stack_size__;

    /* Sanity checks */
    ASSERT(__bss_end__ <= __stack_limit__, "ERROR: BSS overflows into stack region")
    ASSERT((__stack_top__ & 0x7) == 0, "ERROR: Stack not 8-byte aligned")
}

/* Export symbols for cart startup code */
__flash_start__ = ORIGIN(FLASH);
__flash_end__ = ORIGIN(FLASH) + LENGTH(FLASH);
__ram_start__ = ORIGIN(RAM);
__ram_end__ = ORIGIN(RAM) + LENGTH(RAM);
