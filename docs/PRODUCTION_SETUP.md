# Production Odoo Setup Guide

Complete production deployment checklist for Odoo 18 + SuperClaude orchestration.

---

## Phase 1: Database Manager Security

**First priority**: Secure the Odoo database manager interface.

### 1.1 Set Master Password

```bash
# Access database manager
# Navigate to: https://insightpulseai.net/web/database/manager
```

1. Click **"Set Master Password"**
2. Generate strong password:
   ```bash
   openssl rand -base64 32
   # Example: xK9mP2vR7wQ8nL4jF6hT5yU3oI1eA0sD
   ```
3. Store in password vault (1Password, Bitwarden, etc.)
4. **NEVER commit this password to git**

### 1.2 Verify Protection

After setting master password, all database operations require authentication:
- Creating databases
- Duplicating databases
- Backing up databases
- Restoring databases
- Dropping databases

---

## Phase 2: Production Database Setup

### 2.1 Create Production Database

**Option A: Via Database Manager UI**
1. Navigate to: `https://insightpulseai.net/web/database/manager`
2. Enter master password
3. Create new database:
   - **Database Name**: `insightpulse_prod`
   - **Email**: `admin@insightpulseai.net`
   - **Password**: (generate with `openssl rand -base64 24`)
   - **Language**: English
   - **Country**: United States
   - **Demo data**: ❌ Unchecked (production must be clean)

**Option B: Via CLI** (recommended for automation)
```bash
# Create production database
docker exec -i odoo18 odoo -d insightpulse_prod \
  --without-demo=all \
  --stop-after-init \
  --db_host=<your-db-host> \
  --db_port=5432 \
  --db_user=<db-user> \
  --db_password=<db-password>
```

### 2.2 Lock Odoo to Production DB

**Critical security measure**: Prevent users from accessing database manager or switching databases.

Edit `odoo.conf` (location varies by setup):
```ini
# Lock to production database only
dbfilter = ^insightpulse_prod$

# Hide database manager
list_db = False

# Disable database selector on login page
db_name = insightpulse_prod
```

Apply changes:
```bash
# If using Docker
docker restart odoo18

# Or reload config (if running as service)
sudo systemctl reload odoo
```

Verify:
- Navigate to `https://insightpulseai.net` → Should go directly to login (no DB selector)
- Try accessing `/web/database/manager` → Should require master password

---

## Phase 3: Install Baseline Applications

### 3.1 Core Modules

Install essential apps for production use:

```bash
# Install core + UX + project/comms + expenses
docker exec odoo18 odoo -d insightpulse_prod \
  -i base,web,web_responsive,project,mail,hr,hr_expense \
  --stop-after-init
```

**Modules installed**:
- `base`: Odoo core framework
- `web`: Web interface
- `web_responsive`: Mobile-friendly UI
- `project`: Project management + Kanban
- `mail`: Discuss (email/chat/channels)
- `hr`: Human Resources
- `hr_expense`: Expense management

### 3.2 Verify Installation

```bash
# Check installed modules
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
installed = env['ir.module.module'].search([('state', '=', 'installed')])
print(f"Installed modules: {len(installed)}")
for mod in installed.sorted('name'):
    print(f"  • {mod.name}: {mod.shortdesc}")
PY
```

---

## Phase 4: OCR + CI/CD Project Setup

### 4.1 Configure OCR Endpoint

Set the OCR API URL for expense receipt scanning:

```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
ICP = env['ir.config_parameter']

# Set OCR API endpoint (DigitalOcean droplet)
ICP.set_param('hr_expense_ocr_audit.ocr_api_url', 'https://insightpulseai.net/ocr')

# Verify
ocr_url = ICP.get_param('hr_expense_ocr_audit.ocr_api_url')
print(f"OCR endpoint configured: {ocr_url}")
PY
```

### 4.2 Bootstrap CI/CD Kanban + Discuss

Run the automated bootstrap script (idempotent - safe to run multiple times):

```bash
# Set environment variables
export ODOO_URL="https://insightpulseai.net"
export ODOO_DB="insightpulse_prod"
export ODOO_ADMIN_EMAIL="admin@insightpulseai.net"
export ODOO_API_KEY="<generate-from-odoo-ui>"  # Settings → Users → API Keys
export REPO="jgtolentino/odoboo-workspace"
export ODOO_CONTAINER="odoo18"

# Run bootstrap
./scripts/bootstrap_superclaude.sh
```

**What this creates**:
- Project: "CI/CD Pipeline"
- Stages: Backlog → Spec Review → In PR → CI Green → Staging ✅ → Ready for Prod → Deployed → Blocked
- Custom fields: `x_pr_number`, `x_build_status`, `x_env`, etc. (9 total)
- Discuss channel: `#ci-updates` (Your Own Slack)
- GitHub secrets: `ODOO_URL`, `ODOO_DATABASE`, `ODOO_API_KEY`

**Alternative: Manual setup** (if bootstrap script unavailable):
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()

# Create project
proj = env['project.project'].search([('name','=','CI/CD Pipeline')], limit=1)
if not proj:
    proj = env['project.project'].create({'name':'CI/CD Pipeline'})

# Create stages
stages = ['Backlog','Spec Review','In PR','CI Green','Staging ✅','Ready for Prod','Deployed','Blocked']
for s in stages:
    if not env['project.task.type'].search([('name','=',s),('project_ids','in',proj.id)], limit=1):
        env['project.task.type'].create({'name':s,'project_ids':[(4,proj.id)]})

# Create Discuss channel
if not env['discuss.channel'].search([('name','=','ci-updates')], limit=1):
    env['discuss.channel'].create({'name':'ci-updates','public':'public'})

print(f"✅ Project ID: {proj.id}")
PY
```

---

## Phase 5: Email & Portal Configuration

### 5.1 Configure Outgoing Email (SMTP)

**Settings → Technical → Email → Outgoing Mail Servers**

Example (Gmail/Google Workspace):
```
SMTP Server: smtp.gmail.com
Port: 587
Connection Security: TLS (STARTTLS)
Username: noreply@insightpulseai.net
Password: <app-specific-password>
```

Test email:
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
IrMailServer = env['ir.mail_server']
server = IrMailServer.search([], limit=1)
server.test_smtp_connection()
print("✅ SMTP connection successful")
PY
```

### 5.2 Enable Portal Access for Clients

**Settings → Users & Companies → Portal Access**

1. Set portal mode:
   - **On invitation**: Clients must be invited (recommended)
   - **Free sign up**: Anyone can create account (public projects only)

2. Create portal user template:
   ```bash
   docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
   env = env.sudo()
   User = env['res.users']

   # Create portal user for client
   portal_user = User.create({
       'name': 'Client Name',
       'login': 'client@company.com',
       'email': 'client@company.com',
       'groups_id': [(6, 0, [env.ref('base.group_portal').id])],
   })

   # Share CI/CD project (read-only)
   proj = env['project.project'].search([('name','=','CI/CD Pipeline')], limit=1)
   proj.message_subscribe(partner_ids=[portal_user.partner_id.id])

   print(f"✅ Portal user created: {portal_user.login}")
   PY
   ```

3. Send invitation email:
   - **Settings → Users → Portal → Send invitation**

---

## Phase 6: Backup Production Database

### 6.1 Manual Backup (One-Time)

**Via Database Manager**:
1. Navigate to: `https://insightpulseai.net/web/database/manager`
2. Enter master password
3. Select `insightpulse_prod`
4. Click **Backup**
5. Format: **zip** (includes filestore)
6. Download to secure location

**Via CLI** (recommended for automation):
```bash
# Backup database + filestore
docker exec odoo18 pg_dump -U odoo -d insightpulse_prod -F c -f /tmp/insightpulse_prod_$(date +%Y%m%d).dump

# Copy to host
docker cp odoo18:/tmp/insightpulse_prod_$(date +%Y%m%d).dump ./backups/

# Compress
gzip ./backups/insightpulse_prod_$(date +%Y%m%d).dump

# Upload to S3/DigitalOcean Spaces (optional)
# aws s3 cp ./backups/insightpulse_prod_$(date +%Y%m%d).dump.gz s3://your-bucket/odoo-backups/
```

### 6.2 Automated Daily Backups

Create cron job for daily backups:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/scripts/backup_odoo.sh
```

**Backup script** (`scripts/backup_odoo.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/var/backups/odoo"
RETENTION_DAYS=7
DB_NAME="insightpulse_prod"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
docker exec odoo18 pg_dump -U odoo -d "$DB_NAME" -F c -f "/tmp/${DB_NAME}_${DATE}.dump"

# Copy to host
docker cp "odoo18:/tmp/${DB_NAME}_${DATE}.dump" "$BACKUP_DIR/"

# Compress
gzip "$BACKUP_DIR/${DB_NAME}_${DATE}.dump"

# Clean up old backups
find "$BACKUP_DIR" -name "${DB_NAME}_*.dump.gz" -mtime +$RETENTION_DAYS -delete

# Optional: Upload to cloud storage
# aws s3 cp "$BACKUP_DIR/${DB_NAME}_${DATE}.dump.gz" "s3://your-bucket/odoo-backups/"

echo "✅ Backup completed: ${DB_NAME}_${DATE}.dump.gz"
```

---

## Phase 7: Create Staging Database

### 7.1 Duplicate Production to Staging

**Via Database Manager**:
1. Navigate to database manager
2. Enter master password
3. Select `insightpulse_prod`
4. Click **Duplicate**
5. New database name: `insightpulse_stage`

**Via CLI**:
```bash
# Dump production
docker exec odoo18 pg_dump -U odoo -d insightpulse_prod -F c -f /tmp/prod.dump

# Restore as staging
docker exec odoo18 pg_restore -U odoo -d insightpulse_stage -c /tmp/prod.dump

# Clean up
docker exec odoo18 rm /tmp/prod.dump
```

### 7.2 Configure Staging-Specific Settings

**Important**: Staging should NOT send real emails or charge real payments.

```bash
docker exec -i odoo18 odoo shell -d insightpulse_stage <<'PY'
env = env.sudo()

# Disable outgoing emails
IrMailServer = env['ir.mail_server']
for server in IrMailServer.search([]):
    server.active = False

# Set staging base URL
ICP = env['ir.config_parameter']
ICP.set_param('web.base.url', 'https://staging.insightpulseai.net')

# Update OCR endpoint to staging
ICP.set_param('hr_expense_ocr_audit.ocr_api_url', 'https://staging.insightpulseai.net/ocr')

# Rename admin user to prevent confusion
admin = env.ref('base.user_admin')
admin.name = 'Admin (STAGING)'

print("✅ Staging database configured")
PY
```

### 7.3 Point Staging URL to Staging DB

Update `odoo.conf` for staging instance:
```ini
# Staging-specific config
dbfilter = ^insightpulse_stage$
db_name = insightpulse_stage
```

Or use environment variable in Docker:
```bash
docker run -e DB_NAME=insightpulse_stage odoo:18
```

---

## Phase 8: Verification Checklist

### 8.1 Production Database

- [ ] Master password set and stored in vault
- [ ] Database: `insightpulse_prod` created
- [ ] `dbfilter = ^insightpulse_prod$` in odoo.conf
- [ ] Demo data disabled (`--without-demo=all`)
- [ ] Core modules installed (base, web, project, mail, hr)
- [ ] OCR endpoint configured
- [ ] CI/CD project created with 8 stages
- [ ] Discuss channel `#ci-updates` created
- [ ] Custom fields added to project.task (9 fields)
- [ ] SMTP configured and tested
- [ ] Portal access enabled
- [ ] Backup completed and stored securely
- [ ] GitHub secrets set (ODOO_URL, ODOO_DATABASE, ODOO_API_KEY)

### 8.2 Staging Database

- [ ] Database: `insightpulse_stage` duplicated from production
- [ ] Outgoing emails disabled
- [ ] Base URL set to staging domain
- [ ] Admin user renamed to "(STAGING)"
- [ ] Staging URL points to staging database

### 8.3 SuperClaude Orchestration

- [ ] Bootstrap script executed successfully
- [ ] Workflow file exists: `.github/workflows/superclaude-pr.yml`
- [ ] Agent configs exist: `.claude/agents/*.agent.yaml`
- [ ] Sync script executable: `scripts/odoo_kanban_sync.py`
- [ ] MCP servers configured: `mcp/servers.json`
- [ ] Smoke test passed (see `docs/SUPERCLAUDE_SMOKE_TEST.md`)

---

## Phase 9: Post-Setup Tasks

### 9.1 Create Admin API Key

For CI/CD integration:

1. Navigate to: **Settings → Users & Companies → Users**
2. Select your admin user
3. Click **"Edit"**
4. Scroll to **API Keys** section
5. Click **"Generate API Key"**
6. Copy and store in GitHub secrets:
   ```bash
   gh secret set ODOO_API_KEY -b "<your-api-key>"
   ```

### 9.2 Configure OAuth (Optional)

For corporate SSO (OMC/TBWA employees):

Follow guide: `docs/ODOO_OAUTH_SETUP.md`

Allowed domains:
- `omc.com`
- `tbwa-smp.com`

### 9.3 Install Additional Modules (As Needed)

```bash
# OCA modules (if not already installed)
docker exec odoo18 odoo -d insightpulse_prod \
  -i web_timeline,auditlog,queue_job \
  --stop-after-init

# Custom modules (from addons/ directory)
docker exec odoo18 odoo -d insightpulse_prod \
  -i hr_expense_ocr_audit,auth_domain_guard \
  --stop-after-init
```

### 9.4 Schedule Regular Tasks

**Daily**:
- Database backup (2 AM)
- Log rotation

**Weekly**:
- Security updates check
- Dependency vulnerability scan

**Monthly**:
- Backup verification (test restore)
- Performance review (slow query analysis)

---

## Troubleshooting

### Issue: Cannot access database manager

**Symptom**: `/web/database/manager` returns 404 or redirects to login

**Cause**: `list_db = False` in odoo.conf

**Fix**: Temporarily enable database manager
```bash
# Edit odoo.conf
list_db = True

# Restart
docker restart odoo18

# After changes, set back to False
```

---

### Issue: "Database already exists" error

**Symptom**: Cannot create `insightpulse_prod` database

**Cause**: Database name conflict

**Fix**: Drop old database or choose different name
```bash
# List databases
docker exec -i odoo18 psql -U odoo -l

# Drop old database (CAUTION!)
docker exec -i odoo18 psql -U odoo -c "DROP DATABASE insightpulse_prod;"
```

---

### Issue: SMTP test fails

**Symptom**: `test_smtp_connection()` raises exception

**Common causes**:
1. Firewall blocking port 587/465
2. Invalid credentials
3. App-specific password required (Gmail)
4. Less secure app access disabled

**Fix**:
```bash
# Test from container
docker exec -it odoo18 bash
apt-get update && apt-get install -y telnet
telnet smtp.gmail.com 587

# If connection fails, check firewall rules
# If connection succeeds but auth fails, regenerate app password
```

---

### Issue: Portal users can't access project

**Symptom**: Portal user gets "Access Denied" on CI/CD project

**Cause**: Project not shared with portal user

**Fix**:
```bash
docker exec -i odoo18 odoo shell -d insightpulse_prod <<'PY'
env = env.sudo()
proj = env['project.project'].search([('name','=','CI/CD Pipeline')], limit=1)
portal_user = env['res.users'].search([('login','=','client@company.com')], limit=1)

# Subscribe to project
proj.message_subscribe(partner_ids=[portal_user.partner_id.id])

# Or set project to public
proj.privacy_visibility = 'portal'
proj._compute_access_url()

print(f"✅ Project shared with {portal_user.name}")
PY
```

---

## Security Best Practices

1. **Never** commit passwords or API keys to git
2. **Always** use HTTPS for production (TLS/SSL)
3. **Enable** two-factor authentication for admin users
4. **Rotate** database master password every 90 days
5. **Limit** database manager access (set `list_db = False`)
6. **Review** user access rights monthly
7. **Monitor** login attempts (Settings → Technical → Audit → Logs)
8. **Keep** Odoo and dependencies updated
9. **Test** backups monthly (verify restore works)
10. **Use** separate databases for staging/production

---

## Next Steps

After completing production setup:

1. **Run smoke test**: `docs/SUPERCLAUDE_SMOKE_TEST.md`
2. **Create first PR**: Test SuperClaude orchestration
3. **Invite team members**: Settings → Users → Invite
4. **Configure OAuth**: (if using corporate SSO)
5. **Set up monitoring**: Odoo logs, server metrics, uptime checks

---

**Your production Odoo instance is now fully secured and ready for SuperClaude-orchestrated CI/CD!** 🚀
