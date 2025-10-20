#!/bin/bash
set -e

echo "📦 Downloading Minimal Core OCA Modules (8 essentials for OCR/Audit/Compliance)"
echo "==============================================================================="

# Configuration
OCA_VERSION="18.0"
OCA_BASE_DIR="oca-modules"

mkdir -p "$OCA_BASE_DIR"
cd "$OCA_BASE_DIR"

echo ""
echo "Step 1: Cloning OCA repositories..."
echo "-----------------------------------"

# 1. web (responsive UI + PWA)
if [ ! -d "web" ]; then
    echo "✓ Cloning OCA/web (web_responsive, web_pwa_oca)..."
    git clone -b $OCA_VERSION --depth 1 https://github.com/OCA/web.git
else
    echo "⚠ web already exists, skipping..."
fi

# 2. server-tools (environment config + auditlog)
if [ ! -d "server-tools" ]; then
    echo "✓ Cloning OCA/server-tools (server_environment, auditlog)..."
    git clone -b $OCA_VERSION --depth 1 https://github.com/OCA/server-tools.git
else
    echo "⚠ server-tools already exists, skipping..."
fi

# 3. queue (async job processing for OCR)
if [ ! -d "queue" ]; then
    echo "✓ Cloning OCA/queue (queue_job for async OCR processing)..."
    git clone -b $OCA_VERSION --depth 1 https://github.com/OCA/queue.git
else
    echo "⚠ queue already exists, skipping..."
fi

# 4. storage (S3/DigitalOcean Spaces for receipt attachments)
if [ ! -d "storage" ]; then
    echo "✓ Cloning OCA/storage (storage_backend for DO Spaces)..."
    git clone -b $OCA_VERSION --depth 1 https://github.com/OCA/storage.git
else
    echo "⚠ storage already exists, skipping..."
fi

echo ""
echo "Step 2: Minimal Core 8 Modules (Priority Installation Order)"
echo "------------------------------------------------------------"
cat <<EOF

**MINIMAL CORE 8 OCA MODULES**

1. web_responsive              [web/]
   Purpose: Mobile-friendly backend UI
   Priority: CRITICAL - Day 1 install

2. web_pwa_oca                [web/]
   Purpose: Installable PWA (no App Store)
   Priority: HIGH - Mobile experience

3. server_environment         [server-tools/]
   Purpose: 12-factor config in ir.config_parameter
   Priority: CRITICAL - OCR API URL config

4. queue_job                  [queue/]
   Purpose: Async OCR processing (reliable background jobs)
   Priority: CRITICAL - OCR performance

5. auditlog                   [server-tools/]
   Purpose: Model-level audit trail (compliance)
   Priority: HIGH - hr_expense_ocr_audit integration

6. storage_backend            [storage/]
   Purpose: S3/DO Spaces for receipt attachments
   Priority: MEDIUM - Attachment storage

7. web_environment_ribbon     [web/]
   Purpose: DEV/TEST/PROD environment badge
   Priority: MEDIUM - Safety control

8. module_auto_update         [server-tools/]
   Purpose: Auto-update installed addons on deploy
   Priority: LOW - Deployment automation

EOF

echo ""
echo "Step 3: Update Odoo Configuration"
echo "---------------------------------"
echo "Add to odoo.conf:"
echo ""
echo "addons_path = addons,oca-modules/web,oca-modules/server-tools,oca-modules/queue,oca-modules/storage,/path/to/custom-modules"
echo ""

echo ""
echo "Step 4: Installation Commands"
echo "-----------------------------"
cat <<'INSTALL'
# In Odoo container or local dev:
docker exec -i odoo18 odoo -d odoboo_local -i \
  web_responsive,web_pwa_oca,server_environment,queue_job,auditlog,storage_backend,web_environment_ribbon,module_auto_update \
  --stop-after-init \
  --db_host=db --db_port=5432 --db_user=odoo --db_password=odoo

# Or via Apps menu in Odoo UI (recommended for first-time setup)
INSTALL

echo ""
echo "✅ OCA repositories downloaded!"
echo "Next: Update odoo.conf addons_path and install via Apps menu"
echo ""
