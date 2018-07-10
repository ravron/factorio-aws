#!/usr/bin/env bash

set -eux
set -o pipefail

# This script should be run as user factorio
if [[ "$USER" != "factorio" ]]; then
    echo "run this script as user factorio" >&2
    exit 1
fi

readonly TMP_LOC="/tmp/factorio.tar.xz"

# Pull down and unpack the latest stable server
#trap "rm -f $TMP_LOC" EXIT
if [[ -e "$TMP_LOC" ]] ; then
    curl --location "https://www.factorio.com/get-download/stable/headless/linux64" \
        --output "$TMP_LOC"
fi

# Expand into /opt/factorio
tar --extract --file "$TMP_LOC" --directory /opt

# Make data directories if not already there
mkdir --parents /factorio/saves
mkdir --parents /factorio/mods
mkdir --parents /factorio/scenarios
mkdir --parents /factorio/script-output

# Link data directories into the data location
ln --force --symbolic --no-dereference /factorio/saves /opt/factorio/saves
ln --force --symbolic --no-dereference /factorio/mods /opt/factorio/mods
ln --force --symbolic --no-dereference /factorio/scenarios /opt/factorio/scenarios
ln --force --symbolic --no-dereference /factorio/script-output /opt/factorio/script-output
