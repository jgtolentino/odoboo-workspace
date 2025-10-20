#!/usr/bin/env bash
set -euo pipefail

# Set Odoo Admin Credentials
# Updates admin user email and password

DB_NAME="${DB_NAME:-insightpulse_prod}"
ODOO_CTN="${ODOO_CTN:-odoo18}"
ADMIN_EMAIL="jgtolentino_rn@yahoo.com"
ADMIN_PASS="Postgres_26"

echo "==> Setting Odoo Admin Credentials"
echo "Database: $DB_NAME"
echo "Container: $ODOO_CTN"
echo "Admin Email: $ADMIN_EMAIL"
echo ""

# Update admin user credentials via Odoo shell
docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<PY
# Find admin user (usually ID 2, but search to be sure)
admin = env['res.users'].search([('login', '=', 'admin')], limit=1)

if not admin:
    # If 'admin' doesn't exist, try to find user ID 2
    admin = env['res.users'].browse(2)
    if not admin.exists():
        print("❌ Admin user not found")
        exit(1)

# Update credentials
admin.write({
    'login': '$ADMIN_EMAIL',
    'email': '$ADMIN_EMAIL',
    'password': '$ADMIN_PASS'
})

env.cr.commit()

print("✅ Admin credentials updated")
print(f"   Email: $ADMIN_EMAIL")
print(f"   Password: $ADMIN_PASS")
print("")
print("🌐 Login at: https://insightpulseai.net/web/login")
PY

echo ""
echo "✅ Admin user configured successfully"
echo ""
echo "Login credentials:"
echo "  Email: $ADMIN_EMAIL"
echo "  Password: $ADMIN_PASS"
echo "  URL: https://insightpulseai.net/web/login"
