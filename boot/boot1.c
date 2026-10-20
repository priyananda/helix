#include "boot1.h"
unsigned char * convertString(int number,int base);

/* Set 80x25 text mode (int 10h, ah=0, al=2) */
static void set_text_mode(void){
    __asm__ __volatile__(
        "int $0x10\n"
        :
        : "a"(0x0002)
        : "memory", "cc"
    );
}
void boot_prompt();
extern void jmp_in_dry_well();
void outString(const char * str){
	/* put_string takes the string in DS:SI */
	__asm__ __volatile__(
		"calll put_string\n"
		: "+S" (str)
		:
		: "eax", "ebx", "memory", "cc"
	);
}

void puts(const char * str){
	outString(str);
	outString("\n\r");
}

void putch(char ch1){
	__asm__ __volatile__(
		"int $0x10\n"
		:
		: "a"(0x0E00 | (unsigned char)ch1), "b"(0)
		: "memory", "cc"
	);
}	
void putchx(unsigned char chl){
    chl &= 0xf;
    chl += (chl <= (unsigned char)9)? '0' : 'A' - 10;
    putch(chl);
}

int getch(void){
	unsigned short ax;
	__asm__ __volatile__(
		"int $0x16\n"
		: "=a"(ax)
		: "a"(0)
		: "memory", "cc"
	);
	return (char)ax;
}

void show_graphics(){
    unsigned long mem;
    short low,high;
    boot_prompt();
    show_gfx();
    mem = get_mem_size();
    high = (short)(mem >> 16);
    low = (short)mem;
    puts     ("+---------------------------------------------------------------------+");
    puts     ("|              Entering 16 Bit Initialization Routine                 |");
    puts     ("+---------------------------------------------------------------------+");
    puts     ("    Probing Memory ................................................... ");
    outString("        Size of main memory is                   [ 0x");
    putchx((unsigned char )(high >> 12));
    putchx((unsigned char )(high >> 8));
    putchx((unsigned char )(high >> 4));
    putchx((unsigned char )high );
    putchx((unsigned char )(low >> 12));
    putchx((unsigned char )(low >> 8));
    putchx((unsigned char )(low >> 4));
    putchx((unsigned char )low );
    puts(" ]");
    puts     ("   Probing Processor .................................................. ");
    outString("       Processor String is                     ");
    get_cpu();
    puts(cpu_str);
    outString("Press any key to switch to 32 bit mode ... ");
    getch();
}

void error_msg(const char * message){
    set_text_mode();
	puts(message);
	puts("Press any key to reboot");
	getch();
	reboot();
}

void boot_prompt(){
    char x = 0;
    set_text_mode();
    puts("-----------------------------------------------------------------------------");
    puts("                             HILOW Helix Loader                              ");
    puts("-----------------------------------------------------------------------------");
    puts("Press:");
    puts("      1 Boot into Helix ");
    puts("      2 Boot into Other Operating system");
    x = getch();
    if (x == (char) '1')return;
    /* Read the hard disk MBR to 0x7C0:0 and chain to it */
    __asm__ __volatile__(
		"pushw %%es\n"
		"mov %w0, %%es\n"
		"int $0x13\n"
		"popw %%es\n"
		:
		: "r"(0x7C0), "a"(0x0201), "b"(0), "c"(0x0001), "d"(0x0080)
		: "memory", "cc"
	);
    jmp_in_dry_well();
}
