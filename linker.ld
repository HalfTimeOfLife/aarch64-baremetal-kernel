ENTRY(_start)

SECTIONS
{
    . = 0x40000000;

    .text : {
        *(.text*)
    }

    .rodata : {
        *(.rodata*)
    }

    .data : {
        *(.data*)
    }

    .bss : {
        *(.bss*)
    }

    . = ALIGN(16);

    .stack :
    {
        _stack_bottom = .;
        . += 0x10000;
        _stack_top = .;
    }
}