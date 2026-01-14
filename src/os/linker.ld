ENTRY(_start)

/* 
linker.ld
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
   * RP235X OS Memory Map (2MB Flash variant):
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
  .flash_start - microzig places the vector table here.
  Must be at the very start of flash (0x10000000) for ARM Cortex-M.
  microzig also places the bootmeta (IMAGE_DEF) in this section.
  */
  .flash_start :
  {
    . = ALIGN(4);
    KEEP(*(microzig_flash_start))
    KEEP(*(.vectors .vectors.*))
    /* RP2350 IMAGE_DEF block - bootmeta must follow vector table */
    . = ALIGN(4);
    __bootmeta_start__ = .;
    KEEP(*(.bootmeta))
    __bootmeta_end__ = .;
  } > flash

  /*
  .text - code and read-only data placed in flash.
  KEEP() prevents the linker from discarding sections even if unused
  (important for things like interrupt vectors and init/fini arrays).
  */
  .text :
  {
    . = ALIGN(4);

    /* All regular code sections */
    *(.text*)

    /* Read-only data (constants, strings) */
    *(.rodata*)
  } > flash

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

  /*
  .ram_vectors - RAM copy of the vector table if the system relocates
  the vector table to RAM (NOLOAD ensures it isn't stored in the output image).
  Placed at the start of kernel_ram so the CPU can use it after relocation.
  microzig uses this section name for RAM vector table support.
  */
  .ram_vectors (NOLOAD) :
  {
    KEEP(*(ram_vectors))
    KEEP(*(.ram_vector_table))
  } > kernel_ram

  /*
  .data - initialized (writable) data. This section is stored in flash
  (LOADADDR(.data)) but at runtime is copied to RAM (the AT> flash
  directive tells the linker the load origin).
  __data_start__ and __data_end__ bracket the runtime copy range.
  */
  __data_start_flash__ = LOADADDR(.data);
  microzig_data_load_start = LOADADDR(.data);
  .data :
  {
    . = ALIGN(4);
    __data_start__ = .;
    microzig_data_start = .;
    *(.time_critical*)    /* specially tagged data needing placement */
    *(.data)
    *(.data*)
    __data_end__ = .;
    microzig_data_end = .;
  } > kernel_ram AT> flash /* AT> flash tells the linker that this section is loaded from flash but runs in RAM */

  /*
  .bss zero-initialized data in RAM. NOLOAD means it's not stored in
  the output image; runtime must clear the region. (basically uninitialized global variables)
  __bss_start__/__bss_end__ mark the zeroing range.
  */
  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    __bss_start__ = .;
    microzig_bss_start = .;
    *(.bss)
    *(.bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
    microzig_bss_end = .;
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
  scratch_x / scratch_y are the fast scratch RAM banks 4KB each (SRAM4/SRAM5).
  These can hold time-critical data, DMA buffers, or separate stacks.
  Data can be initialized from flash (AT > flash) or left uninitialized (NOLOAD).
  */
  
  /* Scratch X (SRAM4) - 4KB for IRQ stack and fast buffers */
  .scratch_x (NOLOAD):
  {
    . = ALIGN(8); /* needs to be 8 for scratch sections */
    __scratch_x_start__ = .;
    *(.scratch_x*)
    . = ALIGN(8);
    . = . + 2K;  /* Reserve 2KB for IRQ/exception stack */
    __irq_stack_top__ = .;
    . = ORIGIN(scratch_x) + LENGTH(scratch_x);
    __scratch_x_end__ = .;
  } > scratch_x

  /* Scratch Y (SRAM5) - 4KB for main system stack */
  .scratch_y (NOLOAD):
  {
    . = ALIGN(8);
    __scratch_y_start__ = .;
    *(.scratch_y*)
    . = ALIGN(8);
    . = ORIGIN(scratch_y) + LENGTH(scratch_y);
    __scratch_y_end__ = .;
  } > scratch_y

  /*
  Stack symbols:
  - Main stack grows down from top of scratch_y
  - IRQ stack grows down from middle of scratch_x
  - Allows separate stacks for main thread vs interrupts/exceptions
  */
  __stack_top__ = ORIGIN(scratch_y) + LENGTH(scratch_y);
  __stack_limit__ = ORIGIN(scratch_y);
  __irq_stack_limit__ = ORIGIN(scratch_x) + 2K; /* IRQ stack is only 2KB, the rest of scratch_x is for fast buffers */

  /* kernel/process RAM region bounds for use by runtime code */
  __kernel_ram_start__ = ORIGIN(kernel_ram);
  __kernel_ram_end__ = ORIGIN(kernel_ram) + LENGTH(kernel_ram);
  __process_ram_start__ = ORIGIN(process_ram);
  __process_ram_end__ = ORIGIN(process_ram) + LENGTH(process_ram);
  
  /* scratch RAM bounds */
  __scratch_x_region_start__ = ORIGIN(scratch_x);
  __scratch_x_region_end__ = ORIGIN(scratch_x) + LENGTH(scratch_x);
  __scratch_y_region_start__ = ORIGIN(scratch_y);
  __scratch_y_region_end__ = ORIGIN(scratch_y) + LENGTH(scratch_y);

  /* Default stack pointer symbol used by startup code; points to top of main stack */
  PROVIDE(__stack = __stack_top__);

  /* All sanity checks */
  ASSERT(__stack_limit__ >= __heap_limit__, "ERROR: Heap would overflow into stack region")
  ASSERT(__data_start_flash__ <= 0x10080000, "ERROR: Kernel code exceeds 512KB flash allocation")
  ASSERT(__data_end__ <= __kernel_ram_end__, "ERROR: .data section too large for kernel_ram")
  ASSERT(__bss_end__ <= __kernel_ram_end__, "ERROR: .bss section overflows kernel_ram")
  ASSERT((__stack_top__ & 0x7) == 0, "ERROR: Stack pointer not 8-byte aligned")
  ASSERT((__irq_stack_top__ & 0x7) == 0, "ERROR: IRQ stack pointer not 8-byte aligned")
  ASSERT(__stack_limit__ != __irq_stack_limit__, "ERROR: Main and IRQ stacks overlap")
}
