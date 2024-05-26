#!/bin/bash -eux
# This script must be run as root.

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))
cp -r $build_scripts_root/ci-boot/* /
ls /
systemctl enable ci-boot-setup.service

# Change default settings for the SD card to enable headless & keyboardless first boot
# Note: we could change the username by making a `/boot/userconf.txt` file with the new username
# and an encrypted representation of the password (and un-disabling and unmasking
# `userconfig.service`), but we don't need to do that for now.
# See https://github.com/RPi-Distro/userconf-pi/blob/bookworm/userconf-service and
# https://www.raspberrypi.com/documentation/computers/configuration.html#configuring-a-user and
# and the "firstrun"-related and "cloudinit"-related lines of
# https://github.com/raspberrypi/rpi-imager/blob/qml/src/OptionsPopup.qml and
# the RPi SD card image's `/usr/lib/raspberrypi-sys-mods/firstboot` and
# `/usr/lib/raspberrypi-sys-mods/imager_custom` scripts
echo "pi:copepode" | chpasswd
sed -i -e "s~^XKBLAYOUT=.*~XKBLAYOUT=\"us\"~" /etc/default/keyboard
systemctl disable userconfig.service