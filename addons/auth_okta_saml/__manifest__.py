# -*- coding: utf-8 -*-
{
    'name': 'Okta SAML Authentication',
    'version': '18.0.1.0.0',
    'category': 'Authentication',
    'summary': 'Enterprise SSO with Okta SAML for corporate domains',
    'description': """
Okta SAML Authentication
========================
Enables Okta SSO authentication for corporate email domains.

Supported Domains:
- @tbwa-smp.com
- @oomc.com

Features:
- Single Sign-On (SSO) via Okta
- SAML 2.0 protocol
- Auto-create users from Okta directory
- Profile attribute mapping
- Group/role synchronization
    """,
    'author': 'InsightPulse',
    'website': 'https://insightpulse.ai',
    'depends': ['base', 'web', 'auth_saml'],
    'data': [
        'security/ir.model.access.csv',
        'views/auth_saml_templates.xml',
        'data/auth_saml_data.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}
