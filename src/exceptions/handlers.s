.section .text.handlers

.global el_synchronous
.global el_irq

.include "gic/gic.inc"

.extern uart_puts
.extern uart_put_hex
.extern timer_set_interval
.extern tick_count
.global fault_count

// ------------------------------------------------------------------
// el_synchronous
//   Synchronous exception handler: dumps ELR, SPSR, ESR, EC and FAR, then
//   svc (EC 0x15): returns after the svc
//   data abort (EC 0x25): counts it then skips the faulting instruction, returns
//   anything else: halts
//
//   in    x19 ELR_EL1, x20 SPSR_EL1, x21 ESR_EL1, x22 FAR_EL1
//         (set by CALL_HANDLER)
//   out   eret
//   uses  x0-x3 (interrupted context is not saved)
// ------------------------------------------------------------------
el_synchronous:
    stp x29, x30, [sp, #-16]!

    adr x0, message_synchronous
    bl uart_puts

    // x19/x20/x21/x22 set by CALL_HANDLER
    adr x0, message_prefix_elr_el1
    bl uart_puts
    mov x0, x19
    bl uart_put_hex

    adr x0, message_prefix_spsr_el1
    bl uart_puts
    mov x0, x20
    bl uart_put_hex

    adr x0, message_prefix_esr_el1
    bl uart_puts
    mov x0, x21
    bl uart_put_hex

    adr x0, message_prefix_ec
    bl uart_puts
    lsr x0, x21, #26
    and x0, x0, #0x3F
    bl uart_put_hex

    adr x0, message_prefix_far_el1
    bl uart_puts
    mov x0, x22
    bl uart_put_hex

    adr x0, message_newline
    bl uart_puts

    lsr x1, x21, #26
    and x1, x1, #0x3F

    cmp x1, #0x15
    b.eq .Lsync_return

    cmp x1, #0x25
    b.ne .Lsync_halt

    adr x0, fault_count
    ldr x2, [x0]
    add x2, x2, #1
    str x2, [x0]

    add x19, x19, #4
    msr elr_el1, x19

.Lsync_return:
    ldp x29, x30, [sp], #16
    eret

.Lsync_halt:
    adr x0, message_unhandled_exception
    bl uart_puts
    b .

// ------------------------------------------------------------------
// el_irq
//   IRQ handler: acknowledges the interrupt, dispatches by ID
//   (30 = timer), signals end of interrupt, then returns with eret.
//
//   in    -
//   out   eret
//   uses  x0-x3, x19-x24 (interrupted context is not saved)
// ------------------------------------------------------------------
el_irq:
    stp x23, x30, [sp, #-16]!

    // moves the interrupt to active
    ldr x0, =GICC_BASE
    ldr w23, [x0, #GICC_IAR]

    cmp w23, #30
    b.eq timer_irq

    adr x0, message_irq
    bl uart_puts

    adr x0, message_prefix_iar
    bl uart_puts
    mov x0, x23
    bl uart_put_hex

    adr x0, message_newline
    bl uart_puts
    
    b eoi

timer_irq:
    bl timer_set_interval
    
    adr x0, tick_count
    ldr x24, [x0]
    add x24, x24, #1
    str x24, [x0]

    tst x24, #0x1FF
    b.ne eoi
    
    adr x0, message_prefix_tick
    bl uart_puts
    mov x0, x24
    bl uart_put_hex
    adr x0, message_newline
    bl uart_puts

eoi:
    // write back the exact raw value read from GICC_IAR
    ldr x0, =GICC_BASE
    str w23, [x0, #GICC_EOIR]

    ldp x23, x30, [sp], #16
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

message_prefix_ec:
    .asciz "\nEC:       0x"

message_prefix_far_el1:
    .asciz "\nFAR_EL1:  0x"

message_prefix_tick:
    .asciz "\nTick: 0x"

message_unhandled_exception:
    .asciz "\nUnhandled exception, halting"

.section .bss.handlers
.align 3
fault_count:
    .skip 8
