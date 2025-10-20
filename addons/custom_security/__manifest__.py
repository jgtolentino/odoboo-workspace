# -*- coding: utf-8 -*-
{
    'name': 'Custom Security - Hide Vendor Names',
    'version': '18.0.1.0.0',
    'category': 'Security',
    'summary': 'Hide vendor names from Account Managers while keeping product rates visible',
    'description': """
Custom Security Rules
=====================

Account Managers can:
- See service products (roles/expertise) WITH rates
- Search and add products to sales orders and projects
- Build client estimates using product rates

Account Managers CANNOT see:
- Vendor names (supplier names hidden)
- Vendor contact information
- Supplier records in Contacts

Use Case:
---------
AM: "I need a Senior Developer for 40 hours"
System: Shows "Senior Developer - $150/hr" ✅
System: DOES NOT show "Provided by TechStaff Corp" ❌

Finance sees full details:
- Senior Developer - $150/hr
- Vendor: TechStaff Corp
- Contact: john@techstaffcorp.com
    """,
    'author': 'Your Company',
    'website': 'https://insightpulseai.net',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'product',
        'sale_management',
    ],
    'data': [
        'security/security_groups.xml',
        'security/ir.model.access.csv',
        'views/product_views.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
}
