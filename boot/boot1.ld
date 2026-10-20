/* boot1 is loaded by boot0 at 0x0A00:0000 and entered at offset 0,
 * so boot_startup.o (which holds "start") must be linked first. */
OUTPUT_FORMAT(binary)
ENTRY(start)
SECTIONS
{
	.text 0x0000 :
	{
		*(.text .text.*)
		etext = .; _etext = .;
	}
	.data . :
	{
		*(.rodata .rodata.*)
		*(.data .data.*)
		*(.bss .bss.* COMMON)
		edata = .; _edata = .;
	}
	/DISCARD/ :
	{
		*(.comment) *(.note*) *(.eh_frame*)
	}
}
