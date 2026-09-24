.section .text.gic

.global gic_init

.include "gic/gic.inc"

gic_init:
    // Distributor: enable Group 0 forwarding
    ldr x0, =GICD_BASE
    mov w1, #0x1
    str w1, [x0, #GICD_CTLR]

    // Distributor: enable SGI 0 and PPI 30
    ldr x0, =GICD_BASE
    mov  w2, #0x1
    movk w2, #0x4000, lsl #16 
    str w2, [x0, #GICD_ISENABLER0]

    // CPU interface: let all priorities through
    ldr x0, =GICC_BASE
    mov w3, #0xFF
    str w3, [x0, #GICC_PMR]

    // CPU interface: enable Group 0 signaling
    ldr x0, =GICC_BASE
    mov w4, #0x1
    str w4, [x0, #GICC_CTLR]

    ret
