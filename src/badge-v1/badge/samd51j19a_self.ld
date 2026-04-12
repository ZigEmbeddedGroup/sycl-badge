/**
 * \file
 *
 * \brief Linker script for running in internal FLASH on the SAMD51J19A
 *
 * Copyright (c) 2017 Microchip Technology Inc.
 *
 * \asf_license_start
 *
 * \page License
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the Licence at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * \asf_license_stop
 *
 */


/*
OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)
*/

ENTRY(microzig_main)

/* Memory Spaces Definitions */
MEMORY
{
  rom      (rx)  : ORIGIN = 0x00004000, LENGTH = 0x00080000 - 0x4000
  ram      (rwx) : ORIGIN = 0x20000000, LENGTH = 0x00030000
  bkupram  (rwx) : ORIGIN = 0x47000000, LENGTH = 0x00002000
  qspi     (rwx) : ORIGIN = 0x04000000, LENGTH = 0x01000000
}

PHDRS
{
  ph_rom   PT_LOAD FLAGS(0x5);
  ph_ram   PT_LOAD FLAGS(0x7);
  ph_bkupram   PT_LOAD FLAGS(0x7);
  ph_qspi   PT_LOAD FLAGS(0x7);
}

/* Section Definitions */
SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        KEEP(*(microzig_flash_start))
        KEEP(*(.vectors .vectors.*))
        *(.text .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
        *(.rodata .rodata* .gnu.linkonce.r.*)
        *(.ARM.extab* .gnu.linkonce.armextab.*)

        /* Support C constructors, and C destructors in both user code
           and the C library. This also provides support for C++ code. */
        . = ALIGN(4);
        KEEP(*(.init))
        . = ALIGN(4);
        __preinit_array_start = .;
        KEEP (*(.preinit_array))
        __preinit_array_end = .;

        . = ALIGN(4);
        __init_array_start = .;
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = .;

        . = ALIGN(4);
        KEEP (*crtbegin.o(.ctors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*crtend.o(.ctors))

        . = ALIGN(4);
        KEEP(*(.fini))

        . = ALIGN(4);
        __fini_array_start = .;
        KEEP (*(.fini_array))
        KEEP (*(SORT(.fini_array.*)))
        __fini_array_end = .;

        KEEP (*crtbegin.o(.dtors))
        KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
        KEEP (*(SORT(.dtors.*)))
        KEEP (*crtend.o(.dtors))

        . = ALIGN(4);
    } > rom : ph_rom

    /* .ARM.exidx is sorted, so has to go in its own output section.  */
    PROVIDE_HIDDEN (__exidx_start = .);
    .ARM.exidx :
    {
      *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > rom : ph_rom
    PROVIDE_HIDDEN (__exidx_end = .);

        microzig_data_start = .;
        microzig_data_end = .;

    . = ALIGN(4);
    _etext = .;

    .relocate : AT (_etext)
    {
        . = ALIGN(4);
        microzig_data_start = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        . = ALIGN(4);
        microzig_data_end = .;
    } > ram : ph_ram

    .bkupram (NOLOAD):
    {
        . = ALIGN(8);
        _sbkupram = .;
        *(.bkupram .bkupram.*);
        . = ALIGN(8);
        _ebkupram = .;
    } > bkupram : ph_bkupram

    .qspi (NOLOAD):
    {
        . = ALIGN(8);
        _sqspi = .;
        *(.qspi .qspi.*);
        . = ALIGN(8);
        _eqspi = .;
    } > qspi : ph_qspi

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        microzig_bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        microzig_bss_end = .;
    } > ram : ph_ram

    . = ALIGN(4);
    _end = . ;

  microzig_data_load_start = LOADADDR(.relocate);
}
