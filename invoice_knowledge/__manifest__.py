{
    'name': 'Invoice Knowledge Management',
    'version': '16.0.1.0.0',
    'category': 'Accounting',
    'summary': 'Invoice management with document attachment and knowledge integration',
    'description': """
        Accounting invoice module with:
        - Invoice document attachment and versioning
        - Knowledge base integration for invoice templates
        - Vendor document linking
        - Invoice status tracking and workflows
        - Computed fields for financial rollups
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'account',
        'knowledge_workspace',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/account_move_views.xml',
        'views/invoice_template_views.xml',
    ],
    'installable': True,
    'license': 'AGPL-3',
}
