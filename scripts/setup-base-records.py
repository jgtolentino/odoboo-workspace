#!/usr/bin/env python3
"""
Base Records Setup for Notion-Style Workspace
Creates foundational records: Projects, Folders, Tags, Users, Stages, etc.

Usage:
    docker exec -i odoo18 python3 /mnt/scripts/setup-base-records.py

Or via odoo shell:
    docker exec -i odoo18 odoo shell -d odoo_production < setup-base-records.py
"""

import logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

print("=" * 70)
print("  Base Records Setup for Notion-Style Workspace")
print("=" * 70)
print()

def create_base_records(env):
    """Create all base records required for the workspace"""

    # =========================================================================
    # 1. CREATE MAIN PROJECT
    # =========================================================================
    print("▶ Creating main project...")

    project = env['project.project'].search([('name', '=', 'Compliance & Month-End')], limit=1)
    if not project:
        project = env['project.project'].create({
            'name': 'Compliance & Month-End',
            'privacy_visibility': 'portal',  # Portal users can access
            'allow_subtasks': True,
            'allow_recurring_tasks': True,
            'alias_enabled': True,  # Enable email alias
            'alias_name': 'compliance',  # compliance@domain.com creates tasks
        })
        print(f"✓ Created project: {project.name} (ID: {project.id})")
    else:
        print(f"⏭️  Project already exists: {project.name} (ID: {project.id})")

    # =========================================================================
    # 2. CREATE PROJECT STAGES (Kanban columns)
    # =========================================================================
    print("\n▶ Creating project stages...")

    stages_config = [
        ('Backlog', 1, False, '#D3D3D3'),      # Gray
        ('To Do', 2, False, '#87CEEB'),        # Light blue
        ('Doing', 3, False, '#FFD700'),        # Gold
        ('Review', 4, False, '#FFA500'),       # Orange
        ('Done', 5, True, '#90EE90'),          # Light green
        ('Blocked', 6, False, '#FF6B6B'),      # Red
    ]

    stages = {}
    for name, sequence, fold, color in stages_config:
        stage = env['project.task.type'].search([
            ('name', '=', name),
            ('project_ids', 'in', project.id)
        ], limit=1)

        if not stage:
            stage = env['project.task.type'].create({
                'name': name,
                'sequence': sequence,
                'fold': fold,
                'project_ids': [(4, project.id)],
                # Note: color requires web_widget_colorpicker module
            })
            print(f"  ✓ Created stage: {name}")
        else:
            print(f"  ⏭️  Stage exists: {name}")

        stages[name] = stage

    # =========================================================================
    # 3. CREATE TAGS
    # =========================================================================
    print("\n▶ Creating tags...")

    tags_config = [
        # Areas
        ('Month-End', '#FF6B6B'),
        ('Tax', '#4ECDC4'),
        ('Procurement', '#95E1D3'),
        ('Expenses', '#F38181'),
        ('Compliance', '#AA96DA'),

        # Categories
        ('Finance', '#3D84A8'),
        ('Statutory', '#FFAB73'),
        ('Vendor Management', '#C9CBCF'),
        ('Reporting', '#90AACB'),

        # Priority
        ('High Priority', '#FF0000'),
        ('Medium Priority', '#FFA500'),
        ('Low Priority', '#00FF00'),

        # Status
        ('Approval Needed', '#FFD700'),
        ('Blocked', '#DC143C'),
        ('Recurring', '#9370DB'),
    ]

    tags = {}
    for name, color in tags_config:
        tag = env['project.tags'].search([('name', '=', name)], limit=1)
        if not tag:
            tag = env['project.tags'].create({'name': name})
            print(f"  ✓ Created tag: {name}")
        else:
            print(f"  ⏭️  Tag exists: {name}")
        tags[name] = tag

    # =========================================================================
    # 4. CREATE DMS FOLDER STRUCTURE
    # =========================================================================
    print("\n▶ Creating DMS folder structure...")

    # Check if DMS is installed
    if not env['ir.module.module'].search([
        ('name', '=', 'dms'),
        ('state', '=', 'installed')
    ]):
        print("  ⚠️  DMS module not installed, skipping folder creation")
    else:
        # Create root storage
        storage = env['dms.storage'].search([('name', '=', 'Compliance Evidence Storage')], limit=1)
        if not storage:
            storage = env['dms.storage'].create({
                'name': 'Compliance Evidence Storage',
                'save_type': 'database',  # Store in database (change to 'attachment' for filesystem)
            })
            print(f"  ✓ Created DMS storage: {storage.name}")

        # Create root directory
        root_dir = env['dms.directory'].search([
            ('name', '=', 'Compliance Evidence'),
            ('parent_id', '=', False)
        ], limit=1)

        if not root_dir:
            root_dir = env['dms.directory'].create({
                'name': 'Compliance Evidence',
                'storage_id': storage.id,
            })
            print(f"  ✓ Created root directory: {root_dir.name}")

        # Create subdirectories
        subdirs = [
            'Month-End Closing',
            'Tax Filing',
            'Bank Reconciliations',
            'Financial Statements',
            'Vendor Documents',
            'Expense Reports',
            'Audit Trail',
            'Statutory Filings',
            'Board Documents',
        ]

        for subdir_name in subdirs:
            subdir = env['dms.directory'].search([
                ('name', '=', subdir_name),
                ('parent_id', '=', root_dir.id)
            ], limit=1)

            if not subdir:
                subdir = env['dms.directory'].create({
                    'name': subdir_name,
                    'parent_id': root_dir.id,
                    'storage_id': storage.id,
                })
                print(f"    ✓ Created subdirectory: {subdir_name}")

    # =========================================================================
    # 5. CREATE KNOWLEDGE BASE STRUCTURE
    # =========================================================================
    print("\n▶ Creating Knowledge base structure...")

    # Check if document_page is installed
    if not env['ir.module.module'].search([
        ('name', '=', 'document_page'),
        ('state', '=', 'installed')
    ]):
        print("  ⚠️  document_page module not installed, skipping knowledge pages")
    else:
        # Create root page
        root_page = env['document.page'].search([
            ('name', '=', 'Operations Workspace'),
            ('parent_id', '=', False)
        ], limit=1)

        if not root_page:
            root_page = env['document.page'].create({
                'name': 'Operations Workspace',
                'content': '''<h1>Welcome to Operations Workspace</h1>
<p>This is your central hub for compliance, finance, and operational knowledge.</p>
<h2>Quick Links</h2>
<ul>
<li>Month-End Closing Process</li>
<li>Tax Filing Guidelines</li>
<li>Procurement Procedures</li>
<li>Expense Management</li>
<li>Bank Reconciliation SOP</li>
<li>Financial Reporting Guide</li>
</ul>
<h2>Key Contacts</h2>
<ul>
<li>Finance Team: finance@company.com</li>
<li>Tax Team: tax@company.com</li>
<li>Procurement: procurement@company.com</li>
</ul>
''',
                'type': 'content',
            })
            print(f"  ✓ Created knowledge root page: {root_page.name}")
        else:
            print(f"  ⏭️  Root page exists: {root_page.name}")

    # =========================================================================
    # 6. CREATE CALENDAR EVENT TYPES
    # =========================================================================
    print("\n▶ Creating calendar event types...")

    event_types = [
        ('Tax Deadlines', '#FF6B6B'),
        ('Finance Meetings', '#4ECDC4'),
        ('Procurement', '#95E1D3'),
        ('Internal Deadlines', '#F38181'),
        ('Regulatory Deadlines', '#AA96DA'),
        ('Statutory Deadlines', '#FFAB73'),
        ('Board Meetings', '#3D84A8'),
    ]

    for name, color in event_types:
        categ = env['calendar.event.type'].search([('name', '=', name)], limit=1)
        if not categ:
            categ = env['calendar.event.type'].create({'name': name})
            print(f"  ✓ Created event type: {name}")
        else:
            print(f"  ⏭️  Event type exists: {name}")

    # =========================================================================
    # 7. CREATE CALENDAR ALARMS
    # =========================================================================
    print("\n▶ Creating calendar alarm templates...")

    alarms = [
        ('1 day before', -1, 'days'),
        ('2 days before', -2, 'days'),
        ('3 days before', -3, 'days'),
        ('1 week before', -7, 'days'),
        ('1 hour before', -60, 'minutes'),
        ('30 minutes before', -30, 'minutes'),
    ]

    for name, interval, interval_type in alarms:
        alarm = env['calendar.alarm'].search([('name', '=', name)], limit=1)
        if not alarm:
            alarm = env['calendar.alarm'].create({
                'name': name,
                'interval': abs(interval),
                'interval_type': interval_type,
                'alarm_type': 'notification',
            })
            print(f"  ✓ Created alarm: {name}")
        else:
            print(f"  ⏭️  Alarm exists: {name}")

    # =========================================================================
    # 8. CREATE SAMPLE USERS (if needed)
    # =========================================================================
    print("\n▶ Creating sample users...")

    users_config = [
        ('accountant@company.com', 'Staff Accountant', 'Accountant'),
        ('tax@company.com', 'Tax Specialist', 'Tax'),
        ('am@company.com', 'Account Manager', 'Account Manager'),
        ('finance.director@company.com', 'Finance Director', 'Finance Director'),
        ('cfo@company.com', 'Chief Financial Officer', 'CFO'),
    ]

    for email, name, login in users_config:
        user = env['res.users'].search([('login', '=', email)], limit=1)
        if not user:
            # Check if partner exists
            partner = env['res.partner'].search([('email', '=', email)], limit=1)
            if not partner:
                partner = env['res.partner'].create({
                    'name': name,
                    'email': email,
                    'company_type': 'person',
                })

            print(f"  ⚠️  User '{email}' does not exist. Partner created, but user creation requires password.")
            print(f"     Create user manually via Settings → Users → Create")
        else:
            print(f"  ⏭️  User exists: {email}")

    env.cr.commit()

    print("\n" + "=" * 70)
    print("  ✓ Base Records Setup Complete!")
    print("=" * 70)
    print("\nCreated:")
    print(f"  - Project: {project.name}")
    print(f"  - Stages: {len(stages)} stages")
    print(f"  - Tags: {len(tags)} tags")
    print(f"  - Calendar event types: {len(event_types)}")
    print(f"  - Calendar alarms: {len(alarms)}")
    if env['ir.module.module'].search([('name', '=', 'dms'), ('state', '=', 'installed')]):
        print(f"  - DMS folders: 1 root + {len(subdirs)} subdirectories")
    if env['ir.module.module'].search([('name', '=', 'document_page'), ('state', '=', 'installed')]):
        print(f"  - Knowledge pages: 1 root page")

    print("\nNext steps:")
    print("  1. Import data using CSV templates in data/templates/")
    print("  2. Run setup-workflows.py to configure email alerts")
    print("  3. Access Odoo at https://insightpulseai.net:8069")
    print()

# Run if called directly via odoo shell
if __name__ != '__main__':
    # Running inside odoo shell
    create_base_records(env)
