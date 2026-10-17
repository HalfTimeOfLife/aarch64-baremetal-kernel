.section .text.boot

.global _start

.extern _exception_vector_table
.extern gic_init
.extern uart_puts
.extern uart_putc
.extern uart_put_hex
.extern timer_init
.extern pmm_init
.extern page_alloc
.extern mmu_config
.extern mmu_map_identity
.extern mmu_map_high
.extern mmu_enable
.extern mmu_enable_caches
.extern tests_run

.include "gic/gic.inc"
.include "mm/mm.inc"

_start:
    adr x0, _stack_top
    mov sp, x0

    adr x0, _bss_start
    adr x1, _bss_end

bss_loop:
    cmp x0, x1
    b.hs bss_done
    str  xzr, [x0], #8
    b bss_loop


bss_done:
    adr x0, message
    bl uart_puts

    // VBAR_EL1 must be set before any exception can occur
    adr x0, _exception_vector_table
    msr vbar_el1, x0

    // Initialize the physical memory manager
    bl pmm_init

    // Configure MAIR_EL1 and TCR_EL1 (the MMU is still off)
    bl mmu_config

    // TTBR0 root table: identity map of the RAM, the GIC and the UART
    bl page_alloc
    mov x19, x0
    bl mmu_map_identity

    // TTBR1 root table: direct map of the RAM at PA + KERNEL_VA_OFFSET
    bl page_alloc
    mov x20, x0
    bl mmu_map_high

    // Enable the MMU, then the caches
    mov x0, x19
    mov x1, x20
    bl mmu_enable
    bl mmu_enable_caches

    // Transition to the high-half kernel
    ldr x0, =high_half_entry
    br  x0

high_half_entry:
    // Switch to the high virtual stack
    adr x0, _stack_top
    mov sp, x0

    // Switch exception vectors to their high virtual address
    adr x0, _exception_vector_table
    msr vbar_el1, x0
    isb

    // Run tests - See src/tests/tests.s
    adr x0, message_begin_tests
    bl uart_puts
    bl tests_run
    adr x0, message_end_tests
    bl uart_puts

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

message_begin_tests:
    .asciz "\n---------- Begin tests ----------"

message_end_tests:
    .asciz "---------- End tests ----------\n"
