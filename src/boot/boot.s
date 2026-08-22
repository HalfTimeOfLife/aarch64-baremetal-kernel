.section .text.boot

.global _start
.extern kernel_main

_start:
    // Setup stack
    ldr x0, =_stack_top
    mov sp, x0

    bl kernel_main

    b .


