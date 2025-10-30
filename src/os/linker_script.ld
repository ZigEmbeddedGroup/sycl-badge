/*
* exported symbols:
* __preinit_array_start
* __preinit_array_end
* __init_array_start
* __init_array_end
* __fini_array_start
* __fini_array_end
* __exidx_start
* __exidx_end
*/

/* 
linker_script.ld
Based on upstream examples (CMSIS & pico-sdk).
This file tells the linker where to place sections of the final binary
in the target memory map and defines symbols used by startup/runtime.
*/


/* 
MEMORY
Defines named memory regions that the linker can allocate sections into.
Each region has an origin (start address) and a length.
The attributes in parentheses specify access/permission flags:
  r  = readable, w = writable, x = executable, !w = not writable (read-only flash/rom)
*/
MEMORY
{
  /* 
   * RP2350 OS Memory Map (2MB Flash variant):
   * - Flash: XIP mapped at 0x10000000 (2MB onboard)
   * - SRAM: 520KB total at 0x20000000
   *   - SRAM0-3: 512KB (0x20000000 - 0x20080000)
   *   - SRAM4-5: 8KB scratch (0x20080000 - 0x20082000)
   * 
   * OS Layout:
   * - OS kernel code/data in flash (512KB - 1/4 of 2MB)
   * - Application storage in romfs (1.5MB - 3/4 of 2MB for programs/data)
   * - Kernel RAM: 128KB for OS kernel data/heap
   * - Process RAM: 384KB for user applications (multiple programs)
   * - Scratch RAM: 8KB for stacks and fast buffers
   */
  
  /* OS kernel code and read-only data - 512KB (1/4 of 2MB) */
  flash(rx!w)       : ORIGIN = 0x10000000, LENGTH = 512K

  /* Application storage filesystem - 1.5MB (3/4 of 2MB) for loadable programs */
  romfs(rx!w)       : ORIGIN = 0x10080000, LENGTH = 1536K

  /* OS kernel RAM - 128KB for kernel data structures, heap, etc */
  kernel_ram(rxw)   : ORIGIN = 0x20000000, LENGTH = 128K

  /* User process RAM - 384KB for running applications */
  process_ram(rxw)  : ORIGIN = 0x20020000, LENGTH = 384K

  /* Scratch SRAM for stacks and DMA buffers - 8KB */
  scratch_x(rxw)    : ORIGIN = 0x20080000, LENGTH = 4K
  scratch_y(rxw)    : ORIGIN = 0x20081000, LENGTH = 4K
}

/*
SECTIONS
Map input object file sections to output sections and to memory regions.
This also defines and exports many useful linker symbols used by startup
code and runtime (e.g. __data_start__, __bss_start__, __end__, stack limits).
*/
SECTIONS
{
    /*
  .text - code and read-only data placed in flash.
  KEEP() prevents the linker from discarding sections even if unused
  (important for things like interrupt vectors and init/fini arrays).
  */
  .text :
  {
    . = ALIGN(4);

    /* Vector table (startup vectors) must be kept at its explicit location */
    KEEP(*(.vectors))

    /* Boot metadata region */
    __bootmeta_start__ = .;
    KEEP(*(.bootmeta))
    __bootmeta_end__ = .;

    /* All regular code sections */
    *(.text*)
    KEEP(*(.init))    /* legacy .init code */
    KEEP(*(.fini))    /* legacy .init code */

    /* Read-only data and exception frame info */
    *(.rodata*)
    KEEP(*(.eh_frame*))

    /*
    Constructors/destructors arrays handling.
    The crtbegin/crtend handling keeps C/C++ static ctor/dtor lists
    in a deterministic order so runtime can iterate them.
    */
    *crtbegin.o(.ctors)
    *crtbegin?.o(.ctors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
    *(SORT(.ctors.*))
    *(.ctors)
    *crtbegin.o(.dtors)
    *crtbegin?.o(.dtors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
    *(SORT(.dtors.*))
    *(.dtors)

    /* preinit/init/fini arrays (static init/fini) */
    . = ALIGN(4);
    PROVIDE_HIDDEN(__preinit_array_start = .);
    KEEP(*(SORT(.preinit_array.*)))
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN(__preinit_array_end = .);

    . = ALIGN(4);
    PROVIDE_HIDDEN(__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN(__init_array_end = .);

    . = ALIGN(4);
    PROVIDE_HIDDEN(__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN(__fini_array_end = .);
  } > flash

  /* ARM exception handling tables - in read-only memory */
  .ARM.extab :
  {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } > flash

  /* Exception index (unwinding) table */
  __exidx_start = .;
  .ARM.exidx :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } > flash
  __exidx_end = .;

  /*
  .romfs - a dedicated read-only region for a filesystem or large blobs.
  Symbols __romfs_start__/__romfs_end__ let code locate the embedded data.
  */
   .romfs :
  {
    __romfs_start__ = .;
    KEEP(*(.romfs))
    __romfs_end__ = .;
  } > romfs
  /* keep this at beginning of ram or align to arm alignment requirement for
   cortex-m0plus */
  /*
  .ram_vector_table - a RAM copy of the vector table if the system relocates
  the vector table to RAM (NOLOAD ensures it isn't stored in the output image).
  Placed at the start of kernel_ram so the CPU can use it after relocation.
  */
  .ram_vector_table (NOLOAD) :
  {
    *(.ram_vector_table)
  } > kernel_ram

  /*
  .data - initialized (writable) data. This section is stored in flash
  (LOADADDR(.data)) but at runtime is copied to RAM (the AT> flash
  directive tells the linker the load origin).
  __data_start__ and __data_end__ bracket the runtime copy range.
  */

  /* line 187 "> kernel_ram" : VMA - runtime address in ram - writable
     line 187 "AT> flash" : stored in flash (ROM - read only) in the binary image 
     __data_start__ and __data_end__ are RAM destinations


     essentially what this does is that:
        at boot, copies from __data_start_flash__ (LMA in flash/ROM) to __data_start__ (VMA in RAM)
        for __data_end__ - __data_start__ bytes
  */

  __data_start_flash__ = LOADADDR(.data);
  .data :
  {
    . = ALIGN(4);
    __data_start__ = .;
    *(vtable)             /* place any vtable fragments */
    *(.time_critical*)    /* specially tagged data needing placement */
    *(.time_critical)
    *(.data)
    *(.data*)
    __data_end__ = .;
  } > kernel_ram AT> flash /* "> kernel_ram" : VMA - runtime address in ram - writable */


  /*
  .bss - zero-initialized data in RAM. NOLOAD means it's not stored in
  the output image; runtime must clear the region.
  __bss_start__/__bss_end__ mark the zeroing range.
  */
  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start__ = .;
    *(.bss)
    *(.bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
  } > kernel_ram

  /*
  .heap - optional heap region placed after bss.
  __end__ / end are common linker symbols used by C libs to find the heap start.
  KEEP(*(.heap*)) allows explicit heap sub-sections to be preserved.
  */
  .heap (NOLOAD):
  {
    __end__ = .;
    end = __end__;
    KEEP(*(.heap*))
  } > kernel_ram

  /* compile-time symbol describing the maximum heap limit (end of kernel_ram) */
  __heap_limit__ = ORIGIN(kernel_ram) + LENGTH(kernel_ram);

  /*
  scratch_x / scratch_y - small scratch areas allocated in their own
  RAM regions but whose initial contents are stored in flash (AT > flash).
  The linker also exposes source load addresses for copying at boot.
  */
  .scratch_x :
  {
    __scratch_x_start__ = .;
    *(.scratch_x.*)
    . = ALIGN(4);
    __scratch_x_end__ = .;
  } > scratch_x AT > flash
  __scratch_x_source__ = LOADADDR(.scratch_x);

  .scratch_y :
  {
    __scratch_y_start__ = .;
    *(.scratch_y.*)
    . = ALIGN(4);
    __scratch_y_end__ = .;
  } > scratch_y AT > flash
  __scratch_y_source__ = LOADADDR(.scratch_y);

  /*
  Dummy sections used to reserve stack storage in the scratch regions.
  NOLOAD ensures they do not occupy space in the output image.
  */
  .stack1_dummy (NOLOAD):
  {
    *(.stack1*)
  } > scratch_x

  .stack_dummy (NOLOAD):
  {
    KEEP(*(.stack*))
  } > scratch_y

  /*
  Compute stack-related symbols:
  - __stack_limit__: top of process RAM (lowest permissible stack address)
  - __stack_top__/__stack_bottom__: top/bottom of main stack in scratch_y
  - __stack1_top__/__stack1_bottom__: for alternate/special stack in scratch_x
  These are used by startup code and by runtime checks.
  */
  __stack_limit__ = ORIGIN(process_ram) + LENGTH(process_ram);
  __stack1_top__ = ORIGIN(scratch_x) + LENGTH(scratch_x);
  __stack1_bottom__ = ORIGIN(scratch_x);
  __stack_top__ = ORIGIN(scratch_y) + LENGTH(scratch_y);
  __stack_bottom__ = __stack_limit__;

  /* Expose kernel/process RAM region bounds for use by runtime code */
  __kernel_ram_start__ = ORIGIN(kernel_ram);
  __kernel_ram_end__ = ORIGIN(kernel_ram) + LENGTH(kernel_ram);
  __process_ram_start__ = ORIGIN(process_ram);
  __process_ram_end__ = ORIGIN(process_ram) + LENGTH(process_ram);

  /* Default stack pointer symbol used by startup code; points to top of stack */
  PROVIDE(__stack = __stack_top__);

  /* Sanity check at link time: ensures heap fits inside kernel_ram */
  ASSERT(__stack_limit__ >= __heap_limit__, "region RAM overflowed")
}
