#!/bin/bash
set -e

# ============================================================================
# EXACT DEPLOYMENT COMMANDS - Ready to Execute
# ============================================================================
# Registry: fin-workspace
# Droplet IP: 188.166.237.231
# OCR Port: 8000 (direct, no NGINX proxy initially)
# ============================================================================

echo "🚀 PHASE 1: Push AMD64 Image to Registry"
echo "=========================================="

# Authenticate with DigitalOcean Container Registry
doctl registry login

# Push AMD64 image (after buildx completes)
docker push registry.digitalocean.com/fin-workspace/ocr-service:amd64

# Verify image in registry
echo ""
echo "✓ Verifying image in registry..."
doctl registry repository list-tags fin-workspace/ocr-service

echo ""
echo "🚀 PHASE 2: Deploy on Droplet"
echo "=============================="

# SSH to droplet and deploy
ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  -i ~/.ssh/id_ed25519 root@188.166.237.231 << 'DROPLET_EOF'

# Navigate to deployment directory
cd /root

# Pull latest image
docker compose pull

# Start service (or restart if already running)
docker compose up -d

# Wait for healthcheck
echo "⏳ Waiting for service to start (20 seconds)..."
sleep 20

# Check service status
docker compose ps

# Check logs
docker compose logs --tail=30 ocr

DROPLET_EOF

echo ""
echo "🚀 PHASE 3: Smoke Tests"
echo "======================="

# Test health endpoint (direct HTTP)
echo "Testing health endpoint..."
curl -f http://188.166.237.231:8000/health | jq

# Test OCR endpoint with sample file (if available)
# curl -f -F "file=@sample-receipt.jpg" http://188.166.237.231:8000/ocr | jq

echo ""
echo "✅ OCR Service Deployed Successfully!"
echo ""
echo "📍 Service URL: http://188.166.237.231:8000"
echo "📍 Health: http://188.166.237.231:8000/health"
echo "📍 OCR: http://188.166.237.231:8000/ocr"
echo ""

echo "🚀 PHASE 4: Configure Odoo System Parameters"
echo "============================================="

echo ""
echo "Option 1: Via Odoo UI (Recommended)"
echo "------------------------------------"
echo "1. Settings → Technical → System Parameters"
echo "2. Create New:"
echo "   Key: hr_expense_ocr_audit.ocr_api_url"
echo "   Value: http://188.166.237.231:8000/ocr"
echo ""

echo "Option 2: Via server_environment.json (Recommended for 12-factor)"
echo "-------------------------------------------------------------------"
cat << 'ENV_JSON'
{
  "prod": {
    "ir.config_parameter": {
      "hr_expense_ocr_audit.ocr_api_url": "http://188.166.237.231:8000/ocr",
      "queue_job.channels": "root:2",
      "web.base.url": "http://localhost:8069"
    }
  },
  "dev": {
    "ir.config_parameter": {
      "hr_expense_ocr_audit.ocr_api_url": "http://localhost:8000/ocr",
      "queue_job.channels": "root:2",
      "web.base.url": "http://localhost:8069"
    }
  }
}
ENV_JSON

echo ""
echo "Save to: /etc/odoo/server_environment.json"
echo "Add to odoo.conf:"
echo "  running_env = prod"
echo "  server_environment_files = /etc/odoo/server_environment.json"
echo ""

echo "🚀 PHASE 5: Install OCA Minimal Core Modules"
echo "============================================="

echo ""
echo "Step 1: Download OCA repositories"
echo "----------------------------------"
echo "./scripts/download_oca_minimal.sh"
echo ""

echo "Step 2: Update odoo.conf"
echo "------------------------"
echo "addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons,oca-modules/web,oca-modules/server-tools,oca-modules/queue,oca-modules/storage"
echo ""

echo "Step 3: Restart Odoo"
echo "--------------------"
echo "docker-compose -f docker-compose.local.yml restart odoo"
echo ""

echo "Step 4: Install Critical Modules (Day 1)"
echo "-----------------------------------------"
cat << 'INSTALL_CMD'
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_responsive,server_environment,queue_job \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
INSTALL_CMD
echo ""

echo "Step 5: Install High-Priority Modules (Week 1)"
echo "-----------------------------------------------"
cat << 'INSTALL_CMD2'
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_pwa_oca,auditlog \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
INSTALL_CMD2
echo ""

echo "Step 6: Install Medium/Low-Priority Modules (As Needed)"
echo "--------------------------------------------------------"
cat << 'INSTALL_CMD3'
docker exec -i odoo18 odoo -d odoboo_local -i \
  storage_backend,web_environment_ribbon,module_auto_update \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo
INSTALL_CMD3
echo ""

echo "🚀 PHASE 6: Configure auditlog for hr_expense"
echo "=============================================="

echo ""
echo "Via Odoo UI:"
echo "------------"
echo "1. Settings → Technical → Audit → Audit Rules"
echo "2. Create New Rule:"
echo "   Name: HR Expense Audit"
echo "   Model: Expense (hr.expense)"
echo "   Log Creates: ✓ Yes"
echo "   Log Writes: ✓ Yes"
echo "   Log Unlinks: ✓ Yes"
echo "   Log Reads: ☐ No (performance)"
echo "   Capture Action: ✓ Yes"
echo ""

echo "🚀 PHASE 7: Configure queue_job for Async OCR"
echo "=============================================="

echo ""
echo "Via odoo.conf:"
echo "--------------"
echo "[options]"
echo "workers = 4"
echo "max_cron_threads = 2"
echo ""
echo "Via Odoo UI (Settings → Technical → Scheduled Actions):"
echo "--------------------------------------------------------"
echo "Enable: Queue Job Runner"
echo ""

echo "🚀 PHASE 8: End-to-End Smoke Test"
echo "=================================="

echo ""
echo "1. Create expense → attach receipt"
echo "2. Click 'Process OCR' button"
echo "3. Check queue jobs (Settings → Technical → Queue Jobs)"
echo "4. Verify auto-filled fields (vendor, amount, date, confidence)"
echo "5. Check audit log (Settings → Technical → Audit → Logs)"
echo ""

echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📊 Summary:"
echo "  - OCR Service: http://188.166.237.231:8000"
echo "  - Odoo Config: hr_expense_ocr_audit.ocr_api_url = http://188.166.237.231:8000/ocr"
echo "  - OCA Modules: 8 core modules (web_responsive, server_environment, queue_job, web_pwa_oca, auditlog, storage_backend, web_environment_ribbon, module_auto_update)"
echo "  - Cost: \$5/month droplet + \$0 OCA modules = \$5/month total"
echo ""
