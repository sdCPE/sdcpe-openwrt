#!/usr/bin/env bash
# Copyright (C) 2006-2012 OpenWrt.org
set -x
[ $# == 5 -o $# == 6 ] || {
    echo "SYNTAX: $0 <file> <kernel size> <kernel directory> <rootfs size> <rootfs image> [<align>]"
    exit 1
}

OUTPUT="$1"
KERNELSIZE="$2"
KERNELDIR="$3"
ROOTFSSIZE="$4"
ROOTFSIMAGE="$5"
ALIGN="$6"

rm -f "$OUTPUT"

# shellcheck disable=2046
set $(ptgen -o "$OUTPUT" -h 16 -s 63 -t 0xef -p "${KERNELSIZE}m" -t 0x83 -p "${ROOTFSSIZE}m" ${ALIGN:+-l "$ALIGN"} ${SIGNATURE:+-S "0x$SIGNATURE"})

KERNELOFFSET="$(($1 / 512))"
KERNELCOUNT="$(($2 / 1024))" # mkfs.fat BLOCK_SIZE=1024
ROOTFSOFFSET="$(($3 / 512))"
ROOTFSCOUNT="$(($4 / 512))"

[ -n "$PADDING" ] && dd if=/dev/zero of="$OUTPUT" bs=512 seek="$ROOTFSOFFSET" conv=notrunc count="$ROOTFSCOUNT"
dd if="$ROOTFSIMAGE" of="$OUTPUT" bs=512 seek="$ROOTFSOFFSET" conv=notrunc

mkfs.fat -C -n BOOT "$OUTPUT.kernel" "$KERNELCOUNT"
mcopy -s -i "$OUTPUT.kernel" "$KERNELDIR"/* ::/
dd if="$OUTPUT.kernel" of="$OUTPUT" bs=512 seek="$KERNELOFFSET" conv=notrunc
rm -f "$OUTPUT.kernel"
