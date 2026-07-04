# Oracle CI/CD from GitHub Actions

Automatic deploy to your Oracle Cloud VM when **CI passes on `main`**, or manually via **Actions → Deploy Oracle → Run workflow**.

## Flow

```
push/merge to main
       │
       ▼
   CI (test + e2e) ──fail──► stop
       │
      pass
       │
       ▼
Deploy Oracle (SSH)
       │
       ▼
git pull → docker compose up --build → /health OK
```

## One-time: Oracle VM setup

### 1. Create VM (Oracle Console)

- Shape: **Ampere A1** (Always Free), Ubuntu 22.04+
- Region: Singapore / Japan
- Add your **SSH public key**
- Security List: allow **TCP 80** (and 22 for SSH)

### 2. Bootstrap on the VM

SSH in:

```bash
ssh ubuntu@<ORACLE_PUBLIC_IP>
```

Run bootstrap (clone + Docker + `.env.prod` template):

```bash
git clone https://github.com/Trinhleo/guitar-ai.git ~/guitar-ai
cd ~/guitar-ai
chmod +x scripts/oracle-vm-bootstrap.sh
./scripts/oracle-vm-bootstrap.sh
```

Edit secrets **on the VM only** (never commit):

```bash
nano ~/guitar-ai/.env.prod
```

```env
POSTGRES_PASSWORD=<openssl rand -hex 16>
JWT_SECRET=<openssl rand -hex 32>
GO_ENV=production
```

First manual deploy:

```bash
cd ~/guitar-ai
./scripts/deploy-docker-prod.sh
curl http://localhost/health
```

Open in browser: `http://<ORACLE_PUBLIC_IP>`

### 3. Deploy SSH key for GitHub Actions

On your **local machine**:

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/guitar-ai-deploy -N ""
```

On **Oracle VM**, add the **public** key:

```bash
echo "paste contents of guitar-ai-deploy.pub" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Test from local:

```bash
ssh -i ~/.ssh/guitar-ai-deploy ubuntu@<ORACLE_IP> "echo OK"
```

## One-time: GitHub repository setup

### 1. Environment (recommended)

Repo → **Settings → Environments → New environment** → name: `production`

Optional: add required reviewers before deploy.

### 2. Secrets

**Settings → Secrets and variables → Actions → Secrets**

| Secret | Example | Required |
|--------|---------|----------|
| `ORACLE_SSH_HOST` | `123.45.67.89` | Yes |
| `ORACLE_SSH_USER` | `ubuntu` (or `opc` on Oracle Linux) | Yes |
| `ORACLE_SSH_PRIVATE_KEY` | Full contents of `guitar-ai-deploy` (private key) | Yes |
| `ORACLE_SSH_PORT` | `22` | No (default 22) |
| `ORACLE_PUBLIC_URL` | Same as IP or domain for health check | No |

### 3. Variables (optional)

**Settings → Secrets and variables → Actions → Variables**

| Variable | Default | Description |
|----------|---------|-------------|
| `ORACLE_APP_DIR` | `/home/ubuntu/guitar-ai` | Repo path on VM |

## Trigger deploy

| Trigger | When |
|---------|------|
| **Automatic** | After CI succeeds on push/merge to `main` |
| **Manual** | Actions → **Deploy Oracle** → Run workflow |

## Verify CI/CD

1. Merge a small change to `main`
2. Wait for **CI** job green
3. **Deploy Oracle** job should start automatically
4. Check: `curl http://<ORACLE_IP>/health`

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Permission denied (publickey)` | Check `ORACLE_SSH_PRIVATE_KEY` and authorized_keys on VM |
| `Missing .env.prod` | Create on VM: `cp .env.prod.example .env.prod` and edit |
| `docker: permission denied` | `sudo usermod -aG docker ubuntu` + re-login SSH |
| Health check fails in workflow | Open port 80 on Oracle Security List |
| Build slow / timeout | Normal first build (~10–15 min); workflow timeout is 25m |
| Deploy skipped | CI must pass on `main`; check workflow_run conclusion |

## Manual deploy (without GitHub)

On the VM:

```bash
cd ~/guitar-ai
git pull origin main
./scripts/deploy-oracle-remote.sh
```

## Security notes

- `.env.prod` stays **only on the VM** — not in GitHub secrets (Postgres password persists in Docker volume).
- Use a **dedicated deploy key**, not your personal SSH key.
- Restrict Oracle Security List: port 22 from your IP if possible; port 80 public for web.

See also [DEPLOY.md](./DEPLOY.md) for Docker Compose details.
