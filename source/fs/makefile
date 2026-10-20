CC?=gcc
AR?=ar
CFLAGS?=-std=gnu89 -m32 -march=i386 -ffreestanding -nostdinc -fno-builtin \
	-fno-stack-protector -fno-pic -fno-pie -fno-asynchronous-unwind-tables \
	-fno-unwind-tables -fcf-protection=none -mno-sse -mno-mmx
INCDIR=include
BUILDDIR=../../build
BUILDDIRFS=$(BUILDDIR)/fs

FS_SRCS=cache dir diskette error fnode global init link login misc mkfs mount \
	open path perm read write dostar fileio shell dohelp norm
FS_OBJS=$(addprefix $(BUILDDIRFS)/,$(addsuffix .o,$(FS_SRCS)))

$(BUILDDIR)/fs.a : $(FS_OBJS)
	rm -f $@ && $(AR) cr $@ $^

$(BUILDDIRFS)/%.o : %.c | $(BUILDDIRFS)
	$(CC) $(CFLAGS) -I$(INCDIR) -c -o $@ $<

$(BUILDDIRFS):
	mkdir -p $@

clean:
	rm -f $(BUILDDIRFS)/*.o
	rm -f $(BUILDDIR)/fs.a

.PHONY: clean
