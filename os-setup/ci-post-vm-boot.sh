#!/bin/bash -eux
# This script must be run as root.

setup_user="$1" # e.g. "pi"

if [ ! -f "/var/lib/os-setup/success-in-vm" ]; then
  echo "Error: the OS setup scripts did not complete successfully during the previous boot!"
  exit 1
fi

rm -rf /usr/lib/os-setup
rm -rf /var/lib/os-setup

systemctl disable "vm-boot-setup@$setup_user.service"
rm /usr/lib/systemd/system/vm-boot-setup@.service

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))

$build_scripts_root/setup/cleanup.sh
