#!/bin/bash
# This script must be run as root.

device="$1"
sysroot="$2"

umount "$sysroot/boot"
umount "$sysroot"
losetup -d "$device"
