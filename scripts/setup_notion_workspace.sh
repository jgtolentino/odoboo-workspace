#!/bin/bash
# Setup Notion-style workspace in Odoo with CI/CD Pipeline project
#
# Features:
# - CI/CD Pipeline project with custom workflow stages
# - Custom fields for PR tracking (PR number, URL, repo, build status, environment)
# - Discuss channel for CI/CD notifications (#ci-updates)
# - Kanban board with 8 workflow stages
#
# Usage:
#   DB_NAME=twba-fin-ops ./scripts/setup_notion_workspace.sh
#   # Or with custom database:
#   DB_NAME=your_database ./scripts/setup_notion_workspace.sh

set -e

DB_NAME="${DB_NAME:-twba-fin-ops}"
ODOO_CTN="${ODOO_CTN:-odoo18}"

echo "🚀 Setting up Notion-style workspace in Odoo..."
echo "   Database: $DB_NAME"
echo "   Container: $ODOO_CTN"
echo ""

docker exec -i "$ODOO_CTN" odoo shell -d "$DB_NAME" <<'PYEOF'
print("🚀 STARTING NOTION-STYLE WORKSPACE SETUP...")
print("")

# 1. Create/Update Admin User
print("👤 Setting up admin user...")
user = env['res.users'].search([
    '|',
    ('login', '=', 'jgtolentino_rn@yahoo.com'),
    ('login', '=', 'admin')
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

# 2. Create CI/CD Pipeline Project
print("\n📊 Creating CI/CD Pipeline project...")
proj = env['project.project'].search([('name', '=', 'CI/CD Pipeline')], limit=1)
if not proj:
    proj = env['project.project'].create({
        'name': 'CI/CD Pipeline',
        'privacy_visibility': 'followers',
    })
    print(f"✅ Project created (ID: {proj.id})")
else:
    print(f"✅ Project exists (ID: {proj.id})")

# 3. Create Stages (Notion-style workflow)
print("\n📋 Creating workflow stages...")
stages_data = [
    {'name': 'Backlog', 'sequence': 1, 'fold': False},
    {'name': 'Spec Review', 'sequence': 2, 'fold': False},
    {'name': 'In PR', 'sequence': 3, 'fold': False},
    {'name': 'CI Green', 'sequence': 4, 'fold': False},
    {'name': 'Staging ✅', 'sequence': 5, 'fold': False},
    {'name': 'Ready for Prod', 'sequence': 6, 'fold': False},
    {'name': 'Deployed', 'sequence': 7, 'fold': True},
    {'name': 'Blocked', 'sequence': 8, 'fold': False},
]

for stage_data in stages_data:
    stage = env['project.task.type'].search([
        ('name', '=', stage_data['name']),
        ('project_ids', 'in', proj.id)
    ], limit=1)

    if not stage:
        stage_data['project_ids'] = [(4, proj.id)]
        env['project.task.type'].create(stage_data)
        print(f"  ✅ {stage_data['name']}")
    else:
        print(f"  ⏭️  {stage_data['name']} (exists)")

# 4. Add Custom Fields for CI/CD tracking
print("\n🔧 Adding custom fields...")
IrModelFields = env['ir.model.fields']
task_model_id = env['ir.model']._get_id('project.task')

fields_to_add = [
    {'name': 'x_pr_number', 'field_description': 'PR Number', 'ttype': 'integer'},
    {'name': 'x_pr_url', 'field_description': 'PR URL', 'ttype': 'char', 'size': 512},
    {'name': 'x_repo', 'field_description': 'Repository', 'ttype': 'char', 'size': 256},
    {
        'name': 'x_build_status',
        'field_description': 'Build Status',
        'ttype': 'selection',
        'selection': "[('queued','Queued'),('running','Running'),('passed','Passed'),('failed','Failed')]"
    },
    {
        'name': 'x_env',
        'field_description': 'Environment',
        'ttype': 'selection',
        'selection': "[('preview','Preview'),('staging','Staging'),('prod','Production')]"
    },
    {'name': 'x_deploy_url', 'field_description': 'Deploy URL', 'ttype': 'char', 'size': 512},
    {'name': 'x_commit_sha', 'field_description': 'Commit SHA', 'ttype': 'char', 'size': 64},
    {'name': 'x_author', 'field_description': 'Author', 'ttype': 'char', 'size': 128},
    {'name': 'x_merged_at', 'field_description': 'Merged At', 'ttype': 'datetime'},
]

for field in fields_to_add:
    if not IrModelFields.search([('model', '=', 'project.task'), ('name', '=', field['name'])], limit=1):
        vals = {
            'name': field['name'],
            'model_id': task_model_id,
            'field_description': field['field_description'],
            'ttype': field['ttype'],
            'store': True
        }
        if 'size' in field:
            vals['size'] = field['size']
        if 'selection' in field:
            vals['selection'] = field['selection']

        IrModelFields.create(vals)
        print(f"  ✅ {field['name']}")
    else:
        print(f"  ⏭️  {field['name']} (exists)")

# 5. Create Discuss Channel for CI/CD notifications
print("\n💬 Creating #ci-updates channel...")
channel = env['discuss.channel'].search([('name', '=', 'ci-updates')], limit=1)
if not channel:
    channel = env['discuss.channel'].create({
        'name': 'ci-updates',
        'channel_type': 'channel',
        'description': 'CI/CD notifications (Your Own Slack)',
    })
    channel.message_post(
        body="<p>🤖 SuperClaude CI/CD System Ready</p><p>This channel will receive automated notifications for:</p><ul><li>PR status updates</li><li>Build success/failures</li><li>Deployment notifications</li><li>Staging/Production releases</li></ul>",
        message_type='comment',
    )
    print(f"✅ Channel created (ID: {channel.id})")
else:
    print(f"✅ Channel exists (ID: {channel.id})")

# 6. Create sample tasks to demonstrate workflow
print("\n📝 Creating sample tasks...")
sample_tasks = [
    {
        'name': 'Setup automated deployments',
        'stage': 'Backlog',
        'x_repo': 'odoboo-workspace',
        'x_pr_number': 1,
    },
    {
        'name': 'Add visual regression tests',
        'stage': 'Spec Review',
        'x_repo': 'odoboo-workspace',
    },
    {
        'name': 'Implement OCR expense scanning',
        'stage': 'In PR',
        'x_repo': 'odoboo-workspace',
        'x_pr_number': 42,
        'x_pr_url': 'https://github.com/jgtolentino/odoboo-workspace/pull/42',
        'x_build_status': 'running',
    },
]

for task_data in sample_tasks:
    stage_name = task_data.pop('stage')
    stage = env['project.task.type'].search([
        ('name', '=', stage_name),
        ('project_ids', 'in', proj.id)
    ], limit=1)

    existing = env['project.task'].search([
        ('name', '=', task_data['name']),
        ('project_id', '=', proj.id)
    ], limit=1)

    if not existing:
        task_data['project_id'] = proj.id
        task_data['stage_id'] = stage.id if stage else False
        env['project.task'].create(task_data)
        print(f"  ✅ {task_data['name']}")
    else:
        print(f"  ⏭️  {task_data['name']} (exists)")

env.cr.commit()

print("\n" + "="*60)
print("✅ NOTION-STYLE WORKSPACE READY!")
print("="*60)
print("\n🔑 Login at: https://insightpulseai.net")
print("   Email:    jgtolentino_rn@yahoo.com")
print("   Password: admin123")
print("\n📊 Created:")
print("   ✅ Admin user with full access")
print("   ✅ CI/CD Pipeline project")
print("   ✅ 8 workflow stages (Backlog → Deployed)")
print("   ✅ 9 custom fields (PR tracking, builds, deployments)")
print("   ✅ #ci-updates channel (Slack-style notifications)")
print("   ✅ 3 sample tasks (demonstrating workflow)")
print("\n🎯 Next steps:")
print("   1. Open: Project → CI/CD Pipeline")
print("   2. Switch to Kanban view (group by stage)")
print("   3. Open: Discuss → #ci-updates")
print("   4. Customize views and create your tasks")
print("="*60)
PYEOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "🌐 Access your Notion-style workspace:"
echo "   https://insightpulseai.net/web#action=project.action_view_all_task"
echo ""
