# Production Completion - CLI Instructions

## Complete All Remaining Steps via CLI

### Prerequisites

- Server: 188.166.237.231 (insightpulseai.net)
- Odoo container: odoo18
- Database: Connected to Supabase or local PostgreSQL

---

## Step 1: Install Odoo Modules via CLI

### Option A: Using Odoo Shell (Recommended)

```bash
# Connect to Odoo shell
ssh root@188.166.237.231 "docker exec -i odoo18 odoo shell -d postgres --xmlrpc-port=8069" << 'ODOO_SHELL'

# Install web_responsive
module = env['ir.module.module'].search([('name', '=', 'web_responsive')])
if module:
    module.button_immediate_install()
    print("✅ web_responsive installed")
else:
    print("⚠️ web_responsive not found - may need OCA repository")

# Install hr_expense
module = env['ir.module.module'].search([('name', '=', 'hr_expense')])
if module:
    module.button_immediate_install()
    print("✅ hr_expense installed")
else:
    print("⚠️ hr_expense not found")

# Install hr module (dependency for hr_expense)
module = env['ir.module.module'].search([('name', '=', 'hr')])
if module and module.state != 'installed':
    module.button_immediate_install()
    print("✅ hr installed")

# Commit changes
env.cr.commit()
exit()
ODOO_SHELL
```

### Option B: Using Odoo CLI with Database Upgrade

```bash
# Install modules via CLI (recommended for production)
ssh root@188.166.237.231 << 'EOF'

# Stop Odoo container
docker stop odoo18

# Install modules with upgrade mode
docker run --rm \
  --network root_default \
  -e HOST=db \
  -e USER=odoo \
  -e PASSWORD=odoo \
  odoo:18 \
  odoo -d postgres -i web_responsive,hr,hr_expense --stop-after-init

# Restart Odoo container
docker start odoo18

# Wait for startup
sleep 10

# Check if modules installed
docker exec odoo18 psql -h db -U odoo -d postgres -c \
  "SELECT name, state FROM ir_module_module WHERE name IN ('web_responsive', 'hr', 'hr_expense');"

EOF
```

### Option C: Direct Database Update (Fastest)

```bash
# Mark modules for installation via database
ssh root@188.166.237.231 "docker exec -i odoo18 psql -h db -U odoo -d postgres" << 'SQL'

-- Update module state to 'to install'
UPDATE ir_module_module
SET state = 'to install'
WHERE name IN ('web_responsive', 'hr', 'hr_expense')
  AND state = 'uninstalled';

-- Verify
SELECT name, state FROM ir_module_module
WHERE name IN ('web_responsive', 'hr', 'hr_expense');

SQL

# Restart Odoo to trigger module installation
ssh root@188.166.237.231 "docker restart odoo18 && sleep 15 && docker logs --tail 50 odoo18"
```

---

## Step 2: Add OCA Repository for Missing Modules (queue_job, auditlog)

```bash
ssh root@188.166.237.231 << 'EOF'

# Create OCA addons directory
mkdir -p /opt/odoo/addons/oca

# Clone OCA server-tools (contains queue_job, auditlog)
cd /opt/odoo/addons/oca
git clone --depth 1 --branch 18.0 https://github.com/OCA/server-tools.git
git clone --depth 1 --branch 18.0 https://github.com/OCA/web.git

# Update docker-compose.yml to mount OCA addons
cat >> /root/docker-compose.yml << 'DOCKER_COMPOSE'

  odoo:
    volumes:
      - /opt/odoo/addons/oca/server-tools:/mnt/extra-addons/server-tools
      - /opt/odoo/addons/oca/web:/mnt/extra-addons/web
DOCKER_COMPOSE

# Restart Odoo with new addons path
docker-compose -f /root/docker-compose.yml up -d odoo

# Wait for startup
sleep 15

# Update module list
docker exec odoo18 odoo shell -d postgres --stop-after-init << 'ODOO_UPDATE'
env['ir.module.module'].update_list()
env.cr.commit()
exit()
ODOO_UPDATE

# Install OCA modules
docker exec odoo18 psql -h db -U odoo -d postgres -c \
  "UPDATE ir_module_module SET state = 'to install' WHERE name IN ('queue_job', 'auditlog', 'web_responsive') AND state = 'uninstalled';"

# Restart to trigger installation
docker restart odoo18

EOF
```

---

## Step 3: Verify All Module Installations

```bash
# Check module status
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres" << 'SQL'

SELECT
  name,
  state,
  CASE
    WHEN state = 'installed' THEN '✅'
    WHEN state = 'to install' THEN '🔄'
    WHEN state = 'uninstalled' THEN '❌'
    ELSE '⚠️'
  END as status
FROM ir_module_module
WHERE name IN (
  'web_responsive',
  'hr',
  'hr_expense',
  'queue_job',
  'auditlog',
  'base'
)
ORDER BY state, name;

SQL
```

---

## Step 4: Configure OCR Integration (Already Done, Verify)

```bash
# Verify OCR URL configuration
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres" << 'SQL'

SELECT key, value
FROM ir_config_parameter
WHERE key = 'hr_expense_ocr_audit.ocr_api_url';

SQL
```

**Expected Output:**

```
                  key                  |            value
---------------------------------------+------------------------------
 hr_expense_ocr_audit.ocr_api_url     | https://insightpulseai.net/ocr
```

---

## Step 5: Final System Verification

### Complete Health Check Script

```bash
#!/bin/bash
# Save as: verify-production.sh

echo "========================================="
echo "PRODUCTION SYSTEM VERIFICATION"
echo "========================================="
echo

# 1. Service Health
echo "1. SERVICE HEALTH CHECKS"
echo "----------------------------------------"
curl -sf https://insightpulseai.net/health && echo "✅ Main health OK" || echo "❌ Main health FAILED"
curl -sf https://insightpulseai.net/ocr/health && echo "✅ OCR service OK" || echo "❌ OCR service FAILED"
curl -sf https://insightpulseai.net/agent/health && echo "✅ Agent service OK" || echo "❌ Agent service FAILED"
echo

# 2. Container Status
echo "2. CONTAINER STATUS"
echo "----------------------------------------"
ssh root@188.166.237.231 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'odoo|nginx|ocr|agent'"
echo

# 3. Security Status
echo "3. SECURITY STATUS"
echo "----------------------------------------"
ssh root@188.166.237.231 "ufw status | grep -E 'Status|22|80|443'"
ssh root@188.166.237.231 "systemctl is-active fail2ban" && echo "✅ fail2ban active" || echo "❌ fail2ban inactive"
ssh root@188.166.237.231 "systemctl is-active certbot.timer" && echo "✅ certbot auto-renewal active" || echo "❌ certbot timer inactive"
echo

# 4. Odoo Module Status
echo "4. ODOO MODULE STATUS"
echo "----------------------------------------"
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres -t -c \"SELECT name || ': ' || state FROM ir_module_module WHERE name IN ('web_responsive', 'hr', 'hr_expense', 'queue_job', 'auditlog') ORDER BY name;\""
echo

# 5. OCR Configuration
echo "5. OCR CONFIGURATION"
echo "----------------------------------------"
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres -t -c \"SELECT value FROM ir_config_parameter WHERE key = 'hr_expense_ocr_audit.ocr_api_url';\""
echo

# 6. Backup Status
echo "6. BACKUP STATUS"
echo "----------------------------------------"
ssh root@188.166.237.231 "crontab -l | grep snapshot" && echo "✅ Automated snapshots configured" || echo "❌ No automated snapshots"
doctl compute droplet snapshots list 525178434 --format Name,CreatedAt | head -5
echo

echo "========================================="
echo "VERIFICATION COMPLETE"
echo "========================================="
```

### Run Verification

```bash
# Make executable
chmod +x verify-production.sh

# Run verification
./verify-production.sh
```

---

## Step 6: Create Production Snapshot

```bash
# Create final production snapshot with all modules installed
doctl compute droplet-action snapshot 525178434 \
  --snapshot-name "odoo-prod-complete-$(date +%Y%m%d-%H%M)" \
  --wait

# Verify snapshot created
doctl compute droplet snapshots list 525178434 --format Name,CreatedAt,Size | head -5
```

---

## Step 7: Test End-to-End OCR Flow (Optional)

```bash
# Upload test receipt image to OCR service
curl -X POST https://insightpulseai.net/ocr/parse \
  -H "Content-Type: multipart/form-data" \
  -F "file=@sample-receipt.jpg" \
  | jq '.'

# Expected output:
# {
#   "merchant": "...",
#   "date": "...",
#   "total": "...",
#   "confidence": 0.XX,
#   "items": [...]
# }
```

---

## Quick Reference Commands

### View Logs

```bash
# Odoo logs
ssh root@188.166.237.231 "docker logs -f odoo18"

# OCR service logs
ssh root@188.166.237.231 "docker logs -f ocr-service"

# Nginx logs
ssh root@188.166.237.231 "docker logs -f services-nginx"
```

### Restart Services

```bash
# Restart all services
ssh root@188.166.237.231 "docker-compose -f /root/docker-compose.yml restart"

# Restart specific service
ssh root@188.166.237.231 "docker restart odoo18"
```

### Database Access

```bash
# Connect to Odoo database
ssh root@188.166.237.231 "docker exec -it odoo18 psql -h db -U odoo -d postgres"

# Or via Odoo shell
ssh root@188.166.237.231 "docker exec -it odoo18 odoo shell -d postgres"
```

### Update Module List (After Adding OCA)

```bash
ssh root@188.166.237.231 << 'EOF'
docker exec odoo18 odoo shell -d postgres --stop-after-init << 'ODOO_CMD'
env['ir.module.module'].update_list()
env.cr.commit()
exit()
ODOO_CMD
EOF
```

---

## Troubleshooting

### Modules Not Found

```bash
# Check available modules
ssh root@188.166.237.231 "docker exec odoo18 find /usr/lib/python3/dist-packages/odoo/addons -name '__manifest__.py' | wc -l"

# Update module list
ssh root@188.166.237.231 "docker exec odoo18 odoo shell -d postgres --stop-after-init -c 'env[\"ir.module.module\"].update_list(); env.cr.commit()'"
```

### Module Installation Failed

```bash
# Check Odoo logs for errors
ssh root@188.166.237.231 "docker logs --tail 100 odoo18 | grep -i error"

# Check module dependencies
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres -c \"SELECT name, state, latest_version FROM ir_module_module WHERE name = 'hr_expense';\""
```

### Database Connection Issues

```bash
# Verify database connection
ssh root@188.166.237.231 "docker exec odoo18 psql -h db -U odoo -d postgres -c 'SELECT version();'"

# Check environment variables
ssh root@188.166.237.231 "docker exec odoo18 env | grep -E 'HOST|USER|PASSWORD'"
```

---

## Next Steps After CLI Completion

1. **Test Odoo Web UI**
   - Navigate to https://insightpulseai.net (or localhost:8069 if testing locally)
   - Login with admin credentials
   - Verify modules installed: Apps → Installed

2. **Configure Email Notifications**
   - Settings → Technical → Outgoing Mail Servers
   - Add SMTP server for @mention alerts

3. **Set Up Mobile Access**
   - Install web_pwa_oca module
   - Users can "Add to Home Screen" on mobile

4. **Monitor Uptime**
   - Check GitHub Actions: .github/workflows/ocr-uptime.yml
   - Should run every 15 minutes

5. **Schedule Regular Snapshots**
   - Verify cron: `ssh root@188.166.237.231 "crontab -l | grep snapshot"`
   - Should create daily snapshots at 3:05 AM UTC

---

## Success Criteria Checklist

- [ ] All health endpoints return 200 OK
- [ ] Odoo accessible at https://insightpulseai.net
- [ ] web_responsive module installed
- [ ] hr_expense module installed
- [ ] OCR URL configured correctly
- [ ] Security hardening complete (UFW, fail2ban, auto-updates)
- [ ] SSL auto-renewal active
- [ ] Automated backups scheduled
- [ ] Uptime monitoring active
- [ ] Production snapshot created

**Run `./verify-production.sh` to check all criteria automatically.**
