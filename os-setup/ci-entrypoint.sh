#!/bin/bash -eu

/usr/bin/su - pi -s /usr/bin/bash -c '\
  export DEBIAN_FRONTEND=noninteractive && \
  /run/os-setup/setup.sh && \
  /run/os-setup/cleanup.sh \
'
