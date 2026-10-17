ENTRY(_start_phys)

KERNEL_PHYS      = 0x40000000;
KERNEL_VA_OFFSET = 0xFFFF000000000000;

SECTIONS
{
    . = KERNEL_PHYS + KERNEL_VA_OFFSET;
    _kernel_start = .;


    .text : AT(ADDR(.text) - KERNEL_VA_OFFSET)
    {
        *(.text*)
    }
    .rodata : AT(ADDR(.rodata) - KERNEL_VA_OFFSET) 
    {
        *(.rodata*)
    }

    .data : AT(ADDR(.data) - KERNEL_VA_OFFSET) 
    {
        *(.data*)
    }

    . = ALIGN(8);
    .bss : AT(ADDR(.bss) - KERNEL_VA_OFFSET) 
    {
        _bss_start = .;
        *(.bss*)
        . = ALIGN(8);
        _bss_end = .;
    }

    . = ALIGN(16);

    .stack : AT(ADDR(.stack) - KERNEL_VA_OFFSET)
    {
        _stack_bottom = .;
        . += 0x10000;
        _stack_top = .;
    }
    _kernel_end = .;

    . = ALIGN(4096);
    _heap_start = ABSOLUTE(. - KERNEL_VA_OFFSET);

    _start_phys = _start - KERNEL_VA_OFFSET;
}