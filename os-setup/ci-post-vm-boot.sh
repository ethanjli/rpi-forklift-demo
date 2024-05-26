#!/bin/bash -eux
# This script must be run as root.

if [ ! -f "/var/lib/os-setup/success-in-vm" ]; then
  echo "Error: the OS setup scripts did not complete successfully during the previous boot!"
  exit 1
fi

rm -rf /usr/lib/os-setup
rm -rf /var/lib/os-setup

systemctl disable "boot-setup@in-vm.service"
rm /usr/lib/systemd/system/boot-setup@.service

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))

$build_scripts_root/setup/cleanup.sh
