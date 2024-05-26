#!/bin/bash -eux

# Run setup scripts
export DEBIAN_FRONTEND=noninteractive
build_scripts_root=$(dirname $(realpath $BASH_SOURCE))
$build_scripts_root/setup.sh
$build_scripts_root/cleanup.sh

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
echo "pi:copepode" | sudo chpasswd
sudo sed -i -e "s~^XKBLAYOUT=.*~XKBLAYOUT=\"us\"~" /etc/default/keyboard
sudo systemctl disable userconfig.service
# This is needed to have the login prompt on tty1, because we disabled userconfig.service. See
# https://forums.raspberrypi.com/viewtopic.php?p=2032694#p2032694
sudo systemctl enable getty@tty1
