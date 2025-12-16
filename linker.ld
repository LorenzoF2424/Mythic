ENTRY(main)
SECTIONS
{
    . = 0x1000; /* Dici al linker che il codice parte da qui */
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) }
}