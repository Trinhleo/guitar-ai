#!/usr/bin/env bash
# Check health of primary + fallback API endpoints.
set -euo pipefail

PRIMARY="${API_PRIMARY:-http://localhost:5000}"
FALLBACKS="${API_FALLBACK_URLS:-}"

check_url() {
  local base="$1"
  local label="$2"
  local url
  if [[ -z "$base" ]]; then
    url="http://localhost/health"
  else
    base="${base%/}"
    url="${base}/health"
  fi

  if curl -sf --max-time 8 "$url" >/dev/null 2>&1; then
    echo "OK   $label: $url"
    return 0
  fi
  echo "DOWN $label: $url"
  return 1
}

failed=0
check_url "$PRIMARY" "primary" || failed=1

if [[ -n "$FALLBACKS" ]]; then
  IFS=',' read -ra URLS <<< "$FALLBACKS"
  for i in "${!URLS[@]}"; do
    url="$(echo "${URLS[$i]}" | xargs)"
    [[ -z "$url" ]] && continue
    check_url "$url" "fallback-$((i + 1))" || failed=1
  done
fi

exit "$failed"
