.section .text.vectors

.global _exception_vector_table

// Saves context, jumps to the real handler with sp as context pointer
.macro CALL_HANDLER handler
vector_\handler:
	mrs	x19,  ELR_EL1
	mrs	x20,  SPSR_EL1
	mrs	x21,  ESR_EL1

	mov	x0, sp

    bl \handler
.endm

// Label for unused vector in the table
.macro UNUSED_VECTOR
1:	
    wfe
	b	1b
.endm

// 2 KB alignment required for VBAR_EL1
.align 11

_exception_vector_table:
.org 0x000
	UNUSED_VECTOR
.org 0x080
	UNUSED_VECTOR
.org 0x100
	UNUSED_VECTOR
.org 0x180
	UNUSED_VECTOR

// Only current EL, SP_ELx entries are used (EL1 only)
.org 0x200
	CALL_HANDLER el_synchronous
.org 0x280
	CALL_HANDLER el_irq
.org 0x300
	UNUSED_VECTOR
.org 0x380
	UNUSED_VECTOR

.org 0x400
	UNUSED_VECTOR
.org 0x480
	UNUSED_VECTOR
.org 0x500
	UNUSED_VECTOR
.org 0x580
	UNUSED_VECTOR

.org 0x600
	UNUSED_VECTOR
.org 0x680
	UNUSED_VECTOR
.org 0x700
	UNUSED_VECTOR
.org 0x780
	UNUSED_VECTOR
.org 0x800
