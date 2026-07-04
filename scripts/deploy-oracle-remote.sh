#!/usr/bin/env bash
# Runs ON the Oracle VM — called by GitHub Actions SSH deploy or manually after git pull.
set -euo pipefail

APP_DIR="${APP_DIR:-/home/ubuntu/guitar-ai}"
BRANCH="${DEPLOY_BRANCH:-main}"

cd "$APP_DIR"

if [[ ! -f .env.prod ]]; then
  echo "Missing $APP_DIR/.env.prod — create it before CI/CD deploy (see docs/DEPLOY_ORACLE_CI.md)"
  exit 1
fi

echo "==> Fetch $BRANCH"
git fetch origin "$BRANCH"
git reset --hard "origin/$BRANCH"

chmod +x scripts/deploy-docker-prod.sh
export APP_DIR
./scripts/deploy-docker-prod.sh
