.section .text.timer

.global timer_set_interval
.global timer_init
.global tick_count

timer_set_interval:
    mrs x0, cntfrq_el0

    mov x1, #100
    udiv x0, x0, x1

    msr cntp_tval_el0, x0

    ret

timer_init:
    str x30, [sp, #-16]!
    bl timer_set_interval

    mov x1, #1
    msr cntp_ctl_el0, x1

    ldr x30, [sp], #16
    ret

.section .bss
.align 3
tick_count:
    .skip 8