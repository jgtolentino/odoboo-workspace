# Production Hardening Checklist

**10-Point Green-Light Checklist** for production-ready OCR service deployment.

---

## ✅ 1. Odoo URL Configuration

**Requirement**: Configure correct OCR service URL based on topology

**Same Host** (Odoo + OCR on same droplet):
```python
# Via Odoo UI: Settings → Technical → System Parameters
hr_expense_ocr_audit.ocr_api_url = http://127.0.0.1:8000/ocr
```

**Different Host** (Recommended - Odoo remote, OCR on droplet):
```bash
# Via server_environment
sudo tee -a /etc/odoo/server_env/prod <<'ENV'
[hr_expense_ocr_audit]
ocr_api_url = https://ocr.insightpulseai.net/ocr
ocr_secret = <paste from /etc/ocr/token>
ENV
```

**Verification**:
```python
# Odoo shell
url = env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url')
print(f"OCR URL: {url}")  # Should match topology
```

---

## ✅ 2. Firewall Configuration

**Requirement**: Secure droplet with UFW rules

**Implementation**:
```bash
# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Deny direct access to OCR service
ufw deny 8000/tcp

# Deny Docker daemon ports
ufw deny 2375/tcp
ufw deny 2376/tcp

# Enable firewall
ufw --force enable

# Verify
ufw status verbose
```

**Expected Output**:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
8000/tcp                   DENY        Anywhere
2375/tcp                   DENY        Anywhere
2376/tcp                   DENY        Anywhere
```

---

## ✅ 3. TLS Auto-Renewal

**Requirement**: Ensure Let's Encrypt certificates auto-renew

**Verification**:
```bash
# Test auto-renewal (dry run)
certbot renew --dry-run

# Expected output: "The dry run was successful."

# Check systemd timer exists
systemctl status certbot.timer

# Expected: active (running)
```

**Manual Renewal** (if needed):
```bash
certbot renew
systemctl reload nginx
```

**Certificate Check**:
```bash
# Check expiry date
certbot certificates

# Expected: Valid for ~90 days, auto-renews at <30 days
```

---

## ✅ 4. Bearer Token Authentication

**Requirement**: Secure OCR endpoints with token-based auth

### Step 1: Generate Secret

```bash
# Create secret directory
sudo mkdir -p /etc/ocr
sudo chmod 700 /etc/ocr

# Generate token
OCR_SECRET=$(openssl rand -hex 32)
echo "$OCR_SECRET" | sudo tee /etc/ocr/token >/dev/null
sudo chmod 600 /etc/ocr/token

# Display token (copy for Odoo config)
echo "== ODOO HEADER TO SEND =="
echo "X-OCR-Secret: $OCR_SECRET"
```

### Step 2: Nginx Configuration

```bash
# Global rate-limit zone
sudo tee /etc/nginx/conf.d/limits.conf >/dev/null <<'NG'
limit_req_zone $binary_remote_addr zone=ocr:10m rate=10r/s;
NG

# Update OCR vhost
sudo tee /etc/nginx/sites-available/ocr.conf >/dev/null <<'NG'
server {
  listen 80;
  server_name ocr.insightpulseai.net;
  client_max_body_size 20m;

  # Require client header to prevent public abuse
  set $bad_secret 1;
  if ($http_x_ocr_secret = "") { set $bad_secret 1; }
  if ($http_x_ocr_secret = "REPLACE_WITH_TOKEN") { set $bad_secret 0; }
  if ($bad_secret = 1) { return 401; }

  limit_req zone=ocr burst=20 nodelay;

  location / {
    # Inject bearer to upstream
    proxy_set_header Authorization "Bearer REPLACE_WITH_TOKEN";
    proxy_pass http://127.0.0.1:8000;
    include /etc/nginx/proxy_params;
  }
}
NG

# Replace placeholder with actual token
sudo sed -i "s|REPLACE_WITH_TOKEN|$(cat /etc/ocr/token)|g" /etc/nginx/sites-available/ocr.conf

# Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

### Step 3: FastAPI Bearer Validation

**File**: `services/ocr-service/app/main.py`

```python
import os
from fastapi import FastAPI, Header, HTTPException, UploadFile, File

OCR_TOKEN = os.getenv("OCR_TOKEN", "")

app = FastAPI()

def check_bearer(authorization: str | None):
    """Validate Bearer token from Nginx"""
    if not OCR_TOKEN:
        return  # No token required in dev
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    token = authorization.split(" ", 1)[1]
    if token != OCR_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid Bearer token")

@app.get("/health")
def health():
    return {"status": "ok", "service": "ocr-service", "model_loaded": True}

@app.post("/ocr")
async def process_ocr(
    file: UploadFile = File(...),
    authorization: str | None = Header(default=None)
):
    check_bearer(authorization)
    # ... existing OCR logic
```

### Step 4: Update Docker Compose

```yaml
# /opt/ocr/docker-compose.yml
services:
  ocr-service:
    environment:
      - OCR_TOKEN=${OCR_TOKEN}
    # ... rest of config
```

**Start with token**:
```bash
export OCR_TOKEN=$(cat /etc/ocr/token)
cd /opt/ocr
docker compose up -d
```

### Step 5: Odoo Configuration

**Via server_environment** (`/etc/odoo/server_env/prod`):
```ini
[hr_expense_ocr_audit]
ocr_api_url = https://ocr.insightpulseai.net/ocr
ocr_secret = <paste from /etc/ocr/token>
```

**In Odoo Module** (`models/hr_expense.py`):
```python
def _call_ocr_service(self, file_data):
    """Call OCR service with authentication"""
    url = self.env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url')
    secret = self.env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_secret')

    headers = {'X-OCR-Secret': secret}
    files = {'file': file_data}

    response = requests.post(url, headers=headers, files=files, timeout=30)
    response.raise_for_status()
    return response.json()
```

**Verification**:
```bash
# Test without token (should fail)
curl -X POST https://ocr.insightpulseai.net/ocr
# Expected: 401 Unauthorized

# Test with wrong token (should fail)
curl -X POST -H "X-OCR-Secret: wrong" https://ocr.insightpulseai.net/ocr
# Expected: 401 Unauthorized

# Test with correct token (should work)
curl -X POST -H "X-OCR-Secret: $(cat /etc/ocr/token)" https://ocr.insightpulseai.net/ocr
# Expected: 422 (missing file) or 200 (with file)
```

---

## ✅ 5. Rate Limiting

**Requirement**: Protect OCR endpoints from abuse

**Already configured in Step 4 above**:
```nginx
limit_req_zone $binary_remote_addr zone=ocr:10m rate=10r/s;
limit_req zone=ocr burst=20 nodelay;
```

**Configuration Details**:
- **Zone**: `ocr` with 10MB memory (~160K IPs)
- **Rate**: 10 requests/second per IP
- **Burst**: Allow up to 20 requests in burst
- **nodelay**: Process burst immediately (no queuing)

**Verification**:
```bash
# Test rate limit with ab (ApacheBench)
ab -n 30 -c 5 -H "X-OCR-Secret: $(cat /etc/ocr/token)" https://ocr.insightpulseai.net/health

# Should see some 503 Service Unavailable responses after burst exhausted
```

**Adjust if needed**:
```nginx
# Higher rate for production (20 req/s)
limit_req_zone $binary_remote_addr zone=ocr:10m rate=20r/s;

# Larger burst capacity (50 requests)
limit_req zone=ocr burst=50 nodelay;
```

---

## ✅ 6. Docker Log Rotation

**Requirement**: Prevent disk space exhaustion from container logs

**Implementation**:
```bash
# Create Docker daemon configuration
sudo tee /etc/docker/daemon.json >/dev/null <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3",
    "compress": "true"
  }
}
JSON

# Restart Docker daemon
sudo systemctl restart docker

# Restart OCR service
cd /opt/ocr
docker compose down
docker compose up -d
```

**Configuration Details**:
- **max-size**: 50MB per log file
- **max-file**: Keep 3 files (150MB total per container)
- **compress**: Compress rotated logs

**Nginx Log Rotation**:
```bash
# Verify logrotate exists
cat /etc/logrotate.d/nginx

# Should contain:
# /var/log/nginx/*.log {
#   daily
#   missingok
#   rotate 14
#   compress
#   delaycompress
#   notifempty
#   create 0640 www-data adm
#   sharedscripts
#   postrotate
#     [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
#   endscript
# }
```

**Verification**:
```bash
# Check current log sizes
docker inspect ocr-service | jq '.[0].HostConfig.LogConfig'

# Expected:
# {
#   "Type": "json-file",
#   "Config": {
#     "max-size": "50m",
#     "max-file": "3",
#     "compress": "true"
#   }
# }

# Check Nginx logs
ls -lh /var/log/nginx/
```

---

## ✅ 7. Database Backups

**Requirement**: Automated daily PostgreSQL backups to DigitalOcean Spaces

### Step 1: Install AWS CLI

```bash
sudo apt-get update
sudo apt-get install -y awscli
```

### Step 2: Configure Credentials

```bash
# Set DO Spaces credentials
export SPACES_REGION=sgp1
export SPACES_ENDPOINT=https://$SPACES_REGION.digitaloceanspaces.com
export SPACES_ACCESS_KEY="<your_access_key>"
export SPACES_SECRET_KEY="<your_secret_key>"

# Configure AWS CLI
aws configure set aws_access_key_id "$SPACES_ACCESS_KEY"
aws configure set aws_secret_access_key "$SPACES_SECRET_KEY"
aws configure set default.region "$SPACES_REGION"
```

### Step 3: Create Bucket with Retention

```bash
# Create bucket
BUCKET=ipai-odoo-backups
aws --endpoint-url "$SPACES_ENDPOINT" s3api create-bucket --bucket "$BUCKET" || true

# Set 7-day lifecycle policy
aws --endpoint-url "$SPACES_ENDPOINT" s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET" \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "expire7d",
      "Status": "Enabled",
      "Expiration": {"Days": 7},
      "Filter": {"Prefix": ""}
    }]
  }'
```

### Step 4: Configure PostgreSQL Auth

```bash
# Create .pgpass for non-interactive auth
echo "127.0.0.1:5432:odoo:odoo:${PGPASSWORD}" | sudo tee -a /root/.pgpass >/dev/null
sudo chmod 600 /root/.pgpass
```

### Step 5: Create Backup Script

```bash
sudo tee /usr/local/bin/odoo_pg_backup.sh >/dev/null <<'SH'
#!/usr/bin/env bash
set -euo pipefail

# Configuration from environment
DB="${DB_NAME:-odoo}"
USER="${DB_USER:-odoo}"
HOST="${DB_HOST:-127.0.0.1}"
PORT="${DB_PORT:-5432}"

# Timestamp
TS="$(date +%F_%H%M%S)"
FILE="/tmp/${DB}_$TS.sql.gz"

# Dump and compress
pg_dump -h "$HOST" -p "$PORT" -U "$USER" -d "$DB" \
  --format=plain \
  --no-owner \
  --no-privileges | gzip -9 > "$FILE"

# Upload to Spaces
aws --endpoint-url "${SPACES_ENDPOINT:-https://sgp1.digitaloceanspaces.com}" \
  s3 cp "$FILE" "s3://${SPACES_BUCKET:-ipai-odoo-backups}/odoo/${DB}/$TS.sql.gz" \
  --only-show-errors

# Cleanup local file
rm -f "$FILE"

echo "✅ Backup completed: s3://${SPACES_BUCKET}/odoo/${DB}/$TS.sql.gz"
SH

sudo chmod +x /usr/local/bin/odoo_pg_backup.sh
```

### Step 6: Configure Environment

```bash
sudo tee /etc/default/odoo_backup >/dev/null <<'E'
export SPACES_ENDPOINT=https://sgp1.digitaloceanspaces.com
export SPACES_BUCKET=ipai-odoo-backups
export DB_NAME=odoo
export DB_USER=odoo
export DB_HOST=127.0.0.1
export DB_PORT=5432
E
```

### Step 7: Install Cron Job

```bash
# Add to root crontab (daily at 03:20 AM)
(crontab -l 2>/dev/null; echo '20 3 * * * . /etc/default/odoo_backup && /usr/local/bin/odoo_pg_backup.sh >> /var/log/odoo_backup.log 2>&1') | crontab -

# Verify crontab
crontab -l | grep odoo_backup
```

### Step 8: Test Backup

```bash
# Run backup manually
. /etc/default/odoo_backup && /usr/local/bin/odoo_pg_backup.sh

# Verify upload to Spaces
aws --endpoint-url "$SPACES_ENDPOINT" s3 ls "s3://$SPACES_BUCKET/odoo/$DB_NAME/" | tail -5

# Check local log
tail -f /var/log/odoo_backup.log
```

**Restore Procedure**:
```bash
# Download latest backup
LATEST=$(aws --endpoint-url "$SPACES_ENDPOINT" s3 ls "s3://$SPACES_BUCKET/odoo/$DB_NAME/" | tail -1 | awk '{print $4}')
aws --endpoint-url "$SPACES_ENDPOINT" s3 cp "s3://$SPACES_BUCKET/odoo/$DB_NAME/$LATEST" /tmp/restore.sql.gz

# Restore
gunzip -c /tmp/restore.sql.gz | psql -h 127.0.0.1 -U odoo -d odoo_restore

# Cleanup
rm /tmp/restore.sql.gz
```

---

## ✅ 8. Monitoring & Alerts

**Requirement**: Health checks and queue backlog monitoring

### Health Check Monitoring

**Using UptimeRobot** (Free tier):
1. Create monitor: `https://ocr.insightpulseai.net/health`
2. Interval: 5 minutes
3. Alert on: HTTP status ≠ 200

**Using Supabase Edge Function**:
```sql
-- Create health_checks table
CREATE TABLE public.health_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service TEXT NOT NULL,
  status TEXT NOT NULL,
  response_time_ms INT,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert check
INSERT INTO health_checks (service, status, response_time_ms)
SELECT 'ocr-service', 'ok', 150;

-- Query recent failures
SELECT * FROM health_checks
WHERE status != 'ok'
AND checked_at > NOW() - INTERVAL '1 hour'
ORDER BY checked_at DESC;
```

### Queue Backlog Monitoring

**SQL Query**:
```sql
-- Check queue backlog
SELECT
  kind,
  status,
  COUNT(*) as count,
  MAX(created_at) as latest,
  MIN(created_at) as oldest,
  EXTRACT(EPOCH FROM (NOW() - MIN(created_at))) / 60 as age_minutes
FROM task_queue
WHERE status IN ('pending', 'processing')
GROUP BY kind, status
HAVING COUNT(*) > 10 OR EXTRACT(EPOCH FROM (NOW() - MIN(created_at))) / 60 > 5
ORDER BY age_minutes DESC;
```

**Alert Trigger**: Backlog > 10 items OR age > 5 minutes

**Via Supabase Edge Function** (cron every 5 minutes):
```typescript
// supabase/functions/monitor-queue/index.ts
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const { data, error } = await supabase
    .from('task_queue')
    .select('kind, status, created_at')
    .in('status', ['pending', 'processing'])

  if (error) throw error

  const backlog = data.length
  const oldestAge = data.length > 0 ?
    (Date.now() - new Date(data[0].created_at).getTime()) / 1000 / 60 : 0

  if (backlog > 10 || oldestAge > 5) {
    // Send alert (Slack, email, etc.)
    await fetch(Deno.env.get('SLACK_WEBHOOK_URL')!, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: `⚠️ OCR Queue Alert: ${backlog} items, oldest ${oldestAge.toFixed(0)} min`
      })
    })
  }

  return new Response(JSON.stringify({ backlog, oldestAge }))
})
```

---

## ✅ 9. Immutable Image Deployment

**Requirement**: Deploy with git SHA tags, maintain `:prod` pointer

### Build with SHA Tag

```bash
# Get current git SHA
cd services/ocr-service
GIT_SHA=$(git rev-parse --short HEAD)

# Build and push with both tags
docker buildx build \
  --platform linux/amd64 \
  -t registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA \
  -t registry.digitalocean.com/fin-workspace/ocr-service:prod \
  --push .

# Verify architecture
docker manifest inspect registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA \
  | jq -r '.manifests[].platform.architecture'
# Expected: amd64
```

### Update Docker Compose

```yaml
# /opt/ocr/docker-compose.yml
services:
  ocr-service:
    image: registry.digitalocean.com/fin-workspace/ocr-service:sha-b218fcb  # Use SHA tag
    # OR
    image: registry.digitalocean.com/fin-workspace/ocr-service:prod  # Use prod pointer
```

### Deployment Process

```bash
# 1. Build with SHA
GIT_SHA=$(git rev-parse --short HEAD)
docker buildx build --platform linux/amd64 \
  -t registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA \
  --push services/ocr-service

# 2. Test SHA deployment
ssh root@188.166.237.231
cd /opt/ocr
sed -i "s|:sha-.*|:sha-$GIT_SHA|" docker-compose.yml
docker compose pull
docker compose up -d

# 3. Verify health
curl -f https://ocr.insightpulseai.net/health

# 4. Update :prod pointer
docker tag registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA \
           registry.digitalocean.com/fin-workspace/ocr-service:prod
docker push registry.digitalocean.com/fin-workspace/ocr-service:prod
```

### Rollback Procedure

```bash
# Rollback to previous SHA
PREVIOUS_SHA=a3f2e1c
cd /opt/ocr
sed -i "s|:sha-.*|:sha-$PREVIOUS_SHA|" docker-compose.yml
docker compose pull
docker compose up -d
```

---

## ✅ 10. Odoo Module Installation Order

**Requirement**: Install modules in correct dependency order

### Installation Script

```bash
#!/bin/bash
set -e

DB="odoboo_local"
MODULES=(
  "web_responsive"
  "server_environment"
  "queue_job"
  "hr_expense_ocr_audit"
  "auditlog"
  "web_pwa_oca"
  "storage_backend"
  "web_environment_ribbon"
)

for MODULE in "${MODULES[@]}"; do
  echo "Installing: $MODULE"
  docker exec odoo18 odoo -d "$DB" -i "$MODULE" --stop-after-init \
    --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
done

echo "Restarting Odoo..."
docker restart odoo18

echo "✅ All modules installed successfully"
```

### Manual Installation

```bash
# 1. web_responsive (UI framework)
docker exec odoo18 odoo -d odoboo_local -i web_responsive --stop-after-init

# 2. server_environment (config management)
docker exec odoo18 odoo -d odoboo_local -i server_environment --stop-after-init

# 3. queue_job (async processing)
docker exec odoo18 odoo -d odoboo_local -i queue_job --stop-after-init

# 4. hr_expense_ocr_audit (OCR module)
docker exec odoo18 odoo -d odoboo_local -i hr_expense_ocr_audit --stop-after-init

# 5. auditlog (change tracking)
docker exec odoo18 odoo -d odoboo_local -i auditlog --stop-after-init

# 6. web_pwa_oca (Progressive Web App)
docker exec odoo18 odoo -d odoboo_local -i web_pwa_oca --stop-after-init

# 7. storage_backend (file storage)
docker exec odoo18 odoo -d odoboo_local -i storage_backend --stop-after-init

# 8. web_environment_ribbon (environment indicator)
docker exec odoo18 odoo -d odoboo_local -i web_environment_ribbon --stop-after-init

# Restart Odoo
docker restart odoo18
```

### Verification

```python
# Odoo shell
docker exec -it odoo18 odoo shell -d odoboo_local

# Check installed modules
Module = env['ir.module.module']
required = ['web_responsive', 'server_environment', 'queue_job',
            'hr_expense_ocr_audit', 'auditlog', 'web_pwa_oca',
            'storage_backend', 'web_environment_ribbon']

for name in required:
    module = Module.search([('name', '=', name)])
    print(f"{name}: {module.state}")
    # Expected: installed
```

---

## Verification Matrix

| # | Check | Command | Expected |
|---|-------|---------|----------|
| 1 | Odoo URL | `env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url')` | `https://ocr.insightpulseai.net/ocr` |
| 2 | Firewall | `ufw status` | 80/443 allowed, 8000/2375/2376 denied |
| 3 | TLS | `certbot renew --dry-run` | "successful" |
| 4 | Auth | `curl -H "X-OCR-Secret: $(cat /etc/ocr/token)" https://ocr.insightpulseai.net/health` | `{"status":"ok"}` |
| 5 | Rate Limit | Check `/etc/nginx/conf.d/limits.conf` | `limit_req_zone` exists |
| 6 | Logs | `docker inspect ocr-service \| jq '.[0].HostConfig.LogConfig'` | `max-size: 50m` |
| 7 | Backups | `crontab -l \| grep odoo_backup` | Cron exists |
| 8 | Monitoring | `curl https://ocr.insightpulseai.net/health` | HTTP 200 |
| 9 | Image | `docker manifest inspect <image> \| jq '.manifests[].platform.architecture'` | `amd64` |
| 10 | Modules | Odoo UI → Apps | All 8 modules installed |

---

## Final Smoke Test

```bash
#!/bin/bash
set -e

echo "1. Firewall Check"
ufw status | grep -E "80|443|8000|2375|2376"

echo "2. TLS Check"
certbot renew --dry-run 2>&1 | grep -i success

echo "3. Health Check"
curl -f https://ocr.insightpulseai.net/health

echo "4. Auth Check"
curl -f -H "X-OCR-Secret: $(cat /etc/ocr/token)" https://ocr.insightpulseai.net/health

echo "5. Log Rotation Check"
docker inspect ocr-service | jq '.[0].HostConfig.LogConfig.Config."max-size"'

echo "6. Backup Check"
crontab -l | grep odoo_backup

echo "7. Image Architecture Check"
docker manifest inspect registry.digitalocean.com/fin-workspace/ocr-service:prod \
  | jq -r '.manifests[].platform.architecture'

echo "✅ All checks passed!"
```

---

**Status**: Production-Ready Checklist
**Last Updated**: 2025-10-20
**Next Review**: Before first production deployment
