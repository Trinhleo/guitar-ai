# Dual deploy + fallback

Run **Fly.io (primary API)** and **Docker on VPS (full stack backup)** in parallel. The Flutter client automatically fails over when an endpoint is down.

## Architecture

```
                    ┌─────────────────┐
                    │  Flutter Web    │
                    │  (VPS nginx or  │
                    │   static host)  │
                    └────────┬────────┘
                             │ API_BASE_URL + API_FALLBACK_URLS
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │ VPS Docker │  │  Fly.io    │  │  (future)  │
     │  primary   │  │  fallback  │  │            │
     │ same-origin│  │  HTTPS API │  │            │
     └─────┬──────┘  └─────┬──────┘  └────────────┘
           │               │
     ┌─────▼──────┐  ┌─────▼──────┐
     │ Postgres   │  │ Fly Postgres│
     │ (local)    │  │ or Neon     │
     └────────────┘  └─────────────┘
```

## Client failover (built-in)

At startup, `ApiClient.initialize()` probes `GET /health` on each URL and picks the first healthy one.

Build-time defines (comma-separated fallbacks):

```bash
flutter build web --release \
  --dart-define=API_BASE_URL= \
  --dart-define=API_FALLBACK_URLS=https://guitar-ai-api.fly.dev,https://backup.example.com
```

| Define | Example | Meaning |
|--------|---------|---------|
| `API_BASE_URL` | `` (empty) | Same-origin via nginx on VPS |
| `API_BASE_URL` | `https://guitar-ai-api.fly.dev` | Fly as primary |
| `API_FALLBACK_URLS` | `https://backup-ip` | Try next if primary fails |

On each request, **502/503/504** or network errors trigger retry on the next URL.

WebSocket uses the active `api.baseUrl` after failover.

## Recommended setup

### Option A — VPS primary, Fly fallback (simplest)

1. **VPS (Oracle/Hetzner):** full stack
   ```bash
   cp .env.prod.example .env.prod
   # set JWT_SECRET, POSTGRES_PASSWORD, FLY_API_URL=https://your-app.fly.dev
   ./scripts/deploy-docker-prod.sh
   ```
   Web uses same-origin API; Fly URL is baked in as fallback.

2. **Fly.io:** API only (backup)
   ```bash
   ./scripts/deploy-fly.sh
   ```

### Option B — Fly primary, VPS fallback

Build web with:
```bash
--dart-define=API_BASE_URL=https://guitar-ai-api.fly.dev \
--dart-define=API_FALLBACK_URLS=http://YOUR_VPS_IP
```

## Database note (important)

| DB setup | Failover behavior |
|----------|-------------------|
| **Separate DBs** (default) | Users/sessions on Fly ≠ VPS — fallback works for **uptime**, not data sync |
| **Shared Neon Postgres** | Point both `DATABASE_URL` to Neon — **true failover** with same data |

Shared DB example:
```bash
# Fly
fly secrets set DATABASE_URL="postgresql://..." GO_ENV=production JWT_SECRET="..." -a guitar-ai-api

# VPS .env.prod — use external DB instead of local postgres service
# (customize docker-compose to use EXTERNAL_DATABASE_URL)
```

## Deploy commands

| Task | Command |
|------|---------|
| Deploy Fly API | `./scripts/deploy-fly.sh` |
| Deploy VPS Docker | `./scripts/deploy-docker-prod.sh` |
| Check all endpoints | `API_PRIMARY= FLY_API_URL=https://x.fly.dev API_FALLBACK_URLS=https://x.fly.dev ./scripts/check-endpoints.sh` |
| GitHub Actions Fly deploy | Actions → Deploy Fly API (needs `FLY_API_TOKEN` secret) |

## Register / sign up

| Service | URL | Role |
|---------|-----|------|
| **Fly.io** | https://fly.io/app/sign-up | Primary/backup API (PaaS) |
| **Oracle Cloud Free** | https://www.oracle.com/cloud/free/ | VPS for Docker full stack |
| **Neon** (optional) | https://neon.tech | Shared Postgres for true failover |

## Verify failover

1. Start both deployments.
2. Stop VPS: `docker compose -f docker-compose.prod.yml down`
3. Reload web app — should switch to Fly after health probe / failed request.
4. Run `./scripts/check-endpoints.sh` with your URLs.

See also [DEPLOY.md](./DEPLOY.md) for single-target deploy details.
