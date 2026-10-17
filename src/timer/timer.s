.section .text.timer

.global timer_set_interval
.global timer_init
.global tick_count

// ------------------------------------------------------------------
// timer_set_interval
//   Arms the timer for the next tick (CNTFRQ_EL0 / 100, about 10 ms).
//
//   in    -
//   out   -
//   uses  x0, x1
// ------------------------------------------------------------------
timer_set_interval:
    mrs x0, cntfrq_el0

    mov x1, #100
    udiv x0, x0, x1

    msr cntp_tval_el0, x0

    ret

// ------------------------------------------------------------------
// timer_init
//   Arms the first tick and enables the non-secure EL1 physical timer.
//
//   in    -
//   out   -
//   uses  x0, x1; x30 is saved
// ------------------------------------------------------------------
timer_init:
    str x30, [sp, #-16]!
    bl timer_set_interval

    mov x1, #1
    msr cntp_ctl_el0, x1

    ldr x30, [sp], #16
    ret

.section .bss.timer
.align 3
tick_count:
    .skip 8
