# Deployment Standards

## Overview

This document defines **how** we deploy odoboo-workspace services to production, ensuring reliability, security, and rollback capability. All deployments follow Infrastructure as Code principles with immutable image tags.

## Deployment Architecture

```
Developer → Git Push → GitHub Actions → Deploy
                                      ↓
                          ┌───────────┴───────────┐
                          │                       │
                    Vercel Deploy          DigitalOcean Deploy
                    (Web Frontend)         (OCR Microservice)
                          │                       │
                          └───────────┬───────────┘
                                      ↓
                              Supabase PostgreSQL
                              (Database Migrations)
```

## Deployment Targets

### Web Frontend (Vercel)

**Platform**: Vercel Serverless

**Deployment Trigger**: Git push to `main` branch

**Process**:
1. GitHub webhook triggers Vercel build
2. Next.js build with TypeScript compilation and linting
3. Deploy to edge network (150+ global locations)
4. Automatic preview URLs for PRs

**Configuration**: `vercel.json`
```json
{
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key"
  }
}
```

**Rollback**: Git revert + push triggers automatic redeploy

**SLA**: 99.9% uptime (Vercel guarantee)

### OCR Microservice (DigitalOcean)

**Platform**: DigitalOcean Droplet (Singapore, s-2vcpu-4gb)

**Deployment Trigger**: Manual via deployment script

**Process**:
1. Build AMD64 Docker image with `docker buildx`
2. Tag with `:prod` and `:sha-<gitsha>` for immutability
3. Push to DigitalOcean Container Registry (DOCR)
4. SSH to droplet and deploy via docker-compose
5. NGINX reverse proxy with Let's Encrypt TLS
6. Firewall hardening (port 8000 internal only)

**Configuration**: `infra/do/docker-compose-droplet.yml`
```yaml
version: "3.8"
services:
  ocr:
    image: registry.digitalocean.com/fin-workspace/ocr-service:prod
    container_name: ocr-service
    ports:
      - "127.0.0.1:8000:8000"  # Localhost only
    environment:
      UVICORN_WORKERS: "2"
      LOG_LEVEL: "info"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:8000/health || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 5
```

**Deployment Script**: `infra/do/DEPLOY_WITH_TLS.sh`
```bash
#!/bin/bash
# 1. Build AMD64 image
# 2. Push to DOCR with immutable tags
# 3. Deploy to droplet
# 4. Setup NGINX + Certbot TLS
# 5. Configure firewall
# 6. Verify HTTPS endpoint
```

**Rollback**: Deploy previous SHA tag (`docker-compose pull` with `:sha-<previous>`)

**SLA**: 99.9% uptime (DigitalOcean droplet + monitoring)

### Database (Supabase)

**Platform**: Supabase PostgreSQL (AWS us-east-1)

**Deployment Trigger**: Manual migration execution

**Process**:
1. Write SQL migration in `packages/db/sql/`
2. Test locally with `supabase start` + `supabase db reset`
3. Push to GitHub, create PR
4. CI runs drift detection (schema validation)
5. Merge to `main` triggers production migration
6. Execute via `psql "$POSTGRES_URL" -f migration.sql`

**Migration Pattern**:
```sql
-- Migration: 00_task_bus.sql
-- Description: Task queue for AI-assisted workflows

BEGIN;

CREATE TABLE IF NOT EXISTS task_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE task_queue ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see tasks in their org
CREATE POLICY "org_read_tasks" ON task_queue
  FOR SELECT USING (
    org_id = auth.jwt() ->> 'org_id'
  );

COMMIT;
```

**Rollback**: Git-tracked migrations with DOWN scripts

**SLA**: 99.99% uptime (Supabase managed service)

## CI/CD Pipeline

### GitHub Actions Workflows

**Workflow 1: Continuous Integration** (`.github/workflows/ci.yml`)
```yaml
name: CI
on: [push, pull_request]
jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
```

**Workflow 2: Database Staging** (`.github/workflows/db-staging.yml`)
```yaml
name: DB Staging
on:
  pull_request:
    paths: ['packages/db/sql/**']
jobs:
  migrate-staging:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Apply migration to staging
        run: psql "${{ secrets.STAGING_POSTGRES_URL }}" -f packages/db/sql/*.sql
      - name: Run drift detection
        run: ./scripts/db-sync-check.sh --db "${{ secrets.STAGING_POSTGRES_URL }}"
```

**Workflow 3: Database Production** (`.github/workflows/db-prod.yml`)
```yaml
name: DB Production
on:
  push:
    branches: [main]
    paths: ['packages/db/sql/**']
jobs:
  migrate-prod:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Apply migration to production
        run: psql "${{ secrets.PROD_POSTGRES_URL }}" -f packages/db/sql/*.sql
      - name: Verify schema consistency
        run: ./scripts/db-sync-check.sh --db "${{ secrets.PROD_POSTGRES_URL }}"
```

**Workflow 4: Visual Parity** (`.github/workflows/visual-parity.yml`)
```yaml
name: Visual Parity
on:
  pull_request:
    paths: ['src/**/*.tsx', 'src/**/*.css']
jobs:
  visual-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npx playwright install --with-deps chromium
      - run: npm run build
      - run: npm run preview &
      - run: node scripts/snap.js --routes="/expenses,/tasks" --base-url="http://localhost:4173"
      - run: node scripts/ssim.js --routes="/expenses,/tasks" --odoo-version="19.0"
      - name: Check thresholds
        run: |
          MOBILE_SSIM=$(jq -r '.mobile_ssim' visual_results.json)
          DESKTOP_SSIM=$(jq -r '.desktop_ssim' visual_results.json)
          if (( $(echo "$MOBILE_SSIM < 0.97" | bc -l) )); then
            echo "❌ Mobile SSIM $MOBILE_SSIM < 0.97 threshold"
            exit 1
          fi
          if (( $(echo "$DESKTOP_SSIM < 0.98" | bc -l) )); then
            echo "❌ Desktop SSIM $DESKTOP_SSIM < 0.98 threshold"
            exit 1
          fi
```

## Deployment Checklist

### Pre-Deployment

- [ ] All tests pass (`npm test`)
- [ ] Linting passes (`npm run lint`)
- [ ] TypeScript compilation succeeds (`npm run typecheck`)
- [ ] RLS policy tests pass (database)
- [ ] Visual parity tests pass (SSIM thresholds)
- [ ] Schema drift check passes (Supabase)
- [ ] Environment variables updated (Vercel secrets)
- [ ] OCR service health check returns 200 (DigitalOcean)

### During Deployment

**Web Frontend** (Vercel):
1. Push to `main` branch
2. Wait for Vercel build (2-5 minutes)
3. Monitor Vercel dashboard for errors
4. Check preview URL before promoting

**OCR Microservice** (DigitalOcean):
1. Build AMD64 image: `docker buildx build --platform linux/amd64`
2. Tag with SHA: `docker tag ocr-service:amd64 registry.digitalocean.com/fin-workspace/ocr-service:sha-<gitsha>`
3. Push to DOCR: `docker push registry.digitalocean.com/fin-workspace/ocr-service:prod`
4. Deploy to droplet: `./infra/do/DEPLOY_WITH_TLS.sh`
5. Verify health: `curl -sf https://ocr.insightpulseai.net/health`

**Database** (Supabase):
1. Apply migration: `psql "$POSTGRES_URL" -f packages/db/sql/XX_migration.sql`
2. Verify schema: `./scripts/db-sync-check.sh --db "$POSTGRES_URL"`
3. Check RLS policies: `SELECT * FROM pg_policies WHERE tablename='<table>';`
4. Test API endpoints: `curl -H "apikey: $SUPABASE_ANON_KEY" $SUPABASE_URL/rest/v1/<table>`

### Post-Deployment

- [ ] Smoke test: Visit https://atomic-crm.vercel.app and test critical flows
- [ ] OCR test: Upload sample receipt and verify extraction
- [ ] Database test: Query task_queue and verify RLS enforcement
- [ ] Monitoring: Check Vercel Analytics, Supabase Logs, Sentry errors
- [ ] Performance: Verify TTI < 2.5s (Vercel Analytics)
- [ ] Mobile test: Test on iOS/Android devices
- [ ] Alert: Notify team in Slack #deployments channel

## Rollback Procedures

### Web Frontend Rollback (Vercel)

**Scenario**: Deployment introduced critical bug

**Steps**:
1. Identify previous working commit: `git log --oneline`
2. Revert commit: `git revert <commit-sha>`
3. Push to `main`: `git push origin main`
4. Vercel auto-deploys reverted version (2-5 minutes)
5. Verify rollback: Check preview URL and production site

**Alternative (Instant)**:
1. Go to Vercel dashboard → Deployments
2. Find previous successful deployment
3. Click "Promote to Production"
4. Instant rollback (no rebuild)

### OCR Microservice Rollback (DigitalOcean)

**Scenario**: New OCR service version has issues

**Steps**:
1. Identify previous SHA tag: `git log --oneline`
2. SSH to droplet: `ssh root@188.166.237.231`
3. Update docker-compose.yml: `image: registry.digitalocean.com/fin-workspace/ocr-service:sha-<previous>`
4. Pull and restart: `docker-compose pull && docker-compose up -d`
5. Verify health: `curl http://localhost:8000/health`
6. Test endpoint: `curl -F file=@sample.jpg http://localhost:8000/v1/parse`

**Time**: 2-5 minutes

### Database Rollback (Supabase)

**Scenario**: Migration introduced data corruption or breaking change

**Steps**:
1. Execute DOWN migration: `psql "$POSTGRES_URL" -f packages/db/sql/XX_migration_down.sql`
2. Verify schema: `./scripts/db-sync-check.sh --db "$POSTGRES_URL"`
3. Test API endpoints: `curl -H "apikey: $SUPABASE_ANON_KEY" $SUPABASE_URL/rest/v1/<table>`
4. Restore data from snapshot (if needed): `SELECT restore_snapshot('<snapshot_id>');`

**Time**: 5-15 minutes

**Prevention**: Always write DOWN migrations for reversibility

## Monitoring and Alerts

### Vercel Analytics

**Metrics**:
- Time to Interactive (TTI) - Target: <2.5s (p75)
- First Contentful Paint (FCP) - Target: <1.5s
- Largest Contentful Paint (LCP) - Target: <2.5s
- Error rate - Target: <1%

**Alerts**:
- TTI >3s for 5 minutes → Slack #incidents
- Error rate >1% for 5 minutes → PagerDuty

### Supabase Logs

**Metrics**:
- Query performance (p95 latency)
- Connection pool usage
- Error rates by table
- RLS policy violations

**Alerts**:
- p95 latency >500ms → Slack #backend
- RLS violations detected → Immediate escalation (email + Slack)
- Connection pool >80% → Slack #backend

### Sentry Error Tracking

**Metrics**:
- Error count by severity
- Affected users count
- Error frequency trends
- Stack traces with context

**Alerts**:
- New error type introduced → Slack #dev
- Error spike (>100 in 5 minutes) → PagerDuty
- Critical error → Immediate escalation

### OCR Service Monitoring

**Metrics**:
- P95 processing time - Target: <30s
- Success rate - Target: >95%
- Confidence score distribution
- Uptime - Target: 99.9%

**Alerts**:
- P95 >45s for 10 minutes → Slack #backend
- Success rate <90% for 5 minutes → PagerDuty
- Service down → Immediate escalation

**Health Check**: `https://ocr.insightpulseai.net/health`

**Monitoring Script** (cron every 5 minutes):
```bash
#!/bin/bash
RESPONSE=$(curl -sf --max-time 10 https://ocr.insightpulseai.net/health)
if [ $? -ne 0 ]; then
  echo "❌ OCR service health check failed"
  # Send PagerDuty alert
  curl -X POST https://events.pagerduty.com/v2/enqueue \
    -H "Content-Type: application/json" \
    -d '{"routing_key":"'$PAGERDUTY_KEY'","event_action":"trigger","payload":{"summary":"OCR service down","severity":"critical"}}'
fi
```

## Security Standards

### Secrets Management

**Never** commit secrets to git. Use environment variables and secret managers.

**Vercel Secrets**:
```bash
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
```

**DigitalOcean Secrets** (environment variables in docker-compose):
```yaml
environment:
  OCR_API_KEY: ${OCR_API_KEY}
  SUPABASE_URL: ${SUPABASE_URL}
```

**Supabase Vault** (for PII):
```sql
INSERT INTO vault.secrets (secret, name)
VALUES ('sensitive_value', 'stripe_api_key');
```

### TLS/SSL

**Web Frontend**: Vercel provides automatic TLS (Let's Encrypt)

**OCR Microservice**: NGINX + Certbot
```bash
certbot --nginx -d ocr.insightpulseai.net \
  --non-interactive --agree-tos \
  --email admin@insightpulseai.net
```

**Auto-Renewal**: Certbot timer renews certificates automatically
```bash
systemctl status certbot.timer
```

### Firewall

**DigitalOcean Droplet**:
```bash
# Allow SSH (port 22)
ufw allow 22/tcp

# Allow HTTP (port 80) - redirects to HTTPS
ufw allow 80/tcp

# Allow HTTPS (port 443)
ufw allow 443/tcp

# DENY direct access to port 8000 (internal only)
ufw deny 8000/tcp

# Enable firewall
ufw enable
```

**Verification**:
```bash
ufw status
```

## Cost Management

**Monthly Budget**: <$20 USD

**Breakdown**:
- Supabase Free Tier: $0 (up to 500MB database)
- Vercel Hobby: $0 (free tier)
- DigitalOcean Droplet: $12 (s-2vcpu-4gb, Singapore)
- DigitalOcean Container Registry: $5 (basic tier)
- DigitalOcean Spaces: $0 (included with DOCR)
- **Total**: $17/month

**Cost Monitoring**:
- DigitalOcean: Set billing alerts at $15, $20
- Vercel: Monitor usage dashboard, upgrade to Pro if needed ($20/month)
- Supabase: Monitor database size, upgrade to Pro if >500MB ($25/month)

## References

- Product Vision: [/spec/00-product-vision.md](../spec/00-product-vision.md)
- Technical Architecture: [/plan/architecture.md](./architecture.md)
- Technology Stack: [/plan/stack.md](./stack.md)
- Constitution: [/constitution.md](../constitution.md)
