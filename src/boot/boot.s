.section .text.boot

.global _start
.extern _exception_vector_table
.extern gic_init
.extern uart_puts
.extern timer_init

.include "gic/gic.inc"

_start:
    ldr x0, =_stack_top
    mov sp, x0

    ldr x0, =message
    bl uart_puts

    // VBAR_EL1 must be set before any exception can occur
    ldr x0, =_exception_vector_table
    msr vbar_el1, x0

    // Must run after VBAR_EL1 and before IRQ unmask
    bl gic_init

    bl timer_init

    msr daifclr, #2

    // Provoke Synchronous exception
    svc #0

    // Provoke IRQ exception
    ldr x0, =GICD_BASE
    mov w1, #0x2000000
    str w1, [x0, #GICD_SGIR]

    b .

.section .rodata.boot

message:
    .asciz "Hello, AArch64!\n"
