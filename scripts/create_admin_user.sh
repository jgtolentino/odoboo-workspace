#!/usr/bin/env bash
#
# Create Admin User for Odoo Login
# Run this on your Mac terminal: ./scripts/create_admin_user.sh
#

set -e

echo "🚀 Creating admin user for Odoo..."
echo ""

# Prompt for database name
read -p "Enter database name [odoboo_local]: " DB_NAME
DB_NAME=${DB_NAME:-odoboo_local}

# Prompt for container name
read -p "Enter Odoo container name [odoo18]: " CONTAINER
CONTAINER=${CONTAINER:-odoo18}

echo ""
echo "Creating user in database: $DB_NAME"
echo "Using container: $CONTAINER"
echo ""

# Create/update admin user
docker exec -i "$CONTAINER" odoo shell -d "$DB_NAME" <<'PYEOF'
import sys

env = env.sudo()

# Admin details
admin_email = 'jgtolentino_rn@yahoo.com'
admin_password = 'admin123'  # Change this after first login!
admin_name = 'Admin'

# Check if user exists
user = env['res.users'].search([('login', '=', admin_email)], limit=1)

if user:
    print(f"✅ User exists (ID: {user.id})")
    print(f"   Name: {user.name}")
    print(f"   Email: {user.email}")
    print(f"   Active: {user.active}")

    # Update password
    user.write({'password': admin_password})
    print(f"✅ Password updated to: {admin_password}")
else:
    print(f"Creating new admin user: {admin_email}")

    # Get system group (admin rights)
    system_group = env.ref('base.group_system')

    # Create user
    user = env['res.users'].create({
        'name': admin_name,
        'login': admin_email,
        'email': admin_email,
        'password': admin_password,
        'active': True,
        'groups_id': [(6, 0, [system_group.id])],
    })
    print(f"✅ User created (ID: {user.id})")

# Commit changes
env.cr.commit()

print("")
print("=" * 60)
print("✅ ADMIN USER READY")
print("=" * 60)
print(f"Email:    {admin_email}")
print(f"Password: {admin_password}")
print("=" * 60)
print("")
print("⚠️  SECURITY: Change password after first login!")
print("   Settings → Users & Companies → Users → Admin → Edit")
print("")

PYEOF

echo ""
echo "✅ Done! You can now log in at:"
echo "   http://localhost:8069"
echo ""
echo "Credentials:"
echo "   Email:    jgtolentino_rn@yahoo.com"
echo "   Password: admin123"
echo ""
