#!/bin/bash -eux
# This script must be run as root.

image="$1"
sysroot="${2:-}"

echo "Mounting $image..." 1>&2
device="$(losetup -fP --show $image)"
echo "Mounted to $device!" 1>&2

if [ -z "$sysroot" ]; then
  return 0
fi

echo "Mounting $device..." 1>&2
mkdir -p "$sysroot"
mount "${device}p2" "$sysroot"
mount "${device}p1" "$sysroot/boot"
echo "Mounted to $sysroot!" 1>&2

echo $device
