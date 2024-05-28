#!/bin/bash -eux
# See https://forums.raspberrypi.com/viewtopic.php?p=2207807#p2207807

base_dtb="$1"
custom_dtb="$2"

cp "$base_dtb" "$custom_dtb"

# dtparam=uart0=on
tmpfile="$(mktemp --tmpdir=/tmp dtb.XXXXXXX)"
dtmerge "$custom_dtb" "$tmpfile" - uart0=on
mv "$tmpfile" "$custom_dtb"

# dtparam=disable-bt
tmpfile="$(mktemp --tmpdir=/tmp dtb.XXXXXXX)"
dtmerge "$custom_dtb" "$tmpfile" /boot/overlays/disable-bt.dtbo
mv "$tmpfile" "$custom_dtb"
