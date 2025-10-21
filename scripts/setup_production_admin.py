#!/usr/bin/env python3
"""
Setup production admin account in Odoo with full app access

Usage:
    python3 setup_production_admin.py

Environment Variables:
    ODOO_URL      - Odoo URL (default: https://insightpulseai.net)
    ODOO_DB       - Database name (default: insightpulse_prod)
    ADMIN_EMAIL   - Admin email (default: jgtolentino_rn@yahoo.com)
    ADMIN_PASSWORD - Admin password (default: admin123)
"""

import os
import sys
import xmlrpc.client

# Configuration
ODOO_URL = os.getenv("ODOO_URL", "https://insightpulseai.net")
ODOO_DB = os.getenv("ODOO_DB", "insightpulse_prod")
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "jgtolentino_rn@yahoo.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "admin123")

def setup_admin():
    """Create/update admin user and grant all app access"""

    print("🚀 Setting up production admin account...")
    print(f"   URL: {ODOO_URL}")
    print(f"   Database: {ODOO_DB}")
    print(f"   Email: {ADMIN_EMAIL}")
    print("")

    # Connect to Odoo
    try:
        common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")

        # Try to authenticate with existing credentials first
        print("🔐 Attempting authentication...")
        uid = common.authenticate(ODOO_DB, ADMIN_EMAIL, ADMIN_PASSWORD, {})

        if uid:
            print(f"✅ Authenticated as existing user (ID: {uid})")
        else:
            print("⚠️  Authentication failed - will try to create/update user")
            # Try with 'admin' default credentials
            uid = common.authenticate(ODOO_DB, 'admin', 'admin', {})
            if not uid:
                print("❌ Cannot authenticate. Check if database exists and has default admin user.")
                sys.exit(1)
            print(f"✅ Authenticated as admin user (ID: {uid})")

    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("")
        print("Common issues:")
        print("  - Is Odoo running?")
        print("  - Is the URL correct?")
        print("  - Is the database created?")
        print("  - Check firewall/network settings")
        sys.exit(1)

    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")

    # Find or create admin user
    print("")
    print("👤 Setting up admin user...")

    try:
        # Search for user with target email
        user_ids = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'res.users', 'search',
            [[('login', '=', ADMIN_EMAIL)]],
            {'limit': 1}
        )

        if user_ids:
            user_id = user_ids[0]
            # Update existing user
            models.execute_kw(
                ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
                'res.users', 'write',
                [[user_id], {
                    'login': ADMIN_EMAIL,
                    'email': ADMIN_EMAIL,
                    'password': ADMIN_PASSWORD,
                }]
            )
            print(f"✅ Updated existing user (ID: {user_id})")
        else:
            # Create new user
            user_id = models.execute_kw(
                ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
                'res.users', 'create',
                [{
                    'name': 'Administrator',
                    'login': ADMIN_EMAIL,
                    'email': ADMIN_EMAIL,
                    'password': ADMIN_PASSWORD,
                }]
            )
            print(f"✅ Created new user (ID: {user_id})")

    except Exception as e:
        print(f"❌ Error setting up user: {e}")
        sys.exit(1)

    # Grant admin access
    print("")
    print("🔑 Granting admin rights...")

    try:
        # Get Settings/Administration group
        admin_group_id = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'ir.model.data', 'xmlid_to_res_id',
            ['base.group_system']
        )

        # Get all groups
        all_groups = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'res.groups', 'search',
            [[]]
        )

        # Get user's current groups
        user_data = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'res.users', 'read',
            [[user_id]],
            {'fields': ['groups_id']}
        )[0]

        current_groups = set(user_data['groups_id'])

        # Critical groups to add
        critical_xml_ids = [
            'base.group_system',           # Settings
            'base.group_erp_manager',      # Access Rights
            'base.group_user',             # Internal User
        ]

        groups_to_add = []

        # Add critical groups
        for xml_id in critical_xml_ids:
            try:
                group_id = models.execute_kw(
                    ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
                    'ir.model.data', 'xmlid_to_res_id',
                    [xml_id]
                )
                if group_id not in current_groups:
                    groups_to_add.append(group_id)
                    print(f"  ✅ Adding: {xml_id}")
            except:
                print(f"  ⚠️  Group not found: {xml_id}")

        # Add manager groups for all apps
        manager_groups = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'res.groups', 'search_read',
            [[
                '|',
                ('name', 'ilike', 'manager'),
                ('name', 'ilike', 'administrator')
            ]],
            {'fields': ['id', 'name']}
        )

        for group in manager_groups:
            if group['id'] not in current_groups:
                groups_to_add.append(group['id'])
                print(f"  ✅ Adding: {group['name']}")

        # Update user groups
        if groups_to_add:
            models.execute_kw(
                ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
                'res.users', 'write',
                [[user_id], {'groups_id': [(4, gid) for gid in groups_to_add]}]
            )
            print(f"✅ Added {len(groups_to_add)} new groups")
        else:
            print("✅ User already has all required groups")

        # Get final group count
        user_data = models.execute_kw(
            ODOO_DB, uid, ADMIN_PASSWORD if uid else 'admin',
            'res.users', 'read',
            [[user_id]],
            {'fields': ['groups_id']}
        )[0]

        total_groups = len(user_data['groups_id'])

    except Exception as e:
        print(f"❌ Error granting rights: {e}")
        sys.exit(1)

    print("")
    print("="*60)
    print("✅ PRODUCTION ADMIN SETUP COMPLETE!")
    print("="*60)
    print("")
    print(f"🔑 Login Details:")
    print(f"   URL:      {ODOO_URL}")
    print(f"   Email:    {ADMIN_EMAIL}")
    print(f"   Password: {ADMIN_PASSWORD}")
    print(f"   Database: {ODOO_DB}")
    print("")
    print(f"✨ Admin Access:")
    print(f"   - Total Groups: {total_groups}")
    print(f"   - Settings & Administration: ✅")
    print(f"   - All App Manager Rights: ✅")
    print(f"   - Full System Access: ✅")
    print("")
    print("="*60)

if __name__ == '__main__':
    setup_admin()
