#!/bin/bash -eux
# This script must be run as root.

image="$1"
sysroot="$2"

echo "Mounting $image..."
device="$(losetup -fP --show $image)"
echo "Mounted to $device!"

echo "Mounting $device..."
mkdir -p "$sysroot"
mount "${device}p2" "$sysroot"
mount "${device}p1" "$sysroot/boot"
echo "Mounted to $sysroot!"
