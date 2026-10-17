.section .text.uart

.global uart_putc
.global uart_puts
.global uart_put_hex

.include "uart/uart.inc"

// ------------------------------------------------------------------
// uart_putc
//   Writes one character to the UART, polling until the FIFO has room.
//
//   in    w0   character
//   out   -
//   uses  x1, x2
// ------------------------------------------------------------------
uart_putc:
    ldr x1, =UART_BASE

wait:
    ldr w2, [x1, #UART_FR]
    tst w2, #UART_TXFF
    b.ne wait

    str w0, [x1, #UART_DR]

    ret

// ------------------------------------------------------------------
// uart_puts
//   Writes a null-terminated string to the UART.
//
//   in    x0   string address
//   out   -
//   uses  x0, x1, x2 (via uart_putc); x19, x30 are saved
// ------------------------------------------------------------------
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

// ------------------------------------------------------------------
// uart_put_hex
//   Prints a 64-bit value as 16 hexadecimal digits.
//
//   in    x0   value
//   out   -
//   uses  x0, x1, x2, x3; x19, x20, x30 are saved
// ------------------------------------------------------------------
uart_put_hex:
    stp x19, x20, [sp, #-32]!
    stp x30, xzr, [sp, #16]

    mov x19, x0
    mov x20, #16

hex_loop:
    lsr x3, x19, #60
    and x3, x3, #0xF

    adr x2, hex_chars
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
