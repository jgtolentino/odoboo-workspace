# CapRover Self-Hosting Guide

**CapRover**: Free, open-source PaaS (Platform as a Service) - Heroku/Vercel alternative with web UI

**Repository**: https://github.com/caprover/caprover

---

## Why CapRover?

### vs. Supabase Cloud
| Feature | CapRover | Supabase Cloud Free |
|---------|----------|-------------------|
| **Cost** | $6/month (DO droplet) | $0 (500MB limit) |
| **Apps** | Unlimited | 2 projects |
| **Database** | Unlimited | 500MB |
| **Storage** | Unlimited | 1GB |
| **Deployments** | Unlimited | Unlimited |
| **Custom Domains** | Free (unlimited) | $0.01/GB egress |
| **Docker Support** | ✅ Native | ❌ Edge Functions only |

### vs. DigitalOcean App Platform
| Feature | CapRover | DO App Platform |
|---------|----------|-----------------|
| **Cost** | $6/month | $5/app/month |
| **Multi-App** | Unlimited apps | 1 app = $5 |
| **Web UI** | ✅ Full dashboard | ✅ DO Console |
| **Git Deploy** | ✅ Auto-deploy | ✅ Auto-deploy |
| **Database** | Self-hosted PostgreSQL | Separate $15/month |

**Winner**: CapRover = $6/month for unlimited apps + databases vs DO App Platform = $5/app + $15/database

---

## Architecture

```
CapRover on DigitalOcean Droplet ($6/month)
├── Captain Dashboard (Web UI)
│   └── https://captain.your-domain.com
├── Apps (Unlimited)
│   ├── ade-ocr-backend.your-domain.com
│   ├── expense-flow-api.your-domain.com
│   ├── atomic-crm.your-domain.com
│   └── supabase.your-domain.com (self-hosted)
├── Databases
│   ├── PostgreSQL (multiple instances)
│   ├── MongoDB
│   ├── MySQL
│   └── Redis
└── Storage
    ├── Persistent volumes
    └── Backups to DO Spaces
```

---

## Installation

### Prerequisites

**DigitalOcean Droplet**:
- Ubuntu 22.04 LTS
- 2GB RAM minimum ($6/month droplet)
- 1 vCPU
- 50GB SSD
- Static IP address

**Domain Requirements**:
- Root domain: `your-domain.com`
- Wildcard DNS: `*.your-domain.com` → Droplet IP
- SSL: Automatic via Let's Encrypt

### Step 1: Create DigitalOcean Droplet

```bash
# Via doctl CLI
doctl compute droplet create caprover-prod \
  --image ubuntu-22-04-x64 \
  --size s-1vcpu-2gb \
  --region sgp1 \
  --enable-monitoring \
  --enable-ipv6 \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header | head -n 1)

# Get droplet IP
doctl compute droplet list caprover-prod --format PublicIPv4 --no-header
# Output: 188.166.XXX.XXX
```

**Via DO Console**:
1. Create Droplets → Ubuntu 22.04
2. Basic Plan → Regular CPU → $6/month
3. Choose Singapore datacenter
4. Add SSH key
5. Enable monitoring + IPv6
6. Create Droplet

### Step 2: Configure DNS

**Cloudflare** (or your DNS provider):

```
Type: A
Name: @
Content: 188.166.XXX.XXX (droplet IP)
Proxy: OFF (DNS only)

Type: A
Name: *
Content: 188.166.XXX.XXX (droplet IP)
Proxy: OFF (DNS only)
```

**Verify DNS**:
```bash
dig captain.your-domain.com +short
# Should return: 188.166.XXX.XXX
```

### Step 3: Install CapRover

**SSH into droplet**:
```bash
ssh root@188.166.XXX.XXX
```

**Run installer**:
```bash
# Install Docker (if not present)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install CapRover
docker run -p 80:80 -p 443:443 -p 3000:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /captain:/captain \
  -e ACCEPTED_TERMS=true \
  caprover/caprover

# Wait 60 seconds for CapRover to start
sleep 60

# Verify
curl http://localhost:3000
# Should return CapRover web interface
```

### Step 4: Initial Setup via Web UI

**Access Dashboard**:
```
URL: http://188.166.XXX.XXX:3000
Default Password: captain42
```

**Setup Wizard**:
1. **Email**: your-email@example.com
2. **Password**: Generate strong password (store in `~/.zshrc`)
3. **Root Domain**: `your-domain.com`
4. **Force HTTPS**: Enable after Let's Encrypt setup
5. **Enable NetData Monitoring**: Yes

**Add to `~/.zshrc`**:
```bash
# CapRover
export CAPROVER_URL=https://captain.your-domain.com
export CAPROVER_PASSWORD="generated-strong-password"
export CAPROVER_DOMAIN="your-domain.com"
```

### Step 5: Install CapRover CLI

```bash
# Install globally
npm install -g caprover

# Login
caprover login

# Prompts:
# CapRover URL: https://captain.your-domain.com
# Password: [your password]
# Name: production

# Verify
caprover list
```

---

## Deploy Applications

### Example 1: Deploy Node.js App (ade-ocr-backend)

**Create `captain-definition` file**:
```json
{
  "schemaVersion": 2,
  "dockerfileLines": [
    "FROM node:18-alpine",
    "WORKDIR /app",
    "COPY package*.json ./",
    "RUN npm ci --only=production",
    "COPY . .",
    "EXPOSE 8080",
    "CMD [\"npm\", \"start\"]"
  ]
}
```

**Deploy**:
```bash
# Create app in CapRover dashboard or CLI
caprover api --path /user/apps/appDefinitions/register \
  --method POST \
  --data '{"appName":"ade-ocr-backend","hasPersistentData":false}'

# Deploy from local directory
cd /path/to/ade-ocr-backend
caprover deploy --appName ade-ocr-backend

# Or deploy from Git
caprover deploy --appName ade-ocr-backend \
  --branch main \
  --repoUrl https://github.com/jgtolentino/ade-ocr-backend.git
```

**Configure Environment Variables** (via Dashboard):
1. Apps → ade-ocr-backend → App Configs
2. Add Environment Variables:
   ```
   OPENAI_API_KEY=sk-...
   SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...
   ```
3. Enable HTTPS
4. Add custom domain: `ade-ocr.your-domain.com`

### Example 2: Deploy PostgreSQL Database

**One-Click Apps** (via Dashboard):
1. Apps → One-Click Apps/Databases
2. Search: PostgreSQL
3. Click Install
4. Configure:
   ```
   App Name: postgres-main
   Postgres Version: 15
   Postgres Password: [generate strong password]
   Persistent Data: Yes (enable)
   ```
5. Install

**Connect from Apps**:
```
Host: srv-captain--postgres-main
Port: 5432
Database: postgres
Username: postgres
Password: [your password]
```

### Example 3: Self-Host Supabase on CapRover

**Clone Supabase**:
```bash
git clone https://github.com/supabase/supabase
cd supabase/docker
```

**Create `captain-definition`**:
```json
{
  "schemaVersion": 2,
  "dockerfileLines": [
    "FROM supabase/postgres:15",
    "# CapRover will handle docker-compose services separately"
  ]
}
```

**Alternative: Use CapRover's Docker Compose Support**:
1. Apps → Create New App → `supabase`
2. Enable "Has Persistent Data"
3. Deployment → Method → "I will upload my source via tarball"
4. Upload `supabase/docker` directory
5. CapRover auto-detects `docker-compose.yml`

**Access**:
```
Supabase Studio: https://supabase.your-domain.com
API: https://supabase.your-domain.com/rest/v1
Postgres: srv-captain--supabase:5432
```

---

## Migration from Current Stack

### Phase 1: Setup CapRover (No Downtime)

```bash
# 1. Create droplet + install CapRover (30 min)
# 2. Deploy test app to verify
# 3. Keep current DO App Platform running
```

### Phase 2: Migrate ade-ocr-backend

```bash
# 1. Deploy to CapRover
caprover deploy --appName ade-ocr-backend

# 2. Configure same environment variables
# 3. Test: curl https://ade-ocr.your-domain.com/health
# 4. Update DNS to point to CapRover
# 5. Verify production traffic
# 6. Delete DO App Platform app
```

### Phase 3: Migrate Database (if self-hosting)

```bash
# 1. Install PostgreSQL on CapRover
# 2. Backup Supabase Cloud
pg_dump "$SUPABASE_URL/postgres" > backup.sql

# 3. Restore to CapRover PostgreSQL
psql -h srv-captain--postgres-main -U postgres < backup.sql

# 4. Update app connection strings
# 5. Test thoroughly before switching
```

### Phase 4: Cost Comparison

**Before (Current Stack)**:
```
Supabase Cloud: $0 (free tier)
DO App Platform (ade-ocr-backend): $5/month
DO App Platform (expense-flow-api): $5/month
Vercel (frontend): $0 (free tier)
---
Total: $10/month
```

**After (CapRover)**:
```
DO Droplet (2GB): $6/month
CapRover: $0 (open source)
All apps: $0 (unlimited)
PostgreSQL: $0 (self-hosted)
---
Total: $6/month (40% savings)
```

**At Scale**:
```
5 apps + 2 databases
Current: $25 apps + $30 databases = $55/month
CapRover: $6/month droplet (93% savings)
```

---

## Advanced Configuration

### Auto-Deploy from GitHub

**Setup Webhook**:
1. CapRover Dashboard → Apps → ade-ocr-backend
2. Deployment → Enable Auto Deploy from GitHub
3. Copy webhook URL
4. GitHub → Settings → Webhooks → Add webhook
   ```
   Payload URL: https://captain.your-domain.com/api/v2/user/apps/webhooks/triggerbuild
   Content type: application/json
   Secret: [from CapRover]
   Events: Just the push event
   ```
5. Push to `main` branch → Auto-deploy

### Monitoring & Alerts

**NetData** (included):
```
URL: https://captain.your-domain.com/netdata
Metrics: CPU, RAM, Disk, Network
Real-time: Yes
```

**Uptime Monitoring**:
```bash
# Install UptimeRobot one-click app
# Or use external: UptimeRobot.com (free)
```

### Backups

**Database Backups to DO Spaces**:
```bash
# Install in CapRover
caprover api --path /user/apps/appDefinitions/register \
  --method POST \
  --data '{"appName":"backup-cron","hasPersistentData":false}'

# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -h srv-captain--postgres-main -U postgres > /backup/db_$TIMESTAMP.sql
s3cmd put /backup/db_$TIMESTAMP.sql s3://your-backup-bucket/
EOF

# Schedule cron job in CapRover
```

### SSL/TLS Configuration

**Let's Encrypt** (automatic):
1. Apps → ade-ocr-backend → HTTP Settings
2. Enable HTTPS
3. Force HTTPS
4. CapRover auto-generates SSL cert via Let's Encrypt
5. Auto-renewal every 90 days

---

## Comparison Table

| Feature | CapRover | Supabase Cloud | DO App Platform | Vercel |
|---------|----------|----------------|-----------------|--------|
| **Cost (starter)** | $6/month | $0 (limited) | $5/app | $0 (limited) |
| **Apps** | Unlimited | 2 projects | 1 app = $5 | Unlimited |
| **Database** | Self-hosted | 500MB | $15/month | External |
| **Storage** | Unlimited | 1GB | Separate | 100GB/month |
| **Custom Domain** | Free | Free | Free | Free |
| **Web UI** | ✅ Excellent | ✅ Excellent | ✅ Good | ✅ Excellent |
| **Git Deploy** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Docker** | ✅ Native | ❌ No | ✅ Yes | ❌ No |
| **One-Click Apps** | ✅ 50+ apps | ❌ No | ❌ No | ❌ No |
| **Monitoring** | ✅ NetData | ✅ Dashboard | ✅ Dashboard | ✅ Analytics |
| **Backups** | Manual/Cron | Auto | Auto | Auto |

---

## Production Checklist

### Security
- [ ] Change default CapRover password
- [ ] Enable firewall (UFW)
- [ ] Configure fail2ban
- [ ] Enable automatic security updates
- [ ] Use strong database passwords
- [ ] Store secrets in environment variables
- [ ] Enable HTTPS for all apps
- [ ] Configure CORS properly

### Monitoring
- [ ] Enable NetData
- [ ] Set up UptimeRobot (external monitoring)
- [ ] Configure alerts (email/Slack)
- [ ] Monitor disk usage
- [ ] Set up log aggregation

### Backups
- [ ] Database backups to DO Spaces (daily)
- [ ] Application data backups
- [ ] Test restore procedures
- [ ] Document recovery process
- [ ] Keep 30 days of backups

### Performance
- [ ] Enable HTTP/2
- [ ] Configure CDN (Cloudflare)
- [ ] Enable gzip compression
- [ ] Optimize Docker images
- [ ] Monitor resource usage

---

## Troubleshooting

### CapRover won't start
```bash
# Check Docker status
systemctl status docker

# Restart Docker
systemctl restart docker

# Check CapRover logs
docker logs captain-captain --tail 100

# Restart CapRover
docker restart captain-captain
```

### App deployment fails
```bash
# Check app logs
caprover logs --appName ade-ocr-backend --tail 100

# Check build logs in dashboard
# Apps → ade-ocr-backend → Deployment → View Logs

# Common issues:
# 1. Missing captain-definition file
# 2. Wrong Dockerfile syntax
# 3. Missing environment variables
# 4. Port not exposed (must expose port in Dockerfile)
```

### SSL certificate fails
```bash
# Verify DNS is correct
dig captain.your-domain.com +short

# Check Let's Encrypt rate limits
# Max 50 certs per domain per week

# Force SSL renewal
# Dashboard → Settings → Force SSL Renewal
```

### Out of disk space
```bash
# Clean Docker images
docker system prune -a

# Clean old deployments
# Dashboard → Apps → [app] → Deployment → Delete Old Images

# Resize droplet
doctl compute droplet-action resize DROPLET_ID --size s-2vcpu-4gb
```

---

## Next Steps

1. **Setup CapRover**: Create DO droplet + install CapRover (1 hour)
2. **Deploy Test App**: Verify everything works (30 min)
3. **Migrate ade-ocr-backend**: Move from DO App Platform (1 hour)
4. **Self-Host Supabase** (optional): Full control + unlimited usage (2 hours)
5. **Setup Backups**: Automate database backups to DO Spaces (1 hour)
6. **Monitor & Optimize**: Configure monitoring + alerts (1 hour)

**Total Time**: ~6 hours for complete setup
**Total Cost**: $6/month (vs current $10/month = 40% savings)

---

## Resources

- **CapRover Docs**: https://caprover.com/docs
- **GitHub**: https://github.com/caprover/caprover
- **Community**: https://github.com/caprover/caprover/discussions
- **One-Click Apps**: https://caprover.com/docs/one-click-apps.html
- **DigitalOcean**: https://www.digitalocean.com/products/droplets

---

**Generated**: 2025-10-19
**Stack**: CapRover + DigitalOcean + PostgreSQL + Node.js
**Status**: Production-ready deployment guide
