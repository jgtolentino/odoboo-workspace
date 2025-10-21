#!/usr/bin/env bash
#
# Complete Odoo Setup - One Command Does Everything
# Run once: ./scripts/setup_odoo_complete.sh
#

set -e

CONTAINER="${ODOO_CONTAINER:-odoo18}"
DB_NAME="${ODOO_DB:-odoboo_local}"
ADMIN_EMAIL="jgtolentino_rn@yahoo.com"
ADMIN_PASSWORD="admin123"

echo "🚀 COMPLETE ODOO SETUP STARTING..."
echo ""

# ============================================================================
# 1. CREATE/UPDATE ADMIN USER
# ============================================================================
echo "👤 Setting up admin user..."
docker exec -i "$CONTAINER" odoo shell -d "$DB_NAME" <<'PYEOF'
env = env.sudo()

# Find or create admin
user = env['res.users'].search([
    '|',
    ('login', '=', 'jgtolentino_rn@yahoo.com'),
    ('login', '=', 'jgtolentino.rn@gmail.com')
], limit=1)

if not user:
    user = env['res.users'].create({
        'name': 'Admin',
        'login': 'jgtolentino_rn@yahoo.com',
        'email': 'jgtolentino_rn@yahoo.com',
        'password': 'admin123',
    })
    print(f"✅ User created (ID: {user.id})")
else:
    user.password = 'admin123'
    print(f"✅ User updated (ID: {user.id})")

# Grant admin rights
admin_group = env.ref('base.group_system')
if admin_group.id not in user.groups_id.ids:
    user.groups_id = [(4, admin_group.id)]
    print("✅ Admin rights granted")

env.cr.commit()
PYEOF

echo ""

# ============================================================================
# 2. INSTALL BASE MODULES
# ============================================================================
echo "📦 Installing base modules..."
docker exec -i "$CONTAINER" odoo -d "$DB_NAME" \
  -i base,web,project,mail \
  --stop-after-init \
  --db_host=db \
  --db_port=5432 \
  --db_user=odoo \
  --db_password=odoo 2>/dev/null || echo "Modules already installed"

echo ""

# ============================================================================
# 3. CREATE CI/CD PIPELINE PROJECT
# ============================================================================
echo "📊 Creating CI/CD Pipeline project..."
docker exec -i "$CONTAINER" odoo shell -d "$DB_NAME" <<'PYEOF'
env = env.sudo()

# Create project
proj = env['project.project'].search([('name', '=', 'CI/CD Pipeline')], limit=1)
if not proj:
    proj = env['project.project'].create({
        'name': 'CI/CD Pipeline',
        'privacy_visibility': 'followers',
    })
    print(f"✅ Project created (ID: {proj.id})")
else:
    print(f"✅ Project exists (ID: {proj.id})")

# Create stages
stages = ['Backlog', 'Spec Review', 'In PR', 'CI Green', 'Staging ✅', 'Ready for Prod', 'Deployed', 'Blocked']
for s in stages:
    if not env['project.task.type'].search([('name', '=', s), ('project_ids', 'in', proj.id)], limit=1):
        env['project.task.type'].create({'name': s, 'project_ids': [(4, proj.id)]})
        print(f"  ✅ Stage: {s}")

env.cr.commit()
PYEOF

echo ""

# ============================================================================
# 4. ADD CUSTOM FIELDS
# ============================================================================
echo "🔧 Adding custom fields..."
docker exec -i "$CONTAINER" odoo shell -d "$DB_NAME" <<'PYEOF'
env = env.sudo()
IrModelFields = env['ir.model.fields']
task_model_id = env['ir.model']._get_id('project.task')

def add_field(name, desc, ftype, **kwargs):
    if not IrModelFields.search([('model', '=', 'project.task'), ('name', '=', name)], limit=1):
        vals = {'name': name, 'model_id': task_model_id, 'field_description': desc, 'ttype': ftype, 'store': True}
        vals.update(kwargs)
        IrModelFields.create(vals)
        print(f"  ✅ {name}")

add_field('x_pr_number', 'PR Number', 'integer')
add_field('x_pr_url', 'PR URL', 'char', size=512)
add_field('x_repo', 'Repository', 'char', size=256)
add_field('x_build_status', 'Build Status', 'selection',
          selection="[('queued','Queued'),('running','Running'),('passed','Passed'),('failed','Failed')]")
add_field('x_env', 'Environment', 'selection',
          selection="[('preview','Preview'),('staging','Staging'),('prod','Production')]")

env.cr.commit()
PYEOF

echo ""

# ============================================================================
# 5. CREATE DISCUSS CHANNEL
# ============================================================================
echo "💬 Creating #ci-updates channel..."
docker exec -i "$CONTAINER" odoo shell -d "$DB_NAME" <<'PYEOF'
env = env.sudo()

channel = env['discuss.channel'].search([('name', '=', 'ci-updates')], limit=1)
if not channel:
    channel = env['discuss.channel'].create({
        'name': 'ci-updates',
        'channel_type': 'channel',
        'description': 'CI/CD notifications (Your Own Slack)',
    })
    print(f"✅ Channel created (ID: {channel.id})")

    # Post welcome message
    channel.message_post(
        body="<p>🤖 SuperClaude CI/CD System Ready</p>",
        message_type='comment',
    )
else:
    print(f"✅ Channel exists (ID: {channel.id})")

env.cr.commit()
PYEOF

echo ""

# ============================================================================
# DONE
# ============================================================================
echo "═══════════════════════════════════════════════════════════════"
echo "✅ SETUP COMPLETE!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "🔑 Login Credentials:"
echo "   URL:      http://localhost:8069"
echo "   Email:    jgtolentino_rn@yahoo.com"
echo "   Password: admin123"
echo ""
echo "📊 What was created:"
echo "   ✅ Admin user with full access"
echo "   ✅ CI/CD Pipeline project (8 stages)"
echo "   ✅ Custom fields (x_pr_number, x_build_status, etc.)"
echo "   ✅ #ci-updates Discuss channel"
echo ""
echo "🚀 Next steps:"
echo "   1. Log in at http://localhost:8069"
echo "   2. Go to Project → CI/CD Pipeline"
echo "   3. Go to Discuss → #ci-updates"
echo ""
echo "⚠️  Change password after first login!"
echo "═══════════════════════════════════════════════════════════════"
