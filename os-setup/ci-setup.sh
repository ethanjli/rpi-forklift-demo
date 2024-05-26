#!/bin/bash -eux

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))

# Run setup scripts
export DEBIAN_FRONTEND=noninteractive
$build_scripts_root/setup/setup.sh
$build_scripts_root/setup/cleanup.sh
