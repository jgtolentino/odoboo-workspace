#!/usr/bin/env python3
"""
Quick verification script for Odoo custom field creation
Tests the field creation logic before running on production
"""

# This script is designed to be run via: docker exec -i odoo18 python3 < test_odoo_fields.py
# Or interactively via: docker exec -it odoo18 odoo shell -d <dbname>

import sys

# Simulate the Odoo shell environment structure
# In actual Odoo shell, 'env' is already available

FIELD_DEFINITIONS = [
    {
        'name': 'x_pr_number',
        'description': 'PR Number',
        'type': 'integer',
        'extra': {}
    },
    {
        'name': 'x_pr_url',
        'description': 'PR URL',
        'type': 'char',
        'extra': {'size': 512}
    },
    {
        'name': 'x_repo',
        'description': 'Repository',
        'type': 'char',
        'extra': {'size': 256}
    },
    {
        'name': 'x_commit_sha',
        'description': 'Commit SHA',
        'type': 'char',
        'extra': {'size': 64}
    },
    {
        'name': 'x_author',
        'description': 'Author',
        'type': 'char',
        'extra': {'size': 128}
    },
    {
        'name': 'x_deploy_url',
        'description': 'Deploy URL',
        'type': 'char',
        'extra': {'size': 512}
    },
    {
        'name': 'x_build_status',
        'description': 'Build Status',
        'type': 'selection',
        'extra': {
            'selection': "[('queued','Queued'),('running','Running'),('passed','Passed'),('failed','Failed')]"
        }
    },
    {
        'name': 'x_env',
        'description': 'Environment',
        'type': 'selection',
        'extra': {
            'selection': "[('preview','Preview'),('staging','Staging'),('prod','Production')]"
        }
    },
    {
        'name': 'x_agent_notes',
        'description': 'Agent Notes',
        'type': 'text',
        'extra': {}
    },
]


def validate_field_definitions():
    """Validate that field definitions are correctly structured"""
    print("=" * 70)
    print("ODOO CUSTOM FIELD VALIDATION")
    print("=" * 70)
    print()

    errors = []

    for i, field in enumerate(FIELD_DEFINITIONS, 1):
        print(f"{i}. {field['name']} ({field['type']})")

        # Check required keys
        required = ['name', 'description', 'type', 'extra']
        for key in required:
            if key not in field:
                errors.append(f"  ❌ Missing '{key}' in {field['name']}")
                continue

        # Validate field name (must start with x_)
        if not field['name'].startswith('x_'):
            errors.append(f"  ❌ Field name must start with 'x_': {field['name']}")

        # Validate type
        valid_types = ['char', 'text', 'integer', 'float', 'boolean',
                       'date', 'datetime', 'selection', 'many2one', 'one2many']
        if field['type'] not in valid_types:
            errors.append(f"  ❌ Invalid type '{field['type']}' for {field['name']}")

        # Type-specific validations
        if field['type'] == 'char' and 'size' not in field['extra']:
            errors.append(f"  ⚠️  Warning: char field without size: {field['name']}")

        if field['type'] == 'selection' and 'selection' not in field['extra']:
            errors.append(f"  ❌ selection field missing 'selection' key: {field['name']}")

        # Validate selection format
        if field['type'] == 'selection':
            try:
                # Check if selection string is valid Python list
                sel = field['extra']['selection']
                if not sel.startswith('[') or not sel.endswith(']'):
                    errors.append(f"  ❌ Invalid selection format for {field['name']}")
            except Exception as e:
                errors.append(f"  ❌ Error validating selection for {field['name']}: {e}")

        # Print field summary
        if not any(field['name'] in err for err in errors):
            print(f"   ✓ {field['description']}")
            if field['extra']:
                for key, val in field['extra'].items():
                    print(f"     • {key}: {val}")
        print()

    # Summary
    print("=" * 70)
    if errors:
        print(f"❌ VALIDATION FAILED ({len(errors)} errors)")
        print("=" * 70)
        for err in errors:
            print(err)
        return False
    else:
        print(f"✅ VALIDATION PASSED (all {len(FIELD_DEFINITIONS)} fields valid)")
        print("=" * 70)
        return True


def generate_odoo_shell_script():
    """Generate the actual Odoo shell script for field creation"""
    print()
    print("=" * 70)
    print("GENERATED ODOO SHELL SCRIPT")
    print("=" * 70)
    print()
    print("# Copy this into: docker exec -i odoo18 odoo shell -d <dbname>")
    print()
    print("env = env.sudo()")
    print("IrModelFields = env['ir.model.fields']")
    print("task_model_id = env['ir.model']._get_id('project.task')")
    print()

    for field in FIELD_DEFINITIONS:
        print(f"# {field['description']}")
        print(f"existing = IrModelFields.search([")
        print(f"    ('model', '=', 'project.task'),")
        print(f"    ('name', '=', '{field['name']}')")
        print(f"], limit=1)")
        print()
        print(f"if not existing:")
        print(f"    vals = {{")
        print(f"        'name': '{field['name']}',")
        print(f"        'model_id': task_model_id,")
        print(f"        'field_description': '{field['description']}',")
        print(f"        'ttype': '{field['type']}',")
        print(f"        'store': True,")

        for key, val in field['extra'].items():
            if isinstance(val, str):
                print(f"        '{key}': {val},")  # For selection (already quoted)
            else:
                print(f"        '{key}': {val},")

        print(f"    }}")
        print(f"    IrModelFields.create(vals)")
        print(f"    print('Created: {field['name']}')")
        print(f"else:")
        print(f"    print('Exists: {field['name']}')")
        print()


if __name__ == '__main__':
    # Run validation
    valid = validate_field_definitions()

    if valid:
        # Generate shell script
        generate_odoo_shell_script()
        sys.exit(0)
    else:
        sys.exit(1)
