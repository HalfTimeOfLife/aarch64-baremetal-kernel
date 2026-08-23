.section .text.uart

.global uart_putc
.global uart_puts

.equ UART_BASE, 0x09000000
.equ UART_FR,   0x18
.equ UART_DR,   0x00
.equ UART_TXFF, 0x20


uart_putc:
    ldr x1, =UART_BASE

wait:
    ldr w2, [x1, #UART_FR]
    tst w2, #UART_TXFF
    b.ne wait

    str w0, [x1, #UART_DR]

    ret

uart_puts:
    stp x19, x30, [sp, #-16]!
    mov x19, x0

loop:
    ldrb w0, [x19], #1
    cbz w0, done
    bl uart_putc
    b loop

done:
    ldp x19, x30, [sp], #16
    ret
