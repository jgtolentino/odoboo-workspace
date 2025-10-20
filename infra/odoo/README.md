# Odoo Backend Deployment Guide

Complete production deployment for Odoo 18 with OCA modules and OCR integration.

## Architecture

```
Internet
    ↓
Nginx (443) + Let's Encrypt
    ↓
Odoo 18 (8069) + Longpolling (8072)
    ↓
PostgreSQL 15
    ⇄
OCR Service (188.166.237.231)
```

## Prerequisites

1. **DigitalOcean Account**
   - doctl CLI installed and authenticated
   - SSH key added to account

2. **DNS Configuration**
   - Domain pointed to your droplet IP (A record)
   - Example: `odoo.insightpulseai.net`

3. **OCR Service Running**
   - Deployed on separate droplet (188.166.237.231)
   - TLS endpoint: `https://ocr.insightpulseai.net/ocr`
   - Bearer token stored at `/etc/ocr/token`

## Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Set environment variables
export SSH_KEY_ID=$(doctl compute ssh-key list --format ID --no-header | head -1)
export ODOO_DOMAIN="odoo.insightpulseai.net"
export OCR_DROPLET_IP="188.166.237.231"

# Run deployment script
chmod +x infra/odoo/deploy.sh
./infra/odoo/deploy.sh
```

**Deployment Steps**:
1. Provisions DigitalOcean droplet (s-2vcpu-4gb, Singapore region)
2. Installs Docker + Docker Compose
3. Uploads configuration files
4. Generates secure passwords
5. Starts PostgreSQL + Odoo
6. Configures Let's Encrypt TLS
7. Clones OCA addons
8. Runs sanity checks

**Duration**: ~5-10 minutes

### Option 2: Manual Deployment

#### Step 1: Provision Droplet

```bash
doctl compute droplet create odoo-backend \
  --size s-2vcpu-4gb \
  --image ubuntu-24-04-x64 \
  --region sgp1 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --wait
```

#### Step 2: Install Dependencies

```bash
# SSH into droplet
DROPLET_IP=$(doctl compute droplet get odoo-backend --format PublicIPv4 --no-header)
ssh root@$DROPLET_IP

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

# Install Docker Compose
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install Certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx
```

#### Step 3: Upload Configuration

```bash
# From your local machine
mkdir -p /opt/odoo/{config,addons,oca}
scp infra/odoo/docker-compose.yml root@$DROPLET_IP:/opt/odoo/
scp infra/odoo/.env.sample root@$DROPLET_IP:/opt/odoo/.env
scp infra/odoo/config/odoo.conf root@$DROPLET_IP:/opt/odoo/config/
scp infra/odoo/nginx.conf root@$DROPLET_IP:/opt/odoo/
```

#### Step 4: Configure Environment

```bash
# On droplet
cd /opt/odoo

# Generate passwords
DB_PASSWORD=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 32)

# Update .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" .env
sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=$ADMIN_PASSWORD|" .env

# Get OCR secret
OCR_SECRET=$(ssh root@188.166.237.231 "cat /etc/ocr/token")
sed -i "s|OCR_SECRET=.*|OCR_SECRET=$OCR_SECRET|" .env

echo "Admin password: $ADMIN_PASSWORD"  # Save this!
```

#### Step 5: Start Services

```bash
cd /opt/odoo

# Start database and Odoo first
docker compose up -d db odoo

# Wait for health check
until docker compose exec -T odoo curl -sf http://localhost:8069/web/health; do
  sleep 5
done
```

#### Step 6: Configure TLS

```bash
# Obtain Let's Encrypt certificate
certbot certonly --standalone -d odoo.insightpulseai.net \
  --non-interactive --agree-tos --email admin@insightpulseai.net

# Start Nginx
docker compose up -d nginx
```

#### Step 7: Clone OCA Addons

```bash
cd /opt/odoo/oca

git clone -b 18.0 --depth 1 https://github.com/OCA/web.git
git clone -b 18.0 --depth 1 https://github.com/OCA/server-tools.git
git clone -b 18.0 --depth 1 https://github.com/OCA/queue.git
git clone -b 18.0 --depth 1 https://github.com/OCA/social.git
git clone -b 18.0 --depth 1 https://github.com/OCA/project.git

# Restart Odoo
cd /opt/odoo
docker compose restart odoo
```

## Module Installation

### Method 1: Via UI (Recommended)

1. Navigate to `https://odoo.insightpulseai.net`
2. Create database with admin credentials
3. Go to **Apps** → **Update Apps List**
4. Install modules in order:
   - `web_responsive` (OCA)
   - `queue_job` (OCA)
   - `knowledge` (core)
   - `project` (core)
   - `hr_expense` (core)
   - `hr_expense_ocr_audit` (custom)

### Method 2: CLI Installation

```bash
ssh root@$DROPLET_IP
cd /opt/odoo

# Install base modules
docker compose exec odoo odoo \
  -d production \
  -i knowledge,project,hr_expense,queue_job,web_responsive \
  --stop-after-init

# Restart Odoo
docker compose restart odoo
```

### Module Installation Order (with Dependencies)

```bash
# Phase 1: Base dependencies
queue_job  # OCA - background job processing

# Phase 2: Core functionality
knowledge  # Odoo core - knowledge base
project    # Odoo core - project management
hr_expense # Odoo core - expense tracking

# Phase 3: UI enhancements
web_responsive  # OCA - mobile-friendly UI

# Phase 4: Custom integrations
hr_expense_ocr_audit  # Custom - OCR expense processing
```

## OCR Integration Configuration

### Step 1: Configure System Parameters

Navigate to: **Settings** → **Technical** → **System Parameters**

Add the following parameters:

| Key | Value | Description |
|-----|-------|-------------|
| `ocr.api.url` | `https://ocr.insightpulseai.net/ocr` | OCR service endpoint |
| `ocr.api.secret` | `[from .env OCR_SECRET]` | Bearer token for authentication |
| `ocr.confidence.threshold` | `0.60` | Minimum confidence for auto-approval |
| `ocr.processing.timeout` | `30` | Max processing time (seconds) |

### Step 2: Configure Queue Jobs

1. Go to **Settings** → **Technical** → **Job Channels**
2. Create new channel: `ocr` with priority `5`
3. Configure worker assignment:
   - Default channel: 1 worker
   - OCR channel: 1 worker

### Step 3: Test OCR Integration

1. Create a test expense: **Expenses** → **New Expense**
2. Upload a receipt image
3. Click **Process with OCR** button
4. Verify fields populated: vendor, amount, date, tax
5. Check confidence score in **OCR Audit** tab

## Verification & Smoke Tests

### Health Checks

```bash
# Odoo health endpoint
curl -sf https://odoo.insightpulseai.net/web/health
# Expected: {"status":"ok"}

# Database connection
ssh root@$DROPLET_IP
cd /opt/odoo
docker compose exec db psql -U odoo -d postgres -c "SELECT version();"

# Odoo logs
docker compose logs odoo --tail 50
```

### OCR Service Connectivity

```bash
# From Odoo container
docker compose exec odoo curl -sf \
  -H "Authorization: Bearer $OCR_SECRET" \
  -F "file=@/tmp/sample_receipt.jpg" \
  https://ocr.insightpulseai.net/ocr
```

### Queue Job Processing

```bash
# Check queue jobs
ssh root@$DROPLET_IP
cd /opt/odoo
docker compose exec db psql -U odoo -d production -c \
  "SELECT COUNT(*) FROM queue_job WHERE state='done' AND created_at > NOW() - INTERVAL '1 hour';"
```

## Operations

### Start/Stop Services

```bash
# Stop all
docker compose down

# Start all
docker compose up -d

# Restart Odoo only
docker compose restart odoo

# View logs
docker compose logs -f odoo
```

### Database Backups

```bash
# Manual backup
docker compose exec db pg_dump -U odoo production > backup_$(date +%Y%m%d).sql

# Automated daily backups (cron)
echo "0 2 * * * cd /opt/odoo && docker compose exec -T db pg_dump -U odoo production | gzip > /backups/odoo_\$(date +\%Y\%m\%d).sql.gz" | crontab -
```

### TLS Certificate Renewal

```bash
# Manual renewal
certbot renew --nginx

# Verify auto-renewal
systemctl status certbot.timer
```

### Update OCA Modules

```bash
cd /opt/odoo/oca
for repo in web server-tools queue social project; do
  cd $repo
  git pull origin 18.0
  cd ..
done

docker compose restart odoo
```

## Troubleshooting

### Odoo Won't Start

```bash
# Check logs
docker compose logs odoo --tail 100

# Common issues:
# - Database connection: Check DB_PASSWORD in .env matches docker-compose.yml
# - Port conflict: Ensure 8069, 8072 not already in use
# - Memory: Upgrade droplet size if OOM errors
```

### Nginx 502 Bad Gateway

```bash
# Check Odoo health
docker compose exec odoo curl -sf http://localhost:8069/web/health

# Restart Odoo
docker compose restart odoo

# Check Nginx logs
docker compose logs nginx --tail 50
```

### OCR Integration Failing

```bash
# Test OCR service directly
curl -sf https://ocr.insightpulseai.net/health

# Check OCR secret matches
ssh root@188.166.237.231 "cat /etc/ocr/token"
# Compare with OCR_SECRET in /opt/odoo/.env

# Check Odoo system parameters
# Settings → Technical → System Parameters → ocr.api.*
```

### Queue Jobs Stuck

```bash
# Identify stuck jobs
docker compose exec db psql -U odoo -d production -c \
  "SELECT id, name, state, date_created FROM queue_job WHERE state='started' AND date_created < NOW() - INTERVAL '5 minutes';"

# Restart queue job workers
docker compose restart odoo
```

## Performance Tuning

### Worker Configuration

Edit `config/odoo.conf`:

```ini
# For 4GB droplet (s-2vcpu-4gb)
workers = 2
max_cron_threads = 1

# For 8GB droplet (s-4vcpu-8gb)
workers = 4
max_cron_threads = 2
```

### Database Connection Pool

Edit `docker-compose.yml`:

```yaml
services:
  odoo:
    environment:
      DB_MAXCONN: 128  # Increase for high traffic
```

### Nginx Caching

Edit `nginx.conf`:

```nginx
# Static files cache
location ~* /web/static/ {
    proxy_cache_valid 200 60m;
    expires 864000;
}
```

## Security Hardening

### Firewall Configuration

```bash
# Allow only necessary ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (redirect to HTTPS)
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Database Access

```bash
# Restrict PostgreSQL to localhost only
# docker-compose.yml already binds to 127.0.0.1
```

### Admin Password Rotation

```bash
# Generate new admin password
NEW_ADMIN_PASSWORD=$(openssl rand -base64 32)

# Update .env
sed -i "s|ADMIN_PASSWORD=.*|ADMIN_PASSWORD=$NEW_ADMIN_PASSWORD|" .env

# Restart Odoo
docker compose restart odoo
```

## Monitoring

### Health Checks

```bash
# Automated health check (cron every 5 minutes)
*/5 * * * * curl -sf https://odoo.insightpulseai.net/web/health || echo "Odoo health check failed" | mail -s "Alert: Odoo Down" admin@example.com
```

### Resource Monitoring

```bash
# Docker stats
docker stats --no-stream

# Disk usage
df -h
docker system df

# Memory usage
free -h
```

## Upgrade Path

### Odoo Version Upgrade (18.0 → 18.1)

```bash
# Backup first
docker compose exec db pg_dump -U odoo production > backup_before_upgrade.sql

# Update ODOO_TAG in .env
sed -i 's|ODOO_TAG=18.0|ODOO_TAG=18.1|' .env

# Pull new image and restart
docker compose pull odoo
docker compose up -d odoo
```

## Support

**Documentation**:
- Odoo Official: https://www.odoo.com/documentation/18.0/
- OCA Modules: https://github.com/OCA
- OCR Service: `docs/OCR_SERVICE_DEPLOYMENT.md`

**Common Issues**:
- See `docs/PRODUCTION_CHECKLIST.md` for hardening checklist
- See `docs/OCR_QUICKSTART.md` for OCR configuration

**Emergency Rollback**:
```bash
# Stop services
docker compose down

# Restore database
docker compose up -d db
docker compose exec -T db psql -U odoo -d postgres -c "DROP DATABASE production;"
docker compose exec -T db psql -U odoo -d postgres -c "CREATE DATABASE production;"
docker compose exec -T db psql -U odoo -d production < backup_YYYYMMDD.sql

# Restart all
docker compose up -d
```
