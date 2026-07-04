# Deploy Guide

## Local full stack (development)

```bash
docker compose up -d --build
# Web: http://localhost:3000
# API: http://localhost:5000
```

## Production (Docker Compose on VPS)

1. Copy and edit environment:

```bash
cp .env.example .env.prod
# Set JWT_SECRET and POSTGRES_PASSWORD to strong values
# Set GO_ENV=production so the API refuses weak JWT secrets
```

2. Start:

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
```

3. Verify:

```bash
curl http://localhost/health
curl http://localhost/api/instruments
```

The web container nginx proxies `/api` and `/ws` to the Go API. Flutter web is built with an empty `API_BASE_URL` so requests use same-origin paths.

## Fly.io (API only)

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/) and log in.

2. Create app and Postgres:

```bash
fly apps create guitar-ai-api
fly postgres create --name guitar-ai-db --region sin
fly postgres attach guitar-ai-db -a guitar-ai-api
```

3. Set secrets:

```bash
fly secrets set JWT_SECRET="your-production-secret" -a guitar-ai-api
```

4. Deploy from repo root:

```bash
fly deploy -c fly.toml
```

5. Health check:

```bash
fly curl /health -a guitar-ai-api
```

Deploy Flutter web separately (e.g. Firebase Hosting, Cloudflare Pages, or the `web` service in docker-compose.prod.yml) and point `API_BASE_URL` at your Fly API URL if not using a reverse proxy.

## Health endpoints

| Endpoint | OK response |
|----------|-------------|
| `GET /health` | `{"status":"ok","db":"ok"}` |
| Degraded | `503 {"status":"degraded","db":"down"}` |

## CI / E2E

```bash
make test
make e2e-test
```
