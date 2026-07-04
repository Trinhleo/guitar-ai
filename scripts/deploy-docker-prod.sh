#!/usr/bin/env bash
# Deploy full stack (Postgres + API + Web) on Oracle VPS via Docker Compose.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.prod}"

cd "$ROOT"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — run scripts/oracle-vm-bootstrap.sh or copy .env.prod.example"
  exit 1
fi

echo "==> Building and starting production stack"
docker compose -f docker-compose.prod.yml --env-file "$ENV_FILE" up -d --build

echo "==> Waiting for health"
for i in $(seq 1 45); do
  if curl -sf http://localhost/health >/dev/null 2>&1; then
    echo "OK: http://localhost/health"
    curl -s http://localhost/health
    echo
    exit 0
  fi
  sleep 2
done

echo "Health check timed out — run: docker compose -f docker-compose.prod.yml logs"
exit 1
