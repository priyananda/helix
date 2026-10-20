CC=gcc
LD=ld
NASM=nasm
LDSCRIPT=boot1.ld
# boot1 runs in 16-bit real mode. gcc -m16 emits 32-bit code assembled with
# .code16gcc, so calls between C and nasm use 32-bit call/ret (see
# boot_startup.asm).
CFLAGS=-std=gnu89 -m16 -march=i386 -ffreestanding -nostdinc -fno-builtin \
	-fno-stack-protector -fno-pic -fno-pie -fno-asynchronous-unwind-tables \
	-fno-unwind-tables -fcf-protection=none -mno-sse -mno-mmx \
	-fno-toplevel-reorder
LDFLAGS=-T$(LDSCRIPT) -m elf_i386 -z noexecstack
OUTDIR=../output
BUILDDIR=../build

# boot_startup.o must come first: boot0 jumps to offset 0 of boot1.bin
OBJS=$(BUILDDIR)/boot_startup.o $(BUILDDIR)/boot_main.o $(BUILDDIR)/fat12.o \
	$(BUILDDIR)/graphics.o $(BUILDDIR)/boot1.o

all: $(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin

$(OUTDIR)/boot0.bin : boot0.asm | $(OUTDIR)
	$(NASM) -f bin -o $@ $<

# boot1.ld sets OUTPUT_FORMAT(binary), so the link output is the flat image
$(OUTDIR)/boot1.bin : $(OBJS) $(LDSCRIPT) | $(OUTDIR)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

$(BUILDDIR)/boot_startup.o : boot_startup.asm gdt.asm | $(BUILDDIR)
	$(NASM) -f elf32 -o $@ $<

$(BUILDDIR)/graphics.o : graphics.asm | $(BUILDDIR)
	$(NASM) -f elf32 -o $@ $<

$(BUILDDIR)/%.o : %.c boot1.h fat12.h | $(BUILDDIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(OUTDIR) $(BUILDDIR):
	mkdir -p $@

clean:
	rm -f $(OBJS) $(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin

.PHONY: all clean
