# MVP Backend Design Spec

**Date:** 2026-07-03  
**Status:** Approved — Go backend implemented  
**Scope:** Phase 1 MVP backend only (no frontend yet)

---

## Problem

The `guitar-ai` repo is documentation-only. We need a working, testable backend foundation before building Flutter/React clients or advanced ML audio pipelines.

## Goal

Deliver a **testable MVP backend** that:

1. Runs locally via Docker Compose (PostgreSQL + API)
2. Exposes core REST endpoints from the README
3. Seeds guitar as the first instrument
4. Supports starting a practice session and returning a scored evaluation
5. Has automated unit + integration tests (TDD from the start)

## Non-Goals (Phase 1)

- Flutter/React frontend
- Real-time WebSocket feedback
- File upload to S3
- User authentication (use a fixed demo user ID)
- Polyphonic pitch detection from raw audio
- Multiple instruments beyond guitar seed data

## Architecture Decision

### Recommended: Backend-first vertical slice

```
Client (curl/tests) → Go REST API (chi) → PostgreSQL
                              ↓
                     EvaluationEngine (pure Go)
```

**Why not Flutter-first?** No API to call; harder to verify behavior end-to-end.  
**Why Go?** Strong typing, excellent performance for API services, simple deployment as a single binary, and great test tooling for the evaluation engine.  
**Why not full stack now?** Doubles surface area; backend logic (scoring, content) is the core differentiator and is easiest to TDD in isolation.

### Tech choices

| Concern | Choice | Rationale |
|---------|--------|-----------|
| Runtime | Go 1.22 + chi router | Fast, typed, single-binary deployment |
| Database | PostgreSQL 16 | Matches README schema |
| DB driver | pgx/v5 | Idiomatic Postgres driver for Go |
| Migrations | Raw SQL files | Simple, explicit, version-controlled |
| Testing | Go `testing` + httptest | Native TDD support |
| Test DB | Separate `guitar_ai_test` DB | Real integration tests, not mocks |
| Audio (Phase 1) | Accept structured note events in JSON | TDD-friendly; real audio pipeline in Phase 2 |

## Data Model (MVP subset)

### `instruments`
- `id` (varchar PK) — e.g. `guitar`
- `name`, `family`, frequency range, `techniques` (jsonb), `config` (jsonb)

### `musical_content`
- `id` (uuid PK)
- `type` — `lesson` | `solo` | `chord`
- `title`, `difficulty_level`, `bpm`, `key`
- `expected_notes` (jsonb) — array of `{ note, startMs, durationMs }` for evaluation

### `practice_sessions`
- `id` (uuid PK)
- `user_id` (uuid) — hardcoded demo user for MVP
- `content_id`, `instrument_id`
- `overall_score`, `created_at`

### `performance_metrics`
- `session_id`, pitch/timing/technique/expression scores, `instrument_specific_metrics` (jsonb)

## API Endpoints (MVP)

| Method | Path | Behavior |
|--------|------|----------|
| GET | `/health` | `{ status: "ok" }` |
| GET | `/api/instruments` | List seeded instruments |
| GET | `/api/instruments/:id` | Single instrument or 404 |
| GET | `/api/content` | Filter by `type`, `instrument`, `difficulty` |
| GET | `/api/content/:id` | Single content item or 404 |
| POST | `/api/practice/start/:contentId` | Create session, return `{ sessionId }` |
| POST | `/api/practice/:sessionId/evaluate` | Body: `{ playedNotes: [...] }` → scores + persist |
| GET | `/api/practice/:sessionId/results` | Return stored evaluation |

## Evaluation Engine

Pure function module — no DB, no HTTP. Input:

```js
{
  expectedNotes: [{ note: 'E4', startMs: 0, durationMs: 500 }, ...],
  playedNotes:   [{ note: 'E4', startMs: 20, durationMs: 480 }, ...],
  instrumentConfig: { pitchToleranceCents: 50, timingToleranceMs: 80 }
}
```

Output:

```js
{
  overallScore: 87.5,
  pitchAccuracy: 92,
  timingAccuracy: 85,
  techniqueScore: 80,
  expressionScore: 75,
  instrumentSpecificMetrics: { matchedNotes: 8, totalNotes: 10 }
}
```

Scoring weights match README: pitch 40%, timing 35%, technique 15%, expression 7%, consistency 3%.

For MVP, technique/expression/consistency derive from pitch+timing variance (no ML).

## Error Handling

- 404 for missing resources
- 400 for invalid request bodies (missing `playedNotes`, malformed notes)
- 500 only for unexpected DB errors; log server-side, return generic message

## Testing Strategy

| Layer | Tool | What we test |
|-------|------|--------------|
| Unit | Jest | `evaluationEngine.js` scoring logic |
| Integration | Jest + Supertest | HTTP endpoints against test DB |
| Smoke | npm script | `curl /health` after `docker-compose up` |

**TDD rule:** Every production module gets a failing test first. Watch it fail, implement minimally, watch it pass, commit.

## Local Dev Flow

```bash
docker-compose up -d          # postgres (or use local PostgreSQL)
cp .env.example .env
make migrate                # apply migrations + seed
make test                   # all Go tests green
make run                    # API on :5000
make smoke                  # curl health + instruments
```

## Success Criteria

- [x] `make test` passes with ≥15 tests
- [x] PostgreSQL running locally or via Docker Compose
- [x] `GET /api/instruments` returns guitar
- [x] Full practice flow works: start → evaluate → results
- [x] Evaluation engine handles edge cases (empty notes, wrong notes, timing drift)

## Phase 2 Preview (after MVP merges)

- WebSocket real-time feedback
- Audio file upload + pitch detection (Python sidecar or `pitchfinder`)
- User auth (JWT)
- Flutter monorepo per `FLUTTER_ARCHITECTURE.md`
