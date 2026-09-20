.section .text.uart

.global uart_putc
.global uart_puts
.global uart_put_hex

.equ UART_BASE, 0x09000000
.equ UART_FR,   0x18
.equ UART_DR,   0x00
.equ UART_TXFF, 0x20

// Writes one character in w0 to UART, polling until the FIFO has room
uart_putc:
    ldr x1, =UART_BASE

wait:
    ldr w2, [x1, #UART_FR]
    tst w2, #UART_TXFF
    b.ne wait

    str w0, [x1, #UART_DR]

    ret

// Writes a null-terminated string pointed to by x0
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

// Prints the 64-bit value in x0 as 16 hex digits
uart_put_hex:
    stp x19, x20, [sp, #-32]!
    stp x30, xzr, [sp, #16]

    mov x19, x0
    mov x20, #16

hex_loop:
    lsr x3, x19, #60
    and x3, x3, #0xF

    ldr x2, =hex_chars
    ldrb w0, [x2, x3]
    bl uart_putc

    lsl x19, x19, #4

    subs x20, x20, #1
    b.ne hex_loop

    ldp x30, xzr, [sp, #16]
    ldp x19, x20, [sp], #32
    ret

.section .rodata.uart

hex_chars:
    .asciz "0123456789ABCDEF"
