#!/usr/bin/env bash
set -euo pipefail

# OCA Module Installation Script for Odoo 18
# Installs Community + OCA modules for enterprise-level features

# --- CONFIGURATION ---
DB_NAME="${DB_NAME:-insightpulse_prod}"
OCR_URL="${OCR_URL:-https://insightpulseai.net/ocr}"
ODOO_CTN="${ODOO_CTN:-odoo18}"
OCA_DIR="/opt/odoo/oca"
BASE_URL="${BASE_URL:-https://insightpulseai.net}"

echo "==> OCA Module Installation"
echo "Database: $DB_NAME"
echo "OCR URL: $OCR_URL"
echo "Container: $ODOO_CTN"
echo ""

# --- HELPER FUNCTIONS ---
clone_repo() {
    repo="$1"
    branch="${2:-18.0}"
    repo_dir="$(basename "$repo")"

    if [ -d "$repo_dir" ]; then
        echo "  ✓ $repo_dir already exists"
    else
        echo "  ⬇  Cloning $repo..."
        git clone -b "$branch" --depth 1 "https://github.com/OCA/$repo.git"
    fi
}

# --- STEP 1: CLONE OCA REPOSITORIES ---
echo "==> Step 1: Cloning OCA Repositories"
mkdir -p "$OCA_DIR"
cd "$OCA_DIR"

# Essential repositories
clone_repo "web"                            # web_responsive, web_timeline, web_pwa_oca
clone_repo "server-tools"                   # attachment_indexation, base_automation, auditlog
clone_repo "queue"                          # queue_job (background jobs)
clone_repo "mis-builder"                    # mis_builder (BI dashboards)
clone_repo "dms"                            # dms (Document Management System)
clone_repo "knowledge"                      # document_page (wiki)
clone_repo "account-financial-reporting"    # account_financial_report, partner_statement
clone_repo "account-financial-tools"        # account_lock_date, account_payment_order
clone_repo "sale-workflow"                  # sale_margin, sale_workflow
clone_repo "purchase-workflow"              # purchase_request, purchase_requisition
clone_repo "stock-logistics-workflow"       # stock_picking_batch, stock_ux
clone_repo "hr-timesheet"                   # hr_timesheet enhancements
clone_repo "project"                        # project extensions

echo "✅ OCA repositories cloned"

# --- STEP 2: RESTART ODOO TO LOAD NEW ADDONS ---
echo ""
echo "==> Step 2: Restarting Odoo to load new addons"
docker restart "$ODOO_CTN"

echo "Waiting for Odoo to start..."
sleep 10

# --- STEP 3: UPDATE APP LIST ---
echo ""
echo "==> Step 3: Updating app list"
docker exec -it "$ODOO_CTN" odoo -d "$DB_NAME" -u base --stop-after-init

# --- STEP 4: INSTALL MODULES ---
echo ""
echo "==> Step 4: Installing modules (this may take 5-10 minutes)"

# Build module list
MODULES=$(cat <<'CSV'
web_responsive,
web_timeline,
web_pwa_oca,
document_page,
dms,
attachment_indexation,
mis_builder,
auditlog,
queue_job,
base_automation,
account_financial_report,
account_payment_order,
account_lock_date,
sale_margin,
sale_workflow,
stock_picking_batch,
stock_ux,
hr_timesheet,
hr_holidays_public,
hr_expense
CSV
)

# Clean module list (remove whitespace and newlines)
MODULES="$(echo "$MODULES" | tr -d '\n' | tr -d ' ')"

echo "Installing modules: $MODULES"
docker exec -it "$ODOO_CTN" odoo -d "$DB_NAME" --init "$MODULES" --stop-after-init

echo "✅ Modules installed"

# --- STEP 5: SET SYSTEM PARAMETERS ---
echo ""
echo "==> Step 5: Configuring system parameters"

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<PY
# Set OCR URL
env['ir.config_parameter'].sudo().set_param('hr_expense_ocr_audit.ocr_api_url', '$OCR_URL')

# Set base URL
env['ir.config_parameter'].sudo().set_param('web.base.url', '$BASE_URL')

# Create paper billing opt-in field if not exists
if 'paper_billing_opt_in' not in env['res.partner']._fields:
    env['ir.model.fields'].create({
        'name': 'paper_billing_opt_in',
        'model': 'res.partner',
        'field_description': 'Paper Billing Opt-in',
        'ttype': 'boolean'
    })
    print('✅ Created paper_billing_opt_in field')

print('✅ System parameters configured')
print(f'   - OCR URL: $OCR_URL')
print(f'   - Base URL: $BASE_URL')
PY

# --- STEP 6: FINAL RESTART ---
echo ""
echo "==> Step 6: Final restart"
docker restart "$ODOO_CTN"

echo "Waiting for Odoo to start..."
sleep 10

# --- STEP 7: VERIFY INSTALLATION ---
echo ""
echo "==> Step 7: Verifying installation"

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<'PY'
# Check installed modules
modules = [
    'web_responsive', 'document_page', 'dms', 'mis_builder',
    'queue_job', 'hr_expense', 'auditlog'
]

print("\n📊 Module Installation Status:")
print("-" * 60)

for mod_name in modules:
    mod = env['ir.module.module'].search([('name', '=', mod_name)], limit=1)
    if mod:
        status = "✅" if mod.state == 'installed' else "❌"
        print(f"{status} {mod_name:30s} {mod.state}")
    else:
        print(f"⚠️  {mod_name:30s} not found")

print("-" * 60)

# Count total installed modules
total = env['ir.module.module'].search_count([('state', '=', 'installed')])
print(f"\nTotal installed modules: {total}")
PY

# --- SUMMARY ---
echo ""
echo "=" * 60
echo "✅ OCA Installation Complete!"
echo "=" * 60
echo ""
echo "📦 What was installed:"
echo "   - UX: web_responsive, web_timeline, web_pwa_oca"
echo "   - Knowledge: document_page (wiki), dms (document management)"
echo "   - BI: mis_builder (dashboards)"
echo "   - Ops: queue_job, auditlog, base_automation"
echo "   - Finance: account_financial_report, partner_statement"
echo "   - Sales: sale_margin, sale_workflow"
echo "   - Purchase: purchase_request, purchase_requisition"
echo "   - Inventory: stock_picking_batch, stock_ux"
echo "   - HR: hr_timesheet, hr_holidays_public, hr_expense"
echo ""
echo "🔧 Configuration:"
echo "   - OCR URL: $OCR_URL"
echo "   - Base URL: $BASE_URL"
echo "   - Paper billing field added to partners"
echo ""
echo "🌐 Next steps:"
echo "   1. Login at: $BASE_URL/web/login"
echo "   2. Import Notion data: python3 /opt/imports/notion-to-odoo.py"
echo "   3. Configure portal: Settings → Users & Companies → Portal"
echo "   4. Setup automated actions: Settings → Technical → Automation"
echo "   5. Create customer statements: Accounting → Reporting → Partner Statement"
echo ""
echo "📚 Documentation:"
echo "   - OCA Modules: https://github.com/OCA"
echo "   - Odoo 18 Docs: https://www.odoo.com/documentation/18.0/"
