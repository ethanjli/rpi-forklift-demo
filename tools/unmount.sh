#!/bin/bash -eux
# This script must be run as root.

device="$1"
sysroot="$2"

echo "Unmounting $sysroot..."
umount "$sysroot/boot"
umount "$sysroot"

echo "Unmounting $device..."
e2fsck -p -f "${device}p2"
losetup -d "$device"
