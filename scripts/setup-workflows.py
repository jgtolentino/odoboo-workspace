#!/usr/bin/env python3
"""
Workflow and Automation Setup for Notion-Style Workspace
Creates:
- Email alerts for task deadlines
- Approval workflows (AM → Finance Director)
- Activity reminders
- Automated actions

Usage:
    docker exec -i odoo18 odoo shell -d odoo_production < setup-workflows.py
"""

print("=" * 70)
print("  Workflow and Automation Setup")
print("=" * 70)
print()

def create_workflows(env):
    """Create automated workflows and email alerts"""

    # =========================================================================
    # 1. TASK DEADLINE REMINDERS (Automated Actions)
    # =========================================================================
    print("▶ Creating task deadline reminder automation...")

    task_model = env['ir.model'].search([('model', '=', 'project.task')], limit=1)

    # Delete existing automation if exists
    existing = env['base.automation'].search([
        ('name', '=', 'Task Deadline Reminder - 1 Day Before')
    ])
    if existing:
        existing.unlink()

    # Create automation: Send email 1 day before deadline
    automation = env['base.automation'].create({
        'name': 'Task Deadline Reminder - 1 Day Before',
        'model_id': task_model.id,
        'trigger': 'on_time',
        'trg_date_id': env['ir.model.fields'].search([
            ('model_id', '=', task_model.id),
            ('name', '=', 'date_deadline')
        ], limit=1).id,
        'trg_date_range': -1,
        'trg_date_range_type': 'day',
        'filter_pre_domain': str([
            ('date_deadline', '!=', False),
            ('stage_id.fold', '=', False),  # Not in folded/done stage
        ]),
        'state': 'code',
        'code': '''
# Send email reminder to assignee
if record.user_id and record.user_id.email:
    mail_template = env.ref('mail.mail_template_data_notification_email_default', raise_if_not_found=False)
    if mail_template:
        record.message_post(
            subject='Task Deadline Tomorrow: %s' % record.name,
            body='''
<p>Hello %s,</p>
<p>This is a reminder that the following task is due tomorrow:</p>
<ul>
<li><strong>Task:</strong> %s</li>
<li><strong>Project:</strong> %s</li>
<li><strong>Due Date:</strong> %s</li>
<li><strong>Description:</strong> %s</li>
</ul>
<p>Please ensure you complete this task on time.</p>
<p><a href="/web#id=%s&model=project.task&view_type=form">Click here to view task</a></p>
''' % (record.user_id.name, record.name, record.project_id.name if record.project_id else 'N/A', record.date_deadline, record.description or 'N/A', record.id),
            partner_ids=[record.user_id.partner_id.id],
            message_type='notification',
            subtype_xmlid='mail.mt_comment',
        )
        log('Sent deadline reminder to %s' % record.user_id.email)
''',
        'active': True,
    })
    print(f"  ✓ Created automation: {automation.name}")

    # =========================================================================
    # 2. OVERDUE TASK ALERTS
    # =========================================================================
    print("\n▶ Creating overdue task alert automation...")

    existing = env['base.automation'].search([
        ('name', '=', 'Overdue Task Alert - Daily')
    ])
    if existing:
        existing.unlink()

    automation = env['base.automation'].create({
        'name': 'Overdue Task Alert - Daily',
        'model_id': task_model.id,
        'trigger': 'on_time',
        'trg_date_id': env['ir.model.fields'].search([
            ('model_id', '=', task_model.id),
            ('name', '=', 'date_deadline')
        ], limit=1).id,
        'trg_date_range': 1,
        'trg_date_range_type': 'day',
        'filter_pre_domain': str([
            ('date_deadline', '<', 'context_today().strftime("%Y-%m-%d")'),
            ('stage_id.fold', '=', False),  # Not done
        ]),
        'state': 'code',
        'code': '''
# Send overdue alert
if record.user_id and record.user_id.email:
    days_overdue = (fields.Date.today() - record.date_deadline).days
    record.message_post(
        subject='⚠️ Task Overdue: %s (%s days)' % (record.name, days_overdue),
        body='''
<p><strong style="color: red;">⚠️ OVERDUE TASK</strong></p>
<p>Hello %s,</p>
<p>The following task is overdue by %s days:</p>
<ul>
<li><strong>Task:</strong> %s</li>
<li><strong>Project:</strong> %s</li>
<li><strong>Due Date:</strong> %s</li>
<li><strong>Priority:</strong> %s</li>
</ul>
<p>Please update the task status or extend the deadline.</p>
<p><a href="/web#id=%s&model=project.task&view_type=form">Click here to view task</a></p>
''' % (record.user_id.name, days_overdue, record.name, record.project_id.name if record.project_id else 'N/A', record.date_deadline, dict(record._fields['priority'].selection).get(record.priority, 'Normal'), record.id),
        partner_ids=[record.user_id.partner_id.id],
        message_type='notification',
        subtype_xmlid='mail.mt_comment',
    )
''',
        'active': True,
    })
    print(f"  ✓ Created automation: {automation.name}")

    # =========================================================================
    # 3. APPROVAL WORKFLOW: TASK SUBMITTED → NOTIFY APPROVER
    # =========================================================================
    print("\n▶ Creating approval workflow automation...")

    existing = env['base.automation'].search([
        ('name', '=', 'Approval Request - Notify Approver')
    ])
    if existing:
        existing.unlink()

    # Check if x_approval_status field exists
    if env['ir.model.fields'].search([
        ('model_id', '=', task_model.id),
        ('name', '=', 'x_approval_status')
    ]):
        automation = env['base.automation'].create({
            'name': 'Approval Request - Notify Approver',
            'model_id': task_model.id,
            'trigger': 'on_write',
            'filter_pre_domain': str([
                ('x_approval_status', '=', 'submitted')
            ]),
            'state': 'code',
            'code': '''
# Notify Finance Director when approval is needed
finance_director = env['res.users'].search([
    ('email', '=', 'finance.director@company.com')
], limit=1)

if finance_director:
    record.message_post(
        subject='Approval Required: %s' % record.name,
        body='''
<p>Hello %s,</p>
<p>A new task requires your approval:</p>
<ul>
<li><strong>Task:</strong> %s</li>
<li><strong>Submitted by:</strong> %s</li>
<li><strong>Project:</strong> %s</li>
<li><strong>Compliance Area:</strong> %s</li>
<li><strong>Description:</strong> %s</li>
</ul>
<p>Please review and approve/reject this request.</p>
<p><a href="/web#id=%s&model=project.task&view_type=form">Click here to review</a></p>
''' % (finance_director.name, record.name, record.user_id.name if record.user_id else 'N/A', record.project_id.name if record.project_id else 'N/A', dict(record._fields.get('x_area').selection).get(record.x_area, 'N/A') if hasattr(record, 'x_area') else 'N/A', record.description or 'N/A', record.id),
        partner_ids=[finance_director.partner_id.id],
        message_type='notification',
        subtype_xmlid='mail.mt_comment',
    )
    # Create activity for approver
    env['mail.activity'].create({
        'res_id': record.id,
        'res_model_id': task_model.id,
        'user_id': finance_director.id,
        'summary': 'Review and Approve: %s' % record.name,
        'activity_type_id': env.ref('mail.mail_activity_data_todo').id,
        'date_deadline': fields.Date.today(),
    })
''',
            'active': True,
        })
        print(f"  ✓ Created automation: {automation.name}")
    else:
        print("  ⚠️  x_approval_status field not found, skipping approval automation")

    # =========================================================================
    # 4. NEW TASK ASSIGNED → NOTIFY ASSIGNEE
    # =========================================================================
    print("\n▶ Creating task assignment notification...")

    existing = env['base.automation'].search([
        ('name', '=', 'Task Assigned - Notify Assignee')
    ])
    if existing:
        existing.unlink()

    automation = env['base.automation'].create({
        'name': 'Task Assigned - Notify Assignee',
        'model_id': task_model.id,
        'trigger': 'on_write',
        'filter_pre_domain': str([
            ('user_id', '!=', False)
        ]),
        'state': 'code',
        'code': '''
# Notify assignee when task is assigned to them
if record.user_id and record.user_id.email:
    # Check if user_id changed in this write
    if 'user_id' in env.context.get('params', {}).get('args', [{}])[0]:
        record.message_post(
            subject='Task Assigned to You: %s' % record.name,
            body='''
<p>Hello %s,</p>
<p>You have been assigned a new task:</p>
<ul>
<li><strong>Task:</strong> %s</li>
<li><strong>Project:</strong> %s</li>
<li><strong>Due Date:</strong> %s</li>
<li><strong>Priority:</strong> %s</li>
<li><strong>Description:</strong> %s</li>
</ul>
<p><a href="/web#id=%s&model=project.task&view_type=form">Click here to view task</a></p>
''' % (record.user_id.name, record.name, record.project_id.name if record.project_id else 'N/A', record.date_deadline or 'Not set', dict(record._fields['priority'].selection).get(record.priority, 'Normal'), record.description or 'N/A', record.id),
            partner_ids=[record.user_id.partner_id.id],
            message_type='notification',
            subtype_xmlid='mail.mt_comment',
        )
''',
        'active': True,
    })
    print(f"  ✓ Created automation: {automation.name}")

    # =========================================================================
    # 5. MONTH-END CLOSING CHECKLIST (Recurring Task Template)
    # =========================================================================
    print("\n▶ Creating recurring task template for month-end...")

    # Find the project
    project = env['project.project'].search([('name', '=', 'Compliance & Month-End')], limit=1)

    if project:
        # Check if recurring tasks module is available
        if env['ir.module.module'].search([
            ('name', '=', 'project_task_recurring'),
            ('state', '=', 'installed')
        ]):
            print("  ℹ️  project_task_recurring module installed")
            print("     Create recurring task manually via UI for month-end checklist")
        else:
            print("  ℹ️  Create master task template for month-end (copy manually each month)")

    env.cr.commit()

    print("\n" + "=" * 70)
    print("  ✓ Workflow and Automation Setup Complete!")
    print("=" * 70)
    print("\nCreated automations:")
    print("  1. Task Deadline Reminder - 1 Day Before")
    print("  2. Overdue Task Alert - Daily")
    if env['ir.model.fields'].search([('model', '=', 'project.task'), ('name', '=', 'x_approval_status')]):
        print("  3. Approval Request - Notify Approver")
    print("  4. Task Assigned - Notify Assignee")
    print("\nEmail notifications will be sent for:")
    print("  - Tasks due tomorrow")
    print("  - Overdue tasks")
    print("  - Approval requests")
    print("  - New task assignments")
    print("\nNote: Ensure email server is configured in Odoo:")
    print("      Settings → Technical → Outgoing Mail Servers")
    print()

# Run if called via odoo shell
if __name__ != '__main__':
    create_workflows(env)
