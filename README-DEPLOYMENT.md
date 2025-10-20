# Odoo 18.0 + OCA Enterprise Deployment Guide

Complete deployment guide for Odoo 18.0 with OCA modules on DigitalOcean.

## Table of Contents

- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Production Deployment](#production-deployment)
- [Configuration](#configuration)
- [Post-Deployment](#post-deployment)
- [Troubleshooting](#troubleshooting)
- [Cost Estimates](#cost-estimates)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/jgtolentino/odoboo-workspace.git
cd odoboo-workspace
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your credentials
nano .env
```

### 3. Deploy

```bash
# Local development
./scripts/deploy.sh local

# Production (choose one)
./scripts/deploy.sh app       # App Platform (managed)
./scripts/deploy.sh droplet   # Single Droplet
./scripts/deploy.sh terraform # Full infrastructure
```

## Deployment Options

### Option 1: App Platform (Recommended for Beginners)

**Pros:**
- ✅ Fully managed by DigitalOcean
- ✅ Auto-scaling capabilities
- ✅ Built-in CI/CD
- ✅ Zero-downtime deployments
- ✅ Easy rollbacks

**Cons:**
- ❌ Higher cost (~$35/month minimum)
- ❌ Less control over infrastructure

**Deploy:**
```bash
export DO_TOKEN="your_token"
export DOMAIN_NAME="odoo.yourdomain.com"
./scripts/deploy.sh app
```

### Option 2: Single Droplet (Best Value)

**Pros:**
- ✅ Lower cost (~$24/month)
- ✅ Full control
- ✅ Simple architecture

**Cons:**
- ❌ Manual scaling
- ❌ You manage updates

**Deploy:**
```bash
export DO_TOKEN="your_token"
export DOMAIN_NAME="odoo.yourdomain.com"
export SSH_KEY_ID="12345678"
./scripts/deploy.sh droplet
```

### Option 3: Terraform (Production-Grade)

**Pros:**
- ✅ Infrastructure as Code
- ✅ Version controlled infrastructure
- ✅ Load balancer + managed database
- ✅ High availability setup
- ✅ Automatic SSL certificates

**Cons:**
- ❌ Higher cost (~$56/month)
- ❌ More complex setup

**Deploy:**
```bash
cd terraform
terraform init
terraform plan -var="do_token=$DO_TOKEN" -var="domain_name=odoo.yourdomain.com"
terraform apply
```

### Option 4: Local Development

**For testing and development only.**

```bash
./scripts/deploy.sh local
```

Access at: http://localhost:8069

## Prerequisites

### Required Tools

Install these tools on your local machine:

```bash
# macOS (using Homebrew)
brew install doctl terraform docker docker-compose git

# Ubuntu/Debian
sudo apt install docker.io docker-compose git
snap install doctl terraform
```

### DigitalOcean Account Setup

1. **Create Account**: https://cloud.digitalocean.com/registrations/new
2. **Generate API Token**: https://cloud.digitalocean.com/account/api/tokens
3. **Add SSH Key**: https://cloud.digitalocean.com/account/security

### Domain Configuration (Optional but Recommended)

1. Register a domain (e.g., from Namecheap, Google Domains)
2. Point nameservers to DigitalOcean:
   - `ns1.digitalocean.com`
   - `ns2.digitalocean.com`
   - `ns3.digitalocean.com`

## Local Development

### Start Local Environment

```bash
# First time setup
./scripts/deploy.sh local

# View logs
docker-compose logs -f odoo

# Stop services
docker-compose down

# Restart services
docker-compose restart
```

### Access Odoo Locally

- **URL**: http://localhost:8069
- **Database**: `odoo`
- **Username**: `admin@admin.com`
- **Password**: `admin` (change on first login)

### Install OCA Modules

1. Access Odoo at http://localhost:8069
2. Go to **Apps** menu
3. Update Apps List
4. Search for OCA modules (e.g., "web responsive", "helpdesk")
5. Click **Install**

## Production Deployment

### Step 1: Prepare Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Required variables:**
```env
DO_TOKEN=dop_v1_abc123...
DOMAIN_NAME=odoo.example.com
ODOO_ADMIN_PASSWORD=strong_password_123
```

### Step 2: Choose Deployment Method

#### App Platform Deployment

```bash
# Authenticate
doctl auth init --access-token $DO_TOKEN

# Create app
doctl apps create --spec app.yaml --wait

# Get app URL
doctl apps list
```

#### Terraform Deployment

```bash
cd terraform

# Initialize
terraform init

# Review plan
terraform plan \
  -var="do_token=$DO_TOKEN" \
  -var="domain_name=odoo.example.com" \
  -var="admin_password=strong_password_123"

# Apply
terraform apply -auto-approve

# Get outputs
terraform output
```

### Step 3: Configure DNS

**After deployment, update DNS records:**

```bash
# Get load balancer IP
terraform output load_balancer_ip

# Add A record to your domain:
# Type: A
# Name: odoo (or @)
# Value: <load_balancer_ip>
# TTL: 300
```

### Step 4: SSL Certificate

**Automatic with Terraform** - Let's Encrypt certificate is provisioned automatically.

**Manual setup:**

```bash
ssh root@<droplet_ip>
certbot --nginx -d odoo.example.com
```

## Configuration

### Odoo Configuration

Edit `config/odoo.conf`:

```ini
[options]
admin_passwd = $pbkdf2-sha512$25000$your_hashed_password
db_host = your-db-host.db.ondigitalocean.com
db_port = 25060
db_user = odoo
db_password = your_db_password
```

### OCA Modules Configuration

Add/remove repositories in `scripts/download_oca_modules.sh`:

```bash
OCA_REPOS=(
    "web"
    "server-ux"
    "helpdesk"        # Add this
    "your-custom-repo" # Add custom repos
)
```

### Nginx Configuration

Edit `nginx/nginx.conf` for custom proxy settings.

## Post-Deployment

### Create First Database

1. Access Odoo: `https://odoo.example.com`
2. Create database:
   - Database Name: `production`
   - Email: `admin@example.com`
   - Password: Strong password
   - Language: English
   - Country: Your country
   - Demo data: NO (for production)

### Install Essential Modules

**Recommended first installs:**

1. **Web Responsive** (OCA/web) - Mobile-friendly interface
2. **Helpdesk** (OCA/helpdesk) - Customer support
3. **Project** (Core) - Project management
4. **Sales** (Core) - CRM and sales
5. **Accounting** (Core) - Financial management

### Configure Users and Permissions

1. Settings → Users & Companies → Users
2. Create users
3. Assign access rights
4. Configure email notifications

### Backup Configuration

**Automated backups with DigitalOcean:**

```bash
# Enable automatic database backups
doctl databases backups list <database-id>

# Create manual backup
doctl databases backups create <database-id>
```

**Manual backup:**

```bash
# Backup database
pg_dump -h db-host -U odoo -d odoo18 > backup.sql

# Backup filestore
tar -czf filestore-backup.tar.gz /var/lib/odoo/filestore
```

## Troubleshooting

### Deployment Issues

**App Platform deployment fails:**

```bash
# Check logs
doctl apps logs <app-id> --follow

# Check deployment status
doctl apps get <app-id>
```

**Terraform errors:**

```bash
# Enable debug logging
export TF_LOG=DEBUG

# Check state
terraform show

# Destroy and recreate
terraform destroy
terraform apply
```

### Runtime Issues

**Odoo won't start:**

```bash
# Check Docker logs
docker-compose logs -f odoo

# Restart services
docker-compose restart

# Check database connection
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

**Database connection errors:**

```bash
# Test database connectivity
nc -zv db-host.db.ondigitalocean.com 25060

# Check firewall rules
doctl compute firewall list
```

**OCA modules not appearing:**

```bash
# Re-download OCA modules
./scripts/download_oca_modules.sh

# Update apps list in Odoo
# Settings → Apps → Update Apps List
```

### Performance Issues

**Slow response times:**

1. **Check workers configuration** in `config/odoo.conf`:
   ```ini
   workers = 4  # Increase if needed
   ```

2. **Monitor resource usage:**
   ```bash
   doctl compute droplet get <droplet-id>
   ```

3. **Upgrade droplet size** if needed:
   ```bash
   doctl compute droplet-action resize <droplet-id> --size s-4vcpu-8gb
   ```

## Cost Estimates

### App Platform

| Component | Size | Cost/Month |
|-----------|------|------------|
| Odoo Service | Professional XS | $12 |
| Worker | Basic XXS | $5 |
| Managed DB | 1GB | $15 |
| **Total** | | **~$32/month** |

### Single Droplet

| Component | Size | Cost/Month |
|-----------|------|------------|
| Droplet | 2 vCPU, 4GB | $24 |
| Backups | Optional | $4.80 |
| **Total** | | **~$24-29/month** |

### Terraform (Production)

| Component | Size | Cost/Month |
|-----------|------|------------|
| Droplet | 2 vCPU, 4GB | $24 |
| Managed DB | 1GB | $15 |
| Spaces | 250GB | $5 |
| Load Balancer | Standard | $12 |
| **Total** | | **~$56/month** |

### Cost Optimization Tips

1. **Use smaller droplets** for testing ($6/month)
2. **Share database** across multiple apps
3. **Use Spaces** instead of local storage
4. **Enable backups** only for production
5. **Scale down** during off-hours (App Platform)

## GitHub Actions CI/CD

Automatic deployment on push to main:

1. **Add secrets** to GitHub repository:
   - `DIGITALOCEAN_ACCESS_TOKEN`
   - `ODOO_ADMIN_PASSWORD`
   - `DO_REGISTRY` (if using container registry)
   - `APP_ID` (if using App Platform)

2. **Add variables**:
   - `DOMAIN_NAME`

3. **Push to main branch** → automatic deployment

## Next Steps

1. ✅ **Secure your installation**
   - Change admin password
   - Enable 2FA
   - Configure firewall rules

2. ✅ **Setup monitoring**
   - Enable DigitalOcean monitoring
   - Configure uptime checks
   - Setup email alerts

3. ✅ **Configure backups**
   - Enable automated database backups
   - Setup filestore backups
   - Test restore procedure

4. ✅ **Customize Odoo**
   - Install required modules
   - Configure company settings
   - Setup email server
   - Customize views and reports

## Support

- **Odoo Documentation**: https://www.odoo.com/documentation/18.0/
- **OCA Documentation**: https://odoo-community.org/
- **DigitalOcean Docs**: https://docs.digitalocean.com/
- **GitHub Issues**: https://github.com/jgtolentino/odoboo-workspace/issues

## License

This deployment configuration is provided as-is. Odoo is licensed under LGPL-3.0.

---

**Generated**: 2025-10-20
**Odoo Version**: 18.0
**OCA Modules**: Latest compatible versions
**Stack**: DigitalOcean + PostgreSQL 15 + Odoo 18.0 + OCA
