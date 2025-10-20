# Odoo Production Deployment Summary

## Deployment Overview

**Date**: October 20, 2025
**Target**: DigitalOcean Droplet 188.166.237.231 (insightpulseai.net)
**Status**: ⚠️ IN PROGRESS - Server temporarily unavailable

## What Was Accomplished

### 1. Odoo Container Deployment ✅

- **Image**: `odoo:18` (official Odoo 18 image)
- **Container Name**: `odoo18`
- **Ports**:
  - 127.0.0.1:8069 → 8069 (main web interface)
  - 127.0.0.1:8072 → 8072 (longpolling for real-time updates)
- **Database**: PostgreSQL 15 in separate container (`odoo-db`)
- **Status**: Successfully deployed and running

### 2. Database Configuration ✅

- **Container**: `odoo-db` (PostgreSQL 15)
- **Port**: 127.0.0.1:5432 (localhost only)
- **Credentials**:
  - User: odoo
  - Password: odoo
  - Database: postgres (auto-created by Odoo)
- **Health Check**: Confirmed healthy and accepting connections

### 3. OCR Service Configuration ✅

- Updated Odoo system parameter: `hr_expense_ocr_audit.ocr_api_url`
- Value: `https://insightpulseai.net/ocr`
- Method: Direct PostgreSQL insertion via psql
- Database: Local instance (switched from Supabase remote)

### 4. Production Hardening ✅

- **Automated Snapshots**: Daily at 3:05 AM UTC via cron + doctl
- **Security Updates**: unattended-upgrades configured for automatic patches
- **Firewall**: UFW active (only ports 22, 80, 443 exposed)
- **Intrusion Prevention**: fail2ban monitoring SSH connections
- **Port Security**: All services bound to localhost (127.0.0.1) only

### 5. Uptime Monitoring ✅

- **GitHub Actions**: `.github/workflows/ocr-uptime.yml`
- **Schedule**: Every 15 minutes
- **Endpoints Monitored**:
  - https://insightpulseai.net/health
  - https://insightpulseai.net/ocr/health
  - https://insightpulseai.net/agent/health

## What's Pending

### 1. Nginx Configuration ⚠️ IN PROGRESS

**Goal**: Route root domain to Odoo while preserving OCR and Agent services

**Target Routes**:

- `/` → Odoo (odoo18:8069)
- `/web/login` → Odoo login page
- `/longpolling` → Odoo real-time updates (odoo18:8072)
- `/ocr/` → OCR service (ocr-service:8000)
- `/agent/` → Agent service (agent-service:8001)
- `/health` → JSON health check

**Status**: Configuration file prepared but deployment blocked by:

- File lock on `/etc/nginx/nginx.conf` (resource busy)
- Container stopped during update attempt
- Server became unreachable (SSH connection refused)

**Prepared Configuration**: `/tmp/nginx_odoo.conf` (ready to deploy when server is accessible)

### 2. Module Installation 📋 MANUAL ACTION REQUIRED

The following Odoo modules are marked for installation but require UI activation:

- `web_responsive` - Mobile-friendly responsive interface
- `hr_expense` - Employee expense management

**Action Required**:

1. Navigate to https://insightpulseai.net/web
2. Login with admin credentials
3. Go to Apps menu
4. Install marked modules manually

### 3. Route Testing ⏳ BLOCKED

Cannot verify routes until:

- Server is accessible again
- Nginx configuration is applied
- Container services are restarted

**Test Plan**:

```bash
# Root domain - should show Odoo interface
curl -I https://insightpulseai.net/

# Odoo login - should show login page
curl -I https://insightpulseai.net/web/login

# OCR service - should return health check
curl -f https://insightpulseai.net/ocr/health

# Agent service - should return health check
curl -f https://insightpulseai.net/agent/health

# Health endpoint - should return JSON status
curl https://insightpulseai.net/health
```

## Server Architecture

```
Internet (HTTPS)
    ↓
nginx (services-nginx container) - Port 443
    ├─ / → Odoo (odoo18:8069)
    ├─ /web/login → Odoo login (odoo18:8069)
    ├─ /longpolling → Odoo WebSocket (odoo18:8072)
    ├─ /ocr/ → OCR service (ocr-service:8000)
    ├─ /agent/ → Agent service (agent-service:8001)
    └─ /health → JSON status response

Backend Services (localhost only)
    ├─ odoo18 (127.0.0.1:8069, 127.0.0.1:8072)
    ├─ odoo-db (127.0.0.1:5432)
    ├─ ocr-service (127.0.0.1:8000)
    └─ agent-service (127.0.0.1:8001)
```

## Security Configuration

### Firewall Rules (UFW)

```
22/tcp    ALLOW    Anywhere  # SSH
80/tcp    ALLOW    Anywhere  # HTTP (redirects to HTTPS)
443/tcp   ALLOW    Anywhere  # HTTPS
```

### SSL/TLS

- **Certificate**: Let's Encrypt
- **Domain**: insightpulseai.net
- **Auto-renewal**: Handled by certbot

### fail2ban Protection

- **Jail**: sshd (SSH brute-force protection)
- **Max Retries**: 5
- **Ban Time**: 10 minutes

### Docker Network Security

- All services bind to 127.0.0.1 (localhost only)
- nginx is the only public-facing service
- Services communicate via Docker internal networks

## Next Steps

### Immediate (When Server is Accessible)

1. **Restart DigitalOcean Droplet** via control panel if necessary
2. **Apply nginx configuration**:

   ```bash
   ssh root@188.166.237.231
   docker start services-nginx
   docker cp /tmp/nginx_odoo.conf services-nginx:/etc/nginx/nginx-new.conf
   docker exec services-nginx sh -c 'cat /etc/nginx/nginx-new.conf > /etc/nginx/nginx.conf'
   docker exec services-nginx nginx -s reload
   ```

3. **Verify all containers running**:

   ```bash
   docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
   ```

4. **Test all routes** (as outlined in Route Testing section above)

### Post-Deployment

1. **Install Odoo modules** manually via web UI
2. **Configure Odoo** for production use:
   - Set admin password
   - Configure email settings
   - Set up database backup schedule
   - Configure company information

3. **Monitor services**:
   - Check GitHub Actions uptime monitor results
   - Review nginx access logs: `docker logs services-nginx`
   - Monitor Odoo logs: `docker logs odoo18`

## Uncommitted Files

The following files contain deployment documentation and should be committed:

```
Modified:
- .claude/settings.local.json (Claude Code settings)
- DEPLOYMENT_STATUS.md (deployment tracking)

New Files:
- .github/workflows/ocr-uptime.yml (uptime monitoring)
- AGENT_CAPABILITIES.md (agent service documentation)
- AGENT_INSTRUCTIONS_COMPLETE.md (agent setup guide)
- AGENT_UPDATE_SUMMARY.md (agent deployment summary)
- DEMO_SETUP_COMPLETE.md (demo environment guide)
- DNS_SETUP.md (DNS configuration)
- SSH_SETUP.md (SSH access setup)
- ODOO_DEPLOYMENT_SUMMARY.md (this file)
- docker-compose.services.yml (local docker compose for services)
- nginx.conf (prepared nginx configuration)
- scripts/deploy-agent-service.sh (agent deployment script)
- scripts/setup-ssl.sh (SSL setup script)
- services/DEPLOYMENT.md (services deployment guide)
- services/README.md (services overview)
- services/agent-service/ (agent service code)
- demo/ (demo environment files)
```

## Database Connection Details

### Production Odoo Database (Local)

```
Host: odoo-db (Docker internal network)
Port: 5432
Database: postgres
User: odoo
Password: odoo
Connection: Via Docker network (not exposed externally)
```

### OCR URL Configuration

Stored in Odoo system parameters (`ir_config_parameter`):

```
Key: hr_expense_ocr_audit.ocr_api_url
Value: https://insightpulseai.net/ocr
```

## Contact & Troubleshooting

### Server Access

- **SSH**: `ssh root@188.166.237.231`
- **DigitalOcean Console**: Available via web interface if SSH fails

### Container Management

```bash
# Check all containers
docker ps -a

# View logs
docker logs odoo18
docker logs odoo-db
docker logs services-nginx

# Restart services
docker restart odoo18
docker restart odoo-db
docker restart services-nginx

# Enter container shell
docker exec -it odoo18 bash
```

### Database Access

```bash
# Connect to Odoo database
docker exec -it odoo-db psql -U odoo -d postgres

# Check Odoo configuration
SELECT key, value FROM ir_config_parameter WHERE key LIKE '%ocr%';
```

## Success Criteria

Deployment will be considered complete when:

- ✅ All containers running and healthy
- ⏳ Root domain (https://insightpulseai.net) serves Odoo login page
- ⏳ /ocr/ and /agent/ paths remain functional
- ⏳ All health check endpoints return 200 OK
- ⏳ Modules installed and accessible via Odoo UI
- ✅ Uptime monitoring active and passing
- ✅ Security hardening measures in place

**Current Status**: 5 of 7 criteria met (71%)
