#!/usr/bin/env python3
"""Build a bootable 1.44MB FAT12 Helix floppy image without root.

usage: mkfloppy.py OUT.img boot0.bin FILE...

The boot sector is boot0.bin with a FAT12 BPB merged in (bytes 3..61 come
from the BPB, the rest from boot0). Each FILE is copied into the root
directory under its 8.3 name, in contiguous clusters starting at cluster 2.
boot0 looks for BOOT1.BIN and boot1 looks for KERNEL.BIN.
"""
import struct
import sys

SECTOR = 512
TOTAL_SECTORS = 2880
FAT_SECTORS = 9
ROOT_ENTRIES = 224
ROOT_SECTORS = ROOT_ENTRIES * 32 // SECTOR
FIRST_DATA_SECTOR = 1 + 2 * FAT_SECTORS + ROOT_SECTORS  # 33


def main(out, boot0, files):
    img = bytearray(TOTAL_SECTORS * SECTOR)

    bpb = struct.pack('<3s8sHBHBHHBHHHIIBBBI11s8s',
                      b'\xeb\x3c\x90', b'HELIX   ', SECTOR, 1, 1, 2,
                      ROOT_ENTRIES, TOTAL_SECTORS, 0xF0, FAT_SECTORS, 18, 2,
                      0, 0, 0, 0, 0x29, 0x12345678, b'HELIX      ',
                      b'FAT12   ')
    b0 = open(boot0, 'rb').read()
    if len(b0) != SECTOR or b0[510:512] != b'\x55\xaa':
        sys.exit('%s is not a 512-byte boot sector' % boot0)
    img[0:62] = bpb
    img[0:3] = b0[0:3]
    img[62:SECTOR] = b0[62:SECTOR]

    fat = bytearray(FAT_SECTORS * SECTOR)
    fat[0:3] = b'\xf0\xff\xff'

    def set_fat(cluster, value):
        off = cluster * 3 // 2
        if cluster & 1:
            fat[off] = (fat[off] & 0x0f) | ((value << 4) & 0xf0)
            fat[off + 1] = (value >> 4) & 0xff
        else:
            fat[off] = value & 0xff
            fat[off + 1] = (fat[off + 1] & 0xf0) | ((value >> 8) & 0x0f)

    root = bytearray(ROOT_SECTORS * SECTOR)
    cluster = 2
    for i, path in enumerate(files):
        data = open(path, 'rb').read()
        nclusters = max(1, (len(data) + SECTOR - 1) // SECTOR)
        base = path.replace('\\', '/').split('/')[-1].upper()
        name, _, ext = base.partition('.')
        if len(name) > 8 or len(ext) > 3:
            sys.exit('%s is not an 8.3 file name' % base)
        entry = name.ljust(8).encode() + ext.ljust(3).encode()
        root[i * 32:(i + 1) * 32] = struct.pack(
            '<11sB10sHHHI', entry, 0x20, b'\0' * 10, 0, 0, cluster, len(data))
        off = (FIRST_DATA_SECTOR + cluster - 2) * SECTOR
        if off + len(data) > len(img):
            sys.exit('floppy image is full')
        img[off:off + len(data)] = data
        for k in range(nclusters):
            set_fat(cluster + k,
                    0xfff if k == nclusters - 1 else cluster + k + 1)
        cluster += nclusters

    for copy in range(2):
        start = (1 + copy * FAT_SECTORS) * SECTOR
        img[start:start + len(fat)] = fat
    img[(1 + 2 * FAT_SECTORS) * SECTOR:FIRST_DATA_SECTOR * SECTOR] = root

    open(out, 'wb').write(img)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
