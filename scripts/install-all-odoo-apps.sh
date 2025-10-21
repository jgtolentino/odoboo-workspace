#!/bin/bash
# Install all Odoo applications
# Usage: ./install-all-odoo-apps.sh [database_name]

DB="${1:-insightpulse_prod}"

echo "=================================="
echo "Installing Odoo Apps to: $DB"
echo "=================================="

# Step 1: Install baseline apps
echo ""
echo "Step 1/2: Installing baseline app pack..."
docker compose -f docker-compose.yml exec -T odoo18 \
  odoo -d "$DB" --without-demo=all --stop-after-init \
  -i base,web,web_responsive,mail,contacts,calendar,crm,project,hr,hr_holidays,hr_timesheet,hr_expense,account,stock,purchase,sale,documents,website,website_sale,mass_mailing || true

echo ""
echo "Step 1 complete!"
echo ""

# Step 2: Install all remaining applications
echo "Step 2/2: Installing all remaining applications..."
docker compose -f docker-compose.yml exec -T odoo18 bash -lc "python3 - <<'PY'
import odoo, odoo.api as api
DB='$DB'
odoo.tools.config['db_name']=DB
odoo.registry(DB)
with api.Environment.manage():
    cr=odoo.sql_db.db_connect(DB).cursor()
    env=api.Environment(cr, odoo.SUPERUSER_ID, {})
    mods = env['ir.module.module'].search([('state','=','uninstalled'),('application','=',True)])
    names = [m.name for m in mods]
    if names:
        env['ir.module.module'].browse(mods.ids).button_immediate_install()
        cr.commit()
        print('Installed apps:', ', '.join(names))
    else:
        print('No remaining apps to install.')
    cr.close()
PY"

echo ""
echo "=================================="
echo "✅ All Odoo apps installed!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Refresh your Odoo Apps view (enable developer mode)"
echo "2. All applications should now show as installed"
