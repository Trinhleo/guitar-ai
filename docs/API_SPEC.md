# API Specification

Base URL: `http://localhost:5000` (dev) or same-origin `/api` via nginx (Docker web).

Authenticated routes require header: `Authorization: Bearer <token>`.

## Health

| Method | Path | Auth | Response |
|--------|------|------|----------|
| GET | `/health` | No | `{ "status": "ok", "db": "ok" }` or 503 if DB down |

## Auth

| Method | Path | Body | Response |
|--------|------|------|----------|
| POST | `/api/auth/register` | `{ email, password, displayName? }` | 201 `{ token, userId, email }` |
| POST | `/api/auth/login` | `{ email, password }` | 200 `{ token, userId, email }` |

## Instruments

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/instruments` | No |
| GET | `/api/instruments/{id}` | No |

## Content

| Method | Path | Query params | Auth |
|--------|------|--------------|------|
| GET | `/api/content` | `type`, `instrument`, `difficulty` | No |
| GET | `/api/content/{id}` | — | No |
| GET | `/api/content/recommendations` | `instrument`, `limit` | Yes |

Recommendations response:

```json
{
  "items": [{ "content": { ... }, "reason": "...", "targetDifficulty": 2 }],
  "targetDifficulty": 2,
  "averageScore": 85.5
}
```

## Practice

| Method | Path | Body | Auth |
|--------|------|------|------|
| GET | `/api/practice/history` | — | Yes |
| POST | `/api/practice/start/{contentId}` | `{ instrumentId }` | Yes |
| POST | `/api/practice/{sessionId}/evaluate` | `{ playedNotes: [{ note, startMs, durationMs }] }` | Yes |
| POST | `/api/practice/{sessionId}/upload` | multipart `audio` (WAV) | Yes |
| GET | `/api/practice/{sessionId}/results` | — | Yes |

Evaluate/upload upserts metrics (one row per session).

## Stats

| Method | Path | Query | Auth |
|--------|------|-------|------|
| GET | `/api/stats/progress` | — | Yes |
| GET | `/api/stats/achievements` | — | Yes |
| GET | `/api/stats/leaderboard` | `instrument`, `limit` | Yes |
| GET | `/api/stats/insights` | — | Yes |

## WebSocket

| Path | Auth |
|------|------|
| `GET /ws/practice/{sessionId}?token=<jwt>` | JWT in query (dev); send `{ note, startMs, durationMs }` for live feedback |

## Supported instruments (seed data)

- `guitar`, `piano`, `violin`, `drums`

## Error format

```json
{ "error": "message" }
```

Common status codes: 400 (bad request), 401 (unauthorized), 404 (not found), 409 (duplicate email), 503 (health degraded).
