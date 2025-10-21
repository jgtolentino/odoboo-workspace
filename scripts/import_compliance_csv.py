#!/usr/bin/env python3
"""
Import compliance/regulatory CSV data into Odoo project.task

Usage:
    python3 import_compliance_csv.py <csv_file> <project_name>

Example:
    python3 import_compliance_csv.py data/compliance_master.csv "Compliance Master"

CSV Columns Expected (flexible, will use what's available):
- Task / Description (required) - Task name
- Task Category - Category tag
- Frequency - Frequency tag
- Owner - Task owner
- Reviewer - Reviewer name
- Approver - Approver name
- Status - Status text
- Evidence Link - URL to evidence
- Due Window - Due window description
- Form - Form type/number
- Period Covered - Period description
- BIR Deadline - Date (YYYY-MM-DD or MM/DD/YYYY)
- Prep Target - Date
- Review Target - Date
- Approval Target - Date
"""

import os
import sys
import csv
import xmlrpc.client
from datetime import datetime

# Configuration from environment
ODOO_URL = os.getenv("ODOO_URL", "http://localhost:8069")
ODOO_DB = os.getenv("ODOO_DB", "odoboo_local")
ODOO_USER = os.getenv("ODOO_USER", "jgtolentino_rn@yahoo.com")
ODOO_PASSWORD = os.getenv("ODOO_PASSWORD", "admin123")

def parse_date(date_str):
    """Parse date from various formats"""
    if not date_str or not date_str.strip():
        return None

    date_str = date_str.strip()

    # Try YYYY-MM-DD
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').strftime('%Y-%m-%d')
    except:
        pass

    # Try MM/DD/YYYY
    try:
        return datetime.strptime(date_str, '%m/%d/%Y').strftime('%Y-%m-%d')
    except:
        pass

    # Try DD/MM/YYYY
    try:
        return datetime.strptime(date_str, '%d/%m/%Y').strftime('%Y-%m-%d')
    except:
        pass

    return None

def find_or_create_project(models, uid, password, db, name):
    """Find existing project or create new one"""
    project_ids = models.execute_kw(
        db, uid, password,
        'project.project', 'search',
        [[('name', '=', name)]],
        {'limit': 1}
    )

    if project_ids:
        print(f"✅ Using existing project: {name} (ID: {project_ids[0]})")
        return project_ids[0]

    project_id = models.execute_kw(
        db, uid, password,
        'project.project', 'create',
        [{'name': name, 'privacy_visibility': 'followers'}]
    )

    print(f"✅ Created new project: {name} (ID: {project_id})")
    return project_id

def find_or_create_tag(models, uid, password, db, name):
    """Find existing tag or create new one"""
    if not name or not name.strip():
        return None

    name = name.strip()

    tag_ids = models.execute_kw(
        db, uid, password,
        'project.tags', 'search',
        [[('name', '=', name)]],
        {'limit': 1}
    )

    if tag_ids:
        return tag_ids[0]

    tag_id = models.execute_kw(
        db, uid, password,
        'project.tags', 'create',
        [{'name': name}]
    )

    return tag_id

def import_csv(csv_path, project_name):
    """Import CSV into Odoo"""

    print("📊 Importing compliance data to Odoo...")
    print(f"   URL: {ODOO_URL}")
    print(f"   Database: {ODOO_DB}")
    print(f"   User: {ODOO_USER}")
    print(f"   CSV: {csv_path}")
    print(f"   Project: {project_name}")
    print("")

    # Connect to Odoo
    common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
    uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_PASSWORD, {})

    if not uid:
        print("❌ Authentication failed. Check credentials.")
        sys.exit(1)

    print(f"✅ Authenticated as user ID {uid}")

    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")

    # Find or create project
    project_id = find_or_create_project(models, uid, ODOO_PASSWORD, ODOO_DB, project_name)
    print("")

    # Read CSV
    if not os.path.exists(csv_path):
        print(f"❌ CSV file not found: {csv_path}")
        sys.exit(1)

    tasks_created = 0
    tasks_skipped = 0

    with open(csv_path, 'r', encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)

        print("📋 Processing tasks...")
        print("")

        for row in reader:
            # Get task name
            task_name = row.get('Task') or row.get('Description') or row.get('Name')
            if not task_name or not task_name.strip():
                tasks_skipped += 1
                continue

            task_name = task_name.strip()

            # Check if task already exists in this project
            existing = models.execute_kw(
                ODOO_DB, uid, ODOO_PASSWORD,
                'project.task', 'search',
                [[('name', '=', task_name), ('project_id', '=', project_id)]],
                {'limit': 1}
            )

            if existing:
                print(f"  ⏭️  {task_name} - already exists")
                tasks_skipped += 1
                continue

            # Collect tags
            tags = []
            if row.get('Task Category'):
                tag_id = find_or_create_tag(models, uid, ODOO_PASSWORD, ODOO_DB, row['Task Category'])
                if tag_id:
                    tags.append(tag_id)

            if row.get('Frequency'):
                tag_id = find_or_create_tag(models, uid, ODOO_PASSWORD, ODOO_DB, row['Frequency'])
                if tag_id:
                    tags.append(tag_id)

            # Build task values
            task_vals = {
                'name': task_name,
                'project_id': project_id,
            }

            # Add tags
            if tags:
                task_vals['tag_ids'] = [(6, 0, tags)]

            # Add deadline
            bir_deadline = parse_date(row.get('BIR Deadline', ''))
            if bir_deadline:
                task_vals['date_deadline'] = bir_deadline

            # Add custom fields (safely, only if they exist)
            custom_fields = {
                'x_task_category': row.get('Task Category'),
                'x_frequency': row.get('Frequency'),
                'x_owner': row.get('Owner'),
                'x_reviewer': row.get('Reviewer'),
                'x_approver': row.get('Approver'),
                'x_status_text': row.get('Status'),
                'x_evidence_url': row.get('Evidence Link'),
                'x_due_window': row.get('Due Window'),
                'x_form': row.get('Form'),
                'x_period_covered': row.get('Period Covered'),
                'x_bir_deadline': parse_date(row.get('BIR Deadline', '')),
                'x_prep_target': parse_date(row.get('Prep Target', '')),
                'x_review_target': parse_date(row.get('Review Target', '')),
                'x_approval_target': parse_date(row.get('Approval Target', '')),
            }

            # Only add non-None values
            for key, value in custom_fields.items():
                if value:
                    task_vals[key] = value

            # Create task
            try:
                task_id = models.execute_kw(
                    ODOO_DB, uid, ODOO_PASSWORD,
                    'project.task', 'create',
                    [task_vals]
                )
                print(f"  ✅ {task_name} (ID: {task_id})")
                tasks_created += 1
            except Exception as e:
                print(f"  ❌ {task_name} - Error: {e}")
                tasks_skipped += 1

    print("")
    print("="*60)
    print(f"✅ Import complete!")
    print(f"   Created: {tasks_created}")
    print(f"   Skipped: {tasks_skipped}")
    print("="*60)
    print("")
    print(f"🎯 View tasks at: {ODOO_URL}/web#action=project.action_view_all_task&model=project.task&view_type=kanban&cids=1&menu_id=")
    print("")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 import_compliance_csv.py <csv_file> <project_name>")
        print("")
        print("Example:")
        print("  python3 import_compliance_csv.py data/compliance.csv 'Compliance Master'")
        sys.exit(1)

    csv_path = sys.argv[1]
    project_name = sys.argv[2]

    import_csv(csv_path, project_name)
