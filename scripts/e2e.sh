#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${E2E_PORT:-5099}"
export E2E_BASE_URL="http://localhost:${PORT}"
export GO_ENV="${GO_ENV:-test}"
export JWT_SECRET="${JWT_SECRET:-e2e-test-jwt-secret}"
export DATABASE_URL="${DATABASE_URL:-postgresql://guitar:guitar@localhost:5432/guitar_ai_test}"
export PORT

SERVER_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID"
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Starting API for e2e tests on port ${PORT}..."
cd "$ROOT/backend"
go run ./cmd/server migrate
PORT="${PORT}" go run ./cmd/server &
SERVER_PID=$!

for _ in $(seq 1 30); do
  if curl -sf "${E2E_BASE_URL}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! curl -sf "${E2E_BASE_URL}/health" >/dev/null 2>&1; then
  echo "API failed to start on port ${PORT}" >&2
  exit 1
fi

cd "$ROOT/e2e"
npm install --no-fund --no-audit
npx playwright install chromium
npm test
