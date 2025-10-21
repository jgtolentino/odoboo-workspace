# -*- coding: utf-8 -*-
{
    'name': 'Google OAuth Authentication',
    'version': '18.0.1.0.0',
    'category': 'Authentication',
    'summary': 'Sign in with Google OAuth for allowed domains',
    'description': """
Google OAuth Authentication
============================
Enables Google OAuth sign-in for Odoo.

Allowed Domains:
- @tbwa-smp.com
- @oomc.com
- @gmail.com

Features:
- One-click Google sign-in
- Auto-create users from allowed domains
- Secure OAuth 2.0 flow
- Profile picture sync
    """,
    'author': 'InsightPulse',
    'website': 'https://insightpulse.ai',
    'depends': ['base', 'web', 'auth_oauth'],
    'data': [
        'views/auth_oauth_templates.xml',
        'data/auth_oauth_data.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}
