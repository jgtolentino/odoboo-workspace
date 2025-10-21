# Production Admin Setup Guide

Complete guide for setting up admin account in production Odoo.

---

## Quick Start

**One command** (sets up admin with full access):

```bash
python3 scripts/setup_production_admin.py
```

That's it! The script will:

1. ✅ Connect to production Odoo (https://insightpulseai.net)
2. ✅ Create/update admin user (jgtolentino_rn@yahoo.com)
3. ✅ Grant full system access (all apps)
4. ✅ Verify setup and show credentials

---

## Prerequisites

### 1. Production Odoo Deployed

Ensure your Odoo server is running at https://insightpulseai.net

**Check if server is up:**

```bash
curl -I https://insightpulseai.net/web/login
```

Expected: HTTP 200 response

### 2. Database Created

Database `insightpulse_prod` must exist.

**To create database** (if not exists):

```bash
# SSH to your droplet
ssh root@YOUR_DROPLET_IP

# Run one-shot deployment (creates database automatically)
sudo bash /opt/fin-workspace/scripts/deploy_production_oneshot.sh
```

### 3. Python 3 Installed

```bash
python3 --version
# Should show Python 3.7+
```

---

## Configuration Options

### Option 1: Default Settings (Recommended)

Just run the script with defaults:

```bash
python3 scripts/setup_production_admin.py
```

**Defaults:**

- URL: https://insightpulseai.net
- Database: insightpulse_prod
- Email: jgtolentino_rn@yahoo.com
- Password: admin123

### Option 2: Custom Settings

Override defaults with environment variables:

```bash
export ODOO_URL="https://your-domain.com"
export ODOO_DB="your_database"
export ADMIN_EMAIL="your-email@example.com"
export ADMIN_PASSWORD="your_secure_password"

python3 scripts/setup_production_admin.py
```

### Option 3: One-Liner with Custom Password

```bash
ADMIN_PASSWORD="MySecurePass123!" python3 scripts/setup_production_admin.py
```

---

## Step-by-Step Walkthrough

### Step 1: Verify Production Server

```bash
# Check if Odoo is accessible
curl -s https://insightpulseai.net/web/database/selector | grep -q "insightpulse_prod" && echo "✅ Database exists" || echo "❌ Database not found"
```

### Step 2: Run Admin Setup

```bash
cd /path/to/odoboo-workspace

# Run setup script
python3 scripts/setup_production_admin.py
```

**Expected output:**

```
🚀 Setting up production admin account...
   URL: https://insightpulseai.net
   Database: insightpulse_prod
   Email: jgtolentino_rn@yahoo.com

🔐 Attempting authentication...
✅ Authenticated as existing user (ID: 2)

👤 Setting up admin user...
✅ Updated existing user (ID: 2)

🔑 Granting admin rights...
  ✅ Adding: base.group_system
  ✅ Adding: base.group_erp_manager
  ✅ Adding: base.group_user
  ✅ Adding: Project / Administrator
  ✅ Adding: HR / Manager
  ✅ Adding: Sales / Manager
  ... (more groups)

✅ Added 15 new groups

============================================================
✅ PRODUCTION ADMIN SETUP COMPLETE!
============================================================

🔑 Login Details:
   URL:      https://insightpulseai.net
   Email:    jgtolentino_rn@yahoo.com
   Password: admin123
   Database: insightpulse_prod

✨ Admin Access:
   - Total Groups: 42
   - Settings & Administration: ✅
   - All App Manager Rights: ✅
   - Full System Access: ✅

============================================================
```

### Step 3: Verify Login

```bash
# Open in browser
open https://insightpulseai.net/web/login

# Or test with curl
curl -X POST https://insightpulseai.net/web/session/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "params": {
      "db": "insightpulse_prod",
      "login": "jgtolentino_rn@yahoo.com",
      "password": "admin123"
    }
  }'
```

### Step 4: Verify App Access

1. Login to https://insightpulseai.net
2. Check top menu - you should see ALL apps:
   - Discuss
   - Calendar
   - Contacts
   - CRM
   - Sales
   - Invoicing
   - Inventory
   - Purchase
   - Project
   - Timesheets
   - Expenses
   - HR
   - Settings (gear icon)

3. Navigate to: Settings → Users & Companies → Users
4. Find your user (jgtolentino_rn@yahoo.com)
5. Check Access Rights tab → Should show 40+ groups

---

## Troubleshooting

### Error: Connection Failed

**Problem:** Cannot connect to https://insightpulseai.net

**Solutions:**

1. **Check if server is up:**

   ```bash
   curl -I https://insightpulseai.net/web/login
   ```

2. **Check DNS:**

   ```bash
   nslookup insightpulseai.net
   # Should return your droplet IP
   ```

3. **Check firewall:**

   ```bash
   # SSH to droplet
   ssh root@YOUR_DROPLET_IP
   sudo ufw status
   # Should show: 80/tcp ALLOW, 443/tcp ALLOW
   ```

4. **Check Odoo is running:**
   ```bash
   ssh root@YOUR_DROPLET_IP
   docker ps | grep odoo
   # Should show odoo18 container running
   ```

### Error: Authentication Failed

**Problem:** "Cannot authenticate. Check if database exists..."

**Solutions:**

1. **Check if database exists:**

   ```bash
   ssh root@YOUR_DROPLET_IP
   docker exec -i postgres15 psql -U odoo -l | grep insightpulse_prod
   ```

2. **Create database if missing:**

   ```bash
   ssh root@YOUR_DROPLET_IP
   cd /opt/fin-workspace/compose
   docker compose exec -T odoo18 odoo -i base -d insightpulse_prod --stop-after-init
   ```

3. **Try with default admin credentials first:**
   ```bash
   # Test authentication with default credentials
   curl -X POST https://insightpulseai.net/web/session/authenticate \
     -H "Content-Type: application/json" \
     -d '{
       "params": {
         "db": "insightpulse_prod",
         "login": "admin",
         "password": "admin"
       }
     }'
   ```

### Error: Database Does Not Exist

**Problem:** Database `insightpulse_prod` not found

**Solution:** Run one-shot deployment to create database:

```bash
ssh root@YOUR_DROPLET_IP
sudo bash /opt/fin-workspace/scripts/deploy_production_oneshot.sh
```

This will:

- Create `insightpulse_prod` database
- Install base modules
- Setup initial admin user

Then re-run the admin setup script:

```bash
python3 scripts/setup_production_admin.py
```

### Error: SSL Certificate Verification Failed

**Problem:** SSL/TLS certificate verification error

**Solution:** Install/update CA certificates:

```bash
# macOS
brew upgrade ca-certificates

# Ubuntu/Debian
sudo apt update && sudo apt install ca-certificates

# Or skip SSL verification (TESTING ONLY):
export PYTHONHTTPSVERIFY=0
python3 scripts/setup_production_admin.py
```

---

## Advanced Usage

### Change Admin Password After Setup

```bash
# Login to Odoo UI
open https://insightpulseai.net/web/login

# Go to: Top-right dropdown → My Profile → Security
# Click "Change Password"
# Enter new password and save
```

### Add Additional Admins

```bash
# Set different email
export ADMIN_EMAIL="second-admin@example.com"
export ADMIN_PASSWORD="SecurePass456!"

python3 scripts/setup_production_admin.py
```

### Grant Access to Specific Apps Only

If you want limited access instead of full admin:

1. Login to Odoo as admin
2. Go to: Settings → Users & Companies → Users
3. Create new user
4. Access Rights tab → Select specific app groups only
5. Don't add "Settings" or "Administration" groups

### Revoke Admin Access

```bash
# Login to Odoo UI as another admin
# Go to: Settings → Users & Companies → Users
# Find user to revoke
# Access Rights tab → Uncheck admin groups
# Save
```

---

## Security Best Practices

### 1. Change Default Password

**Immediately after setup:**

```bash
# Option A: Change via UI (recommended)
# Login → My Profile → Security → Change Password

# Option B: Re-run setup with new password
ADMIN_PASSWORD="NewSecurePassword123!" python3 scripts/setup_production_admin.py
```

### 2. Enable Two-Factor Authentication

1. Login to Odoo
2. Top-right dropdown → My Profile → Account Security
3. Enable Two-Factor Authentication
4. Scan QR code with authenticator app
5. Save

### 3. Limit Admin Access

Create separate users for different roles:

- **Super Admin**: Full access (Settings + all apps)
- **App Admins**: Manager access to specific apps only
- **Regular Users**: User access without admin rights

### 4. Audit Admin Actions

1. Install `auditlog` module (already included in OCA)
2. Go to: Settings → Technical → Audit → Rules
3. Create rules to track admin actions
4. Review logs regularly: Settings → Technical → Audit → Logs

### 5. Secure Master Password

The master/admin password in `/etc/odoo/odoo.conf` should be:

```bash
ssh root@YOUR_DROPLET_IP
nano /opt/fin-workspace/config/odoo.conf

# Change this line:
admin_passwd = YOUR_SECURE_MASTER_PASSWORD

# Restart Odoo
cd /opt/fin-workspace/compose
docker compose restart odoo18
```

**IMPORTANT:** Master password is separate from user password!

---

## Next Steps After Setup

### 1. Configure Apps

Visit each app and configure:

- **Project**: Create projects, set up Kanban stages
- **HR**: Add employees, set up departments
- **CRM**: Configure sales pipeline
- **Accounting**: Set up chart of accounts
- **Inventory**: Configure warehouses, products

### 2. Import Data

Use the compliance import scripts:

```bash
# Import compliance data
./scripts/import_all_compliance.sh
```

### 3. Configure Email

Setup outgoing/incoming mail servers:

1. Settings → Technical → Outgoing Mail Servers
2. Add your SMTP server (Gmail, SendGrid, etc.)
3. Test connection

### 4. Setup Automated Backups

```bash
ssh root@YOUR_DROPLET_IP

# Create backup script
cat > /opt/backup-odoo.sh <<'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker exec postgres15 pg_dump -U odoo insightpulse_prod | gzip > /opt/backups/odoo_${TIMESTAMP}.sql.gz
# Keep only last 7 days
find /opt/backups -name "odoo_*.sql.gz" -mtime +7 -delete
EOF

chmod +x /opt/backup-odoo.sh

# Add to cron (daily at 2 AM)
crontab -e
# Add this line:
# 0 2 * * * /opt/backup-odoo.sh
```

### 5. Configure Users

Create users for your team:

1. Settings → Users & Companies → Users
2. Create → Enter name, email
3. Access Rights → Assign appropriate groups
4. Send invitation email

---

## Support

For issues or questions:

1. Check [Troubleshooting](#troubleshooting) section
2. Verify server status and connectivity
3. Check Odoo logs:
   ```bash
   ssh root@YOUR_DROPLET_IP
   docker logs odoo18 --tail 100
   ```

---

**Setup Status**: ✅ Ready to use
**Script Location**: [scripts/setup_production_admin.py](scripts/setup_production_admin.py)
**Last Updated**: 2025-10-21
