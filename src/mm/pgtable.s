.section .text.pgtable

.global map_page
.global translate
   .global map_range

.extern uart_putc
.extern uart_puts
.extern uart_put_hex
.extern page_alloc

.include "mm/mm.inc"

// ------------------------------------------------------------------
// map_page
//   Maps one 4 KB page: virtual address -> physical address,
//   creating the missing intermediate tables.
//
//   in    x0   root table (level 0), a zeroed 4 KB page
//         x1   virtual address (4 KB aligned)
//         x2   physical address (4 KB aligned)
//         x3   attributes (profile, without type bits nor address)
//   out   -
//   uses  x0-x4 (via page_alloc); x19-x24 and x30 are saved
// ------------------------------------------------------------------
map_page:
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x24, [sp, #-16]!
    stp x30, xzr, [sp, #-16]!

    mov x19, x0          // current table (starts at the root)
    mov x20, x1          // virtual address
    mov x21, x2          // physical address
    mov x22, x3          // attributes
    mov x23, #39         // shift of the current level (39, 30, 21)

.Llevel_loop:
    lsr x1, x20, x23
    and x1, x1, #0x1FF
    add x24, x19, x1, lsl #3
    ldr x2, [x24]

    tst x2, #1
    b.ne .Ldown_level

    bl page_alloc
    cbz x0, .Lerror_map_page

    orr x2, x0, #DESCR_TYPE_TABLE
    str x2, [x24]

.Ldown_level:
    and x19, x2, #DESCR_ADDR_MASK
    sub x23, x23, #9
    cmp x23, #12
    b.hi .Llevel_loop

    // Level 3
    lsr x1, x20, #12
    and x1, x1, #0x1FF
    add x24, x19, x1, lsl #3

    orr x2, x21, x22
    orr x2, x2, #DESCR_TYPE_PAGE
    str x2, [x24]

    dsb ishst
    isb

    ldp x30, xzr, [sp], #16
    ldp x23, x24, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret

.Lerror_map_page:
    adr x0, error_map_page_message
    bl  uart_puts
    mov x0, x20
    bl  uart_put_hex
    b .

// ------------------------------------------------------------------
// map_range
//   Maps a range of 4 KB pages: va -> pa
//
//   in    x0   root table (level 0)
//         x1   virtual address of the first page
//         x2   physical address of the first page
//         x3   attributes (profile, as for map_page)
//         x4   size in bytes
//   out   -
//   uses  x0-x4 (via map_page); x19-x23 and x30 are saved
// ------------------------------------------------------------------
map_range:
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x30, [sp, #-16]!

    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x22, x3
    add x23, x1, x4

.Lrange_loop:
    cmp x20, x23
    b.hs .Lrange_done

    mov x0, x19
    mov x1, x20 
    mov x2, x21 
    mov x3, x22 
    bl map_page

    add x20, x20, #PAGE_SIZE
    add x21, x21, #PAGE_SIZE
    b .Lrange_loop

.Lrange_done:
    ldp x23, x30, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret


// ------------------------------------------------------------------
// translate
//   Translate a virtual address to a physical address. Read-only.
//
//   in    x0   root table (level 0), as filled by map_page
//         x1   virtual address
//   out   x0   physical address, including the offset inside the page,
//              or 0 if the address is not mapped
//   uses  x0-x3 (via the UART functions); x19-x23 and x30 are saved
// ------------------------------------------------------------------
translate:
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    stp x23, x30, [sp, #-16]!

    mov x19, x0          // current table (starts at the root)
    mov x20, x1          // virtual address
    mov x21, #39         // shift of the current level (39, 30, 21)
    mov x22, #0          // Level counter

.Ltranslate_loop:
    lsr x1, x20, x21
    and x1, x1, #0x1FF
    add x2, x19, x1, lsl #3
    ldr x23, [x2]

    adr x0, level_message
    bl uart_puts
    add w0, w22, #48
    bl uart_putc
    adr x0, level_address_message
    bl uart_puts
    mov x0, x23
    bl  uart_put_hex

    tbz x23, #0, .Linvalid
    
    cmp x21, #12
    b.eq .Lfound

    and x19, x23, #DESCR_ADDR_MASK
    sub x21, x21, #9
    add x22, x22, #1
    b .Ltranslate_loop

.Lfound:
    and x0, x23, #DESCR_ADDR_MASK
    and x1, x20, #(PAGE_SIZE - 1)
    orr x0, x0, x1
    b   .Ldone

.Linvalid:
    mov x0, #0

.Ldone:
    ldp x23, x30, [sp], #16
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ret


.section .rodata.pgtable

error_map_page_message:
    .asciz "\nError: map_page failed for virtual address 0x"

level_message:
    .asciz "\nLevel: "

level_address_message:
    .asciz ": 0x"
