#!/bin/bash -eux

# This is needed to have the login prompt on tty1, because we disabled userconfig.service. See
# https://forums.raspberrypi.com/viewtopic.php?p=2032694#p2032694
sudo systemctl enable getty@tty1
