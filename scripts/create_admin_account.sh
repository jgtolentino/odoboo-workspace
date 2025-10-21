#!/bin/bash
set -e

# Simple script to create admin account in Odoo
# Usage: ./scripts/create_admin_account.sh

DB_NAME="${DB_NAME:-insightpulse_prod}"
ADMIN_EMAIL="${ADMIN_EMAIL:-jgtolentino_rn@yahoo.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

echo "🚀 Creating admin account in Odoo..."
echo "   Database: $DB_NAME"
echo "   Email: $ADMIN_EMAIL"
echo ""

docker exec -i odoo18 odoo shell -d "$DB_NAME" <<PYEOF
print("👤 Setting up admin user...")

# Search for existing user
user = env['res.users'].search([
    '|',
    ('login', '=', '$ADMIN_EMAIL'),
    ('login', '=', 'admin')
], limit=1)

if not user:
    # Create new user
    user = env['res.users'].create({
        'name': 'Admin',
        'login': '$ADMIN_EMAIL',
        'email': '$ADMIN_EMAIL',
        'password': '$ADMIN_PASSWORD',
    })
    print(f"✅ User created (ID: {user.id})")
else:
    # Update existing user
    user.write({
        'login': '$ADMIN_EMAIL',
        'email': '$ADMIN_EMAIL',
        'password': '$ADMIN_PASSWORD',
    })
    print(f"✅ User updated (ID: {user.id})")

# Grant admin rights
admin_group = env.ref('base.group_system')
if admin_group.id not in user.groups_id.ids:
    user.groups_id = [(4, admin_group.id)]
    print("✅ Admin rights granted")
else:
    print("✅ Admin rights already granted")

env.cr.commit()

print("")
print("="*60)
print("✅ ACCOUNT CREATED!")
print("="*60)
print("")
print("🔑 Login at: https://insightpulseai.net")
print(f"   Email:    $ADMIN_EMAIL")
print(f"   Password: $ADMIN_PASSWORD")
print("")
print("="*60)
PYEOF
