{
    'name': 'Workspace Rollups & Analytics',
    'version': '16.0.1.0.0',
    'category': 'Tools',
    'summary': 'Advanced computed fields and rollups for workspace analytics',
    'description': """
        Workspace rollups and analytics module providing:
        - Cross-module computed fields and aggregations
        - Workspace-wide metrics and KPIs
        - Advanced rollup calculations (like Notion)
        - Analytics and reporting helpers
        - Performance optimization for computed fields
    """,
    'author': 'OCA Community',
    'website': 'https://github.com/oca',
    'depends': [
        'knowledge_workspace',
        'hr_expense_documents',
        'project_workspace',
        'invoice_knowledge',
        'vendor_knowledge',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/workspace_metric_views.xml',
        'views/workspace_rollup_views.xml',
    ],
    'installable': True,
    'license': 'AGPL-3',
}
