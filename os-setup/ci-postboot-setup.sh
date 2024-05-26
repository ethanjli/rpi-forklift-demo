#!/bin/bash -eux
# This script must be run as root.

systemd disable ci-boot-setup.service
rm /usr/lib/systemd/system/ci-boot-setup.service

# This is needed to have the login prompt on tty1, because we disabled userconfig.service. See
# https://forums.raspberrypi.com/viewtopic.php?p=2032694#p2032694
systemctl enable getty@tty1
