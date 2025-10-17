{
    'name': 'HR Expense Documents & Concur Ready',
    'version': '19.0.1.0',
    'category': 'Human Resources',
    'summary': 'HR expense tracking with Concur integration, vendor rate cards, and document management',
    'description': """
        HR Expense module with:
        - Expense tracking with document attachments
        - Approval workflows
        - Knowledge base integration
        - Expense categorization
        - Computed fields for totals and rollups
        - Concur mapping and integration
        - Vendor rate cards with effective dating
        - Export queue for Concur synchronization
        - FX rate locking and tax calculations
        - OCR field extraction
    """,
    'author': 'OCA Community + InsightPulseAI',
    'website': 'https://github.com/oca',
    'depends': [
        'base',
        'mail',
        'hr_expense',
        'account',
        'project',
        'knowledge_workspace',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/hr_expense_views.xml',
        'views/expense_category_views.xml',
        'views/rate_card_views.xml',
        'views/concur_mapping_views.xml',
        'data/ir_config_parameter.xml',
        'data/ir_cron.xml',
    ],
    'installable': True,
    'license': 'AGPL-3',
}
