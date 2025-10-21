# -*- coding: utf-8 -*-
{
    'name': 'Magic Link Authentication',
    'version': '18.0.1.0.0',
    'category': 'Authentication',
    'summary': 'Passwordless authentication via email magic links',
    'description': """
Magic Link Authentication
=========================
Enables passwordless login via email magic links for Odoo.

Features:
- Send magic link to user email
- Secure token-based authentication
- Configurable link expiration (default: 15 minutes)
- Works with existing user accounts
    """,
    'author': 'InsightPulse',
    'website': 'https://insightpulse.ai',
    'depends': ['base', 'web', 'mail'],
    'data': [
        'security/ir.model.access.csv',
        'views/auth_magic_link_templates.xml',
        'data/mail_templates.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}
