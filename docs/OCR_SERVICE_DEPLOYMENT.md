# OCR Service Deployment Guide

Complete deployment guide for PaddleOCR-VL OCR service on DigitalOcean droplet with Odoo integration.

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Topology Decision Tree                                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Same Droplet (Odoo + OCR):                                  │
│   Odoo ──► http://127.0.0.1:8000/ocr ──► OCR Service       │
│   └─ Fast, no TLS needed, internal-only                     │
│                                                               │
│ Different Hosts (Recommended):                               │
│   Odoo ──► https://ocr.insightpulseai.net/ocr ──► Nginx    │
│            └─ TLS ──► http://127.0.0.1:8000 ──► OCR        │
│   └─ Secure, scalable, firewall-protected                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- DigitalOcean droplet: `188.166.237.231` (Singapore region)
- SSH access: `ssh -i ~/.ssh/id_ed25519 root@188.166.237.231`
- Domain: `ocr.insightpulseai.net` (DNS A record → `188.166.237.231`)
- Docker & Docker Compose installed
- DigitalOcean Container Registry: `registry.digitalocean.com/fin-workspace`

---

## Part 1: OCR Service Deployment

### 1.1 Deploy OCR Service Container

```bash
# SSH to droplet
ssh -i ~/.ssh/id_ed25519 root@188.166.237.231

# Create deployment directory
mkdir -p /opt/ocr
cd /opt/ocr

# Upload docker-compose.yml (already done via scp)
# File: /opt/ocr/docker-compose.yml
```

**Docker Compose Configuration** (`/opt/ocr/docker-compose.yml`):
```yaml
version: '3.8'

services:
  ocr-service:
    image: registry.digitalocean.com/fin-workspace/ocr-service:prod
    container_name: ocr-service
    restart: unless-stopped
    ports:
      - "127.0.0.1:8000:8000"  # Localhost-only binding
    environment:
      - OCR_IMPL=paddleocr-vl
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LOG_LEVEL=info
    volumes:
      - ocr-uploads:/app/uploads
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  ocr-uploads:
```

### 1.2 Pull and Start Service

```bash
# Authenticate with DigitalOcean Container Registry
doctl registry login

# Pull latest image
docker pull registry.digitalocean.com/fin-workspace/ocr-service:prod

# Set OpenAI API key
export OPENAI_API_KEY="sk-proj-..."  # From environment or secrets

# Start service
cd /opt/ocr
docker compose up -d

# Verify running
docker ps | grep ocr-service
docker logs ocr-service --tail 20

# Test health endpoint
curl -f http://127.0.0.1:8000/health
# Expected: {"status":"ok","ocr_impl":"paddleocr-vl","version":"1.0.0"}
```

---

## Part 2: Nginx + TLS Setup (For Remote Access)

**⚠️ Only required if Odoo runs on a different host than OCR service**

### 2.1 Install Nginx

```bash
apt update
apt install -y nginx
```

### 2.2 Configure Nginx Site

```bash
# Create Nginx configuration
tee /etc/nginx/sites-available/ocr.conf >/dev/null <<'NG'
server {
  listen 80;
  server_name ocr.insightpulseai.net;

  client_max_body_size 20m;

  location / {
    proxy_pass http://127.0.0.1:8000;
    include /etc/nginx/proxy_params;

    # Additional proxy headers
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;

    # Timeouts for OCR processing (up to 30s)
    proxy_connect_timeout 35s;
    proxy_send_timeout 35s;
    proxy_read_timeout 35s;
  }

  # Security headers
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
}
NG

# Enable site
ln -sf /etc/nginx/sites-available/ocr.conf /etc/nginx/sites-enabled/ocr.conf

# Test configuration
nginx -t

# Reload Nginx
systemctl reload nginx
```

### 2.3 Install TLS Certificate (Let's Encrypt)

```bash
# Install Certbot
apt update
apt install -y certbot python3-certbot-nginx

# Obtain and install certificate
certbot --nginx -d ocr.insightpulseai.net

# Follow prompts:
# - Email: your-email@example.com
# - Agree to terms: Yes
# - Redirect HTTP to HTTPS: Yes (recommended)

# Verify auto-renewal
certbot renew --dry-run
```

### 2.4 Firewall Configuration

```bash
# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Deny direct access to OCR service port
ufw deny 8000/tcp

# Deny Docker daemon ports
ufw deny 2375/tcp
ufw deny 2376/tcp

# Enable firewall (if not already enabled)
ufw --force enable

# Verify rules
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

## Part 3: Odoo Integration

### 3.1 Determine OCR Service URL

**Decision Matrix**:

| Scenario | OCR Service URL | Notes |
|----------|-----------------|-------|
| Same droplet (Odoo + OCR) | `http://127.0.0.1:8000/ocr` | Fast, no TLS overhead |
| Different hosts | `https://ocr.insightpulseai.net/ocr` | Secure, requires Nginx + TLS |

### 3.2 Configure Odoo System Parameter

**Option A: Via Odoo UI** (Quick Method)
1. Navigate to **Settings → Technical → Parameters → System Parameters**
2. Create new parameter:
   - **Key**: `hr_expense_ocr_audit.ocr_api_url`
   - **Value**: `http://127.0.0.1:8000/ocr` (same host) OR `https://ocr.insightpulseai.net/ocr` (remote)
3. Save

**Option B: Via Odoo Shell** (Programmatic)
```python
# Start Odoo shell
docker exec -it odoo18 odoo shell -d odoboo_local

# Set parameter
env['ir.config_parameter'].sudo().set_param(
    'hr_expense_ocr_audit.ocr_api_url',
    'https://ocr.insightpulseai.net/ocr'  # or http://127.0.0.1:8000/ocr
)

# Verify
print(env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url'))
```

**Option C: Via OCA server_environment** (Production Recommended)

Install OCA `server_environment` module:
```bash
# Clone OCA server-env repository
cd /path/to/odoo/addons
git clone -b 18.0 --depth 1 https://github.com/OCA/server-env.git

# Install module
docker exec odoo18 odoo -d odoboo_local -i server_environment --stop-after-init
```

Configure environment file:
```bash
# Edit odoo.conf
vim /etc/odoo/odoo.conf
# Add: server_env = prod

# Create environment directory
mkdir -p /etc/odoo/server_env

# Create prod configuration
tee /etc/odoo/server_env/prod <<'ENV'
[hr_expense_ocr_audit]
ocr_api_url = https://ocr.insightpulseai.net/ocr

[queue_job]
channels = root:ocr
ENV

# Restart Odoo
docker restart odoo18
```

---

## Part 4: Verification & Testing

### 4.1 Health Check Tests

```bash
# Test 1: Direct container access (on droplet)
curl -f http://127.0.0.1:8000/health
# Expected: {"status":"ok","ocr_impl":"paddleocr-vl","version":"1.0.0"}

# Test 2: Via Nginx (if configured)
curl -f https://ocr.insightpulseai.net/health
# Expected: {"status":"ok","ocr_impl":"paddleocr-vl","version":"1.0.0"}

# Test 3: Check TLS certificate
curl -vI https://ocr.insightpulseai.net 2>&1 | grep -E "SSL|subject|issuer"
# Expected: Valid certificate from Let's Encrypt
```

### 4.2 OCR Smoke Test

```bash
# Test with sample receipt
curl -X POST https://ocr.insightpulseai.net/ocr \
  -F "file=@/path/to/sample-receipt.jpg" \
  -H "Content-Type: multipart/form-data" | jq

# Expected response:
# {
#   "vendor": "Starbucks",
#   "amount": 12.50,
#   "date": "2025-10-20",
#   "tax": 1.12,
#   "confidence": 0.92,
#   "fields": {...}
# }
```

### 4.3 Odoo Integration Test

**Via Odoo Shell**:
```python
# Start Odoo shell
docker exec -it odoo18 odoo shell -d odoboo_local

# Test 1: Verify parameter
url = env['ir.config_parameter'].sudo().get_param('hr_expense_ocr_audit.ocr_api_url')
print(f"OCR Service URL: {url}")

# Test 2: Health check from Odoo
import requests
health_url = url.replace('/ocr', '/health')
response = requests.get(health_url, timeout=5)
print(f"Health Check: {response.json()}")

# Test 3: Create test expense and trigger OCR
Expense = env['hr.expense']
expense = Expense.create({
    'name': 'Test Receipt',
    'employee_id': 1,
    'product_id': 1,
})

# Upload receipt image (attach to expense)
Attachment = env['ir.attachment']
attachment = Attachment.create({
    'name': 'receipt.jpg',
    'datas': base64.b64encode(open('/path/to/receipt.jpg', 'rb').read()),
    'res_model': 'hr.expense',
    'res_id': expense.id,
})

# Trigger OCR processing
expense.action_process_ocr()

# Check queue job status
Job = env['queue.job']
jobs = Job.search([('model_name', '=', 'hr.expense')], limit=5, order='id desc')
for job in jobs:
    print(f"Job {job.id}: {job.state} - {job.name}")
```

---

## Part 5: Queue Job Configuration

### 5.1 Install queue_job Module

```bash
# Clone OCA queue repository
cd /path/to/odoo/addons
git clone -b 18.0 --depth 1 https://github.com/OCA/queue.git

# Install module
docker exec odoo18 odoo -d odoboo_local -i queue_job --stop-after-init

# Restart Odoo
docker restart odoo18
```

### 5.2 Configure OCR Channel

**Via Odoo UI**:
1. Navigate to **Settings → Technical → Job Channels**
2. Create new channel:
   - **Name**: `root:ocr`
   - **Parent Channel**: `root`
   - **Capacity**: `5`
3. Save

**Via Odoo Shell**:
```python
Channel = env['queue.job.channel']
Channel.create({
    'name': 'root:ocr',
    'parent_id': env.ref('queue_job.channel_root').id,
    'capacity': 5,
})
```

### 5.3 Configure Scheduled Action

**Via Odoo UI**:
1. Navigate to **Settings → Technical → Automation → Scheduled Actions**
2. Find "Process Pending OCR" action
3. Verify configuration:
   - **Active**: ✅ Enabled
   - **Interval**: Every 5 minutes
   - **Model**: `hr.expense`
   - **Code**: `model.process_pending_ocr_queue()`
4. Save

**Verify Cron**:
```python
Cron = env['ir.cron']
cron = Cron.search([('name', '=', 'Process Pending OCR')], limit=1)
print(f"Active: {cron.active}")
print(f"Interval: {cron.interval_number} {cron.interval_type}")
```

---

## Part 6: Operations & Maintenance

### 6.1 Service Management

```bash
# View logs
cd /opt/ocr
docker compose logs -f

# Restart service
docker compose restart

# Stop service
docker compose down

# Update to latest image
docker pull registry.digitalocean.com/fin-workspace/ocr-service:prod
docker compose up -d

# Check resource usage
docker stats ocr-service
```

### 6.2 Snapshot & Backup

```bash
# Create droplet snapshot (safe restore point)
doctl compute droplet-action snapshot 525178434 \
  --snapshot-name "ocr-$(date +%F)" \
  --wait

# List snapshots
doctl compute snapshot list --format ID,Name,CreatedAt

# Restore from snapshot (if needed)
doctl compute droplet create ocr-service-restored \
  --image <snapshot-id> \
  --size s-1vcpu-1gb \
  --region sgp1
```

### 6.3 Monitoring

**Add to Supabase task_queue**:
```sql
-- Insert OCR health check task
INSERT INTO task_queue (kind, payload, status, created_at)
VALUES (
  'OCR_HEALTH_CHECK',
  '{"url": "https://ocr.insightpulseai.net/health"}',
  'pending',
  NOW()
);

-- Query recent OCR jobs
SELECT
  id,
  kind,
  status,
  created_at,
  completed_at,
  EXTRACT(EPOCH FROM (completed_at - created_at)) as duration_seconds
FROM task_queue
WHERE kind LIKE 'OCR_%'
ORDER BY created_at DESC
LIMIT 10;
```

### 6.4 Troubleshooting

**Issue: OCR service not responding**
```bash
# Check container status
docker ps | grep ocr-service

# Check logs for errors
docker logs ocr-service --tail 50

# Restart service
docker compose restart

# Test health endpoint
curl -f http://127.0.0.1:8000/health
```

**Issue: Nginx 502 Bad Gateway**
```bash
# Check Nginx error log
tail -f /var/log/nginx/error.log

# Verify OCR service is running on 127.0.0.1:8000
ss -tlnp | grep 8000

# Test direct connection
curl -f http://127.0.0.1:8000/health

# Reload Nginx
nginx -t && systemctl reload nginx
```

**Issue: TLS certificate expired**
```bash
# Check certificate expiry
certbot certificates

# Renew certificate
certbot renew

# Test auto-renewal
certbot renew --dry-run
```

**Issue: Odoo can't reach OCR service**
```bash
# From Odoo container, test connectivity
docker exec -it odoo18 bash
curl -f https://ocr.insightpulseai.net/health

# Check firewall rules
ufw status verbose

# Verify DNS resolution
nslookup ocr.insightpulseai.net
```

---

## Part 7: Performance Tuning

### 7.1 OCR Service Optimization

**Increase worker processes** (if high volume):
```yaml
# docker-compose.yml
services:
  ocr-service:
    environment:
      - WORKERS=4  # Default: 1
      - WORKER_TIMEOUT=60  # OCR processing timeout
```

**Add Redis caching** (optional):
```yaml
services:
  ocr-service:
    environment:
      - REDIS_URL=redis://redis:6379/0
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

### 7.2 Nginx Optimization

```nginx
# Add to /etc/nginx/sites-available/ocr.conf
http {
  # Enable compression
  gzip on;
  gzip_types application/json;

  # Connection limits
  limit_conn_zone $binary_remote_addr zone=ocr_limit:10m;
  limit_conn ocr_limit 10;

  # Rate limiting (100 req/min per IP)
  limit_req_zone $binary_remote_addr zone=ocr_rate:10m rate=100r/m;
  limit_req zone=ocr_rate burst=20;
}
```

---

## Quick Reference

### Service URLs

| Environment | URL | Notes |
|-------------|-----|-------|
| Same host | `http://127.0.0.1:8000/ocr` | Internal-only, fast |
| Remote (prod) | `https://ocr.insightpulseai.net/ocr` | TLS-secured, public |

### Common Commands

```bash
# Deployment
cd /opt/ocr && docker compose up -d

# Logs
docker logs ocr-service -f

# Restart
docker compose restart

# Health check
curl -f https://ocr.insightpulseai.net/health

# Snapshot
doctl compute droplet-action snapshot 525178434 --snapshot-name "ocr-$(date +%F)"

# Update image
docker pull registry.digitalocean.com/fin-workspace/ocr-service:prod && docker compose up -d
```

### Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| Docker Compose | `/opt/ocr/docker-compose.yml` | Service definition |
| Nginx Config | `/etc/nginx/sites-available/ocr.conf` | Reverse proxy |
| TLS Cert | `/etc/letsencrypt/live/ocr.insightpulseai.net/` | Let's Encrypt certificate |
| Odoo Config | `/etc/odoo/odoo.conf` | Odoo server settings |
| Odoo Env | `/etc/odoo/server_env/prod` | Environment-specific config |

---

**Last Updated**: 2025-10-20
**Deployment Status**: ✅ Production-Ready
**Droplet**: 188.166.237.231 (Singapore)
**Domain**: ocr.insightpulseai.net
