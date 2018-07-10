#!/usr/bin/env bash

set -eux
set -o pipefail

# Mostly taken from https://github.com/dtandersen/docker_factorio_server/blob/master/0.16/Dockerfile

readonly SCRIPT_LOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly FGID=845
readonly FUID=845

sudo yum update -y
sudo yum install -y \
    git \
    golang

# Build the player count checker
go build -o "$SCRIPT_LOC"/player-checker "$SCRIPT_LOC"/main.go

# Create group and user if not already present
sudo groupadd --gid "$FGID" --system factorio || true
sudo useradd --uid "$FUID" --gid "$FGID" --system factorio || true

# Create install and data locations
sudo mkdir --parents /opt/factorio /factorio

# Copy the server run script and player count checker to where the factorio user
# can run it
sudo cp "$SCRIPT_LOC"/run.sh /factorio
sudo cp "$SCRIPT_LOC"/player-checker /factorio

# Chown install and data locations
sudo chown --recursive factorio:factorio /opt/factorio /factorio

# Copy server service to systemd location and enable
sudo cp "$SCRIPT_LOC"/factorio.service /etc/systemd/system
sudo systemctl enable factorio.service

# Copy server idle timer and service to systemd location and enable timer
sudo cp "$SCRIPT_LOC"/factorio-idle.{timer,service} /etc/systemd/system
sudo systemctl enable factorio-idle.timer

# Copy the second half of the setup script, run by user factorio, to tmp
trap "rm -f /tmp/factorio_setup.sh" EXIT
cp "$SCRIPT_LOC"/factorio_setup.sh /tmp/factorio_setup.sh

# Switch to factorio
sudo su - factorio /tmp/factorio_setup.sh
