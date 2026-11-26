#!/bin/sh
# Railway mounts the volume as root, so fix ownership before dropping privileges.
set -e
: "${DATA_DIR:=/app/data}"
mkdir -p "$DATA_DIR"
chown -R ninerouter:ninerouter "$DATA_DIR"
exec gosu ninerouter /usr/local/bin/9router "$@"
