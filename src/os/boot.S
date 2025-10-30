// boot code for rp2350 - arm cortex m33 - 32bit
.syntax unified // use unified syntax - standard for ARM
.cpu cortex-m33 // telling assembler to generate code for cortex-m33 processor - this determines available instructions
.thumb // thumb is 16/32bit compact instruction set - cortex-m only processes thumb 

// vector table - must be first in flash at 0x10000000 - tells cpu where to find exception/interrupt handlers

// this below places all code in vectors section - 'a' is for allocatable (takes space in output), 'x' is for executable 
.section .vectors, "ax" 
.align 2 // align next data to 2^2 = 4byte

.global __vectors // make __vectors symbol globally visible to linker 

__vectors:
    // word reserves one 32bit word and initializes with given val
    // entry 0 is init stack pointer - cpu loads this into stack pointer (sp) on reset
    .word __stack_top__ // 0 : init stack pointer (from linker)

    // entry 1 resets handler addr - cpu jumps here after loading sp 
    .word _start // reset handler - startup code

    // core arm cortex m exception handlers
    .word hang_handler      // 2: NMI - nonmaskable interrupt
    .word hang_handler      // 3: hardFault - unrecoverable err
    .word hang_handler      // 4: memManage - memory protection fault
    .word hang_handler      // 5: busFault - bus err during mem access 
    .word hang_handler      // 6: usageFault - undefined instructions, etc 
    .word hang_handler      // 7: secureFault 
    .word hang_handler      // 8: reserved used by arm spec
    .word hang_handler      // 9: reserved
    .word hang_handler      // 10: reserved
    .word hang_handler      // 11: SVCall - supervisor call for os services
    .word hang_handler      // 12: debugMonitor - debugger breakpoints
    .word hang_handler      // 13: reserved 
    .word hang_handler      // 14: pendSV - context switch for os scheduler
    .word hang_handler      // 15: sysTick - timer interrupt for os tick 

    // other entries - +16 - interrupt irqs
    .rept 52 // .rept x : repeat next line x times - using 52 since rp2350 has 52 IRQ peripherals, source: datasheet
    .word hang_handler // 
    .endr // .endr : end repeat block

// reset handler - entry point after power/reset - runs when cpu starts/resets

.section .text.boot // place executable code in .text.boot section 

.global _start // export _start symbol so linker can find entry point

.type _start, %function // telling assembler _start is a function - this for debugging

.thumb_func // mark _start as thumb code - corttex-m specific

// reset handler code
_start:
    // copy .data (contains initialized glob/static vars) from flash (LMA - ROM) to RAM (VMA) 
    ldr r0, =__data_start_flash__ // source in flash - load address of __data_start_flash__ into reg r0

    ldr r1, =__data_start__ // RAM destination (VMA) held in r1

    ldr r2, =__data_end__ // end address held in r2

    // calc data size: data_ram_end - data_ram_start, sub r1 from r2, keep in r2, update flag
    subs r2, r2, r1 

    // ble (less than equal to) target (if size <=0 skip copy) - if data section empty, skip copy loop
    ble .Ldata_done

// local label - starting w .L so linker doesn't export
.Ldata_loop:
    ldr r3, [r0], #4 // load word from addr in r0 into r3, then r0 = r0 + 4

    str r3, [r1], #4 // store word from r3 to addr in r1, then r1 = r1 + 4 , store to ram, increment r1

    subs r2, r2, #4 // decrement counter, sub 4 from r2, decrement byte counter by word size

    bgt .Ldata_loop // if counter > 0, keep looping 

// marking end of .data copy 
.Ldata_done:
 
    ldr r0, =__bss_start__ // load start addr of .bss (uninitialized global/static variables (is zeroed)) into r0
    
    ldr r1, =__bss_end__ // load end addr of .bss into r1
    
    movs r2, #0 // move immediate val 0 into r2, update flags, is the val written to zero mem

// .bss zeroing loop
.Lbss_loop:
    
    cmp r0, r1 // check if end of .bss reached, compare r0 and r1, set flags based on r0 - r1
    
    bge .Lbss_done // if r0 >= r1, done zeroing
    
    str r2, [r0], #4 // store r2 (zero) to addr in r0,  then r0 = r0 + 4
    
    b .Lbss_loop // uncond branch, always jump back to loop start
   
    
// end of .bss zeroing
.Lbss_done:

    // call kernel main, jump to function and save return address in LR, 
    bl kernel_main

    // if kernel returns, hang forever - safety since kernel main should never return

// exception handler that just loops forever
hang_handler:

    wfe // wait for event (low power), sleep until interrupt
    
    b hang_handler // branch unconditionally back to hang_handler - inf loop