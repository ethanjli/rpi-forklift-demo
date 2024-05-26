#!/bin/bash -eux
# The localization configuration provides a set of defaults for internationalization and
# localization settings.

# Generate the en_US UTF-8 locale for use. Note: refer to the contents of
# /usr/share/i18n/SUPPORTED for a list of locales which can be generated.
sudo bash -c 'cat > /etc/locale.gen' << EOT
en_US.UTF-8 UTF-8
EOT
sudo dpkg-reconfigure --frontend=noninteractive locales

# Change the default locales so that the base-locale is en_US.UTF-8.
# FIXME: https://wiki.debian.org/Locale#Standard recommends that instead we should actually set the
# default locale to "None" - so that users who access the system over SSH can set their own locale
# using the LANG environment variable. We can do this with the command `sudo update-locale --reset`.
export LANG="en_US.UTF-8"
sudo update-locale LANG="$LANG"

# Change the timezone to UTC
# If systemd is not running (e.g. when setup scripts are run in an unbooted chroot or container),
# we can't use `timedatectl`:
if ! sudo timedatectl set-timezone UTC 2>/dev/null; then
  sudo rm /etc/localtime
  sudo ln -s /usr/share/zoneinfo/UTC /etc/localtime
fi
