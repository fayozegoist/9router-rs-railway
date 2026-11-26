#!/usr/bin/env bash
# Deploy this template to Railway.
# Requires: railway CLI (npm i -g @railway/cli) + a logged-in session (railway login).
# Run from the repo root: ./scripts/deploy-railway.sh
set -euo pipefail

PROJECT="${PROJECT:-9router-rs}"
SERVICE="${SERVICE:-9router-rs}"
DATA_MOUNT="${DATA_MOUNT:-/app/data}"

command -v railway >/dev/null || { echo "railway CLI missing: npm i -g @railway/cli"; exit 1; }
railway whoami >/dev/null 2>&1 || { echo "not logged in: railway login"; exit 1; }

INITIAL_PASSWORD="${INITIAL_PASSWORD:-$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-24)}"
JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32)}"

# Project + service. `init` fails if already linked, so fall back to `link`.
railway init --name "$PROJECT" >/dev/null 2>&1 || railway link >/dev/null

railway variables \
  --set "INITIAL_PASSWORD=$INITIAL_PASSWORD" \
  --set "JWT_SECRET=$JWT_SECRET" \
  --set "DATA_DIR=$DATA_MOUNT" \
  --set "AUTH_COOKIE_SECURE=true" \
  --set "ENABLE_REQUEST_LOGS=false"

# Persistent volume for the SQLite DB. Older CLI builds lack `volume add`.
railway volume add --mount-path "$DATA_MOUNT" \
  || echo "!! add the volume manually: service -> Volumes -> mount $DATA_MOUNT"

railway up --detach
railway domain || true

cat <<EOF

Deployed. Dashboard password: $INITIAL_PASSWORD
Open the Railway domain, log in, then change the password in account settings.
Base URL for clients: https://<your-domain>/v1
Keep replicas at 1 — state is SQLite on the volume.
EOF
