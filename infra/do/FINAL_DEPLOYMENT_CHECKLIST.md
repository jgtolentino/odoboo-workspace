# OCR Service - Final Deployment Checklist

**Date**: 2025-10-20
**Droplet**: 188.166.237.231 (ID: 525178434, Singapore)
**Domain**: ocr.insightpulseai.net
**Registry**: registry.digitalocean.com/fin-workspace

---

## ✅ Pre-Deployment Status

- [x] App Platform `odoboo-ocr-service` deleted
- [x] Deployment scripts created and tested
- [x] Docker Compose config with localhost-only binding (127.0.0.1:8000)
- [x] NGINX config with 60s timeout and 10MB upload limit
- [ ] **AMD64 build completing** (PyTorch 670.2 MB downloading)

---

## 🚀 Deployment Sequence (Execute When Build Completes)

### Step 1: Verify Build Completion

```bash
# Check if build finished
docker images | grep ocr-service

# Should see:
# ocr-service    amd64    <image-id>    <timestamp>    ~2.5GB
```

### Step 2: Tag and Push to Registry

```bash
cd services/ocr-service

# Tag with immutable SHA
GIT_SHA=$(git rev-parse --short HEAD)
docker tag ocr-service:amd64 registry.digitalocean.com/fin-workspace/ocr-service:prod
docker tag ocr-service:amd64 registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA

# Login and push
doctl registry login
docker push registry.digitalocean.com/fin-workspace/ocr-service:prod
docker push registry.digitalocean.com/fin-workspace/ocr-service:sha-$GIT_SHA
```

**IMPORTANT**: You won't see `:amd64` tag in DOCR - buildx embeds arch in manifest.

### Step 3: Verify AMD64 Architecture

```bash
# Verify architecture in manifest
docker buildx imagetools inspect registry.digitalocean.com/fin-workspace/ocr-service:prod | grep 'linux/amd64'

# Expected output:
#   Platform: linux/amd64
```

### Step 4: Deploy on Droplet

```bash
# Upload docker-compose file
scp -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 \
  infra/do/docker-compose-droplet.yml \
  root@188.166.237.231:/opt/ocr/docker-compose.yml

# SSH and deploy
ssh root@188.166.237.231

# On droplet:
cd /opt/ocr
doctl registry login
docker compose -f docker-compose.yml pull
docker compose -f docker-compose.yml up -d

# Wait and test
sleep 10
curl -f http://localhost:8000/health

# Expected: {"status":"ok"}
```

### Step 5: Lock Down Firewall

```bash
# Still on droplet
ufw allow 80,443/tcp
ufw deny 8000/tcp

# Enable firewall (if not already)
echo "y" | ufw enable

# Verify
ufw status

# Expected:
# To                         Action      From
# --                         ------      ----
# 80,443/tcp                 ALLOW       Anywhere
# 8000/tcp                   DENY        Anywhere
```

### Step 6: Configure Odoo (Temporary HTTP)

**In Odoo UI**:
1. Navigate to: Settings → Technical → System Parameters
2. Create/Update Parameter:
   - **Key**: `hr_expense_ocr_audit.ocr_api_url`
   - **Value**: `http://188.166.237.231:8000/ocr`

**Note**: This is temporary HTTP access. Will switch to HTTPS after DNS + TLS setup.

---

## 🌐 DNS + TLS Setup (Optional but Recommended)

### Step 7: Configure DNS in Squarespace

**In Squarespace → Domains → DNS Settings**:

Add DNS record:
- **Type**: A
- **Host**: `ocr`
- **Value**: `188.166.237.231`
- **TTL**: Auto

**Full domain**: `ocr.insightpulseai.net`

**Wait**: 5-10 minutes for DNS propagation

**Verify**:
```bash
dig +short ocr.insightpulseai.net A
# Should return: 188.166.237.231
```

### Step 8: Setup NGINX + TLS

```bash
# Upload NGINX config
scp -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 \
  infra/do/nginx-ocr.conf \
  root@188.166.237.231:/tmp/ocr.conf

# SSH to droplet
ssh root@188.166.237.231

# Install NGINX + Certbot
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Copy NGINX config
cp /tmp/ocr.conf /etc/nginx/sites-available/ocr
ln -sf /etc/nginx/sites-available/ocr /etc/nginx/sites-enabled/ocr

# Test and reload
nginx -t
systemctl reload nginx

# Get TLS certificate
certbot --nginx -d ocr.insightpulseai.net --non-interactive --agree-tos --email jgtolentino_rn@yahoo.com

# Verify HTTPS
curl -f https://ocr.insightpulseai.net/health | jq
```

### Step 9: Update Odoo to HTTPS

**In Odoo UI**:
1. Settings → Technical → System Parameters
2. Update Parameter:
   - **Key**: `hr_expense_ocr_audit.ocr_api_url`
   - **Value**: `https://ocr.insightpulseai.net/ocr`

---

## 🧪 Verification & Testing

### Health Check
```bash
# Internal (on droplet)
curl -f http://localhost:8000/health | jq

# External (after TLS setup)
curl -f https://ocr.insightpulseai.net/health | jq

# Expected: {"status":"ok"}
```

### OCR Smoke Test
```bash
# Prepare sample receipt
curl -F file=@sample-receipt.jpg http://localhost:8000/ocr | jq

# Expected: JSON with extracted fields (vendor, amount, date, confidence)
```

### Firewall Verification
```bash
# From local machine - should FAIL (expected behavior)
curl -f --max-time 5 http://188.166.237.231:8000/health

# Expected: Connection timed out or Connection refused
```

### Docker Logs
```bash
# On droplet
cd /opt/ocr
docker compose -f docker-compose.yml logs -f ocr
```

---

## 🔧 Troubleshooting

### Build Issues

**If PyTorch download is slow**:
```bash
# Stop current build
docker buildx stop

# Rebuild with plain logs
cd services/ocr-service
docker buildx build --platform linux/amd64 --progress=plain -t ocr-service:amd64 --load .
```

**Alternative: CPU-only PyTorch (smaller)**:
```dockerfile
# In requirements.txt, replace torch lines with:
--index-url https://download.pytorch.org/whl/cpu
torch==2.1.0
torchvision==0.16.0
```

### Deployment Issues

**Container won't start**:
```bash
# Check logs
docker compose -f docker-compose.yml logs ocr

# Check image architecture
docker inspect ocr-service | grep Architecture
# Should be: "Architecture": "amd64"
```

**Health endpoint fails**:
```bash
# Check if service is running
docker ps | grep ocr-service

# Check port binding
docker port ocr-service

# Test internal health
docker exec ocr-service curl -f http://localhost:8000/health
```

**Architecture mismatch**:
```bash
# Verify manifest
docker buildx imagetools inspect registry.digitalocean.com/fin-workspace/ocr-service:prod

# Should show:
# MediaType: application/vnd.oci.image.index.v1+json
# Manifests:
#   Name:      linux/amd64
```

---

## 📋 Post-Deployment Tasks

### 1. Setup Automated Snapshots
```bash
chmod +x infra/do/SNAPSHOT_AUTOMATION.sh
./infra/do/SNAPSHOT_AUTOMATION.sh cron

# Configured:
# - Daily snapshots at 3:05 AM
# - 7-day retention
# - Automatic cleanup
```

### 2. Install OCA Minimal Modules (Optional)
```bash
chmod +x scripts/download_oca_minimal.sh
./scripts/download_oca_minimal.sh

# Install 8 core modules:
# - web_responsive, server_environment, queue_job
# - web_pwa_oca, auditlog, storage_backend
# - web_environment_ribbon, module_auto_update
```

### 3. Test End-to-End OCR Flow
```bash
# 1. Upload receipt in Odoo Expenses
# 2. Check OCR extraction in expense form
# 3. Verify confidence scores
# 4. Review audit logs
```

---

## 🔐 Security Checklist

- [x] Port 8000 bound to localhost only (127.0.0.1:8000)
- [ ] UFW firewall configured (deny 8000, allow 80/443)
- [ ] TLS certificate installed (Let's Encrypt)
- [ ] NGINX reverse proxy configured
- [ ] Automated certificate renewal enabled
- [ ] Docker logs rotated (10MB max, 3 files)
- [ ] Daily automated snapshots scheduled
- [ ] Service restart policy: unless-stopped

---

## 📞 Quick Reference

**Droplet Access**:
```bash
ssh root@188.166.237.231
```

**Service Management**:
```bash
cd /opt/ocr
docker compose -f docker-compose.yml [pull|up|down|restart|logs]
```

**Registry Login**:
```bash
doctl registry login
```

**Health Check**:
```bash
curl -f http://localhost:8000/health
```

**Firewall Status**:
```bash
ufw status
```

**NGINX Status**:
```bash
systemctl status nginx
journalctl -u nginx -n 50
```

**TLS Certificate Renewal**:
```bash
certbot renew --dry-run
systemctl status certbot.timer
```

---

## 📊 Expected Results

**Build Metrics**:
- Image size: ~2.5 GB (AMD64)
- Build time: 25-35 minutes (PyTorch download dependent)
- Dependencies: 670.2 MB PyTorch + 125.7 MB PaddlePaddle + others

**Deployment Metrics**:
- Deployment time: 5-10 minutes
- Health check: <500ms response
- OCR processing: <30s per receipt (P95)
- Memory usage: ~500MB-1GB (with 2 workers)

**Security Status**:
- Port 8000: INTERNAL ONLY
- TLS: A+ rating (Let's Encrypt)
- Firewall: UFW active with strict rules
- Auto-renewal: Enabled via certbot.timer

---

## ✅ Deployment Complete

**Production Status**:
- OCR Service: https://ocr.insightpulseai.net
- Health Endpoint: https://ocr.insightpulseai.net/health
- Odoo Integration: https://ocr.insightpulseai.net/ocr
- Automated Backups: Daily snapshots with 7-day retention
- TLS: Valid Let's Encrypt certificate with auto-renewal

**Cost**:
- Droplet: $24/month (s-2vcpu-4gb, Singapore)
- Registry: $0 (starter plan - 500MB)
- **Total**: $24/month

**Next Milestone**: Optional App Platform landing site deployment
