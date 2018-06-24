#!/usr/bin/env bash

set -eux
set -o pipefail

# This script should be run as user factorio
if [[ "$USER" != "factorio" ]]; then
    echo "run this script as user factorio" >&2
    exit 1
fi

readonly CONFIG="/factorio/config"
readonly SAVES="/factorio/saves"
readonly FPORT=34197
readonly FRCON_PORT=27015

mkdir --parents "$CONFIG"

if [[ ! -s "$CONFIG"/rconpw ]]; then
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c20 >| "$CONFIG"/rconpw
fi

if [[ ! -s "$CONFIG"/server-settings.json ]]; then
  cp /opt/factorio/data/server-settings.example.json "$CONFIG"/server-settings.json
fi

if [[ ! -s "$CONFIG"/map-gen-settings.json ]]; then
  cp /opt/factorio/data/map-gen-settings.example.json "$CONFIG"/map-gen-settings.json
fi

if [[ ! -s "$CONFIG"/map-settings.json ]]; then
  cp /opt/factorio/data/map-settings.example.json "$CONFIG"/map-settings.json
fi

# If there are any temp save files, delete them
if [[ -n "$(find "$SAVES" -iname '*.tmp.zip' -print -quit)" ]]; then
  rm -f "$SAVES"/*.tmp.zip
fi

# If there are no normal save files, create one
if [[ -z "$(find "$SAVES" -iname '*.zip' -print -quit)" ]]; then
    /opt/factorio/bin/x64/factorio \
        --create "$SAVES"/_autosave1.zip  \
        --map-gen-settings "$CONFIG"/map-gen-settings.json \
        --map-settings "$CONFIG"/map-settings.json
fi

exec /opt/factorio/bin/x64/factorio \
  --port "$FPORT" \
  --start-server-load-latest \
  --server-settings "$CONFIG"/server-settings.json \
  --server-whitelist "$CONFIG"/server-whitelist.json \
  --server-banlist "$CONFIG"/server-banlist.json \
  --rcon-port "$FRCON_PORT" \
  --rcon-password "$(cat "$CONFIG"/rconpw)" \
  --server-id "$CONFIG"/server-id.json \
  $@
