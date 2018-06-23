#!/usr/bin/env bash

set -eux
set -o pipefail

# This script should be run as user factorio
if [[ "$USER" != "factorio" ]]; then
    echo "run this script as user factorio" >2
    exit 1
fi

readonly TMP_LOC="/tmp/factorio.tar.xz"

# Pull down and unpack the latest stable server
curl --location https://www.factorio.com/get-download/stable/headless/linux64 \
    --output "$TMP_LOC"
# Expand into /opt/factorio
tar --extract --file "$TMP_LOC" --directory /opt

# Link data files into the data location
ln -s /factorio/saves /opt/factorio/saves
ln -s /factorio/mods /opt/factorio/mods
ln -s /factorio/scenarios /opt/factorio/scenarios
ln -s /factorio/script-output /opt/factorio/script-output
