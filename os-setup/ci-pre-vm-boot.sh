#!/bin/bash -eux
# This script must be run as root.

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))
cp -r $build_scripts_root/ci-boot/* /
systemctl enable boot-setup@in-vm.service

# Persist the setup scripts for boot, since it's not as simple to mount them into a QEMU VM
cp -r $build_scripts_root /usr/lib/os-setup

$build_scripts_root/ci-pre-headless-boot.sh
# Don't make a login prompt on the main tty where setup script output will be shown:
systemctl disable getty@tty1.service
