#!/bin/bash -eux
# See https://forums.raspberrypi.com/viewtopic.php?p=2207807#p2207807

base_dtb="$1"
output_dtb="$2"

intermediate_dtb="$(mktemp --tmpdir=/tmp dtb.XXXXXXX)"
cp "$base_dtb" "$intermediate_dtb"

# dtparam=uart0=on
tmpfile="$(mktemp -u --tmpdir=/tmp dtb.XXXXXXX)"
dtmerge "$intermediate_dtb" "$tmpfile" - uart0=on
mv "$tmpfile" "$intermediate_dtb"

# dtparam=disable-bt
tmpfile="$(mktemp -u --tmpdir=/tmp dtb.XXXXXXX)"
dtmerge "$intermediate_dtb" "$tmpfile" /boot/overlays/disable-bt.dtbo
mv "$tmpfile" "$intermediate_dtb"

cp "$intermediate_dtb" "$output_dtb"
