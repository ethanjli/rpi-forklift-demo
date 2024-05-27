#!/bin/bash
# This script must be run as root.

image="$1"
sysroot="$2"

device="$(losetup -fP --show "$image")"
e2fsck -p -f "${device}p2"
mkdir -p "$sysroot"
mount "${device}p2" "$sysroot"
mount "${device}p1" "$sysroot/boot"

echo "$device"
