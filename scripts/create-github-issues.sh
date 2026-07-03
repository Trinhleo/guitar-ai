#!/usr/bin/env bash
# Create GitHub labels, milestones, and sprint issues for kanban tracking.
# Requires: gh CLI authenticated with repo scope
# Usage:
#   ./scripts/create-github-issues.sh              # create everything
#   ./scripts/create-github-issues.sh --labels-only
#   ./scripts/create-github-issues.sh --dry-run

set -euo pipefail

REPO="${REPO:-Trinhleo/guitar-ai}"
DRY_RUN=false
LABELS_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --labels-only) LABELS_ONLY=true ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

create_label() {
  local name="$1"
  local color="$2"
  local description="$3"
  run gh label create "$name" --repo "$REPO" --color "$color" --description "$description" --force
}

echo "==> Creating labels..."
create_label "priority: P0" "b60205" "Must have this sprint"
create_label "priority: P1" "d93f0b" "Should have this sprint"
create_label "priority: P2" "fbca04" "Nice to have / backlog"
create_label "area: backend" "1d76db" "Go API, database, evaluation"
create_label "area: frontend" "5319e7" "Flutter web and mobile"
create_label "area: infra" "006b75" "Docker, CI/CD, DevOps"
create_label "sprint-1" "0e8a16" "Sprint 1 — Core UX"
create_label "sprint-2" "c5def5" "Sprint 2 — Real-time & Audio"
create_label "epic: auth" "e99695" "Authentication epic"
create_label "epic: audio" "f9d0c4" "Audio and pitch detection epic"
create_label "epic: realtime" "bfd4f2" "WebSocket real-time feedback epic"
create_label "status: done" "ededed" "Completed work"

if $LABELS_ONLY; then
  echo "Labels created."
  exit 0
fi

echo "==> Creating milestones..."
if ! $DRY_RUN; then
  gh api "repos/$REPO/milestones" -f title="Sprint 1 — Core UX" \
    -f description="Auth, history, stabilize frontend/backend integration" \
    -f due_on="$(date -u -d '+14 days' +%Y-%m-%dT23:59:59Z 2>/dev/null || date -u -v+14d +%Y-%m-%dT23:59:59Z)" \
    >/dev/null 2>&1 || echo "  (milestone may already exist)"
  gh api "repos/$REPO/milestones" -f title="Sprint 2 — Real-time & Audio" \
    -f description="WebSocket feedback, microphone input, pitch detection" \
    -f due_on="$(date -u -d '+28 days' +%Y-%m-%dT23:59:59Z 2>/dev/null || date -u -v+28d +%Y-%m-%dT23:59:59Z)" \
    >/dev/null 2>&1 || echo "  (milestone may already exist)"
else
  echo "[dry-run] create milestones Sprint 1 and Sprint 2"
fi

create_issue() {
  local title="$1"
  local body="$2"
  shift 2
  run gh issue create --repo "$REPO" --title "$title" --body "$body" "$@"
}

echo "==> Creating Sprint 1 issues..."

create_issue \
  "[Sprint 1] Merge & verify Flutter web frontend" \
  "## Goal
Land PR #3 and confirm the end-to-end practice flow works locally.

## Acceptance Criteria
- [ ] PR #3 merged to main
- [ ] \`make run\` + \`make frontend-run\` works
- [ ] User can: pick guitar → select lesson → submit practice → see scores

## Notes
- PR: https://github.com/Trinhleo/guitar-ai/pull/3
" \
  --label "enhancement" --label "priority: P0" --label "area: frontend" --label "sprint-1" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] JWT authentication — Go backend" \
  "## Goal
Replace the demo user ID with real signup/login and JWT-protected practice endpoints.

## Acceptance Criteria
- [ ] \`users\` table with bcrypt password hashing
- [ ] \`POST /api/auth/register\` and \`POST /api/auth/login\`
- [ ] JWT middleware on practice endpoints
- [ ] Go integration tests for auth flow

## Technical Notes
- Use \`golang-jwt/jwt\` or similar
- Store \`JWT_SECRET\` in \`.env\`
" \
  --label "enhancement" --label "priority: P0" --label "area: backend" --label "sprint-1" --label "epic: auth" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] JWT authentication — Flutter frontend" \
  "## Goal
Login/register screens with token storage and authenticated API calls.

## Acceptance Criteria
- [ ] Login and register screens
- [ ] Token persisted via shared_preferences
- [ ] ApiClient sends \`Authorization: Bearer\` header
- [ ] Flutter tests for auth flow

## Blocked By
- JWT backend issue
" \
  --label "enhancement" --label "priority: P0" --label "area: frontend" --label "sprint-1" --label "epic: auth" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] Practice history API" \
  "## Goal
\`GET /api/practice/history\` returns past sessions for the authenticated user.

## Acceptance Criteria
- [ ] Returns sessions with scores, ordered by date desc
- [ ] Pagination via limit/offset query params
- [ ] Go integration tests
" \
  --label "enhancement" --label "priority: P1" --label "area: backend" --label "sprint-1" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] Practice history UI" \
  "## Goal
Flutter screen listing past practice sessions with score details.

## Acceptance Criteria
- [ ] History list screen
- [ ] Tap session to view scores
- [ ] Empty state when no sessions exist

## Blocked By
- Practice history API issue
" \
  --label "enhancement" --label "priority: P1" --label "area: frontend" --label "sprint-1" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] Docker Compose — Go API + Postgres" \
  "## Goal
Run the full backend with a single \`docker compose up\`.

## Acceptance Criteria
- [ ] Dockerfile for Go backend
- [ ] docker-compose.yml includes api + postgres services
- [ ] README updated with Docker instructions
" \
  --label "enhancement" --label "priority: P1" --label "area: infra" --label "sprint-1" \
  --milestone "Sprint 1 — Core UX"

create_issue \
  "[Sprint 1] CI pipeline — Go + Flutter tests" \
  "## Goal
GitHub Actions running tests on every push and PR.

## Acceptance Criteria
- [ ] Workflow runs \`make test\`
- [ ] Workflow runs \`make frontend-test\`
- [ ] Status checks visible on PRs
" \
  --label "enhancement" --label "priority: P1" --label "area: infra" --label "sprint-1" \
  --milestone "Sprint 1 — Core UX"

echo "==> Creating Sprint 2 issues..."

create_issue \
  "[Sprint 2] WebSocket real-time feedback — Go backend" \
  "## Goal
Live pitch/timing hints during practice via WebSocket.

## Acceptance Criteria
- [ ] \`WS /ws/practice/:sessionId\` endpoint
- [ ] Server accepts note events, returns feedback JSON
- [ ] Go tests with websocket client
" \
  --label "enhancement" --label "priority: P0" --label "area: backend" --label "sprint-2" --label "epic: realtime" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] WebSocket client — Flutter" \
  "## Goal
Connect practice screen to live feedback stream.

## Acceptance Criteria
- [ ] WebSocket client in network package
- [ ] Practice screen shows live score updates
- [ ] Reconnect on disconnect

## Blocked By
- WebSocket backend issue
" \
  --label "enhancement" --label "priority: P0" --label "area: frontend" --label "sprint-2" --label "epic: realtime" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] Microphone input — Flutter" \
  "## Goal
Record audio during practice on web and mobile.

## Acceptance Criteria
- [ ] Mic permission request
- [ ] Record/stop UI
- [ ] Platform-specific implementation (web vs mobile)
" \
  --label "enhancement" --label "priority: P1" --label "area: frontend" --label "sprint-2" --label "epic: audio" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] Audio upload + pitch detection — Go backend" \
  "## Goal
Accept WAV upload, detect notes, feed existing evaluation engine.

## Acceptance Criteria
- [ ] \`POST /api/practice/:sessionId/upload\`
- [ ] Pitch detection pipeline (Python sidecar or Go library)
- [ ] Integration test with sample WAV file
" \
  --label "enhancement" --label "priority: P1" --label "area: backend" --label "sprint-2" --label "epic: audio" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] Flutter mobile app (app_mobile)" \
  "## Goal
iOS + Android app sharing packages with web.

## Acceptance Criteria
- [ ] \`frontend/apps/app_mobile\` scaffolded
- [ ] Shares network + shared_ui packages
- [ ] Practice flow works on emulator
" \
  --label "enhancement" --label "priority: P2" --label "area: frontend" --label "sprint-2" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] Seed content — solos and chords" \
  "## Goal
Expand library beyond one guitar lesson.

## Acceptance Criteria
- [ ] Migration with 3+ solos and 3+ chord exercises
- [ ] Content visible in Flutter library screen
" \
  --label "enhancement" --label "priority: P2" --label "area: backend" --label "sprint-2" \
  --milestone "Sprint 2 — Real-time & Audio"

create_issue \
  "[Sprint 2] Progress dashboard — stats API + UI" \
  "## Goal
User progress metrics and dashboard screen.

## Acceptance Criteria
- [ ] \`GET /api/stats/progress\` endpoint
- [ ] Dashboard screen in Flutter
- [ ] Pitch/timing trend over time
" \
  --label "enhancement" --label "priority: P2" --label "area: backend" --label "area: frontend" --label "sprint-2" \
  --milestone "Sprint 2 — Real-time & Audio"

echo ""
echo "Done! Next steps:"
echo "  1. Open https://github.com/$REPO/projects → New project → Board"
echo "  2. Columns: Backlog | Ready | In Progress | In Review | Done"
echo "  3. Add all issues to the project"
echo "  4. See docs/SPRINT_BACKLOG.md for workflow rules"
