#!/bin/bash -eu

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))
/usr/bin/su - pi "$build_scripts_root/ci-setup.sh"
