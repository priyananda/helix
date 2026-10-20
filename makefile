CC=gcc
LD=ld
AR=ar
NASM=nasm
OBJCOPY=objcopy
LDSCRIPT=kernel.ld
CFLAGS=-std=gnu89 -m32 -march=i386 -ffreestanding -nostdinc -fno-builtin \
	-fno-stack-protector -fno-pic -fno-pie -fno-asynchronous-unwind-tables \
	-fno-unwind-tables -fcf-protection=none -mno-sse -mno-mmx
LDFLAGS=-T$(LDSCRIPT) -m elf_i386 -z noexecstack --no-warn-rwx-segments
INCDIR=include
AFLAGS=-f elf32 -i$(INCDIR)/ -isource/asm/
BUILDDIR=build
BUILDDIRINT=build/int
BUILDDIRIO=build/io
BUILDDIRKLIB=build/klib
OUTDIR=output

export CC AR CFLAGS

KLIB_OBJS=$(addprefix $(BUILDDIRKLIB)/,atoi.o ctype.o key.o printf.o string.o)
IO_OBJS=$(addprefix $(BUILDDIRIO)/,io.o video.o pic.o keymap.o keyboard.o floppy.o ports.o)
INT_OBJS=$(addprefix $(BUILDDIRINT)/,intrfun.o intrutil.o)

# startup.o must come first: boot1 jumps to the start of the kernel image
# at 0x10000, and the real-mode int 13h trampoline in startup.asm must sit
# within the first 64K of the image.
KERNEL_OBJS=$(BUILDDIR)/startup.o $(BUILDDIR)/main.o $(BUILDDIR)/keyb.o
KERNEL_LIBS=$(BUILDDIR)/fs.a $(BUILDDIR)/io.a $(BUILDDIR)/int.a $(BUILDDIR)/klib.a

all: $(OUTDIR)/kernel.bin $(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin

# Bootable 1.44MB floppy image (no root needed)
image: $(OUTDIR)/floppy.img

$(OUTDIR)/floppy.img : $(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin $(OUTDIR)/kernel.bin tools/mkfloppy.py
	python3 tools/mkfloppy.py $@ $(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin $(OUTDIR)/kernel.bin

run: $(OUTDIR)/floppy.img
	qemu-system-i386 -drive file=$<,format=raw,if=floppy -boot a

$(OUTDIR)/kernel.bin : $(BUILDDIR)/kernel.out | $(OUTDIR)
	$(OBJCOPY) --output-target=binary $< $@

# The libraries reference each other (e.g. fs uses klib and io), so group them.
$(BUILDDIR)/kernel.out : $(KERNEL_OBJS) $(KERNEL_LIBS) $(LDSCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OBJS) --start-group $(KERNEL_LIBS) --end-group

$(BUILDDIR)/klib.a : $(KLIB_OBJS)
	rm -f $@ && $(AR) cr $@ $^

$(BUILDDIR)/io.a : $(IO_OBJS)
	rm -f $@ && $(AR) cr $@ $^

$(BUILDDIR)/int.a : $(INT_OBJS)
	rm -f $@ && $(AR) cr $@ $^

$(BUILDDIR)/fs.a : FORCE
	$(MAKE) -C source/fs

# real.asm and prot16.asm are flat 16-bit blobs that startup.asm pulls in
# with incbin.
$(BUILDDIR)/startup.o : source/asm/startup.asm $(BUILDDIR)/real.bin $(BUILDDIR)/prot16.bin
	$(NASM) $(AFLAGS) -i$(BUILDDIR)/ -o $@ $<

$(BUILDDIR)/%.bin : source/asm/%.asm | $(BUILDDIR)
	$(NASM) -f bin -o $@ $<

$(BUILDDIR)/keyb.o : source/asm/keyb.asm | $(BUILDDIR)
	$(NASM) $(AFLAGS) -o $@ $<

$(OUTDIR)/boot0.bin $(OUTDIR)/boot1.bin : FORCE
	$(MAKE) -C boot

$(BUILDDIRINT)/%.o : source/int/%.c | $(BUILDDIRINT)
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

$(BUILDDIRIO)/%.o : source/io/%.c | $(BUILDDIRIO)
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

$(BUILDDIRKLIB)/%.o : source/klib/%.c | $(BUILDDIRKLIB)
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

$(BUILDDIR)/%.o : source/%.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

$(BUILDDIR) $(BUILDDIRINT) $(BUILDDIRIO) $(BUILDDIRKLIB) $(OUTDIR):
	mkdir -p $@

clean:
	rm -rf $(BUILDDIR) $(OUTDIR)

FORCE:

.PHONY: all image run clean FORCE
