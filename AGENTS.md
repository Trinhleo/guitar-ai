# AGENTS.md

## Cursor Cloud specific instructions

This repo is a **Go backend** (`backend/`, chi + pgx, requires **Go 1.25**) plus a
**Flutter frontend** (`frontend/`). Standard commands live in the root `Makefile` and
`README.md` — use those; only the non-obvious caveats are noted here.

### Backend (primary runnable service)
- Go 1.25 is the default toolchain on this VM (`go version` → 1.25.x). The repo's
  `backend/go.mod` requires 1.25; the older 1.22 base toolchain cannot build it.
- **PostgreSQL 16 must be running before `make run`, `make migrate`, or `make test`.**
  It does not auto-start on a fresh VM. Start it with:
  `sudo pg_ctlcluster 16 main start`
- DB role/databases are already provisioned in the PG data dir: role `guitar`/`guitar`,
  databases `guitar_ai` (dev) and `guitar_ai_test` (tests). Recreate if missing with
  `createdb -O guitar guitar_ai` / `guitar_ai_test`.
- Copy env once: `cp .env.example .env` (points `DATABASE_URL` at local Postgres).
- Tests (`make test`) run with `GO_ENV=test` and hit `guitar_ai_test` — they need a live
  Postgres, not just a build. `internal/api` tests exercise real DB queries.
- Run the API with `make run` (listens on `http://localhost:5000`; `/health` returns
  `{"db":"ok","status":"ok"}`). `make migrate` applies `backend/migrations/*.sql` (seeds
  instruments + content). Config falls back to the local DB URL even without `.env`.
- Auth is JWT: `POST /api/auth/register` / `login` return a token; send it as
  `Authorization: Bearer <token>` for `/api/practice/*` and `/api/stats/*`.

### Frontend (Flutter)
- Flutter SDK is **not** installed on the base VM. `make frontend-run` / `frontend-test`
  require installing Flutter 3.16+ first. The backend is fully runnable/testable without it.

### Docker
- `docker compose up` (full stack) is documented in the README but Docker is not installed
  on the base VM. Prefer the native Go + local Postgres path above for local dev.
