#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-5000}"
BASE="http://localhost:${PORT}"

health=$(curl -sf "${BASE}/health")
echo "${health}" | grep -q '"status":"ok"'

instruments=$(curl -sf "${BASE}/api/instruments")
echo "${instruments}" | grep -q 'guitar'

echo "Smoke tests passed"
