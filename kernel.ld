/* The kernel is loaded by boot1 at 0x10000 and entered at that address,
 * so startup.o (which holds "start") must be linked first. */
OUTPUT_FORMAT("elf32-i386")
ENTRY(start)
SECTIONS
{
	.text 0x10000 :
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
