#!/usr/bin/env bash

set -eux
set -o pipefail

# Mostly taken from https://github.com/dtandersen/docker_factorio_server/blob/master/0.16/Dockerfile

readonly FGID=845
readonly FUID=845

# Create group and user if not already present
sudo groupadd --gid "$FGID" --system factorio || true
sudo useradd --uid "$FUID" --gid "$FGID" --system factorio || true


