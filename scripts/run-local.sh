#!/usr/bin/env bash
# Build and run the gateway locally in Docker.
# Run from the repo root: ./scripts/run-local.sh
set -euo pipefail

IMAGE="${IMAGE:-9router-rs}"
PORT="${PORT:-20128}"
DATA="${DATA:-$PWD/.data}"

mkdir -p "$DATA"

docker build -t "$IMAGE" .
docker run --rm -p "$PORT:20128" -v "$DATA:/app/data" \
  -e INITIAL_PASSWORD="${INITIAL_PASSWORD:-123456}" \
  -e JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32)}" \
  -e AUTH_COOKIE_SECURE=false \
  "$IMAGE"
