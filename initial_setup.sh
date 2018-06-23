#!/usr/bin/env bash

set -eux
set -o pipefail

# Mostly taken from https://github.com/dtandersen/docker_factorio_server/blob/master/0.16/Dockerfile

readonly FGID=845
readonly FUID=845
readonly TMP_LOC="/tmp/factorio.tar.xz"

# Create group and user if not already present
sudo groupadd --gid "$FGID" --system factorio || true
sudo useradd --uid "$FUID" --gid "$FGID" --system factorio || true

# Create install and data locations
sudo mkdir --parents /opt/factorio /factorio
sudo chown --recursive factorio:factorio /opt/factorio /factorio

# Switch to factorio
sudo su - factorio

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


