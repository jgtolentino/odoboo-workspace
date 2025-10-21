#!/bin/bash
# Grant admin user access to all installed apps/modules in Odoo
#
# Usage: ./scripts/grant_admin_all_apps.sh
#
# Environment variables:
#   DB_NAME - Database name (default: odoboo_local)
#   ADMIN_EMAIL - Admin email (default: jgtolentino_rn@yahoo.com)

set -e

DB_NAME="${DB_NAME:-odoboo_local}"
ADMIN_EMAIL="${ADMIN_EMAIL:-jgtolentino_rn@yahoo.com}"
ODOO_CTN="${ODOO_CTN:-odoo18}"

echo "🔐 Granting admin user access to all apps..."
echo "   Database: $DB_NAME"
echo "   Admin: $ADMIN_EMAIL"
echo ""

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<PYEOF
print("👤 Finding admin user...")

# Find admin user
admin = env['res.users'].search([
    '|',
    ('login', '=', '$ADMIN_EMAIL'),
    ('login', '=', 'admin')
], limit=1)

if not admin:
    print("❌ Admin user not found!")
    exit(1)

print(f"✅ Found admin user: {admin.name} ({admin.login}, ID: {admin.id})")
print("")

# Get all available groups
print("📋 Collecting all security groups...")
all_groups = env['res.groups'].search([])
print(f"✅ Found {len(all_groups)} groups")
print("")

# Get critical admin groups
print("🔑 Granting critical admin access...")
critical_groups = [
    'base.group_system',           # Settings/Administration
    'base.group_erp_manager',      # Access Rights
    'base.group_user',             # Internal User
    'project.group_project_manager', # Project Manager
    'hr.group_hr_manager',         # HR Manager
    'account.group_account_manager', # Accounting Manager
    'sales_team.group_sale_manager', # Sales Manager
    'purchase.group_purchase_manager', # Purchase Manager
    'stock.group_stock_manager',   # Inventory Manager
]

added = 0
for group_xml_id in critical_groups:
    try:
        group = env.ref(group_xml_id)
        if group.id not in admin.groups_id.ids:
            admin.groups_id = [(4, group.id)]
            print(f"  ✅ Added: {group.name}")
            added += 1
        else:
            print(f"  ⏭️  Already has: {group.name}")
    except:
        print(f"  ⚠️  Group not found: {group_xml_id}")

print("")
print(f"✅ Added {added} new groups")
print("")

# Grant all app-specific groups
print("📦 Granting app-specific access...")
app_categories = env['ir.module.category'].search([])
app_added = 0

for category in app_categories:
    # Find manager/admin group for this category
    manager_groups = env['res.groups'].search([
        ('category_id', '=', category.id),
        '|',
        ('name', 'ilike', 'manager'),
        ('name', 'ilike', 'admin')
    ])

    for group in manager_groups:
        if group.id not in admin.groups_id.ids:
            admin.groups_id = [(4, group.id)]
            print(f"  ✅ {category.name}: {group.name}")
            app_added += 1

env.cr.commit()

print("")
print("="*60)
print(f"✅ COMPLETE!")
print(f"   Total groups added: {added + app_added}")
print(f"   Total groups: {len(admin.groups_id)}")
print("="*60)
print("")
print("🎯 Admin now has access to:")
print("   - All Settings & Administration")
print("   - All installed apps and modules")
print("   - Full manager rights across the system")
print("")
PYEOF
