# Sprint Backlog & Kanban Guide

Track work using **GitHub Issues** + **GitHub Projects** (Kanban board).

---

## Setup (one-time)

### 1. Create labels

Repo → **Issues** → **Labels** → New label, or run:

```bash
./scripts/create-github-issues.sh --labels-only
```

| Label | Color | Purpose |
|-------|-------|---------|
| `priority: P0` | `#b60205` | Must ship this sprint |
| `priority: P1` | `#d93f0b` | Should ship this sprint |
| `priority: P2` | `#fbca04` | Backlog / nice-to-have |
| `area: backend` | `#1d76db` | Go API, DB, evaluation |
| `area: frontend` | `#5319e7` | Flutter web/mobile |
| `area: infra` | `#006b75` | Docker, CI/CD |
| `sprint-1` | `#0e8a16` | Sprint 1 ticket |
| `sprint-2` | `#c5def5` | Sprint 2 ticket |
| `status: done` | `#ededed` | Completed (move in Project) |

### 2. Create milestones

| Milestone | Due | Goal |
|-----------|-----|------|
| **Sprint 1 — Core UX** | +2 weeks | Auth, history, stable frontend |
| **Sprint 2 — Real-time & Audio** | +4 weeks | WebSocket, mic input, pitch detection |

### 3. Create Kanban Project

1. Go to https://github.com/Trinhleo/guitar-ai/projects
2. **New project** → **Board** template
3. Name: `Guitar AI Kanban`
4. Columns:

```
Backlog → Ready → In Progress → In Review → Done
```

5. Add workflow: auto-move to **Done** when issue is closed

### 4. Bulk-create issues

```bash
./scripts/create-github-issues.sh
```

Requires `gh auth login` with `repo` scope.

---

## Current status (as of 2026-07-03)

| Item | Status |
|------|--------|
| Go MVP backend | ✅ Done |
| Flutter web frontend | ✅ Done |
| JWT auth (backend + Flutter) | ✅ Done |
| Practice history API + UI | ✅ Done |
| Progress stats API + UI | ✅ Done |
| Seed content (solos + chords) | ✅ Done |
| Docker Compose (API + Postgres) | ✅ Done |
| CI pipeline (Go + Flutter) | ✅ Done |
| WebSocket feedback | ✅ Done |
| Microphone + pitch detection | ✅ Done |
| Flutter mobile app | ✅ Done |
| Achievements + speed + pitch viz | ✅ Done |
| app_shared refactor | ✅ Done |
| Progress charts | ✅ Done |
| Piano + more content | ✅ Done |
| Session detail + pitch quality | ✅ Done |
| Technique hints + recommendations | ✅ Done |
| Docker web + E2E tests | ✅ Done |
| Smart recommendations | ✅ Done |
| Production deploy configs | ✅ Done |
| Violin instrument | ✅ Done |
| DB health check | ✅ Done |
| Leaderboard API + UI | ✅ Done |
| Drums instrument | ✅ Done |
| Practice insights API | ✅ Done |

---

## Stabilization — Quality & CI

### #34 — Fix CI pipeline
- **Priority:** P0 · **Area:** infra
- **Acceptance:**
  - [x] Flutter mobile tests run with correct working directory
  - [x] CI green on `main`

### #35 — Metrics upsert + DB constraints
- **Priority:** P0 · **Area:** backend
- **Acceptance:**
  - [x] Re-evaluate upserts `performance_metrics` (one row per session)
  - [x] Migration 008: unique index, FK, indexes
  - [x] Integration test for re-evaluate

### #36 — Security + docs sync
- **Priority:** P1 · **Area:** backend + docs
- **Acceptance:**
  - [x] Refuse default JWT secret when `GO_ENV=production`
  - [x] README + `docs/API_SPEC.md` synced with actual API
  - [x] Violin UUID conflict fixed; `DemoUserID` removed

### #37 — Frontend polish
- **Priority:** P1 · **Area:** frontend
- **Acceptance:**
  - [x] Home recommendations filter by instrument
  - [x] Practice "Submit" renamed to "Demo score"
  - [x] App title updated to "Music AI Tutor"

---

## Sprint 8 — Social & Insights

### #31 — Leaderboard API + UI
- **Priority:** P0 · **Area:** backend + frontend
- **Goal:** Rank users by average session score
- **Acceptance:**
  - [x] `GET /api/stats/leaderboard` with optional instrument filter
  - [x] Leaderboard screen with rank, scores, current user highlight
  - [x] Integration tests

### #32 — Drums instrument + content
- **Priority:** P1 · **Area:** backend
- **Goal:** Fourth instrument with rhythm exercises
- **Acceptance:**
  - [x] Migration 007 with drums + 3 exercises
  - [x] Visible in instruments API

### #33 — Practice insights API
- **Priority:** P1 · **Area:** backend + frontend
- **Goal:** Personalized tips based on practice patterns
- **Acceptance:**
  - [x] `GET /api/stats/insights` with streak, weak areas, suggestions
  - [x] Insights section on Progress screen
  - [x] E2E coverage

---

## Sprint 7 — Production & Multi-Instrument

### #27 — Smart recommendations (difficulty-aware)
- **Priority:** P0 · **Area:** backend + frontend
- **Goal:** Recommend content matched to user's average score
- **Acceptance:**
  - [x] Difficulty targeting based on performance
  - [x] `reason` field per recommendation
  - [x] Home screen shows recommendation reason

### #28 — Production deploy configs
- **Priority:** P1 · **Area:** infra
- **Goal:** Document and config for production deployment
- **Acceptance:**
  - [x] `docker-compose.prod.yml`
  - [x] `fly.toml` for API
  - [x] `docs/DEPLOY.md`

### #29 — Violin instrument + content
- **Priority:** P1 · **Area:** backend
- **Goal:** Third instrument with lessons
- **Acceptance:**
  - [x] Migration 006 with violin + 3 exercises
  - [x] Visible in instruments API

### #30 — Health check with DB ping
- **Priority:** P1 · **Area:** backend
- **Goal:** `/health` reports database connectivity
- **Acceptance:**
  - [x] Returns `db: ok` when Postgres reachable
  - [x] Returns 503 when DB down

---

## Sprint 6 — Deploy & Recommendations

### #24 — Technique feedback hints
- **Priority:** P0 · **Area:** backend + frontend
- **Goal:** Actionable tips after practice based on scores
- **Acceptance:**
  - [x] `techniqueHints` in evaluate/results responses
  - [x] Shown on practice + session detail screens
  - [x] Unit tests

### #25 — Content recommendations
- **Priority:** P1 · **Area:** backend + frontend
- **Goal:** Suggest next lessons based on history
- **Acceptance:**
  - [x] `GET /api/content/recommendations`
  - [x] Home screen "Recommended for you" section
  - [x] Integration tests

### #26 — Docker full stack + E2E
- **Priority:** P1 · **Area:** infra
- **Goal:** `docker compose up` runs web + API; Playwright smoke tests
- **Acceptance:**
  - [x] Flutter web Dockerfile + nginx proxy
  - [x] `web` service in docker-compose
  - [x] Playwright API flow tests via `make e2e-test`

---

## Sprint 5 — Session Detail & Quality

### #21 — Session detail screen
- **Priority:** P0 · **Area:** backend + frontend
- **Goal:** History → full session view with expected vs played notes
- **Acceptance:**
  - [x] Store `played_notes` on evaluate
  - [x] Extended `GET /api/practice/:sessionId/results`
  - [x] SessionDetailScreen in app_shared

### #22 — Pitch detection improvements
- **Priority:** P0 · **Area:** backend
- **Goal:** Better note segmentation from WAV
- **Acceptance:**
  - [x] Silence gate (RMS threshold)
  - [x] Correlation confidence threshold
  - [x] Merge adjacent same-pitch notes
  - [x] Unit tests

### #23 — README sync
- **Priority:** P1 · **Area:** docs
- **Goal:** Reflect current stack and roadmap progress
- **Acceptance:**
  - [x] Tech stack updated
  - [x] Project structure updated
  - [x] Roadmap checkboxes synced

---

## Sprint 4 — Refactor & Multi-Instrument

### #18 — Refactor shared screens (`app_shared`)
- **Priority:** P0 · **Area:** frontend
- **Goal:** Single package for screens/services shared by web + mobile
- **Acceptance:**
  - [x] `frontend/packages/app_shared` created
  - [x] Web + mobile depend on `app_shared`
  - [x] Duplicate screen files removed from apps

### #19 — Progress charts
- **Priority:** P0 · **Area:** backend + frontend
- **Goal:** Pitch/timing trends over sessions
- **Acceptance:**
  - [x] `trends` array in `GET /api/stats/progress`
  - [x] `ScoreTrendChart` widget on Progress screen
  - [x] Integration tests

### #20 — Piano instrument + content
- **Priority:** P1 · **Area:** backend
- **Goal:** Second instrument with lessons
- **Acceptance:**
  - [x] Piano in `instruments` table
  - [x] Migration with 2+ piano lessons + 1 guitar lesson
  - [x] Visible in Flutter library (filter by type)

---

## Sprint 3 — Gamification & UX Polish

### #15 — Achievements API + UI
- **Priority:** P1 · **Area:** backend + frontend
- **Goal:** Milestone badges based on practice stats
- **Acceptance:**
  - [x] `GET /api/stats/achievements`
  - [x] Achievements screen in Flutter (web + mobile)
  - [x] Integration tests

### #16 — Practice speed control
- **Priority:** P1 · **Area:** frontend
- **Goal:** Practice at 50%, 75%, or 100% tempo
- **Acceptance:**
  - [x] Speed selector on practice screen
  - [x] Note timings scaled for evaluation

### #17 — Live pitch visualization
- **Priority:** P1 · **Area:** frontend
- **Goal:** Real-time pitch/timing meters during practice
- **Acceptance:**
  - [x] `PitchMeter` widget in shared_ui
  - [x] Shown on practice screen with live feedback

---

## Sprint 1 — Core UX

### #1 — Merge & verify Flutter web frontend
- **Priority:** P0 · **Area:** frontend · **Labels:** `sprint-1`, `area: frontend`
- **Goal:** Land PR #3, confirm end-to-end practice flow works locally
- **Acceptance:**
  - [ ] PR #3 merged
  - [ ] `make run` + `make frontend-run` works
  - [ ] User can pick guitar → lesson → submit → see scores

### #2 — JWT authentication (backend)
- **Priority:** P0 · **Area:** backend · **Epic:** auth
- **Goal:** Replace demo user with real signup/login
- **Acceptance:**
  - [ ] `users` table + password hashing (bcrypt)
  - [ ] `POST /api/auth/register`, `POST /api/auth/login`
  - [ ] JWT middleware on practice endpoints
  - [ ] Go tests for auth flow

### #3 — JWT authentication (Flutter)
- **Priority:** P0 · **Area:** frontend · **Epic:** auth · **Blocked by:** #2
- **Goal:** Login/register screens, token storage, authenticated API calls
- **Acceptance:**
  - [ ] Login + register screens
  - [ ] Token persisted (shared_preferences)
  - [ ] ApiClient sends `Authorization: Bearer` header
  - [ ] Flutter widget tests for auth state

### #4 — Practice history API
- **Priority:** P1 · **Area:** backend
- **Goal:** `GET /api/practice/history` for current user
- **Acceptance:**
  - [ ] Returns sessions with scores, ordered by date
  - [ ] Pagination (limit/offset)
  - [ ] Integration tests

### #5 — Practice history UI
- **Priority:** P1 · **Area:** frontend · **Blocked by:** #4
- **Goal:** History screen showing past sessions
- **Acceptance:**
  - [ ] List of past practice sessions
  - [ ] Tap session → view scores
  - [ ] Empty state when no history

### #6 — Docker Compose: Go API + Postgres
- **Priority:** P1 · **Area:** infra
- **Goal:** Single `docker compose up` runs full backend stack
- **Acceptance:**
  - [ ] Dockerfile for Go backend
  - [ ] `docker-compose.yml` includes api + postgres
  - [ ] README updated

### #7 — CI pipeline (Go + Flutter tests)
- **Priority:** P1 · **Area:** infra
- **Goal:** GitHub Actions on every PR
- **Acceptance:**
  - [ ] `make test` on push/PR
  - [ ] `make frontend-test` on push/PR
  - [ ] Status checks required before merge

---

## Sprint 2 — Real-time & Audio

### #8 — WebSocket real-time feedback
- **Priority:** P0 · **Area:** backend · **Epic:** realtime
- **Goal:** Live pitch/timing hints during practice
- **Acceptance:**
  - [ ] `WS /ws/practice/:sessionId`
  - [ ] Server accepts note events, returns feedback JSON
  - [ ] Go tests with httptest websocket client

### #9 — WebSocket client (Flutter)
- **Priority:** P0 · **Area:** frontend · **Blocked by:** #8
- **Goal:** Connect practice screen to live feedback stream
- **Acceptance:**
  - [ ] WebSocket client in `network` package
  - [ ] Practice screen shows live score updates
  - [ ] Reconnect on disconnect

### #10 — Microphone input (Flutter)
- **Priority:** P1 · **Area:** frontend · **Epic:** audio
- **Goal:** Record audio during practice (web + mobile)
- **Acceptance:**
  - [ ] Request mic permission
  - [ ] Record button with waveform or timer
  - [ ] Platform-specific implementation (web vs mobile)

### #11 — Audio upload + pitch detection
- **Priority:** P1 · **Area:** backend · **Epic:** audio
- **Goal:** Accept WAV upload, detect notes, feed evaluation engine
- **Acceptance:**
  - [ ] `POST /api/practice/:sessionId/upload`
  - [ ] Pitch detection (Python sidecar or Go lib)
  - [ ] Detected notes → existing `EvaluatePerformance`
  - [ ] Integration test with sample WAV

### #12 — Flutter mobile app (`app_mobile`)
- **Priority:** P2 · **Area:** frontend
- **Goal:** iOS + Android app sharing packages with web
- **Acceptance:**
  - [ ] `frontend/apps/app_mobile` created
  - [ ] Shares `network` + `shared_ui` packages
  - [ ] Practice flow works on emulator

### #13 — Seed more content (solos + chords)
- **Priority:** P2 · **Area:** backend
- **Goal:** Expand library beyond one guitar lesson
- **Acceptance:**
  - [ ] Migration with 3+ solos, 3+ chord exercises
  - [ ] Content visible in Flutter library screen

### #14 — Progress dashboard / stats API
- **Priority:** P2 · **Area:** backend + frontend
- **Goal:** `GET /api/stats/progress` + dashboard UI
- **Acceptance:**
  - [ ] Overall progress metrics per user
  - [ ] Dashboard screen in Flutter
  - [ ] Charts for pitch/timing over time

---

## Kanban workflow

```
┌──────────┐   ┌───────┐   ┌─────────────┐   ┌───────────┐   ┌──────┐
│ Backlog  │ → │ Ready │ → │ In Progress │ → │ In Review │ → │ Done │
└──────────┘   └───────┘   └─────────────┘   └───────────┘   └──────┘
     │              │              │                │
  Prioritized    Has AC        Branch open       PR open      Merged +
  not started    no blockers    agent/dev        CI green     closed
```

**Rules:**
1. WIP limit: max **2** items In Progress
2. Every ticket needs **acceptance criteria** before moving to Ready
3. Link PRs to issues (`Closes #N` in PR body)
4. Close issue only when acceptance criteria are met

---

## Linking PRs to issues

In PR description:

```markdown
Closes #2
Related: #3
```

GitHub auto-closes issues when PR merges to default branch.
