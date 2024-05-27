#!/bin/bash -eux
# The Forklift pallet github.com/PlanktoScope/pallet-standard provides the standard configuration of
# Forklift package deployments of Docker containerized applications, OS config files, and systemd
# system services for the PlanktoScope software distribution.

config_files_root=$(dirname $(realpath $BASH_SOURCE))

# Set up & stage local pallet

pallet_path="github.com/ethanjli/pallet-example-minimal"
pallet_version="f2ea1b4"

journalctl --no-pager -u "bind-.local-share-forklift-stages@-home-$USER.service"

# FIXME: forklift plt switch should automatically make this path:
mkdir -p $HOME/.local/share/forklift/pallet
forklift plt switch --no-cache-img $pallet_path@$pallet_version

# Note: the pi user will only be able to run `forklift stage plan` and `forklift stage cache-img`
# without root permissions after a reboot, so we may need `sudo -E` here; I had tried running
# `newgrp docker` in the script to avoid the need for `sudo -E here`, but it doesn't work in the
# script here (even though it works after the script finishes, before rebooting):
FORKLIFT="forklift"
journalctl --no-pager -u docker.service
if [ -S /var/run/docker.sock ] && ! sudo -E docker ps 2&>1 > /dev/null; then
  echo "Warning: Docker couldn't start, so we'll try to start it again with iptables-legacy..."
  sudo cp /etc/alternatives/iptables /etc/alternatives/iptables-forkliftbackup
  sudo cp /etc/alternatives/ip6tables /etc/alternatives/ip6tables-forkliftbackup
  sudo rm /etc/alternatives/iptables
  sudo rm /etc/alternatives/ip6tables
  sudo ln -s /usr/sbin/iptables-legacy /etc/alternatives/iptables
  sudo ln -s /usr/sbin/ip6tables-legacy /etc/alternatives/ip6tables
  sudo systemctl start docker.service
  journalctl --no-pager -u docker.service
fi
if ! docker ps; then
  FORKLIFT="sudo -E forklift"
fi

# TODO: remove this troubleshooting code:
if ! sudo -E docker ps; then
  echo "Warning: Docker does not appear to be running or available!"
  exit 0
fi

$FORKLIFT stage plan
$FORKLIFT stage cache-img
next_pallet="$(basename $(forklift stage locate-bun next))"
# Applying the staged pallet (i.e. making Docker instantiate all the containers) significantly
# decreases first-boot time, by up to 30 sec for github.com/PlanktoScope/pallet-standard.
if ! $FORKLIFT stage apply; then
  echo "Warning: the next staged pallet could not be successfully applied. We'll try again on the next boot, since the pallet might require some files which will only be created during the next boot."
  # Reset the "apply-failed" status of the staged pallet to apply:
  forklift stage set-next --no-cache-img "$next_pallet"
fi

if [ -f /etc/alternatives/iptables-forkliftbackup ]; then
  sudo mv /etc/alternatives/iptables-forkliftbackup /etc/alternatives/ip6tables
fi
if [ -f /etc/alternatives/ip6tables-forkliftbackup ]; then
  sudo mv /etc/alternatives/ip6tables-forkliftbackup /etc/alternatives/ip6tables
fi
