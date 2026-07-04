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

### 1. Create VM

#### Option A — Saved stack (recommended if you clicked "Save stack")

If the Console showed **Out of capacity** and you saved a stack, use **Cloud Shell**:

```bash
git clone -b cursor/oracle-vm-retry-6dcd https://github.com/Trinhleo/guitar-ai.git ~/guitar-ai
cd ~/guitar-ai
chmod +x scripts/oracle-stack-apply-retry.sh

./scripts/oracle-stack-apply-retry.sh \
  --stack-id ocid1.ormstack.oc1.ap-singapore-1.amaaaaaaso7lw4iadqqwc7iggetnh6sj6jb5q6kojs6sim2xe7yili6xtlhq \
  --interval 90
```

Behavior:

- Retries **Apply stack** every 90s when AD is full
- **Stops immediately** when apply succeeds or VM is already RUNNING (no spam)
- Safe to run again later — skips if VM exists

Requirements: **Oracle Cloud Shell** only (OCI CLI already logged in). No extra secrets.

#### Option B — Direct CLI launch (no saved stack)

Use **Oracle Cloud Shell** (Console → Cloud Shell icon). OCI CLI is pre-authenticated.

```bash
# 1) Generate SSH key in Cloud Shell (once)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub   # save private key if you SSH from local later

# 2) Clone repo (or curl script only)
git clone https://github.com/Trinhleo/guitar-ai.git ~/guitar-ai
cd ~/guitar-ai
chmod +x scripts/oracle-launch-vm-retry.sh

# 3) Retry A1 across AD-1/2/3 until success (Ctrl+C to stop)
./scripts/oracle-launch-vm-retry.sh \
  --compartment musica-tutor-ai-prod \
  --ssh-key-file ~/.ssh/id_ed25519.pub \
  --create-network \
  --open-ports \
  --interval 90
```

Script output on success:

```
instance_id=ocid1.instance...
public_ip=123.45.67.89
ssh ubuntu@123.45.67.89
```

Options:

| Flag | Purpose |
|------|---------|
| `--create-network` | Create VCN + public subnet if none exists |
| `--open-ports` | Ensure security list allows TCP 22 + 80 |
| `--interval 90` | Wait 90s between full AD cycles |
| `--max-attempts 100` | Stop after 100 cycles (default: retry forever) |
| `--fallback-micro` | Try E2.1.Micro (1 GB) if A1 never succeeds |
| `--dry-run` | Print plan without creating resources |

#### Option C — Oracle Console (manual)

- Shape: **Ampere A1** (Always Free), Ubuntu 22.04+
- Region: home region (e.g. Singapore)
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
| `Out of capacity` for A1 | Use `scripts/oracle-launch-vm-retry.sh` from Cloud Shell |

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
