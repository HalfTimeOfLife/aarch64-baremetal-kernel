.section .text.pmm

.include "mm/mm.inc"

.global page_alloc
.global page_free
.global pmm_init
.global free_count

.extern uart_puts
.extern uart_put_hex

// ------------------------------------------------------------------
// page_free
//   Gives a page back to the allocator.
//   Halts with a message if the address is invalid.
//
//   in    x0   page address (4 KB aligned, inside the heap)
//   out   -
//   uses  x1, x2
// ------------------------------------------------------------------
page_free:
    // address not aligned to 4KB
    tst x0, #(PAGE_SIZE - 1)
    b.ne .Lpage_free_error

    ldr x1, =_heap_start
    cmp x0, x1
    b.lo .Lpage_free_error

    ldr x1, =RAM_END
    cmp x0, x1
    b.hs .Lpage_free_error

    adr  x1, free_list_head
    ldr  x2, [x1]
    str  x2, [x0]
    str  x0, [x1]

    adr  x1, free_count
    ldr  x2, [x1]
    add  x2, x2, #1
    str  x2, [x1]

    ret

.Lpage_free_error:
    // Never returns, so clobbering the callee-saved x19 is harmless
    mov x19, x0
    adr x0, page_free_error_message
    bl  uart_puts
    mov x0, x19
    bl  uart_put_hex
    b .

// ------------------------------------------------------------------
// page_alloc
//   Takes a page from the free list and zeroes it.
//
//   in    -
//   out   x0   page address, or 0 if no page is left
//   uses  x1, x2, x3, x4
// ------------------------------------------------------------------
page_alloc:
    adr x1, free_list_head 
    ldr x0, [x1]

    // free_list_head is NULL
    cbz x0, .Lpage_alloc_error

    ldr x2, [x0]
    str x2, [x1] 


    adr x1, free_count
    ldr x2, [x1]
    sub x2, x2, #1
    str x2, [x1]

    mov x3, x0
    add x4, x0, #PAGE_SIZE

.Lzeroing_loop:
    cmp x3, x4
    b.hs .Lzeroing_done

    stp xzr, xzr, [x3], #16
    b .Lzeroing_loop

.Lzeroing_done:
    ret

.Lpage_alloc_error:
    ret

// ------------------------------------------------------------------
// pmm_init
//   Builds the free list from every page between _heap_start and
//   RAM_END.
//
//   in    -
//   out   -
//   uses  x0, x1, x2 (via page_free); x19, x20, x30 are saved
// ------------------------------------------------------------------
pmm_init:
    stp x19, x20, [sp, #-32]!
    stp x30, xzr, [sp, #16]

    ldr x19, =_heap_start
    ldr x20, =RAM_END

.Linit_loop:
    cmp x19, x20
    b.hs .Linit_done
    mov x0, x19
    bl page_free
    add x19, x19, #PAGE_SIZE
    b .Linit_loop

.Linit_done:
    ldp x30, xzr, [sp, #16]
    ldp x19, x20, [sp], #32
    ret

.section .rodata.pmm

page_free_error_message:
    .asciz "\nError: page_free got an invalid address 0x"

.section .bss.pmm
.align 3
free_list_head:
    .skip 8
free_count:
    .skip 8
