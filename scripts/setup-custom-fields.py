#!/usr/bin/env python3
"""
Custom Fields Setup for Notion-Style Workspace
Creates custom fields for linking tasks, evidence, and knowledge pages

Usage:
    docker exec -i odoo18 odoo shell -d odoo_production < setup-custom-fields.py
"""

print("=" * 70)
print("  Custom Fields Setup for Notion-Style Workspace")
print("=" * 70)
print()

def create_custom_fields(env):
    """Create custom fields for enhanced workspace functionality"""

    IrModelFields = env['ir.model.fields']
    IrModel = env['ir.model']

    # =========================================================================
    # 1. CUSTOM FIELDS ON PROJECT.TASK
    # =========================================================================
    print("▶ Creating custom fields on project.task...")

    task_model = IrModel.search([('model', '=', 'project.task')], limit=1)
    if not task_model:
        print("  ✗ project.task model not found!")
        return

    # Field: x_evidence_url (link to external evidence storage)
    if not IrModelFields.search([
        ('model_id', '=', task_model.id),
        ('name', '=', 'x_evidence_url')
    ]):
        IrModelFields.create({
            'model_id': task_model.id,
            'name': 'x_evidence_url',
            'field_description': 'Evidence URL',
            'ttype': 'char',
            'size': 512,
            'help': 'URL to evidence document (e.g., DigitalOcean Spaces, DMS)',
        })
        print("  ✓ Created field: x_evidence_url")
    else:
        print("  ⏭️  Field exists: x_evidence_url")

    # Field: x_area (compliance area)
    if not IrModelFields.search([
        ('model_id', '=', task_model.id),
        ('name', '=', 'x_area')
    ]):
        IrModelFields.create({
            'model_id': task_model.id,
            'name': 'x_area',
            'field_description': 'Compliance Area',
            'ttype': 'selection',
            'selection': str([
                ('month_end', 'Month-End Closing'),
                ('tax', 'Tax Filing'),
                ('procurement', 'Vendor Management'),
                ('expense', 'Expense Management'),
                ('compliance', 'Regulatory Compliance'),
                ('statutory', 'Statutory Compliance'),
                ('governance', 'Governance'),
            ]),
        })
        print("  ✓ Created field: x_area")
    else:
        print("  ⏭️  Field exists: x_area")

    # Field: x_knowledge_page_id (link to knowledge page)
    # Check if document_page module is installed
    if env['ir.module.module'].search([
        ('name', '=', 'document_page'),
        ('state', '=', 'installed')
    ]):
        knowledge_model = IrModel.search([('model', '=', 'document.page')], limit=1)
        if knowledge_model and not IrModelFields.search([
            ('model_id', '=', task_model.id),
            ('name', '=', 'x_knowledge_page_id')
        ]):
            IrModelFields.create({
                'model_id': task_model.id,
                'name': 'x_knowledge_page_id',
                'field_description': 'Related SOP/Guide',
                'ttype': 'many2one',
                'relation': 'document.page',
                'help': 'Link to related knowledge page (SOP, guide, etc.)',
            })
            print("  ✓ Created field: x_knowledge_page_id")
        elif IrModelFields.search([('model_id', '=', task_model.id), ('name', '=', 'x_knowledge_page_id')]):
            print("  ⏭️  Field exists: x_knowledge_page_id")
    else:
        print("  ⚠️  document_page module not installed, skipping x_knowledge_page_id")

    # Field: x_approval_status (for approval workflows)
    if not IrModelFields.search([
        ('model_id', '=', task_model.id),
        ('name', '=', 'x_approval_status')
    ]):
        IrModelFields.create({
            'model_id': task_model.id,
            'name': 'x_approval_status',
            'field_description': 'Approval Status',
            'ttype': 'selection',
            'selection': str([
                ('draft', 'Draft'),
                ('submitted', 'Submitted'),
                ('approved', 'Approved'),
                ('rejected', 'Rejected'),
            ]),
            'default': 'draft',
        })
        print("  ✓ Created field: x_approval_status")
    else:
        print("  ⏭️  Field exists: x_approval_status")

    # =========================================================================
    # 2. CUSTOM FIELDS ON DMS.DOCUMENT
    # =========================================================================
    if env['ir.module.module'].search([('name', '=', 'dms'), ('state', '=', 'installed')]):
        print("\n▶ Creating custom fields on dms.document...")

        dms_model = IrModel.search([('model', '=', 'dms.document')], limit=1)
        if dms_model:
            # Field: x_task_id (link back to task)
            if not IrModelFields.search([
                ('model_id', '=', dms_model.id),
                ('name', '=', 'x_task_id')
            ]):
                IrModelFields.create({
                    'model_id': dms_model.id,
                    'name': 'x_task_id',
                    'field_description': 'Related Task',
                    'ttype': 'many2one',
                    'relation': 'project.task',
                })
                print("  ✓ Created field: x_task_id")
            else:
                print("  ⏭️  Field exists: x_task_id")

            # Field: x_compliance_area
            if not IrModelFields.search([
                ('model_id', '=', dms_model.id),
                ('name', '=', 'x_compliance_area')
            ]):
                IrModelFields.create({
                    'model_id': dms_model.id,
                    'name': 'x_compliance_area',
                    'field_description': 'Compliance Area',
                    'ttype': 'selection',
                    'selection': str([
                        ('month_end', 'Month-End Closing'),
                        ('tax', 'Tax Filing'),
                        ('procurement', 'Vendor Management'),
                        ('expense', 'Expense Management'),
                        ('compliance', 'Regulatory Compliance'),
                        ('statutory', 'Statutory Compliance'),
                        ('governance', 'Governance'),
                    ]),
                })
                print("  ✓ Created field: x_compliance_area")
            else:
                print("  ⏭️  Field exists: x_compliance_area")

    # =========================================================================
    # 3. CUSTOM FIELDS ON DOCUMENT.PAGE
    # =========================================================================
    if env['ir.module.module'].search([('name', '=', 'document_page'), ('state', '=', 'installed')]):
        print("\n▶ Creating custom fields on document.page...")

        page_model = IrModel.search([('model', '=', 'document.page')], limit=1)
        if page_model:
            # Field: x_task_ids (many2many link to tasks)
            if not IrModelFields.search([
                ('model_id', '=', page_model.id),
                ('name', '=', 'x_task_ids')
            ]):
                IrModelFields.create({
                    'model_id': page_model.id,
                    'name': 'x_task_ids',
                    'field_description': 'Related Tasks',
                    'ttype': 'one2many',
                    'relation': 'project.task',
                    'relation_field': 'x_knowledge_page_id',
                    'help': 'Tasks that reference this knowledge page',
                })
                print("  ✓ Created field: x_task_ids")
            else:
                print("  ⏭️  Field exists: x_task_ids")

            # Field: x_page_type
            if not IrModelFields.search([
                ('model_id', '=', page_model.id),
                ('name', '=', 'x_page_type')
            ]):
                IrModelFields.create({
                    'model_id': page_model.id,
                    'name': 'x_page_type',
                    'field_description': 'Page Type',
                    'ttype': 'selection',
                    'selection': str([
                        ('sop', 'Standard Operating Procedure'),
                        ('guide', 'Guide'),
                        ('policy', 'Policy'),
                        ('checklist', 'Checklist'),
                        ('meeting_notes', 'Meeting Notes'),
                        ('other', 'Other'),
                    ]),
                    'default': 'guide',
                })
                print("  ✓ Created field: x_page_type")
            else:
                print("  ⏭️  Field exists: x_page_type")

    env.cr.commit()

    print("\n" + "=" * 70)
    print("  ✓ Custom Fields Setup Complete!")
    print("=" * 70)
    print("\nCreated custom fields:")
    print("  On project.task:")
    print("    - x_evidence_url (Char)")
    print("    - x_area (Selection)")
    print("    - x_knowledge_page_id (Many2one → document.page)")
    print("    - x_approval_status (Selection)")
    if env['ir.module.module'].search([('name', '=', 'dms'), ('state', '=', 'installed')]):
        print("  On dms.document:")
        print("    - x_task_id (Many2one → project.task)")
        print("    - x_compliance_area (Selection)")
    if env['ir.module.module'].search([('name', '=', 'document_page'), ('state', '=', 'installed')]):
        print("  On document.page:")
        print("    - x_task_ids (One2many → project.task)")
        print("    - x_page_type (Selection)")
    print("\nNote: You may need to restart Odoo for fields to appear in views.")
    print("      docker restart odoo18")
    print()

# Run if called via odoo shell
if __name__ != '__main__':
    create_custom_fields(env)
