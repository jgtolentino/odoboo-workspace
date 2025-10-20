# OCR Service - Production Deployment Quickstart

**Status**: AMD64 build in progress
**Droplet**: 188.166.237.231 (ID: 525178434, Singapore)
**Registry**: registry.digitalocean.com/fin-workspace

---

## ✅ Pre-Deployment Checklist

### 1. Build Status
```bash
# Check if AMD64 build completed
docker images | grep ocr-service
# Expected: ocr-service:amd64 with recent timestamp
```

### 2. Prerequisites
- ✅ doctl CLI authenticated (`doctl auth list`)
- ✅ SSH key configured (`~/.ssh/id_ed25519`)
- ✅ Droplet running with Docker installed
- ✅ docker-compose-droplet.yml exists on droplet

---

## 🚀 Deployment Options

### Option A: Automated Production Deployment (Recommended)
```bash
chmod +x infra/do/DEPLOY_PRODUCTION.sh
./infra/do/DEPLOY_PRODUCTION.sh
```

**What it does**:
1. ✅ Tags with `:prod` + `:sha-<gitsha>` (immutable tags)
2. ✅ Pushes both tags to registry
3. ✅ Verifies AMD64 architecture
4. ✅ Optional pre-deployment snapshot (with service stop)
5. ✅ Deploys with explicit `-f docker-compose-droplet.yml`
6. ✅ Optional UFW firewall configuration (port 8000 internal only)
7. ✅ Tests health endpoint
8. ✅ Provides next steps summary

### Option B: Quick Manual Deployment
```bash
# 1. Tag and push
cd services/ocr-service
doctl registry login
docker tag ocr-service:amd64 registry.digitalocean.com/fin-workspace/ocr-service:prod
docker push registry.digitalocean.com/fin-workspace/ocr-service:prod

# 2. Deploy on droplet
ssh root@188.166.237.231
doctl registry login
cd /root
docker compose -f docker-compose-droplet.yml pull
docker compose -f docker-compose-droplet.yml up -d

# 3. Test health
curl -f http://localhost:8000/health
```

---

## 🔒 Security Hardening (Post-Deployment)

### Configure UFW Firewall
```bash
# SSH to droplet
ssh root@188.166.237.231

# Install UFW (if not installed)
apt-get update && apt-get install -y ufw

# Allow SSH (CRITICAL - do this first!)
ufw allow 22/tcp

# Allow HTTP/HTTPS (for NGINX later)
ufw allow 80/tcp
ufw allow 443/tcp

# DENY external access to port 8000
ufw deny 8000/tcp

# Enable firewall
echo "y" | ufw enable

# Verify configuration
ufw status
```

**Expected output**:
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
8000/tcp                   DENY        Anywhere
```

---

## 📋 Post-Deployment Tasks

### 1. Configure Odoo System Parameter
**Via Odoo UI**:
1. Navigate to: Settings → Technical → System Parameters
2. Create New Parameter:
   - **Key**: `hr_expense_ocr_audit.ocr_api_url`
   - **Value**: `http://188.166.237.231:8000/ocr`

**Via SQL** (alternative):
```bash
# Connect to Odoo database
docker exec -i postgres15 psql -U odoo -d odoboo_local << 'SQL'
INSERT INTO ir_config_parameter (key, value, create_date, write_date, create_uid, write_uid)
VALUES (
  'hr_expense_ocr_audit.ocr_api_url',
  'http://188.166.237.231:8000/ocr',
  NOW(),
  NOW(),
  1,
  1
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, write_date = NOW();
SQL
```

### 2. Install OCA Minimal Core Modules (8 essentials)
```bash
# Download OCA repositories
chmod +x scripts/download_oca_minimal.sh
./scripts/download_oca_minimal.sh

# Update odoo.conf
# Add to addons_path: oca-modules/web,oca-modules/server-tools,oca-modules/queue,oca-modules/storage

# Restart Odoo
docker-compose -f docker-compose.local.yml restart odoo

# Install via Apps UI or CLI:
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_responsive,server_environment,queue_job,web_pwa_oca,auditlog \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
```

**8 Core Modules**:
1. **web_responsive** (CRITICAL) - Mobile-friendly UI
2. **server_environment** (CRITICAL) - 12-factor config (OCR URL)
3. **queue_job** (CRITICAL) - Async OCR processing
4. **web_pwa_oca** (HIGH) - Progressive web app
5. **auditlog** (HIGH) - Audit trail for hr.expense
6. **storage_backend** (MEDIUM) - DO Spaces for receipts
7. **web_environment_ribbon** (MEDIUM) - DEV/TEST/PROD badge
8. **module_auto_update** (LOW) - Auto-update on deploy

### 3. Setup Automated Daily Snapshots
```bash
chmod +x infra/do/SNAPSHOT_AUTOMATION.sh
./infra/do/SNAPSHOT_AUTOMATION.sh cron

# This creates a cron job for daily snapshots at 3:05 AM
# With 7-day retention (automatic cleanup)
```

### 4. (Optional) Setup NGINX + TLS for HTTPS
```bash
# SSH to droplet
ssh root@188.166.237.231

# Install NGINX + Certbot
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Copy nginx config
# (create nginx-ocr.conf with reverse proxy to localhost:8000)

# Get TLS certificate
certbot --nginx -d your-domain.com

# Update Odoo parameter
# Key: hr_expense_ocr_audit.ocr_api_url
# Value: https://your-domain.com/ocr
```

---

## ✅ Verification

### Health Check
```bash
# Internal (on droplet)
curl -f http://localhost:8000/health | jq

# Expected output:
# {
#   "status": "ok",
#   "service": "ocr-service"
# }
```

### OCR Smoke Test
```bash
# Prepare sample receipt image
curl -F file=@sample-receipt.jpg http://localhost:8000/ocr | jq

# Expected: JSON with extracted fields (vendor, amount, date, confidence)
```

### Firewall Verification
```bash
# External test (from local machine)
curl -f --max-time 5 http://188.166.237.231:8000/health

# Should FAIL if firewall configured correctly
# Expected: "Connection timed out" or "Connection refused"
```

---

## 🔧 Maintenance

### View Logs
```bash
# SSH to droplet
ssh root@188.166.237.231
cd /root
docker compose -f docker-compose-droplet.yml logs --tail=50 ocr
```

### Update OCR Service
```bash
# Build new image locally (AMD64)
cd services/ocr-service
docker buildx build --platform linux/amd64 -t ocr-service:amd64 --load .

# Tag and push
docker tag ocr-service:amd64 registry.digitalocean.com/fin-workspace/ocr-service:prod
docker push registry.digitalocean.com/fin-workspace/ocr-service:prod

# Deploy on droplet
ssh root@188.166.237.231
doctl registry login
cd /root
docker compose -f docker-compose-droplet.yml pull
docker compose -f docker-compose-droplet.yml up -d
```

### Restart Service
```bash
ssh root@188.166.237.231
cd /root
docker compose -f docker-compose-droplet.yml restart ocr
```

### Rollback to Previous Snapshot
```bash
# List snapshots
./infra/do/SNAPSHOT_AUTOMATION.sh list

# Restore from snapshot
./infra/do/SNAPSHOT_AUTOMATION.sh restore <snapshot-id>
```

---

## 📊 Monitoring

### Service Status
```bash
# SSH to droplet
ssh root@188.166.237.231
docker compose -f docker-compose-droplet.yml ps
```

### Resource Usage
```bash
# SSH to droplet
ssh root@188.166.237.231
docker stats ocr-service
```

### Check Snapshots
```bash
doctl compute snapshot list --resource droplet | grep ocr
```

---

## 🚨 Troubleshooting

### Container Won't Start
```bash
# Check logs
docker compose -f docker-compose-droplet.yml logs ocr

# Check image architecture
docker inspect ocr-service | grep Architecture
# Should be: "Architecture": "amd64"
```

### Platform Mismatch Error
```bash
# Verify image architecture in registry
docker buildx imagetools inspect registry.digitalocean.com/fin-workspace/ocr-service:prod | grep "linux/amd64"

# If not AMD64, rebuild:
cd services/ocr-service
docker buildx build --platform linux/amd64 -t ocr-service:amd64 --load .
```

### Health Endpoint Fails
```bash
# Check if service is running
docker ps | grep ocr-service

# Check port binding
docker port ocr-service

# Test internal health
docker exec ocr-service curl -f http://localhost:8000/health
```

### Firewall Issues
```bash
# SSH to droplet
ssh root@188.166.237.231

# Check firewall status
ufw status

# Check if port 8000 is listening
netstat -tlnp | grep 8000

# Test internal access
curl -f http://localhost:8000/health
```

---

## 📞 Support

**Documentation**:
- Production Deployment: [infra/do/DEPLOY_PRODUCTION.sh](DEPLOY_PRODUCTION.sh)
- Snapshot Automation: [infra/do/SNAPSHOT_AUTOMATION.sh](SNAPSHOT_AUTOMATION.sh)
- Full Deployment Guide: [infra/do/DEPLOYMENT_COMMANDS.sh](DEPLOYMENT_COMMANDS.sh)
- OCA Module Guide: [docs/OCA_MINIMAL_CORE.md](../../docs/OCA_MINIMAL_CORE.md)

**Configuration**:
- Droplet ID: 525178434
- IP: 188.166.237.231
- Region: Singapore (sgp1)
- Size: s-2vcpu-4gb
- Image: ubuntu-20-04-x64-docker

**Cost**:
- Droplet: $24/month (s-2vcpu-4gb)
- Registry: $0 (starter plan - 500MB)
- Total: $24/month

**Next Major Milestone**: NGINX + TLS configuration for HTTPS access
