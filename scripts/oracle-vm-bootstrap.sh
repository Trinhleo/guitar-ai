#!/usr/bin/env bash
# One-time Oracle VM setup: Docker, clone repo, create .env.prod.
# Usage: curl -fsSL ... | bash   OR   ./scripts/oracle-vm-bootstrap.sh
set -euo pipefail

APP_DIR="${1:-$HOME/guitar-ai}"
REPO="${GUITAR_AI_REPO:-https://github.com/Trinhleo/guitar-ai.git}"

echo "==> Bootstrap Oracle VM for guitar-ai"
echo "    App directory: $APP_DIR"

if ! command -v git >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y git curl
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installing Docker"
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose-plugin
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo ""
  echo "Docker installed. If 'docker' permission denied, log out and SSH back in, then run:"
  echo "  cd $APP_DIR && ./scripts/oracle-vm-bootstrap.sh"
  echo ""
fi

if [[ ! -d "$APP_DIR/.git" ]]; then
  echo "==> Cloning repository"
  git clone "$REPO" "$APP_DIR"
fi

cd "$APP_DIR"
git pull origin main || true

if [[ ! -f .env.prod ]]; then
  cp .env.prod.example .env.prod
  echo ""
  echo "Created .env.prod — EDIT REQUIRED before deploy:"
  echo "  nano $APP_DIR/.env.prod"
  echo ""
  echo "Set at minimum:"
  echo "  POSTGRES_PASSWORD=<strong-password>"
  echo "  JWT_SECRET=<openssl rand -hex 32>"
  echo "  GO_ENV=production"
  echo ""
  echo "Then run: ./scripts/deploy-docker-prod.sh"
  exit 0
fi

chmod +x scripts/*.sh 2>/dev/null || true
echo "==> .env.prod exists — running first deploy"
./scripts/deploy-docker-prod.sh
