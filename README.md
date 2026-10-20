# helix
Simple OS built as a student project

## Building

Helix was originally built with Turbo C and NASM under DOS (see
`tools/creatb.bat` and `tools/go.bat`), and later with gcc/ld on Linux. It
now builds with a current GNU toolchain plus NASM:

* gcc (tested with 15.2), with 32-bit (`-m32`/`-m16`) support
* GNU binutils: `ld`, `ar`, `objcopy` (tested with 2.46)
* nasm (tested with 3.01)
* python3 (to build the floppy image) and qemu-system-i386 (to run it)

```
make          # output/boot0.bin, output/boot1.bin, output/kernel.bin
make image    # output/floppy.img, a bootable 1.44MB FAT12 floppy
make run      # boot the floppy in qemu
```

The boot sector (`boot0`) and the loader (`boot1`) pause for a key press at
each step; press `1` at the HILOW prompt to boot Helix.
