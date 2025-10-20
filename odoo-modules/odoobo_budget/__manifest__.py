# -*- coding: utf-8 -*-
{
    'name': 'Odoobo Budget Management',
    'version': '18.0.1.0.0',
    'category': 'Project',
    'summary': 'Rate cards, budget requests with AI agent integration',
    'description': """
Odoobo Budget Management
========================

Features:
* Rate card management (role-based pricing)
* Project budget requests (AM creates, FD approves)
* AI agent integration (odoobo-expert skills)
* Vendor privacy (hide from Account Managers)
* Sales Order auto-creation on approval
* Portal integration for clients

Integration with odoobo-expert agent v3.0:
* PR Review skill: Validate budgets before approval
* NL-SQL skill: Natural language queries on budgets
* Odoo-RPC skill: Programmatic data access
* OCR skill: Expense receipt scanning
    """,
    'author': 'Odoobo Expert Team',
    'website': 'https://github.com/jgtolentino/odoboo-workspace',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'sale',
        'project',
        'hr_expense',
        'portal',
        'mail',
    ],
    'data': [
        # Security
        'security/security_groups.xml',
        'security/ir.model.access.csv',
        'security/record_rules.xml',

        # Data
        'data/system_parameters.xml',
        'data/email_templates.xml',
        'data/scheduled_actions.xml',

        # Views
        'views/rate_card_views.xml',
        'views/budget_request_views.xml',
        'views/budget_line_views.xml',
        'views/menu_items.xml',

        # Server Actions
        'data/server_actions.xml',

        # Portal
        'views/portal_templates.xml',
    ],
    'demo': [
        'demo/rate_card_demo.xml',
        'demo/budget_request_demo.xml',
    ],
    'installable': True,
    'application': True,
    'auto_install': False,
}
