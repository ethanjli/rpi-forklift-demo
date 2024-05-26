#!/bin/bash -eux
# This script must be run as root.

if [ ! -f /var/lib/os-setup/success ]; then
  echo "Error: the OS setup scripts did not complete successfully during the previous boot!"
  exit 1
fi

rm -rf /usr/lib/os-setup
rm -rf /var/lib/os-setup

systemctl disable ci-boot-setup.service
rm /usr/lib/systemd/system/ci-boot-setup.service

# This is needed to have the login prompt on tty1, because we disabled userconfig.service. See
# https://forums.raspberrypi.com/viewtopic.php?p=2032694#p2032694
systemctl enable getty@tty1
