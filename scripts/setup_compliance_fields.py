#!/usr/bin/env python3
"""
Setup custom fields for Compliance/Regulatory tracking in Odoo project.task

Fields added:
- x_task_category (Text) - Task Category (Tax, Regulatory, etc.)
- x_frequency (Text) - Frequency (Monthly, Quarterly, Annual)
- x_owner (Text) - Task Owner
- x_reviewer (Text) - Reviewer
- x_approver (Text) - Approver
- x_status_text (Text) - Status
- x_evidence_url (Char) - Evidence Link URL
- x_due_window (Text) - Due Window
- x_form (Text) - Form type/number
- x_period_covered (Text) - Period Covered
- x_bir_deadline (Date) - BIR Deadline
- x_prep_target (Date) - Prep Target Date
- x_review_target (Date) - Review Target Date
- x_approval_target (Date) - Approval Target Date
"""

import os
import sys
import xmlrpc.client

# Configuration from environment
ODOO_URL = os.getenv("ODOO_URL", "http://localhost:8069")
ODOO_DB = os.getenv("ODOO_DB", "odoboo_local")
ODOO_USER = os.getenv("ODOO_USER", "jgtolentino_rn@yahoo.com")
ODOO_PASSWORD = os.getenv("ODOO_PASSWORD", "admin123")

def setup_fields():
    """Create custom fields on project.task model"""

    print("🔧 Setting up compliance tracking fields in Odoo...")
    print(f"   URL: {ODOO_URL}")
    print(f"   Database: {ODOO_DB}")
    print(f"   User: {ODOO_USER}")
    print("")

    # Connect to Odoo
    common = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/common")
    uid = common.authenticate(ODOO_DB, ODOO_USER, ODOO_PASSWORD, {})

    if not uid:
        print("❌ Authentication failed. Check credentials.")
        sys.exit(1)

    print(f"✅ Authenticated as user ID {uid}")

    models = xmlrpc.client.ServerProxy(f"{ODOO_URL}/xmlrpc/2/object")

    # Get project.task model ID
    task_model_id = models.execute_kw(
        ODOO_DB, uid, ODOO_PASSWORD,
        'ir.model', 'search',
        [[('model', '=', 'project.task')]]
    )[0]

    print(f"✅ Found project.task model (ID: {task_model_id})")
    print("")

    # Define custom fields
    fields = [
        {'name': 'x_task_category', 'field_description': 'Task Category', 'ttype': 'char', 'size': 128},
        {'name': 'x_frequency', 'field_description': 'Frequency', 'ttype': 'char', 'size': 64},
        {'name': 'x_owner', 'field_description': 'Owner', 'ttype': 'char', 'size': 128},
        {'name': 'x_reviewer', 'field_description': 'Reviewer', 'ttype': 'char', 'size': 128},
        {'name': 'x_approver', 'field_description': 'Approver', 'ttype': 'char', 'size': 128},
        {'name': 'x_status_text', 'field_description': 'Status', 'ttype': 'char', 'size': 64},
        {'name': 'x_evidence_url', 'field_description': 'Evidence Link', 'ttype': 'char', 'size': 512},
        {'name': 'x_due_window', 'field_description': 'Due Window', 'ttype': 'char', 'size': 128},
        {'name': 'x_form', 'field_description': 'Form', 'ttype': 'char', 'size': 128},
        {'name': 'x_period_covered', 'field_description': 'Period Covered', 'ttype': 'char', 'size': 128},
        {'name': 'x_bir_deadline', 'field_description': 'BIR Deadline', 'ttype': 'date'},
        {'name': 'x_prep_target', 'field_description': 'Prep Target', 'ttype': 'date'},
        {'name': 'x_review_target', 'field_description': 'Review Target', 'ttype': 'date'},
        {'name': 'x_approval_target', 'field_description': 'Approval Target', 'ttype': 'date'},
    ]

    print("📋 Creating custom fields...")
    created = 0
    skipped = 0

    for field in fields:
        # Check if field already exists
        existing = models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.model.fields', 'search',
            [[('model', '=', 'project.task'), ('name', '=', field['name'])]]
        )

        if existing:
            print(f"  ⏭️  {field['name']} - already exists")
            skipped += 1
            continue

        # Create field
        field_vals = {
            'name': field['name'],
            'model_id': task_model_id,
            'field_description': field['field_description'],
            'ttype': field['ttype'],
            'store': True,
        }

        if 'size' in field:
            field_vals['size'] = field['size']

        models.execute_kw(
            ODOO_DB, uid, ODOO_PASSWORD,
            'ir.model.fields', 'create',
            [field_vals]
        )

        print(f"  ✅ {field['name']} ({field['field_description']})")
        created += 1

    print("")
    print("="*60)
    print(f"✅ Field setup complete!")
    print(f"   Created: {created}")
    print(f"   Skipped: {skipped}")
    print("="*60)
    print("")
    print("🎯 Next steps:")
    print("   1. Run: python3 scripts/import_compliance_csv.py <csv_file> <project_name>")
    print("   2. Example: python3 scripts/import_compliance_csv.py data/compliance.csv 'Compliance Master'")
    print("")

if __name__ == '__main__':
    setup_fields()
