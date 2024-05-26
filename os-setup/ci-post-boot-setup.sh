#!/bin/bash -eux
# This script must be run as root.

boot_type="$1" # container or vm

if [ ! -f "/var/lib/os-setup/success-$boot_type" ]; then
  echo "Error: the OS setup scripts did not complete successfully during the previous boot!"
  exit 1
fi

rm -rf /usr/lib/os-setup
rm -rf /var/lib/os-setup

systemctl disable "boot-setup@$boot_type.service"
rm /usr/lib/systemd/system/boot-setup@.service

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))

$build_scripts_root/setup/cleanup.sh

# This is needed to have the login prompt on tty1 (so that a user with a keyboard can log in
# without switching away from the default tty), because we disabled userconfig.service. See
# https://forums.raspberrypi.com/viewtopic.php?p=2032694#p2032694
systemctl enable getty@tty1
