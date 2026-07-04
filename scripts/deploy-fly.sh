#!/usr/bin/env bash
# Deploy Go API to Fly.io (primary cloud endpoint).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="${FLY_APP_NAME:-guitar-ai-api}"

cd "$ROOT"

if ! command -v fly >/dev/null 2>&1; then
  echo "Install flyctl: https://fly.io/docs/hands-on/install-flyctl/"
  exit 1
fi

echo "==> Deploying API to Fly app: $APP_NAME"
fly deploy -c fly.toml -a "$APP_NAME"

echo "==> Health check"
fly curl "/health" -a "$APP_NAME"

echo "Done. API URL: https://${APP_NAME}.fly.dev"
