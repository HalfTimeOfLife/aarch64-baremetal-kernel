.section .text.tests

.global tests_run

.extern uart_puts
.extern uart_put_hex
.extern free_count
.extern page_alloc
.extern page_free
.extern map_page
.extern kernel_root
.extern fault_count

.include "mm/mm.inc"
.include "uart/uart.inc"
.include "gic/gic.inc"

.equ HIGH_RAM_BASE, (RAM_BASE + KERNEL_VA_OFFSET)

.macro check_at name, va, expected
    ldr x0, =\va
    bl hw_translate
    mov x1, x0
    adr x0, \name
    ldr x2, =\expected
    bl check
.endm

// ------------------------------------------------------------------
// hw_translate
//   Translates a virtual address using the hardware translation
//   mechanism and returns the corresponding physical address.
//
//   in    x0   virtual address
//   out   x0   physical address, or 0 if translation fails
//   uses  x1, x2
// ------------------------------------------------------------------
hw_translate:
    mov x1, x0
    at s1e1r, x1
    isb
    mrs x2, par_el1
    tbnz x2, #0, .Lhw_fail

    and x0, x2, #DESCR_ADDR_MASK
    and x1, x1, #(PAGE_SIZE - 1)
    orr x0, x0, x1
    ret

.Lhw_fail:
    mov x0, #0
    ret

// ------------------------------------------------------------------
// check
//   Compares a value against the expected value and prints the
//   test result, updating the test counters.
//
//   in    x0   test name
//         x1   value read
//         x2   value awaited
//   out   -
//   uses  x0, x3, x4, x19, x20, x21
// ------------------------------------------------------------------
check:
    stp x19, x20, [sp, #-16]!
    stp x21, x30, [sp, #-16]!

    mov x19, x0
    mov x20, x1
    mov x21, x2

    // test_count += 1
    adr x3, test_count
    ldr x4, [x3]
    add x4, x4, #1
    str x4, [x3]

    cmp x20, x21
    b.ne .Lcheck_fail

    // Success message
    adr x0, message_pass
    bl uart_puts
    mov x0, x19
    bl uart_puts

    b .Lcheck_done

    // Fail message
.Lcheck_fail:
    adr x0, message_fail
    bl uart_puts
    mov x0, x19
    bl uart_puts
    adr x0, message_got
    bl uart_puts
    mov x0, x20
    bl uart_put_hex
    adr x0, message_expected
    bl uart_puts
    mov x0, x21
    bl uart_put_hex
    adr x0, message_close_parenthesis
    bl uart_puts

    // test_failures += 1
    adr x3, test_failures
    ldr x4, [x3]
    add x4, x4, #1
    str x4, [x3]

.Lcheck_done:
    ldp x21, x30, [sp], #16
    ldp x19, x20, [sp], #16
    ret

// ------------------------------------------------------------------
// tests_run
//   Runs all test suites and prints the overall test result.
//
//   in    -
//   out   -
//   uses  x0, x30
// ------------------------------------------------------------------
tests_run:
    str x30, [sp, #-16]!

    bl test_mmu_registers
    bl test_pmm
    bl test_translation
    bl test_kernel_location
    bl test_high_alias
    bl test_permissions

    adr x0, test_failures
    ldr x0, [x0]
    cbz x0, .Lall_passed

    adr x0, message_failure_tests
    bl uart_puts
    adr x0, test_failures
    ldr x0, [x0]
    bl uart_put_hex
    adr x0, message_newline
    bl uart_puts
    b .Ltests_done

.Lall_passed:
    adr x0, message_success_tests
    bl uart_puts

.Ltests_done:
    ldr x30, [sp], #16
    ret

// ------------------------------------------------------------------
// test_mmu_registers
//   Verifies the MAIR_EL1, TCR_EL1 and SCTLR_EL1 register values.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x3, x30
// ------------------------------------------------------------------
test_mmu_registers:
    str x30, [sp, #-16]!

    // Check MAIR
    adr x0, name_mair
    mrs x1, mair_el1
    ldr x2, =MAIR_VALUE
    bl check

    // Check TCR
    adr x0, name_tcr
    mrs x1, tcr_el1
    ldr x2, =TCR_VALUE
    bl check

    // Check SCTLR
    adr x0, name_sctlr
    ldr x3, =(SCTLR_M | SCTLR_C | SCTLR_I)
    mrs x1, sctlr_el1
    and x1, x1, x3
    mov x2, x3
    bl check

    ldr x30, [sp], #16
    ret

// ------------------------------------------------------------------
// test_translation
//   Verifies hardware address translation for mapped, unmapped,
//   and high virtual addresses.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x19, x30
// ------------------------------------------------------------------
test_translation:
    stp x19, x30, [sp, #-16]!

    check_at name_at_ram, RAM_BASE, RAM_BASE
    check_at name_at_uart, UART_BASE, UART_BASE
    check_at name_at_gic, GICC_BASE, GICC_BASE
    check_at name_at_high, HIGH_RAM_BASE, RAM_BASE
    check_at name_at_unmapped, 0x20000000, 0
    check_at name_at_ram_end, RAM_END, 0

    adr x19, test_translation
    mov x0, x19
    bl hw_translate
    mov x1, x0
    adr x0, name_at_code
    ldr x2, =KERNEL_VA_OFFSET
    sub x2, x19, x2
    bl check

    ldp x19, x30, [sp], #16
    ret

// ------------------------------------------------------------------
// test_kernel_location
//   Verifies that the PC, stack pointer and exception vector table
//   are located in the high virtual address space.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x30
// ------------------------------------------------------------------
test_kernel_location:
    str x30, [sp, #-16]!

    // PC
    adr x1, test_kernel_location
    lsr x1, x1, #48
    adr x0, name_pc_high
    ldr x2, =0xFFFF
    bl check

    // Stack
    mov x1, sp
    lsr x1, x1, #48
    adr x0, name_sp_high
    ldr x2, =0xFFFF
    bl check

    // Vector table
    mrs x1, vbar_el1
    lsr x1, x1, #48
    adr x0, name_vbar_high
    ldr x2, =0xFFFF
    bl check

    ldr x30, [sp], #16
    ret

// ------------------------------------------------------------------
// test_high_alias
//   Verifies that the identity-mapped and high virtual addresses
//   refer to the same physical memory page.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x19, x20, x30
// ------------------------------------------------------------------
test_high_alias:
    stp x19, x20, [sp, #-32]!
    stp x30, xzr, [sp, #16]

    bl page_alloc
    mov x19, x0
    ldr x1, =KERNEL_VA_OFFSET
    add x20, x19, x1

    ldr x1, =0xAAAA5555
    str x1, [x19]
    ldr x1, [x20]
    adr x0, name_alias_high_read
    ldr x2, =0xAAAA5555
    bl check 


    ldr x1, =0x5555AAAA
    str x1, [x20]
    ldr x1, [x19]
    adr x0, name_alias_identity_read
    ldr x2, =0x5555AAAA
    bl check

    mov x0, x19
    bl page_free

    ldp x30, xzr, [sp, #16]
    ldp x19, x20, [sp], #32
    ret

// ------------------------------------------------------------------
// test_pmm
//   Verifies physical memory management, including page allocation,
//   alignment, zeroing, reuse and restoration of the free page count.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x19, x20, x21, x22, x30
// ------------------------------------------------------------------
test_pmm:
    stp x19, x20, [sp, #-48]!
    stp x21, x22, [sp, #16]
    str x30, [sp, #32]

    adr x0, free_count
    ldr x21, [x0]
    x21 = free_count
    bl page_alloc
    mov x19, x0
    bl page_alloc
    mov x20, x0

    // Distinct pages
    cmp x19, x20
    cset x1, ne
    adr x0, name_pmm_distinct
    mov x2, #1
    bl check

    // Aligned pages
    and x1, x19, #(PAGE_SIZE - 1)
    adr x0, name_pmm_aligned
    mov x2, #0
    bl check

    // Zeroed pages
    ldr x1, [x19]
    ldr x2, [x19, #4088]
    orr x1, x1, x2
    adr x0, name_pmm_zeroed
    mov x2, #0
    bl check

    // Two pages taken
    adr x0, free_count ; ldr x0, [x0]
    sub x1, x21, x0
    adr x0, name_pmm_taken
    mov x2, #2
    bl check

    // last page freed is first page allocated
    mov x0, x20
    bl page_free
    bl page_alloc
    mov x22, x0
    mov x1, x22
    adr x0, name_pmm_reuse
    mov x2, x20
    bl check

    // cleaned and restored
    mov x0, x22 ; bl page_free
    mov x0, x19 ; bl page_free
    adr x0, free_count ; ldr x1, [x0]
    adr x0, name_pmm_restored
    mov x2, x21 
    bl check

    ldr x30, [sp, #32]
    ldp x21, x22, [sp, #16]
    ldp x19, x20, [sp], #48
    ret

// ------------------------------------------------------------------
// test_permissions
//   Verifies read-only page permissions, alias access and fault
//   handling for write attempts and unmapped addresses.
//
//   in    -
//   out   -
//   uses  x0, x1, x2, x3, x25, x26, x27, x28, x30
// ------------------------------------------------------------------
test_permissions:
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x25, x26, [sp, #-16]!
    stp x27, x28, [sp, #-16]!
    stp x30, xzr, [sp, #-16]!

    adr x0, kernel_root ; ldr x25, [x0]
    bl page_alloc ; mov x26, x0
    mov x0, x25
    ldr x1, =0x10000000
    mov x2, x26
    ldr x3, =PAGE_RAM_RO
    bl map_page
    ldr x28, =0x10000000

    // Alias read identity map result
    ldr x1, =0xAAAA5555
    str x1, [x26]
    ldr x1, [x28]
    adr x0, name_perm_alias_read
    ldr x2, =0xAAAA5555
    bl check

    // Read only
    adr x0, fault_count
    ldr x27, [x0]
    ldr x1, =0xBBBB6666
    str x1, [x28]
    ldr x1, [x26]
    adr x0, name_perm_unchanged
    ldr x2, =0xAAAA5555
    bl check

    adr x0, fault_count
    ldr x1, [x0]
    sub x1, x1, x27
    adr x0, name_perm_ro_fault
    mov x2, #1
    bl check

    // Read unmapped address
    adr x0, fault_count
    ldr x27, [x0]
    ldr x1, =0x20000000
    ldr x2, [x1]

    adr x0, fault_count ; ldr x1, [x0]
    sub x1, x1, x27
    adr x0, name_perm_unmapped_fault
    mov x2, #1
    bl check

    mov x0, x26
    bl page_free

    ldp x30, xzr, [sp], #16
    ldp x27, x28, [sp], #16
    ldp x25, x26, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret

.section .bss.tests
.align 3
test_count:
    .skip 8
test_failures:
    .skip 8


.section .rodata.tests

message_newline:
    .asciz "\n"

message_pass:
    .asciz "\nPASS: "

message_fail:
    .asciz "\nFAIL: "

message_got:
    .asciz " (got 0x"

message_expected:
    .asciz ", expected 0x"

message_close_parenthesis:
    .asciz ")"

message_success_tests:
    .asciz "\nALL TESTS PASSED\n"

message_failure_tests:
    .asciz "\nTESTS FAILED: 0x"

name_mair:
    .asciz "REGS: MAIR_EL1 holds MAIR_VALUE"

name_tcr:
    .asciz "REGS: TCR_EL1 holds TCR_VALUE"

name_sctlr:
    .asciz "REGS: SCTLR_EL1 holds SCTLR_VALUE"

name_at_ram:
    .asciz "AT: RAM is identity mapped"

name_at_uart:
    .asciz "AT: UART is identity mapped"

name_at_gic:
    .asciz "AT: GIC is identity mapped"

name_at_high:
    .asciz "AT: RAM is mapped in the high half"

name_at_unmapped:
    .asciz "AT: unmapped address is refused"

name_at_ram_end:
    .asciz "AT: address after the RAM is refused"

name_at_code:
    .asciz "AT: kernel code is mapped in the high half"

name_pc_high:
    .asciz "LOC: kernel runs in the high half"

name_sp_high:
    .asciz "LOC: stack is in the high half"

name_vbar_high:
    .asciz "LOC: exception vectors are in the high half"

name_alias_high_read:
    .asciz "ALIAS: high read sees identity write"

name_alias_identity_read:
    .asciz "ALIAS: identity read sees high write"

name_pmm_distinct:
    .asciz "PMM: two pages are distinct"

name_pmm_aligned:
    .asciz "PMM: pages are 4 KB aligned"

name_pmm_zeroed:
    .asciz "PMM: a new page is zeroed"

name_pmm_taken:
    .asciz "PMM: two pages were taken"

name_pmm_reuse:
    .asciz "PMM: last freed page is reused"

name_pmm_restored:
    .asciz "PMM: free count restored"

name_perm_alias_read:
    .asciz "PERM: read-only alias reads the page"

name_perm_unchanged:
    .asciz "PERM: blocked write left the page unchanged"

name_perm_ro_fault:
    .asciz "PERM: write to a read-only page faults once"

name_perm_unmapped_fault:
    .asciz "PERM: unmapped read faults once"
