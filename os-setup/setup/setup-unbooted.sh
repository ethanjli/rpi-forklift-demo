#!/bin/bash -eu
# This script runs setup steps which can run in an unbooted container (e.g. in a systemd-nspawn
# container, for example) for performance reasons, and which don't need to run in a booted VM.

# Determine the base path for sub-scripts

build_scripts_root=$(dirname $(realpath $BASH_SOURCE))

# Set up pretty error printing

red_fg=31
blue_fg=34
bold=1

subscript_fmt="\e[${bold};${blue_fg}m"
error_fmt="\e[${bold};${red_fg}m"
reset_fmt='\e[0m'

function report_starting {
  echo
  echo -e "${subscript_fmt}Starting: ${1}...${reset_fmt}"
}
function report_finished {
  echo -e "${subscript_fmt}Finished: ${1}!${reset_fmt}"
}
function panic {
  echo -e "${error_fmt}Error: couldn't ${1}${reset_fmt}"
  exit 1
}

# Run sub-scripts

description="install base tools"
report_starting "$description"
if $build_scripts_root/tools/install.sh ; then
  report_finished "$description"
else
  panic "$description"
fi

description="configure system locales"
report_starting "$description"
if $build_scripts_root/localization/config.sh ; then
  source $build_scripts_root/localization/export-env.sh
  report_finished "$description"
else
  panic "$description"
fi

description="set up Forklift"
report_starting "$description"
if $build_scripts_root/forklift/install.sh ; then
  report_finished "$description"
else
  panic "$description"
fi

description="configure networking"
report_starting "$description"
if $build_scripts_root/networking/install.sh ; then
  report_finished "$description"
else
  panic "$description"
fi
