#!/bin/bash -eux
# Forklift is used to apply, switch, upgrade, and roll back deployments of Docker containerized
# applications, OS config files, and systemd system services on the OS. This script integrates
# Forklift with the OS's filesystem by installing Forklift and providing some systemd units
# which set up bind mounts and overlay filesystems to bootstrap the configs managed by Forklift.

config_files_root=$(dirname $(realpath $BASH_SOURCE))

# Install Forklift

forklift_version="0.7.2-alpha.6"

arch="$(dpkg --print-architecture | sed -e 's/armhf/arm/' -e 's/aarch64/arm64/')"
curl -L "https://github.com/PlanktoScope/forklift/releases/download/v$forklift_version/forklift_${forklift_version}_linux_${arch}.tar.gz" \
  | sudo tar -C /usr/bin -xz forklift
sudo mv /usr/bin/forklift "/usr/bin/forklift-${forklift_version}"
sudo ln -s "forklift-${forklift_version}" /usr/bin/forklift

# Prepare most of the necessary systemd units:
sudo cp $config_files_root/usr/lib/systemd/system/* /usr/lib/systemd/system/
sudo cp $config_files_root/usr/lib/systemd/system-preset/* /usr/lib/systemd/system-preset/
sudo systemctl preset forklift-apply.service
# Set up read-write filesystem overlays with forklift-managed layers for /etc and /usr
# (see https://docs.kernel.org/filesystems/overlayfs.html):
sudo systemctl preset \
  overlay-sysroot.service \
  bindro-run-forklift-stages-current.service \
  overlay-usr.service \
  overlay-etc.service \
  start-overlaid-units.service

# Make the stage store at /var/lib/forklift/stages available for non-root access in the
# current (i.e. default) user's default Forklift workspace:
sudo systemctl enable "bind-.local-share-forklift-stages@-home-$USER.service" --now
