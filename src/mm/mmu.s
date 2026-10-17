.section .text.mmu

.global mmu_config
.global mmu_map_identity
.global mmu_enable
.global mmu_enable_caches
.global kernel_root
.global mmu_map_high

.extern map_range

.include "gic/gic.inc"
.include "uart/uart.inc"
.include "mm/mm.inc"

// ------------------------------------------------------------------
// mmu_config
//   Configures the memory attributes (MAIR_EL1) and the translation
//   control (TCR_EL1).
//
//   in    -
//   out   -
//   uses  x0
// ------------------------------------------------------------------
mmu_config:
    // Config MAIR_EL1
    ldr x0, =MAIR_VALUE
    msr mair_el1, x0

    // Config TCR_EL1
    ldr x0, =TCR_VALUE
    msr tcr_el1, x0

    isb
    ret

// ------------------------------------------------------------------
// mmu_map_identity
//   Fills a translation table with an identity mapping (va = pa) of
//   everything the kernel touches.
//
//   in    x0   root table (level 0), a zeroed 4 KB page
//   out   -
//   uses  x0-x4 (via map_range); x19 and x30 are saved
// ------------------------------------------------------------------
mmu_map_identity:
    stp x19, x30, [sp, #-16]!

    mov x19, x0

    // Map RAM
    mov x0, x19
    ldr x1, =RAM_BASE
    ldr x2, =RAM_BASE
    ldr x3, =PAGE_RAM
    ldr x4, =RAM_SIZE
    bl map_range

    // Map GIC (distributor and CPU interface, contiguous)
    mov x0, x19
    ldr x1, =GICD_BASE
    ldr x2, =GICD_BASE
    ldr x3, =PAGE_DEVICE
    ldr x4, =GIC_SIZE
    bl map_range

    // Map UART
    mov x0, x19
    ldr x1, =UART_BASE
    ldr x2, =UART_BASE
    ldr x3, =PAGE_DEVICE
    ldr x4, =PAGE_SIZE
    bl map_range

    ldp x19, x30, [sp], #16
    ret

// ------------------------------------------------------------------
// mmu_enable
//   Gives both root tables to the MMU and turns it on.
//
//   in    x0   TTBR0 root table
//         x1   TTBR1 root table
//   out   -
//   uses  x0, x2
// ------------------------------------------------------------------
mmu_enable:
    adr x2, kernel_root
    str x0, [x2]

    dsb ish

    msr ttbr0_el1, x0
    msr ttbr1_el1, x1

    tlbi vmalle1
    dsb ish
    isb

    mrs x2, sctlr_el1
    orr x2, x2, #SCTLR_M
    msr sctlr_el1, x2

    isb
    ret

// ------------------------------------------------------------------
// mmu_enable_caches
//   Invalidates the instruction cache.
//
//   in    -
//   out   -
//   uses  x0
// ------------------------------------------------------------------
mmu_enable_caches:
    ic iallu
    dsb nsh
    isb

    mrs x0, sctlr_el1
    orr x0, x0, #SCTLR_C
    orr x0, x0, #SCTLR_I
    msr sctlr_el1, x0
    isb
    ret

// ------------------------------------------------------------------
// mmu_map_high
//   Direct map of the whole RAM in the high half.
//
//   in    x0   root table for TTBR1 (level 0), a zeroed 4 KB page
//   out   -
//   uses  x0-x4 (via map_range); x19 and x30 are saved
// ------------------------------------------------------------------
mmu_map_high:
    stp x19, x30, [sp, #-16]!

    mov x19, x0

    ldr x3, =RAM_BASE
    ldr x2, =KERNEL_VA_OFFSET
    add x1, x3, x2
    
    mov x2, x3
    ldr x3, =PAGE_RAM
    ldr x4, =RAM_SIZE

    mov x0, x19
    bl map_range

    ldp x19, x30, [sp], #16
    ret

.section .bss.mmu
.align 3
kernel_root:
    .skip 8
