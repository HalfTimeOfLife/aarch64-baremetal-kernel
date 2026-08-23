.section .text.boot

.global _start
.extern uart_puts

_start:
    ldr x0, =_stack_top
    mov sp, x0

    ldr x0, =message
    bl uart_puts

    b .

.section .rodata

message:
    .asciz "Hello, AArch64!"