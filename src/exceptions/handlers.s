.section .text.handlers

.global el_synchronous
.global el_irq

.include "gic/gic.inc"

.extern uart_puts
.extern uart_put_hex

el_synchronous:
    stp x29, x30, [sp, #-16]!

    ldr x0, =message_synchronous
    bl uart_puts

    // x19/x20/x21 set by CALL_HANDLER
    ldr x0, =message_prefix_elr_el1
    bl uart_puts
    mov x0, x19
    bl uart_put_hex

    ldr x0, =message_prefix_spsr_el1
    bl uart_puts
    mov x0, x20
    bl uart_put_hex

    ldr x0, =message_prefix_esr_el1
    bl uart_puts
    mov x0, x21
    bl uart_put_hex

    ldr x0, =message_newline
    bl uart_puts

    // eret returns right after svc
    ldp x29, x30, [sp], #16
    eret

el_irq:
    stp x22, x30, [sp, #-16]!

    // moves the interrupt to active
    ldr x0, =GICC_BASE
    ldr w22, [x0, #GICC_IAR]

    ldr x0, =message_irq
    bl uart_puts

    ldr x0, =message_prefix_iar
    bl uart_puts
    mov x0, x22
    bl uart_put_hex

    ldr x0, =message_newline
    bl uart_puts

    // write back the exact raw value read from GICC_IAR
    ldr x0, =GICC_BASE
    str w22, [x0, #GICC_EOIR]

    ldp x22, x30, [sp], #16
    eret

.section .rodata.handlers

message_newline:
    .asciz "\n"

message_synchronous:
    .asciz "\nSynchronous exception caught!"

message_prefix_elr_el1:
    .asciz "\nELR_EL1:  0x"

message_prefix_spsr_el1:
    .asciz "\nSPSR_EL1: 0x"

message_prefix_esr_el1:
    .asciz "\nESR_EL1:  0x"


message_irq:
    .asciz "\nIRQ exception caught!"

message_prefix_iar:
    .asciz "\nGICC_IAR: 0x"
