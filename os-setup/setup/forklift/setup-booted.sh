#!/bin/bash -eux
# The Forklift pallet github.com/PlanktoScope/pallet-standard provides the standard configuration of
# Forklift package deployments of Docker containerized applications, OS config files, and systemd
# system services for the PlanktoScope software distribution.

config_files_root=$(dirname $(realpath $BASH_SOURCE))

# Prepare to apply the local pallet

# Note: the pi user will only be able to run `forklift stage plan` and `forklift stage cache-img`
# without root permissions after a reboot, so we may need `sudo -E` here; I had tried running
# `newgrp docker` in the script to avoid the need for `sudo -E here`, but it doesn't work in the
# script here (even though it works after the script finishes, before rebooting):
FORKLIFT="forklift"
if [ -S /var/run/docker.sock ] && ! sudo -E docker ps 2&>1 > /dev/null; then
  echo "Warning: docker couldn't start normally during boot, so we'll instead try to start it with iptables disabled..."
  # If Docker couldn't start by itself because we can't use iptables (because we're in a
  # systemd-nspawn container running ARM binaries with QEMU on a non-ARM host), we'll try to start
  # it manually ourselves with iptables disabled:
  sudo mkdir -p /etc/systemd/system/docker.service.d
  override_config="$(sudo mktemp --tmpdir=/etc/systemd/system/docker.service.d --suffix=.conf setup-XXXXXXX)"
  sudo cp "$config_files_root/dockerd-override.conf" "$override_config"
  sudo systemctl daemon-reload
  if ! sudo systemctl start docker.service; then
    echo "Error: couldn't start docker!"
    journalctl --no-pager -u docker.service
    # Note: Docker requires iptables-nft, which won't work if run using qemu-aarch64-static
    # (see https://github.com/multiarch/qemu-user-static/issues/191 for details), e.g. via a
    # systemd-nspawn container. But if we run the systemd-nspawn container on an aarch64 host, it
    # should probably work - so once GitHub rolls out arm64 runner for open-source projects, we may
    # be able to run booted setup (i.e. with Docker) in a systemd-nspawn container rather than a
    # QEMU VM; that will probably make the booted setup step much faster.
    sudo iptables-nft -L || sudo lsmod
    exit 1
  fi
  sudo rm override_config
fi
if ! docker ps; then
  FORKLIFT="sudo -E forklift"
fi

$FORKLIFT stage plan

next_pallet="$(basename $(forklift stage locate-bun next))"
# Applying the staged pallet (i.e. making Docker instantiate all the containers) significantly
# decreases first-boot time, by up to 30 sec for github.com/PlanktoScope/pallet-standard.
if ! $FORKLIFT stage apply; then
  echo "Warning: the next staged pallet could not be successfully applied. We'll try again on the next boot, since the pallet might require some files which will only be created during the next boot."
  # Reset the "apply-failed" status of the staged pallet to apply:
  forklift stage set-next --no-cache-img "$next_pallet"
fi

# Prepare to apply the pallet on future boots, too
sudo systemctl unmask forklift-apply.service
